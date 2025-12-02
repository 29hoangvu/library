// api/auth/AuthApi.java
package api.auth;

import api.BaseApiServlet;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import service.AuthService;
import util.JsonUtil;
import util.JwtUtil;

import java.util.Map;

@WebServlet(name="AuthApi", urlPatterns={"/api/auth/login"})
public class AuthApi extends BaseApiServlet {
    private final AuthService svc = new AuthService();

    static class LoginReq { 
        public String username; 
        public String password; 
    }

    @Override 
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        try {
            // đọc body JSON thành LoginReq
            LoginReq body = readJson(req, LoginReq.class);

            // gọi service login
            var user = svc.login(body.username, body.password);
            if (user == null) {
                JsonUtil.writeJson(resp, 401, Map.of("message", "Sai tài khoản hoặc mật khẩu"));
                return;
            }

            // phát hành JWT
            String token = JwtUtil.issue(Map.of(
                "uid", user.get("uid"),
                "username", user.get("username"),
                "role", user.get("role"),
                "roleID", user.get("roleID")
            ));

            // log ra console server để debug
            System.out.println("[AuthApi] Login OK, user=" + user.get("username") + ", token=" + token);

            // trả về JSON cho frontend
            JsonUtil.writeJson(resp, 200, Map.of(
                "token", token,
                "user", Map.of(
                    "uid", user.get("uid"),
                    "username", user.get("username"),
                    "role", user.get("role"),
                    "roleID", user.get("roleID")
                )
            ));

        } catch (IllegalStateException bad) {
            JsonUtil.writeJson(resp, 403, Map.of("message", bad.getMessage()));
        } catch (Exception e) {
            e.printStackTrace();
            JsonUtil.writeJson(resp, 500, Map.of("message", "Internal Error", "error", e.getMessage()));
        }
    }
}
