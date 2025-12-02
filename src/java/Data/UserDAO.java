package Data;

import java.sql.*;
import Servlet.DBConnection;

public class UserDAO {

    // Hàm cũ vẫn giữ nguyên nếu nơi khác còn dùng
    public boolean createUser(Users user) {
        String sql = "INSERT INTO Users (username, password, status, expiryDate, roleID) VALUES (?, ?, ?, ?, ?)";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, user.getUsername());
            pstmt.setString(2, user.getPassword());
            pstmt.setString(3, user.getStatus());
            if (user.getExpiryDate() == null) pstmt.setNull(4, java.sql.Types.DATE);
            else pstmt.setDate(4, new java.sql.Date(user.getExpiryDate().getTime()));
            pstmt.setInt(5, user.getRoleID());
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); return false; }
    }

    // HÀM MỚI: dùng trong API – có email và trả về id
    public int createUserWithEmail(Connection conn, Users user) throws SQLException {
        String sql = "INSERT INTO users (username, password, status, expiryDate, roleID, email) VALUES (?,?,?,?,?,?)";
        try (PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, user.getUsername());
            ps.setString(2, user.getPassword());
            ps.setString(3, user.getStatus());
            if (user.getExpiryDate() == null) ps.setNull(4, Types.DATE);
            else ps.setDate(4, new java.sql.Date(user.getExpiryDate().getTime()));
            ps.setInt(5, user.getRoleID());
            ps.setString(6, user.getEmail());
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) return rs.getInt(1);
                throw new SQLException("Không lấy được generated key.");
            }
        }
    }
}
