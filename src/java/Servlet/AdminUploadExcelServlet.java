package Servlet;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.*;
import java.sql.*;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.*;

import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

/**
 * Upload Excel để nhập sách hàng loạt. Yêu cầu thư viện Apache POI: -
 * poi-5.x.jar - poi-ooxml-5.x.jar - commons-collections4, xmlbeans, curvesapi
 * (transitive)
 */
@WebServlet(name = "AdminUploadExcelServlet", urlPatterns = {"/AdminUploadExcel"})
@MultipartConfig(maxFileSize = 20 * 1024 * 1024) // 20MB
public class AdminUploadExcelServlet extends HttpServlet {

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd");

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        Part filePart = request.getPart("excelFile");
        if (filePart == null || filePart.getSize() == 0) {
            sendMsg(response, false, "Không có tệp Excel được tải lên.");
            return;
        }

        List<String> logs = new ArrayList<>();
        int imported = 0, skipped = 0, errors = 0;

        try (InputStream is = filePart.getInputStream(); Workbook wb = WorkbookFactory.create(is); // <— tự nhận .xls/.xlsx
                 Connection conn = DBConnection.getConnection()) {

            conn.setAutoCommit(false);

            Sheet sheet = wb.getSheetAt(0);
            if (sheet == null) {
                sendMsg(response, false, "Không tìm thấy sheet đầu tiên trong Excel.");
                return;
            }

            // Header dự kiến:
            // A:ISBN, B:Title, C:AuthorName, D:PublicationYear, E:Language,
            // F:NumberOfPages, G:Format(HARDCOVER|PAPERBACK|EBOOK),
            // H:Publisher, I:Price, J:Quantity, K:DateOfPurchase(yyyy-MM-dd),
            // L:CoverImage(URL), M:Genres (ten1,ten2,...)
            int firstRow = 1; // bỏ hàng tiêu đề

            for (int r = firstRow; r <= sheet.getLastRowNum(); r++) {
                Row row = sheet.getRow(r);
                if (row == null) {
                    continue;
                }

                try {
                    String isbn = getIsbn(row, 0);
                    String title = getStr(row, 1);
                    String author = getStr(row, 2);
                    Integer pubY = getInt(row, 3);
                    String lang = getStr(row, 4);
                    Integer pages = getInt(row, 5);
                    String format = getStr(row, 6);
                    String publisher = getStr(row, 7);
                    Double price = getDoubleSafe(row, 8);;
                    Integer qty = getIntSafe(row, 9);
                    LocalDate dop = getLocalDate(row, 10);
                    String cover = getStr(row, 11);
                    String genres = getStr(row, 12);

                    // Validate tối thiểu
                    if (isBlank(isbn) || isBlank(title) || isBlank(author) || pubY == null || isBlank(format) || qty == null) {
                        skipped++;
                        logs.add("Dòng " + (r + 1) + " thiếu dữ liệu bắt buộc → bỏ qua.");
                        continue;
                    }

                    format = format.trim().toUpperCase(Locale.ROOT);
                    if (!Arrays.asList("HARDCOVER", "PAPERBACK", "EBOOK").contains(format)) {
                        skipped++;
                        logs.add("Dòng " + (r + 1) + " Format không hợp lệ: " + format);
                        continue;
                    }

                    // ====== Insert/Upsert dữ liệu ======
                    // 1) Lấy/ tạo authorId
                    Integer authorId = getOrCreateAuthor(conn, author);

                    // 2) Tạo/cập nhật book (CÓ quantity + status)
                    boolean bookExisted = bookExists(conn, isbn);
                    if (!bookExisted) {
                        insertBook(conn, isbn, title, authorId, pubY, lang, pages, format, publisher, cover, qty);
                    } else {
                        // có thể cập nhật một số field nếu muốn, ở đây giữ nguyên
                    }

                    // 3) Thể loại: nhiều tên -> map sang id, tạo nếu chưa có
                    if (!isBlank(genres)) {
                        String[] names = Arrays.stream(genres.split("[,\n]"))
                                .map(String::trim).filter(s -> !s.isEmpty()).toArray(String[]::new);
                        upsertBookGenres(conn, isbn, names);
                    }

                    // 4) Tạo số lượng bản vật lý (bookitem) + giá + ngày nhập
                    if (qty != null && qty > 0) {
                        insertOneBookItem(conn, isbn, qty, price, dop);
                    }

                    imported++;
                } catch (Exception rowEx) {
                    errors++;
                    logs.add("Dòng " + (r + 1) + " lỗi: " + rowEx.getMessage());
                }
            }

            conn.commit();
        } catch (Exception e) {
            e.printStackTrace();
            sendMsg(response, false, "Lỗi xử lý Excel: " + e.getMessage());
            return;
        }

        sendMsg(response, true,
                "Nhập Excel xong. Thêm mới: " + imported + ", Bỏ qua: " + skipped + ", Lỗi: " + errors);
    }

    // -------------------- Helpers --------------------
    private static boolean isBlank(String s) {
        return s == null || s.trim().isEmpty();
    }
    private static final DateTimeFormatter[] DATE_PARSERS = new DateTimeFormatter[]{
        DateTimeFormatter.ofPattern("yyyy-MM-dd"),
        DateTimeFormatter.ofPattern("dd/MM/yyyy"),
        DateTimeFormatter.ofPattern("MM/dd/yyyy")
    };

// Dùng chung cho mọi cell để lấy "giá trị hiển thị" như Excel đang thấy
    private static final DataFormatter FORMATTER = new DataFormatter(Locale.getDefault());

    private static String getDisplay(Row row, int col) {
        Cell c = row.getCell(col, Row.MissingCellPolicy.RETURN_BLANK_AS_NULL);
        if (c == null) {
            return null;
        }
        return FORMATTER.formatCellValue(c).trim();
    }

// ĐỌC ISBN: giữ nguyên chuỗi, loại bỏ khoảng trắng, dấu gạch, và nếu lỡ là "9,78604E+12" -> lấy chuỗi digit
    private static String getIsbn(Row row, int col) {
        String val = getDisplay(row, col);
        if (val == null || val.isEmpty()) {
            return null;
        }
        // loại bỏ mọi ký tự không phải số
        String digits = val.replaceAll("[^0-9]", "");
        // ISBN 10/13 thì thường 10 hoặc 13 số; nếu > 13 cứ giữ nguyên (theo dữ liệu bạn là 13)
        return digits.isEmpty() ? null : digits;
    }

// số nguyên an toàn từ số/chuỗi có dấu phẩy
    private static Integer getIntSafe(Row row, int col) {
        String s = getDisplay(row, col);
        if (s == null || s.isEmpty()) {
            return null;
        }
        s = s.replaceAll("[\\s,]", "");
        try {
            return Integer.parseInt(s);
        } catch (NumberFormatException e) {
            return null;
        }
    }

// số thực an toàn từ số/chuỗi có dấu phẩy
    private static Double getDoubleSafe(Row row, int col) {
        String s = getDisplay(row, col);
        if (s == null || s.isEmpty()) {
            return null;
        }
        s = s.replaceAll("[\\s,]", "");
        try {
            return Double.parseDouble(s);
        } catch (NumberFormatException e) {
            return null;
        }
    }

// ngày: nếu cell là date -> chuyển LocalDate; nếu là chuỗi -> thử nhiều format
    private static LocalDate getLocalDate(Row row, int col) {
        Cell c = row.getCell(col, Row.MissingCellPolicy.RETURN_BLANK_AS_NULL);
        if (c == null) {
            return null;
        }

        if (c.getCellType() == CellType.NUMERIC && DateUtil.isCellDateFormatted(c)) {
            java.util.Date d = c.getDateCellValue();
            return d.toInstant().atZone(java.time.ZoneId.systemDefault()).toLocalDate();
        }

        String s = FORMATTER.formatCellValue(c).trim();
        if (s.isEmpty()) {
            return null;
        }
        for (DateTimeFormatter f : DATE_PARSERS) {
            try {
                return LocalDate.parse(s, f);
            } catch (Exception ignore) {
            }
        }
        return null;
    }

    private static String getStr(Row row, int col) {
        Cell c = row.getCell(col, Row.MissingCellPolicy.RETURN_BLANK_AS_NULL);
        if (c == null) {
            return null;
        }
        c.setCellType(CellType.STRING);
        String v = c.getStringCellValue();
        return v != null ? v.trim() : null;
    }

    private static Integer getInt(Row row, int col) {
        Cell c = row.getCell(col, Row.MissingCellPolicy.RETURN_BLANK_AS_NULL);
        if (c == null) {
            return null;
        }
        if (c.getCellType() == CellType.NUMERIC) {
            return (int) Math.round(c.getNumericCellValue());
        }
        if (c.getCellType() == CellType.STRING && !c.getStringCellValue().trim().isEmpty()) {
            return Integer.parseInt(c.getStringCellValue().trim());
        }
        return null;
    }

    private static Double getDouble(Row row, int col) {
        Cell c = row.getCell(col, Row.MissingCellPolicy.RETURN_BLANK_AS_NULL);
        if (c == null) {
            return null;
        }
        if (c.getCellType() == CellType.NUMERIC) {
            return c.getNumericCellValue();
        }
        if (c.getCellType() == CellType.STRING && !c.getStringCellValue().trim().isEmpty()) {
            return Double.parseDouble(c.getStringCellValue().trim());
        }
        return null;
    }

    private static Integer getOrCreateAuthor(Connection conn, String name) throws SQLException {
        // Tìm
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT id FROM author WHERE LOWER(name)=LOWER(?) LIMIT 1")) {
            ps.setString(1, name);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        }
        // Tạo
        try (PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO author(name) VALUES(?)", Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, name);
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        }
        throw new SQLException("Không thể tạo tác giả: " + name);
    }

    private static boolean bookExists(Connection conn, String isbn) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT 1 FROM book WHERE isbn=?")) {
            ps.setString(1, isbn);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private static void insertBook(Connection conn, String isbn, String title, Integer authorId,
        Integer pubY, String lang, Integer pages, String format,
        String publisher, String cover, Integer quantity) throws SQLException {

        String sql = "INSERT INTO book " +
                     "(isbn, title, authorId, publicationYear, language, numberOfPages, format, " +
                     " publisher, coverImage, quantity, status) " +
                     "VALUES (?,?,?,?,?,?,?,?,?,?, 'ACTIVE')";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, isbn);
            ps.setString(2, title);
            ps.setInt(3, authorId);
            ps.setObject(4, pubY, Types.INTEGER);
            ps.setString(5, lang);
            ps.setObject(6, pages, Types.INTEGER);
            ps.setString(7, format);
            ps.setString(8, publisher);
            ps.setString(9, cover);
            if (quantity == null) ps.setNull(10, Types.INTEGER);
            else ps.setInt(10, quantity);
            ps.executeUpdate();
        }
    }


    private static void upsertBookGenres(Connection conn, String isbn, String[] names) throws SQLException {
        // Lấy book_id từ isbn (nếu bạn đang dùng bảng liên kết theo isbn, sửa lại cho khớp schema của bạn)
        Integer bookId = null;
        try (PreparedStatement ps = conn.prepareStatement("SELECT id FROM book WHERE isbn=?")) {
            ps.setString(1, isbn);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    bookId = rs.getInt(1);
                }
            }
        }
        if (bookId == null) {
            throw new SQLException("Không tìm thấy book id cho ISBN " + isbn);
        }

        for (String name : names) {
            Integer gid = null;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT id FROM genre WHERE LOWER(name)=LOWER(?) LIMIT 1")) {
                ps.setString(1, name);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        gid = rs.getInt(1);
                    }
                }
            }
            if (gid == null) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO genre(name) VALUES(?)", Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, name);
                    ps.executeUpdate();
                    try (ResultSet rs = ps.getGeneratedKeys()) {
                        if (rs.next()) {
                            gid = rs.getInt(1);
                        }
                    }
                }
            }
            // Gắn book-genre (tránh trùng)
            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT IGNORE INTO book_genre(book_id, genre_id) VALUES(?,?)")) {
                ps.setInt(1, bookId);
                ps.setInt(2, gid);
                ps.executeUpdate();
            }
        }
    }

    private static void insertOneBookItem(Connection conn, String isbn, Integer qty, Double price, LocalDate dop) throws SQLException {
        String sql = "INSERT INTO bookitem (book_isbn, price, date_of_purchase) VALUES (?, ?, ?)";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, isbn);
            if (price == null) ps.setNull(2, Types.DECIMAL);
            else ps.setBigDecimal(2, new java.math.BigDecimal(price));
            if (dop == null) ps.setNull(3, Types.DATE);
            else ps.setDate(3, java.sql.Date.valueOf(dop));
            ps.executeUpdate();
        }
    }


    private static void sendMsg(HttpServletResponse resp, boolean ok, String msg) throws IOException {
        resp.setContentType("text/html; charset=UTF-8");
        PrintWriter out = resp.getWriter();
        out.println("<meta charset='utf-8'/>");
        out.println("<script>");
        out.println("alert(" + toJsStr((ok ? "✅ " : "❌ ") + msg) + ");");
        out.println("window.location.href=document.referrer || '" + "/admin/books.jsp" + "';");
        out.println("</script>");
    }

    private static String toJsStr(String s) {
        return "'" + s.replace("\\", "\\\\").replace("'", "\\'").replace("\n", "\\n") + "'";
    }
}
