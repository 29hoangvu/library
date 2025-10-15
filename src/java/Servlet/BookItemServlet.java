package Servlet;
//Vi tri ke
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.*;
import java.sql.*;

public class BookItemServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String bookId = request.getParameter("bookId");  // ISBN hoặc tên sách
        String rackId = request.getParameter("rackId");  // ID kệ đã chọn

        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null, bookItemRs = null, rackRs = null;

        try {
            conn = DBConnection.getConnection();

            // 1️⃣ Kiểm tra xem sách có tồn tại trong bảng book không
            String checkBookQuery = "SELECT isbn FROM book WHERE isbn = ? OR title = ?";
            stmt = conn.prepareStatement(checkBookQuery);
            stmt.setString(1, bookId);
            stmt.setString(2, bookId);
            rs = stmt.executeQuery();

            if (!rs.next()) {
                sendResponse(response, "Lỗi: Không tìm thấy sách.");
                return;
            }
            String isbn = rs.getString("isbn");

            // 2️⃣ Kiểm tra xem kệ đã chứa sách nào chưa
            String checkRackQuery = "SELECT book_isbn FROM bookitem WHERE rack_id = ?";
            stmt = conn.prepareStatement(checkRackQuery);
            stmt.setInt(1, Integer.parseInt(rackId));
            rackRs = stmt.executeQuery();

            // 3️⃣ Kiểm tra xem sách đã có trong bookitem chưa
            String checkBookItemQuery = "SELECT book_isbn FROM bookitem WHERE book_isbn = ?";
            stmt = conn.prepareStatement(checkBookItemQuery);
            stmt.setString(1, isbn);
            bookItemRs = stmt.executeQuery();

            if (bookItemRs.next()) {
                // Nếu sách đã có trong bookitem, cập nhật vị trí kệ
                String updateQuery = "UPDATE bookitem SET rack_id = ? WHERE book_isbn = ?";
                stmt = conn.prepareStatement(updateQuery);
                stmt.setInt(1, Integer.parseInt(rackId));
                stmt.setString(2, isbn);
                stmt.executeUpdate();

                sendResponse(response, "Cập nhật vị trí sách thành công!");
            } else {
                // Nếu sách chưa có trong bookitem, thêm mới vào
                String insertQuery = "INSERT INTO bookitem (book_isbn, rack_id) VALUES (?, ?)";
                stmt = conn.prepareStatement(insertQuery);
                stmt.setString(1, isbn);
                stmt.setInt(2, Integer.parseInt(rackId));
                stmt.executeUpdate();

                sendResponse(response, "Thêm sách vào kệ thành công!");
            }
        } catch (SQLException e) {
            e.printStackTrace();
            sendResponse(response, "Lỗi: Cơ sở dữ liệu.");
        } finally {
            try {
                if (rs != null) rs.close();
                if (bookItemRs != null) bookItemRs.close();
                if (rackRs != null) rackRs.close();
                if (stmt != null) stmt.close();
                if (conn != null) conn.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }

    private void sendResponse(HttpServletResponse response, String message) throws IOException {
        response.setContentType("text/html; charset=UTF-8");
        response.getWriter().println("<script>alert('" + message + "'); window.location.href='addBookItem.jsp';</script>");
    }
}
