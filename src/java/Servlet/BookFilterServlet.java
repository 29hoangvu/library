package Servlet;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;
import java.util.*;

public class BookFilterServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        resp.setCharacterEncoding("UTF-8");
        List<Map<String, Object>> filteredBooks = new ArrayList<>();

        String genreId = req.getParameter("genreId");
        String genreName = req.getParameter("genreName");
        String yearFromStr = req.getParameter("yearFrom");
        String yearToStr = req.getParameter("yearTo");
        String pagesMinStr = req.getParameter("pagesMin");

        Integer yearFrom = null, yearTo = null, pagesMin = null;
        try {
            if (yearFromStr != null && !yearFromStr.isEmpty())
                yearFrom = Integer.parseInt(yearFromStr);
            if (yearToStr != null && !yearToStr.isEmpty())
                yearTo = Integer.parseInt(yearToStr);
            if (pagesMinStr != null && !pagesMinStr.isEmpty())
                pagesMin = Integer.parseInt(pagesMinStr);
        } catch (NumberFormatException e) {
            // bỏ qua lỗi parse
        }

        StringBuilder sql = new StringBuilder(
            "SELECT b.isbn, b.title, a.name AS author, " +
            "b.publicationYear, b.numberOfPages, b.format, b.coverImage " +
            "FROM book b LEFT JOIN author a ON b.authorId = a.id WHERE 1=1"
        );

        List<Object> params = new ArrayList<>();

        if (genreId != null && !genreId.isBlank()) {
            sql.append(" AND b.id IN (SELECT book_id FROM book_genre WHERE genre_id=?)");
            params.add(Integer.parseInt(genreId));
        }
        if (yearFrom != null) {
            sql.append(" AND b.publicationYear >= ?");
            params.add(yearFrom);
        }
        if (yearTo != null) {
            sql.append(" AND b.publicationYear <= ?");
            params.add(yearTo);
        }
        if (pagesMin != null) {
            sql.append(" AND b.numberOfPages >= ?");
            params.add(pagesMin);
        }

        sql.append(" ORDER BY b.publicationYear ASC");

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> b = new HashMap<>();
                    b.put("isbn", rs.getString("isbn"));
                    b.put("title", rs.getString("title"));
                    b.put("author", rs.getString("author"));
                    b.put("publicationYear", rs.getInt("publicationYear"));
                    b.put("numberOfPages", rs.getInt("numberOfPages"));
                    b.put("format", rs.getString("format"));
                    b.put("coverImage", rs.getString("coverImage"));
                    filteredBooks.add(b);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
            req.setAttribute("error", e.getMessage());
        }

        req.setAttribute("filteredBooks", filteredBooks);
        req.setAttribute("genreId", genreId);
        req.setAttribute("genreName", genreName);
        req.setAttribute("yearFrom", yearFrom);
        req.setAttribute("yearTo", yearTo);
        req.setAttribute("pagesMin", pagesMin);

        req.getRequestDispatcher("/index.jsp").forward(req, resp);
    }
}
