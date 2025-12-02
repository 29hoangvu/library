// src/main/java/api/admin/AdminPendingUsersApi.java
package api.admin;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;

import dto.admin.PendingUsersPage;
import service.admin.AdminUserManagementService;
import util.JsonUtil;

@WebServlet(name="AdminPendingUsersApi", urlPatterns={"/api/admin/pending-users"})
public class AdminPendingUsersApi extends HttpServlet {

    private final AdminUserManagementService svc = new AdminUserManagementService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        // (tuỳ) kiểm tra quyền ADMIN
        Object role = req.getAttribute("role");
        if (role != null && !"ADMIN".equalsIgnoreCase(String.valueOf(role))) {
            JsonUtil.writeJson(resp, 403, err("Chỉ ADMIN được phép truy cập."));
            return;
        }

        int page = parseInt(req.getParameter("page"), 1);
        int size = parseInt(req.getParameter("size"), 10);

        try {
            PendingUsersPage result = svc.getPendingUsers(page, size);
            JsonUtil.writeJson(resp, 200, result);
        } catch (Exception e) {
            e.printStackTrace();
            JsonUtil.writeJson(resp, 500, err("Lỗi máy chủ / CSDL."));
        }
    }

    private static int parseInt(String s, int d){
        try { return Integer.parseInt(s); } catch(Exception e){ return d; }
    }

    private static Map<String,Object> err(String msg){
        return new LinkedHashMap<String,Object>(){{
            put("ok", false);
            put("message", msg);
        }};
    }
}
