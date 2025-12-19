<%@page import="java.net.URLEncoder"%>
<%@ page import="java.sql.*, java.time.*, java.time.format.DateTimeFormatter" %>
<%@ page import="Servlet.DBConnection, Servlet.PasswordHashing, Servlet.EmailUtility" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<%
    request.setCharacterEncoding("UTF-8");

    String username = request.getParameter("username");
    String rawPwd = request.getParameter("password");
    String email = request.getParameter("email");
    String paymentMethod = request.getParameter("paymentMethod");
    String yearsStr = request.getParameter("years");

    if (username == null || rawPwd == null || email == null || yearsStr == null
            || username.trim().isEmpty() || rawPwd.trim().isEmpty() || email.trim().isEmpty()) {
        out.println("<script>alert('Vui lòng điền đầy đủ thông tin.'); history.back();</script>");
    } else {
        int years = 1;
        try {
            years = Integer.parseInt(yearsStr);
        } catch (Exception ignore) {
        }
        if (years <= 0) {
            years = 1;
        }

        String hashedPwd = PasswordHashing.hashPassword(rawPwd);

        if ("offline".equalsIgnoreCase(paymentMethod)) {
            try (Connection conn = DBConnection.getConnection()) {
                // Check username tồn tại
                try (PreparedStatement ck = conn.prepareStatement("SELECT id FROM users WHERE username=?")) {
                    ck.setString(1, username);
                    try (ResultSet rs = ck.executeQuery()) {
                        if (rs.next()) {
                            out.println("<script>alert('Tên đăng nhập đã tồn tại, vui lòng chọn tên khác.'); history.back();</script>");
                            return;
                        }
                    }
                }

                // Tạo tài khoản PENDING
                LocalDate today = LocalDate.now();
                LocalDate expiry = today.plusYears(years);
                LocalDate deadline = today.plusDays(7);

                try (PreparedStatement st = conn.prepareStatement(
                        "INSERT INTO users (username, password, email, status, expiryDate, roleID) VALUES (?, ?, ?, 'PENDING', ?, 3)")) {
                    st.setString(1, username);
                    st.setString(2, hashedPwd);
                    st.setString(3, email);
                    st.setDate(4, java.sql.Date.valueOf(expiry));
                    st.executeUpdate();
                }

                // ===== GỬI EMAIL NHẮC NỘP LỆ PHÍ (OFFLINE) =====
                try {
                    DateTimeFormatter dfDate = DateTimeFormatter.ofPattern("dd/MM/yyyy");
                    DateTimeFormatter dfDateTime = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");
                    ZoneId VN = ZoneId.of("Asia/Ho_Chi_Minh");

                    String nowStr = LocalDateTime.now(VN).format(dfDateTime);
                    String startStr = today.format(dfDate);
                    String expiryStr = expiry.format(dfDate);
                    String deadlineStr = deadline.format(dfDate);

                    long amount = 100_000L * years;
                    String amountStr = String.format("%,d đ", amount).replace(',', '.');

                    String subject = "Hướng dẫn nộp lệ phí (offline) để kích hoạt tài khoản - Thư Viện Số";

                    String html
                            = "<div style='font-family:Arial,Helvetica,sans-serif;line-height:1.6'>"
                            + "  <h2 style='color:#2563eb;margin:0 0 12px'>Đăng ký thành công (chờ nộp lệ phí)</h2>"
                            + "  <p>Xin chào <b>" + username + "</b>,</p>"
                            + "  <p>Bạn đã đăng ký tài khoản thành viên <b>Thư Viện Số</b> với hình thức thanh toán <b>trực tiếp tại thư viện</b>.</p>"
                            + "  <ul>"
                            + "    <li><b>Thời điểm đăng ký:</b> " + nowStr + " (GMT+7)</li>"
                            + "    <li><b>Thời gian hiệu lực dự kiến:</b> từ " + startStr + " đến hết ngày " + expiryStr + "</li>"
                            + "    <li><b>Gói:</b> " + years + " năm</li>"
                            + "    <li><b>Lệ phí cần nộp:</b> " + amountStr + "</li>"
                            + "    <li><b>Tài khoản:</b> " + username + " (" + email + ")</li>"
                            + "  </ul>"
                            + "  <p><b>Vui lòng đến thư viện để nộp lệ phí trước ngày " + deadlineStr + "</b> để <b>kích hoạt</b> tài khoản. Sau thời hạn này, đăng ký có thể bị hủy.</p>"
                            + "  <p>Sau khi nộp lệ phí, hãy <b>đăng nhập</b> vào hệ thống để <b>cập nhật thông tin cá nhân</b> (họ tên, ngày sinh, số điện thoại, địa chỉ...).</p>"
                            + "  <p style='margin-top:16px'>Trân trọng,<br/>Đội ngũ <b>Thư Viện Số</b></p>"
                            + "</div>";

                    EmailUtility.sendHtmlEmail(email, subject, html);
                } catch (Exception mailEx) {
                    mailEx.printStackTrace();
                }

                // Lấy thông tin để hiển thị popup
                DateTimeFormatter dfDate = DateTimeFormatter.ofPattern("dd/MM/yyyy");
                String deadlineStr = deadline.format(dfDate);
                String expiryStr = expiry.format(dfDate);
                long amount = 100_000L * years;
                String amountStr = String.format("%,d đ", amount).replace(',', '.');
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Đăng ký thành công</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        
        .popup-overlay {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.5);
            backdrop-filter: blur(5px);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 9999;
            animation: fadeIn 0.3s ease;
        }
        
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
        
        @keyframes slideDown {
            from {
                transform: translateY(-50px);
                opacity: 0;
            }
            to {
                transform: translateY(0);
                opacity: 1;
            }
        }
        
        .popup-container {
            background: white;
            border-radius: 16px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            max-width: 500px;
            width: 90%;
            animation: slideDown 0.4s ease;
            overflow: hidden;
        }
        
        .popup-header {
            padding: 30px 30px 20px;
            text-align: center;
        }
        
        .warning-icon {
            width: 80px;
            height: 80px;
            background: linear-gradient(135deg, #f59e0b, #d97706);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 20px;
            animation: scaleIn 0.5s ease 0.2s both;
        }
        
        @keyframes scaleIn {
            from { transform: scale(0); }
            to { transform: scale(1); }
        }
        
        .warning-icon svg {
            width: 45px;
            height: 45px;
            stroke: white;
            stroke-width: 3;
            fill: none;
            stroke-linecap: round;
            stroke-linejoin: round;
        }
        
        .popup-title {
            font-size: 28px;
            font-weight: 700;
            color: #1f2937;
            margin-bottom: 10px;
        }
        
        .popup-message {
            font-size: 16px;
            color: #6b7280;
            line-height: 1.6;
        }
        
        .popup-body {
            padding: 0 30px 30px;
        }
        
        .info-grid {
            background: #f9fafb;
            border-radius: 12px;
            padding: 20px;
            margin-top: 20px;
        }
        
        .info-item {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid #e5e7eb;
        }
        
        .info-item:last-child {
            border-bottom: none;
        }
        
        .info-label {
            font-weight: 600;
            color: #4b5563;
        }
        
        .info-value {
            color: #1f2937;
            text-align: right;
            max-width: 60%;
            word-wrap: break-word;
        }
        
        .deadline-highlight {
            color: #dc2626;
            font-weight: 700;
        }
        
        .alert-box {
            background: #fef3c7;
            border-left: 4px solid #f59e0b;
            padding: 15px;
            border-radius: 8px;
            margin-top: 20px;
        }
        
        .alert-box p {
            color: #92400e;
            font-weight: 600;
            margin: 0;
            font-size: 14px;
        }
        
        .popup-footer {
            padding: 0 30px 30px;
        }
        
        .btn {
            width: 100%;
            padding: 14px;
            border: none;
            border-radius: 10px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
        }
        
        .btn-primary {
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
        }
        
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 25px rgba(102, 126, 234, 0.4);
        }
        
        .btn-secondary {
            background: #f3f4f6;
            color: #4b5563;
            margin-top: 10px;
        }
        
        .btn-secondary:hover {
            background: #e5e7eb;
        }
    </style>
</head>
<body>
    <div class="popup-overlay">
        <div class="popup-container">
            <div class="popup-header">
                <div class="warning-icon">
                    <svg viewBox="0 0 24 24">
                        <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
                        <line x1="12" y1="9" x2="12" y2="13"></line>
                        <line x1="12" y1="17" x2="12.01" y2="17"></line>
                    </svg>
                </div>
                <h1 class="popup-title">Đăng ký thành công!</h1>
                <p class="popup-message">Tài khoản của bạn đã được tạo với trạng thái chờ kích hoạt.</p>
            </div>
            <div class="popup-body">
                <div class="alert-box">
                    <p>⚠️ Vui lòng đến thư viện để nộp lệ phí trong vòng 7 ngày để kích hoạt tài khoản!</p>
                </div>
                <div class="info-grid">
                    <div class="info-item">
                        <span class="info-label">Tên đăng nhập:</span>
                        <span class="info-value"><%= username %></span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Email:</span>
                        <span class="info-value"><%= email %></span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Gói dịch vụ:</span>
                        <span class="info-value"><%= years %> năm</span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Lệ phí cần nộp:</span>
                        <span class="info-value"><%= amountStr %></span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Hiệu lực đến:</span>
                        <span class="info-value"><%= expiryStr %></span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Hạn nộp phí:</span>
                        <span class="info-value deadline-highlight"><%= deadlineStr %></span>
                    </div>
                </div>
            </div>
            <div class="popup-footer">
                <button class="btn btn-primary" onclick="window.location='<%= request.getContextPath() %>/user/login.jsp'">Đăng nhập ngay</button>
                <button class="btn btn-secondary" onclick="window.location='<%= request.getContextPath() %>/'">Về trang chủ</button>
            </div>
        </div>
    </div>
</body>
</html>
<%
                return;
            } catch (Exception e) {
                e.printStackTrace();
                out.println("<script>alert('Có lỗi xảy ra: " + e.getMessage().replace("'", "\\'") + "'); history.back();</script>");
                return;
            }
        } else {
            long amount = 100_000L * years;
            session.setAttribute("REG_username", username);
            session.setAttribute("REG_hpwd", hashedPwd);
            session.setAttribute("REG_email", email);
            session.setAttribute("REG_years", years);

            String target = request.getContextPath() + "/ajaxServlet"
                    + "?amount=" + amount
                    + "&order_id=" + URLEncoder.encode("LIB" + System.currentTimeMillis(), "UTF-8")
                    + "&order_info=" + URLEncoder.encode("Thanh toan dang ky thu vien - " + username, "UTF-8")
                    + "&language=vn";

            response.sendRedirect(target);
        }
    }
%>