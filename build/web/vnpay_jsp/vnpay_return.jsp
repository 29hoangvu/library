<%@ page import="java.sql.*, java.time.*, java.time.format.DateTimeFormatter" %>
<%@ page import="java.text.NumberFormat, java.util.Locale" %>
<%@ page import="Servlet.DBConnection, Servlet.EmailUtility" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Xác nhận thanh toán</title>
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
        
        .success-icon {
            width: 80px;
            height: 80px;
            background: linear-gradient(135deg, #10b981, #059669);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 20px;
            animation: scaleIn 0.5s ease 0.2s both;
        }
        
        .error-icon {
            width: 80px;
            height: 80px;
            background: linear-gradient(135deg, #ef4444, #dc2626);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 20px;
            animation: scaleIn 0.5s ease 0.2s both;
        }
        
        @keyframes scaleIn {
            from {
                transform: scale(0);
            }
            to {
                transform: scale(1);
            }
        }
        
        .success-icon svg, .error-icon svg {
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
        
        .loading {
            text-align: center;
            padding: 40px;
        }
        
        .spinner {
            border: 4px solid #f3f4f6;
            border-top: 4px solid #667eea;
            border-radius: 50%;
            width: 50px;
            height: 50px;
            animation: spin 1s linear infinite;
            margin: 0 auto 20px;
        }
        
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
<%
    request.setCharacterEncoding("UTF-8");
    String vnp_ResponseCode = request.getParameter("vnp_ResponseCode");
    
    if ("00".equals(vnp_ResponseCode)) {
        String username = (String) session.getAttribute("REG_username");
        String hashedPwd = (String) session.getAttribute("REG_hpwd");
        String email = (String) session.getAttribute("REG_email");
        Integer years = (Integer) session.getAttribute("REG_years");

        if (username == null || hashedPwd == null || email == null || years == null) {
%>
    <div class="popup-overlay">
        <div class="popup-container">
            <div class="popup-header">
                <div class="error-icon">
                    <svg viewBox="0 0 24 24">
                        <line x1="18" y1="6" x2="6" y2="18"></line>
                        <line x1="6" y1="6" x2="18" y2="18"></line>
                    </svg>
                </div>
                <h1 class="popup-title">Lỗi!</h1>
                <p class="popup-message">Không tìm thấy thông tin đăng ký. Vui lòng thử lại.</p>
            </div>
            <div class="popup-footer">
                <button class="btn btn-primary" onclick="window.location='<%= request.getContextPath() %>/user/register.jsp'">Quay lại đăng ký</button>
            </div>
        </div>
    </div>
<%
            return;
        }

        try (Connection conn = DBConnection.getConnection()) {
            try (PreparedStatement ck = conn.prepareStatement("SELECT id FROM users WHERE username=?")) {
                ck.setString(1, username);
                try (ResultSet rs = ck.executeQuery()) {
                    if (rs.next()) {
%>
    <div class="popup-overlay">
        <div class="popup-container">
            <div class="popup-header">
                <div class="error-icon">
                    <svg viewBox="0 0 24 24">
                        <line x1="18" y1="6" x2="6" y2="18"></line>
                        <line x1="6" y1="6" x2="18" y2="18"></line>
                    </svg>
                </div>
                <h1 class="popup-title">Lỗi!</h1>
                <p class="popup-message">Tên đăng nhập đã tồn tại, vui lòng chọn tên khác.</p>
            </div>
            <div class="popup-footer">
                <button class="btn btn-primary" onclick="window.location='<%= request.getContextPath() %>/user/register.jsp'">Quay lại đăng ký</button>
            </div>
        </div>
    </div>
<%
                        return;
                    }
                }
            }

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

            DateTimeFormatter dfDate = DateTimeFormatter.ofPattern("dd/MM/yyyy");
            DateTimeFormatter dfDateTime = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");
            ZoneId VN = ZoneId.of("Asia/Ho_Chi_Minh");
            String nowStr = LocalDateTime.now(VN).format(dfDateTime);
            String startStr = today.format(dfDate);
            String expiryStr = expiry.format(dfDate);

            NumberFormat vnd = NumberFormat.getCurrencyInstance(new Locale("vi", "VN"));
            long amount = years.longValue() * 100_000L;
            String amountStr = vnd.format(amount);

            String txnRef = request.getParameter("vnp_TxnRef");
            if (txnRef == null) {
                txnRef = "(không có)";
            }

            String subject = "Xác nhận đăng ký thành công - Thư Viện Số";
            String html = "<div style='font-family:Arial,Helvetica,sans-serif;line-height:1.6'>"
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

            EmailUtility.sendHtmlEmail(email, subject, html);

            session.removeAttribute("REG_username");
            session.removeAttribute("REG_hpwd");
            session.removeAttribute("REG_email");
            session.removeAttribute("REG_years");
%>
    <div class="popup-overlay">
        <div class="popup-container">
            <div class="popup-header">
                <div class="success-icon">
                    <svg viewBox="0 0 24 24">
                        <polyline points="20 6 9 17 4 12"></polyline>
                    </svg>
                </div>
                <h1 class="popup-title">Đăng ký thành công!</h1>
                <p class="popup-message">Chúc mừng! Tài khoản của bạn đã được kích hoạt.</p>
            </div>
            <div class="popup-body">
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
                        <span class="info-label">Hiệu lực đến:</span>
                        <span class="info-value"><%= expiryStr %></span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Số tiền:</span>
                        <span class="info-value"><%= amountStr %></span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Mã giao dịch:</span>
                        <span class="info-value"><%= txnRef %></span>
                    </div>
                </div>
            </div>
            <div class="popup-footer">
                <button class="btn btn-primary" onclick="window.location='<%= request.getContextPath() %>/user/login.jsp'">Đăng nhập ngay</button>
                <button class="btn btn-secondary" onclick="window.location='<%= request.getContextPath() %>/'">Về trang chủ</button>
            </div>
        </div>
    </div>
<%
        } catch (Exception e) {
            e.printStackTrace();
%>
    <div class="popup-overlay">
        <div class="popup-container">
            <div class="popup-header">
                <div class="error-icon">
                    <svg viewBox="0 0 24 24">
                        <line x1="18" y1="6" x2="6" y2="18"></line>
                        <line x1="6" y1="6" x2="18" y2="18"></line>
                    </svg>
                </div>
                <h1 class="popup-title">Có lỗi xảy ra!</h1>
                <p class="popup-message"><%= e.getMessage() %></p>
            </div>
            <div class="popup-footer">
                <button class="btn btn-primary" onclick="window.location='<%= request.getContextPath() %>/user/register.jsp'">Thử lại</button>
            </div>
        </div>
    </div>
<%
        }
    } else {
%>
    <div class="popup-overlay">
        <div class="popup-container">
            <div class="popup-header">
                <div class="error-icon">
                    <svg viewBox="0 0 24 24">
                        <line x1="18" y1="6" x2="6" y2="18"></line>
                        <line x1="6" y1="6" x2="18" y2="18"></line>
                    </svg>
                </div>
                <h1 class="popup-title">Thanh toán thất bại!</h1>
                <p class="popup-message">Giao dịch không thành công. Vui lòng thử lại.</p>
            </div>
            <div class="popup-footer">
                <button class="btn btn-primary" onclick="window.location='<%= request.getContextPath() %>/user/register.jsp'">Thử lại</button>
            </div>
        </div>
    </div>
<%
    }
%>
</body>
</html>