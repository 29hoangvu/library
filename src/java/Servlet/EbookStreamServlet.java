package Servlet;

import jakarta.servlet.http.*;
import jakarta.servlet.ServletException;
import java.io.*;
import java.sql.*;

public class EbookStreamServlet extends HttpServlet {

  @Override
  protected void doGet(HttpServletRequest req, HttpServletResponse resp)
      throws IOException {

    // 0) Input
    final String isbn = req.getParameter("isbn");
    final boolean asDownload = "true".equalsIgnoreCase(req.getParameter("download"));
    if (isbn == null || isbn.isBlank()) {
      resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Missing isbn");
      return;
    }

    // 1) Lấy metadata từ DB
    String relPath = null;
    String mime = null;
    long fileSize = -1;
    try (Connection c = DBConnection.getConnection();
         PreparedStatement ps = c.prepareStatement(
            "SELECT file_path, mime_type, file_size FROM ebook_asset WHERE book_isbn=?")) {
      ps.setString(1, isbn);
      try (ResultSet rs = ps.executeQuery()) {
        if (rs.next()) {
          relPath  = rs.getString("file_path");
          mime     = rs.getString("mime_type");
          fileSize = rs.getLong("file_size");
        }
      }
    } catch (Exception ex) {
      resp.sendError(500, "DB error");
      return;
    }
    if (relPath == null) {
      resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Ebook not found");
      return;
    }

    // 2) Xác định file vật lý
    String baseDir = getServletContext().getInitParameter("ebook.baseDir");
    if (baseDir == null || baseDir.isBlank()) {
        resp.sendError(500, "Missing ebook.baseDir");
        return;
    }

    String rel = relPath.replaceFirst("^[\\\\/]+", "");  // Xóa / hoặc \ đầu nếu có

    File file = new File(baseDir, rel);

    // Log ra để debug
    System.out.println("📁 [EBOOK] Trying to serve file: " + file.getAbsolutePath());

    if (!file.exists() || !file.isFile()) {
        String msg = "❌ Không tìm thấy ebook tại: " + file.getAbsolutePath();
        System.err.println("[ebook] Not found: " + file.getAbsolutePath());

        // Trả về HTML có log trên F12 Console
        resp.setContentType("text/html; charset=UTF-8");
        resp.getWriter().println("<script>");
        resp.getWriter().println("console.error(" + toJS(msg) + ");");
        resp.getWriter().println("console.warn('Đã gửi lỗi từ server - kiểm tra đường dẫn hoặc file!');");
        resp.getWriter().println("</script>");
        resp.getWriter().println("<p style='color:red'>" + msg + "</p>");
        return;
    }


    // 3) Chuẩn bị response (reset buffer để Tomcat không bật chunked khi đã set length)
    try {
      resp.reset();
    } catch (IllegalStateException ignore) {}
    resp.setBufferSize(1024 * 64); // 64KB
    resp.setContentType(mime);
    resp.setHeader("Accept-Ranges", "bytes");
    resp.setHeader("Cache-Control", "private, max-age=0, must-revalidate");
    resp.setHeader("X-Content-Type-Options", "nosniff");
    resp.setHeader(
        "Content-Disposition",
        (asDownload ? "attachment; " : "inline; ") + "filename=\"" + file.getName() + "\""
    );

    // 4) Xử lý Range (nếu có)
    String range = req.getHeader("Range");
    long start = 0, end = fileSize - 1;
    boolean partial = false;

    if (range != null && range.startsWith("bytes=")) {
      try {
        String[] parts = range.substring(6).split("-", 2);
        if (!parts[0].isEmpty()) start = Long.parseLong(parts[0]);
        if (parts.length > 1 && !parts[1].isEmpty()) end = Long.parseLong(parts[1]);
        if (start < 0 || start >= fileSize) {
          resp.setHeader("Content-Range", "bytes */" + fileSize);
          resp.sendError(HttpServletResponse.SC_REQUESTED_RANGE_NOT_SATISFIABLE);
          return;
        }
        if (end < start || end >= fileSize) end = fileSize - 1;
        partial = true;
      } catch (NumberFormatException ignore) {
        // Nếu range sai format -> trả full file
        start = 0; end = fileSize - 1; partial = false;
      }
    }

    long contentLen = end - start + 1;

    if (partial) {
      resp.setStatus(HttpServletResponse.SC_PARTIAL_CONTENT);
      resp.setHeader("Content-Range", "bytes " + start + "-" + end + "/" + fileSize);
    }
    // Quan trọng: chỉ set Content-Length đúng bằng số bytes sẽ gửi
    resp.setContentLengthLong(contentLen);

    // 5) Stream dữ liệu
    try (RandomAccessFile raf = new RandomAccessFile(file, "r");
         OutputStream out = resp.getOutputStream()) {
      raf.seek(start);
      byte[] buf = new byte[1024 * 64];
      long remaining = contentLen;
      while (remaining > 0) {
        int toRead = (int) Math.min(buf.length, remaining);
        int read = raf.read(buf, 0, toRead);
        if (read == -1) break;           // EOF sớm (hiếm)
        out.write(buf, 0, read);
        remaining -= read;
      }
      out.flush(); // đảm bảo gửi hết
    } catch (IOException clientAbort) {
      // Client đóng/đổi trang giữa chừng -> bỏ qua để không ném lỗi lên trình duyệt
      // (Tomcat sẽ log ClientAbortException; đây là bình thường)
    }
  }

    private String toJS(String s) {
        if (s == null) return "null";
        return "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"") + "\"";
    }

}
