// service/BookService.java
package service;

import Servlet.DBConnection;
import dto.book.BookOperationResult;
import dto.books.DeleteBookRequest;
import dto.books.RestoreBookRequest;
import java.sql.*;
import java.util.*;

public class BookService {
    public Map<String,Object> getOne(String isbn) throws Exception {
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(
                 "SELECT isbn, title, publisher, publicationYear, language, numberOfPages, format FROM book WHERE isbn=?")) {
            ps.setString(1, isbn);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                Map<String,Object> m = new LinkedHashMap<>();
                m.put("isbn", rs.getString("isbn"));
                m.put("title", rs.getString("title"));
                m.put("publisher", rs.getString("publisher"));
                m.put("publicationYear", rs.getInt("publicationYear"));
                m.put("language", rs.getString("language"));
                m.put("numberOfPages", rs.getInt("numberOfPages"));
                m.put("format", rs.getString("format"));
                return m;
            }
        }
    }

    public List<Map<String,Object>> search(String q, int page, int size) throws Exception {
        String like = "%" + (q == null ? "" : q.trim()) + "%";
        int off = (page - 1) * size;
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(
                 "SELECT isbn, title, publisher, publicationYear FROM book " +
                 "WHERE title LIKE ? OR isbn LIKE ? ORDER BY title LIMIT ? OFFSET ?")) {
            ps.setString(1, like);
            ps.setString(2, like);
            ps.setInt(3, size);
            ps.setInt(4, off);
            try (ResultSet rs = ps.executeQuery()) {
                List<Map<String,Object>> list = new ArrayList<>();
                while (rs.next()) {
                    Map<String,Object> m = new LinkedHashMap<>();
                    m.put("isbn", rs.getString("isbn"));
                    m.put("title", rs.getString("title"));
                    m.put("publisher", rs.getString("publisher"));
                    m.put("publicationYear", rs.getInt("publicationYear"));
                    list.add(m);
                }
                return list;
            }
        }
    }

    public String create(Map<String,Object> b) throws Exception {
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(
                 "INSERT INTO book(isbn,title,publisher,publicationYear,language,numberOfPages,format) VALUES (?,?,?,?,?,?,?)")) {
            ps.setString(1, (String)b.get("isbn"));
            ps.setString(2, (String)b.get("title"));
            ps.setString(3, (String)b.get("publisher"));
            ps.setObject(4, b.get("publicationYear"));
            ps.setString(5, (String)b.get("language"));
            ps.setObject(6, b.get("numberOfPages"));
            ps.setString(7, (String)b.get("format"));
            ps.executeUpdate();
            return (String)b.get("isbn");
        }
    }
    /**
     * Đánh dấu sách là DELETED (soft delete)
     */
    public BookOperationResult deleteBook(DeleteBookRequest req) throws SQLException {
        BookOperationResult result = new BookOperationResult();
        
        if (req == null || req.isbn == null || req.isbn.trim().isEmpty()) {
            result.success = false;
            result.code = "INVALID_ISBN";
            result.message = "ISBN không hợp lệ";
            return result;
        }

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);
            
            try {
                // 1) Kiểm tra sách có tồn tại không
                String checkExistSql = "SELECT status FROM book WHERE isbn = ?";
                String currentStatus = null;
                
                try (PreparedStatement ps = conn.prepareStatement(checkExistSql)) {
                    ps.setString(1, req.isbn);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            currentStatus = rs.getString("status");
                        }
                    }
                }
                
                if (currentStatus == null) {
                    conn.rollback();
                    result.success = false;
                    result.code = "NOT_FOUND";
                    result.message = "Không tìm thấy sách với ISBN: " + req.isbn;
                    return result;
                }
                
                if ("DELETED".equalsIgnoreCase(currentStatus)) {
                    conn.rollback();
                    result.success = false;
                    result.code = "ALREADY_DELETED";
                    result.message = "Sách đã được đánh dấu xóa trước đó";
                    return result;
                }

                // 2) Kiểm tra sách có đang được mượn không
                String checkBorrowSql = """
                    SELECT COUNT(*) AS cnt FROM borrow b
                    JOIN bookitem bi ON b.book_item_id = bi.book_item_id
                    WHERE bi.book_isbn = ? 
                      AND b.status IN ('Borrowed', 'Pending Approval')
                """;
                
                try (PreparedStatement ps = conn.prepareStatement(checkBorrowSql)) {
                    ps.setString(1, req.isbn);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next() && rs.getInt("cnt") > 0) {
                            conn.rollback();
                            result.success = false;
                            result.code = "BORROWED";
                            result.message = "Không thể xóa! Sách đang được mượn hoặc chờ duyệt.";
                            return result;
                        }
                    }
                }

                // 3) Đánh dấu sách là DELETED
                String updateSql = "UPDATE book SET status = 'DELETED' WHERE isbn = ?";
                int rows;
                
                try (PreparedStatement ps = conn.prepareStatement(updateSql)) {
                    ps.setString(1, req.isbn);
                    rows = ps.executeUpdate();
                }

                if (rows > 0) {
                    conn.commit();
                    result.success = true;
                    result.code = "SUCCESS";
                    result.message = "Sách đã được đánh dấu xóa thành công";
                } else {
                    conn.rollback();
                    result.success = false;
                    result.code = "UPDATE_FAILED";
                    result.message = "Không thể cập nhật trạng thái sách";
                }
                
                return result;
                
            } catch (SQLException e) {
                try { conn.rollback(); } catch (SQLException ignore) {}
                throw e;
            } finally {
                try { conn.setAutoCommit(true); } catch (SQLException ignore) {}
            }
        }
    }

    /**
     * Khôi phục sách từ DELETED về ACTIVE
     */
    public BookOperationResult restoreBook(RestoreBookRequest req) throws SQLException {
        BookOperationResult result = new BookOperationResult();
        
        if (req == null || req.isbn == null || req.isbn.trim().isEmpty()) {
            result.success = false;
            result.code = "INVALID_ISBN";
            result.message = "ISBN không hợp lệ";
            return result;
        }

        try (Connection conn = DBConnection.getConnection()) {
            // Kiểm tra sách có ở trạng thái DELETED không
            String checkSql = "SELECT status FROM book WHERE isbn = ?";
            String currentStatus = null;
            
            try (PreparedStatement ps = conn.prepareStatement(checkSql)) {
                ps.setString(1, req.isbn);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        currentStatus = rs.getString("status");
                    }
                }
            }
            
            if (currentStatus == null) {
                result.success = false;
                result.code = "NOT_FOUND";
                result.message = "Không tìm thấy sách với ISBN: " + req.isbn;
                return result;
            }
            
            if (!"DELETED".equalsIgnoreCase(currentStatus)) {
                result.success = false;
                result.code = "NOT_DELETED";
                result.message = "Sách không ở trạng thái DELETED";
                return result;
            }

            // Khôi phục về ACTIVE
            String updateSql = "UPDATE book SET status = 'ACTIVE' WHERE isbn = ?";
            int rows;
            
            try (PreparedStatement ps = conn.prepareStatement(updateSql)) {
                ps.setString(1, req.isbn);
                rows = ps.executeUpdate();
            }

            if (rows > 0) {
                result.success = true;
                result.code = "SUCCESS";
                result.message = "Khôi phục sách thành công";
            } else {
                result.success = false;
                result.code = "UPDATE_FAILED";
                result.message = "Không thể khôi phục sách";
            }
            
            return result;
        }
    }

    /**
     * Lấy danh sách sách đã xóa
     */
    public java.util.List<java.util.Map<String, Object>> getDeletedBooks() throws SQLException {
        java.util.List<java.util.Map<String, Object>> books = new java.util.ArrayList<>();
        
        String sql = """
            SELECT b.isbn, b.title, b.status
            FROM book b
            WHERE UPPER(b.status) = 'DELETED'
            ORDER BY b.title ASC
        """;
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            
            while (rs.next()) {
                java.util.Map<String, Object> book = new java.util.HashMap<>();
                book.put("isbn", rs.getString("isbn"));
                book.put("title", rs.getString("title"));
                book.put("status", rs.getString("status"));
                books.add(book);
            }
        }
        
        return books;
    }
}
