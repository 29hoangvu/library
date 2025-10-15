package Servlet;

import jakarta.servlet.http.*;
import jakarta.servlet.ServletException;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.*;
import Data.ReminderDTO;


public class ReminderJobServlet extends HttpServlet {

    // HCM timezone (khớp môi trường VN)
    private static final ZoneId ZONE = ZoneId.of("Asia/Ho_Chi_Minh");

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        runJob(resp);
    }
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        runJob(resp);
    }

    private void runJob(HttpServletResponse resp) throws IOException {
        resp.setContentType("text/plain; charset=UTF-8");
        PrintWriter out = resp.getWriter();

        int sentDue = 0;
        int sentExpiry = 0;
        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            // 1) Nhắc trả sách còn 1 ngày
            List<ReminderDTO> dueList = fetchDueTomorrow(conn);
            for (ReminderDTO r : dueList) {
                String subject = "Nhắc trả sách: còn 1 ngày đến hạn";
                String html = buildDueEmailHtml(r.username, r.bookTitle, r.dueDate);
                try {
                    EmailUtility.sendHtmlEmail(r.email, subject, html);
                    insertLog(conn, "DUE", r.borrowId, r.userId);
                    sentDue++;
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }

            // 2) Nhắc gia hạn tài khoản trước 10 ngày
            List<ReminderDTO> expiryList = fetchExpiryIn10Days(conn);
            for (ReminderDTO r : expiryList) {
                String subject = "Nhắc gia hạn tài khoản: còn 10 ngày";
                String html = buildExpiryEmailHtml(r.username, r.expiryDate);
                try {
                    EmailUtility.sendHtmlEmail(r.email, subject, html);
                    insertLog(conn, "EXPIRY", r.userId, r.userId); // ref_id = user_id
                    sentExpiry++;
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }

            conn.commit();
        } catch (Exception e) {
            e.printStackTrace();
        }

        out.printf("Done. Sent DUE=%d, EXPIRY=%d%n", sentDue, sentExpiry);
    }

    /** Lấy danh sách mượn còn 1 ngày đến hạn */
    private List<ReminderDTO> fetchDueTomorrow(Connection conn) throws SQLException {
        List<ReminderDTO> list = new ArrayList<>();

        // Tính ngày mai theo timezone VN, sau đó so với DATE(due_date)
        LocalDate tomorrow = LocalDate.now(ZONE).plusDays(1);

        String sql =
            "SELECT br.borrow_id, br.user_id, br.due_date, b.title, u.username, u.email " +
            "FROM borrow br " +
            "JOIN bookitem bi ON bi.book_item_id = br.book_item_id " +
            "JOIN book b ON b.isbn = bi.book_isbn " +
            "JOIN users u ON u.id = br.user_id " +
            "WHERE br.status IN ('Borrowed','Overdue') " +
            "  AND DATE(br.due_date) = ? " +
            "  AND NOT EXISTS ( " +
            "      SELECT 1 FROM reminder_log rl " +
            "      WHERE rl.type='DUE' AND rl.ref_id=br.borrow_id " +
            "  )";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setDate(1, java.sql.Date.valueOf(tomorrow));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ReminderDTO r = new ReminderDTO();
                    r.borrowId   = rs.getInt("borrow_id");
                    r.userId     = rs.getInt("user_id");
                    r.dueDate    = rs.getTimestamp("due_date");
                    r.bookTitle  = rs.getString("title");
                    r.username   = rs.getString("username");
                    r.email      = rs.getString("email");
                    list.add(r);
                }
            }
        }
        return list;
    }

    /** Lấy user còn 10 ngày hết hạn tài khoản */
    private List<ReminderDTO> fetchExpiryIn10Days(Connection conn) throws SQLException {
        List<ReminderDTO> list = new ArrayList<>();

        LocalDate target = LocalDate.now(ZONE).plusDays(10);

        String sql =
            "SELECT u.id, u.username, u.email, u.expiryDate " +
            "FROM users u " +
            "WHERE u.status = 'ACTIVE' " +
            "  AND u.expiryDate IS NOT NULL " +
            "  AND DATE(u.expiryDate) = ? " +
            "  AND NOT EXISTS ( " +
            "      SELECT 1 FROM reminder_log rl " +
            "      WHERE rl.type='EXPIRY' AND rl.ref_id=u.id " +
            "  )";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setDate(1, java.sql.Date.valueOf(target));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ReminderDTO r = new ReminderDTO();
                    r.userId     = rs.getInt("id");
                    r.username   = rs.getString("username");
                    r.email      = rs.getString("email");
                    r.expiryDate = rs.getTimestamp("expiryDate");
                    list.add(r);
                }
            }
        }
        return list;
    }

    private void insertLog(Connection conn, String type, Integer refId, int userId) throws SQLException {
        String ins = "INSERT INTO reminder_log (type, ref_id, user_id) VALUES (?, ?, ?)";
        try (PreparedStatement ps = conn.prepareStatement(ins)) {
            ps.setString(1, type);
            ps.setInt(2, refId);
            ps.setInt(3, userId);
            ps.executeUpdate();
        }
    }

    // =========== Email templates ===========
    private String buildDueEmailHtml(String username, String bookTitle, java.util.Date dueDate) {
        String dueStr = (dueDate == null) ? "N/A" : new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm").format(dueDate);
        return """
            <div style="font-family:Arial,Helvetica,sans-serif;font-size:14px;color:#111;line-height:1.6">
              <h2 style="color:#4f46e5;margin:0 0 12px">Nhắc trả sách – còn 1 ngày</h2>
              <p>Chào <b>%s</b>,</p>
              <p>Cuốn sách bạn đang mượn sắp đến hạn trả:</p>
              <ul>
                <li><b>Tựa sách:</b> %s</li>
                <li><b>Hạn trả:</b> %s</li>
              </ul>
              <p>Vui lòng mang sách đến quầy để trả đúng hạn nhằm tránh phát sinh phí trễ hẹn.</p>
              <p>Trân trọng,<br/>Thư Viện Số</p>
            </div>
        """.formatted(escape(username), escape(bookTitle), dueStr);
    }

    private String buildExpiryEmailHtml(String username, java.util.Date expiryDate) {
        String expStr = (expiryDate == null) ? "N/A" : new java.text.SimpleDateFormat("dd/MM/yyyy").format(expiryDate);
        return """
            <div style="font-family:Arial,Helvetica,sans-serif;font-size:14px;color:#111;line-height:1.6">
              <h2 style="color:#16a34a;margin:0 0 12px">Nhắc gia hạn tài khoản – còn 10 ngày</h2>
              <p>Chào <b>%s</b>,</p>
              <p>Tài khoản thư viện của bạn sẽ hết hạn vào ngày <b>%s</b>.</p>
              <p>Vui lòng gia hạn sớm để tiếp tục sử dụng đầy đủ dịch vụ (mượn/trả, đề xuất sách, v.v.).</p>
              <p>Trân trọng,<br/>Thư Viện Số</p>
            </div>
        """.formatted(escape(username), expStr);
    }

    private String escape(String s) {
        if (s == null) return "";
        return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;");
    }
}
