package Servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

public class ReturnBookServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        int borrowId = Integer.parseInt(request.getParameter("id"));
        double finePerIncident = 5000; // Phí phạt nếu trễ hạn

        try (Connection conn = DBConnection.getConnection()) {
            // 1. Lấy due_date và book_item_id
            String selectSql = "SELECT due_date, book_item_id FROM borrow WHERE borrow_id = ?";
            PreparedStatement selectStmt = conn.prepareStatement(selectSql);
            selectStmt.setInt(1, borrowId);
            ResultSet rs = selectStmt.executeQuery();

            if (rs.next()) {
                LocalDate dueDate = rs.getDate("due_date").toLocalDate();
                int bookItemId = rs.getInt("book_item_id");
                LocalDate returnDate = LocalDate.now();

                double fineAmount = 0;
                if (returnDate.isAfter(dueDate)) {
                    fineAmount = finePerIncident;
                }

                // 2. Lấy ISBN từ bảng bookitem
                String getBookSql = "SELECT book_isbn FROM bookitem WHERE book_item_id = ?";
                PreparedStatement getBookStmt = conn.prepareStatement(getBookSql);
                getBookStmt.setInt(1, bookItemId);
                ResultSet bookRs = getBookStmt.executeQuery();

                if (bookRs.next()) {
                    String bookIsbn = bookRs.getString("book_isbn");

                    // 3. Cập nhật borrow
                    String updateBorrowSql = "UPDATE borrow SET return_date = NOW(), status = 'Returned', fine_amount = ? WHERE borrow_id = ?";
                    PreparedStatement updateBorrowStmt = conn.prepareStatement(updateBorrowSql);
                    updateBorrowStmt.setDouble(1, fineAmount);
                    updateBorrowStmt.setInt(2, borrowId);
                    int updated = updateBorrowStmt.executeUpdate();

                    if (updated > 0) {
                        // 4. Cập nhật số lượng sách
                        String updateBookSql = "UPDATE book SET quantity = quantity + 1 WHERE isbn = ?";
                        PreparedStatement updateBookStmt = conn.prepareStatement(updateBookSql);
                        updateBookStmt.setString(1, bookIsbn);
                        updateBookStmt.executeUpdate();

                        // ✅ Gửi phản hồi thành công
                        sendResponse(response, "Xác nhận trả sách thành công" + (fineAmount > 0 ? (", phạt " + fineAmount + " VNĐ") : ""));
                    } else {
                        sendResponse(response, "Lỗi khi cập nhật trạng thái mượn sách.");
                    }
                } else {
                    sendResponse(response, "Không tìm thấy sách trong hệ thống.");
                }
            } else {
                sendResponse(response, "Không tìm thấy thông tin mượn sách.");
            }
        } catch (SQLException e) {
            e.printStackTrace();
            sendResponse(response, "Lỗi SQL: " + e.getMessage());
        }
    }

    // ✅ Hàm tiện ích gửi phản hồi và redirect
    private void sendResponse(HttpServletResponse response, String message) throws IOException {
        response.setContentType("application/json; charset=UTF-8");
        response.getWriter().write("{\"message\":\"" + message.replace("\"", "\\\"") + "\", \"redirect\":\"adminBorrowedBooks.jsp\"}");
}   

}
