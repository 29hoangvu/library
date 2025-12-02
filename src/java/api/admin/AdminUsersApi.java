 // src/main/java/api/admin/AdminUsersApi.java
package api.admin;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;

import dto.admin.AdminUsersQuery;
import dto.admin.AdminUsersPage;
import service.admin.AdminUserManagementService;
import util.JsonUtil;

@WebServlet(name="AdminUsersApi", urlPatterns={"/api/admin/users"})
public class AdminUsersApi extends HttpServlet {

    private final AdminUserManagementService svc = new AdminUserManagementService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        req.setCharacterEncoding("UTF-8");

        String searchUsername = trim(req.getParameter("searchUsername"));
        String filterRoleStr  = trim(req.getParameter("filterRole")); // "1"/"2"/"3" hoặc rỗng
        int page = parseInt(req.getParameter("page"), 1);   // 1-based
        int size = parseInt(req.getParameter("size"), 10);  // mặc định 10

        Integer roleId = null;
        if (!isBlank(filterRoleStr)) {
            try {
                roleId = Integer.parseInt(filterRoleStr);
            } catch (NumberFormatException e) {
                JsonUtil.writeJson(resp, 400, err("filterRole không hợp lệ."));
                return;
            }
        }

        AdminUsersQuery q = new AdminUsersQuery();
        q.searchUsername = searchUsername;
        q.roleId = roleId;
        q.page = page;
        q.size = size;

        try {
            AdminUsersPage result = svc.getUsers(q);
            JsonUtil.writeJson(resp, 200, result);
        } catch (Exception e) {
            e.printStackTrace();
            JsonUtil.writeJson(resp, 500, err("Lỗi máy chủ hoặc CSDL."));
        }
    }

    // ===== helpers =====
    private static String trim(String s){ return s==null? null : s.trim(); }
    private static boolean isBlank(String s){ return s==null || s.trim().isEmpty(); }

    private static int parseInt(String s, int def){
        try { return Integer.parseInt(s); } catch (Exception e) { return def; }
    }

    private static Map<String,Object> err(String msg){
        return new LinkedHashMap<String,Object>(){{
            put("ok", false);
            put("message", msg);
        }};
    }
}
