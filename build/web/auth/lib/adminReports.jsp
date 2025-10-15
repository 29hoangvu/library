<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.util.*, java.net.URLEncoder, Servlet.DBConnection, Data.Users" %>

<%-- ========= Helpers cho JSON (khai báo cấp trang) ========= --%>
<%!
    private String toJsonStringArray(java.util.List<String> list) {
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < list.size(); i++) {
            String s = list.get(i) == null ? "" : list.get(i);
            s = s.replace("\\", "\\\\").replace("\"", "\\\"");
            sb.append("\"").append(s).append("\"");
            if (i < list.size() - 1) {
                sb.append(",");
            }
        }
        sb.append("]");
        return sb.toString();
    }

    private String toJsonIntArray(java.util.List<Integer> list) {
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < list.size(); i++) {
            int v = (list.get(i) == null ? 0 : list.get(i));
            sb.append(v);
            if (i < list.size() - 1) {
                sb.append(",");
            }
        }
        sb.append("]");
        return sb.toString();
    }
    private int parseIntOrDefault(String s, int d) {
            if (s == null || s.isBlank()) return d;
            try { return Integer.parseInt(s); } catch (Exception e) { return d; }
        }
%>

<%
    request.setAttribute("pageTitle", "Thống kê & Báo cáo");
    Users user = (Users) session.getAttribute("user");
    if (user == null || (user.getRoleID() != 1 && user.getRoleID() != 2)) {
        response.sendRedirect("../../index.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html lang="vi">
    <head>
        <meta charset="UTF-8" />
        <title><%= request.getAttribute("pageTitle")%></title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />

        <!-- Tailwind -->
        <script src="https://cdn.tailwindcss.com"></script>
        <!-- Chart.js -->
        <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

        <!-- Fonts & Icons -->
        <link rel="preconnect" href="https://fonts.googleapis.com">
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
        <link rel="icon" href="./images/reading-book.png" type="image/x-icon" />

        <style>
            html, body {
                font-family: Inter, ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, Arial;
            }
            
            .glass-card {
                background: rgba(255, 255, 255, 0.9);
                backdrop-filter: blur(10px);
                border: 1px solid rgba(255, 255, 255, 0.18);
            }
            
            .gradient-bg {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            }
            
            .gradient-bg-alt {
                background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
            }
            
            .chart-card {
                transition: all 0.3s ease;
            }
            
            .chart-card:hover {
                transform: translateY(-4px);
                box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
            }
            
            .stat-badge {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            }
            
            @keyframes fadeIn {
                from { opacity: 0; transform: translateY(20px); }
                to { opacity: 1; transform: translateY(0); }
            }
            
            .animate-fade-in {
                animation: fadeIn 0.6s ease-out;
            }
            
            .filter-select {
                appearance: none;
                background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3E%3Cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='M6 8l4 4 4-4'/%3E%3C/svg%3E");
                background-position: right 0.5rem center;
                background-repeat: no-repeat;
                background-size: 1.5em 1.5em;
                padding-right: 2.5rem;
            }
        </style>
        
        <script>
            tailwind.config = {
                theme: {
                    extend: {
                        colors: {
                            primary: '#667eea',
                            secondary: '#764ba2',
                        }
                    }
                }
            }
        </script>
    </head>
    <%-- Header chung --%>
    <jsp:include page="../includes/header.jsp" />
    <body class="bg-gradient-to-br from-gray-50 via-blue-50 to-purple-50 min-h-screen">         
        <main id="mainContent" class="transition-all duration-300 pt-32 pb-12">
            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                
                <%-- Page Header --%>
                <div class="mb-8 animate-fade-in mt-10">
                    <div class="flex items-center gap-3 mb-2">
                        <div class="w-12 h-12 rounded-2xl gradient-bg flex items-center justify-center">
                            <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                            </svg>
                        </div>
                        <div>
                            <h1 class="text-3xl font-bold text-gray-900">Thống kê & Báo cáo</h1>
                            <p class="text-gray-600 text-sm mt-1">Phân tích dữ liệu thư viện chi tiết</p>
                        </div>
                    </div>
                </div>

                <%-- ====== Bộ lọc ====== --%>
                <div class="glass-card rounded-3xl shadow-xl p-6 mb-8 animate-fade-in">
                    <div class="flex items-center gap-2 mb-5">
                        <svg class="w-5 h-5 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z" />
                        </svg>
                        <h2 class="text-xl font-bold text-gray-800">Bộ lọc dữ liệu</h2>
                    </div>
                    
                    <form method="GET" class="space-y-4">
                        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                            <%
                                String reportType = request.getParameter("reportType");
                                if (reportType == null || reportType.isBlank())
                                    reportType = "borrowReport";
                                String monthFilter = request.getParameter("month");
                                String yearFilter = request.getParameter("year");
                            %>
                            
                            <div class="space-y-2">
                                <label for="reportType" class="block text-sm font-semibold text-gray-700">
                                    Loại báo cáo
                                </label>
                                <select class="filter-select w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-purple-400 focus:ring-4 focus:ring-purple-100 transition-all"
                                        name="reportType" id="reportType">
                                    <option value="borrowReport" <%= "borrowReport".equals(reportType) ? "selected" : ""%>>📚 Báo cáo mượn sách</option>
                                    <option value="fineReport" <%= "fineReport".equals(reportType) ? "selected" : ""%>>💰 Thống kê tiền phạt</option>
                                </select>
                            </div>

                            <div class="space-y-2">
                                <label for="month" class="block text-sm font-semibold text-gray-700">
                                    Tháng
                                </label>
                                <select class="filter-select w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-purple-400 focus:ring-4 focus:ring-purple-100 transition-all"
                                        name="month" id="month">
                                    <option value="">Tất cả tháng</option>
                                    <% for (int i = 1; i <= 12; i++) { %>
                                    <option value="<%= i%>" <%= monthFilter != null && monthFilter.equals(String.valueOf(i)) ? "selected" : ""%>>
                                        Tháng <%= i%>
                                    </option>
                                    <% } %>
                                </select>
                            </div>

                            <div class="space-y-2">
                                <label for="year" class="block text-sm font-semibold text-gray-700">
                                    Năm
                                </label>
                                <select class="filter-select w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-purple-400 focus:ring-4 focus:ring-purple-100 transition-all"
                                        name="year" id="year">
                                    <option value="">Tất cả năm</option>
                                    <%
                                        try (Connection connYear = DBConnection.getConnection(); 
                                             PreparedStatement stmtYear = (connYear != null)
                                                ? connYear.prepareStatement("SELECT DISTINCT YEAR(borrowed_date) AS y FROM borrow ORDER BY y DESC")
                                                : null; 
                                             ResultSet rsYear = (stmtYear != null ? stmtYear.executeQuery() : null)) {
                                            if (rsYear != null) {
                                                while (rsYear.next()) {
                                                    int y = rsYear.getInt("y");
                                    %>
                                    <option value="<%= y%>" <%= yearFilter != null && yearFilter.equals(String.valueOf(y)) ? "selected" : ""%>><%= y%></option>
                                    <%
                                                }
                                            } else {
                                                for (int y = java.time.Year.now().getValue(); y >= java.time.Year.now().getValue() - 5; y--) {
                                    %>
                                    <option value="<%= y%>" <%= yearFilter != null && yearFilter.equals(String.valueOf(y)) ? "selected" : ""%>><%= y%></option>
                                    <%
                                                }
                                            }
                                        } catch (Exception e) {
                                    %>
                                    <option disabled>Không tải được danh sách năm</option>
                                    <%
                                        }
                                    %>
                                </select>
                            </div>

                            <div class="space-y-2">
                                <label class="block text-sm font-semibold text-gray-700 opacity-0">
                                    Actions
                                </label>
                                <div class="flex gap-2">
                                    <button type="submit"
                                            class="flex-1 inline-flex items-center justify-center gap-2 px-4 py-3 rounded-xl gradient-bg text-white font-semibold hover:shadow-lg transform hover:scale-105 transition-all">
                                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                                        </svg>
                                        Xem
                                    </button>
                                    <a href="<%= request.getContextPath()%>/ExportReportExcelServlet?reportType=<%= reportType%>&month=<%= monthFilter == null ? "" : monthFilter%>&year=<%= yearFilter == null ? "" : yearFilter%>"
                                       class="inline-flex items-center justify-center px-4 py-3 rounded-xl bg-emerald-500 text-white font-semibold hover:bg-emerald-600 hover:shadow-lg transform hover:scale-105 transition-all">
                                        <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                                            <path d="M12 16l4-5h-3V4h-2v7H8z"></path>
                                            <path d="M20 18H4v-2h16v2z"></path>
                                        </svg>
                                    </a>
                                </div>
                            </div>
                        </div>
                    </form>
                </div>

                <%-- ====== Xử lý dữ liệu ====== --%>
                <%
                    List<String> labelsMonthly = new ArrayList<>();
                    List<Integer> seriesMonthly = new ArrayList<>();
                    List<String> topTitles = new ArrayList<>();
                    List<Integer> topCounts = new ArrayList<>();
                    List<String> fineUsers = new ArrayList<>();
                    List<Integer> fineTotals = new ArrayList<>();
                    
                    class Row {
                        int month;
                        int year;
                        String titleOrUser;
                        int countOrAmount;
                    }
                    List<Row> tableRows = new ArrayList<>();
                    int tableTotal = 0;

                    if ("fineReport".equals(reportType)) {
                        // Chart: tổng tiền phạt theo tháng
                        String sqlFineMonthly = "SELECT YEAR(borrowed_date) AS y, MONTH(borrowed_date) AS m, SUM(fine_amount) AS totalFine "
                                + "FROM borrow WHERE fine_amount > 0 "
                                + (monthFilter != null && !monthFilter.isEmpty() ? " AND MONTH(borrowed_date)=? " : "")
                                + (yearFilter != null && !yearFilter.isEmpty() ? " AND YEAR(borrowed_date)=? " : "")
                                + "GROUP BY YEAR(borrowed_date), MONTH(borrowed_date) ORDER BY y ASC, m ASC";

                        try (Connection c = DBConnection.getConnection(); 
                             PreparedStatement ps = (c != null ? c.prepareStatement(sqlFineMonthly) : null)) {
                            if (ps != null) {
                                int idx = 1;
                                if (monthFilter != null && !monthFilter.isEmpty()) ps.setInt(idx++, Integer.parseInt(monthFilter));
                                if (yearFilter != null && !yearFilter.isEmpty()) ps.setInt(idx++, Integer.parseInt(yearFilter));
                                try (ResultSet rs = ps.executeQuery()) {
                                    while (rs.next()) {
                                        labelsMonthly.add(String.format("%02d/%d", rs.getInt("m"), rs.getInt("y")));
                                        seriesMonthly.add(rs.getInt("totalFine"));
                                    }
                                }
                            }
                        } catch (SQLException e) {
                            out.println("<div class='text-red-600'>Lỗi: " + e.getMessage() + "</div>");
                        }

                        // Top users phạt
                        String sqlFineTopUsers = "SELECT u.username AS userName, SUM(b.fine_amount) AS totalFine "
                                + "FROM borrow b JOIN users u ON b.user_id = u.id WHERE b.fine_amount > 0 "
                                + (monthFilter != null && !monthFilter.isEmpty() ? " AND MONTH(b.borrowed_date)=? " : "")
                                + (yearFilter != null && !yearFilter.isEmpty() ? " AND YEAR(b.borrowed_date)=? " : "")
                                + "GROUP BY u.username ORDER BY totalFine DESC LIMIT 10";

                        try (Connection c = DBConnection.getConnection();
                             PreparedStatement ps = (c != null ? c.prepareStatement(sqlFineTopUsers) : null)) {
                            if (ps != null) {
                                int idx = 1;
                                if (monthFilter != null && !monthFilter.isEmpty()) ps.setInt(idx++, Integer.parseInt(monthFilter));
                                if (yearFilter != null && !yearFilter.isEmpty()) ps.setInt(idx++, Integer.parseInt(yearFilter));
                                try (ResultSet rs = ps.executeQuery()) {
                                    while (rs.next()) {
                                        fineUsers.add(rs.getString("userName"));
                                        fineTotals.add(rs.getInt("totalFine"));
                                    }
                                }
                            }
                        } catch (SQLException e) {
                            out.println("<div class='text-red-600'>Lỗi: " + e.getMessage() + "</div>");
                        }

                        // Bảng chi tiết
                        StringBuilder sb = new StringBuilder(
                                "SELECT MONTH(borrowed_date) AS month, YEAR(borrowed_date) AS year, users.username AS userName, SUM(fine_amount) AS totalFine "
                                + "FROM borrow JOIN users ON borrow.user_id = users.id WHERE fine_amount > 0"
                        );
                        List<Integer> params = new ArrayList<>();
                        if (monthFilter != null && !monthFilter.isEmpty()) {
                            sb.append(" AND MONTH(borrowed_date)=?");
                            params.add(Integer.parseInt(monthFilter));
                        }
                        if (yearFilter != null && !yearFilter.isEmpty()) {
                            sb.append(" AND YEAR(borrowed_date)=?");
                            params.add(Integer.parseInt(yearFilter));
                        }
                        sb.append(" GROUP BY YEAR(borrowed_date), MONTH(borrowed_date), users.username ORDER BY year DESC, month ASC");

                        try (Connection c = DBConnection.getConnection(); 
                             PreparedStatement ps = (c != null ? c.prepareStatement(sb.toString()) : null)) {
                            if (ps != null) {
                                for (int i = 0; i < params.size(); i++) ps.setInt(i + 1, params.get(i));
                                try (ResultSet rs = ps.executeQuery()) {
                                    while (rs.next()) {
                                        Row r = new Row();
                                        r.month = rs.getInt("month");
                                        r.year = rs.getInt("year");
                                        r.titleOrUser = rs.getString("userName");
                                        r.countOrAmount = rs.getInt("totalFine");
                                        tableRows.add(r);
                                        tableTotal += r.countOrAmount;
                                    }
                                }
                            }
                        } catch (SQLException e) {
                            out.println("<div class='text-red-600'>Lỗi: " + e.getMessage() + "</div>");
                        }

                    } else { // borrowReport
                        // Chart theo tháng
                        String sqlBorrowMonthly = "SELECT YEAR(borrowed_date) AS y, MONTH(borrowed_date) AS m, COUNT(*) AS cnt "
                                + "FROM borrow JOIN bookitem ON borrow.book_item_id = bookitem.book_item_id "
                                + "JOIN book ON bookitem.book_isbn = book.isbn WHERE 1=1 "
                                + (monthFilter != null && !monthFilter.isEmpty() ? " AND MONTH(borrowed_date)=? " : "")
                                + (yearFilter != null && !yearFilter.isEmpty() ? " AND YEAR(borrowed_date)=? " : "")
                                + "GROUP BY YEAR(borrowed_date), MONTH(borrowed_date) ORDER BY y ASC, m ASC";

                        try (Connection c = DBConnection.getConnection(); 
                             PreparedStatement ps = (c != null ? c.prepareStatement(sqlBorrowMonthly) : null)) {
                            if (ps != null) {
                                int idx = 1;
                                if (monthFilter != null && !monthFilter.isEmpty()) ps.setInt(idx++, Integer.parseInt(monthFilter));
                                if (yearFilter != null && !yearFilter.isEmpty()) ps.setInt(idx++, Integer.parseInt(yearFilter));
                                try (ResultSet rs = ps.executeQuery()) {
                                    while (rs.next()) {
                                        labelsMonthly.add(String.format("%02d/%d", rs.getInt("m"), rs.getInt("y")));
                                        seriesMonthly.add(rs.getInt("cnt"));
                                    }
                                }
                            }
                        } catch (SQLException e) {
                            out.println("<div class='text-red-600'>Lỗi: " + e.getMessage() + "</div>");
                        }

                        // Top 10 sách
                        String sqlTop = "SELECT book.title, COUNT(*) AS cnt "
                                + "FROM borrow JOIN bookitem ON borrow.book_item_id = bookitem.book_item_id "
                                + "JOIN book ON bookitem.book_isbn = book.isbn WHERE 1=1 "
                                + (monthFilter != null && !monthFilter.isEmpty() ? " AND MONTH(borrowed_date)=? " : "")
                                + (yearFilter != null && !yearFilter.isEmpty() ? " AND YEAR(borrowed_date)=? " : "")
                                + "GROUP BY book.title ORDER BY cnt DESC LIMIT 10";

                        try (Connection c = DBConnection.getConnection(); 
                             PreparedStatement ps = (c != null ? c.prepareStatement(sqlTop) : null)) {
                            if (ps != null) {
                                int idx = 1;
                                if (monthFilter != null && !monthFilter.isEmpty()) ps.setInt(idx++, Integer.parseInt(monthFilter));
                                if (yearFilter != null && !yearFilter.isEmpty()) ps.setInt(idx++, Integer.parseInt(yearFilter));
                                try (ResultSet rs = ps.executeQuery()) {
                                    while (rs.next()) {
                                        topTitles.add(rs.getString("title"));
                                        topCounts.add(rs.getInt("cnt"));
                                    }
                                }
                            }
                        } catch (SQLException e) {
                            out.println("<div class='text-red-600'>Lỗi: " + e.getMessage() + "</div>");
                        }

                        // Bảng chi tiết
                        StringBuilder sb = new StringBuilder(
                                "SELECT MONTH(borrowed_date) AS month, YEAR(borrowed_date) AS year, book.title, COUNT(*) AS count "
                                + "FROM borrow JOIN bookitem ON borrow.book_item_id = bookitem.book_item_id "
                                + "JOIN book ON bookitem.book_isbn = book.isbn WHERE 1=1"
                        );
                        List<Integer> params = new ArrayList<>();
                        if (monthFilter != null && !monthFilter.isEmpty()) {
                            sb.append(" AND MONTH(borrowed_date)=?");
                            params.add(Integer.parseInt(monthFilter));
                        }
                        if (yearFilter != null && !yearFilter.isEmpty()) {
                            sb.append(" AND YEAR(borrowed_date)=?");
                            params.add(Integer.parseInt(yearFilter));
                        }
                        sb.append(" GROUP BY YEAR(borrowed_date), MONTH(borrowed_date), book.title ORDER BY year DESC, month ASC");

                        try (Connection c = DBConnection.getConnection(); 
                             PreparedStatement ps = (c != null ? c.prepareStatement(sb.toString()) : null)) {
                            if (ps != null) {
                                for (int i = 0; i < params.size(); i++) ps.setInt(i + 1, params.get(i));
                                try (ResultSet rs = ps.executeQuery()) {
                                    while (rs.next()) {
                                        Row r = new Row();
                                        r.month = rs.getInt("month");
                                        r.year = rs.getInt("year");
                                        r.titleOrUser = rs.getString("title");
                                        r.countOrAmount = rs.getInt("count");
                                        tableRows.add(r);
                                        tableTotal += r.countOrAmount;
                                    }
                                }
                            }
                        } catch (SQLException e) {
                            out.println("<div class='text-red-600'>Lỗi: " + e.getMessage() + "</div>");
                        }
                    }
                %>
                <%
                    // ==== Phân trang cho bảng chi tiết ====
                    int pageSize = parseIntOrDefault(request.getParameter("pageSize"), 20);
                    if (pageSize <= 0) pageSize = 20;        // chống lỗi
                    int totalRows = tableRows.size();
                    int totalPages = Math.max(1, (int) Math.ceil(totalRows / (double) pageSize));

                    int currentPage = parseIntOrDefault(request.getParameter("page"), 1);
                    if (currentPage < 1) currentPage = 1;
                    if (currentPage > totalPages) currentPage = totalPages;

                    int fromIndex = (currentPage - 1) * pageSize;
                    int toIndex = Math.min(fromIndex + pageSize, totalRows);

                    List<Row> pagedRows = (fromIndex < toIndex) ? tableRows.subList(fromIndex, toIndex) : new ArrayList<>();

                    // Tạo base URL giữ nguyên bộ lọc + pageSize (để gắn vào các nút trang)
                    StringBuilder baseUrlSb = new StringBuilder();
                    baseUrlSb.append(request.getRequestURI()).append("?")
                             .append("reportType=").append(URLEncoder.encode(reportType, "UTF-8"))
                             .append("&month=").append(monthFilter == null ? "" : URLEncoder.encode(monthFilter, "UTF-8"))
                             .append("&year=").append(yearFilter == null ? "" : URLEncoder.encode(yearFilter, "UTF-8"))
                             .append("&pageSize=").append(pageSize)
                             .append("&page=");
                    String baseUrl = baseUrlSb.toString();

                    // Tính cửa sổ trang hiển thị (ví dụ 7 nút)
                    int window = 7;
                    int half = window / 2;
                    int start = Math.max(1, currentPage - half);
                    int end = Math.min(totalPages, start + window - 1);
                    if (end - start + 1 < window) {
                        start = Math.max(1, end - window + 1);
                    }
                %>

                <%-- ====== Biểu đồ ====== --%>
                <% if ("fineReport".equals(reportType)) { %>
                    <div class="grid grid-cols-1 xl:grid-cols-3 gap-6 mb-8">
                        <!-- Chart chính: Tiền phạt theo tháng -->
                        <div class="xl:col-span-2 glass-card rounded-3xl shadow-xl p-6 chart-card animate-fade-in">
                            <div class="flex items-center justify-between mb-6">
                                <div class="flex items-center gap-3">
                                    <div class="w-10 h-10 rounded-xl gradient-bg-alt flex items-center justify-center">
                                        <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                                        </svg>
                                    </div>
                                    <div>
                                        <h3 class="text-lg font-bold text-gray-800">Tiền phạt theo tháng</h3>
                                        <p class="text-sm text-gray-500">Biểu đồ cột</p>
                                    </div>
                                </div>
                                <span class="stat-badge text-white text-xs font-semibold px-3 py-1.5 rounded-full">VNĐ</span>
                            </div>
                            <div class="h-80">
                                <canvas id="fineMonthlyChart"></canvas>
                            </div>
                        </div>

                        <!-- Pie chart: Top users -->
                        <div class="glass-card rounded-3xl shadow-xl p-6 chart-card animate-fade-in">
                            <div class="flex items-center justify-between mb-6">
                                <div class="flex items-center gap-3">
                                    <div class="w-10 h-10 rounded-xl gradient-bg flex items-center justify-center">
                                        <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 3.055A9.001 9.001 0 1020.945 13H11V3.055z" />
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.488 9H15V3.512A9.025 9.025 0 0120.488 9z" />
                                        </svg>
                                    </div>
                                    <div>
                                        <h3 class="text-lg font-bold text-gray-800">Top 10 Users</h3>
                                        <p class="text-sm text-gray-500">Tỷ trọng phạt</p>
                                    </div>
                                </div>
                            </div>
                            <div class="h-80">
                                <canvas id="fineUserPie"></canvas>
                            </div>
                        </div>
                    </div>
                <% } else { %>
                    <div class="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6 mb-8">
                        <!-- Chart chính: Mượn theo tháng -->
                        <div class="xl:col-span-2 glass-card rounded-3xl shadow-xl p-6 chart-card animate-fade-in">
                            <div class="flex items-center justify-between mb-6">
                                <div class="flex items-center gap-3">
                                    <div class="w-10 h-10 rounded-xl gradient-bg flex items-center justify-center">
                                        <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 12l3-3 3 3 4-4M8 21l4-4 4 4M3 4h18M4 4h16v12a1 1 0 01-1 1H5a1 1 0 01-1-1V4z" />
                                        </svg>
                                    </div>
                                    <div>
                                        <h3 class="text-lg font-bold text-gray-800">Lượt mượn theo tháng</h3>
                                        <p class="text-sm text-gray-500">Biểu đồ đường</p>
                                    </div>
                                </div>
                                <span class="stat-badge text-white text-xs font-semibold px-3 py-1.5 rounded-full">Lượt</span>
                            </div>
                            <div class="h-80">
                                <canvas id="borrowMonthlyChart"></canvas>
                            </div>
                        </div>

                        <!-- Top 10 sách (Bar ngang) -->
                        <div class="glass-card rounded-3xl shadow-xl p-6 chart-card animate-fade-in">
                            <div class="flex items-center justify-between mb-6">
                                <div class="flex items-center gap-3">
                                    <div class="w-10 h-10 rounded-xl gradient-bg-alt flex items-center justify-center">
                                        <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                                        </svg>
                                    </div>
                                    <div>
                                        <h3 class="text-lg font-bold text-gray-800">Top 10 Sách</h3>
                                        <p class="text-sm text-gray-500">Mượn nhiều nhất</p>
                                    </div>
                                </div>
                            </div>
                            <div class="h-80">
                                <canvas id="borrowTopChart"></canvas>
                            </div>
                        </div>

                        <!-- Pie chart: Top 10 -->
                        <div class="glass-card rounded-3xl shadow-xl p-6 chart-card animate-fade-in lg:col-span-2 xl:col-span-1">
                            <div class="flex items-center justify-between mb-6">
                                <div class="flex items-center gap-3">
                                    <div class="w-10 h-10 rounded-xl gradient-bg flex items-center justify-center">
                                        <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 3.055A9.001 9.001 0 1020.945 13H11V3.055z" />
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.488 9H15V3.512A9.025 9.025 0 0120.488 9z" />
                                        </svg>
                                    </div>
                                    <div>
                                        <h3 class="text-lg font-bold text-gray-800">Tỷ trọng Top 10</h3>
                                        <p class="text-sm text-gray-500">Biểu đồ tròn</p>
                                    </div>
                                </div>
                            </div>
                            <div class="h-80">
                                <canvas id="borrowTopPie"></canvas>
                            </div>
                        </div>
                    </div>
                <% } %>

                <%-- ====== Bảng chi tiết ====== --%>
                <div class="glass-card rounded-3xl shadow-xl overflow-hidden animate-fade-in">
                    <div class="px-6 py-5 border-b border-gray-200 bg-gradient-to-r from-purple-50 to-blue-50">
                        <div class="flex items-center justify-between">
                            <div class="flex items-center gap-3">
                                <div class="w-10 h-10 rounded-xl gradient-bg flex items-center justify-center">
                                    <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                                    </svg>
                                </div>
                                <div>
                                    <h3 class="text-xl font-bold text-gray-800">
                                        <%= "fineReport".equals(reportType) ? "Chi tiết tiền phạt" : "Chi tiết mượn sách"%>
                                    </h3>
                                    <p class="text-sm text-gray-600 mt-0.5">Dữ liệu theo bộ lọc đã chọn</p>
                                </div>
                            </div>
                            <div class="text-right">
                                <p class="text-sm text-gray-600">Tổng cộng</p>
                                <p class="text-2xl font-bold text-purple-600">
                                    <%= tableTotal%><%= "fineReport".equals(reportType) ? " VNĐ" : " lượt"%>
                                </p>
                            </div>
                        </div>
                    </div>
                    
                    <div class="overflow-x-auto">
                        <table class="w-full">
                            <thead class="bg-gray-50">
                                <tr>
                                    <th class="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider">
                                        Tháng
                                    </th>
                                    <th class="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider">
                                        Năm
                                    </th>
                                    <th class="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider">
                                        <%= "fineReport".equals(reportType) ? "Người dùng" : "Tên sách"%>
                                    </th>
                                    <th class="px-6 py-4 text-right text-xs font-bold text-gray-700 uppercase tracking-wider">
                                        <%= "fineReport".equals(reportType) ? "Tiền phạt" : "Số lượt"%>
                                    </th>
                                </tr>
                            </thead>
                            <tbody class="bg-white divide-y divide-gray-100">
                                <%
                                    if (tableRows.isEmpty()) {
                                %>
                                <tr>
                                    <td colspan="4" class="px-6 py-12 text-center">
                                        <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
                                        </svg>
                                        <p class="mt-4 text-gray-500 font-medium">Không có dữ liệu phù hợp</p>
                                        <p class="text-sm text-gray-400">Thử thay đổi bộ lọc để xem kết quả khác</p>
                                    </td>
                                </tr>
                                <% } else {
                                        for (int i = 0; i < pagedRows.size(); i++) {
                                            Row r = pagedRows.get(i);
                                            String rowClass = (i % 2 == 0) ? "bg-white" : "bg-gray-50";
                                 %>
                                     <tr class="<%= rowClass %> hover:bg-purple-50 transition-colors">
                                         <td class="px-6 py-4 whitespace-nowrap">
                                             <span class="inline-flex items-center px-2.5 py-1 rounded-lg bg-blue-100 text-blue-800 text-sm font-medium">
                                                 <%= r.month %>
                                             </span>
                                         </td>
                                         <td class="px-6 py-4 whitespace-nowrap">
                                             <span class="inline-flex items-center px-2.5 py-1 rounded-lg bg-purple-100 text-purple-800 text-sm font-medium">
                                                 <%= r.year %>
                                             </span>
                                         </td>
                                         <td class="px-6 py-4 text-sm text-gray-900 font-medium"><%= r.titleOrUser %></td>
                                         <td class="px-6 py-4 whitespace-nowrap text-right">
                                             <span class="text-base font-bold text-gray-900">
                                                 <%= String.format("%,d", r.countOrAmount) %><%= "fineReport".equals(reportType) ? " ₫" : "" %>
                                             </span>
                                         </td>
                                     </tr>
                                <%
                                        }
                                    }
                                %>
                            </tbody>
                            <% if (!tableRows.isEmpty()) { %>
                            <tfoot class="bg-gradient-to-r from-purple-50 to-blue-50">
                                <tr>
                                    <td colspan="3" class="px-6 py-4 text-right text-base font-bold text-gray-900">
                                        Tổng cộng:
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap text-right">
                                        <span class="text-xl font-bold text-purple-600">
                                            <%= String.format("%,d", tableTotal)%><%= "fineReport".equals(reportType) ? " ₫" : " lượt"%>
                                        </span>
                                    </td>
                                </tr>
                            </tfoot>
                            <% } %>
                        </table>
                        <div class="px-6 py-4 flex flex-col md:flex-row md:items-center md:justify-between gap-3">
                        <!-- Info -->
                        <div class="text-sm text-gray-600">
                          Hiển thị
                          <span class="font-semibold text-gray-900"><%= totalRows == 0 ? 0 : (fromIndex + 1) %></span>
                          –
                          <span class="font-semibold text-gray-900"><%= toIndex %></span>
                          trên
                          <span class="font-semibold text-gray-900"><%= totalRows %></span>
                          dòng • Trang
                          <span class="font-semibold text-gray-900"><%= currentPage %> / <%= totalPages %></span>
                        </div>

                        <!-- Page size selector -->
                        <form method="GET" class="flex items-center gap-2">
                          <input type="hidden" name="reportType" value="<%= reportType %>"/>
                          <input type="hidden" name="month" value="<%= monthFilter == null ? "" : monthFilter %>"/>
                          <input type="hidden" name="year" value="<%= yearFilter == null ? "" : yearFilter %>"/>
                          <input type="hidden" name="page" value="1"/>
                          <label class="text-sm text-gray-600">Mỗi trang</label>
                          <select name="pageSize" class="px-3 py-2 rounded-lg border border-gray-300 focus:ring-2 focus:ring-purple-200">
                            <option value="10"  <%= pageSize==10  ? "selected":"" %>>10</option>
                            <option value="20"  <%= pageSize==20  ? "selected":"" %>>20</option>
                            <option value="50"  <%= pageSize==50  ? "selected":"" %>>50</option>
                            <option value="100" <%= pageSize==100 ? "selected":"" %>>100</option>
                          </select>
                          <button class="ml-2 inline-flex items-center px-3 py-2 rounded-lg bg-gray-800 text-white text-sm hover:bg-gray-700">
                            Áp dụng
                          </button>
                        </form>
                      </div>

                      <!-- Pagination buttons -->
                      <div class="px-6 pb-6">
                        <div class="flex flex-wrap items-center gap-2">
                          <!-- Prev -->
                          <a class="px-3 py-2 rounded-lg border text-sm
                                    <%= currentPage==1 ? "pointer-events-none text-gray-300 border-gray-200 bg-gray-50" : "text-gray-700 border-gray-300 hover:bg-gray-50" %>"
                             href="<%= currentPage==1 ? "#" : (baseUrl + (currentPage-1)) %>">« Trước</a>

                          <%-- Page numbers (window) --%>
                          <%
                            if (start > 1) {
                          %>
                            <a class="px-3 py-2 rounded-lg border text-sm text-gray-700 border-gray-300 hover:bg-gray-50"
                               href="<%= baseUrl + 1 %>">1</a>
                            <% if (start > 2) { %>
                              <span class="px-2 text-gray-400">…</span>
                            <% } %>
                          <%
                            }
                            for (int p = start; p <= end; p++) {
                              boolean active = (p == currentPage);
                          %>
                            <a class="px-3 py-2 rounded-lg border text-sm <%= active ? "bg-purple-600 text-white border-purple-600" : "text-gray-700 border-gray-300 hover:bg-gray-50" %>"
                               href="<%= active ? "#" : (baseUrl + p) %>"><%= p %></a>
                          <%
                            }
                            if (end < totalPages) {
                              if (end < totalPages - 1) {
                          %>
                            <span class="px-2 text-gray-400">…</span>
                          <%
                              }
                          %>
                            <a class="px-3 py-2 rounded-lg border text-sm text-gray-700 border-gray-300 hover:bg-gray-50"
                               href="<%= baseUrl + totalPages %>"><%= totalPages %></a>
                          <%
                            }
                          %>

                          <!-- Next -->
                          <a class="px-3 py-2 rounded-lg border text-sm
                                    <%= currentPage==totalPages ? "pointer-events-none text-gray-300 border-gray-200 bg-gray-50" : "text-gray-700 border-gray-300 hover:bg-gray-50" %>"
                             href="<%= currentPage==totalPages ? "#" : (baseUrl + (currentPage+1)) %>">Sau »</a>
                        </div>
                      </div>

                    </div>
                </div>

            </div>
        </main>

        <%-- ========= Scripts vẽ Chart ========= --%>
        <script>
            // Chart configuration
            Chart.defaults.font.family = 'Inter, sans-serif';
            Chart.defaults.color = '#6b7280';
            
            const gradientColors = {
                purple: ['rgba(102, 126, 234, 0.8)', 'rgba(118, 75, 162, 0.8)'],
                pink: ['rgba(240, 147, 251, 0.8)', 'rgba(245, 87, 108, 0.8)'],
                blue: ['rgba(59, 130, 246, 0.8)', 'rgba(147, 51, 234, 0.8)']
            };

            (function () {
                const monthlyLabels = <%= toJsonStringArray(labelsMonthly)%>;
                const monthlyData = <%= toJsonIntArray(seriesMonthly)%>;

            <% if ("fineReport".equals(reportType)) { %>
                // Fine Monthly Chart
                const ctxFine = document.getElementById('fineMonthlyChart');
                if (ctxFine) {
                    const gradient = ctxFine.getContext('2d').createLinearGradient(0, 0, 0, 400);
                    gradient.addColorStop(0, 'rgba(245, 87, 108, 0.8)');
                    gradient.addColorStop(1, 'rgba(240, 147, 251, 0.4)');
                    
                    new Chart(ctxFine, {
                        type: 'bar',
                        data: {
                            labels: monthlyLabels,
                            datasets: [{
                                label: 'Tổng tiền phạt (VNĐ)',
                                data: monthlyData,
                                backgroundColor: gradient,
                                borderColor: 'rgba(245, 87, 108, 1)',
                                borderWidth: 2,
                                borderRadius: 8,
                                hoverBackgroundColor: 'rgba(245, 87, 108, 1)'
                            }]
                        },
                        options: {
                            responsive: true,
                            maintainAspectRatio: false,
                            scales: {
                                y: {
                                    beginAtZero: true,
                                    grid: {color: 'rgba(0, 0, 0, 0.05)'},
                                    ticks: {
                                        callback: function(value) {
                                            return value.toLocaleString() + ' ₫';
                                        }
                                    }
                                },
                                x: {grid: {display: false}}
                            },
                            plugins: {
                                legend: {
                                    display: false
                                },
                                tooltip: {
                                    backgroundColor: 'rgba(0, 0, 0, 0.8)',
                                    padding: 12,
                                    borderRadius: 8,
                                    callbacks: {
                                        label: function(context) {
                                            return context.parsed.y.toLocaleString() + ' VNĐ';
                                        }
                                    }
                                }
                            }
                        }
                    });
                }

                // Fine User Pie
                const fineUserLabels = <%= toJsonStringArray(fineUsers) %>;
                const fineUserData = <%= toJsonIntArray(fineTotals) %>;
                const ctxFinePie = document.getElementById('fineUserPie');
                if (ctxFinePie) {
                    new Chart(ctxFinePie, {
                        type: 'doughnut',
                        data: {
                            labels: fineUserLabels,
                            datasets: [{
                                data: fineUserData,
                                backgroundColor: [
                                    'rgba(102, 126, 234, 0.8)',
                                    'rgba(118, 75, 162, 0.8)',
                                    'rgba(245, 87, 108, 0.8)',
                                    'rgba(240, 147, 251, 0.8)',
                                    'rgba(59, 130, 246, 0.8)',
                                    'rgba(16, 185, 129, 0.8)',
                                    'rgba(251, 191, 36, 0.8)',
                                    'rgba(239, 68, 68, 0.8)',
                                    'rgba(168, 85, 247, 0.8)',
                                    'rgba(236, 72, 153, 0.8)'
                                ],
                                borderWidth: 2,
                                borderColor: '#fff'
                            }]
                        },
                        options: {
                            responsive: true,
                            maintainAspectRatio: false,
                            plugins: {
                                legend: {
                                    position: 'bottom',
                                    labels: {
                                        padding: 15,
                                        usePointStyle: true,
                                        font: {size: 11}
                                    }
                                },
                                tooltip: {
                                    backgroundColor: 'rgba(0, 0, 0, 0.8)',
                                    padding: 12,
                                    borderRadius: 8,
                                    callbacks: {
                                        label: function(context) {
                                            const total = context.dataset.data.reduce((a, b) => a + b, 0);
                                            const percentage = ((context.parsed / total) * 100).toFixed(1);
                                            return context.label + ': ' + context.parsed.toLocaleString() + ' ₫ (' + percentage + '%)';
                                        }
                                    }
                                }
                            }
                        }
                    });
                }

            <% } else { %>
                // Borrow Monthly Chart
                const ctxBorrowM = document.getElementById('borrowMonthlyChart');
                if (ctxBorrowM) {
                    const gradient = ctxBorrowM.getContext('2d').createLinearGradient(0, 0, 0, 400);
                    gradient.addColorStop(0, 'rgba(102, 126, 234, 0.3)');
                    gradient.addColorStop(1, 'rgba(118, 75, 162, 0.05)');
                    
                    new Chart(ctxBorrowM, {
                        type: 'line',
                        data: {
                            labels: monthlyLabels,
                            datasets: [{
                                label: 'Số lượt mượn',
                                data: monthlyData,
                                borderColor: 'rgba(102, 126, 234, 1)',
                                backgroundColor: gradient,
                                borderWidth: 3,
                                fill: true,
                                tension: 0.4,
                                pointRadius: 5,
                                pointBackgroundColor: 'rgba(102, 126, 234, 1)',
                                pointBorderColor: '#fff',
                                pointBorderWidth: 2,
                                pointHoverRadius: 7
                            }]
                        },
                        options: {
                            responsive: true,
                            maintainAspectRatio: false,
                            scales: {
                                y: {
                                    beginAtZero: true,
                                    grid: {color: 'rgba(0, 0, 0, 0.05)'}
                                },
                                x: {grid: {display: false}}
                            },
                            plugins: {
                                legend: {display: false},
                                tooltip: {
                                    backgroundColor: 'rgba(0, 0, 0, 0.8)',
                                    padding: 12,
                                    borderRadius: 8
                                }
                            }
                        }
                    });
                }

                // Borrow Top 10 Chart
                const topTitles = <%= toJsonStringArray(topTitles)%>;
                const topCounts = <%= toJsonIntArray(topCounts)%>;
                const ctxBorrowTop = document.getElementById('borrowTopChart');
                if (ctxBorrowTop) {
                    const gradient = ctxBorrowTop.getContext('2d').createLinearGradient(0, 0, 400, 0);
                    gradient.addColorStop(0, 'rgba(240, 147, 251, 0.8)');
                    gradient.addColorStop(1, 'rgba(245, 87, 108, 0.8)');
                    
                    new Chart(ctxBorrowTop, {
                        type: 'bar',
                        data: {
                            labels: topTitles,
                            datasets: [{
                                label: 'Số lượt mượn',
                                data: topCounts,
                                backgroundColor: gradient,
                                borderColor: 'rgba(245, 87, 108, 1)',
                                borderWidth: 2,
                                borderRadius: 8
                            }]
                        },
                        options: {
                            indexAxis: 'y',
                            responsive: true,
                            maintainAspectRatio: false,
                            scales: {
                                x: {
                                    beginAtZero: true,
                                    grid: {color: 'rgba(0, 0, 0, 0.05)'}
                                },
                                y: {
                                    grid: {display: false},
                                    ticks: {
                                        callback: function(value, index) {
                                            const label = this.getLabelForValue(value);
                                            return label.length > 30 ? label.substring(0, 30) + '...' : label;
                                        }
                                    }
                                }
                            },
                            plugins: {
                                legend: {display: false},
                                tooltip: {
                                    backgroundColor: 'rgba(0, 0, 0, 0.8)',
                                    padding: 12,
                                    borderRadius: 8
                                }
                            }
                        }
                    });
                }

                // Borrow Top Pie
                const ctxBorrowPie = document.getElementById('borrowTopPie');
                if (ctxBorrowPie) {
                    new Chart(ctxBorrowPie, {
                        type: 'doughnut',
                        data: {
                            labels: topTitles,
                            datasets: [{
                                data: topCounts,
                                backgroundColor: [
                                    'rgba(102, 126, 234, 0.8)',
                                    'rgba(118, 75, 162, 0.8)',
                                    'rgba(245, 87, 108, 0.8)',
                                    'rgba(240, 147, 251, 0.8)',
                                    'rgba(59, 130, 246, 0.8)',
                                    'rgba(16, 185, 129, 0.8)',
                                    'rgba(251, 191, 36, 0.8)',
                                    'rgba(239, 68, 68, 0.8)',
                                    'rgba(168, 85, 247, 0.8)',
                                    'rgba(236, 72, 153, 0.8)'
                                ],
                                borderWidth: 2,
                                borderColor: '#fff'
                            }]
                        },
                        options: {
                            responsive: true,
                            maintainAspectRatio: false,
                            plugins: {
                                legend: {
                                    position: 'bottom',
                                    labels: {
                                        padding: 15,
                                        usePointStyle: true,
                                        font: {size: 11},
                                        generateLabels: function(chart) {
                                            const data = chart.data;
                                            if (data.labels.length && data.datasets.length) {
                                                return data.labels.map((label, i) => {
                                                    const shortLabel = label.length > 20 ? label.substring(0, 20) + '...' : label;
                                                    return {
                                                        text: shortLabel,
                                                        fillStyle: data.datasets[0].backgroundColor[i],
                                                        hidden: false,
                                                        index: i
                                                    };
                                                });
                                            }
                                            return [];
                                        }
                                    }
                                },
                                tooltip: {
                                    backgroundColor: 'rgba(0, 0, 0, 0.8)',
                                    padding: 12,
                                    borderRadius: 8,
                                    callbacks: {
                                        label: function(context) {
                                            const total = context.dataset.data.reduce((a, b) => a + b, 0);
                                            const percentage = ((context.parsed / total) * 100).toFixed(1);
                                            return context.label + ': ' + context.parsed + ' lượt (' + percentage + '%)';
                                        }
                                    }
                                }
                            }
                        }
                    });
                }
            <% } %>
            })();
        </script>
    </body>
</html>