<%@page import="java.net.URLEncoder"%>
<%@ page import="java.sql.*, java.time.*, java.time.format.DateTimeFormatter" %>
<%@ page import="Servlet.DBConnection, Servlet.PasswordHashing, Servlet.EmailUtility" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %><%
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
                            return; // dừng hẳn nhánh offline
                        }
                    }
                }

                // Tạo tài khoản PENDING
                LocalDate today = LocalDate.now();
                LocalDate expiry = today.plusYears(years);
                LocalDate deadline = today.plusDays(7); // hạn nộp phí 7 ngày

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
                    // Định dạng tiền Việt (đơn giản)
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
                    // Không làm fail quy trình chỉ vì gửi mail lỗi
                    mailEx.printStackTrace();
                }

                out.println("<script>alert('Đăng ký thành công! Vui lòng đến thư viện để nộp lệ phí trong 7 ngày để kích hoạt tài khoản.'); "
                        + "window.location='" + request.getContextPath() + "/user/login.jsp';</script>");
                return;
            } catch (Exception e) {
                e.printStackTrace();
                return;
            }
        } else {
            long amount = 100_000L * years; // đơn vị VND
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
            // KHÔNG viết gì bên dưới và KHÔNG thêm return;
        }
    }
%>
