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
/* Toast Notification Styles */
.toast-container {
    position: fixed;
    top: 20px;
    right: 20px;
    z-index: 9999;
    display: flex;
    flex-direction: column;
    gap: 10px;
    pointer-events: none;
    margin: 30px;
}

.toast {
    background: white;
    border-radius: 12px;
    padding: 16px 20px;
    box-shadow: 0 10px 40px rgba(0, 0, 0, 0.15);
    display: flex;
    align-items: center;
    gap: 12px;
    min-width: 320px;
    max-width: 420px;
    pointer-events: auto;
    animation: slideInRight 0.3s ease-out;
    border-left: 4px solid;
}

.toast.success {
    border-left-color: #10b981;
}

.toast.error {
    border-left-color: #ef4444;
}

.toast.warning {
    border-left-color: #f59e0b;
}

.toast.info {
    border-left-color: #3b82f6;
}

.toast-icon {
    flex-shrink: 0;
    width: 24px;
    height: 24px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
}

.toast.success .toast-icon {
    background: #d1fae5;
    color: #059669;
}

.toast.error .toast-icon {
    background: #fee2e2;
    color: #dc2626;
}

.toast.warning .toast-icon {
    background: #fef3c7;
    color: #d97706;
}

.toast.info .toast-icon {
    background: #dbeafe;
    color: #2563eb;
}

.toast-content {
    flex: 1;
}

.toast-title {
    font-weight: 600;
    color: #111827;
    margin-bottom: 2px;
    font-size: 14px;
}

.toast-message {
    color: #6b7280;
    font-size: 13px;
    line-height: 1.4;
}

.toast-close {
    flex-shrink: 0;
    width: 20px;
    height: 20px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    color: #9ca3af;
    transition: all 0.2s;
}

.toast-close:hover {
    background: #f3f4f6;
    color: #4b5563;
}

@keyframes slideInRight {
    from {
        transform: translateX(400px);
        opacity: 0;
    }
    to {
        transform: translateX(0);
        opacity: 1;
    }
}

@keyframes slideOutRight {
    from {
        transform: translateX(0);
        opacity: 1;
    }
    to {
        transform: translateX(400px);
        opacity: 0;
    }
}

.toast.hiding {
    animation: slideOutRight 0.3s ease-out forwards;
}

/* Confirmation Modal Styles */
.modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.5);
    backdrop-filter: blur(4px);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 9998;
    opacity: 0;
    animation: fadeIn 0.2s ease-out forwards;
}

.modal-content {
    background: white;
    border-radius: 16px;
    padding: 0;
    max-width: 450px;
    width: 90%;
    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
    transform: scale(0.9);
    animation: scaleIn 0.2s ease-out forwards;
}

.modal-header {
    padding: 24px 24px 16px 24px;
    display: flex;
    align-items: flex-start;
    gap: 16px;
}

.modal-icon {
    flex-shrink: 0;
    width: 48px;
    height: 48px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
}

.modal-icon.warning {
    background: #fef3c7;
    color: #d97706;
}

.modal-icon.danger {
    background: #fee2e2;
    color: #dc2626;
}

.modal-icon.success {
    background: #d1fae5;
    color: #059669;
}

.modal-icon.info {
    background: #dbeafe;
    color: #2563eb;
}

.modal-header-text {
    flex: 1;
    padding-top: 4px;
}

.modal-title {
    font-size: 18px;
    font-weight: 700;
    color: #111827;
    margin-bottom: 8px;
}

.modal-message {
    font-size: 14px;
    color: #6b7280;
    line-height: 1.5;
}

.modal-footer {
    padding: 16px 24px 24px 24px;
    display: flex;
    gap: 12px;
    justify-content: flex-end;
}

.modal-btn {
    padding: 10px 20px;
    border-radius: 8px;
    font-size: 14px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s;
    border: none;
    outline: none;
}

.modal-btn-cancel {
    background: #f3f4f6;
    color: #374151;
}

.modal-btn-cancel:hover {
    background: #e5e7eb;
}

.modal-btn-confirm {
    background: linear-gradient(135deg, #3b82f6, #2563eb);
    color: white;
    box-shadow: 0 2px 8px rgba(59, 130, 246, 0.3);
}

.modal-btn-confirm:hover {
    box-shadow: 0 4px 12px rgba(59, 130, 246, 0.4);
    transform: translateY(-1px);
}

.modal-btn-confirm.danger {
    background: linear-gradient(135deg, #ef4444, #dc2626);
    box-shadow: 0 2px 8px rgba(239, 68, 68, 0.3);
}

.modal-btn-confirm.danger:hover {
    box-shadow: 0 4px 12px rgba(239, 68, 68, 0.4);
}

@keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
}

@keyframes scaleIn {
    from {
        transform: scale(0.9);
        opacity: 0;
    }
    to {
        transform: scale(1);
        opacity: 1;
    }
}

@keyframes fadeOut {
    from { opacity: 1; }
    to { opacity: 0; }
}

.modal-overlay.hiding {
    animation: fadeOut 0.2s ease-out forwards;
}

.modal-overlay.hiding .modal-content {
    animation: scaleOut 0.2s ease-out forwards;
}

@keyframes scaleOut {
    from {
        transform: scale(1);
        opacity: 1;
    }
    to {
        transform: scale(0.9);
        opacity: 0;
    }
}

/* Responsive */
@media (max-width: 640px) {
    .toast-container {
        left: 10px;
        right: 10px;
        top: 30px;
        margin-top: 30px;
    }
    
    .toast {
        min-width: auto;
        max-width: none;
    }
    
    .modal-content {
        width: 95%;
    }
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
                                <% if (fineAmount > 0) { %>
                            <span class="text-red-600 font-semibold">
                                <%= String.format("%,.0f", fineAmount)%> VNĐ
                            </span>
                            <% } else { %>
                            <span class="text-gray-400">0 VNĐ</span>
                            <% } %>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                <% if (status.equals("Borrowed") || status.equals("Overdue")) { %>
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
  const ADMIN_BORROW_API = '<%=request.getContextPath()%>/api/admin/am-borrows';

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
    if (!confirm("Bạn có chắc muốn xác nhận trả sách không?")) return;
    const token = localStorage.getItem('token');
    if (!token) {
      showModal('Lỗi', 'Không tìm thấy token đăng nhập. Vui lòng đăng nhập lại.');
      return;
    }
    const body = new URLSearchParams();
    body.append('action', 'return');
    body.append('borrowId', borrowId);

    fetch(ADMIN_BORROW_API, {
      method: 'POST',
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
        "Authorization": "Bearer " + token
      },
      body: body.toString()
    })
    .then(response => response.json())
    .then(d => {
      if (d.ok) {
        alert(d.message || "Xác nhận trả sách thành công");
        window.location.reload();
      } else {
        alert(d.message || "Không thể xác nhận trả sách.");
      }
    })
    .catch(err => {
      console.error(err);
      alert("Lỗi khi xác nhận trả sách.");
    });
  }
</script>
<!-- Toast Container -->
<div class="toast-container top-30" id="toastContainer"></div>

<!-- Modal Container -->
<div id="modalContainer"></div>          
<script>
// ========== Toast Notification System ==========
const Toast = {
    container: null,
    
    init() {
        this.container = document.getElementById('toastContainer');
        if (!this.container) {
            this.container = document.createElement('div');
            this.container.id = 'toastContainer';
            this.container.className = 'toast-container';
            document.body.appendChild(this.container);
        }
    },
    
    show(options) {
        this.init();
        
        const {
            type = 'info', // success, error, warning, info
            title = '',
            message = '',
            duration = 4000
        } = options;
        
        const toast = document.createElement('div');
        toast.className = `toast ${type}`;
        
        const icons = {
            success: '<svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path></svg>',
            error: '<svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"></path></svg>',
            warning: '<svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"></path></svg>',
            info: '<svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd"></path></svg>'
        };
        
        var titleHtml = title ? '<div class="toast-title">' + title + '</div>' : '';
        
        toast.innerHTML = '<div class="toast-icon">' + icons[type] + '</div>' +
            '<div class="toast-content">' +
                titleHtml +
                '<div class="toast-message">' + message + '</div>' +
            '</div>' +
            '<div class="toast-close">' +
                '<svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">' +
                    '<path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"></path>' +
                '</svg>' +
            '</div>';
        
        this.container.appendChild(toast);
        
        // Close button handler
        const closeBtn = toast.querySelector('.toast-close');
        closeBtn.addEventListener('click', () => this.hide(toast));
        
        // Auto hide
        if (duration > 0) {
            setTimeout(() => this.hide(toast), duration);
        }
        
        return toast;
    },
    
    hide(toast) {
        toast.classList.add('hiding');
        setTimeout(() => {
            if (toast.parentNode) {
                toast.parentNode.removeChild(toast);
            }
        }, 300);
    },
    
    success(message, title = 'Thành công') {
        return this.show({ type: 'success', title, message });
    },
    
    error(message, title = 'Lỗi') {
        return this.show({ type: 'error', title, message });
    },
    
    warning(message, title = 'Cảnh báo') {
        return this.show({ type: 'warning', title, message });
    },
    
    info(message, title = 'Thông tin') {
        return this.show({ type: 'info', title, message });
    }
};

// ========== Confirmation Modal System ==========
const Modal = {
    show(options) {
        const {
            type = 'warning', // warning, danger, success, info
            title = 'Xác nhận',
            message = 'Bạn có chắc chắn muốn thực hiện hành động này?',
            confirmText = 'Xác nhận',
            cancelText = 'Hủy',
            onConfirm = () => {},
            onCancel = () => {}
        } = options;
        
        const icons = {
            warning: '<svg class="w-6 h-6" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"></path></svg>',
            danger: '<svg class="w-6 h-6" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"></path></svg>',
            success: '<svg class="w-6 h-6" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path></svg>',
            info: '<svg class="w-6 h-6" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd"></path></svg>'
        };
        
        const overlay = document.createElement('div');
        overlay.className = 'modal-overlay';
        
        var confirmBtnClass = 'modal-btn modal-btn-confirm' + (type === 'danger' ? ' danger' : '');
        
        overlay.innerHTML = '<div class="modal-content">' +
                '<div class="modal-header">' +
                    '<div class="modal-icon ' + type + '">' +
                        icons[type] +
                    '</div>' +
                    '<div class="modal-header-text">' +
                        '<h3 class="modal-title">' + title + '</h3>' +
                        '<p class="modal-message">' + message + '</p>' +
                    '</div>' +
                '</div>' +
                '<div class="modal-footer">' +
                    '<button class="modal-btn modal-btn-cancel" data-action="cancel">' +
                        cancelText +
                    '</button>' +
                    '<button class="' + confirmBtnClass + '" data-action="confirm">' +
                        confirmText +
                    '</button>' +
                '</div>' +
            '</div>';
        
        document.body.appendChild(overlay);
        
        // Event handlers
        overlay.querySelector('[data-action="cancel"]').addEventListener('click', () => {
            this.hide(overlay);
            onCancel();
        });
        
        overlay.querySelector('[data-action="confirm"]').addEventListener('click', () => {
            this.hide(overlay);
            onConfirm();
        });
        
        // Click outside to close
        overlay.addEventListener('click', (e) => {
            if (e.target === overlay) {
                this.hide(overlay);
                onCancel();
            }
        });
        
        // ESC key to close
        const escHandler = (e) => {
            if (e.key === 'Escape') {
                this.hide(overlay);
                onCancel();
                document.removeEventListener('keydown', escHandler);
            }
        };
        document.addEventListener('keydown', escHandler);
        
        return overlay;
    },
    
    hide(overlay) {
        overlay.classList.add('hiding');
        setTimeout(() => {
            if (overlay.parentNode) {
                overlay.parentNode.removeChild(overlay);
            }
        }, 200);
    },
    
    confirm(options) {
        return new Promise((resolve) => {
            this.show({
                ...options,
                onConfirm: () => resolve(true),
                onCancel: () => resolve(false)
            });
        });
    }
};

// ========== Cập nhật hàm confirmReturn ==========
function confirmReturn(borrowId) {
    Modal.confirm({
        type: 'warning',
        title: 'Xác nhận trả sách',
        message: 'Bạn có chắc chắn muốn xác nhận người dùng đã trả sách này không? Hành động này không thể hoàn tác.',
        confirmText: 'Xác nhận trả',
        cancelText: 'Hủy bỏ'
    }).then(confirmed => {
        if (!confirmed) return;
        
        const token = localStorage.getItem('token');
        if (!token) {
            Toast.error('Không tìm thấy token đăng nhập. Vui lòng đăng nhập lại.', 'Lỗi xác thực');
            return;
        }
        
        // Hiển thị toast đang xử lý
        const processingToast = Toast.info('Đang xử lý yêu cầu...', 'Vui lòng đợi', 0);
        
        const body = new URLSearchParams();
        body.append('action', 'return');
        body.append('borrowId', borrowId);

        fetch(ADMIN_BORROW_API, {
            method: 'POST',
            headers: {
                "Accept": "application/json",
                "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
                "Authorization": "Bearer " + token
            },
            body: body.toString()
        })
        .then(response => response.json())
        .then(data => {
            // Ẩn toast đang xử lý
            Toast.hide(processingToast);
            
            if (data.ok) {
                Toast.success(data.message || 'Xác nhận trả sách thành công!', 'Hoàn tất');
                setTimeout(() => window.location.reload(), 1500);
            } else {
                Toast.error(data.message || 'Không thể xác nhận trả sách. Vui lòng thử lại.', 'Thất bại');
            }
        })
        .catch(err => {
            Toast.hide(processingToast);
            console.error(err);
            Toast.error('Đã xảy ra lỗi khi kết nối với máy chủ. Vui lòng thử lại sau.', 'Lỗi kết nối');
        });
    });
}

// ========== Ví dụ sử dụng Toast ==========
/*
// Success toast
Toast.success('Thao tác đã được thực hiện thành công!');

// Error toast
Toast.error('Đã xảy ra lỗi trong quá trình xử lý.');

// Warning toast
Toast.warning('Hãy kiểm tra lại thông tin trước khi tiếp tục.');

// Info toast
Toast.info('Dữ liệu đang được tải...');

// Custom toast
Toast.show({
    type: 'success',
    title: 'Tiêu đề tùy chỉnh',
    message: 'Nội dung thông báo',
    duration: 5000
});
*/

// ========== Ví dụ sử dụng Modal ==========
/*
// Simple confirmation
Modal.confirm({
    title: 'Xác nhận xóa',
    message: 'Bạn có chắc chắn muốn xóa mục này?',
    type: 'danger'
}).then(confirmed => {
    if (confirmed) {
        console.log('User confirmed');
    }
});

// With custom buttons
Modal.show({
    type: 'warning',
    title: 'Cảnh báo',
    message: 'Thay đổi sẽ không được lưu',
    confirmText: 'Tiếp tục',
    cancelText: 'Quay lại',
    onConfirm: () => console.log('Confirmed'),
    onCancel: () => console.log('Cancelled')
});
*/
</script>
</body>
</html>
