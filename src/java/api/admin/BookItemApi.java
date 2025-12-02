// src/main/java/api/admin/BookItemApi.java
package api.admin;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;

import dto.bookitem.BookItemRackUpdateRequest;
import dto.bookitem.BookItemRackUpdateResult;
import service.BookItemService;
import util.JsonUtil;

@WebServlet(name="BookItemApi", urlPatterns={"/api/admin/book-items"})
public class BookItemApi extends HttpServlet {

    private final BookItemService svc = new BookItemService();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        req.setCharacterEncoding("UTF-8");

        // (tuỳ) kiểm tra quyền ADMIN nếu bạn set trong JwtAuthFilter
        Object roleObj = req.getAttribute("role");
        if (roleObj != null && !"ADMIN".equalsIgnoreCase(String.valueOf(roleObj))) {
            JsonUtil.writeJson(resp, 403, err("Chỉ ADMIN mới được phép cập nhật vị trí kệ."));
            return;
        }

        String bookId  = trim(req.getParameter("bookId"));   // có thể là ISBN hoặc title
        String rackStr = trim(req.getParameter("rackId"));

        if (isBlank(bookId) || isBlank(rackStr)) {
            JsonUtil.writeJson(resp, 400, err("Thiếu tham số bookId hoặc rackId."));
            return;
        }

        int rackId;
        try {
            rackId = Integer.parseInt(rackStr);
        } catch (NumberFormatException e) {
            JsonUtil.writeJson(resp, 400, err("rackId phải là số nguyên."));
            return;
        }

        BookItemRackUpdateRequest dto = new BookItemRackUpdateRequest();
        dto.bookId = bookId;
        dto.rackId = rackId;

        try {
            BookItemRackUpdateResult result = svc.updateRack(dto);

            Map<String,Object> out = new LinkedHashMap<>();
            out.put("ok", result.ok);
            out.put("message", result.message);

            Map<String,Object> data = new LinkedHashMap<>();
            data.put("isbn", result.isbn);
            data.put("rackId", result.rackId);
            data.put("updated", result.updated);

            out.put("data", data);

            JsonUtil.writeJson(resp, 200, out);

        } catch (IllegalStateException ex) {
            String code = ex.getMessage();
            switch (code) {
                case "BOOK_NOT_FOUND" -> JsonUtil.writeJson(resp, 404,
                        err("Không tìm thấy sách theo ISBN/Tên đã nhập."));
                case "BOOKITEM_NOT_FOUND" -> JsonUtil.writeJson(resp, 404,
                        err("Sách này chưa có trong bookitem, không thể cập nhật kệ."));
                case "RACK_NOT_FOUND" -> JsonUtil.writeJson(resp, 404,
                        err("Kệ không tồn tại."));
                case "UPDATE_FAILED" -> JsonUtil.writeJson(resp, 500,
                        err("Không cập nhật được vị trí kệ."));
                default -> {
                    ex.printStackTrace();
                    JsonUtil.writeJson(resp, 400, err("Lỗi nghiệp vụ: " + code));
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
            JsonUtil.writeJson(resp, 500, err("Lỗi cơ sở dữ liệu."));
        }
    }

    // ===== Helpers HTTP-level =====
    private static String trim(String s){ return s==null? null : s.trim(); }
    private static boolean isBlank(String s){ return s==null || s.trim().isEmpty(); }

    private static Map<String,Object> err(String msg){
        return new LinkedHashMap<String,Object>(){{
            put("ok", false);
            put("message", msg);
        }};
    }
}
