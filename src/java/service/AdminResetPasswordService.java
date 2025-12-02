package service;

import Servlet.DBConnection;
import Servlet.PasswordHashing;
import Servlet.EmailUtility;

import java.security.SecureRandom;
import java.sql.*;

public class AdminResetPasswordService {

    /** Reset mật khẩu user + gửi mail */
    public ResetResult resetUserPassword(int userId) throws Exception {

        String username = null;
        String email = null;

        // 1) Lấy info user trước
        try(Connection conn = DBConnection.getConnection()){
            try(PreparedStatement ps = conn.prepareStatement(
                "SELECT username, email FROM users WHERE id=?"
            )){
                ps.setInt(1, userId);
                try(ResultSet rs = ps.executeQuery()){
                    if(!rs.next()){
                        return new ResetResult(false, "User không tồn tại", null,false);
                    }
                    username = rs.getString("username");
                    email    = rs.getString("email");
                }
            }
        }

        // 2) Generate password
        String rawPassword = genPass(12);
        String hashed = PasswordHashing.hashPassword(rawPassword);

        // 3) Update DB
        try(Connection conn = DBConnection.getConnection()){
            try(PreparedStatement ps = conn.prepareStatement(
                "UPDATE users SET password=? WHERE id=?"
            )){
                ps.setString(1, hashed);
                ps.setInt(2, userId);
                ps.executeUpdate();
            }
        }

        // 4) Gửi email
        boolean emailSent = false;
        try{
            String subject = "[Library] Mật khẩu mới của bạn";

            String html =
                    "<p>Xin chào <b>" + escape(username) + "</b>,</p>" +
                    "<p>Mật khẩu của bạn đã được reset bởi quản trị viên.</p>" +
                    "<p><b>Mật khẩu mới:</b> <code>" + escape(rawPassword) + "</code></p>" +
                    "<p>Vui lòng đổi mật khẩu ngay khi đăng nhập.</p>" +
                    "<p>Trân trọng,<br>Thư Viện Số</p>";

            EmailUtility.sendHtmlEmail(email, subject, html);
            emailSent = true;

        }catch(Exception ex){ emailSent = false; }

        return new ResetResult(true,
                emailSent ?
                        "Reset mật khẩu thành công — mật khẩu đã gửi về email" :
                        "Reset thành công nhưng chưa gửi được email.",
                rawPassword,
                emailSent
        );
    }

    // ========= Helpers =========

    private static String escape(String s){
        if(s == null) return "";
        return s.replace("&","&amp;")
                .replace("<","&lt;")
                .replace(">","&gt;");
    }

    /** Generate strong random password */
    private static String genPass(int len){
        final String U="ABCDEFGHJKLMNPQRSTUVWXYZ";
        final String L="abcdefghijkmnopqrstuvwxyz";
        final String D="23456789";
        final String S="@#$%&*?!";
        final String ALL = U+L+D+S;

        SecureRandom r=new SecureRandom();
        StringBuilder sb=new StringBuilder(len);

        sb.append(U.charAt(r.nextInt(U.length())));
        sb.append(L.charAt(r.nextInt(L.length())));
        sb.append(D.charAt(r.nextInt(D.length())));
        sb.append(S.charAt(r.nextInt(S.length())));

        for(int i=4;i<len;i++){
            sb.append(ALL.charAt(r.nextInt(ALL.length())));
        }

        // Shuffle
        for(int i = sb.length()-1;i>0;i--){
            int j = r.nextInt(i+1);
            char t= sb.charAt(i);
            sb.setCharAt(i, sb.charAt(j));
            sb.setCharAt(j, t);
        }
        return sb.toString();
    }

    // Resultado DTO
    public static class ResetResult {
        public boolean ok;
        public String message;
        public String plaintextPassword;
        public boolean emailSent;
        public ResetResult(boolean ok, String msg, String pass, boolean emailSent){
            this.ok=ok; this.message=msg;
            this.plaintextPassword=pass;
            this.emailSent=emailSent;
        }
    }
}
