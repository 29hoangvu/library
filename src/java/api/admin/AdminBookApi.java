package api.admin;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.*;
import java.nio.file.Paths;
import java.security.MessageDigest;
import java.time.LocalDate;
import java.util.Map;

import service.admin.AdminBookService;
import dto.AdminBookCreateRequest;
import dto.EbookAssetInfo;

@WebServlet(name = "AdminBookApi", urlPatterns = {"/api/admin/books"})
@MultipartConfig(
        fileSizeThreshold = 1 * 1024 * 1024,
        maxFileSize = 200 * 1024 * 1024,
        maxRequestSize = 210 * 1024 * 1024
)
public class AdminBookApi extends HttpServlet {

    private final AdminBookService bookService = new AdminBookService();

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        boolean isMultipart = isMultipart(request);

        String isbn, title, publisher, language, format, authorName, isNewAuthor, authorIdParam;
        String genreIdsCsv, newGenresCsv, dateOfPurchaseStr;
        int publicationYear, numberOfPages, quantity;
        double price;

        try {
            if (isMultipart) {
                isbn = p(request, "isbn");
                title = p(request, "title");
                publisher = p(request, "publisher");
                publicationYear = toInt(p(request, "publicationYear"), 0);
                language = p(request, "language");
                numberOfPages = toInt(p(request, "numberOfPages"), 0);
                format = p(request, "format");
                authorName = p(request, "authorName");
                isNewAuthor = p(request, "isNewAuthor");
                authorIdParam = p(request, "authorId");
                genreIdsCsv = p(request, "genreIds");
                newGenresCsv = p(request, "newGenres");
                quantity = "EBOOK".equalsIgnoreCase(format) ? 1 : toInt(p(request, "quantity"), 1);
                price = toDouble(p(request, "price"), 0);
                dateOfPurchaseStr = p(request, "dateOfPurchase");
            } else {
                Map<String, Object> body = Json.readJsonMap(request);
                isbn = s(body, "isbn");
                title = s(body, "title");
                publisher = s(body, "publisher");
                publicationYear = i(body, "publicationYear", 0);
                language = s(body, "language");
                numberOfPages = i(body, "numberOfPages", 0);
                format = s(body, "format");
                authorName = s(body, "authorName");
                isNewAuthor = s(body, "isNewAuthor");
                authorIdParam = s(body, "authorId");
                genreIdsCsv = s(body, "genreIds");
                newGenresCsv = s(body, "newGenres");
                quantity = "EBOOK".equalsIgnoreCase(format) ? 1 : i(body, "quantity", 1);
                price = d(body, "price", 0);
                dateOfPurchaseStr = s(body, "dateOfPurchase");
            }
        } catch (IOException badJson) {
            json(response, 400, Map.of("message", "Bad request: invalid JSON"));
            return;
        }

        if (isBlank(isbn) || isBlank(title) || isBlank(format) || isBlank(dateOfPurchaseStr)) {
            json(response, 400, Map.of("message", "Thiếu trường bắt buộc (isbn/title/format/dateOfPurchase)."));
            return;
        }

        final LocalDate dateOfPurchase;
        try {
            dateOfPurchase = LocalDate.parse(dateOfPurchaseStr);
        } catch (Exception e) {
            json(response, 400, Map.of("message", "Định dạng ngày không hợp lệ (yyyy-MM-dd)."));
            return;
        }

        try {
            String imagePath = "images/default-cover.jpg";
            EbookAssetInfo ebookInfo = null;

            if (isMultipart) {
                Part coverPart = request.getPart("coverImage");
                if (coverPart != null && coverPart.getSize() > 0) {
                    String fileName = Paths.get(coverPart.getSubmittedFileName()).getFileName().toString();
                    imagePath = "images/" + fileName;
                    String realPath = getServletContext().getRealPath("/") + "images";
                    File uploadDir = new File(realPath);
                    if (!uploadDir.exists()) {
                        uploadDir.mkdir();
                    }
                    coverPart.write(realPath + File.separator + fileName);
                }

                if ("EBOOK".equalsIgnoreCase(format)) {
                    Part ebookPart = request.getPart("ebookFile");
                    if (ebookPart != null && ebookPart.getSize() > 0) {
                        String ct = safe(ebookPart.getContentType(), "");
                        String submitted = ebookPart.getSubmittedFileName();

                        boolean okType = ct.equalsIgnoreCase("application/pdf")
                                || ct.equalsIgnoreCase("application/epub+zip")
                                || ct.equalsIgnoreCase("application/octet-stream")
                                || ends(submitted, ".pdf", ".epub");
                        if (!okType) {
                            throw new ServletException("Định dạng ebook không hợp lệ. Chỉ hỗ trợ PDF/EPUB.");
                        }

                        String originalName = Paths.get(submitted).getFileName().toString();
                        String safeName = sanitizeFilename(originalName);

                        String realDir = getServletContext().getRealPath("/") + "ebooks";
                        File dir = new File(realDir);
                        if (!dir.exists() && !dir.mkdirs()) {
                            throw new IOException("Không tạo được thư mục ebooks");
                        }

                        File target = ensureUniqueName(dir, safeName);
                        String md5;
                        long size;

                        try (InputStream in = ebookPart.getInputStream(); OutputStream out = new FileOutputStream(target)) {
                            byte[] buf = new byte[8192];
                            int r;
                            MessageDigest digest = MessageDigest.getInstance("MD5");
                            while ((r = in.read(buf)) != -1) {
                                digest.update(buf, 0, r);
                                out.write(buf, 0, r);
                            }
                            out.flush();
                            md5 = md5Hex(digest);
                            size = target.length();
                        } catch (Exception ioEx) {
                            try {
                                if (target != null) {
                                    target.delete();
                                }
                            } catch (Exception ignore) {
                            }
                            throw ioEx;
                        }

                        ebookInfo = new EbookAssetInfo();
                        ebookInfo.filePath = "ebooks/" + target.getName();
                        ebookInfo.mimeType = ct;
                        ebookInfo.fileSize = size;
                        ebookInfo.checksumMd5 = md5;
                    }
                }
            }

            AdminBookCreateRequest dto = new AdminBookCreateRequest();
            dto.isbn = isbn;
            dto.title = title;
            dto.publisher = publisher;
            dto.publicationYear = publicationYear;
            dto.language = language;
            dto.numberOfPages = numberOfPages;
            dto.format = format;
            dto.authorName = authorName;
            dto.isNewAuthor = isNewAuthor;
            dto.authorIdParam = authorIdParam;
            dto.genreIdsCsv = genreIdsCsv;
            dto.newGenresCsv = newGenresCsv;
            dto.quantity = quantity;
            dto.price = price;
            dto.dateOfPurchase = dateOfPurchase;
            dto.coverImagePath = imagePath;
            dto.ebookAsset = ebookInfo;

            int bookId = bookService.createBook(dto);

            json(response, 201, Map.of(
                    "message", "Thêm sách thành công!",
                    "bookId", bookId
            ));

        } catch (IllegalArgumentException e) {
            json(response, 400, Map.of("message", e.getMessage()));
        } catch (Exception e) {
            e.printStackTrace();
            json(response, 500, Map.of("message", "Lỗi: " + e.getMessage()));
        }
    }
// ========= UTIL =========

    private static boolean isMultipart(HttpServletRequest req) {
        String ct = req.getContentType();
        return ct != null && ct.toLowerCase().startsWith("multipart/");
    }

    private static String p(HttpServletRequest req, String name) {
        String v = req.getParameter(name);
        return v == null ? null : v.trim();
    }

    private static String s(Map<String, Object> m, String k) {
        Object v = m.get(k);
        return v == null ? null : String.valueOf(v).trim();
    }

    private static int i(Map<String, Object> m, String k, int def) {
        try {
            Object v = m.get(k);
            return v == null ? def : Integer.parseInt(String.valueOf(v));
        } catch (Exception e) {
            return def;
        }
    }

    private static double d(Map<String, Object> m, String k, double def) {
        try {
            Object v = m.get(k);
            return v == null ? def : Double.parseDouble(String.valueOf(v));
        } catch (Exception e) {
            return def;
        }
    }

    private static int toInt(String v, int def) {
        try {
            return Integer.parseInt(safe(v, "" + def));
        } catch (Exception e) {
            return def;
        }
    }

    private static double toDouble(String v, double def) {
        try {
            return Double.parseDouble(safe(v, "" + def));
        } catch (Exception e) {
            return def;
        }
    }

    private static String safe(String v, String def) {
        return (v == null || v.isBlank()) ? def : v.trim();
    }

    private static boolean isBlank(String s) {
        return s == null || s.trim().isEmpty();
    }

    private static boolean ends(String name, String... exts) {
        if (name == null) {
            return false;
        }
        String low = name.toLowerCase();
        for (String e : exts) {
            if (low.endsWith(e)) {
                return true;
            }
        }
        return false;
    }

    private static String sanitizeFilename(String name) {
        if (name == null) {
            return "file.pdf";
        }
        int dot = name.lastIndexOf('.');
        String base = (dot > 0) ? name.substring(0, dot) : name;
        String ext = (dot > 0) ? name.substring(dot) : "";
        base = base.trim().replaceAll("\\s+", "_").replaceAll("[^a-zA-Z0-9._-]", "_");
        if (base.isBlank()) {
            base = "file";
        }
        if (!ext.equalsIgnoreCase(".pdf") && !ext.equalsIgnoreCase(".epub")) {
            if (name.toLowerCase().endsWith(".epub")) {
                ext = ".epub";
            } else {
                ext = ".pdf";
            }
        }
        return base + ext.toLowerCase();
    }

    private static File ensureUniqueName(File dir, String filename) {
        File f = new File(dir, filename);
        if (!f.exists()) {
            return f;
        }
        int dot = filename.lastIndexOf('.');
        String base = (dot > 0) ? filename.substring(0, dot) : filename;
        String ext = (dot > 0) ? filename.substring(dot) : "";
        int i = 1;
        while (true) {
            File cand = new File(dir, base + "-" + i + ext);
            if (!cand.exists()) {
                return cand;
            }
            i++;
        }
    }

    private static String md5Hex(MessageDigest md) {
        byte[] d = md.digest();
        StringBuilder sb = new StringBuilder(d.length * 2);
        for (byte b : d) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }

    private static void json(HttpServletResponse resp, int status, Map<String, ?> obj) throws IOException {
        String payload = Json.toJson(obj);
        byte[] data = payload.getBytes(java.nio.charset.StandardCharsets.UTF_8);
        resp.resetBuffer();
        resp.setStatus(status);
        resp.setCharacterEncoding("UTF-8");
        resp.setContentType("application/json; charset=UTF-8");
        resp.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        resp.setHeader("Pragma", "no-cache");
        resp.setDateHeader("Expires", 0);
        resp.setContentLength(data.length);
        try (OutputStream os = resp.getOutputStream()) {
            os.write(data);
            os.flush();
        }
    }

    // ====== Mini JSON helper (Gson) ======
    static class Json {

        static final com.google.gson.Gson GSON
                = new com.google.gson.GsonBuilder().disableHtmlEscaping().create();

        static String toJson(Object o) {
            return GSON.toJson(o);
        }

        @SuppressWarnings("unchecked")
        static Map<String, Object> readJsonMap(HttpServletRequest req) throws IOException {
            try (BufferedReader br = req.getReader()) {
                return GSON.fromJson(br, Map.class);
            }
        }
    }
}
