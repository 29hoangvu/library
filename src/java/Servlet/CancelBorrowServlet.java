package Servlet;

import java.io.IOException;
import java.sql.*;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import Data.Users;

public class CancelBorrowServlet extends HttpServlet {
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession();
        Users user = (Users) session.getAttribute("user");

        if (user == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String borrowId = request.getParameter("borrow_id");

        if (borrowId == null || borrowId.trim().isEmpty()) {
            response.sendRedirect("borrowedBooks.jsp?error=missing_id");
            return;
        }

        try (Connection conn = DBConnection.getConnection()) {
            // Kiểm tra borrow_id có thuộc về user không & trạng thái có phải "Chờ duyệt" không
            String checkSql = "SELECT status FROM borrow WHERE borrow_id = ? AND user_id = ?";
            PreparedStatement checkStmt = conn.prepareStatement(checkSql);
            checkStmt.setInt(1, Integer.parseInt(borrowId));
            checkStmt.setInt(2, user.getId());
            ResultSet rs = checkStmt.executeQuery();

            if (rs.next() && "Pending Approval".equals(rs.getString("status"))) {
                // Xóa bản ghi nếu đang "Chờ duyệt"
                String deleteSql = "DELETE FROM borrow WHERE borrow_id = ?";
                PreparedStatement deleteStmt = conn.prepareStatement(deleteSql);
                deleteStmt.setInt(1, Integer.parseInt(borrowId));
                int rows = deleteStmt.executeUpdate();

                if (rows > 0) {
                    sendResponse(response, "Hủy đăng ký mượn thành công!!");
                } else {
                    sendResponse(response, "Hủy thất bại!!");
                }
            } else {
                sendResponse(response, "Lỗi");
            }
        } catch (SQLException e) {
            e.printStackTrace();
            sendResponse(response, "Lỗi cơ sở dữ liệu!");
        }
    }
    private void sendResponse(HttpServletResponse response, String message) throws IOException {
        response.setContentType("text/html; charset=UTF-8");
        response.getWriter().println("<script>alert('" + message + "'); window.location.href='user/borrowedBooks.jsp';</script>");
    }
}
