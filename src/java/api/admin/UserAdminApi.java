package api.admin;

import api.BaseApiServlet;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import util.JsonUtil;
import java.sql.*;
import Servlet.DBConnection;
import service.AdminResetPasswordService;

@WebServlet(name="UserAdminApi", urlPatterns = {
        "/api/admin/am-users/*",
        "/api/admin/am-users/reset/*"
})
public class UserAdminApi extends BaseApiServlet {

    // --------- GET /api/admin/am-users/{id} : xem chi tiết ----------
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp){
        String path = req.getPathInfo(); // "/{id}"
        try(Connection conn = DBConnection.getConnection()){
            if (path == null || path.length() <= 1) {
                bad(resp, "Thiếu user id");
                return;
            }
            int id = Integer.parseInt(path.substring(1));

            var st = conn.prepareStatement(
                "SELECT id, username, email, status, roleID, expiryDate FROM users WHERE id=?"
            );
            st.setInt(1,id);
            var rs = st.executeQuery();
            if(!rs.next()){
                bad(resp,"User không tồn tại.");
                return;
            }
            var map = new java.util.LinkedHashMap<String,Object>();
            map.put("ok", true);
            map.put("id", rs.getInt("id"));
            map.put("username", rs.getString("username"));
            map.put("email", rs.getString("email"));
            map.put("status", rs.getString("status"));
            map.put("roleID", rs.getInt("roleID"));
            map.put("expiryDate", rs.getDate("expiryDate"));
            JsonUtil.writeJson(resp, 200, map);
        }catch(Exception e){ safe500(resp,e); }
    }

    // --------- PUT /api/admin/am-users/{id} : cập nhật ----------
    @Override
    protected void doPut(HttpServletRequest req, HttpServletResponse resp){
        try{
            var body = readJson(req); // {"email":"..","status":"ACTIVE","roleID":2}
            String path = req.getPathInfo();
            if (path == null || path.length() <= 1) {
                bad(resp, "Thiếu user id");
                return;
            }
            int id = Integer.parseInt(path.substring(1));

            try(Connection conn = DBConnection.getConnection()){
                var st = conn.prepareStatement(
                    "UPDATE users SET email=?, status=?, roleID=?, updatedAt=NOW() WHERE id=?"
                );
                st.setString(1,(String)body.get("email"));
                st.setString(2,(String)body.get("status"));
                st.setInt(3, ((Number)body.get("roleID")).intValue());
                st.setInt(4,id);
                int n = st.executeUpdate();
                if(n==0){
                    bad(resp,"Không cập nhật được");
                    return;
                }

                var res = new java.util.LinkedHashMap<String,Object>();
                res.put("ok", true);
                res.put("message", "Cập nhật thành công");
                JsonUtil.writeJson(resp, 200, res);
            }
        }catch(Exception e){ safe500(resp,e); }
    }

    // --------- DELETE /api/admin/am-users/{id} : xóa ----------
    @Override
    protected void doDelete(HttpServletRequest req, HttpServletResponse resp){
        try(Connection conn = DBConnection.getConnection()){
            String path = req.getPathInfo();
            if (path == null || path.length() <= 1) {
                bad(resp, "Thiếu user id");
                return;
            }
            int id = Integer.parseInt(path.substring(1));

            var st = conn.prepareStatement("DELETE FROM users WHERE id=?");
            st.setInt(1,id);
            st.executeUpdate();

            var res = new java.util.LinkedHashMap<String,Object>();
            res.put("ok", true);
            res.put("message", "Đã xóa user");
            JsonUtil.writeJson(resp, 200, res);
        }catch(Exception e){ safe500(resp,e); }
    }

    // --------- POST /api/admin/am-users/reset/{id} : reset MK + gửi mail ----------
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp){
        // mapping: /api/admin/am-users/reset/*  => pathInfo là "/{id}"
        String path = req.getPathInfo();   // "/5"
        if (path == null || path.length() <= 1) {
            bad(resp, "Thiếu user id");
            return;
        }

        try{
            int id = Integer.parseInt(path.substring(1));

            AdminResetPasswordService svc = new AdminResetPasswordService();
            AdminResetPasswordService.ResetResult res = svc.resetUserPassword(id);

            var payload = new java.util.LinkedHashMap<String,Object>();
            payload.put("ok", res.ok);
            payload.put("message", res.message);
            payload.put("emailSent", res.emailSent);

            JsonUtil.writeJson(resp, 200, payload);
        }catch(Exception e){
            safe500(resp,e);
        }
    }

    // --------- helpers ----------
    @SuppressWarnings("unchecked")
    protected java.util.Map<String,Object> readJson(HttpServletRequest req){
        try {
            java.io.InputStream is = req.getInputStream();
            return util.JsonUtil.MAPPER.readValue(is, java.util.Map.class);
        } catch (Exception e){
            return new java.util.HashMap<>();
        }
    }
}
