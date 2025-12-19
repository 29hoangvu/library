// api/admin/BookManagementApi.java
package api.books;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.util.Map;

import dto.books.DeleteBookRequest;
import dto.books.RestoreBookRequest;
import dto.book.BookOperationResult;
import service.BookService;

@WebServlet(name="BookManagementApi", urlPatterns={"/api/admin/book-management"})
public class BookManagementApi extends HttpServlet {

    private final BookService bookService = new BookService();

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        // Authentication check (optional - thêm nếu cần)
        // Object roleObj = request.getAttribute("role");
        // if (!"ADMIN".equalsIgnoreCase(String.valueOf(roleObj))) {
        //     writeJson(response, Map.of("ok", false, "message", "Unauthorized"), 403);
        //     return;
        // }

        String action = request.getParameter("action");
        System.out.println("=== BookManagementApi ===");
        System.out.println("Action: " + action);

        try {
            switch (action != null ? action : "") {
                case "delete" -> handleDelete(request, response);
                case "restore" -> handleRestore(request, response);
                default -> writeJson(response, Map.of(
                        "ok", false,
                        "message", "Invalid action: " + action
                ), 400);
            }
        } catch (Exception e) {
            e.printStackTrace();
            writeJson(response, Map.of(
                    "ok", false,
                    "message", "Lỗi hệ thống: " + e.getMessage()
            ), 500);
        }
    }

    private void handleDelete(HttpServletRequest request, HttpServletResponse response) throws Exception {
        String isbn = request.getParameter("isbn");
        System.out.println("Delete book - ISBN: " + isbn);

        if (isbn == null || isbn.trim().isEmpty()) {
            writeJson(response, Map.of(
                    "ok", false,
                    "message", "Thiếu ISBN"
            ), 400);
            return;
        }

        DeleteBookRequest dto = new DeleteBookRequest();
        dto.isbn = isbn.trim();

        BookOperationResult result = bookService.deleteBook(dto);

        if (result.success) {
            writeJson(response, Map.of(
                    "ok", true,
                    "message", result.message
            ), 200);
        } else {
            int statusCode = switch (result.code) {
                case "NOT_FOUND" -> 404;
                case "BORROWED" -> 409;
                case "ALREADY_DELETED" -> 409;
                default -> 400;
            };
            
            writeJson(response, Map.of(
                    "ok", false,
                    "message", result.message,
                    "code", result.code
            ), statusCode);
        }
    }

    private void handleRestore(HttpServletRequest request, HttpServletResponse response) throws Exception {
        String isbn = request.getParameter("isbn");
        System.out.println("Restore book - ISBN: " + isbn);

        if (isbn == null || isbn.trim().isEmpty()) {
            writeJson(response, Map.of(
                    "ok", false,
                    "message", "Thiếu ISBN"
            ), 400);
            return;
        }

        RestoreBookRequest dto = new RestoreBookRequest();
        dto.isbn = isbn.trim();

        BookOperationResult result = bookService.restoreBook(dto);

        if (result.success) {
            writeJson(response, Map.of(
                    "ok", true,
                    "message", result.message
            ), 200);
        } else {
            int statusCode = "NOT_FOUND".equals(result.code) ? 404 : 400;
            
            writeJson(response, Map.of(
                    "ok", false,
                    "message", result.message,
                    "code", result.code
            ), statusCode);
        }
    }

    private void writeJson(HttpServletResponse resp, Map<String, ?> obj, int status) throws IOException {
        String json = new com.google.gson.GsonBuilder()
                .disableHtmlEscaping()
                .create()
                .toJson(obj);
        byte[] data = json.getBytes(StandardCharsets.UTF_8);

        resp.resetBuffer();
        resp.setStatus(status);
        resp.setCharacterEncoding("UTF-8");
        resp.setContentType("application/json; charset=UTF-8");
        resp.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        resp.setContentLength(data.length);

        try (OutputStream os = resp.getOutputStream()) {
            os.write(data);
            os.flush();
        }
    }
}