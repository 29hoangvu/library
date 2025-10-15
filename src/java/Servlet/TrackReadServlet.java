package Servlet;

import jakarta.servlet.http.*;
import jakarta.servlet.ServletException;
import java.io.IOException;
import java.sql.*;
import java.time.*;

public class TrackReadServlet extends HttpServlet {

    private static final ZoneId ZONE = ZoneId.of("Asia/Ho_Chi_Minh");

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String isbn = req.getParameter("isbn");
        if (isbn == null || isbn.isBlank()) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        HttpSession session = req.getSession(true);
        String sessionId = session.getId();

        // Lấy user_id nếu có đăng nhập (tùy cách bạn lưu Users vào session)
        Integer userId = null;
        Object u = session.getAttribute("user");
        if (u instanceof Data.Users) {
            userId = ((Data.Users) u).getId();
        } else if (session.getAttribute("userId") instanceof Integer) {
            userId = (Integer) session.getAttribute("userId");
        }

        String ip = getClientIp(req);
        String ua = trim(req.getHeader("User-Agent"), 255);
        LocalDate today = LocalDate.now(ZONE);

        String sql = "INSERT IGNORE INTO ebook_read_log " +
                     "(isbn, user_id, session_id, ip_addr, user_agent, viewed_date) " +
                     "VALUES (?,?,?,?,?,?)";

        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, isbn);
            if (userId == null) ps.setNull(2, Types.INTEGER); else ps.setInt(2, userId);
            ps.setString(3, sessionId);
            ps.setString(4, ip);
            ps.setString(5, ua);
            ps.setDate(6, java.sql.Date.valueOf(today));
            ps.executeUpdate();
            resp.setStatus(HttpServletResponse.SC_NO_CONTENT);
        } catch (Exception e) {
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            resp.setContentType("text/plain; charset=UTF-8");
            resp.getWriter().write("DB error: " + e.getMessage());
        }
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        doPost(req, resp);
    }

    private static String getClientIp(HttpServletRequest req) {
        String h = req.getHeader("X-Forwarded-For");
        if (h != null && !h.isBlank()) {
            int comma = h.indexOf(',');
            return comma > 0 ? h.substring(0, comma).trim() : h.trim();
        }
        return req.getRemoteAddr();
    }

    private static String trim(String s, int max) {
        if (s == null) return null;
        return s.length() <= max ? s : s.substring(0, max);
    }
}
