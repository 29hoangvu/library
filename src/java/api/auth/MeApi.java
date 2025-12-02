// api/auth/MeApi.java
package api.auth;

import api.BaseApiServlet;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import util.JsonUtil;
import java.util.Map;

@WebServlet(name="MeApi", urlPatterns={"/api/auth/me"})
public class MeApi extends BaseApiServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) {
        try {
            Object uid = req.getAttribute("uid");
            Object username = req.getAttribute("username");
            Object role = req.getAttribute("role");
            Object roleID = req.getAttribute("roleID");

            if (uid == null) {
                JsonUtil.writeJson(resp, 401, Map.of("message", "Unauthorized"));
                return;
            }

            JsonUtil.writeJson(resp, 200, Map.of(
                "uid", uid,
                "username", username,
                "role", role,
                "roleID", roleID
            ));
        } catch (Exception e) {
            try {
                JsonUtil.writeJson(resp, 500, Map.of("message", "Internal Error"));
            } catch (Exception ignore) {}
        }
    }
}

