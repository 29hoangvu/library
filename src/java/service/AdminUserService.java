// service/AdminUserService.java
//Tao ng dung phia admin
package service;

import Servlet.DBConnection;
import Servlet.PasswordHashing;
import Servlet.EmailUtility;
import Data.UserDAO;
import Data.Users;

import dto.admin.AdminCreateUserRequest;
import dto.admin.AdminCreateUserResult;

import java.security.SecureRandom;
import java.sql.*;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Date;

public class AdminUserService {

    private final UserDAO userDAO = new UserDAO();

    /**
     * Tạo user mới bởi ADMIN.
     * Giả định: username, email, roleId đã được validate ở API.
     * Ném IllegalStateException với code:
     *  - "USERNAME_EXISTS"
     *  - "EMAIL_EXISTS"
     */
    public AdminCreateUserResult createUser(AdminCreateUserRequest req) throws Exception {
        // 1) Tạo mật khẩu random + hash
        String rawPassword = genPass(12);
        String hashed = PasswordHashing.hashPassword(rawPassword);

        // 2) expiryDate: Member (3) thì +1 năm, Admin/Librarian để NULL
        Date expiryDate = null;
        if (req.roleId != 1 && req.roleId != 2) {
            LocalDate oneYear = LocalDate.now().plusYears(1);
            expiryDate = Date.from(oneYear.atStartOfDay(ZoneId.systemDefault()).toInstant());
        }

        int newId;
        boolean emailSent = false;

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            try {
                // 3) Check trùng username
                if (exists(conn, "SELECT 1 FROM users WHERE username = ?", req.username)) {
                    conn.rollback();
                    throw new IllegalStateException("USERNAME_EXISTS");
                }

                // 4) Check trùng email
                if (exists(conn, "SELECT 1 FROM users WHERE email = ?", req.email)) {
                    conn.rollback();
                    throw new IllegalStateException("EMAIL_EXISTS");
                }

                // 5) Tạo Users
                Users u = new Users(0, req.username, hashed, "ACTIVE", expiryDate, req.roleId);
                u.setEmail(req.email); // cần có setter email trong Users

                // 6) Lưu users (+ email) qua DAO
                newId = userDAO.createUserWithEmail(conn, u);

                // 7) Lưu user_profile nếu có bảng
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO user_profile (userID, fullName, gender, birthDate, phone, address) " +
                        "VALUES (?,?,?,?,?,?)"
                )) {
                    ps.setInt(1, newId);
                    ps.setString(2, emptyToNull(req.fullName));
                    ps.setString(3, emptyToNull(req.gender));

                    if (!isBlank(req.birthDate)) {
                        ps.setDate(4, java.sql.Date.valueOf(req.birthDate));
                    } else {
                        ps.setNull(4, Types.DATE);
                    }

                    ps.setString(5, emptyToNull(req.phone));
                    ps.setString(6, emptyToNull(req.address));
                    ps.executeUpdate();
                } catch (SQLException ignore) {
                    // nếu chưa có bảng user_profile thì bỏ qua
                }

                conn.commit();

            } catch (Exception e) {
                try { conn.rollback(); } catch (Exception ignore) {}
                throw e;
            } finally {
                try { conn.setAutoCommit(true); } catch (Exception ignore) {}
            }
        }

        // 8) Gửi mail mật khẩu tạm (ngoài transaction)
        try {
            String subject = "[Library] Tài khoản mới của bạn";
            String displayName = isBlank(req.fullName) ? req.username : req.fullName;

            String html =
                    "<p>Xin chào " + escapeHtml(displayName) + ",</p>" +
                    "<p>Tài khoản của bạn đã được tạo trên hệ thống:</p>" +
                    "<ul>" +
                    "<li><b>Tên đăng nhập:</b> " + escapeHtml(req.username) + "</li>" +
                    "<li><b>Mật khẩu tạm thời:</b> <code>" + escapeHtml(rawPassword) + "</code></li>" +
                    "</ul>" +
                    "<p>Vui lòng đăng nhập và <b>đổi mật khẩu</b> ngay trong lần đầu sử dụng.</p>" +
                    "<p>Trân trọng,<br>Thư Viện Số</p>";

            EmailUtility.sendHtmlEmail(req.email, subject, html);
            emailSent = true;
        } catch (Exception ignore) {
            emailSent = false;
        }

        // 9) Build result
        AdminCreateUserResult res = new AdminCreateUserResult();
        res.success = true;
        res.message = "Tạo tài khoản thành công"
                + (emailSent ? " và đã gửi mật khẩu qua email." : " (chưa gửi được email).");
        res.userId = newId;
        res.username = req.username;
        res.email = req.email;
        res.emailSent = emailSent;

        return res;
    }

    // ===== helpers =====

    private static boolean exists(Connection c, String sql, String v) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, v);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private static boolean isBlank(String s) {
        return s == null || s.trim().isEmpty();
    }

    private static String emptyToNull(String s) {
        return isBlank(s) ? null : s.trim();
    }

    private static String escapeHtml(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;");
    }

    private static String genPass(int len) {
        final String U = "ABCDEFGHJKLMNPQRSTUVWXYZ";
        final String L = "abcdefghijkmnopqrstuvwxyz";
        final String D = "23456789";
        final String S = "@#$%&*?!";
        final String ALL = U + L + D + S;

        SecureRandom r = new SecureRandom();
        StringBuilder sb = new StringBuilder(len);

        sb.append(U.charAt(r.nextInt(U.length())));
        sb.append(L.charAt(r.nextInt(L.length())));
        sb.append(D.charAt(r.nextInt(D.length())));
        sb.append(S.charAt(r.nextInt(S.length())));

        for (int i = 4; i < len; i++) {
            sb.append(ALL.charAt(r.nextInt(ALL.length())));
        }

        // shuffle
        for (int i = sb.length() - 1; i > 0; i--) {
            int j = r.nextInt(i + 1);
            char t = sb.charAt(i);
            sb.setCharAt(i, sb.charAt(j));
            sb.setCharAt(j, t);
        }
        return sb.toString();
    }
}
