// src/main/java/service/AdminUserManagementService.java
package service.admin;

import Servlet.DBConnection;
import dto.admin.*;

import java.sql.*;
import java.time.LocalDate;

import java.util.ArrayList;
import java.util.List;

public class AdminUserManagementService {

    // ===== Pending users =====

    public PendingUsersPage getPendingUsers(int page, int size) throws Exception {
        if (page < 1) page = 1;
        if (size < 1 || size > 100) size = 10;
        int offset = (page - 1) * size;

        PendingUsersPage out = new PendingUsersPage();
        out.page = page;
        out.size = size;

        try (Connection con = DBConnection.getConnection()) {
            long total = countPending(con);
            List<PendingUserItem> items = listPending(con, size, offset);
            int totalPages = (int) Math.ceil(total / (double) size);

            out.ok = true;
            out.message = "OK";
            out.total = total;
            out.totalPages = totalPages;
            out.items = items;
            return out;
        }
    }

    private long countPending(Connection c) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(
                "SELECT COUNT(*) FROM users WHERE status='PENDING'")) {
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getLong(1);
            }
        }
    }

    private List<PendingUserItem> listPending(Connection c, int limit, int offset) throws SQLException {
        String sql = "SELECT id, username, email FROM users WHERE status='PENDING' ORDER BY id DESC LIMIT ? OFFSET ?";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, limit);
            ps.setInt(2, offset);
            try (ResultSet rs = ps.executeQuery()) {
                List<PendingUserItem> out = new ArrayList<>();
                while (rs.next()) {
                    PendingUserItem item = new PendingUserItem();
                    item.id = rs.getInt("id");
                    item.username = rs.getString("username");
                    item.email = rs.getString("email");
                    out.add(item);
                }
                return out;
            }
        }
    }

    // ===== Review user (approve / reject) =====

    /**
     * Ném IllegalArgumentException("INVALID_ACTION") nếu action không phải approve/reject
     * Ném IllegalStateException("NOT_FOUND_OR_ALREADY_HANDLED") nếu không có user PENDING tương ứng
     */
    public ReviewUserResult reviewUser(ReviewUserRequest req) throws Exception {
        String action = req.action == null ? "" : req.action.trim().toLowerCase();
        if (!"approve".equals(action) && !"reject".equals(action)) {
            throw new IllegalArgumentException("INVALID_ACTION");
        }

        int affected = 0;
        try (Connection con = DBConnection.getConnection()) {
            if ("approve".equals(action)) {
                LocalDate oneYear = LocalDate.now().plusYears(1);
                java.sql.Date exp = java.sql.Date.valueOf(oneYear);

                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE users SET status='ACTIVE', expiryDate=? WHERE id=? AND status='PENDING'")) {
                    ps.setDate(1, exp);
                    ps.setInt(2, req.userId);
                    affected = ps.executeUpdate();
                }
            } else { // reject
                try (PreparedStatement ps = con.prepareStatement(
                        "DELETE FROM users WHERE id=? AND status='PENDING'")) {
                    ps.setInt(1, req.userId);
                    affected = ps.executeUpdate();
                }
            }
        }

        if (affected <= 0) {
            throw new IllegalStateException("NOT_FOUND_OR_ALREADY_HANDLED");
        }

        ReviewUserResult res = new ReviewUserResult();
        res.ok = true;
        res.message = "Cập nhật thành công.";
        res.userId = req.userId;
        res.action = action;
        return res;
    }

    // ===== Admin users list =====

    public AdminUsersPage getUsers(AdminUsersQuery query) throws Exception {
        int page = query.page < 1 ? 1 : query.page;
        int size = (query.size < 1 || query.size > 200) ? 10 : query.size;
        int offset = (page - 1) * size;

        StringBuilder where = new StringBuilder(" WHERE 1=1 ");
        List<Object> params = new ArrayList<>();

        if (query.searchUsername != null && !query.searchUsername.trim().isEmpty()) {
            where.append(" AND username LIKE ? ");
            params.add("%" + query.searchUsername.trim() + "%");
        }
        if (query.roleId != null) {
            where.append(" AND roleID = ? ");
            params.add(query.roleId);
        }

        String countSql = "SELECT COUNT(*) FROM users " + where;
        String dataSql =
                "SELECT id, username, roleID, status, expiryDate " +
                "FROM users " + where +
                " ORDER BY id DESC LIMIT ? OFFSET ?";

        AdminUsersPage out = new AdminUsersPage();
        out.page = page;
        out.size = size;

        try (Connection con = DBConnection.getConnection()) {
            long total = 0L;
            try (PreparedStatement ps = con.prepareStatement(countSql)) {
                bind(ps, params);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) total = rs.getLong(1);
                }
            }

            List<AdminUserItem> items = new ArrayList<>();
            List<Object> p2 = new ArrayList<>(params);
            p2.add(size);
            p2.add(offset);

            try (PreparedStatement ps = con.prepareStatement(dataSql)) {
                bind(ps, p2);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        AdminUserItem row = new AdminUserItem();
                        row.id = rs.getInt("id");
                        row.username = rs.getString("username");
                        row.roleId = rs.getInt("roleID");
                        row.roleText = mapRoleText(row.roleId);
                        row.status = rs.getString("status");
                        row.expiryDate = rs.getString("expiryDate"); // có thể null
                        items.add(row);
                    }
                }
            }

            int totalPages = (int) Math.ceil(total / (double) size);
            out.ok = true;
            out.message = "OK";
            out.total = total;
            out.totalPages = totalPages;
            out.items = items;
            return out;
        }
    }

    private static void bind(PreparedStatement ps, List<Object> params) throws SQLException {
        int i = 1;
        for (Object p : params) {
            if (p instanceof Integer) {
                ps.setInt(i++, (Integer) p);
            } else if (p instanceof Long) {
                ps.setLong(i++, (Long) p);
            } else {
                ps.setString(i++, String.valueOf(p));
            }
        }
    }

    private static String mapRoleText(int roleID) {
        if (roleID == 1) return "Admin";
        if (roleID == 2) return "Librarian";
        return "Member";
    }
}
