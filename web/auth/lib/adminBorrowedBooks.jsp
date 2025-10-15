<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.text.SimpleDateFormat, Servlet.DBConnection" %>
<%@ page import="jakarta.servlet.http.HttpSession" %>
<%@ page import="Data.Users" %>
<%
    SimpleDateFormat dateFormat = new SimpleDateFormat("dd/MM/yyyy");
    SimpleDateFormat inputDateFormat = new SimpleDateFormat("yyyy-MM-dd");
%>
<%
    request.setAttribute("pageTitle", "Quản lý sách - Admin");
%>
<style>
/* Custom Pagination Styles */
.pagination-btn {
    transition: all 0.2s ease-in-out;
    user-select: none;
}

.pagination-btn:hover:not(:disabled) {
    transform: translateY(-1px);
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.pagination-btn:active:not(:disabled) {
    transform: translateY(0);
}

.page-number-btn {
    min-width: 40px;
    height: 40px;
    display: flex;
    align-items: center;
    justify-content: center;
    border: 1px solid #d1d5db;
    background: white;
    color: #6b7280;
    font-weight: 500;
    transition: all 0.2s ease-in-out;
    cursor: pointer;
}

.page-number-btn:hover {
    background: #f3f4f6;
    color: #374151;
    transform: translateY(-1px);
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.page-number-btn.active {
    background: linear-gradient(135deg, #3b82f6, #2563eb);
    color: white;
    border-color: #2563eb;
    box-shadow: 0 2px 8px rgba(59, 130, 246, 0.3);
    transform: translateY(-1px);
}

.page-number-btn.dots {
    cursor: default;
    background: transparent;
    border: none;
    color: #9ca3af;
}

.page-number-btn.dots:hover {
    background: transparent;
    transform: none;
    box-shadow: none;
}

/* Responsive design */
@media (max-width: 640px) {
    .pagination-btn {
        padding: 8px 12px;
        font-size: 12px;
    }
    
    .page-number-btn {
        min-width: 36px;
        height: 36px;
        font-size: 14px;
    }
}

/* Loading animation for page transitions */
.pagination-loading {
    opacity: 0.6;
    pointer-events: none;
}

.pagination-loading::after {
    content: '';
    position: absolute;
    top: 50%;
    left: 50%;
    width: 20px;
    height: 20px;
    margin: -10px 0 0 -10px;
    border: 2px solid #f3f3f3;
    border-top: 2px solid #3b82f6;
    border-radius: 50%;
    animation: spin 1s linear infinite;
}

@keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
}
</style>
<%@ include file="../includes/header.jsp" %>
<main class="transition-all duration-300 pt-32" id="mainContent">
    <div class="min-h-screen bg-gray-50 p-6">
        <div class="max-w-7xl mx-auto">
            <!-- Header with Search -->
            <div class="mb-8">
                <div class="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
                    <div>
                        <h1 class="text-3xl font-bold text-gray-900 mb-2">Quản lý Mượn/Trả Sách</h1>
                        <p class="text-gray-600">Theo dõi và quản lý tình trạng mượn/trả sách của người dùng</p>
                    </div>

                    <!-- Search Box moved to header -->
                    <div class="lg:max-w-md w-full lg:w-80">
                        <label for="searchInput" class="block text-sm font-medium text-gray-700 mb-2">
                            Tìm kiếm
                        </label>
                        <div class="relative">
                            <input type="text" 
                                   id="searchInput" 
                                   placeholder="Tìm theo tên người dùng hoặc tên sách..."
                                   class="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition duration-200">
                            <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                <svg class="h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
                                </svg>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Enhanced Filter Section -->
            <div class="bg-white rounded-xl shadow-lg p-6 mb-6 border border-gray-100">
                <!-- Date Filters -->
                <div class="mb-6">
                    <h4 class="text-sm font-medium text-gray-700 mb-3 flex items-center">
                        <svg class="w-4 h-4 mr-1 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
                        </svg>
                        Lọc theo ngày
                    </h4>
                    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                        <!-- Borrowed Date Filter -->
                        <div class="space-y-2">
                            <label class="block text-sm font-medium text-gray-700">Ngày mượn từ</label>
                            <div class="relative">
                                <input type="date" 
                                       id="borrowedDateFrom" 
                                       class="w-full px-3 py-2.5 border border-gray-300 rounded-lg shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition duration-200 bg-white">
                            </div>
                        </div>
                        <div class="space-y-2">
                            <label class="block text-sm font-medium text-gray-700">Ngày mượn đến</label>
                            <div class="relative">
                                <input type="date" 
                                       id="borrowedDateTo" 
                                       class="w-full px-3 py-2.5 border border-gray-300 rounded-lg shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition duration-200 bg-white">
                            </div>
                        </div>

                        <!-- Due Date Filter -->
                        <div class="space-y-2">
                            <label class="block text-sm font-medium text-gray-700">Hạn trả từ</label>
                            <div class="relative">
                                <input type="date" 
                                       id="dueDateFrom" 
                                       class="w-full px-3 py-2.5 border border-gray-300 rounded-lg shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition duration-200 bg-white">
                            </div>
                        </div>
                        <div class="space-y-2">
                            <label class="block text-sm font-medium text-gray-700">Hạn trả đến</label>
                            <div class="relative">
                                <input type="date" 
                                       id="dueDateTo" 
                                       class="w-full px-3 py-2.5 border border-gray-300 rounded-lg shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition duration-200 bg-white">
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Status Filter and Action Buttons -->
                <div class="border-t border-gray-100 pt-6">
                    <div class="flex flex-col sm:flex-row gap-4 items-end">
                        <div class="flex-1 max-w-xs">
                            <label class="block text-sm font-medium text-gray-700 mb-2 flex items-center">
                                <svg class="w-4 h-4 mr-1 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                                </svg>
                                Trạng thái
                            </label>
                            <select id="statusFilter" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition duration-200 bg-white">
                                <option value="">Tất cả trạng thái</option>
                                <option value="Borrowed">Đang mượn</option>
                                <option value="Overdue">Trễ hạn</option>
                                <option value="Returned">Đã trả</option>
                                <option value="Lost">Mất sách</option>
                            </select>
                        </div>

                        <div class="flex gap-3">
                            <button onclick="applyFilters()" 
                                    class="bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800 text-white px-6 py-2.5 rounded-lg font-medium transition duration-200 shadow-sm hover:shadow-md transform hover:-translate-y-0.5 flex items-center gap-2">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
                                </svg>
                                Áp dụng
                            </button>
                            <button onclick="clearFilters()" 
                                    class="bg-gradient-to-r from-gray-500 to-gray-600 hover:from-gray-600 hover:to-gray-700 text-white px-6 py-2.5 rounded-lg font-medium transition duration-200 shadow-sm hover:shadow-md transform hover:-translate-y-0.5 flex items-center gap-2">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path>
                                </svg>
                                Xóa bộ lọc
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Books Table -->
            <div class="bg-white rounded-xl shadow-lg overflow-hidden border border-gray-100">
                <div class="overflow-x-auto">
                    <table class="w-full table-auto">
                        <thead class="bg-gradient-to-r from-gray-50 to-gray-100 border-b border-gray-200">
                            <tr>
                            <th class="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Người Mượn</th>
                            <th class="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Sách</th>
                            <th class="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">ISBN</th>
                            <th class="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Ngày Mượn</th>
                            <th class="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Hạn Trả</th>
                            <th class="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Ngày Trả</th>
                            <th class="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Trạng Thái</th>
                            <th class="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Tiền Phạt</th>
                            <th class="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Thao Tác</th>
                            </tr>
                        </thead>
                        <tbody id="tableBody" class="bg-white divide-y divide-gray-200">
                            <%
                                Connection conn = null;
                                Statement stmt = null;
                                ResultSet rs = null;

                                try {
                                    conn = DBConnection.getConnection();
                                    stmt = conn.createStatement();
                                    String sql = "SELECT b.borrow_id, u.username, bk.title, bk.isbn, "
                                            + "b.borrowed_date, b.due_date, b.return_date, "
                                            + "b.status, b.fine_amount, b.book_item_id "
                                            + "FROM borrow b "
                                            + "JOIN users u ON b.user_id = u.id "
                                            + "JOIN bookitem bi ON b.book_item_id = bi.book_item_id "
                                            + "JOIN book bk ON bi.book_isbn = bk.isbn "
                                            + "WHERE b.status != 'Pending Approval' "
                                            + "ORDER BY b.borrow_id DESC";

                                    rs = stmt.executeQuery(sql);
                                    boolean hasData = false;

                                    while (rs.next()) {
                                        hasData = true;
                                        String status = rs.getString("status");
                                        String statusText = "";
                                        String statusClass = "";

                                        // Improved status mapping with CSS classes
                                        switch (status) {
                                            case "Borrowed":
                                                statusText = "Đang mượn";
                                                statusClass = "bg-blue-100 text-blue-800";
                                                break;
                                            case "Overdue":
                                                statusText = "Trễ hạn";
                                                statusClass = "bg-red-100 text-red-800";
                                                break;
                                            case "Returned":
                                                statusText = "Đã trả";
                                                statusClass = "bg-green-100 text-green-800";
                                                break;
                                            case "Lost":
                                                statusText = "Mất sách";
                                                statusClass = "bg-gray-100 text-gray-800";
                                                break;
                                            default:
                                                statusText = status;
                                                statusClass = "bg-gray-100 text-gray-800";
                                        }

                                        // Date formatting with null checks
                                        java.sql.Date borrowedDate = rs.getDate("borrowed_date");
                                        java.sql.Date dueDate = rs.getDate("due_date");
                                        java.sql.Date returnDate = rs.getDate("return_date");

                                        String borrowedDateStr = (borrowedDate != null) ? dateFormat.format(borrowedDate) : "N/A";
                                        String dueDateStr = (dueDate != null) ? dateFormat.format(dueDate) : "N/A";
                                        String returnDateStr = (returnDate != null) ? dateFormat.format(returnDate) : "Chưa trả";

                                        // ISO format for filtering
                                        String borrowedDateISO = (borrowedDate != null) ? borrowedDate.toString() : "";
                                        String dueDateISO = (dueDate != null) ? dueDate.toString() : "";
                                        String returnDateISO = (returnDate != null) ? returnDate.toString() : "";

                                        // Fine amount handling
                                        double fineAmount = 0;
                                        if (rs.getObject("fine_amount") != null) {
                                            fineAmount = rs.getDouble("fine_amount");
                                        }
                            %>
                            <tr class="hover:bg-gray-50 transition duration-150 table-row" 
                                data-username="<%= rs.getString("username").toLowerCase()%>"
                                data-title="<%= rs.getString("title").toLowerCase()%>"
                                data-status="<%= status%>"
                                data-borrowed-date="<%= borrowedDateISO%>"
                                data-due-date="<%= dueDateISO%>"
                                data-return-date="<%= returnDateISO%>">
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                <%= rs.getString("username")%>
                            </td>
                            <td class="px-6 py-4 text-sm text-gray-900 max-w-xs truncate" title="<%= rs.getString("title")%>">
                                <%= rs.getString("title")%>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-600 font-mono">
                                <%= rs.getString("isbn")%>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                <%= borrowedDateStr%>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                <%= dueDateStr%>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                <%= returnDateStr%>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                            <span class="inline-flex px-2 py-1 text-xs font-semibold rounded-full <%= statusClass%>">
                                <%= statusText%>
                            </span>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm">
                                <% if (fineAmount > 0) {%>
                            <span class="text-red-600 font-semibold">
                                <%= String.format("%,.0f", fineAmount)%> VNĐ
                            </span>
                            <% } else { %>
                            <span class="text-gray-400">0 VNĐ</span>
                            <% } %>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                <% if (status.equals("Borrowed") || status.equals("Overdue")) {%>
                            <button onclick="confirmReturn(<%= rs.getInt("borrow_id")%>)" 
                                    class="bg-green-600 hover:bg-green-700 text-white px-2 py-2 rounded-lg text-sm font-medium transition duration-200 shadow-sm hover:shadow-md transform hover:-translate-y-0.5">
                                Xác nhận Trả
                            </button>
                            <% } else if (status.equals("Returned")) { %>
                            <span class="text-green-600 text-sm font-medium">Đã hoàn thành</span>
                            <% } else { %>
                            <span class="text-gray-400 text-sm">Không có thao tác</span>
                            <% } %>
                            </td>
                            </tr>
                            <%
                                }

                                if (!hasData) {
                            %>
                            <tr id="noDataRow">
                            <td colspan="10" class="px-6 py-12 text-center text-gray-500">
                                <div class="flex flex-col items-center">
                                    <svg class="w-12 h-12 text-gray-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.746 0 3.332.477 4.5 1.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332.477-4.5 1.253z"></path>
                                    </svg>
                                    <p class="text-lg font-medium">Không có dữ liệu mượn/trả sách</p>
                                    <p class="text-sm">Chưa có giao dịch mượn/trả sách nào được ghi nhận</p>
                                </div>
                            </td>
                            </tr>
                            <%
                                }
                            } catch (SQLException e) {
                                e.printStackTrace();
                            %>
                            <tr>
                            <td colspan="10" class="px-6 py-12 text-center text-red-500">
                                <div class="flex flex-col items-center">
                                    <svg class="w-12 h-12 text-red-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                                    </svg>
                                    <p class="text-lg font-medium">Lỗi kết nối cơ sở dữ liệu</p>
                                    <p class="text-sm">Không thể tải dữ liệu. Vui lòng thử lại sau.</p>
                                </div>
                            </td>
                            </tr>
                            <%
                                } finally {
                                    // Proper resource cleanup
                                    if (rs != null) try {
                                        rs.close();
                                    } catch (SQLException e) {
                                        e.printStackTrace();
                                    }
                                    if (stmt != null) try {
                                        stmt.close();
                                    } catch (SQLException e) {
                                        e.printStackTrace();
                                    }
                                    if (conn != null) try {
                                        conn.close();
                                    } catch (SQLException e) {
                                        e.printStackTrace();
                                    }
                                }
                            %>
                        </tbody>
                    </table>
                    <!-- Enhanced Pagination Controls -->
                    <div class="flex flex-col sm:flex-row justify-between items-center px-6 py-6 border-t border-gray-100 bg-gray-50" id="paginationControls">
                        <!-- Info Section -->
                        <div class="mb-4 sm:mb-0">
                            <p class="text-sm text-gray-600 flex items-center">
                                <svg class="w-4 h-4 mr-2 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                                </svg>
                                Hiển thị <span class="font-semibold text-gray-900" id="showingStart">1</span> - 
                                <span class="font-semibold text-gray-900" id="showingEnd">10</span> trong tổng số 
                                <span class="font-semibold text-gray-900" id="totalRecords">0</span> bản ghi
                            </p>
                        </div>

                        <!-- Pagination Navigation -->
                        <div class="flex items-center space-x-2">
                            <!-- First Page Button -->
                            <button onclick="goToPage(1)" 
                                    class="pagination-btn first-btn flex items-center px-3 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-l-lg hover:bg-gray-50 hover:text-gray-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200" 
                                    id="firstBtn" title="Trang đầu">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 19l-7-7 7-7m8 14l-7-7 7-7"></path>
                                </svg>
                            </button>

                            <!-- Previous Page Button -->
                            <button onclick="prevPage()" 
                                    class="pagination-btn prev-btn flex items-center px-3 py-2 text-sm font-medium text-gray-500 bg-white border-t border-b border-r border-gray-300 hover:bg-gray-50 hover:text-gray-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200" 
                                    id="prevBtn" title="Trang trước">
                                <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
                                </svg>
                                Trước
                            </button>

                            <!-- Page Numbers -->
                            <div id="pageNumbers" class="hidden sm:flex items-center space-x-1">
                                <!-- Page numbers will be inserted here dynamically -->
                            </div>

                            <!-- Current Page Indicator for Mobile -->
                            <div class="sm:hidden flex items-center px-4 py-2 text-sm font-medium text-white bg-blue-600 border border-blue-600 rounded-lg">
                                <span id="currentPageMobile">1</span> / <span id="totalPagesMobile">1</span>
                            </div>

                            <!-- Next Page Button -->
                            <button onclick="nextPage()" 
                                    class="pagination-btn next-btn flex items-center px-3 py-2 text-sm font-medium text-gray-500 bg-white border-t border-b border-r border-gray-300 hover:bg-gray-50 hover:text-gray-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200" 
                                    id="nextBtn" title="Trang sau">
                                Sau
                                <svg class="w-4 h-4 ml-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
                                </svg>
                            </button>

                            <!-- Last Page Button -->
                            <button onclick="goToLastPage()" 
                                    class="pagination-btn last-btn flex items-center px-3 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-r-lg hover:bg-gray-50 hover:text-gray-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200" 
                                    id="lastBtn" title="Trang cuối">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 5l7 7-7 7M5 5l7 7-7 7"></path>
                                </svg>
                            </button>
                        </div>

                        <!-- Rows per page selector -->
                        <div class="mt-4 sm:mt-0 sm:ml-6">
                            <label class="flex items-center text-sm text-gray-600">
                                <span class="mr-2">Hiển thị:</span>
                                <select id="rowsPerPageSelect" onchange="changeRowsPerPage()" 
                                        class="px-3 py-1 text-sm border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white transition-all duration-200">
                                    <option value="5">5</option>
                                    <option value="10" selected>10</option>
                                    <option value="20">20</option>
                                    <option value="50">50</option>
                                    <option value="100">100</option>
                                </select>
                                <span class="ml-2">/ trang</span>
                            </label>
                        </div>
                    </div>

                </div>
            </div>

            <!-- No Results Message (Hidden by default) -->
            <div id="noResultsMessage" class="bg-white rounded-xl shadow-lg p-12 text-center text-gray-500 hidden border border-gray-100">
                <svg class="w-12 h-12 text-gray-300 mb-4 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
                </svg>
                <p class="text-lg font-medium">Không tìm thấy kết quả</p>
                <p class="text-sm">Thử điều chỉnh từ khóa tìm kiếm hoặc bộ lọc</p>
            </div>
        </div>
    </div>

<script>
  // ========== State ==========
  let originalRows = [];        // << thêm biến toàn cục lưu mọi dòng gốc
  let currentFilteredRows = []; // tập dòng sau khi lọc
  let currentPage = 1;
  let rowsPerPage = 10;
  let totalRecords = 0;

  // ========== Pagination core ==========
  function updatePaginationInfo(filteredRows = originalRows) {
    currentFilteredRows = filteredRows;
    totalRecords = filteredRows.length;
    const totalPages = Math.ceil(totalRecords / rowsPerPage);

    const start = Math.min((currentPage - 1) * rowsPerPage + 1, totalRecords);
    const end = Math.min(currentPage * rowsPerPage, totalRecords);

    // cập nhật khu vực thông tin
    document.getElementById('showingStart').textContent = totalRecords > 0 ? start : 0;
    document.getElementById('showingEnd').textContent = end;
    document.getElementById('totalRecords').textContent = totalRecords;

    // mobile indicator
    document.getElementById('currentPageMobile').textContent = currentPage;
    document.getElementById('totalPagesMobile').textContent = totalPages || 1;

    // nút điều hướng + dãy trang
    updatePaginationButtons(totalPages);
    generatePageNumbers(totalPages);
  }

  function updatePaginationButtons(totalPages) {
    const firstBtn = document.getElementById('firstBtn');
    const prevBtn  = document.getElementById('prevBtn');
    const nextBtn  = document.getElementById('nextBtn');
    const lastBtn  = document.getElementById('lastBtn');

    firstBtn.disabled = currentPage === 1;
    prevBtn.disabled  = currentPage === 1;
    nextBtn.disabled  = currentPage === totalPages || totalPages === 0;
    lastBtn.disabled  = currentPage === totalPages || totalPages === 0;

    [firstBtn, prevBtn, nextBtn, lastBtn].forEach(btn => {
      if (btn.disabled) {
        btn.classList.add('opacity-50', 'cursor-not-allowed');
        btn.classList.remove('hover:bg-gray-50', 'hover:text-gray-700');
      } else {
        btn.classList.remove('opacity-50', 'cursor-not-allowed');
        btn.classList.add('hover:bg-gray-50', 'hover:text-gray-700');
      }
    });
  }

  function generatePageNumbers(totalPages) {
    const pageNumbersContainer = document.getElementById('pageNumbers');
    pageNumbersContainer.innerHTML = '';
    if (totalPages <= 1) return;

    const maxVisiblePages = 5;
    let startPage = Math.max(1, currentPage - Math.floor(maxVisiblePages / 2));
    let endPage = Math.min(totalPages, startPage + maxVisiblePages - 1);
    if (endPage - startPage < maxVisiblePages - 1) {
      startPage = Math.max(1, endPage - maxVisiblePages + 1);
    }

    if (startPage > 1) {
      addPageNumber(1);
      if (startPage > 2) addDots();
    }
    for (let i = startPage; i <= endPage; i++) addPageNumber(i);
    if (endPage < totalPages) {
      if (endPage < totalPages - 1) addDots();
      addPageNumber(totalPages);
    }
  }

  function addPageNumber(pageNum) {
    const pageNumbersContainer = document.getElementById('pageNumbers');
    const button = document.createElement('button');
    button.className = 'page-number-btn' + (pageNum === currentPage ? ' active' : '');
    button.textContent = pageNum;
    button.onclick = () => goToPage(pageNum);
    pageNumbersContainer.appendChild(button);
  }

  function addDots() {
    const pageNumbersContainer = document.getElementById('pageNumbers');
    const dots = document.createElement('span');
    dots.className = 'page-number-btn dots';
    dots.textContent = '...';
    pageNumbersContainer.appendChild(dots);
  }

  function renderTablePage(page, rows = originalRows) {
    const tableContainer = document.querySelector('.overflow-x-auto');
    tableContainer.classList.add('pagination-loading');

    setTimeout(() => {
      const start = (page - 1) * rowsPerPage;
      const end = start + rowsPerPage;

      // ẩn tất cả
      originalRows.forEach(row => row.style.display = 'none');
      // chỉ hiển thị dòng thuộc trang hiện tại
      rows.forEach((row, index) => {
        row.style.display = (index >= start && index < end) ? '' : 'none';
      });

      updatePaginationInfo(rows);
      tableContainer.classList.remove('pagination-loading');
    }, 80);
  }

  function goToPage(page) {
    const totalPages = Math.ceil(totalRecords / rowsPerPage);
    if (page >= 1 && page <= totalPages && page !== currentPage) {
      currentPage = page;
      renderTablePage(currentPage, currentFilteredRows);
      document.querySelector('.overflow-x-auto').scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  }

  function prevPage() { if (currentPage > 1) goToPage(currentPage - 1); }
  function nextPage() {
    const totalPages = Math.ceil(totalRecords / rowsPerPage);
    if (currentPage < totalPages) goToPage(currentPage + 1);
  }
  function goToLastPage() {
    const totalPages = Math.ceil(totalRecords / rowsPerPage);
    if (totalPages > 0) goToPage(totalPages);
  }

  function changeRowsPerPage() {
    // đọc từ combobox duy nhất còn lại (dưới bảng)
    const select = document.getElementById('rowsPerPageSelect');
    const newRowsPerPage = parseInt(select.value, 10);

    // giữ vị trí hàng đầu của trang cũ để “đổi size trang” không nhảy quá xa
    const oldStartIndex = (currentPage - 1) * rowsPerPage;
    rowsPerPage = newRowsPerPage;
    currentPage = Math.floor(oldStartIndex / rowsPerPage) + 1;

    renderTablePage(currentPage, currentFilteredRows.length ? currentFilteredRows : originalRows);
  }

  // ========== Filtering ==========
  function applyFilters() {
    const searchTerm = document.getElementById('searchInput').value.toLowerCase();
    const statusFilter = document.getElementById('statusFilter').value;
    const borrowedDateFrom = document.getElementById('borrowedDateFrom').value; // yyyy-mm-dd
    const borrowedDateTo   = document.getElementById('borrowedDateTo').value;
    const dueDateFrom      = document.getElementById('dueDateFrom').value;
    const dueDateTo        = document.getElementById('dueDateTo').value;

    const filteredRows = [];

    originalRows.forEach(row => {
      let showRow = true;
      const username = row.dataset.username || '';
      const title    = row.dataset.title || '';
      const status   = row.dataset.status || '';
      const borrowed = row.dataset.borrowedDate || '';
      const due      = row.dataset.dueDate || '';

      if (searchTerm && !username.includes(searchTerm) && !title.includes(searchTerm)) showRow = false;
      if (statusFilter && status !== statusFilter) showRow = false;

      // so sánh ngày theo chuỗi yyyy-mm-dd là OK (so sánh từ điển đúng thứ tự thời gian)
      if (borrowedDateFrom && borrowed && borrowed < borrowedDateFrom) showRow = false;
      if (borrowedDateTo   && borrowed && borrowed > borrowedDateTo)   showRow = false;
      if (dueDateFrom      && due      && due      < dueDateFrom)      showRow = false;
      if (dueDateTo        && due      && due      > dueDateTo)        showRow = false;

      if (showRow) filteredRows.push(row);
    });

    currentPage = 1;
    renderTablePage(currentPage, filteredRows);

    // toggle no-result
    const noResultsMessage = document.getElementById('noResultsMessage');
    const tableWrapper = document.querySelector('.bg-white.rounded-xl.shadow-lg.overflow-hidden');
    if (filteredRows.length === 0) {
      tableWrapper.style.display = 'none';
      noResultsMessage.classList.remove('hidden');
    } else {
      tableWrapper.style.display = '';
      noResultsMessage.classList.add('hidden');
    }
  }

  // NEW: làm việc cho nút "Xóa bộ lọc"
  function clearFilters() {
    // reset inputs
    document.getElementById('searchInput').value = '';
    document.getElementById('statusFilter').value = '';
    ['borrowedDateFrom','borrowedDateTo','dueDateFrom','dueDateTo']
      .forEach(id => { const el = document.getElementById(id); if (el) el.value = ''; });

    // hiển thị lại toàn bộ
    currentPage = 1;
    renderTablePage(currentPage, originalRows);

    // khôi phục hiển thị bảng & ẩn no-result nếu có
    const noResultsMessage = document.getElementById('noResultsMessage');
    const tableWrapper = document.querySelector('.bg-white.rounded-xl.shadow-lg.overflow-hidden');
    tableWrapper.style.display = '';
    noResultsMessage.classList.add('hidden');
  }

  // ========== Init ==========
  document.addEventListener('DOMContentLoaded', function () {
    // lấy các dòng của bảng
    const rows = document.querySelectorAll('.table-row');
    originalRows = Array.from(rows);
    currentFilteredRows = originalRows.slice();

    // sync rowsPerPage nếu combobox đã set sẵn value
    const select = document.getElementById('rowsPerPageSelect');
    if (select) rowsPerPage = parseInt(select.value, 10) || 10;

    // render trang đầu
    renderTablePage(1);

    // lắng nghe bộ lọc
    document.getElementById('searchInput').addEventListener('input', applyFilters);
    document.getElementById('statusFilter').addEventListener('change', applyFilters);
    ['borrowedDateFrom','borrowedDateTo','dueDateFrom','dueDateTo']
      .forEach(id => document.getElementById(id).addEventListener('change', applyFilters));
  });
    function confirmReturn(borrowId) {
            if (confirm("Bạn có chắc muốn xác nhận trả sách không?")) {
                fetch('../../ReturnBookServlet', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                    body: 'id=' + borrowId
                })
                        .then(response => response.json())
                        .then(data => {
                            alert(data.message);
                            window.location.href = data.redirect;
                        })
                        .catch(err => {
                            alert("Lỗi khi xác nhận trả sách.");
                            console.error(err);
                        });
            }
        }
</script>
          
</body>
</html>