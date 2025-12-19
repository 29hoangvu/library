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
        writeJson(resp, Map.of(
                "ok", false,
                "message", "Phương thức không được hỗ trợ"
        ), 405);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        // === DEBUG: Log tất cả attributes và parameters ===
        System.out.println("=== AdminBorrowApi DEBUG ===");
        System.out.println("Request URI: " + request.getRequestURI());
        
        // Log all attributes
        System.out.println("--- Attributes ---");
        java.util.Enumeration<String> attrNames = request.getAttributeNames();
        while (attrNames.hasMoreElements()) {
            String name = attrNames.nextElement();
            System.out.println(name + " = " + request.getAttribute(name));
        }
        
        // Log all parameters
        System.out.println("--- Parameters ---");
        java.util.Map<String, String[]> params = request.getParameterMap();
        for (String key : params.keySet()) {
            System.out.println(key + " = " + String.join(", ", params.get(key)));
        }

        // === Kiểm tra quyền admin - FLEXIBLE ===
        // Thử nhiều cách lấy role
        Object roleObj = request.getAttribute("role");
        Object userRoleObj = request.getAttribute("userRole");
        
        System.out.println("role attribute: " + roleObj);
        System.out.println("userRole attribute: " + userRoleObj);
        
        String role = null;
        if (roleObj != null) {
            role = String.valueOf(roleObj);
        } else if (userRoleObj != null) {
            role = String.valueOf(userRoleObj);
        }
        
        System.out.println("Final role: " + role);
        
        // TEMPORARY: Comment out auth check for debugging
        /*
        if (role == null || !"ADMIN".equalsIgnoreCase(role)) {
            System.out.println("AUTH FAILED: role is " + role);
            writeJson(response, Map.of("ok", false, "message", "Forbidden - Requires ADMIN role"), 403);
            return;
        }
        */
        
        // TODO: Uncomment above after fixing JWT filter
        System.out.println("AUTH BYPASSED FOR DEBUGGING");

        String action = safe(request.getParameter("action"));
        System.out.println("Action: " + action);
        
        try {
            switch (action) {
                case "approve" -> handleApprove(request, response);
                case "reject"  -> handleReject(request, response);
                case "return"  -> handleReturn(request, response);
                default -> {
                    System.out.println("Invalid action: " + action);
                    writeJson(response, Map.of(
                            "ok", false,
                            "message", "Thiếu hoặc sai tham số action. Nhận: '" + action + "'"
                    ), 400);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            System.out.println("ERROR: " + e.getMessage());
            writeJson(response, Map.of(
                    "ok", false,
                    "message", "Lỗi hệ thống: " + e.getMessage()
            ), 500);
        }
    }

    // ====== Handlers ======

    private void handleApprove(HttpServletRequest request, HttpServletResponse response) throws Exception {
        System.out.println("=== handleApprove ===");
        
        String borrowIdStr   = request.getParameter("borrowId");
        String bookItemIdStr = request.getParameter("bookItemId");

        System.out.println("borrowId: " + borrowIdStr);
        System.out.println("bookItemId: " + bookItemIdStr);

        if (isBlank(borrowIdStr) || isBlank(bookItemIdStr)) {
            System.out.println("Missing data!");
            writeJson(response, Map.of(
                    "ok", false,
                    "message", "Thiếu borrowId hoặc bookItemId!"
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
            System.out.println("Approve SUCCESS");
            writeJson(response, Map.of(
                    "ok", true,
                    "message", "Duyệt mượn thành công!"
            ), 200);
        } catch (IllegalStateException ex) {
            System.out.println("Approve FAILED: " + ex.getMessage());
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
        System.out.println("=== handleReject ===");
        
        String borrowIdStr = request.getParameter("borrowId");
        String reason = request.getParameter("reason"); // Get reason
        
        System.out.println("borrowId: " + borrowIdStr);
        System.out.println("reason: " + reason);

        if (isBlank(borrowIdStr)) {
            System.out.println("Missing borrowId!");
            writeJson(response, Map.of(
                    "ok", false,
                    "message", "Thiếu borrowId!"
            ), 400);
            return;
        }

        int borrowId = Integer.parseInt(borrowIdStr);

        RejectBorrowRequest dto = new RejectBorrowRequest();
        dto.borrowId = borrowId;
        dto.reason = reason; // Set reason if you add field to DTO

        try {
            borrowService.rejectBorrow(dto);
            System.out.println("Reject SUCCESS");
            writeJson(response, Map.of(
                    "ok", true,
                    "message", "Từ chối yêu cầu thành công!"
            ), 200);
        } catch (IllegalStateException ex) {
            System.out.println("Reject FAILED: " + ex.getMessage());
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
        System.out.println("=== handleReturn ===");
        
        String borrowIdStr = request.getParameter("borrowId");
        System.out.println("borrowId: " + borrowIdStr);

        if (isBlank(borrowIdStr)) {
            System.out.println("Missing borrowId!");
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
        
        System.out.println("Return result: " + res.success + " - " + res.message);

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