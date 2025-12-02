package service;

import dto.books.BookUpdateRequest;
import Servlet.DBConnection;

import java.sql.*;
import java.util.Optional;

public class BookUpdateService {

    public void updateBook(BookUpdateRequest dto) throws Exception {
        if (dto == null || dto.isbn == null || dto.isbn.isBlank()) {
            throw new IllegalArgumentException("MISSING_ISBN");
        }

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            // 1) Tìm book_id theo ISBN
            Integer bookId = null;
            try (PreparedStatement ps = conn.prepareStatement("SELECT id FROM book WHERE isbn=?")) {
                ps.setString(1, dto.isbn);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        bookId = rs.getInt(1);
                    }
                }
            }
            if (bookId == null) {
                throw new IllegalArgumentException("BOOK_NOT_FOUND");
            }

            // 2) Author
            int authorID = getOrInsertAuthor(conn, dto.authorName);

            // 3) Ảnh bìa
            String imagePath = Optional.ofNullable(dto.coverImagePath).orElse("");

            // 4) UPDATE book (không đụng format nếu chưa bật)
            String status = saneStatus(dto.status);
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE book SET title=?, publisher=?, publicationYear=?, language=?, " +
                            "numberOfPages=?, quantity=?, authorID=?, coverImage=?, status=? WHERE isbn=?")) {
                ps.setString(1, dto.title);
                ps.setString(2, dto.publisher);
                ps.setInt(3, dto.publicationYear);
                ps.setString(4, dto.language);
                ps.setInt(5, dto.numberOfPages);
                ps.setInt(6, dto.quantity);
                ps.setInt(7, authorID);
                ps.setString(8, imagePath);
                ps.setString(9, status);
                ps.setString(10, dto.isbn);
                ps.executeUpdate();
            }

            // 5) Format nếu bật chỉnh sửa
            if (dto.formatEditEnabled && dto.format != null && !dto.format.isBlank()) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE book SET format=? WHERE isbn=?")) {
                    ps.setString(1, dto.format.trim());
                    ps.setString(2, dto.isbn);
                    ps.executeUpdate();
                }
            }

            // 6) book_description
            if (dto.description != null) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO book_description(id,isbn,description) VALUES (?,?,?) " +
                                "ON DUPLICATE KEY UPDATE description=?")) {
                    ps.setInt(1, bookId);
                    ps.setString(2, dto.isbn);
                    ps.setString(3, dto.description);
                    ps.setString(4, dto.description);
                    ps.executeUpdate();
                }
            }

            // 7) Genres
            try (PreparedStatement del = conn.prepareStatement(
                    "DELETE FROM book_genre WHERE book_id=?")) {
                del.setInt(1, bookId);
                del.executeUpdate();
            }

            if (dto.genreIdsCsv != null && !dto.genreIdsCsv.isBlank()) {
                for (String s : dto.genreIdsCsv.split(",")) {
                    String t = s.trim();
                    if (!t.isEmpty()) {
                        insertBookGenre(conn, bookId, Integer.parseInt(t));
                    }
                }
            }

            if (dto.newGenresCsv != null && !dto.newGenresCsv.isBlank()) {
                for (String name : dto.newGenresCsv.split(",")) {
                    String t = name.trim();
                    if (t.isEmpty()) continue;
                    int gid = getOrInsertGenre(conn, t);
                    insertBookGenre(conn, bookId, gid);
                }
            }

            conn.commit();
        }
    }

    // ===== Helpers nội bộ =====

    private static String saneStatus(String s) {
        if (s == null) return "ACTIVE";
        return "DELETED".equalsIgnoreCase(s) ? "DELETED" : "ACTIVE";
    }

    private static int getOrInsertAuthor(Connection conn, String name) throws SQLException {
        if (name == null || name.isBlank()) {
            throw new SQLException("Thiếu tên tác giả");
        }
        try (PreparedStatement s = conn.prepareStatement(
                "SELECT id FROM author WHERE name=?")) {
            s.setString(1, name);
            try (ResultSet r = s.executeQuery()) {
                if (r.next()) return r.getInt(1);
            }
        }
        try (PreparedStatement ins = conn.prepareStatement(
                "INSERT INTO author(name) VALUES (?)",
                Statement.RETURN_GENERATED_KEYS)) {
            ins.setString(1, name);
            ins.executeUpdate();
            try (ResultSet k = ins.getGeneratedKeys()) {
                if (k.next()) return k.getInt(1);
            }
        }
        throw new SQLException("Không thể thêm/tìm tác giả");
    }

    private static int getOrInsertGenre(Connection conn, String name) throws SQLException {
        try (PreparedStatement s = conn.prepareStatement(
                "SELECT id FROM genre WHERE name=?")) {
            s.setString(1, name);
            try (ResultSet r = s.executeQuery()) {
                if (r.next()) return r.getInt(1);
            }
        }
        try (PreparedStatement ins = conn.prepareStatement(
                "INSERT INTO genre(name) VALUES (?)",
                Statement.RETURN_GENERATED_KEYS)) {
            ins.setString(1, name);
            ins.executeUpdate();
            try (ResultSet k = ins.getGeneratedKeys()) {
                if (k.next()) return k.getInt(1);
            }
        }
        throw new SQLException("Không thể thêm/tìm thể loại");
    }

    private static void insertBookGenre(Connection conn, int bookId, int genreId) throws SQLException {
        try (PreparedStatement ins = conn.prepareStatement(
                "INSERT INTO book_genre(book_id, genre_id) VALUES (?, ?)")) {
            ins.setInt(1, bookId);
            ins.setInt(2, genreId);
            ins.executeUpdate();
        }
    }
}
