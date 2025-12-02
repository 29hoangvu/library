// service/AdminBookService.java
package service.admin;

import Servlet.DBConnection;
import dto.AdminBookCreateRequest;
import dto.EbookAssetInfo;

import java.sql.*;
import java.time.LocalDate;

public class AdminBookService {

    public int createBook(AdminBookCreateRequest r) throws Exception {
        if (r == null) throw new IllegalArgumentException("request is null");
        if (isBlank(r.isbn) || isBlank(r.title) || isBlank(r.format) || r.dateOfPurchase == null) {
            throw new IllegalArgumentException("Thiếu dữ liệu bắt buộc (isbn/title/format/dateOfPurchase)");
        }

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            try {
                // ---- 1) Tác giả ----
                int authorId = resolveAuthor(conn, r.authorIdParam, r.authorName, r.isNewAuthor);

                // ---- 2) Thêm book ----
                int bookId = insertBook(conn, r, authorId);

                // ---- 3) Ghi nhận lô nhập (bookitem) ----
                insertBookItem(conn, r.isbn, r.price, r.dateOfPurchase);

                // ---- 4) Ghi thông tin ebook (nếu có) ----
                if ("EBOOK".equalsIgnoreCase(r.format) && r.ebookAsset != null) {
                    upsertEbookAsset(conn, r.isbn, r.ebookAsset);
                }

                // ---- 5) Gán genre ----
                attachGenres(conn, bookId, r.genreIdsCsv, r.newGenresCsv);

                conn.commit();
                return bookId;
            } catch (Exception e) {
                try { conn.rollback(); } catch (Exception ignore) {}
                throw e;
            } finally {
                try { conn.setAutoCommit(true); } catch (Exception ignore) {}
            }
        }
    }

    // ================== Helpers DB ==================

    private int resolveAuthor(Connection conn, String authorIdParam, String authorName, String isNewAuthor) throws SQLException {
        boolean wantNewAuthor = "true".equalsIgnoreCase(isNewAuthor)
                || ((isBlank(authorIdParam)) && !isBlank(authorName));

        if (wantNewAuthor) {
            if (isBlank(authorName)) {
                throw new SQLException("Tên tác giả mới trống.");
            }
            return getOrInsertAuthor(conn, authorName.trim());
        }

        if (!isBlank(authorIdParam)) {
            try {
                return Integer.parseInt(authorIdParam.trim());
            } catch (NumberFormatException e) {
                throw new SQLException("authorId không hợp lệ.", e);
            }
        }

        throw new SQLException("Không xác định được tác giả.");
    }

    private int insertBook(Connection conn, AdminBookCreateRequest r, int authorId) throws SQLException {
        String imagePath = (isBlank(r.coverImagePath) ? "images/default-cover.jpg" : r.coverImagePath);

        String sqlBook = "INSERT INTO book (isbn, title, publisher, publicationYear, language, numberOfPages, format, authorId, coverImage, quantity, status) "
                       + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'ACTIVE')";
        try (PreparedStatement ps = conn.prepareStatement(sqlBook, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, r.isbn);
            ps.setString(2, r.title);
            ps.setString(3, r.publisher);
            ps.setInt(4, r.publicationYear);
            ps.setString(5, r.language);
            ps.setInt(6, r.numberOfPages);
            ps.setString(7, r.format);
            ps.setInt(8, authorId);
            ps.setString(9, imagePath);
            ps.setInt(10, r.quantity);
            ps.executeUpdate();

            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) return keys.getInt(1);
            }
        }
        throw new SQLException("Không lấy được book.id sau khi insert.");
    }

    private void insertBookItem(Connection conn, String isbn, double price, LocalDate date) throws SQLException {
        String sqlBookItem = "INSERT INTO bookitem (book_isbn, price, date_of_purchase) VALUES (?, ?, ?)";
        try (PreparedStatement ps = conn.prepareStatement(sqlBookItem)) {
            ps.setString(1, isbn);
            ps.setDouble(2, price);
            ps.setDate(3, java.sql.Date.valueOf(date));
            ps.executeUpdate();
        }
    }

    private void upsertEbookAsset(Connection conn, String isbn, EbookAssetInfo e) throws SQLException {
        String sqlE = "INSERT INTO ebook_asset (book_isbn, file_path, mime_type, file_size, checksum_md5) " +
                      "VALUES (?, ?, ?, ?, ?) " +
                      "ON DUPLICATE KEY UPDATE " +
                      "  file_path = VALUES(file_path), " +
                      "  mime_type = VALUES(mime_type), " +
                      "  file_size = VALUES(file_size), " +
                      "  checksum_md5 = VALUES(checksum_md5)";
        try (PreparedStatement ps = conn.prepareStatement(sqlE)) {
            ps.setString(1, isbn);
            ps.setString(2, e.filePath);
            ps.setString(3, e.mimeType);
            ps.setLong(4, e.fileSize);
            ps.setString(5, e.checksumMd5);
            ps.executeUpdate();
        }
    }

    private void attachGenres(Connection conn, int bookId, String genreIdsCsv, String newGenresCsv) throws SQLException {
        if (!isBlank(genreIdsCsv)) {
            for (String s : genreIdsCsv.split(",")) {
                if (isBlank(s)) continue;
                int gid = Integer.parseInt(s.trim());
                insertBookGenreIfAbsent(conn, bookId, gid);
            }
        }

        if (!isBlank(newGenresCsv)) {
            for (String name : newGenresCsv.split(",")) {
                String trimmed = name.trim();
                if (trimmed.isEmpty()) continue;
                int gid = getOrInsertGenre(conn, trimmed);
                insertBookGenreIfAbsent(conn, bookId, gid);
            }
        }
    }

    private int getOrInsertAuthor(Connection conn, String authorName) throws SQLException {
        try (PreparedStatement s = conn.prepareStatement("SELECT id FROM author WHERE name = ?")) {
            s.setString(1, authorName);
            try (ResultSet rs = s.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        try (PreparedStatement ins = conn.prepareStatement(
                "INSERT INTO author(name) VALUES (?)", Statement.RETURN_GENERATED_KEYS)) {
            ins.setString(1, authorName);
            ins.executeUpdate();
            try (ResultSet keys = ins.getGeneratedKeys()) {
                if (keys.next()) return keys.getInt(1);
            }
        }
        throw new SQLException("Không thể thêm/tìm tác giả.");
    }

    private int getOrInsertGenre(Connection conn, String name) throws SQLException {
        try (PreparedStatement s = conn.prepareStatement("SELECT id FROM genre WHERE name = ?")) {
            s.setString(1, name);
            try (ResultSet rs = s.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        try (PreparedStatement ins = conn.prepareStatement(
                "INSERT INTO genre(name) VALUES (?)", Statement.RETURN_GENERATED_KEYS)) {
            ins.setString(1, name);
            ins.executeUpdate();
            try (ResultSet keys = ins.getGeneratedKeys()) {
                if (keys.next()) return keys.getInt(1);
            }
        }
        throw new SQLException("Không thể thêm/tìm thể loại.");
    }

    private void insertBookGenreIfAbsent(Connection conn, int bookId, int genreId) throws SQLException {
        try (PreparedStatement chk = conn.prepareStatement(
                "SELECT 1 FROM book_genre WHERE book_id = ? AND genre_id = ?")) {
            chk.setInt(1, bookId);
            chk.setInt(2, genreId);
            try (ResultSet rs = chk.executeQuery()) {
                if (rs.next()) return;
            }
        }
        try (PreparedStatement ins = conn.prepareStatement(
                "INSERT INTO book_genre(book_id, genre_id) VALUES (?, ?)")) {
            ins.setInt(1, bookId);
            ins.setInt(2, genreId);
            ins.executeUpdate();
        }
    }

    private static boolean isBlank(String s) {
        return s == null || s.trim().isEmpty();
    }
}
