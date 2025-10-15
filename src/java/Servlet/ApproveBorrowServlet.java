package Servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

public class ApproveBorrowServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // tất cả request từ JS dùng POST
        String action = safe(request.getParameter("action"));
        try {
            switch (action) {
                case "approve":
                    handleApprove(request, response);
                    break;
                case "reject":
                    handleReject(request, response);
                    break;
                default:
                    writeJson(response, 400, false, "Thiếu hoặc sai tham số action");
            }
        } catch (Exception e) {
            e.printStackTrace();
            writeJson(response, 500, false, "Lỗi hệ thống! Vui lòng thử lại sau.");
        }
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        // Không hỗ trợ GET cho API này
        writeJson(resp, 405, false, "Phương thức không được hỗ trợ");
    }

    private void handleApprove(HttpServletRequest request, HttpServletResponse response) throws Exception {
        String borrowIdStr = request.getParameter("borrowId");
        String bookItemIdStr = request.getParameter("bookItemId");

        if (isBlank(borrowIdStr) || isBlank(bookItemIdStr)) {
            writeJson(response, 400, false, "Thiếu dữ liệu!");
            return;
        }

        int borrowId = Integer.parseInt(borrowIdStr);
        int bookItemId = Integer.parseInt(bookItemIdStr);

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            // 1) Lấy ISBN từ bookitem
            String isbn = null;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT book_isbn FROM bookitem WHERE book_item_id = ?")) {
                ps.setInt(1, bookItemId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) isbn = rs.getString("book_isbn");
                }
            }
            if (isbn == null) {
                conn.rollback();
                writeJson(response, 404, false, "Không tìm thấy sách.");
                return;
            }

            // 2) Kiểm tra số lượng
            int quantity = 0;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT quantity FROM book WHERE isbn = ? FOR UPDATE")) {
                ps.setString(1, isbn);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) quantity = rs.getInt("quantity");
                }
            }
            if (quantity <= 0) {
                conn.rollback();
                writeJson(response, 409, false, "Sách đã hết, không thể duyệt!");
                return;
            }

            // 3) Cập nhật trạng thái phiếu mượn -> 'Borrowed' (hoặc 'Approved' tuỳ hệ thống của bạn)
            int rowsBorrow;
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE borrow SET status = 'Borrowed' WHERE borrow_id = ?")) {
                ps.setInt(1, borrowId);
                rowsBorrow = ps.executeUpdate();
            }

            // 4) Giảm số lượng sách
            int rowsBook;
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE book SET quantity = quantity - 1 WHERE isbn = ?")) {
                ps.setString(1, isbn);
                rowsBook = ps.executeUpdate();
            }

            if (rowsBorrow > 0 && rowsBook > 0) {
                conn.commit();
                writeJson(response, 200, true, "Duyệt mượn thành công!");
            } else {
                conn.rollback();
                writeJson(response, 500, false, "Lỗi cập nhật dữ liệu.");
            }
        }
    }

    private void handleReject(HttpServletRequest request, HttpServletResponse response) throws Exception {
        String borrowIdStr = request.getParameter("borrowId");
        if (isBlank(borrowIdStr)) {
            writeJson(response, 400, false, "Thiếu borrowId!");
            return;
        }
        int borrowId = Integer.parseInt(borrowIdStr);

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "UPDATE borrow SET status = 'Rejected' WHERE borrow_id = ?")) {
            ps.setInt(1, borrowId);
            int rows = ps.executeUpdate();
            if (rows > 0) {
                writeJson(response, 200, true, "Từ chối yêu cầu thành công!");
            } else {
                writeJson(response, 404, false, "Không tìm thấy yêu cầu.");
            }
        }
    }

    // ===== util =====
    private static void writeJson(HttpServletResponse response, int status, boolean success, String message) throws IOException {
        response.setStatus(status);
        response.setCharacterEncoding("UTF-8");
        response.setContentType("application/json; charset=UTF-8");
        // có thể thêm no-cache nếu muốn
        response.setHeader("Cache-Control", "no-store");
        try (PrintWriter out = response.getWriter()) {
            // đơn giản hoá, không phụ thuộc lib JSON
            out.print("{\"success\":" + success + ",\"message\":\"" + escapeJson(message) + "\"}");
        }
    }

    private static String safe(String s) { return s == null ? "" : s; }
    private static boolean isBlank(String s) { return s == null || s.trim().isEmpty(); }
    private static String escapeJson(String s) {
        return s == null ? "" : s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n");
    }
}
