// api/admin/AdminBorrowApi.java
package api.admin;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.util.Map;

import dto.borrow.ApproveBorrowRequest;
import dto.borrow.RejectBorrowRequest;
import dto.borrow.ReturnBorrowAdminRequest;
import dto.borrow.ReturnBorrowResult;
import service.BorrowService;

@WebServlet(name="AdminBorrowApi", urlPatterns={"/api/admin/am-borrows"})
public class AdminBorrowApi extends HttpServlet {

    private final BorrowService borrowService = new BorrowService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        // Không hỗ trợ GET cho API này
        writeJson(resp, Map.of(
                "ok", false,
                "message", "Phương thức không được hỗ trợ"
        ), 405);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        // Kiểm tra quyền admin (nếu bạn có JwtAuthFilter set "role")
        Object roleObj = request.getAttribute("role");
        if (roleObj == null || !"ADMIN".equalsIgnoreCase(String.valueOf(roleObj))) {
            writeJson(response, Map.of("ok", false, "message", "Forbidden"), 403);
            return;
        }

        String action = safe(request.getParameter("action"));
        try {
            switch (action) {
                case "approve" -> handleApprove(request, response);
                case "reject"  -> handleReject(request, response);
                case "return"  -> handleReturn(request, response);
                default -> writeJson(response, Map.of(
                        "ok", false,
                        "message", "Thiếu hoặc sai tham số action"
                ), 400);
            }
        } catch (Exception e) {
            e.printStackTrace();
            writeJson(response, Map.of(
                    "ok", false,
                    "message", "Lỗi hệ thống! Vui lòng thử lại sau."
            ), 500);
        }
    }

    // ====== Handlers ======

    private void handleApprove(HttpServletRequest request, HttpServletResponse response) throws Exception {
        String borrowIdStr   = request.getParameter("borrowId");
        String bookItemIdStr = request.getParameter("bookItemId");

        if (isBlank(borrowIdStr) || isBlank(bookItemIdStr)) {
            writeJson(response, Map.of(
                    "ok", false,
                    "message", "Thiếu dữ liệu!"
            ), 400);
            return;
        }

        int borrowId   = Integer.parseInt(borrowIdStr);
        int bookItemId = Integer.parseInt(bookItemIdStr);

        ApproveBorrowRequest dto = new ApproveBorrowRequest();
        dto.borrowId   = borrowId;
        dto.bookItemId = bookItemId;

        try {
            borrowService.approveBorrow(dto);
            writeJson(response, Map.of(
                    "ok", true,
                    "message", "Duyệt mượn thành công!"
            ), 200);
        } catch (IllegalStateException ex) {
            String code = ex.getMessage();
            if ("BOOKITEM_NOT_FOUND".equals(code)) {
                writeJson(response, Map.of("ok", false, "message", "Không tìm thấy sách."), 404);
            } else if ("OUT_OF_STOCK".equals(code)) {
                writeJson(response, Map.of("ok", false, "message", "Sách đã hết, không thể duyệt!"), 409);
            } else {
                writeJson(response, Map.of("ok", false, "message", "Lỗi nghiệp vụ: " + code), 400);
            }
        }
    }

    private void handleReject(HttpServletRequest request, HttpServletResponse response) throws Exception {
        String borrowIdStr = request.getParameter("borrowId");
        if (isBlank(borrowIdStr)) {
            writeJson(response, Map.of(
                    "ok", false,
                    "message", "Thiếu borrowId!"
            ), 400);
            return;
        }

        int borrowId = Integer.parseInt(borrowIdStr);

        RejectBorrowRequest dto = new RejectBorrowRequest();
        dto.borrowId = borrowId;

        try {
            borrowService.rejectBorrow(dto);
            writeJson(response, Map.of(
                    "ok", true,
                    "message", "Từ chối yêu cầu thành công!"
            ), 200);
        } catch (IllegalStateException ex) {
            if ("BORROW_NOT_FOUND".equals(ex.getMessage())) {
                writeJson(response, Map.of(
                        "ok", false,
                        "message", "Không tìm thấy yêu cầu."
                ), 404);
            } else {
                throw ex;
            }
        }
    }

    private void handleReturn(HttpServletRequest request, HttpServletResponse response) throws Exception {
        String borrowIdStr = request.getParameter("borrowId");
        if (isBlank(borrowIdStr)) {
            writeJson(response, Map.of(
                    "ok", false,
                    "message", "Thiếu borrowId!"
            ), 400);
            return;
        }

        int borrowId = Integer.parseInt(borrowIdStr);

        ReturnBorrowAdminRequest dto = new ReturnBorrowAdminRequest();
        dto.borrowId = borrowId;

        ReturnBorrowResult res = borrowService.adminReturn(dto);

        writeJson(response, Map.of(
                "ok", res.success,
                "message", res.message,
                "fineAmount", res.fineAmount
        ), 200);
    }

    // ====== util ======
    private static String safe(String s) { return s == null ? "" : s; }
    private static boolean isBlank(String s) { return s == null || s.trim().isEmpty(); }

    private static void writeJson(HttpServletResponse resp, Map<String,?> obj, int status) throws IOException {
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
        resp.setHeader("Pragma", "no-cache");
        resp.setDateHeader("Expires", 0);
        resp.setContentLength(data.length);

        try (OutputStream os = resp.getOutputStream()) {
            os.write(data);
            os.flush();
        }
    }
}
