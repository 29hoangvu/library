<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.time.*, java.time.format.DateTimeFormatter" %>
<%
    // Lấy thông tin từ session hoặc request
    String username = (String) session.getAttribute("REG_username");
    String email = (String) session.getAttribute("REG_email");
    Integer years = (Integer) session.getAttribute("REG_years");
    String paymentMethod = request.getParameter("paymentMethod");
    
    // Nếu không có thông tin, redirect về trang đăng ký
    if (username == null || email == null || years == null) {
        response.sendRedirect(request.getContextPath() + "/user/register.jsp");
        return;
    }
    
    // Tính toán ngày
    LocalDate today = LocalDate.now();
    LocalDate expiry = today.plusYears(years);
    LocalDate deadline = today.plusDays(7);
    
    DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    String expiryStr = expiry.format(formatter);
    String deadlineStr = deadline.format(formatter);
    
    // Tính lệ phí
    long amount = 100_000L * years;
    String amountStr = String.format("%,d đ", amount).replace(',', '.');
    
    // Kiểm tra phương thức thanh toán
    boolean isOffline = "offline".equalsIgnoreCase(paymentMethod);
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <title>Đăng ký thành công</title>
    
    <!-- Tailwind -->
    <script src="https://cdn.tailwindcss.com"></script>
    
    <!-- Icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css"/>
    
    <!-- Font -->
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap"/>
    
    <!-- Favicon -->
    <link rel="icon" href="<%=request.getContextPath()%>/images/reading-book.png" type="image/x-icon"/>
    
    <!-- Global theme -->
    <link rel="stylesheet" href="style1.css"/>
    
    <style>
        body {
            font-family: 'Inter', sans-serif;
        }
        
        .success-container {
            max-width: 520px;
            margin: 0 auto;
            padding: 2rem 1rem;
        }
        
        .success-card {
            background: radial-gradient(circle at top left, rgba(15, 23, 42, 0.98), rgba(15, 23, 42, 0.95));
            border: 1px solid rgba(148, 163, 184, 0.3);
            border-radius: 1.5rem;
            padding: 2.5rem 2rem;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5);
        }
        
        .warning-icon {
            width: 80px;
            height: 80px;
            background: linear-gradient(135deg, #f59e0b, #d97706);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 1.5rem;
            box-shadow: 0 8px 24px rgba(245, 158, 11, 0.4);
        }
        
        .info-row {
            display: flex;
            justify-content: space-between;
            padding: 1rem 0;
            border-bottom: 1px solid rgba(148, 163, 184, 0.2);
            font-size: 0.95rem;
        }
        
        .info-row:last-child {
            border-bottom: none;
        }
        
        .info-label {
            color: #94a3b8;
            font-weight: 500;
        }
        
        .info-value {
            color: #f1f5f9;
            font-weight: 600;
            text-align: right;
        }
        
        .deadline-highlight {
            color: #ef4444;
            font-weight: 700;
        }
        
        .warning-box {
            background: rgba(251, 191, 36, 0.15);
            border: 1px solid rgba(251, 191, 36, 0.4);
            border-left: 4px solid #f59e0b;
            border-radius: 0.75rem;
            padding: 1.25rem;
            margin: 1.5rem 0;
        }
        
        .warning-box-text {
            color: #fbbf24;
            font-size: 0.9rem;
            line-height: 1.6;
            display: flex;
            align-items: start;
            gap: 0.75rem;
        }
        
        .btn-primary {
            width: 100%;
            background: linear-gradient(135deg, #6366f1, #8b5cf6, #3b82f6);
            color: white;
            font-weight: 600;
            padding: 1rem;
            border-radius: 0.875rem;
            border: none;
            cursor: pointer;
            font-size: 1rem;
            transition: all 0.3s ease;
            box-shadow: 0 4px 20px rgba(99, 102, 241, 0.4);
            margin-top: 1.5rem;
        }
        
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 28px rgba(99, 102, 241, 0.6);
        }
        
        .btn-secondary {
            width: 100%;
            background: rgba(148, 163, 184, 0.1);
            color: #cbd5e1;
            font-weight: 500;
            padding: 0.875rem;
            border-radius: 0.875rem;
            border: 1px solid rgba(148, 163, 184, 0.3);
            cursor: pointer;
            font-size: 0.95rem;
            transition: all 0.3s ease;
            margin-top: 0.75rem;
        }
        
        .btn-secondary:hover {
            background: rgba(148, 163, 184, 0.2);
            border-color: rgba(148, 163, 184, 0.5);
        }
        
        .success-title {
            color: #f1f5f9;
            font-size: 1.75rem;
            font-weight: 800;
            text-align: center;
            margin-bottom: 0.75rem;
        }
        
        .success-subtitle {
            color: #cbd5e1;
            font-size: 0.95rem;
            text-align: center;
            margin-bottom: 2rem;
            line-height: 1.5;
        }
        
        .online-success-icon {
            width: 80px;
            height: 80px;
            background: linear-gradient(135deg, #10b981, #059669);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 1.5rem;
            box-shadow: 0 8px 24px rgba(16, 185, 129, 0.4);
        }
        
        .success-box {
            background: rgba(16, 185, 129, 0.15);
            border: 1px solid rgba(16, 185, 129, 0.4);
            border-left: 4px solid #10b981;
            border-radius: 0.75rem;
            padding: 1.25rem;
            margin: 1.5rem 0;
        }
        
        .success-box-text {
            color: #6ee7b7;
            font-size: 0.9rem;
            line-height: 1.6;
            display: flex;
            align-items: start;
            gap: 0.75rem;
        }
    </style>
</head>

<body class="page-background">
    <!-- Floating icons -->
    <div class="floating-elements">
        <i class="fas fa-book floating-book text-6xl text-blue-500" style="top: 10%; left: 85%; --float-duration: 13s;"></i>
        <i class="fas fa-bookmark floating-book text-5xl text-purple-500" style="top: 18%; left: 7%; --float-duration: 15s;"></i>
        <i class="fas fa-feather floating-book text-5xl text-emerald-500" style="top: 55%; left: 88%; --float-duration: 17s;"></i>
        <i class="fas fa-scroll floating-book text-4xl text-orange-500" style="top: 78%; left: 6%; --float-duration: 19s;"></i>
    </div>

    <div class="success-container min-h-screen flex items-center justify-center">
        <div class="success-card">
            <% if (isOffline) { %>
                <!-- OFFLINE PAYMENT -->
                <div class="warning-icon">
                    <i class="fas fa-exclamation text-white text-4xl"></i>
                </div>
                
                <h1 class="success-title">Đăng ký thành công!</h1>
                <p class="success-subtitle">
                    Tài khoản của bạn đã được tạo với trạng thái chờ kích hoạt.
                </p>
                
                <div class="warning-box">
                    <div class="warning-box-text">
                        <i class="fas fa-info-circle text-xl mt-0.5 flex-shrink-0"></i>
                        <span>
                            <strong>Vui lòng đến thư viện để nộp lệ phí trong vòng 7 ngày để kích hoạt tài khoản!</strong>
                        </span>
                    </div>
                </div>
                
                <div class="mt-6">
                    <div class="info-row">
                        <span class="info-label">Tên đăng nhập:</span>
                        <span class="info-value"><%= username %></span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">Email:</span>
                        <span class="info-value"><%= email %></span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">Gói dịch vụ:</span>
                        <span class="info-value"><%= years %> năm</span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">Lệ phí cần nộp:</span>
                        <span class="info-value"><%= amountStr %></span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">Hiệu lực đến:</span>
                        <span class="info-value"><%= expiryStr %></span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">Hạn nộp phí:</span>
                        <span class="info-value deadline-highlight"><%= deadlineStr %></span>
                    </div>
                </div>
                
                <button class="btn-primary" onclick="window.location.href='<%=request.getContextPath()%>/user/login.jsp'">
                    <i class="fas fa-sign-in-alt mr-2"></i>
                    Đăng nhập ngay
                </button>
                
            <% } else { %>
                <!-- ONLINE PAYMENT SUCCESS -->
                <div class="online-success-icon">
                    <i class="fas fa-check text-white text-4xl"></i>
                </div>
                
                <h1 class="success-title">Thanh toán thành công!</h1>
                <p class="success-subtitle">
                    Tài khoản của bạn đã được kích hoạt và sẵn sàng sử dụng.
                </p>
                
                <div class="success-box">
                    <div class="success-box-text">
                        <i class="fas fa-check-circle text-xl mt-0.5 flex-shrink-0"></i>
                        <span>
                            <strong>Giao dịch đã được xác nhận.</strong> Bạn có thể đăng nhập và bắt đầu sử dụng các dịch vụ của thư viện ngay bây giờ!
                        </span>
                    </div>
                </div>
                
                <div class="mt-6">
                    <div class="info-row">
                        <span class="info-label">Tên đăng nhập:</span>
                        <span class="info-value"><%= username %></span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">Email:</span>
                        <span class="info-value"><%= email %></span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">Gói dịch vụ:</span>
                        <span class="info-value"><%= years %> năm</span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">Đã thanh toán:</span>
                        <span class="info-value" style="color: #10b981;"><%= amountStr %></span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">Hiệu lực đến:</span>
                        <span class="info-value"><%= expiryStr %></span>
                    </div>
                </div>
                
                <button class="btn-primary" onclick="window.location.href='<%=request.getContextPath()%>/user/login.jsp'">
                    <i class="fas fa-sign-in-alt mr-2"></i>
                    Đăng nhập ngay
                </button>
            <% } %>
            
            <button class="btn-secondary" onclick="window.location.href='<%=request.getContextPath()%>/index.jsp'">
                <i class="fas fa-home mr-2"></i>
                Về trang chủ
            </button>
        </div>
    </div>

    <script>
        // Clear session data after showing success message
        setTimeout(() => {
            // Optional: You can add AJAX call here to clear session on server
            console.log('Success page loaded');
        }, 1000);
    </script>
</body>
</html>
