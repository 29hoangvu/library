// src/main/java/api/admin/AdminReviewUserApi.java
package api.admin;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;

import dto.admin.ReviewUserRequest;
import dto.admin.ReviewUserResult;
import service.admin.AdminUserManagementService;
import util.JsonUtil;

@WebServlet(name="AdminReviewUserApi", urlPatterns={"/api/admin/review-user"})
public class AdminReviewUserApi extends HttpServlet {

    private final AdminUserManagementService svc = new AdminUserManagementService();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        // (tuỳ) kiểm tra quyền ADMIN
        Object role = req.getAttribute("role");
        if (role != null && !"ADMIN".equalsIgnoreCase(String.valueOf(role))) {
            JsonUtil.writeJson(resp, 403, err("Chỉ ADMIN được phép duyệt."));
            return;
        }

        String idStr  = trim(req.getParameter("userID"));
        String action = trim(req.getParameter("action")); // "approve" | "reject"

        if (isBlank(idStr) || isBlank(action)) {
            JsonUtil.writeJson(resp, 400, err("Thiếu userID hoặc action."));
            return;
        }

        int userId;
        try {
            userId = Integer.parseInt(idStr);
        } catch (NumberFormatException e) {
            JsonUtil.writeJson(resp, 400, err("userID không hợp lệ."));
            return;
        }

        ReviewUserRequest dto = new ReviewUserRequest();
        dto.userId = userId;
        dto.action = action;

        try {
            ReviewUserResult res = svc.reviewUser(dto);
            Map<String,Object> out = new LinkedHashMap<>();
            out.put("ok", res.ok);
            out.put("message", res.message);
            Map<String,Object> data = new LinkedHashMap<>();
            data.put("userID", res.userId);
            data.put("action", res.action);
            out.put("data", data);

            JsonUtil.writeJson(resp, 200, out);

        } catch (IllegalArgumentException ex) {
            if ("INVALID_ACTION".equals(ex.getMessage())) {
                JsonUtil.writeJson(resp, 400, err("action phải là approve hoặc reject."));
            } else {
                JsonUtil.writeJson(resp, 400, err("Tham số không hợp lệ."));
            }

        } catch (IllegalStateException ex) {
            if ("NOT_FOUND_OR_ALREADY_HANDLED".equals(ex.getMessage())) {
                JsonUtil.writeJson(resp, 404, err("Không tìm thấy user PENDING hoặc đã được xử lý."));
            } else {
                JsonUtil.writeJson(resp, 400, err("Lỗi nghiệp vụ: " + ex.getMessage()));
            }

        } catch (Exception e) {
            e.printStackTrace();
            JsonUtil.writeJson(resp, 500, err("Lỗi máy chủ / CSDL."));
        }
    }

    private static String trim(String s){ return s==null? null : s.trim(); }
    private static boolean isBlank(String s){ return s==null || s.trim().isEmpty(); }

    private static Map<String,Object> err(String msg){
        return new LinkedHashMap<String,Object>(){{
            put("ok", false);
            put("message", msg);
        }};
    }
}
