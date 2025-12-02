// api/stats/StatsApi.java
package api.stats;

import Servlet.DBConnection;
import api.BaseApiServlet;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.sql.*;
import java.util.Map;
import util.JsonUtil;

@WebServlet(name = "StatsApi", urlPatterns = {"/api/stats"})
public class StatsApi extends BaseApiServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) {
        try {
            // YÊU CẦU: phải có token => JwtFilter đã set attribute
            Object uid = req.getAttribute("uid");
            if (uid == null) {
                JsonUtil.writeJson(resp, 401, Map.of("message", "Unauthorized"));
                return;
            }

            int totalBooks = 0;
            int totalBorrowed = 0;

            try (Connection c = DBConnection.getConnection()) {
                // tổng số sách
                try (PreparedStatement ps = c.prepareStatement(
                        "SELECT COUNT(*) AS total FROM book");
                     ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) totalBooks = rs.getInt("total");
                }

                // số đang mượn
                try (PreparedStatement ps = c.prepareStatement(
                        "SELECT COUNT(*) AS borrowed FROM borrow WHERE status = 'borrowed'");
                     ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) totalBorrowed = rs.getInt("borrowed");
                }
            }

            ok(resp, Map.of(
                    "totalBooks", totalBooks,
                    "totalBorrowed", totalBorrowed
            ));
        } catch (Exception e) {
            try {
                JsonUtil.writeJson(resp, 500, Map.of("message", "Internal Error", "error", e.getMessage()));
            } catch (Exception ignore) {}
            e.printStackTrace();
        }
    }
}

