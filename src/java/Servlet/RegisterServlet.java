package Servlet;

import java.io.IOException;
import java.sql.*;
import java.time.LocalDate;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;

public class RegisterServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/html; charset=UTF-8");

        String username = request.getParameter("username");
        String email = request.getParameter("email");
        String password = PasswordHashing.hashPassword(request.getParameter("password"));

        try (Connection conn = DBConnection.getConnection()) {
            // Kiểm tra trùng tên đăng nhập
            String checkSQL = "SELECT COUNT(*) FROM users WHERE username = ?";
            PreparedStatement checkStmt = conn.prepareStatement(checkSQL);
            checkStmt.setString(1, username);
            ResultSet rs = checkStmt.executeQuery();
            if (rs.next() && rs.getInt(1) > 0) {
                response.getWriter().println("<script>alert('Tên đăng nhập đã tồn tại.'); window.location='register.jsp';</script>");
                return;
            }

            // Thêm người dùng mới
            String insertSQL = "INSERT INTO users (username, password, email, status, expiryDate, roleID) VALUES (?, ?, ?, 'PENDING', ?, 3)";
            PreparedStatement insertStmt = conn.prepareStatement(insertSQL);
            insertStmt.setString(1, username);
            insertStmt.setString(2, password);
            insertStmt.setString(3, email);
            insertStmt.setDate(4, java.sql.Date.valueOf(LocalDate.now().plusYears(1)));
            insertStmt.executeUpdate();

            // Gửi email thông báo
            String subject = "Xác nhận đăng ký tài khoản thư viện";
            String content = "Chào " + username + ",\n\n"
                    + "Bạn đã đăng ký tài khoản thành công.\n"
                    + "Vui lòng đến thư viện và nộp lệ phí để kích hoạt tài khoản của bạn.\n\n"
                    + "Trân trọng,\nThư viện";

            EmailUtility.sendEmail(email, subject, content);
            response.getWriter().println("<script>alert('Đăng ký thành công! Vui lòng kiểm tra email.'); window.location='login.jsp';</script>");
        } catch (SQLException e) {
            e.printStackTrace();
            response.getWriter().println("<script>alert('Lỗi đăng ký!'); window.location='register.jsp';</script>");
        }
    }
}
