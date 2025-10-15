package Servlet;
//duyet don dktk
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.Calendar;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

public class ApproveUserServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String userID = request.getParameter("userID");
        String action = request.getParameter("action");

        if (userID == null || action == null) {
            response.sendRedirect("createUser.jsp?error=InvalidRequest");
            return;
        }

        Connection conn = null;
        PreparedStatement stmt = null;

        try {
            conn = DBConnection.getConnection();
            if ("approve".equals(action)) {
                // Tính ngày hết hạn (1 năm kể từ ngày duyệt)
                Calendar cal = Calendar.getInstance();
                cal.add(Calendar.YEAR, 1);
                Timestamp expirationDate = new Timestamp(cal.getTimeInMillis());

                // Cập nhật trạng thái và ngày hết hạn
                String sql = "UPDATE users SET status = 'ACTIVE', expiryDate = ? WHERE id = ?";
                stmt = conn.prepareStatement(sql);
                stmt.setTimestamp(1, expirationDate);
                stmt.setInt(2, Integer.parseInt(userID));
            } else if ("reject".equals(action)) {
                // Xóa tài khoản nếu bị từ chối
                String sql = "DELETE FROM users WHERE id = ?";
                stmt = conn.prepareStatement(sql);
                stmt.setInt(1, Integer.parseInt(userID));
            }

            int rowsAffected = stmt.executeUpdate();
            if (rowsAffected > 0) {
                response.sendRedirect("createUser.jsp?success=UserUpdated");
            } else {
                response.sendRedirect("createUser.jsp?error=UpdateFailed");
            }

        } catch (SQLException e) {
            e.printStackTrace();
            response.sendRedirect("createUser.jsp?error=SQLException");
        } finally {
            try {
                if (stmt != null) stmt.close();
                if (conn != null) conn.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }
}
