// src/main/java/Servlet/CheckAvailabilityServlet.java
package Servlet;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;

public class CheckAvailabilityServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        resp.setCharacterEncoding("UTF-8");
        resp.setContentType("application/json; charset=UTF-8");

        String type  = req.getParameter("type");   // username | email
        String value = req.getParameter("value");  // giá trị nhập

        if (type == null || value == null || value.trim().isEmpty()) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            try (PrintWriter out = resp.getWriter()) {
                out.write("{\"ok\":false,\"message\":\"missing params\",\"available\":false}");
            }
            return;
        }

        String column;
        switch (type.toLowerCase()) {
            case "username": column = "username"; break;
            case "email":    column = "email";    break;
            default:
                resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                try (PrintWriter out = resp.getWriter()) {
                    out.write("{\"ok\":false,\"message\":\"invalid type\",\"available\":false}");
                }
                return;
        }

        String sql = "SELECT 1 FROM users WHERE LOWER(" + column + ") = LOWER(?) LIMIT 1";
        boolean available = false;

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, value.trim());
            try (ResultSet rs = ps.executeQuery()) {
                boolean exists = rs.next();
                available = !exists;
            }

            try (PrintWriter out = resp.getWriter()) {
                out.write("{\"ok\":true,\"available\":" + (available ? "true" : "false") + "}");
            }

        } catch (Exception e) {
            // log để xem trong catalina.out
            e.printStackTrace();
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            try (PrintWriter out = resp.getWriter()) {
                out.write("{\"ok\":false,\"message\":\"server error\",\"available\":false}");
            }
        }
    }
}
