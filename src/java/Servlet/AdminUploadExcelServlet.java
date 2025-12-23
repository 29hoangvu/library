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
import org.json.JSONArray;
import org.json.JSONObject;

@MultipartConfig(maxFileSize = 20 * 1024 * 1024) // 20MB
public class AdminUploadExcelServlet extends HttpServlet {

    private static final DateTimeFormatter[] DATE_PARSERS = new DateTimeFormatter[]{
        DateTimeFormatter.ofPattern("yyyy-MM-dd"),
        DateTimeFormatter.ofPattern("dd/MM/yyyy"),
        DateTimeFormatter.ofPattern("MM/dd/yyyy")
    };

    private static final DataFormatter FORMATTER = new DataFormatter(Locale.getDefault());

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json;charset=UTF-8");

        JSONArray details = new JSONArray();
        List<String> logs = new ArrayList<>();

        int imported = 0, skipped = 0, errors = 0;

        Part filePart = request.getPart("excelFile");
        if (filePart == null || filePart.getSize() == 0) {
            response.getWriter().write(
                new JSONObject()
                    .put("success", false)
                    .put("summary", "Không có tệp Excel được tải lên.")
                    .put("logs", List.of("Không tìm thấy file Excel."))
                    .toString()
            );
            return;
        }

        try (
            InputStream is = filePart.getInputStream();
            Workbook wb = WorkbookFactory.create(is);
            Connection conn = DBConnection.getConnection()
        ) {
            conn.setAutoCommit(false);

            Sheet sheet = wb.getSheetAt(0);
            if (sheet == null) {
                throw new RuntimeException("Không tìm thấy sheet đầu tiên trong Excel.");
            }

            int firstRow = 1; // bỏ header

            for (int r = firstRow; r <= sheet.getLastRowNum(); r++) {
                Row row = sheet.getRow(r);
                if (row == null) continue;

                JSONObject item = new JSONObject();
                item.put("rowNumber", r + 1);
                item.put("isbn", "");
                item.put("title", "");
                item.put("status", "skipped");
                item.put("message", "");

                try {
                    String isbn = getIsbn(row, 0);
                    String title = getStr(row, 1);
                    String author = getStr(row, 2);
                    Integer pubY = getInt(row, 3);
                    String lang = getStr(row, 4);
                    Integer pages = getInt(row, 5);
                    String format = getStr(row, 6);
                    String publisher = getStr(row, 7);
                    Double price = getDoubleSafe(row, 8);
                    Integer qty = getIntSafe(row, 9);
                    LocalDate dop = getLocalDate(row, 10);
                    String cover = getStr(row, 11);
                    String genres = getStr(row, 12);

                    item.put("isbn", isbn);
                    item.put("title", title);

                    // validate
                    if (isBlank(isbn) || isBlank(title) || isBlank(author)
                            || pubY == null || isBlank(format) || qty == null) {

                        item.put("status", "skipped");
                        item.put("message", "Thiếu dữ liệu bắt buộc");
                        skipped++;
                        logs.add("Dòng " + (r + 1) + ": bỏ qua (thiếu dữ liệu bắt buộc)");
                        details.put(item);
                        continue;
                    }

                    format = format.trim().toUpperCase(Locale.ROOT);
                    if (!List.of("HARDCOVER", "PAPERBACK", "EBOOK").contains(format)) {
                        item.put("status", "skipped");
                        item.put("message", "Format không hợp lệ: " + format);
                        skipped++;
                        logs.add("Dòng " + (r + 1) + ": bỏ qua (format không hợp lệ)");
                        details.put(item);
                        continue;
                    }

                    Integer authorId = getOrCreateAuthor(conn, author);

                    // ===== CHECK TRÙNG ISBN HOẶC TITLE =====
                    if (bookExists(conn, isbn, title)) {
                        item.put("status", "skipped");
                        item.put("message", "Trùng ISBN hoặc tên sách");
                        skipped++;
                        logs.add("Dòng " + (r + 1) + ": trùng ISBN hoặc tên sách → bỏ qua (" + title + ")");
                        details.put(item);
                        continue;
                    }

                    // ===== INSERT SÁCH MỚI =====
                    insertBook(conn, isbn, title, authorId, pubY,
                               lang, pages, format, publisher, cover, qty);

                    if (!isBlank(genres)) {
                        String[] names = Arrays.stream(genres.split("[,\n]"))
                                .map(String::trim)
                                .filter(s -> !s.isEmpty())
                                .toArray(String[]::new);
                        upsertBookGenres(conn, isbn, names);
                    }

                    // ===== BOOK ITEM =====
                    if (qty != null && qty > 0) {
                        insertOneBookItem(conn, isbn, qty, price, dop);
                    }

                    item.put("status", "IMPORTED");
                    item.put("message", "Thêm thành công");
                    imported++;
                    logs.add("Dòng " + (r + 1) + ": thêm thành công (" + title + ")");
                    details.put(item);

                } catch (Exception rowEx) {
                    item.put("status", "error");
                    item.put("message", rowEx.getMessage());
                    errors++;
                    logs.add("Dòng " + (r + 1) + ": lỗi - " + rowEx.getMessage());
                    details.put(item);
                }
            }

            conn.commit();

        } catch (Exception e) {
            e.printStackTrace();
            response.getWriter().write(
                new JSONObject()
                    .put("success", false)
                    .put("summary", "Có lỗi xảy ra khi xử lý Excel")
                    .put("logs", List.of(e.getMessage()))
                    .toString()
            );
            return;
        }

        JSONObject result = new JSONObject();
        result.put("success", true);
        result.put("imported", imported);
        result.put("skipped", skipped);
        result.put("errors", errors);
        result.put(
            "summary",
            "Thành công: " + imported +
            " | Bỏ qua: " + skipped +
            " | Lỗi: " + errors
        );
        result.put("logs", logs);     // 👈 JSP đang dùng
        result.put("details", details); // để sau này nâng cấp

        response.getWriter().write(result.toString());
    }

    // ================= HELPERS =================

    private static boolean isBlank(String s) {
        return s == null || s.trim().isEmpty();
    }

    private static String getDisplay(Row row, int col) {
        Cell c = row.getCell(col, Row.MissingCellPolicy.RETURN_BLANK_AS_NULL);
        if (c == null) return null;
        return FORMATTER.formatCellValue(c).trim();
    }

    private static String getIsbn(Row row, int col) {
        String v = getDisplay(row, col);
        if (v == null) return null;
        String digits = v.replaceAll("[^0-9]", "");
        return digits.isEmpty() ? null : digits;
    }

    private static String getStr(Row row, int col) {
        return getDisplay(row, col);
    }

    private static Integer getInt(Row row, int col) {
        String s = getDisplay(row, col);
        if (s == null || s.isEmpty()) return null;
        return Integer.parseInt(s.replaceAll("[^0-9]", ""));
    }

    private static Integer getIntSafe(Row row, int col) {
        try {
            return getInt(row, col);
        } catch (Exception e) {
            return null;
        }
    }

    private static Double getDoubleSafe(Row row, int col) {
        String s = getDisplay(row, col);
        if (s == null || s.isEmpty()) return null;
        try {
            return Double.parseDouble(s.replace(",", ""));
        } catch (Exception e) {
            return null;
        }
    }

    private static LocalDate getLocalDate(Row row, int col) {
        Cell c = row.getCell(col, Row.MissingCellPolicy.RETURN_BLANK_AS_NULL);
        if (c == null) return null;

        if (c.getCellType() == CellType.NUMERIC && DateUtil.isCellDateFormatted(c)) {
            return c.getDateCellValue().toInstant()
                    .atZone(java.time.ZoneId.systemDefault())
                    .toLocalDate();
        }

        String s = FORMATTER.formatCellValue(c).trim();
        for (DateTimeFormatter f : DATE_PARSERS) {
            try {
                return LocalDate.parse(s, f);
            } catch (Exception ignored) {}
        }
        return null;
    }

    // ================= DB =================

    private static Integer getOrCreateAuthor(Connection conn, String name) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT id FROM author WHERE LOWER(name)=LOWER(?) LIMIT 1")) {
            ps.setString(1, name);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        try (PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO author(name) VALUES(?)", Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, name);
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }

    private static boolean bookExists(Connection conn, String isbn, String title) throws SQLException {
        String sql = """
            SELECT 1
            FROM book
            WHERE
                (isbn IS NOT NULL AND isbn <> '' AND isbn = ?)
                OR LOWER(title) = LOWER(?)
            LIMIT 1
        """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, isbn == null ? "" : isbn.trim());
            ps.setString(2, title == null ? "" : title.trim());
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }


    private static void insertBook(Connection conn, String isbn, String title, Integer authorId,
        Integer pubY, String lang, Integer pages, String format,
        String publisher, String cover, Integer quantity) throws SQLException {

        String sql = """
            INSERT INTO book
            (isbn, title, authorId, publicationYear, language,
             numberOfPages, format, publisher, coverImage, quantity, status)
            VALUES (?,?,?,?,?,?,?,?,?,?,'ACTIVE')
        """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, isbn);
            ps.setString(2, title);
            ps.setInt(3, authorId);
            ps.setObject(4, pubY);
            ps.setString(5, lang);
            ps.setObject(6, pages);
            ps.setString(7, format);
            ps.setString(8, publisher);
            ps.setString(9, cover);
            ps.setObject(10, quantity);
            ps.executeUpdate();
        }
    }

    private static void upsertBookGenres(Connection conn, String isbn, String[] names) throws SQLException {
        Integer bookId = null;
        try (PreparedStatement ps = conn.prepareStatement("SELECT id FROM book WHERE isbn=?")) {
            ps.setString(1, isbn);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) bookId = rs.getInt(1);
            }
        }
        if (bookId == null) return;

        for (String name : names) {
            Integer gid = null;

            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT id FROM genre WHERE LOWER(name)=LOWER(?) LIMIT 1")) {
                ps.setString(1, name);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) gid = rs.getInt(1);
                }
            }

            if (gid == null) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO genre(name) VALUES(?)", Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, name);
                    ps.executeUpdate();
                    try (ResultSet rs = ps.getGeneratedKeys()) {
                        rs.next();
                        gid = rs.getInt(1);
                    }
                }
            }

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
}
