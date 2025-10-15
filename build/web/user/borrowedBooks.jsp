<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.Connection,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException" %>
<%@ page import="java.util.List,java.util.Map,java.util.HashMap,java.util.ArrayList" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="Servlet.DBConnection, Data.Users" %>

<%
    Connection conn = DBConnection.getConnection();
    if (conn == null) {
        out.println("<p>Lỗi kết nối CSDL</p>");
        return;
    }

    Users user = (Users) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect("index.jsp");
        return;
    }

    int userId = user.getId();
    List<Map<String, String>> borrowedBooks = new ArrayList<>();

    try {
        String query = "SELECT br.borrow_id, b.isbn, b.title, br.borrowed_date, br.due_date, br.return_date, br.status " +
                       "FROM borrow br " +
                       "JOIN bookitem bi ON br.book_item_id = bi.book_item_id " +
                       "JOIN book b ON bi.book_isbn = b.isbn " +
                       "WHERE br.user_id = ?";
        PreparedStatement stmt = conn.prepareStatement(query);
        stmt.setInt(1, userId);
        ResultSet rs = stmt.executeQuery();

        SimpleDateFormat df = new SimpleDateFormat("dd/MM/yyyy");

        while (rs.next()) {
            Map<String, String> book = new HashMap<>();
            book.put("borrow_id", rs.getString("borrow_id"));
            book.put("isbn", rs.getString("isbn"));
            book.put("title", rs.getString("title"));

            java.sql.Date borrowedDate = rs.getDate("borrowed_date");
            java.sql.Date dueDate     = rs.getDate("due_date");
            java.sql.Date returnDate  = rs.getDate("return_date");

            book.put("borrowed_date", borrowedDate != null ? df.format(new java.util.Date(borrowedDate.getTime())) : "");
            book.put("due_date",     dueDate     != null ? df.format(new java.util.Date(dueDate.getTime()))       : "");
            book.put("return_date",  returnDate  != null ? df.format(new java.util.Date(returnDate.getTime()))    : "Chưa trả");

            book.put("status", rs.getString("status"));
            borrowedBooks.add(book);
        }

        rs.close();
        stmt.close();
    } catch (SQLException e) {
        out.println("<p>Lỗi truy vấn dữ liệu: " + e.getMessage() + "</p>");
    }
%>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sách đã mượn - Thư viện Sách</title>

    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    fontFamily: {
                        'inter': ['Inter', 'sans-serif'],
                    },
                    colors: {
                        'primary': '#3b82f6',
                        'secondary': '#64748b',
                    }
                }
            }
        }
    </script>

    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css">

    <!-- Google Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">

    <!-- Favicon -->
    <link rel="icon" href="./images/reading-book.png" type="image/x-icon" />

    <!-- Custom CSS -->
    <link rel="stylesheet" href="home1.css"/>
    <link rel="stylesheet" href="loading.css"/>

    <style>
        .page-container {
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }
        
        .main-content {
            flex: 1;
            padding-bottom: 4rem; /* Space for footer */
        }

        .status-badge {
            display: inline-flex;
            align-items: center;
            padding: 0.25rem 0.75rem;
            border-radius: 9999px;
            font-size: 0.75rem;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.025em;
        }
        
        .status-waiting {
            background-color: #fef3c7;
            color: #d97706;
            border: 1px solid #f59e0b;
        }
        
        .status-borrowed {
            background-color: #dcfce7;
            color: #16a34a;
            border: 1px solid #22c55e;
        }
        
        .status-overdue {
            background-color: #fee2e2;
            color: #dc2626;
            border: 1px solid #ef4444;
        }
        
        .status-returned {
            background-color: #dbeafe;
            color: #2563eb;
            border: 1px solid #3b82f6;
        }

        .table-hover tr:hover {
            background-color: #f8fafc !important;
            transition: background-color 0.2s ease;
        }

        .cancel-btn {
            transition: all 0.2s ease;
        }

        .cancel-btn:hover {
            transform: translateY(-1px);
            box-shadow: 0 4px 8px rgba(239, 68, 68, 0.3);
        }

        .floating-elements {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            pointer-events: none;
            z-index: -1;
            opacity: 0.1;
        }

        .floating-book {
            position: absolute;
            animation: float 6s ease-in-out infinite;
        }

        @keyframes float {
            0%, 100% { transform: translateY(0px) rotate(0deg); }
            50% { transform: translateY(-20px) rotate(5deg); }
        }

        .card-shadow {
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
        }

        .card-shadow:hover {
            box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
            transition: box-shadow 0.3s ease;
        }

        @media (max-width: 768px) {
            .table-container {
                overflow-x: auto;
            }
            
            .table-responsive {
                min-width: 800px;
            }
        }
    </style>

    <script>
        function confirmCancel(borrowId) {
            if (confirm("Bạn có chắc chắn muốn hủy đăng ký mượn sách này?")) {
                window.location.href = "${pageContext.request.contextPath}/CancelBorrowServlet?borrow_id=" + borrowId;
            }
        }
    </script>
</head>

<body class="page-background font-inter page-container">
    <!-- Floating Background Elements -->
    <div class="floating-elements">
        <i class="fas fa-book floating-book text-6xl text-blue-500" style="top: 10%; left: 85%; animation-delay: 0s;"></i>
        <i class="fas fa-bookmark floating-book text-4xl text-purple-500" style="top: 20%; left: 10%; animation-delay: 2s;"></i>
        <i class="fas fa-feather floating-book text-5xl text-green-500" style="top: 60%; left: 90%; animation-delay: 4s;"></i>
        <i class="fas fa-scroll floating-book text-4xl text-orange-500" style="top: 80%; left: 5%; animation-delay: 6s;"></i>
    </div>

    <!-- Include Header -->
    <jsp:include page="layout/header.jsp" />

    <div class="main-content">
        <!-- Page Loader -->
            <div id="page-loader" role="status" aria-live="polite">
                <div class="spinner mb-6"></div>
                <div class="text-center mb-6">
                    <div class="loader-title text-xl">Đang tải dữ liệu…</div>
                    <div class="loader-sub text-sm">Vui lòng chờ trong giây lát</div>
                </div>

                <!-- Skeleton: 1 hàng sách giả để người dùng có gì đó nhìn -->
                <div class="shelf-skeleton px-6">
                    <!-- lặp vài thẻ giả (5–7 cái) -->
                    <div class="sk-card">
                        <div class="sk-img shimmer"></div>
                        <div class="p-4 space-y-3">
                            <div class="sk-line w1 shimmer relative"></div>
                            <div class="sk-line w2 shimmer relative"></div>
                            <div class="sk-line w3 shimmer relative"></div>
                        </div>
                    </div>
                    <div class="sk-card">
                        <div class="sk-img shimmer"></div>
                        <div class="p-4 space-y-3">
                            <div class="sk-line w1 shimmer relative"></div>
                            <div class="sk-line w2 shimmer relative"></div>
                            <div class="sk-line w3 shimmer relative"></div>
                        </div>
                    </div>
                    <div class="sk-card"><div class="sk-img shimmer"></div><div class="p-4 space-y-3"><div class="sk-line w1 shimmer relative"></div><div class="sk-line w2 shimmer relative"></div><div class="sk-line w3 shimmer relative"></div></div></div>
                    <div class="sk-card"><div class="sk-img shimmer"></div><div class="p-4 space-y-3"><div class="sk-line w1 shimmer relative"></div><div class="sk-line w2 shimmer relative"></div><div class="sk-line w3 shimmer relative"></div></div></div>
                    <div class="sk-card"><div class="sk-img shimmer"></div><div class="p-4 space-y-3"><div class="sk-line w1 shimmer relative"></div><div class="sk-line w2 shimmer relative"></div><div class="sk-line w3 shimmer relative"></div></div></div>
                </div>
            </div>
        <div id="app-content">
        <div class="container mx-auto px-4 py-8 max-w-7xl">
            <!-- Page Header -->
            <div class="mb-8">
                <div class="flex items-center mb-4">
                    <i class="fas fa-book-open text-3xl text-primary mr-4"></i>
                    <h1 class="text-3xl font-bold text-gray-800">Sách đã mượn</h1>
                </div>
                <p class="text-gray-600">Quản lý danh sách các sách bạn đã mượn từ thư viện</p>
            </div>

            <!-- Stats Cards -->
            <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
                <%
                    int totalBooks = borrowedBooks.size();
                    int pendingBooks = 0, borrowedCount = 0, overdueCount = 0, returnedCount = 0;
                    
                    for (Map<String, String> book : borrowedBooks) {
                        String status = book.get("status");
                        if ("Pending Approval".equals(status)) pendingBooks++;
                        else if ("Borrowed".equals(status)) borrowedCount++;
                        else if ("Overdue".equals(status)) overdueCount++;
                        else if ("Returned".equals(status)) returnedCount++;
                    }
                %>
                
                <div class="bg-white rounded-xl p-6 card-shadow">
                    <div class="flex items-center">
                        <div class="p-3 bg-blue-100 rounded-lg">
                            <i class="fas fa-books text-2xl text-blue-600"></i>
                        </div>
                        <div class="ml-4">
                            <p class="text-sm text-gray-600">Tổng sách</p>
                            <p class="text-2xl font-bold text-gray-800"><%= totalBooks %></p>
                        </div>
                    </div>
                </div>

                <div class="bg-white rounded-xl p-6 card-shadow">
                    <div class="flex items-center">
                        <div class="p-3 bg-yellow-100 rounded-lg">
                            <i class="fas fa-clock text-2xl text-yellow-600"></i>
                        </div>
                        <div class="ml-4">
                            <p class="text-sm text-gray-600">Chờ duyệt</p>
                            <p class="text-2xl font-bold text-yellow-600"><%= pendingBooks %></p>
                        </div>
                    </div>
                </div>

                <div class="bg-white rounded-xl p-6 card-shadow">
                    <div class="flex items-center">
                        <div class="p-3 bg-green-100 rounded-lg">
                            <i class="fas fa-book-reader text-2xl text-green-600"></i>
                        </div>
                        <div class="ml-4">
                            <p class="text-sm text-gray-600">Đang mượn</p>
                            <p class="text-2xl font-bold text-green-600"><%= borrowedCount %></p>
                        </div>
                    </div>
                </div>

                <div class="bg-white rounded-xl p-6 card-shadow">
                    <div class="flex items-center">
                        <div class="p-3 bg-red-100 rounded-lg">
                            <i class="fas fa-exclamation-triangle text-2xl text-red-600"></i>
                        </div>
                        <div class="ml-4">
                            <p class="text-sm text-gray-600">Quá hạn</p>
                            <p class="text-2xl font-bold text-red-600"><%= overdueCount %></p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Books Table -->
            <div class="bg-white rounded-xl card-shadow overflow-hidden">
                <div class="px-6 py-4 bg-gradient-to-r from-blue-500 to-blue-600">
                    <h3 class="text-xl font-semibold text-white flex items-center">
                        <i class="fas fa-list mr-2"></i>
                        Danh sách sách đã mượn
                    </h3>
                </div>

                <div class="table-container">
                    <% if (borrowedBooks.isEmpty()) { %>
                        <div class="text-center py-12">
                            <i class="fas fa-book-open text-6xl text-gray-300 mb-4"></i>
                            <p class="text-gray-500 text-lg">Bạn chưa mượn sách nào</p>
                            <a href="${pageContext.request.contextPath}/index.jsp" class="inline-block mt-4 bg-blue-500 text-white px-6 py-2 rounded-lg hover:bg-blue-600 transition-colors">
                                Khám phá sách
                            </a>
                        </div>
                    <% } else { %>
                        <table class="table-responsive w-full">
                            <thead class="bg-gray-50">
                                <tr>
                                    <th class="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                        <i class="fas fa-barcode mr-2"></i>ISBN
                                    </th>
                                    <th class="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                        <i class="fas fa-book mr-2"></i>Tên sách
                                    </th>
                                    <th class="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                        <i class="fas fa-calendar-plus mr-2"></i>Ngày mượn
                                    </th>
                                    <th class="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                        <i class="fas fa-calendar-times mr-2"></i>Hạn trả
                                    </th>
                                    <th class="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                        <i class="fas fa-calendar-check mr-2"></i>Ngày trả
                                    </th>
                                    <th class="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                        <i class="fas fa-info-circle mr-2"></i>Trạng thái
                                    </th>
                                    <th class="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                        <i class="fas fa-cogs mr-2"></i>Hành động
                                    </th>
                                </tr>
                            </thead>
                            <tbody class="bg-white divide-y divide-gray-200 table-hover">
                                <% for (Map<String, String> book : borrowedBooks) { 
                                    String status = book.get("status");
                                    String statusClass = "status-waiting";
                                    String statusText = "Chờ duyệt";

                                    if ("Pending Approval".equals(status)) {
                                        statusClass = "status-waiting";
                                        statusText = "Chờ duyệt";
                                    } else if ("Borrowed".equals(status)) {
                                        statusClass = "status-borrowed";
                                        statusText = "Đang mượn";
                                    } else if ("Overdue".equals(status)) {
                                        statusClass = "status-overdue";
                                        statusText = "Quá hạn";
                                    } else if ("Returned".equals(status)) {
                                        statusClass = "status-returned";
                                        statusText = "Đã trả";
                                    }
                                %>
                                    <tr class="hover:bg-gray-50 transition-colors">
                                        <td class="px-6 py-4 whitespace-nowrap text-sm font-mono text-gray-900">
                                            <%= book.get("isbn") %>
                                        </td>
                                        <td class="px-6 py-4 text-sm text-gray-900">
                                            <div class="font-medium">
                                                <%= book.get("title") %>
                                            </div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                            <% if (!book.get("borrowed_date").isEmpty()) { %>
                                                <i class="fas fa-calendar text-blue-500 mr-2"></i>
                                            <% } %>
                                            <%= book.get("borrowed_date") %>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                            <% if (!book.get("due_date").isEmpty()) { %>
                                                <i class="fas fa-calendar text-orange-500 mr-2"></i>
                                            <% } %>
                                            <%= book.get("due_date") %>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                            <% if (!"Chưa trả".equals(book.get("return_date"))) { %>
                                                <i class="fas fa-calendar-check text-green-500 mr-2"></i>
                                            <% } %>
                                            <%= book.get("return_date") %>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <span class="status-badge <%= statusClass %>">
                                                <%= statusText %>
                                            </span>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap text-sm">
                                            <% if ("Pending Approval".equals(status)) { %>
                                                <button 
                                                    class="cancel-btn bg-red-500 hover:bg-red-600 text-white px-4 py-2 rounded-lg font-medium flex items-center transition-all duration-200"
                                                    onclick="confirmCancel('<%= book.get("borrow_id") %>')"
                                                >
                                                    <i class="fas fa-times mr-2"></i>
                                                    Hủy
                                                </button>
                                            <% } else { %>
                                                <span class="text-gray-400 text-sm">Không có</span>
                                            <% } %>
                                        </td>
                                    </tr>
                                <% } %>
                            </tbody>
                        </table>
                    <% } %>
                </div>
            </div>
        </div>
    </div>

    <!-- Include Footer -->
    <jsp:include page="layout/footer.jsp" />
    </div>
    <script src="script.js"></script>
</body>
</html>