package api.books;

import api.BaseApiServlet;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.util.Optional;

import dto.books.BookUpdateRequest;
import service.BookUpdateService;
import util.JsonUtil;

@MultipartConfig(maxFileSize = 16 * 1024 * 1024)
@WebServlet(name = "BookUpdateApi", urlPatterns = {"/api/books/update/*"})
public class BookUpdateApi extends BaseApiServlet {

    private final BookUpdateService bookService = new BookUpdateService();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        handleUpdate(req, resp);
    }

    @Override
    protected void doPut(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        handleUpdate(req, resp);
    }

    private void handleUpdate(HttpServletRequest request, HttpServletResponse response) throws IOException {
        request.setCharacterEncoding("UTF-8");

        // Lấy ISBN từ path: /api/books/update/{isbn}
        String path = request.getPathInfo(); // /{isbn}
        String isbn = (path != null && path.length() > 1) ? path.substring(1) : null;
        if (isbn == null || isbn.isBlank()) {
            JsonUtil.writeJson(response, 400,
                    java.util.Map.of("ok", false, "message", "Missing ISBN in path"));
            return;
        }

        try {
            // ====== Build DTO ======
            BookUpdateRequest dto = new BookUpdateRequest();
            dto.isbn              = isbn;
            dto.title             = getParam(request, "title");
            dto.publisher         = getParam(request, "publisher");
            dto.language          = getParam(request, "language");
            dto.description       = getParam(request, "description");
            dto.authorName        = getParam(request, "authorName");
            dto.status            = getParam(request, "status");
            dto.format            = getParam(request, "format");
            dto.formatEditEnabled = "true".equalsIgnoreCase(getParam(request, "formatEditEnabled"));
            dto.genreIdsCsv       = getParam(request, "genreIds");
            dto.newGenresCsv      = getParam(request, "newGenres");

            dto.publicationYear   = parseInt(getParam(request, "publicationYear"));
            dto.numberOfPages     = parseInt(getParam(request, "numberOfPages"));
            dto.quantity          = parseInt(getParam(request, "quantity"));

            // Ảnh bìa: dùng path cũ nếu không upload file mới
            String existingCover  = Optional.ofNullable(getParam(request, "existingCoverImage"))
                                            .orElse("");

            String imagePath = existingCover;
            Part filePart = null;
            try {
                filePart = request.getPart("coverImage");
            } catch (Exception ignore) {}

            if (filePart != null && filePart.getSize() > 0) {
                String submitted = filePart.getSubmittedFileName();
                if (submitted != null && !submitted.isBlank()) {
                    String fileName = submitted.replace("\\", "/");
                    fileName = fileName.substring(fileName.lastIndexOf('/') + 1);
                    // TODO: nếu muốn ghi ra ổ đĩa: lưu file rồi set imagePath tương ứng
                    imagePath = "images/" + fileName;
                }
            }

            dto.coverImagePath = imagePath;

            // ====== Gọi service ======
            try {
                bookService.updateBook(dto);
                JsonUtil.writeJson(response, 200,
                        java.util.Map.of(
                                "ok", true,
                                "message", "Cập nhật sách thành công",
                                "isbn", isbn
                        ));
            } catch (IllegalArgumentException ex) {
                String code = ex.getMessage();
                if ("BOOK_NOT_FOUND".equals(code)) {
                    JsonUtil.writeJson(response, 404,
                            java.util.Map.of("ok", false, "message", "Không tìm thấy sách"));
                } else if ("MISSING_ISBN".equals(code)) {
                    JsonUtil.writeJson(response, 400,
                            java.util.Map.of("ok", false, "message", "Thiếu ISBN"));
                } else {
                    // các IllegalArgumentException khác
                    JsonUtil.writeJson(response, 400,
                            java.util.Map.of("ok", false, "message", code));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            JsonUtil.writeJson(response, 500,
                    java.util.Map.of("ok", false, "message", "Internal Error: " + e.getMessage()));
        }
    }

    // ====== Helpers ở servlet (ĐỌC PARAM) ======
    private static String getParam(HttpServletRequest req, String name) {
        try {
            String v = req.getParameter(name);
            if (v == null) return null;
            v = v.trim();
            return v.isEmpty() ? null : v;
        } catch (Exception e) {
            return null;
        }
    }

    private static int parseInt(String s) {
        try { return Integer.parseInt(s); } catch (Exception e) { return 0; }
    }
}
