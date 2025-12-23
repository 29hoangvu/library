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
            try {
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
                        + "  <h2 style='color:#10b981;margin:0 0 12px'>Thanh toán thành công!</h2>"
                        + "  <p>Xin chào <b>" + username + "</b>,</p>"
                        + "  <p>Cảm ơn bạn đã đăng ký tài khoản thành viên <b>Thư Viện Số</b>. Giao dịch của bạn đã được xác nhận thành công.</p>"
                        + "  <ul>"
                        + "    <li><b>Thời điểm thanh toán:</b> " + nowStr + " (GMT+7)</li>"
                        + "    <li><b>Thời gian hiệu lực:</b> từ " + startStr + " đến hết ngày " + expiryStr + "</li>"
                        + "    <li><b>Gói đã đăng ký:</b> " + years + " năm</li>"
                        + "    <li><b>Số tiền đã thanh toán:</b> " + amountStr + "</li>"
                        + "    <li><b>Mã giao dịch:</b> " + txnRef + "</li>"
                        + "    <li><b>Tài khoản:</b> " + username + " (" + email + ")</li>"
                        + "  </ul>"
                        + "  <p><b>Tài khoản của bạn đã được kích hoạt!</b> Bạn có thể đăng nhập ngay để sử dụng các dịch vụ của thư viện.</p>"
                        + "  <p>Vui lòng <b>đăng nhập</b> và <b>cập nhật thông tin cá nhân</b> (họ tên, ngày sinh, số điện thoại, địa chỉ...) để hoàn tất hồ sơ.</p>"
                        + "  <p style='margin-top:16px'>Trân trọng,<br/>Đội ngũ <b>Thư Viện Số</b></p>"
                        + "</div>";

                // Gửi HTML (nếu đã thêm sendHtmlEmail)
                EmailUtility.sendHtmlEmail(email, subject, html);
            } catch (Exception mailEx) {
                // Không làm fail quy trình chỉ vì gửi mail lỗi
                mailEx.printStackTrace();
            }

            // ===== GIỮ THÔNG TIN TRONG SESSION ĐỂ HIỂN THỊ TRANG SUCCESS =====
            // Không xóa session ngay, để trang success lấy được thông tin
            // session sẽ được clear sau khi user rời khỏi trang success
            
            // Redirect đến trang thành công với phương thức online
            response.sendRedirect(request.getContextPath() + "/user/registration_success.jsp?paymentMethod=online");
            
        } catch (Exception e) {
            e.printStackTrace();
            out.println("<script>alert('Có lỗi khi lưu dữ liệu: " + e.getMessage().replace("'", "\\'") + "'); window.location='" + request.getContextPath() + "/user/register.jsp';</script>");
        }
    } else {
        // Thanh toán không thành công
        String errorMsg = "Thanh toán không thành công!";
        
        // Xử lý các mã lỗi cụ thể từ VNPAY
        if ("24".equals(vnp_ResponseCode)) {
            errorMsg = "Giao dịch bị hủy bỏ.";
        } else if ("11".equals(vnp_ResponseCode)) {
            errorMsg = "Đã hết thời gian thanh toán.";
        } else if ("51".equals(vnp_ResponseCode)) {
            errorMsg = "Tài khoản không đủ số dư.";
        } else if ("65".equals(vnp_ResponseCode)) {
            errorMsg = "Tài khoản đã vượt quá giới hạn giao dịch.";
        } else if ("75".equals(vnp_ResponseCode)) {
            errorMsg = "Ngân hàng thanh toán đang bảo trì.";
        } else if ("79".equals(vnp_ResponseCode)) {
            errorMsg = "Giao dịch vượt quá số lần thanh toán cho phép.";
        }
        
        out.println("<script>alert('" + errorMsg + " Vui lòng thử lại!'); window.location='" + request.getContextPath() + "/user/register.jsp';</script>");
    }
%>
