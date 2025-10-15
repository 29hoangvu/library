package Servlet;

import java.io.IOException;
import java.sql.*;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import Data.Users;

public class BorrowBookServlet extends HttpServlet {
    private static final int MAX_BORROW_LIMIT = 3;
    private static final int DEFAULT_BORROW_DAYS = 7;

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        doPost(request, response);
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession();
        Users user = (Users) session.getAttribute("user");

        if (user == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String isbn = request.getParameter("isbn");

        if (isbn == null || isbn.trim().isEmpty()) {
            sendResponse(response, "Lỗi: Thiếu thông tin sách!");
            return;
        }

        try (Connection conn = DBConnection.getConnection()) {

            // 1. Kiểm tra số sách đang mượn + chờ duyệt
            String checkSql = "SELECT COUNT(*) AS borrow_count FROM borrow " +
                              "WHERE user_id = ? AND (status = 'Borrowed' OR status = 'Pending Approval')";
            PreparedStatement checkStmt = conn.prepareStatement(checkSql);
            checkStmt.setInt(1, user.getId());
            ResultSet rs = checkStmt.executeQuery();

            if (rs.next() && rs.getInt("borrow_count") >= MAX_BORROW_LIMIT) {
                sendResponse(response, "Bạn đã đạt giới hạn mượn sách! Vui lòng trả bớt để tiếp tục mượn.");
                return;
            }

            // 2. Lấy 1 bản vật lý còn sẵn
            String getBookItemSql = "SELECT book_item_id FROM bookitem WHERE book_isbn = ? "; // Lấy 1 bản còn sẵn
            PreparedStatement getBookItemStmt = conn.prepareStatement(getBookItemSql);
            getBookItemStmt.setString(1, isbn);
            ResultSet bookItemRs = getBookItemStmt.executeQuery();

            int bookItemId;
            if (bookItemRs.next()) {
                bookItemId = bookItemRs.getInt("book_item_id"); // Bây giờ mới có column book_item_id
            } else {
                sendResponse(response, "Không còn bản vật lý nào của sách này sẵn sàng để mượn!");
                return;
            }


            // 3. Đăng ký mượn sách
            String borrowSql = "INSERT INTO borrow (book_item_id, user_id, borrowed_date, due_date, status) " +
                               "VALUES (?, ?, CURDATE(), DATE_ADD(CURDATE(), INTERVAL ? DAY), 'Pending Approval')";
            PreparedStatement borrowStmt = conn.prepareStatement(borrowSql);
            borrowStmt.setInt(1, bookItemId);
            borrowStmt.setInt(2, user.getId());
            borrowStmt.setInt(3, DEFAULT_BORROW_DAYS);

            int rows = borrowStmt.executeUpdate();
            if (rows > 0) {
                sendResponse(response, "Đăng ký mượn thành công! Vui lòng chờ duyệt.");
            } else {
                sendResponse(response, "Lỗi: Không thể đăng ký mượn sách!");
            }

        } catch (SQLException e) {
            e.printStackTrace();
            sendResponse(response, "Lỗi hệ thống! Vui lòng thử lại sau.");
        }
    }

    private void sendResponse(HttpServletResponse response, String message) throws IOException {
        response.setContentType("text/html; charset=UTF-8");
        response.getWriter().println("<script>alert('" + message + "'); window.history.back();</script>");
    }
}
