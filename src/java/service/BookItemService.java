// src/main/java/service/BookItemService.java
package service;

import Servlet.DBConnection;
import dto.bookitem.BookItemRackUpdateRequest;
import dto.bookitem.BookItemRackUpdateResult;

import java.sql.*;

public class BookItemService {

    /**
     * Cập nhật rack cho tất cả bản ghi bookitem có book_isbn tương ứng.
     *
     * Ném IllegalStateException với các code:
     *  - "BOOK_NOT_FOUND"
     *  - "BOOKITEM_NOT_FOUND"
     *  - "RACK_NOT_FOUND"
     *  - "UPDATE_FAILED"
     */
    public BookItemRackUpdateResult updateRack(BookItemRackUpdateRequest dto) throws Exception {
        try (Connection conn = DBConnection.getConnection()) {

            // 1) Chuẩn hoá: lấy ISBN từ book (ưu tiên khớp isbn, nếu không khớp theo title)
            String isbn = findIsbn(conn, dto.bookId);
            if (isbn == null) {
                throw new IllegalStateException("BOOK_NOT_FOUND");
            }

            // 2) Kiểm tra sách đã có trong bookitem chưa
            if (!bookItemExists(conn, isbn)) {
                throw new IllegalStateException("BOOKITEM_NOT_FOUND");
            }

            // 3) Kiểm tra kệ tồn tại
            if (!rackExists(conn, dto.rackId)) {
                throw new IllegalStateException("RACK_NOT_FOUND");
            }

            // 4) UPDATE rack_id
            int n;
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE bookitem SET rack_id = ? WHERE book_isbn = ?")) {
                ps.setInt(1, dto.rackId);
                ps.setString(2, isbn);
                n = ps.executeUpdate();
            }

            if (n == 0) {
                throw new IllegalStateException("UPDATE_FAILED");
            }

            BookItemRackUpdateResult res = new BookItemRackUpdateResult();
            res.ok = true;
            res.message = "Cập nhật vị trí kệ thành công!";
            res.isbn = isbn;
            res.rackId = dto.rackId;
            res.updated = true;
            return res;
        }
    }

    // ===== helpers DB-level =====

    private String findIsbn(Connection conn, String bookId) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT isbn FROM book WHERE isbn = ? OR title = ? LIMIT 1")) {
            ps.setString(1, bookId);
            ps.setString(2, bookId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getString(1) : null;
            }
        }
    }

    private boolean bookItemExists(Connection conn, String isbn) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT 1 FROM bookitem WHERE book_isbn = ? LIMIT 1")) {
            ps.setString(1, isbn);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private boolean rackExists(Connection conn, int rackId) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT 1 FROM rack WHERE rack_id = ?")) {
            ps.setInt(1, rackId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }
    
}
