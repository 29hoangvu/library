package Servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;
import Data.Users;

public class UpdateProfileServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
        throws ServletException, IOException {

        // Đặt encoding trước khi đọc parameters
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");
        response.setContentType("application/json; charset=UTF-8");

        HttpSession session = request.getSession(false);
        Users user = (session != null) ? (Users) session.getAttribute("user") : null;
        if (user == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            try (PrintWriter out = response.getWriter()) {
                out.write("{\"ok\":false,\"msg\":\"unauthorized\"}");
            }
            return;
        }

        int userId = user.getId();

        // Đọc parameters trực tiếp, không dùng emptyToNull
        String fullName = request.getParameter("fullName");
        String gender = request.getParameter("gender");
        String birthDateStr = request.getParameter("birthDate");
        String phone = request.getParameter("phone");
        String address = request.getParameter("address");

        // Parse date
        java.sql.Date birthDate = null;
        if (birthDateStr != null && !birthDateStr.trim().isEmpty()) {
            try {
                birthDate = java.sql.Date.valueOf(birthDateStr);
            } catch (IllegalArgumentException e) {
                System.err.println("Invalid date format: " + birthDateStr);
            }
        }

        // Debug thông tin nhận được
        System.out.println("[UpdateProfileServlet] Received data - "
                + "userId: " + userId + ", "
                + "fullName: " + fullName + ", "
                + "gender: " + gender + ", "
                + "birthDate: " + birthDate + ", "
                + "phone: " + phone + ", "
                + "address: " + address);

        String checkSql = "SELECT 1 FROM user_profile WHERE userID = ?";
        String updateSql = "UPDATE user_profile SET fullName=?, gender=?, birthDate=?, phone=?, address=? WHERE userID=?";
        String insertSql = "INSERT INTO user_profile (userID, fullName, gender, birthDate, phone, address) VALUES (?, ?, ?, ?, ?, ?)";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement psCheck = conn.prepareStatement(checkSql)) {

            psCheck.setInt(1, userId);
            boolean exists = psCheck.executeQuery().next();

            if (exists) {
                try (PreparedStatement psUpdate = conn.prepareStatement(updateSql)) {
                    // Sử dụng setString thay vì setNullableString
                    psUpdate.setString(1, fullName);
                    psUpdate.setString(2, gender);
                    if (birthDate != null) {
                        psUpdate.setDate(3, birthDate);
                    } else {
                        psUpdate.setNull(3, Types.DATE);
                    }
                    psUpdate.setString(4, phone);
                    psUpdate.setString(5, address);
                    psUpdate.setInt(6, userId);
                    
                    int rowsUpdated = psUpdate.executeUpdate();
                    System.out.println("Rows updated: " + rowsUpdated);
                }
            } else {
                try (PreparedStatement psInsert = conn.prepareStatement(insertSql)) {
                    psInsert.setInt(1, userId);
                    psInsert.setString(2, fullName);
                    psInsert.setString(3, gender);
                    if (birthDate != null) {
                        psInsert.setDate(4, birthDate);
                    } else {
                        psInsert.setNull(4, Types.DATE);
                    }
                    psInsert.setString(5, phone);
                    psInsert.setString(6, address);
                    
                    int rowsInserted = psInsert.executeUpdate();
                    System.out.println("Rows inserted: " + rowsInserted);
                }
            }

            try (PrintWriter out = response.getWriter()) {
                out.write("{\"ok\":true}");
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            try (PrintWriter out = response.getWriter()) {
                out.write("{\"ok\":false,\"msg\":\"" + e.getMessage().replace("\"","\\\"") + "\"}");
            }
        }
    }
}