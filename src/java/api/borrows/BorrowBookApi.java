// api/borrows/BorrowBookApi.java
package api.borrows;

import api.BaseApiServlet;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.util.Map;

import service.BorrowService;
import dto.borrow.BorrowRegisterRequest;
import dto.borrow.BorrowRegisterResult;

@WebServlet(name = "BorrowBookApi", urlPatterns = {"/api/borrow/request"})
public class BorrowBookApi extends BaseApiServlet {

    private final BorrowService borrowService = new BorrowService();
    private static final int DEFAULT_BORROW_DAYS = 7;

    static class BorrowReq { public String isbn; }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        doPost(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Integer userId = safeGetUid(req.getAttribute("uid"));
        if (userId == null) {
            writeJson(resp, Map.of("message", "Unauthorized"), 401);
            return;
        }

        String isbn = null;
        try {
            BorrowReq body = readJson(req, BorrowReq.class);
            if (body != null) isbn = body.isbn;
        } catch (Exception ignore) {}

        if (isbn == null || isbn.trim().isEmpty()) {
            isbn = req.getParameter("isbn");
        }
        if (isbn == null || isbn.trim().isEmpty()) {
            writeJson(resp, Map.of("message", "Lỗi: Thiếu thông tin sách!"), 400);
            return;
        }

        try {
            BorrowRegisterRequest dto = new BorrowRegisterRequest();
            dto.userId = userId;
            dto.isbn   = isbn.trim();
            dto.days   = DEFAULT_BORROW_DAYS;

            BorrowRegisterResult result = borrowService.registerBorrowRequest(dto);

            writeJson(resp, Map.of(
                    "message",       "Đăng ký mượn thành công! Vui lòng chờ duyệt.",
                    "borrow_id",     result.borrowId,
                    "book_item_id",  result.bookItemId,
                    "status",        result.status,
                    "days",          result.days
            ), 201);

        } catch (IllegalStateException e) {
            // Map các mã lỗi business ra HTTP code + message
            String code = e.getMessage();
            if ("LIMIT_REACHED".equals(code)) {
                writeJson(resp, Map.of(
                        "message", "Bạn đã đạt giới hạn mượn sách! Vui lòng trả bớt để tiếp tục mượn."
                ), 409);
            } else if ("NO_COPY_AVAILABLE".equals(code)) {
                writeJson(resp, Map.of(
                        "message", "Không còn bản vật lý nào của sách này sẵn sàng để mượn!"
                ), 409);
            } else {
                writeJson(resp, Map.of("message", "Lỗi nghiệp vụ: " + code), 400);
            }
        } catch (Exception e) {
            e.printStackTrace();
            writeJson(resp, Map.of("message", "Lỗi hệ thống! Vui lòng thử lại sau."), 500);
        }
    }

    private Integer safeGetUid(Object uidObj) {
        if (uidObj == null) return null;
        try {
            if (uidObj instanceof Integer i) return i;
            if (uidObj instanceof Long l) return Math.toIntExact(l);
            if (uidObj instanceof String s) return Integer.parseInt(s);
        } catch (Exception ignored) {}
        return null;
    }

    private void writeJson(HttpServletResponse resp, Object obj, int status) throws IOException {
        String json = util.GsonHolder.GSON.toJson(obj);
        byte[] data = json.getBytes(StandardCharsets.UTF_8);

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

    private static class util {
        static class GsonHolder {
            static final com.google.gson.Gson GSON =
                    new com.google.gson.GsonBuilder().disableHtmlEscaping().create();
        }
    }
}
