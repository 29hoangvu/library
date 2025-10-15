<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, Data.Users, Servlet.DBConnection" %>
<%
    Users user = (Users) session.getAttribute("user");
    if (user == null || user.getRoleID() != 1) {
        response.sendRedirect("adminDashboard.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Duyệt Tài Khoản</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        /* Custom animations */
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }
        
        @keyframes slideIn {
            from { transform: translateX(-10px); opacity: 0; }
            to { transform: translateX(0); opacity: 1; }
        }
        
        .fade-in {
            animation: fadeIn 0.5s ease-out;
        }
        
        .slide-in {
            animation: slideIn 0.3s ease-out forwards;
        }
        
        /* Custom gradient backgrounds */
        .gradient-purple {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        
        .gradient-green {
            background: linear-gradient(135deg, #10b981 0%, #059669 100%);
        }
        
        .gradient-red {
            background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
        }
        
        /* Hover effects */
        .btn-hover:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(0, 0, 0, 0.2);
        }
        
        .card-hover:hover {
            transform: translateY(-1px);
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
        }
        
        /* Glass effect */
        .glass-card {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        
        /* Compact table styling */
        .compact-table {
            font-size: 0.875rem; /* 14px */
        }
        
        .compact-table th {
            padding: 0.75rem 1rem;
            font-weight: 600;
            font-size: 0.8125rem; /* 13px */
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }
        
        .compact-table td {
            padding: 0.75rem 1rem;
        }
        
        /* Custom scrollbar */
        .custom-scroll::-webkit-scrollbar {
            height: 6px;
        }
        
        .custom-scroll::-webkit-scrollbar-track {
            background: #f1f5f9;
            border-radius: 3px;
        }
        
        .custom-scroll::-webkit-scrollbar-thumb {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 3px;
        }
    </style>
</head>
<body class="bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-50 min-h-screen">
    <jsp:include page="../includes/header.jsp" />

    <div class="container mx-auto px-4 py-8 mt-16">
        <!-- Header Section -->
        <div class="text-center mb-8 fade-in mt-20">
            <div class="inline-flex items-center gap-3 bg-white/80 backdrop-blur-md px-6 py-3 rounded-2xl shadow-lg">
                <h1 class="text-2xl font-bold bg-gradient-to-r from-purple-600 to-blue-600 bg-clip-text text-transparent">
                    Duyệt Đơn Đăng Ký
                </h1>
            </div>
            <p class="text-gray-600 mt-2 text-sm">Quản lý và phê duyệt tài khoản người dùng mới</p>
        </div>

        <!-- Main Card - Compact Design -->
        <div class="max-w-4xl mx-auto">
            <div class="glass-card rounded-2xl shadow-2xl card-hover transition-all duration-300">
                <!-- Card Header -->
                <div class="gradient-purple p-4 rounded-t-2xl">
                    <div class="flex items-center justify-between text-white">
                        <div class="flex items-center gap-2">
                            <span class="text-lg">📋</span>
                            <h2 class="font-semibold">Danh sách chờ duyệt</h2>
                        </div>
                        <div class="bg-white/20 backdrop-blur-md px-3 py-1 rounded-full text-xs font-medium">
                            <span id="pending-count">Đang tải...</span>
                        </div>
                    </div>
                </div>

                <!-- Table Container -->
                <div class="p-6">
                    <div class="overflow-x-auto custom-scroll bg-white rounded-xl shadow-inner">
                        <table class="w-full compact-table">
                            <thead class="bg-gradient-to-r from-gray-50 to-gray-100 border-b-2 border-gray-200">
                                <tr>
                                    <th class="text-left text-gray-700">
                                        <div class="flex items-center gap-2">
                                            <span class="w-2 h-2 bg-purple-500 rounded-full"></span>
                                            ID
                                        </div>
                                    </th>
                                    <th class="text-left text-gray-700">
                                        <div class="flex items-center gap-2">
                                            <span class="w-2 h-2 bg-blue-500 rounded-full"></span>
                                            Tên người dùng
                                        </div>
                                    </th>
                                    <th class="text-center text-gray-700">
                                        <div class="flex items-center justify-center gap-2">
                                            <span class="w-2 h-2 bg-green-500 rounded-full"></span>
                                            Hành động
                                        </div>
                                    </th>
                                </tr>
                            </thead>
                            <tbody>
                                <%
                                    Connection conn = null;
                                    PreparedStatement stmt = null;
                                    ResultSet rs = null;
                                    try {
                                        conn = DBConnection.getConnection();
                                        stmt = conn.prepareStatement("SELECT id, username FROM users WHERE status='PENDING' ORDER BY id DESC");
                                        rs = stmt.executeQuery();
                                        int count = 0;
                                        while (rs.next()) {
                                            count++;
                                            String trClass = (count % 2 == 0) ? "bg-gray-50/50" : "bg-white";
                                %>
                                <tr class="<%= trClass %> hover:bg-blue-50/70 transition-all duration-200 slide-in border-b border-gray-100 group">
                                    <td class="font-medium text-gray-900">
                                        <div class="flex items-center gap-2">
                                            <span class="w-8 h-8 bg-gradient-to-br from-purple-400 to-purple-600 text-white text-xs font-bold rounded-full flex items-center justify-center">
                                                <%= rs.getInt("id") %>
                                            </span>
                                        </div>
                                    </td>
                                    <td class="text-gray-800">
                                        <div class="flex items-center gap-2">
                                            <span class="w-2 h-2 bg-yellow-400 rounded-full animate-pulse"></span>
                                            <span class="font-medium"><%= rs.getString("username") %></span>
                                        </div>
                                    </td>
                                    <td>
                                        <div class="flex justify-center gap-2">
                                            <form action="ApproveUserServlet" method="post" class="inline-block">
                                                <input type="hidden" name="userID" value="<%= rs.getInt("id") %>">
                                                <button type="submit" 
                                                        name="action" 
                                                        value="approve"
                                                        class="gradient-green text-white px-3 py-1.5 rounded-lg text-xs font-semibold btn-hover transition-all duration-200 flex items-center gap-1 shadow-md">
                                                    <span class="text-sm">✓</span>
                                                    <span>Duyệt</span>
                                                </button>
                                            </form>
                                            <form action="ApproveUserServlet" method="post" class="inline-block">
                                                <input type="hidden" name="userID" value="<%= rs.getInt("id") %>">
                                                <button type="submit" 
                                                        name="action" 
                                                        value="reject"
                                                        class="gradient-red text-white px-3 py-1.5 rounded-lg text-xs font-semibold btn-hover transition-all duration-200 flex items-center gap-1 shadow-md">
                                                    <span class="text-sm">✗</span>
                                                    <span>Từ chối</span>
                                                </button>
                                            </form>
                                        </div>
                                    </td>
                                </tr>
                                <% 
                                        }
                                        if (count == 0) { 
                                %>
                                <tr>
                                    <td colspan="3" class="py-12 text-center">
                                        <div class="flex flex-col items-center gap-4">
                                            <div class="w-16 h-16 bg-gradient-to-br from-gray-200 to-gray-300 rounded-full flex items-center justify-center">
                                                <span class="text-2xl text-gray-400">📋</span>
                                            </div>
                                            <div class="text-center">
                                                <p class="text-gray-500 font-medium">Không có đơn đăng ký nào cần duyệt</p>
                                                <p class="text-gray-400 text-sm mt-1">Tất cả tài khoản đã được xử lý</p>
                                            </div>
                                        </div>
                                    </td>
                                </tr>
                                <script>
                                    document.getElementById('pending-count').textContent = '0 đang chờ';
                                </script>
                                <% 
                                        } else {
                                %>
                                <script>
                                    document.getElementById('pending-count').textContent = '<%= count %> đang chờ';
                                </script>
                                <%
                                        }
                                    } catch (Exception e) { 
                                %>
                                <tr>
                                    <td colspan="3" class="py-8">
                                        <div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-xl mx-4">
                                            <div class="flex items-center gap-3">
                                                <span class="text-red-500 text-xl">⚠️</span>
                                                <div>
                                                    <p class="font-semibold">Có lỗi xảy ra</p>
                                                    <p class="text-sm text-red-600"><%= e.getMessage() %></p>
                                                </div>
                                            </div>
                                        </div>
                                    </td>
                                </tr>
                                <script>
                                    document.getElementById('pending-count').textContent = 'Lỗi';
                                </script>
                                <% 
                                    } finally {
                                        try { if (rs != null) rs.close(); } catch(Exception ig) {}
                                        try { if (stmt != null) stmt.close(); } catch(Exception ig) {}
                                        try { if (conn != null) conn.close(); } catch(Exception ig) {}
                                    } 
                                %>
                            </tbody>
                        </table>
                    </div>
                </div>
                
                <!-- Card Footer -->
                <div class="bg-gray-50 px-6 py-4 rounded-b-2xl border-t border-gray-100">
                    <div class="flex items-center justify-between text-sm text-gray-600">
                        <div class="flex items-center gap-2">
                            <span class="w-2 h-2 bg-green-400 rounded-full"></span>
                            <span>Hệ thống quản lý tài khoản</span>
                        </div>
                        <div class="flex items-center gap-4">
                            <span class="flex items-center gap-1">
                                <span class="text-green-500">✓</span>
                                Duyệt
                            </span>
                            <span class="flex items-center gap-1">
                                <span class="text-red-500">✗</span>
                                Từ chối
                            </span>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Quick Stats Cards -->
        <div class="max-w-4xl mx-auto mt-6 grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="glass-card rounded-xl p-4 text-center card-hover transition-all duration-300">
                <div class="text-2xl mb-2">⏳</div>
                <p class="text-sm text-gray-600">Chờ xử lý</p>
                <p class="font-bold text-purple-600" id="stats-pending">-</p>
            </div>
            <div class="glass-card rounded-xl p-4 text-center card-hover transition-all duration-300">
                <div class="text-2xl mb-2">✅</div>
                <p class="text-sm text-gray-600">Đã duyệt</p>
                <p class="font-bold text-green-600">-</p>
            </div>
            <div class="glass-card rounded-xl p-4 text-center card-hover transition-all duration-300">
                <div class="text-2xl mb-2">❌</div>
                <p class="text-sm text-gray-600">Đã từ chối</p>
                <p class="font-bold text-red-600">-</p>
            </div>
        </div>
    </div>

    <script>
        // Add loading animation
        document.addEventListener('DOMContentLoaded', function() {
            const rows = document.querySelectorAll('.slide-in');
            rows.forEach((row, index) => {
                row.style.animationDelay = `${index * 0.1}s`;
            });
        });
    </script>
</body>
</html>