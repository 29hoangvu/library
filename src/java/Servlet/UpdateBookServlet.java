package Servlet;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.net.URLEncoder;
import java.sql.*;

@MultipartConfig(maxFileSize = 16 * 1024 * 1024)
public class UpdateBookServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        // ====== ẢNH ======
        String existingCover = request.getParameter("existingCoverImage");
        String imagePath = (existingCover != null) ? existingCover : "";
        String ctype = request.getContentType();
        boolean isMultipart = ctype != null && ctype.toLowerCase().startsWith("multipart/");
        if (isMultipart) {
            Part filePart = request.getPart("coverImage");
            if (filePart != null && filePart.getSize() > 0) {
                String submitted = filePart.getSubmittedFileName();
                if (submitted != null && !submitted.isBlank()) {
                    String fileName = submitted.replace("\\", "/");
                    fileName = fileName.substring(fileName.lastIndexOf('/') + 1);
                    // Lưu đường dẫn DB (nếu muốn ghi file vật lý như form Add thì bổ sung write vào /images)
                    imagePath = "images/" + fileName;
                }
            }
        }

        // ====== PARAMS ======
        String isbn = request.getParameter("isbn");
        String title = request.getParameter("title");
        String publisher = request.getParameter("publisher");
        String language = request.getParameter("language");
        String format = request.getParameter("format"); // CHỈ dùng nếu bật chỉnh sửa
        String formatEditEnabled = request.getParameter("formatEditEnabled"); // "true"/"false"
        String description = request.getParameter("description");
        String authorName = request.getParameter("authorName");
        String status = request.getParameter("status");
        if (status == null || status.isBlank()) status = "ACTIVE";
        status = status.equalsIgnoreCase("DELETED") ? "DELETED" : "ACTIVE";

        int publicationYear = parseInt(request.getParameter("publicationYear"));
        int numberOfPages   = parseInt(request.getParameter("numberOfPages"));
        int quantity        = parseInt(request.getParameter("quantity"));

        String genreIdsCsv  = request.getParameter("genreIds");
        String newGenresCsv = request.getParameter("newGenres");

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            int authorID = getOrInsertAuthor(conn, authorName);

            // Lấy book_id
            int bookId = -1;
            try (PreparedStatement ps = conn.prepareStatement("SELECT id FROM book WHERE isbn=?")) {
                ps.setString(1, isbn);
                try (ResultSet r = ps.executeQuery()) {
                    if (r.next()) bookId = r.getInt(1);
                    else { redirectError(response, request, isbn, "Không tìm thấy sách"); return; }
                }
            }

            // ====== UPDATE book (KHÔNG đụng vào format ở bước này) ======
            String up = "UPDATE book SET title=?, publisher=?, publicationYear=?, language=?, " +
                        "numberOfPages=?, quantity=?, authorID=?, coverImage=?, status=? WHERE isbn=?";
            try (PreparedStatement ps = conn.prepareStatement(up)) {
                ps.setString(1, title);
                ps.setString(2, publisher);
                ps.setInt(3, publicationYear);
                ps.setString(4, language);
                ps.setInt(5, numberOfPages);
                ps.setInt(6, quantity);
                ps.setInt(7, authorID);
                ps.setString(8, imagePath);
                ps.setString(9, status);
                ps.setString(10, isbn);
                ps.executeUpdate();
            }

            // ====== CHỈ update format khi bật chỉnh sửa ======
            if ("true".equalsIgnoreCase(formatEditEnabled) && format != null && !format.isBlank()) {
                try (PreparedStatement ps = conn.prepareStatement("UPDATE book SET format=? WHERE isbn=?")) {
                    ps.setString(1, format.trim());
                    ps.setString(2, isbn);
                    ps.executeUpdate();
                }
            }

            // ====== book_description ======
            if (description != null) {
                String upDesc = "INSERT INTO book_description(id,isbn,description) VALUES (?,?,?) " +
                                "ON DUPLICATE KEY UPDATE description=?";
                try (PreparedStatement ps = conn.prepareStatement(upDesc)) {
                    ps.setInt(1, bookId);
                    ps.setString(2, isbn);
                    ps.setString(3, description);
                    ps.setString(4, description);
                    ps.executeUpdate();
                }
            }

            // ====== Genres ======
            try (PreparedStatement del = conn.prepareStatement("DELETE FROM book_genre WHERE book_id=?")) {
                del.setInt(1, bookId);
                del.executeUpdate();
            }
            if (genreIdsCsv != null && !genreIdsCsv.isBlank()) {
                for (String s : genreIdsCsv.split(",")) {
                    String t = s.trim();
                    if (!t.isEmpty()) insertBookGenre(conn, bookId, Integer.parseInt(t));
                }
            }
            if (newGenresCsv != null && !newGenresCsv.isBlank()) {
                for (String name : newGenresCsv.split(",")) {
                    String t = name.trim();
                    if (t.isEmpty()) continue;
                    int gid = getOrInsertGenre(conn, t);
                    insertBookGenre(conn, bookId, gid);
                }
            }

            conn.commit();
            response.sendRedirect(request.getContextPath() + "/auth/lib/editBook.jsp?isbn=" + isbn + "&update=success");

        } catch (Exception e) {
            e.printStackTrace();
            redirectError(response, request, isbn, e.getMessage());
        }
    }

    private void redirectError(HttpServletResponse res, HttpServletRequest req, String isbn, String msg) throws IOException {
        String ctx = req.getContextPath();
        res.sendRedirect(ctx + "/auth/lib/editBook.jsp?isbn=" + isbn + "&error=" + URLEncoder.encode(msg, "UTF-8"));
    }

    private int parseInt(String s) {
        try { return Integer.parseInt(s); } catch (Exception e) { return 0; }
        }

    private int getOrInsertAuthor(Connection conn, String name) throws SQLException {
        try (PreparedStatement s = conn.prepareStatement("SELECT id FROM author WHERE name=?")) {
            s.setString(1, name);
            try (ResultSet r = s.executeQuery()) { if (r.next()) return r.getInt(1); }
        }
        try (PreparedStatement ins = conn.prepareStatement("INSERT INTO author(name) VALUES (?)", Statement.RETURN_GENERATED_KEYS)) {
            ins.setString(1, name);
            ins.executeUpdate();
            try (ResultSet k = ins.getGeneratedKeys()) { if (k.next()) return k.getInt(1); }
        }
        throw new SQLException("Không thể thêm/tìm tác giả");
    }

    private int getOrInsertGenre(Connection conn, String name) throws SQLException {
        try (PreparedStatement s = conn.prepareStatement("SELECT id FROM genre WHERE name=?")) {
            s.setString(1, name);
            try (ResultSet r = s.executeQuery()) { if (r.next()) return r.getInt(1); }
        }
        try (PreparedStatement ins = conn.prepareStatement("INSERT INTO genre(name) VALUES (?)", Statement.RETURN_GENERATED_KEYS)) {
            ins.setString(1, name);
            ins.executeUpdate();
            try (ResultSet k = ins.getGeneratedKeys()) { if (k.next()) return k.getInt(1); }
        }
        throw new SQLException("Không thể thêm/tìm thể loại");
    }

    private void insertBookGenre(Connection conn, int bookId, int genreId) throws SQLException {
        try (PreparedStatement ins = conn.prepareStatement("INSERT INTO book_genre(book_id, genre_id) VALUES (?, ?)")) {
            ins.setInt(1, bookId);
            ins.setInt(2, genreId);
            ins.executeUpdate();
        }
    }
}
