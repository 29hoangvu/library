package service.profile;

import Servlet.DBConnection;
import dto.profile.ProfileDto;
import dto.profile.ProfileUpdateRequest;

import java.sql.*;

public class ProfileService {

    /**
     * Lấy thông tin profile (users + user_profile) cho 1 user
     */
    public ProfileDto getProfileByUserId(int uid) throws SQLException {
        String sql = """
            SELECT 
                u.id AS uid, u.username, u.email, u.status, u.expiryDate,
                p.fullName, p.gender, p.birthDate, p.phone, p.address
            FROM users u
            LEFT JOIN user_profile p ON u.id = p.userID
            WHERE u.id = ?
        """;

        try (Connection cn = DBConnection.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setInt(1, uid);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null; // không tìm thấy user
                }

                ProfileDto dto = new ProfileDto();
                dto.uid        = rs.getInt("uid");
                dto.username   = rs.getString("username");
                dto.email      = rs.getString("email");
                dto.status     = rs.getString("status");
                dto.expiryDate = rs.getDate("expiryDate");

                dto.fullName   = rs.getString("fullName");
                dto.gender     = rs.getString("gender");
                dto.birthDate  = rs.getDate("birthDate");
                dto.phone      = rs.getString("phone");
                dto.address    = rs.getString("address");

                return dto;
            }
        }
    }

    /**
     * Tạo mới hoặc cập nhật bảng user_profile cho user
     */
    public void upsertProfile(int uid, ProfileUpdateRequest req) throws SQLException {
        String checkSql  = "SELECT 1 FROM user_profile WHERE userID = ?";
        String updateSql = """
            UPDATE user_profile
            SET fullName = ?, gender = ?, birthDate = ?, phone = ?, address = ?
            WHERE userID = ?
        """;
        String insertSql = """
            INSERT INTO user_profile (userID, fullName, gender, birthDate, phone, address)
            VALUES (?,?,?,?,?,?)
        """;

        try (Connection cn = DBConnection.getConnection();
             PreparedStatement psCk = cn.prepareStatement(checkSql)) {

            psCk.setInt(1, uid);
            boolean exists;
            try (ResultSet rs = psCk.executeQuery()) {
                exists = rs.next();
            }

            if (exists) {
                try (PreparedStatement ps = cn.prepareStatement(updateSql)) {
                    ps.setString(1, req.fullName);
                    ps.setString(2, req.gender);
                    if (req.birthDate != null) {
                        ps.setDate(3, req.birthDate);
                    } else {
                        ps.setNull(3, Types.DATE);
                    }
                    ps.setString(4, req.phone);
                    ps.setString(5, req.address);
                    ps.setInt(6, uid);
                    ps.executeUpdate();
                }
            } else {
                try (PreparedStatement ps = cn.prepareStatement(insertSql)) {
                    ps.setInt(1, uid);
                    ps.setString(2, req.fullName);
                    ps.setString(3, req.gender);
                    if (req.birthDate != null) {
                        ps.setDate(4, req.birthDate);
                    } else {
                        ps.setNull(4, Types.DATE);
                    }
                    ps.setString(5, req.phone);
                    ps.setString(6, req.address);
                    ps.executeUpdate();
                }
            }
        }
    }
}
