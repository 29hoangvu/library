package Servlet;

import java.io.*;
import java.nio.file.Paths;
import java.sql.*;
import java.time.LocalDate;
import jakarta.servlet.*;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.http.*;
import java.security.MessageDigest;

@MultipartConfig(
    fileSizeThreshold = 1 * 1024 * 1024,   // 1MB: đệm tạm
    maxFileSize       = 200 * 1024 * 1024, // 200MB/file
    maxRequestSize    = 210 * 1024 * 1024  // 210MB/tổng request
)
public class AdminServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        // ---- LẤY FORM ----
        String isbn = request.getParameter("isbn");
        String title = request.getParameter("title");
        String publisher = request.getParameter("publisher");
        int publicationYear = Integer.parseInt(safe(request.getParameter("publicationYear"), "0"));
        String language = request.getParameter("language");
        int numberOfPages = Integer.parseInt(safe(request.getParameter("numberOfPages"), "0"));
        String format = request.getParameter("format");
        String authorName = request.getParameter("authorName");
        String isNewAuthor = request.getParameter("isNewAuthor");
        String authorIdParam = request.getParameter("authorId");

        // Ép quantity = 1 nếu là EBOOK (dù UI đã ẩn/readonly)
        int quantity = "EBOOK".equalsIgnoreCase(format)
                ? 1
                : Integer.parseInt(safe(request.getParameter("quantity"), "1"));

        double price = Double.parseDouble(safe(request.getParameter("price"), "0"));
        String dateOfPurchaseStr = request.getParameter("dateOfPurchase");

        String genreIdsCsv = request.getParameter("genreIds");   // "3,5,9"
        String newGenresCsv = request.getParameter("newGenres"); // "AI,Khoa học dữ liệu"

        // ---- PARSE NGÀY ----
        LocalDate dateOfPurchase;
        try {
            dateOfPurchase = LocalDate.parse(dateOfPurchaseStr);
        } catch (Exception e) {
            sendResponse(response, "Lỗi: Định dạng ngày không hợp lệ.");
            return;
        }

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);  // BẮT ĐẦU TRANSACTION

            // ---- TÁC GIẢ ----
            int authorId;
            boolean wantNewAuthor = "true".equalsIgnoreCase(isNewAuthor)
                    || ((authorIdParam == null || authorIdParam.isBlank())
                        && authorName != null && !authorName.isBlank());

            if (wantNewAuthor) {
                authorId = getOrInsertAuthor(conn, authorName.trim());
            } else if (authorIdParam != null && !authorIdParam.isBlank()) {
                authorId = Integer.parseInt(authorIdParam);
            } else {
                throw new SQLException("Không xác định được tác giả.");
            }


            // ---- ẢNH BÌA ----
            String imagePath = "images/default-cover.jpg";
            Part coverPart = request.getPart("coverImage");
            if (coverPart != null && coverPart.getSize() > 0) {
                String fileName = Paths.get(coverPart.getSubmittedFileName()).getFileName().toString();
                imagePath = "images/" + fileName;
                String realPath = getServletContext().getRealPath("/") + "images";
                File uploadDir = new File(realPath);
                if (!uploadDir.exists()) uploadDir.mkdir();
                coverPart.write(realPath + File.separator + fileName);
            }

            // ---- THÊM BOOK ----
            int bookId;
            String sqlBook = "INSERT INTO book (isbn, title, publisher, publicationYear, language, numberOfPages, format, authorId, coverImage, quantity, status) "
                    + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'ACTIVE')";
            try (PreparedStatement ps = conn.prepareStatement(sqlBook, Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, isbn);
                ps.setString(2, title);
                ps.setString(3, publisher);
                ps.setInt(4, publicationYear);
                ps.setString(5, language);
                ps.setInt(6, numberOfPages);
                ps.setString(7, format);
                ps.setInt(8, authorId);
                ps.setString(9, imagePath);
                ps.setInt(10, quantity);
                ps.executeUpdate();

                try (ResultSet keys = ps.getGeneratedKeys()) {
                    if (keys.next()) {
                        bookId = keys.getInt(1);
                    } else {
                        throw new SQLException("Không lấy được book.id sau khi insert.");
                    }
                }
            }

            // ---- THÊM BOOKITEM (ghi nhận lô nhập) ----
            String sqlBookItem = "INSERT INTO bookitem (book_isbn, price, date_of_purchase) VALUES (?, ?, ?)";
            try (PreparedStatement ps = conn.prepareStatement(sqlBookItem)) {
                ps.setString(1, isbn);
                ps.setDouble(2, price);
                ps.setDate(3, java.sql.Date.valueOf(dateOfPurchase));
                ps.executeUpdate();
            }

            // ---- UPLOAD EBOOK (NẾU FORMAT = EBOOK) ----
            if ("EBOOK".equalsIgnoreCase(format)) {
                Part ebookPart = request.getPart("ebookFile");
                if (ebookPart != null && ebookPart.getSize() > 0) {
                    // 1) Validate MIME/đuôi
                    String ct = safe(ebookPart.getContentType(), "");
                    String submitted = ebookPart.getSubmittedFileName();
                    boolean okType = ct.equalsIgnoreCase("application/pdf")
                                  || ct.equalsIgnoreCase("application/epub+zip")
                                  || ct.equalsIgnoreCase("application/octet-stream") // 1 số trình duyệt gửi vậy
                                  || hasExt(submitted, ".pdf", ".epub");
                    if (!okType) {
                        throw new ServletException("Định dạng ebook không hợp lệ. Chỉ hỗ trợ PDF/EPUB.");
                    }

                    // 2) Lấy đúng tên file người dùng chọn + sanitize
                    String originalName = Paths.get(submitted).getFileName().toString();
                    String safeName = sanitizeFilename(originalName); // ví dụ: "Giáo_trình_AI_(2025).pdf"

                    // 3) Thư mục đích + tránh trùng tên
                    String realDir = getServletContext().getRealPath("/") + "ebooks";
                    File dir = new File(realDir);
                    if (!dir.exists() && !dir.mkdirs()) {
                        throw new IOException("Không tạo được thư mục ebooks");
                    }
                    File target = ensureUniqueName(dir, safeName); // nếu trùng sẽ thành "Giáo_trình_AI_(2025)-1.pdf"

                    // 4) Ghi file + tính MD5
                    try (InputStream in = ebookPart.getInputStream();
                         OutputStream out = new FileOutputStream(target)) {

                        byte[] buf = new byte[8192];
                        int r;
                        MessageDigest md = java.security.MessageDigest.getInstance("MD5");
                        while ((r = in.read(buf)) != -1) {
                            md.update(buf, 0, r);
                            out.write(buf, 0, r);
                        }
                        out.flush();

                        String md5 = md5Hex(md);
                        long size = target.length();

                        // 5) Lưu đường dẫn tương đối đúng yêu cầu: "ebooks/" + tên file đã chọn (có thể đã đổi để tránh trùng)
                        String webRelPath = "ebooks/" + target.getName();
                        String sqlE = "INSERT INTO ebook_asset (book_isbn, file_path, mime_type, file_size, checksum_md5) " +
                                      "VALUES (?, ?, ?, ?, ?) " +
                                      "ON DUPLICATE KEY UPDATE " +
                                      "  file_path = VALUES(file_path), " +
                                      "  mime_type = VALUES(mime_type), " +
                                      "  file_size = VALUES(file_size), " +
                                      "  checksum_md5 = VALUES(checksum_md5)";
                        try (PreparedStatement ps = conn.prepareStatement(sqlE)) {
                            ps.setString(1, isbn);
                            ps.setString(2, webRelPath);   // <-- đúng yêu cầu
                            ps.setString(3, ct);
                            ps.setLong(4, size);
                            ps.setString(5, md5);
                            ps.executeUpdate();
                        }
                    } catch (Exception ioEx) {
                        try { if (target != null) target.delete(); } catch (Exception ignore) {}
                        throw ioEx;
                    }
                }
            }



            // ---- XỬ LÝ GENRE CÓ SẴN ----
            if (genreIdsCsv != null && !genreIdsCsv.isBlank()) {
                for (String s : genreIdsCsv.split(",")) {
                    int gid = Integer.parseInt(s.trim());
                    insertBookGenreIfAbsent(conn, bookId, gid);
                }
            }

            // ---- XỬ LÝ GENRE MỚI ----
            if (newGenresCsv != null && !newGenresCsv.isBlank()) {
                for (String name : newGenresCsv.split(",")) {
                    String trimmed = name.trim();
                    if (trimmed.isEmpty()) continue;
                    int gid = getOrInsertGenre(conn, trimmed);
                    insertBookGenreIfAbsent(conn, bookId, gid);
                }
            }

            conn.commit();
            sendResponse(response, "Thêm sách thành công!");
        } catch (Exception e) {
            e.printStackTrace();
            sendResponse(response, "Lỗi: " + e.getMessage());
        }
    }

    // ========= HELPERS =========
    private static String safe(String v, String def) {
        return (v == null || v.isBlank()) ? def : v.trim();
    }
    private static boolean hasExt(String name, String... exts) {
        if (name == null) return false;
        String low = name.toLowerCase();
        for (String e : exts) if (low.endsWith(e)) return true;
        return false;
    }
    private static String guessExt(String submitted, String mime) {
        if (submitted != null) {
            String low = submitted.toLowerCase();
            if (low.endsWith(".pdf")) return ".pdf";
            if (low.endsWith(".epub")) return ".epub";
        }
        if ("application/epub+zip".equalsIgnoreCase(mime)) return ".epub";
        return ".pdf";
    }
    private static String md5Hex(MessageDigest md) {
        byte[] d = md.digest();
        StringBuilder sb = new StringBuilder(d.length * 2);
        for (byte b : d) sb.append(String.format("%02x", b));
        return sb.toString();
    }

    private int getOrInsertAuthor(Connection conn, String authorName) throws SQLException {
        try (PreparedStatement s = conn.prepareStatement("SELECT id FROM author WHERE name = ?")) {
            s.setString(1, authorName);
            try (ResultSet rs = s.executeQuery()) { if (rs.next()) return rs.getInt(1); }
        }
        try (PreparedStatement ins = conn.prepareStatement("INSERT INTO author(name) VALUES (?)", Statement.RETURN_GENERATED_KEYS)) {
            ins.setString(1, authorName);
            ins.executeUpdate();
            try (ResultSet keys = ins.getGeneratedKeys()) { if (keys.next()) return keys.getInt(1); }
        }
        throw new SQLException("Không thể thêm/tìm tác giả.");
    }

    private int getOrInsertGenre(Connection conn, String name) throws SQLException {
        try (PreparedStatement s = conn.prepareStatement("SELECT id FROM genre WHERE name = ?")) {
            s.setString(1, name);
            try (ResultSet rs = s.executeQuery()) { if (rs.next()) return rs.getInt(1); }
        }
        try (PreparedStatement ins = conn.prepareStatement("INSERT INTO genre(name) VALUES (?)", Statement.RETURN_GENERATED_KEYS)) {
            ins.setString(1, name);
            ins.executeUpdate();
            try (ResultSet keys = ins.getGeneratedKeys()) { if (keys.next()) return keys.getInt(1); }
        }
        throw new SQLException("Không thể thêm/tìm thể loại.");
    }

    private void insertBookGenreIfAbsent(Connection conn, int bookId, int genreId) throws SQLException {
        try (PreparedStatement chk = conn.prepareStatement("SELECT 1 FROM book_genre WHERE book_id = ? AND genre_id = ?")) {
            chk.setInt(1, bookId); chk.setInt(2, genreId);
            try (ResultSet rs = chk.executeQuery()) { if (rs.next()) return; }
        }
        try (PreparedStatement ins = conn.prepareStatement("INSERT INTO book_genre(book_id, genre_id) VALUES (?, ?)")) {
            ins.setInt(1, bookId); ins.setInt(2, genreId); ins.executeUpdate();
        }
    }

    private void sendResponse(HttpServletResponse response, String message) throws IOException {
        response.setContentType("text/html; charset=UTF-8");
        response.getWriter().println("<script>alert('" + message + "'); window.location.href='auth/lib/admin.jsp';</script>");
    }
    // Loại bỏ ký tự lạ, giữ lại [a-zA-Z0-9._-] và thay khoảng trắng bằng _
    private static String sanitizeFilename(String name) {
        if (name == null) return "file";
        // tách tên và phần mở rộng để giữ nguyên ext
        int dot = name.lastIndexOf('.');
        String base = (dot > 0) ? name.substring(0, dot) : name;
        String ext  = (dot > 0) ? name.substring(dot) : "";
        // chuẩn hóa
        base = base.trim().replaceAll("\\s+", "_");
        base = base.replaceAll("[^a-zA-Z0-9._-]", "_");
        // tránh tên rỗng
        if (base.isBlank()) base = "file";
        // chỉ cho phép .pdf hoặc .epub
        if (!ext.equalsIgnoreCase(".pdf") && !ext.equalsIgnoreCase(".epub")) {
            // đoán theo nội dung tên cũ; mặc định .pdf
            if (name.toLowerCase().endsWith(".epub")) ext = ".epub"; else ext = ".pdf";
        }
        return base + ext.toLowerCase();
    }

    // Nếu file đã tồn tại thì thêm -1, -2, ...
    private static File ensureUniqueName(File dir, String filename) {
        File f = new File(dir, filename);
        if (!f.exists()) return f;

        int dot = filename.lastIndexOf('.');
        String base = (dot > 0) ? filename.substring(0, dot) : filename;
        String ext  = (dot > 0) ? filename.substring(dot) : "";
        int i = 1;
        while (true) {
            File cand = new File(dir, base + "-" + i + ext);
            if (!cand.exists()) return cand;
            i++;
        }
    }

}
