package api.borrows;

import api.BaseApiServlet;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.sql.*;
import java.util.*;

import Servlet.DBConnection;

@WebServlet(name = "BorrowCancelApi", urlPatterns = {"/api/borrow/cancel"})
public class BorrowCancelApi extends BaseApiServlet {

    static class CancelReq {
        public Integer borrowId;
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Object uidObj = req.getAttribute("uid");
        if (uidObj == null) {
            writeJson(resp, Map.of("message", "Unauthorized"), 401);
            return;
        }
        int uid = (Integer) uidObj;

        CancelReq body;
        try {
            body = readJson(req, CancelReq.class);
        } catch (Exception e) {
            writeJson(resp, Map.of("message", "Invalid JSON"), 400);
            return;
        }

        if (body == null || body.borrowId == null || body.borrowId <= 0) {
            writeJson(resp, Map.of("message", "Missing borrowId"), 400);
            return;
        }

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            Integer ownerId = null;
            String status = null;
            try (PreparedStatement ps = conn.prepareStatement(
                "SELECT user_id, status FROM borrow WHERE borrow_id = ? FOR UPDATE")) {
                ps.setInt(1, body.borrowId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        ownerId = rs.getInt("user_id");
                        status  = rs.getString("status");
                    }
                }
            }

            if (ownerId == null) {
                conn.rollback();
                writeJson(resp, Map.of("message", "Không tìm thấy yêu cầu mượn"), 404);
                return;
            }
            if (ownerId != uid) {
                conn.rollback();
                writeJson(resp, Map.of("message", "Bạn không có quyền hủy yêu cầu này"), 403);
                return;
            }
            if (!"Pending Approval".equals(status)) {
                conn.rollback();
                writeJson(resp, Map.of("message", "Chỉ hủy được yêu cầu đang chờ duyệt"), 409);
                return;
            }

            int rows;
            try (PreparedStatement ps = conn.prepareStatement(
                "UPDATE borrow SET status='Cancelled' WHERE borrow_id=?")) {
                ps.setInt(1, body.borrowId);
                rows = ps.executeUpdate();
            }

            if (rows == 0) {
                conn.rollback();
                writeJson(resp, Map.of("message", "Không thể hủy yêu cầu"), 500);
                return;
            }

            conn.commit();
            writeJson(resp, Map.of(
                "message", "Đã hủy yêu cầu mượn",
                "borrowId", body.borrowId,
                "status", "Cancelled"
            ), 200);

        } catch (Exception e) {
            e.printStackTrace();
            writeJson(resp, Map.of("message", "Internal error: " + e.getMessage()), 500);
        }
    }
    private void writeJson(HttpServletResponse resp, Object obj, int status) throws IOException {
        String json = new com.google.gson.GsonBuilder().disableHtmlEscaping().create().toJson(obj);
        byte[] data = json.getBytes(StandardCharsets.UTF_8);

        resp.setStatus(status);
        resp.setCharacterEncoding("UTF-8");
        resp.setContentType("application/json; charset=UTF-8");
        resp.setContentLength(data.length);

        try (OutputStream os = resp.getOutputStream()) {
            os.write(data);
            os.flush();
        }
    }
}
