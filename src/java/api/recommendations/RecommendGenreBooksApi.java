
package api.recommendations;


import api.BaseApiServlet;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import util.JsonUtil;
import Servlet.DBConnection;
import java.io.IOException;

import java.sql.*;
import java.util.*;
import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet(name = "RecommendGenreBooksApi", urlPatterns = {"/api/books/recommend-genre"})
public class RecommendGenreBooksApi extends BaseApiServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) {
        String isbn = req.getParameter("isbn");

        if (isbn == null || isbn.trim().isEmpty()) {
            try {
                JsonUtil.writeJson(resp, 400, Map.of(
                        "message", "Thiếu tham số isbn"
                ));
            } catch (IOException ex) {
                Logger.getLogger(RecommendGenreBooksApi.class.getName()).log(Level.SEVERE, null, ex);
            }
            return;
        }

        try (Connection conn = DBConnection.getConnection()) {

            // 1) Lấy genre chính của sách
            String genreSql =
                    "SELECT g.name " +
                    "FROM book b " +
                    "JOIN book_genre bg ON bg.book_id = b.id " +
                    "JOIN genre g ON g.id = bg.genre_id " +
                    "WHERE b.isbn = ? LIMIT 1";

            String primaryGenre = null;
            try (PreparedStatement ps = conn.prepareStatement(genreSql)) {
                ps.setString(1, isbn);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        primaryGenre = rs.getString("name");
                    }
                }
            }

            if (primaryGenre == null) {
                JsonUtil.writeJson(resp, 200, Map.of(
                        "items", List.of()
                ));
                return;
            }

            // 2) Lấy sách cùng thể loại
            String sql =
                    "SELECT DISTINCT b.isbn, b.title, b.coverImage, a.name AS author " +
                    "FROM book b " +
                    "JOIN book_genre bg ON bg.book_id = b.id " +
                    "JOIN genre g ON g.id = bg.genre_id " +
                    "LEFT JOIN author a ON a.id = b.authorId " +
                    "WHERE g.name = ? AND b.isbn <> ? AND b.status = 'ACTIVE' " +
                    "ORDER BY b.id DESC LIMIT 8";

            List<Map<String, Object>> items = new ArrayList<>();

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, primaryGenre);
                ps.setString(2, isbn);

                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String, Object> book = new HashMap<>();
                        book.put("isbn", rs.getString("isbn"));
                        book.put("title", rs.getString("title"));
                        book.put("author", rs.getString("author"));
                        book.put("coverImage", rs.getString("coverImage"));
                        items.add(book);
                    }
                }
            }

            JsonUtil.writeJson(resp, 200, Map.of(
                    "genre", primaryGenre,
                    "items", items
            ));

        } catch (Exception e) {
            safe500(resp, e);
        }
    }
}
