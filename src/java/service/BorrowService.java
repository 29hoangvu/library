// service/BorrowService.java
package service;

import Servlet.DBConnection;
import dto.borrow.BorrowRegisterRequest;
import dto.borrow.BorrowRegisterResult;
import dto.borrow.BorrowHistoryItem;
import dto.borrow.ReturnBorrowRequest;
import dto.borrow.ApproveBorrowRequest;
import dto.borrow.BorrowedItemDto;
import dto.borrow.RejectBorrowRequest;
import dto.borrow.ReturnBorrowAdminRequest;
import dto.borrow.ReturnBorrowResult;

import java.sql.*;
import java.time.LocalDate;
import java.util.*;

public class BorrowService {

    private static final int MAX_BORROW_LIMIT    = 3;
    private static final int DEFAULT_BORROW_DAYS = 7;
    private static final double DEFAULT_FINE_PER_INCIDENT = 5000.0;

    // ========= USER SIDE =========

    /**
     * Đăng ký mượn sách (status = Pending Approval)
     * Logic giống BorrowBookApi cũ nhưng gom vào service.
     */
    public BorrowRegisterResult registerBorrowRequest(BorrowRegisterRequest req) throws Exception {
        if (req == null) throw new IllegalArgumentException("request is null");
        if (req.userId <= 0) throw new IllegalArgumentException("userId không hợp lệ");
        if (req.isbn == null || req.isbn.trim().isEmpty()) {
            throw new IllegalArgumentException("Thiếu ISBN");
        }

        int days = (req.days > 0 ? req.days : DEFAULT_BORROW_DAYS);

        try (Connection conn = DBConnection.getConnection()) {
            // 1) Giới hạn số lượng đang mượn
            String checkSql = """
                SELECT COUNT(*) AS borrow_count
                FROM borrow
                WHERE user_id = ?
                  AND (status = 'Borrowed' OR status = 'Pending Approval')
                """;
            try (PreparedStatement ps = conn.prepareStatement(checkSql)) {
                ps.setInt(1, req.userId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next() && rs.getInt("borrow_count") >= MAX_BORROW_LIMIT) {
                        throw new IllegalStateException("LIMIT_REACHED");
                    }
                }
            }

            // 2) Lấy 1 bản vật lý theo ISBN
            Integer bookItemId = null;
            String getBookItemSql = "SELECT book_item_id FROM bookitem WHERE book_isbn = ? LIMIT 1";
            try (PreparedStatement ps = conn.prepareStatement(getBookItemSql)) {
                ps.setString(1, req.isbn.trim());
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        bookItemId = rs.getInt("book_item_id");
                    }
                }
            }
            if (bookItemId == null) {
                throw new IllegalStateException("NO_COPY_AVAILABLE");
            }

            // 3) Tạo phiếu mượn
            String borrowSql =
                "INSERT INTO borrow (book_item_id, user_id, borrowed_date, due_date, status, extended) " +
                "VALUES (?, ?, CURDATE(), DATE_ADD(CURDATE(), INTERVAL ? DAY), 'Pending Approval', 0)";
            int newId = -1;
            try (PreparedStatement ps = conn.prepareStatement(borrowSql, Statement.RETURN_GENERATED_KEYS)) {
                ps.setInt(1, bookItemId);
                ps.setInt(2, req.userId);
                ps.setInt(3, days);
                ps.executeUpdate();

                try (ResultSet keys = ps.getGeneratedKeys()) {
                    if (keys.next()) {
                        newId = keys.getInt(1);
                    }
                }
            }
            if (newId <= 0) {
                throw new SQLException("Không lấy được borrow_id mới tạo.");
            }

            BorrowRegisterResult res = new BorrowRegisterResult();
            res.borrowId   = newId;
            res.bookItemId = bookItemId;
            res.status     = "Pending Approval";
            res.days       = days;
            return res;
        }
    }

    /**
     * Lấy danh sách phiếu mượn (user hoặc admin xem tất cả).
     */
    public List<BorrowHistoryItem> listUserBorrows(int userId, boolean isAdmin) throws Exception {
        String sql =
            "SELECT br.borrow_id, b.isbn, b.title, br.borrowed_date, br.due_date, " +
            "       br.return_date, br.status " +
            "FROM borrow br " +
            "JOIN bookitem bi ON br.book_item_id = bi.book_item_id " +
            "JOIN book b ON bi.book_isbn = b.isbn " +
            (isAdmin ? "" : "WHERE br.user_id = ? ") +
            "ORDER BY br.borrowed_date DESC";

        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {

            if (!isAdmin) ps.setInt(1, userId);

            try (ResultSet rs = ps.executeQuery()) {
                List<BorrowHistoryItem> list = new ArrayList<>();
                while (rs.next()) {
                    BorrowHistoryItem item = new BorrowHistoryItem();
                    item.borrowId     = rs.getInt("borrow_id");
                    item.isbn         = rs.getString("isbn");
                    item.title        = rs.getString("title");
                    item.status       = rs.getString("status");
                    item.borrowedDate = rs.getDate("borrowed_date");
                    item.dueDate      = rs.getDate("due_date");
                    item.returnDate   = rs.getDate("return_date");
                    list.add(item);
                }
                return list;
            }
        }
    }

    /**
     * Trả sách kiểu "self-service" đơn giản (nếu bạn muốn cho user tự trả).
     * (Tuỳ bạn dùng hoặc bỏ, vì adminReturn phía dưới đã có logic đầy đủ hơn)
     */
    public boolean returnBook(ReturnBorrowRequest req) throws Exception {
        if (req == null) throw new IllegalArgumentException("request is null");
        if (req.borrowId <= 0) throw new IllegalArgumentException("borrowId không hợp lệ");

        String sql = "UPDATE borrow SET status='Returned', return_date=? " +
                     "WHERE borrow_id=? " + (req.admin ? "" : "AND user_id=?");
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {

            ps.setDate(1, java.sql.Date.valueOf(LocalDate.now()));
            ps.setInt(2, req.borrowId);
            if (!req.admin) ps.setInt(3, req.userId);

            return ps.executeUpdate() > 0;
        }
    }

    // ========= ADMIN SIDE =========

    /**
     * Admin duyệt mượn:
     * - Lấy ISBN từ bookitem
     * - FOR UPDATE quantity book
     * - Nếu quantity > 0: set status='Borrowed', quantity--
     */
    public void approveBorrow(ApproveBorrowRequest dto) throws Exception {
        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                // 1) Lấy ISBN từ bookitem
                String isbn = null;
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT book_isbn FROM bookitem WHERE book_item_id = ?")) {
                    ps.setInt(1, dto.bookItemId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            isbn = rs.getString("book_isbn");
                        }
                    }
                }
                if (isbn == null) {
                    conn.rollback();
                    throw new IllegalStateException("BOOKITEM_NOT_FOUND");
                }

                // 2) Kiểm tra số lượng, khóa row bằng FOR UPDATE
                int quantity = 0;
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT quantity FROM book WHERE isbn = ? FOR UPDATE")) {
                    ps.setString(1, isbn);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            quantity = rs.getInt("quantity");
                        }
                    }
                }
                if (quantity <= 0) {
                    conn.rollback();
                    throw new IllegalStateException("OUT_OF_STOCK");
                }

                // 3) Cập nhật phiếu mượn:
                //    - status = 'Borrowed'
                //    - borrowed_date = ngày duyệt (CURDATE())
                //    - due_date = CURDATE() + 7 ngày (hoặc DEFAULT_BORROW_DAYS)
                int rowsBorrow;
                String updateBorrowSql =
                        "UPDATE borrow " +
                        "SET status = 'Borrowed', " +
                        "    borrowed_date = CURDATE(), " +
                        "    due_date = DATE_ADD(CURDATE(), INTERVAL ? DAY) " +
                        "WHERE borrow_id = ?";
                try (PreparedStatement ps = conn.prepareStatement(updateBorrowSql)) {
                    ps.setInt(1, DEFAULT_BORROW_DAYS);
                    ps.setInt(2, dto.borrowId);
                    rowsBorrow = ps.executeUpdate();
                }

                // 4) Giảm số lượng sách trong bảng book
                int rowsBook;
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE book SET quantity = quantity - 1 WHERE isbn = ?")) {
                    ps.setString(1, isbn);
                    rowsBook = ps.executeUpdate();
                }

                if (rowsBorrow > 0 && rowsBook > 0) {
                    conn.commit();
                } else {
                    conn.rollback();
                    throw new IllegalStateException("DB_UPDATE_FAILED");
                }

            } catch (Exception e) {
                try { conn.rollback(); } catch (Exception ignore) {}
                throw e;
            } finally {
                try { conn.setAutoCommit(true); } catch (Exception ignore) {}
            }
        }
    }

    /**
     * Admin từ chối phiếu mượn.
     */
    public void rejectBorrow(RejectBorrowRequest req) throws Exception {
        if (req == null) throw new IllegalArgumentException("request is null");
        if (req.borrowId <= 0) throw new IllegalArgumentException("borrowId không hợp lệ");

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "UPDATE borrow SET status = 'Rejected' WHERE borrow_id = ?")) {
            ps.setInt(1, req.borrowId);
            int rows = ps.executeUpdate();
            if (rows == 0) {
                throw new IllegalStateException("BORROW_NOT_FOUND");
            }
        }
    }

    /**
     * Admin xác nhận trả sách:
     * - Lấy due_date, book_item_id từ borrow
     * - Tính fee nếu trả trễ (default 5000)
     * - Lấy isbn từ bookitem
     * - UPDATE borrow.set(return_date, status='Returned', fine_amount)
     * - UPDATE book.quantity++
     */
    public ReturnBorrowResult adminReturn(ReturnBorrowAdminRequest req) throws Exception {
        if (req == null) throw new IllegalArgumentException("request is null");
        if (req.borrowId <= 0) throw new IllegalArgumentException("borrowId không hợp lệ");

        ReturnBorrowResult result = new ReturnBorrowResult();

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                // 1) Lấy due_date, book_item_id
                String selectSql = "SELECT due_date, book_item_id FROM borrow WHERE borrow_id = ?";
                LocalDate dueDate = null;
                int bookItemId = -1;
                try (PreparedStatement ps = conn.prepareStatement(selectSql)) {
                    ps.setInt(1, req.borrowId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            java.sql.Date d = rs.getDate("due_date");
                            if (d != null) dueDate = d.toLocalDate();
                            bookItemId = rs.getInt("book_item_id");
                        }
                    }
                }
                if (bookItemId <= 0) {
                    conn.rollback();
                    throw new IllegalStateException("BORROW_NOT_FOUND");
                }

                LocalDate returnDate = LocalDate.now();
                double fineAmount = 0;

                if (dueDate != null && returnDate.isAfter(dueDate)) {
                    fineAmount = DEFAULT_FINE_PER_INCIDENT;
                }

                // 2) Lấy isbn từ bookitem
                String bookIsbn = null;
                String getBookSql = "SELECT book_isbn FROM bookitem WHERE book_item_id = ?";
                try (PreparedStatement ps = conn.prepareStatement(getBookSql)) {
                    ps.setInt(1, bookItemId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            bookIsbn = rs.getString("book_isbn");
                        }
                    }
                }
                if (bookIsbn == null) {
                    conn.rollback();
                    throw new IllegalStateException("BOOKITEM_NOT_FOUND");
                }

                // 3) UPDATE borrow
                String updateBorrowSql =
                        "UPDATE borrow SET return_date = NOW(), status = 'Returned', fine_amount = ? WHERE borrow_id = ?";
                int updatedBorrow;
                try (PreparedStatement ps = conn.prepareStatement(updateBorrowSql)) {
                    ps.setDouble(1, fineAmount);
                    ps.setInt(2, req.borrowId);
                    updatedBorrow = ps.executeUpdate();
                }

                if (updatedBorrow <= 0) {
                    conn.rollback();
                    throw new SQLException("Không cập nhật được trạng thái mượn sách.");
                }

                // 4) UPDATE book.quantity++
                String updateBookSql = "UPDATE book SET quantity = quantity + 1 WHERE isbn = ?";
                try (PreparedStatement ps = conn.prepareStatement(updateBookSql)) {
                    ps.setString(1, bookIsbn);
                    ps.executeUpdate();
                }

                conn.commit();

                result.success = true;
                result.fineAmount = fineAmount;
                result.message =
                        "Xác nhận trả sách thành công"
                        + (fineAmount > 0 ? (", phạt " + (long)fineAmount + " VNĐ") : "");

                return result;
            } catch (Exception e) {
                try { conn.rollback(); } catch (Exception ignore) {}
                throw e;
            } finally {
                try { conn.setAutoCommit(true); } catch (Exception ignore) {}
            }
        }
    }
    /**
     * Lấy danh sách borrow (cả Borrowed/Returned/Overdue, v.v.) của 1 user
     */
    public List<BorrowedItemDto> listBorrowedByUser(int userId) throws SQLException {
        List<BorrowedItemDto> out = new ArrayList<>();

        try (Connection c = DBConnection.getConnection()) {
            String sql =
                "SELECT br.borrow_id, b.isbn, b.title, " +
                "       br.borrowed_date, br.due_date, br.return_date, br.status " +
                "FROM borrow br " +
                "JOIN bookitem bi ON br.book_item_id = bi.book_item_id " +
                "JOIN book b ON bi.book_isbn = b.isbn " +
                "WHERE br.user_id=? " +
                "ORDER BY br.borrowed_date DESC";

            try (PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setInt(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        BorrowedItemDto dto = new BorrowedItemDto();
                        dto.borrowId    = rs.getInt("borrow_id");
                        dto.isbn        = rs.getString("isbn");
                        dto.title       = rs.getString("title");
                        dto.borrowedDate= rs.getDate("borrowed_date");
                        dto.dueDate     = rs.getDate("due_date");
                        dto.returnDate  = rs.getDate("return_date");
                        dto.status      = rs.getString("status");
                        out.add(dto);
                    }
                }
            }
        }

        return out;
    }
}
