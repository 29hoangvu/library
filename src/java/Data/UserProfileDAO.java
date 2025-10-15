package Data;

import Data.UserProfile;
import Servlet.DBConnection;

import java.sql.*;

public class UserProfileDAO {

    public static UserProfile getProfileByUserId(int userID) {
        UserProfile profile = null;

        try {
            Connection conn = DBConnection.getConnection();
            String sql = "SELECT * FROM user_profile WHERE userID = ?";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setInt(1, userID);
            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                profile = new UserProfile(
                    rs.getInt("userID"),
                    rs.getString("fullName"),
                    rs.getString("gender"),
                    rs.getDate("birthDate"),
                    rs.getString("phone"),
                    rs.getString("address")
                );
            }

            rs.close();
            ps.close();
            conn.close();
        } catch (Exception e) {
            e.printStackTrace();
        }

        return profile;
    }
}
