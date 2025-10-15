package Data;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import Servlet.DBConnection;

public class UserDAO {
    public boolean createUser(Users user) {
        String sql = "INSERT INTO Users (username, password, status, expiryDate, roleID) VALUES (?, ?, ?, ?, ?)";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, user.getUsername());
            pstmt.setString(2, user.getPassword());
            pstmt.setString(3, user.getStatus());

            if (user.getExpiryDate() == null) {
                pstmt.setNull(4, java.sql.Types.DATE);
            } else {
                pstmt.setDate(4, new java.sql.Date(user.getExpiryDate().getTime()));
            }

            pstmt.setInt(5, user.getRoleID());

            return pstmt.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
}
