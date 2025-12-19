package service.admin;

import Servlet.DBConnection;
import org.apache.poi.ss.usermodel.*;

import java.io.InputStream;
import java.sql.*;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.*;

public class ExcelImportServiceImpl implements ExcelImportService {

    private static final DateTimeFormatter[] DATE_PARSERS = new DateTimeFormatter[]{
        DateTimeFormatter.ofPattern("yyyy-MM-dd"),
        DateTimeFormatter.ofPattern("dd/MM/yyyy"),
        DateTimeFormatter.ofPattern("MM/dd/yyyy")
    };

    private static final DataFormatter FORMATTER = new DataFormatter(Locale.getDefault());

    @Override
    public Map<String, Object> importExcel(InputStream excelStream) throws Exception {

        List<String> logs = new ArrayList<>();
        int imported = 0, skipped = 0, errors = 0;

        try (
            Workbook wb = WorkbookFactory.create(excelStream);
            Connection conn = DBConnection.getConnection()
        ) {
            conn.setAutoCommit(false);

            Sheet sheet = wb.getSheetAt(0);
            if (sheet == null) {
                throw new RuntimeException("Không tìm thấy sheet đầu tiên trong Excel.");
            }

            for (int r = 1; r <= sheet.getLastRowNum(); r++) {
                Row row = sheet.getRow(r);
                if (row == null) continue;

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

                    if (isBlank(isbn) || isBlank(title) || isBlank(author)
                            || pubY == null || isBlank(format) || qty == null) {
                        skipped++;
                        logs.add("Dòng " + (r + 1) + " thiếu dữ liệu bắt buộc → bỏ qua");
                        continue;
                    }

                    format = format.trim().toUpperCase(Locale.ROOT);
                    if (!List.of("HARDCOVER", "PAPERBACK", "EBOOK").contains(format)) {
                        skipped++;
                        logs.add("Dòng " + (r + 1) + " format không hợp lệ: " + format);
                        continue;
                    }

                    // 1️⃣ kiểm tra trùng ISBN hoặc Title
                    if (bookExists(conn, isbn, title)) {
                        skipped++;
                        logs.add("Dòng " + (r + 1)
                            + " trùng ISBN hoặc tên sách → bỏ qua (ISBN=" + isbn + ")");
                        continue;
                    }

                    // 2️⃣ tạo / lấy tác giả
                    Integer authorId = getOrCreateAuthor(conn, author);

                    // 3️⃣ insert book
                    insertBook(conn, isbn, title, authorId, pubY, lang, pages,
                               format, publisher, cover, qty);

                    // 4️⃣ genres
                    if (!isBlank(genres)) {
                        String[] names = Arrays.stream(genres.split("[,\n]"))
                                .map(String::trim)
                                .filter(s -> !s.isEmpty())
                                .toArray(String[]::new);
                        upsertBookGenres(conn, isbn, names);
                    }

                    // 5️⃣ book item
                    if (qty != null && qty > 0) {
                        insertBookItem(conn, isbn, qty, price, dop);
                    }

                    // 6️⃣ chỉ tăng imported khi THỰC SỰ thêm mới
                    imported++;
                    logs.add("Dòng " + (r + 1) + " ✔ Thêm mới sách: " + title);

                } catch (Exception ex) {
                    errors++;
                    logs.add("Dòng " + (r + 1) + " lỗi: " + ex.getMessage());
                }
            }

            conn.commit();
        }

        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("stats", Map.of(
            "imported", imported,
            "skipped", skipped,
            "errors", errors
        ));
        result.put("logs", logs);

        return result;
    }

    // ================= helpers (COPY từ servlet cũ) =================

    private static boolean isBlank(String s) {
        return s == null || s.trim().isEmpty();
    }

    private static String getDisplay(Row row, int col) {
        Cell c = row.getCell(col, Row.MissingCellPolicy.RETURN_BLANK_AS_NULL);
        return c == null ? null : FORMATTER.formatCellValue(c).trim();
    }

    private static String getIsbn(Row row, int col) {
        String val = getDisplay(row, col);
        return val == null ? null : val.replaceAll("[^0-9]", "");
    }

    private static Integer getIntSafe(Row row, int col) {
        String s = getDisplay(row, col);
        if (s == null || s.isEmpty()) return null;
        try { return Integer.parseInt(s.replace(",", "")); }
        catch (Exception e) { return null; }
    }

    private static Double getDoubleSafe(Row row, int col) {
        String s = getDisplay(row, col);
        if (s == null || s.isEmpty()) return null;
        try { return Double.parseDouble(s.replace(",", "")); }
        catch (Exception e) { return null; }
    }

    private static LocalDate getLocalDate(Row row, int col) {
        Cell c = row.getCell(col, Row.MissingCellPolicy.RETURN_BLANK_AS_NULL);
        if (c == null) return null;

        if (c.getCellType() == CellType.NUMERIC && DateUtil.isCellDateFormatted(c)) {
            return c.getDateCellValue().toInstant()
                    .atZone(java.time.ZoneId.systemDefault()).toLocalDate();
        }

        String s = FORMATTER.formatCellValue(c).trim();
        for (DateTimeFormatter f : DATE_PARSERS) {
            try { return LocalDate.parse(s, f); } catch (Exception ignore) {}
        }
        return null;
    }

    private static String getStr(Row row, int col) {
        Cell c = row.getCell(col, Row.MissingCellPolicy.RETURN_BLANK_AS_NULL);
        return c == null ? null : FORMATTER.formatCellValue(c).trim();
    }

    private static Integer getInt(Row row, int col) {
        String s = getDisplay(row, col);
        if (s == null || s.isEmpty()) return null;
        return Integer.parseInt(s);
    }

    // ===== DB helpers (y chang servlet cũ) =====

    private static Integer getOrCreateAuthor(Connection conn, String name) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT id FROM author WHERE LOWER(name)=LOWER(?) LIMIT 1")) {
            ps.setString(1, name);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1);
        }

        try (PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO author(name) VALUES(?)", Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, name);
            ps.executeUpdate();
            ResultSet rs = ps.getGeneratedKeys();
            if (rs.next()) return rs.getInt(1);
        }
        throw new SQLException("Không tạo được tác giả: " + name);
    }

    private boolean bookExists(Connection conn, String isbn, String title) throws Exception {
        String sql =
            "SELECT 1 FROM book WHERE isbn = ? OR LOWER(title) = LOWER(?) LIMIT 1";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, isbn);
            ps.setString(2, title);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }


    private static void insertBook(Connection conn, String isbn, String title, Integer authorId,
                                   Integer pubY, String lang, Integer pages, String format,
                                   String publisher, String cover, Integer qty) throws SQLException {

        String sql = """
            INSERT INTO book
            (isbn,title,authorId,publicationYear,language,numberOfPages,
             format,publisher,coverImage,quantity,status)
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
            ps.setObject(10, qty);
            ps.executeUpdate();
        }
    }

    private static void upsertBookGenres(Connection conn, String isbn, String[] names) throws SQLException {
        Integer bookId = null;
        try (PreparedStatement ps = conn.prepareStatement("SELECT id FROM book WHERE isbn=?")) {
            ps.setString(1, isbn);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) bookId = rs.getInt(1);
        }
        if (bookId == null) throw new SQLException("Không tìm thấy book");

        for (String name : names) {
            Integer gid = null;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT id FROM genre WHERE LOWER(name)=LOWER(?) LIMIT 1")) {
                ps.setString(1, name);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) gid = rs.getInt(1);
            }
            if (gid == null) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO genre(name) VALUES(?)", Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, name);
                    ps.executeUpdate();
                    ResultSet rs = ps.getGeneratedKeys();
                    if (rs.next()) gid = rs.getInt(1);
                }
            }
            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT IGNORE INTO book_genre(book_id, genre_id) VALUES (?,?)")) {
                ps.setInt(1, bookId);
                ps.setInt(2, gid);
                ps.executeUpdate();
            }
        }
    }

    private static void insertBookItem(Connection conn, String isbn, Integer qty,
                                       Double price, LocalDate dop) throws SQLException {
        String sql = "INSERT INTO bookitem(book_isbn,price,date_of_purchase) VALUES (?,?,?)";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, isbn);
            ps.setObject(2, price);
            ps.setObject(3, dop);
            ps.executeUpdate();
        }
    }
}
