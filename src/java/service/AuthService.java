// service/AuthService.java
package service;

import Servlet.DBConnection;
import java.security.MessageDigest;
import java.sql.*;
import java.time.LocalDate;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.Map;

public class AuthService {

    private static String sha256(String s) throws Exception {
        var md = MessageDigest.getInstance("SHA-256");
        return HexFormat.of().formatHex(md.digest(s.getBytes("UTF-8")));
    }

    private static String roleNameFromId(int roleID) {
        // Tùy DB của bạn: 1 = ADMIN, 3 = USER (theo dữ liệu bạn gửi)
        if (roleID == 1) return "ADMIN";
        return "USER";
    }

    /**
     * @return user map { uid, username, role, status, expiryDate, email } nếu ok, hoặc null nếu sai user/pass
     * @throws IllegalStateException nếu tài khoản không ACTIVE hoặc hết hạn
     */
    public Map<String, Object> login(String username, String rawPassword) throws Exception {
        String passHex = sha256(rawPassword);

        String sql = """
            SELECT id, username, password, status, expiryDate, roleID, email
            FROM users
            WHERE username = ?
            LIMIT 1
        """;

        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {

            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;

                String stored = rs.getString("password"); // cột tên "password"
                if (stored == null || !stored.equalsIgnoreCase(passHex)) {
                    return null; // sai mật khẩu
                }

                String status = rs.getString("status");      // ACTIVE / EXPIRED / ...
                Date expiry = rs.getDate("expiryDate");      // có thể NULL
                int roleID = rs.getInt("roleID");
                String role = roleNameFromId(roleID);

                // Kiểm tra trạng thái/ hạn dùng (tùy logic mong muốn)
                if (status != null && !"ACTIVE".equalsIgnoreCase(status)) {
                    throw new IllegalStateException("Account status = " + status);
                }
                if (expiry != null) {
                    LocalDate exp = expiry.toLocalDate();
                    if (exp.isBefore(LocalDate.now())) {
                        throw new IllegalStateException("Membership expired on " + exp);
                    }
                }

                Map<String,Object> user = new LinkedHashMap<>();
                user.put("uid", rs.getInt("id"));
                user.put("username", rs.getString("username"));
                user.put("role", role);
                user.put("roleID", roleID); 
                user.put("status", status);
                user.put("expiryDate", expiry == null ? null : expiry.toLocalDate().toString());
                user.put("email", rs.getString("email"));
                return user;
            }
        }
    }
}
