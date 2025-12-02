// api/admin/AdminCreateUserApi.java
package api.admin;

import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;

import util.JsonUtil;
import dto.admin.AdminCreateUserRequest;
import dto.admin.AdminCreateUserResult;
import service.AdminUserService;

@WebServlet(name="AdminCreateUserApi", urlPatterns={"/api/admin/cre-users"})
@MultipartConfig
public class AdminCreateUserApi extends HttpServlet {

    private final AdminUserService adminUserService = new AdminUserService();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        req.setCharacterEncoding("UTF-8");

        // 1) Kiểm tra quyền ADMIN (nếu JwtAuthFilter đã set "role")
        Object roleObj = req.getAttribute("role");
        if (roleObj != null && !"ADMIN".equalsIgnoreCase(String.valueOf(roleObj))) {
            JsonUtil.writeJson(resp, 403, err("Chỉ ADMIN mới được tạo tài khoản."));
            return;
        }

        // 2) Nhận param từ form-data hoặc x-www-form-urlencoded
        String username  = trim(req.getParameter("username"));
        String email     = trim(req.getParameter("email"));
        String roleStr   = trim(req.getParameter("roleID")); // 1/2/3

        // optional profile
        String fullName  = trim(req.getParameter("fullName"));
        String gender    = trim(req.getParameter("gender"));     // Nam/Nữ/Khác
        String birthDate = trim(req.getParameter("birthDate"));  // yyyy-MM-dd
        String phone     = trim(req.getParameter("phone"));
        String address   = trim(req.getParameter("address"));

        // 3) Validate input HTTP-level
        if (isBlank(username) || isBlank(email) || isBlank(roleStr)) {
            JsonUtil.writeJson(resp, 400, err("Thiếu username, email hoặc roleID."));
            return;
        }

        int roleID;
        try {
            roleID = Integer.parseInt(roleStr);
            if (roleID < 1 || roleID > 3) throw new NumberFormatException();
        } catch (NumberFormatException e) {
            JsonUtil.writeJson(resp, 400, err("roleID không hợp lệ."));
            return;
        }

        // 4) Build DTO cho service
        AdminCreateUserRequest dto = new AdminCreateUserRequest();
        dto.username  = username;
        dto.email     = email;
        dto.roleId    = roleID;
        dto.fullName  = fullName;
        dto.gender    = gender;
        dto.birthDate = birthDate;
        dto.phone     = phone;
        dto.address   = address;

        // 5) Gọi service
        try {
            AdminUserService svc = this.adminUserService;
            AdminCreateUserResult res = svc.createUser(dto);

            Map<String,Object> payload = new LinkedHashMap<>();
            payload.put("ok", res.success);
            payload.put("message", res.message);
            Map<String,Object> data = new LinkedHashMap<>();
            data.put("id", res.userId);
            data.put("username", res.username);
            data.put("email", res.email);
            data.put("emailSent", res.emailSent);
            payload.put("data", data);

            JsonUtil.writeJson(resp, 200, payload);

        } catch (IllegalStateException ex) {
            String code = ex.getMessage();
            if ("USERNAME_EXISTS".equals(code)) {
                JsonUtil.writeJson(resp, 409, err("Username đã tồn tại."));
            } else if ("EMAIL_EXISTS".equals(code)) {
                JsonUtil.writeJson(resp, 409, err("Email đã tồn tại."));
            } else {
                JsonUtil.writeJson(resp, 400, err("Lỗi nghiệp vụ: " + code));
            }
        } catch (Exception e) {
            e.printStackTrace();
            JsonUtil.writeJson(resp, 500, err("Lỗi máy chủ / CSDL."));
        }
    }

    // ===== helpers JSON / string =====
    private static String trim(String s){ return s == null ? null : s.trim(); }
    private static boolean isBlank(String s){ return s == null || s.trim().isEmpty(); }

    private static Object err(String msg){
        return new LinkedHashMap<String,Object>(){{
            put("ok", false);
            put("message", msg);
        }};
    }
}
