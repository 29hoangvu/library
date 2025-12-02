// api/BaseApiServlet.java
package api;

import jakarta.servlet.http.*;
import util.JsonUtil;
import util.ApiError;

import java.io.BufferedReader;

public abstract class BaseApiServlet extends HttpServlet {

    // --------------------------
    // Đọc JSON từ body
    // --------------------------
    protected <T> T readJson(HttpServletRequest req, Class<T> clazz) throws Exception {
        try (BufferedReader br = req.getReader()) {
            return JsonUtil.MAPPER.readValue(br, clazz);
        }
    }

    // --------------------------
    // 200 OK
    // --------------------------
    protected void ok(HttpServletResponse resp, Object data) {
        try {
            JsonUtil.writeJson(resp, 200, data);
            return;
        } catch (Exception e) {
            safe500(resp, e);
        }
    }

    // --------------------------
    // 201 Created
    // --------------------------
    protected void created(HttpServletResponse resp, Object body) {
        try {
            JsonUtil.writeJson(resp, 201, body);
            return;
        } catch (Exception e) {
            safe500(resp, e);
        }
    }

    // --------------------------
    // 400 Bad Request
    // --------------------------
    protected void bad(HttpServletResponse resp, String msg) {
        try {
            JsonUtil.writeJson(resp, 400, ApiError.of(msg));
            return;
        } catch (Exception e) {
            safe500(resp, e);
        }
    }

    // --------------------------
    // Generic error
    // --------------------------
    protected void error(HttpServletResponse resp, int status, Object data) {
        try {
            JsonUtil.writeJson(resp, status, data);
            return;
        } catch (Exception e) {
            safe500(resp, e);
        }
    }

    // --------------------------
    // ⭐ 500 Internal Error (chuẩn)
    // --------------------------
    protected void safe500(HttpServletResponse resp, Exception e) {
        try {
            e.printStackTrace(); // log lỗi

            JsonUtil.writeJson(resp, 500, ApiError.of("Internal Server Error"));
        } catch (Exception ignored) {
            // fallback
            try {
                resp.resetBuffer();
                resp.setStatus(500);
                resp.setContentType("application/json; charset=UTF-8");
                resp.getWriter().write("{\"ok\":false,\"message\":\"Fatal Server Error\"}");
            } catch (Exception ignore2) {
                // ignored
            }
        }
    }
}
