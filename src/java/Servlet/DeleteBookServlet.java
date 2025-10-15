// KHÔNG xóa bookitem nữa → chỉ đánh dấu sách là đã xóa
package Servlet;

import java.io.IOException;
import java.sql.*;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

public class DeleteBookServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/html; charset=UTF-8");

        String isbn = request.getParameter("isbn");

        if (isbn == null || isbn.trim().isEmpty()) {
            response.sendRedirect("adminDashboard.jsp");
            return;
        }

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            // Kiểm tra sách có đang được mượn không
            String checkBorrowSql = """
                SELECT COUNT(*) FROM borrow b
                JOIN bookitem bi ON b.book_item_id = bi.book_item_id
                WHERE bi.book_isbn = ? AND b.return_date IS NULL
            """;
            try (PreparedStatement checkStmt = conn.prepareStatement(checkBorrowSql)) {
                checkStmt.setString(1, isbn);
                ResultSet rs = checkStmt.executeQuery();
                if (rs.next() && rs.getInt(1) > 0) {
                    response.getWriter().write("<script>alert('Không thể xóa! Sách đang được mượn.'); window.location='adminDashboard.jsp';</script>");
                    return;
                }
            }

            // Đánh dấu sách là đã xóa
            String markDeletedSql = "UPDATE book SET status = 'DELETED' WHERE isbn = ?";
            int rowsUpdated;
            try (PreparedStatement stmt = conn.prepareStatement(markDeletedSql)) {
                stmt.setString(1, isbn);
                rowsUpdated = stmt.executeUpdate();
            }

            conn.commit();

            if (rowsUpdated > 0) {
                response.getWriter().write("<script>alert('Sách đã được đánh dấu là đã xóa.'); window.location='adminDashboard.jsp';</script>");
            } else {
                response.getWriter().write("<script>alert('Không tìm thấy sách để xóa!'); window.location='adminDashboard.jsp';</script>");
            }

        } catch (Exception e) {
            e.printStackTrace();
            response.getWriter().write("<script>alert('Lỗi khi xóa sách: " + e.getMessage() + "'); window.location='adminDashboard.jsp';</script>");
        }
    }

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doPost(request, response);
    }
}
