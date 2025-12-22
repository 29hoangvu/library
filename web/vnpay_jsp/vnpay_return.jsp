<%@ page import="java.sql.*, java.time.*, java.time.format.DateTimeFormatter" %>
<%@ page import="java.text.NumberFormat, java.util.Locale" %>
<%@ page import="Servlet.DBConnection, Servlet.EmailUtility" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    request.setCharacterEncoding("UTF-8");

    // Lấy tham số từ VNPAY trả về
    String vnp_ResponseCode = request.getParameter("vnp_ResponseCode");

    // Kiểm tra thanh toán thành công (ResponseCode = "00")
    if ("00".equals(vnp_ResponseCode)) {
        // Lấy thông tin đăng ký từ session
        String username = (String) session.getAttribute("REG_username");
        String hashedPwd = (String) session.getAttribute("REG_hpwd");
        String email = (String) session.getAttribute("REG_email");
        Integer years = (Integer) session.getAttribute("REG_years");

        if (username == null || hashedPwd == null || email == null || years == null) {
            out.println("<script>alert('Không tìm thấy thông tin đăng ký. Vui lòng thử lại.'); window.location='" + request.getContextPath() + "/user/register.jsp';</script>");
            return;
        }

        try (Connection conn = DBConnection.getConnection()) {
            // Kiểm tra trùng username
            try (PreparedStatement ck = conn.prepareStatement("SELECT id FROM users WHERE username=?")) {
                ck.setString(1, username);
                try (ResultSet rs = ck.executeQuery()) {
                    if (rs.next()) {
                        out.println("<script>alert('Tên đăng nhập đã tồn tại, vui lòng chọn tên khác.'); window.location='" + request.getContextPath() + "/user/register.jsp';</script>");
                        return;
                    }
                }
            }

            // Tạo tài khoản với trạng thái ACTIVE
            LocalDate today = LocalDate.now();
            LocalDate expiry = today.plusYears(years);
            try (PreparedStatement st = conn.prepareStatement(
                    "INSERT INTO users (username, password, email, status, expiryDate, roleID) VALUES (?, ?, ?, 'ACTIVE', ?, 3)")) {
                st.setString(1, username);
                st.setString(2, hashedPwd);
                st.setString(3, email);
                st.setDate(4, java.sql.Date.valueOf(expiry));
                st.executeUpdate();
            }

            /* ===== GỬI EMAIL XÁC NHẬN ===== */
            DateTimeFormatter dfDate = DateTimeFormatter.ofPattern("dd/MM/yyyy");
            DateTimeFormatter dfDateTime = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");
            ZoneId VN = ZoneId.of("Asia/Ho_Chi_Minh");
            String nowStr = LocalDateTime.now(VN).format(dfDateTime);
            String startStr = today.format(dfDate);
            String expiryStr = expiry.format(dfDate);

            NumberFormat vnd = NumberFormat.getCurrencyInstance(new Locale("vi", "VN"));
            long amount = years.longValue() * 100_000L;
            String amountStr = vnd.format(amount); // ví dụ: 100.000 ₫

        // Có thể thêm mã GD lấy từ VNPAY nếu bạn lưu, ví dụ:
            String txnRef = request.getParameter("vnp_TxnRef"); // hoặc lấy từ session nếu đã lưu
            if (txnRef == null) {
                txnRef = "(không có)";
            }

        // Chủ đề & nội dung (HTML)
            String subject = "Xác nhận đăng ký thành công - Thư Viện Số";

            String html
                    = "<div style='font-family:Arial,Helvetica,sans-serif;line-height:1.6'>"
                    + "  <h2 style='color:#2563eb;margin:0 0 12px'>Đăng ký thành công!</h2>"
                    + "  <p>Xin chào <b>" + username + "</b>,</p>"
                    + "  <p>Bạn đã đăng ký tài khoản thành viên <b>Thư Viện Số</b> thành công.</p>"
                    + "  <ul>"
                    + "    <li><b>Thời điểm đăng ký:</b> " + nowStr + " (GMT+7)</li>"
                    + "    <li><b>Thời gian hiệu lực:</b> từ " + startStr + " đến hết ngày " + expiryStr + "</li>"
                    + "    <li><b>Gói:</b> " + years + " năm</li>"
                    + "    <li><b>Lệ phí:</b> " + amountStr + "</li>"
                    + "    <li><b>Mã giao dịch:</b> " + txnRef + "</li>"
                    + "    <li><b>Email đăng ký:</b> " + email + "</li>"
                    + "  </ul>"
                    + "  <p>Vui lòng <b>đăng nhập</b> vào hệ thống để <b>cập nhật thông tin cá nhân</b> (họ tên, ngày sinh, số điện thoại, địa chỉ...).</p>"
                    + "  <p style='margin-top:16px'>Trân trọng,<br/>Đội ngũ <b>Thư Viện Số</b></p>"
                    + "</div>";

        // Gửi HTML (nếu đã thêm sendHtmlEmail)
            EmailUtility.sendHtmlEmail(email, subject, html);

            // Xóa thông tin đăng ký từ session
            session.removeAttribute("REG_username");
            session.removeAttribute("REG_hpwd");
            session.removeAttribute("REG_email");
            session.removeAttribute("REG_years");

            out.println("<script>alert('Đăng ký và thanh toán thành công! Vui lòng đăng nhập.'); window.location='" + request.getContextPath() + "/user/login.jsp';</script>");
        } catch (Exception e) {
            e.printStackTrace();
            out.println("<script>alert('Có lỗi khi lưu dữ liệu: " + e.getMessage().replace("'", "\\'") + "'); window.location='" + request.getContextPath() + "/user/register.jsp';</script>");
        }
    } else {
        // Thanh toán không thành công
        out.println("<script>alert('Thanh toán không thành công. Vui lòng thử lại.'); window.location='" + request.getContextPath() + "/user/register.jsp';</script>");
    }
%>