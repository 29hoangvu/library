<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%@ page import="Data.Users" %>

<%
    request.setAttribute("pageTitle", "Quản lý sách - Admin");
%>
<%
    // Đặt biến pagination vào request (sẽ được sử dụng trong searchBook.jspf)
    int dashboardCurrentPage = 1;
    if (request.getParameter("page") != null) {
        try {
            dashboardCurrentPage = Integer.parseInt(request.getParameter("page"));
        } catch (NumberFormatException e) {
            dashboardCurrentPage = 1;
        }
    }
    int dashboardBooksPerPage = 20;
    request.setAttribute("currentPage", dashboardCurrentPage);
    request.setAttribute("booksPerPage", dashboardBooksPerPage);
%>
<%@ include file="../includes/header.jsp" %>
<%
    // Lấy dữ liệu sau khi searchBook.jspf đã xử lý
    @SuppressWarnings(
            
    
    "unchecked")
    List<Map<String, Object>> books = (List<Map<String, Object>>) request.getAttribute("books");
    if (books == null) {
        books = new ArrayList<>();
    }

    Integer totalBooksAttr = (Integer) request.getAttribute("totalBooks");
    int totalBooks = (totalBooksAttr != null) ? totalBooksAttr : 0;
    int totalPages = (int) Math.ceil((double) totalBooks / dashboardBooksPerPage);
%>
<main class="transition-all duration-300 pt-32" id="mainContent">
    <div class="container mx-auto px-4 py-6">
        <!-- Nút nổi góc phải mở popup -->
        <button type="button"
                id="openDeletedModalBtn"
                class="fixed top-32 right-6 z-50 bg-red-600 hover:bg-red-700 text-white font-semibold px-4 py-2 rounded-lg shadow-lg flex items-center gap-2">
            <i class="fa-solid fa-trash-restore"></i>
            Đã xóa
        </button>

        <!-- Modal danh sách sách DELETED -->
        <div id="deletedBooksModal"
             class="fixed inset-0 z-50 hidden">
            <!-- backdrop -->
            <div class="absolute inset-0 bg-black/50" data-close></div>

            <!-- content -->
            <div class="absolute right-6 top-28 w-[min(90vw,700px)] bg-white rounded-2xl shadow-2xl overflow-hidden">
                <div class="px-5 py-4 bg-gradient-to-r from-red-500 to-rose-600 text-white flex items-center justify-between">
                    <div class="font-bold text-lg flex items-center gap-2">
                        <i class="fa-solid fa-box-archive"></i>
                        Sách đã đánh dấu xoá
                    </div>
                    <button type="button" class="text-white/90 hover:text-white" data-close>
                        <i class="fa-solid fa-xmark text-xl"></i>
                    </button>
                </div>

                <div class="p-5 max-h-[65vh] overflow-y-auto">
                    <table class="w-full border border-gray-200 rounded-lg overflow-hidden">
                        <thead class="bg-gray-50">
                            <tr class="text-left text-sm text-gray-600">
                                <th class="px-3 py-2 border-b">ISBN</th>
                                <th class="px-3 py-2 border-b">Tên sách</th>
                                <th class="px-3 py-2 border-b">Trạng thái</th>
                                <th class="px-3 py-2 border-b text-right">Hành động</th>
                            </tr>
                        </thead>
                        <tbody id="deletedBooksTbody" class="text-sm">
                            <%
                                // Lấy danh sách sách status = DELETED
                                try (Connection cDel = DBConnection.getConnection(); PreparedStatement pDel = cDel.prepareStatement(
                                        "SELECT isbn, title, status FROM book WHERE UPPER(status)='DELETED' ORDER BY title ASC"); ResultSet rDel = pDel.executeQuery()) {
                                    boolean any = false;
                                    while (rDel.next()) {
                                        any = true;
                            %>
                            <tr class="hover:bg-gray-50" data-row-isbn="<%= rDel.getString("isbn")%>">
                                <td class="px-3 py-2 border-b font-mono"><%= rDel.getString("isbn")%></td>
                                <td class="px-3 py-2 border-b"><%= rDel.getString("title")%></td>
                                <td class="px-3 py-2 border-b">
                                    <span class="px-2 py-1 rounded-full text-xs bg-red-100 text-red-700">DELETED</span>
                                </td>
                                <td class="px-3 py-2 border-b text-right">
                                    <button type="button"
                                            class="restore-btn inline-flex items-center gap-2 bg-emerald-600 hover:bg-emerald-700 text-white px-3 py-1.5 rounded-md"
                                            data-isbn="<%= rDel.getString("isbn")%>">
                                        <i class="fa-solid fa-rotate-left"></i> Khôi phục
                                    </button>
                                </td>
                            </tr>
                            <%
                                }
                                if (!any) {
                            %>
                            <tr>
                                <td class="px-3 py-6 text-center text-gray-500" colspan="4">
                                    Không có sách nào đang ở trạng thái DELETED.
                                </td>
                            </tr>
                            <%
                                }
                            } catch (Exception ex) {
                            %>
                            <tr>
                                <td class="px-3 py-6 text-center text-red-600" colspan="4">
                                    Lỗi tải danh sách: <%= ex.getMessage()%>
                                </td>
                            </tr>
                            <%
                                }
                            %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <!-- Toast nhỏ -->
        <div id="toast"
             class="fixed top-6 right-6 z-[60] hidden px-4 py-2 rounded-md text-white shadow-lg"></div>

        <!-- Table Container -->
        <div class="bg-white rounded-lg shadow-lg overflow-hidden">
            <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200">
                    <thead class="bg-gray-50">
                        <tr>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">ISBN</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Tên sách</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Tác giả</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Kệ sách</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Số lượng</th>
                            <th class="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">Thao tác</th>
                        </tr>
                    </thead>
                    <tbody class="bg-white divide-y divide-gray-200">
                        <% for (Map<String, Object> book : books) {%>
                        <tr class="hover:bg-gray-50 transition-colors duration-200">
                            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                                <%= book.get("isbn")%>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                <%= book.get("title")%>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                <%= book.get("author")%>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                <%= book.get("rack")%>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                                    <%= book.get("quantity")%>
                                </span>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-center text-sm font-medium">
                                <div class="flex justify-center space-x-2">
                                    <a href="editBook.jsp?isbn=<%= book.get("isbn")%>" 
                                       class="inline-flex items-center px-3 py-2 border border-transparent text-sm leading-4 font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-colors duration-200">
                                        <i class="fas fa-edit mr-1"></i>
                                        Sửa
                                    </a>
                                    <button type="button"
                                            class="delete-book-btn inline-flex items-center px-3 py-2 border border-transparent text-sm leading-4 font-medium rounded-md text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 transition-colors duration-200"
                                            data-isbn="<%= book.get("isbn")%>"
                                            data-title="<%= book.get("title")%>">
                                        <i class="fas fa-trash-alt mr-1"></i>
                                        Xóa
                                    </button>
                                </div>
                            </td>
                        </tr>
                        <% } %>
                    </tbody>
                </table>
            </div>

            <!-- Empty State -->
            <% if (books.isEmpty()) { %>
            <div class="text-center py-12">
                <div class="text-gray-400 mb-4">
                    <i class="fas fa-book-open text-6xl"></i>
                </div>
                <h3 class="text-lg font-medium text-gray-900 mb-2">Không có sách nào</h3>
                <p class="text-gray-500">Chưa có sách nào trong hệ thống hoặc không tìm thấy kết quả phù hợp.</p>
            </div>
            <% } %>
        </div>

        <!-- Pagination -->
        <% if (totalPages > 1) { %>
        <div class="bg-white px-4 py-3 flex items-center justify-between border-t border-gray-200 sm:px-6 mt-4 rounded-lg shadow">
            <div class="flex-1 flex justify-between sm:hidden">
                <% if (dashboardCurrentPage > 1) {%>
                <a href="adminDashboard.jsp?page=<%= dashboardCurrentPage - 1%>&search=<%= request.getParameter("search") != null ? request.getParameter("search") : ""%>" 
                   class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
                    Trước
                </a>
                <% } %>
                <% if (dashboardCurrentPage < totalPages) {%>
                <a href="adminDashboard.jsp?page=<%= dashboardCurrentPage + 1%>&search=<%= request.getParameter("search") != null ? request.getParameter("search") : ""%>" 
                   class="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
                    Tiếp
                </a>
                <% }%>
            </div>

            <div class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
                <div>
                    <p class="text-sm text-gray-700">
                        Hiển thị 
                        <span class="font-medium"><%= ((dashboardCurrentPage - 1) * dashboardBooksPerPage) + 1%></span>
                        đến 
                        <span class="font-medium"><%= Math.min(dashboardCurrentPage * dashboardBooksPerPage, totalBooks)%></span>
                        trong tổng số 
                        <span class="font-medium"><%= totalBooks%></span>
                        kết quả
                    </p>
                </div>
                <div>
                    <nav class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px" aria-label="Pagination">
                        <!-- Previous Page Link -->
                        <% if (dashboardCurrentPage > 1) {%>
                        <a href="adminDashboard.jsp?page=<%= dashboardCurrentPage - 1%>&search=<%= request.getParameter("search") != null ? request.getParameter("search") : ""%>" 
                           class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50">
                            <span class="sr-only">Trang trước</span>
                            <i class="fas fa-chevron-left h-5 w-5" aria-hidden="true"></i>
                        </a>
                        <% } else { %>
                        <span class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-gray-100 text-sm font-medium text-gray-400 cursor-not-allowed">
                            <i class="fas fa-chevron-left h-5 w-5" aria-hidden="true"></i>
                        </span>
                        <% } %>

                        <!-- Page Numbers -->
                        <%
                            int startPage = Math.max(1, dashboardCurrentPage - 2);
                            int endPage = Math.min(totalPages, dashboardCurrentPage + 2);

                            if (startPage > 1) {%>
                        <a href="adminDashboard.jsp?page=1&search=<%= request.getParameter("search") != null ? request.getParameter("search") : ""%>" 
                           class="relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50">
                            1
                        </a>
                        <% if (startPage > 2) { %>
                        <span class="relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700">...</span>
                        <% } %>
                        <% } %>

                        <% for (int i = startPage; i <= endPage; i++) { %>
                        <% if (i == dashboardCurrentPage) {%>
                        <span class="z-10 bg-indigo-50 border-indigo-500 text-indigo-600 relative inline-flex items-center px-4 py-2 border text-sm font-medium">
                            <%= i%>
                        </span>
                        <% } else {%>
                        <a href="adminDashboard.jsp?page=<%= i%>&search=<%= request.getParameter("search") != null ? request.getParameter("search") : ""%>" 
                           class="bg-white border-gray-300 text-gray-500 hover:bg-gray-50 relative inline-flex items-center px-4 py-2 border text-sm font-medium">
                            <%= i%>
                        </a>
                        <% } %>
                        <% } %>

                        <% if (endPage < totalPages) { %>
                        <% if (endPage < totalPages - 1) { %>
                        <span class="relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700">...</span>
                        <% }%>
                        <a href="adminDashboard.jsp?page=<%= totalPages%>&search=<%= request.getParameter("search") != null ? request.getParameter("search") : ""%>" 
                           class="relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50">
                            <%= totalPages%>
                        </a>
                        <% } %>

                        <!-- Next Page Link -->
                        <% if (dashboardCurrentPage < totalPages) {%>
                        <a href="adminDashboard.jsp?page=<%= dashboardCurrentPage + 1%>&search=<%= request.getParameter("search") != null ? request.getParameter("search") : ""%>" 
                           class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50">
                            <span class="sr-only">Trang sau</span>
                            <i class="fas fa-chevron-right h-5 w-5" aria-hidden="true"></i>
                        </a>
                        <% } else { %>
                        <span class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-gray-100 text-sm font-medium text-gray-400 cursor-not-allowed">
                            <i class="fas fa-chevron-right h-5 w-5" aria-hidden="true"></i>
                        </span>
                        <% } %>
                    </nav>
                </div>
            </div>
        </div>
        <% }%>
    </div>
</main>
<script>
(function () {
    const ctx = '<%= request.getContextPath()%>';
    const API_ENDPOINT = ctx + '/api/admin/book-management';
    
    const modal = document.getElementById('deletedBooksModal');
    const openBtn = document.getElementById('openDeletedModalBtn');
    const tbody = document.getElementById('deletedBooksTbody');
    const closeButtons = modal?.querySelectorAll('[data-close]');

    // ========== TOAST SYSTEM ==========
    const Toast = {
        container: null,
        
        init: function() {
            this.container = document.getElementById('toastContainer');
            if (!this.container) {
                this.container = document.createElement('div');
                this.container.id = 'toastContainer';
                this.container.className = 'toast-container';
                document.body.appendChild(this.container);
            }
        },
        
        show: function(options) {
            this.init();
            
            const type = options.type || 'info';
            const title = options.title || '';
            const message = options.message || '';
            const duration = options.duration !== undefined ? options.duration : 4000;
            
            const toast = document.createElement('div');
            toast.className = 'toast ' + type;
            
            const icons = {
                success: '<svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path></svg>',
                error: '<svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"></path></svg>',
                warning: '<svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"></path></svg>',
                info: '<svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd"></path></svg>'
            };
            
            const titleHtml = title ? '<div class="toast-title">' + title + '</div>' : '';
            
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
            
            const self = this;
            toast.querySelector('.toast-close').addEventListener('click', function() {
                self.hide(toast);
            });
            
            if (duration > 0) {
                setTimeout(function() {
                    self.hide(toast);
                }, duration);
            }
            
            return toast;
        },
        
        hide: function(toast) {
            toast.classList.add('hiding');
            setTimeout(function() {
                if (toast.parentNode) {
                    toast.parentNode.removeChild(toast);
                }
            }, 300);
        },
        
        success: function(message, title) {
            return this.show({ 
                type: 'success', 
                title: title || 'Thành công', 
                message: message 
            });
        },
        
        error: function(message, title) {
            return this.show({ 
                type: 'error', 
                title: title || 'Lỗi', 
                message: message 
            });
        },
        
        warning: function(message, title) {
            return this.show({ 
                type: 'warning', 
                title: title || 'Cảnh báo', 
                message: message 
            });
        },
        
        info: function(message, title) {
            return this.show({ 
                type: 'info', 
                title: title || 'Thông tin', 
                message: message 
            });
        }
    };

    // ========== CONFIRMATION MODAL ==========
    const ConfirmModal = {
        show: function(options) {
            const type = options.type || 'warning';
            const title = options.title || 'Xác nhận';
            const message = options.message || 'Bạn có chắc chắn muốn thực hiện hành động này?';
            const confirmText = options.confirmText || 'Xác nhận';
            const cancelText = options.cancelText || 'Hủy';
            const onConfirm = options.onConfirm || function() {};
            const onCancel = options.onCancel || function() {};
            
            const icons = {
                warning: '<svg class="w-6 h-6" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"></path></svg>',
                danger: '<svg class="w-6 h-6" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"></path></svg>',
                success: '<svg class="w-6 h-6" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path></svg>',
                info: '<svg class="w-6 h-6" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd"></path></svg>'
            };
            
            const overlay = document.createElement('div');
            overlay.className = 'confirm-modal-overlay';
            
            const confirmBtnClass = 'confirm-modal-btn confirm-modal-btn-confirm';
            const btnTypeClass = type === 'danger' ? ' danger' : '';
            
            overlay.innerHTML = '<div class="confirm-modal-content">' +
                    '<div class="confirm-modal-header">' +
                        '<div class="confirm-modal-icon ' + type + '">' +
                            icons[type] +
                        '</div>' +
                        '<div class="confirm-modal-header-text">' +
                            '<h3 class="confirm-modal-title">' + title + '</h3>' +
                            '<p class="confirm-modal-message">' + message + '</p>' +
                        '</div>' +
                    '</div>' +
                    '<div class="confirm-modal-footer">' +
                        '<button class="confirm-modal-btn confirm-modal-btn-cancel" data-action="cancel">' +
                            cancelText +
                        '</button>' +
                        '<button class="' + confirmBtnClass + btnTypeClass + '" data-action="confirm">' +
                            confirmText +
                        '</button>' +
                    '</div>' +
                '</div>';
            
            document.body.appendChild(overlay);
            
            const self = this;
            
            overlay.querySelector('[data-action="cancel"]').addEventListener('click', function() {
                self.hide(overlay);
                onCancel();
            });
            
            overlay.querySelector('[data-action="confirm"]').addEventListener('click', function() {
                self.hide(overlay);
                onConfirm();
            });
            
            overlay.addEventListener('click', function(e) {
                if (e.target === overlay) {
                    self.hide(overlay);
                    onCancel();
                }
            });
            
            const escHandler = function(e) {
                if (e.key === 'Escape') {
                    self.hide(overlay);
                    onCancel();
                    document.removeEventListener('keydown', escHandler);
                }
            };
            document.addEventListener('keydown', escHandler);
            
            return overlay;
        },
        
        hide: function(overlay) {
            overlay.classList.add('hiding');
            setTimeout(function() {
                if (overlay.parentNode) {
                    overlay.parentNode.removeChild(overlay);
                }
            }, 200);
        },
        
        confirm: function(options) {
            return new Promise(function(resolve) {
                const originalOnConfirm = options.onConfirm || function() {};
                const originalOnCancel = options.onCancel || function() {};
                
                options.onConfirm = function() {
                    originalOnConfirm();
                    resolve(true);
                };
                options.onCancel = function() {
                    originalOnCancel();
                    resolve(false);
                };
                
                ConfirmModal.show(options);
            });
        }
    };

    // ========== DELETED BOOKS MODAL ==========
    function openModal() {
        modal.classList.remove('hidden');
    }

    function closeModal() {
        modal.classList.add('hidden');
    }

    if (openBtn) {
        openBtn.addEventListener('click', openModal);
    }

    if (modal) {
        modal.addEventListener('click', (e) => {
            if (e.target.hasAttribute('data-close')) {
                closeModal();
            }
        });
    }

    if (closeButtons) {
        closeButtons.forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.preventDefault();
                e.stopPropagation();
                closeModal();
            });
        });
    }

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && !modal?.classList.contains('hidden')) {
            closeModal();
        }
    });

    // ========== RESTORE BOOK ==========
    tbody?.addEventListener('click', async (e) => {
        const btn = e.target.closest('.restore-btn');
        if (!btn) return;

        const isbn = btn.dataset.isbn;
        const row = tbody.querySelector('tr[data-row-isbn="' + isbn + '"]');
        const bookTitle = row?.querySelector('td:nth-child(2)')?.textContent || 'sách này';

        const confirmed = await ConfirmModal.confirm({
            type: 'success',
            title: 'Khôi phục sách',
            message: 'Bạn có chắc chắn muốn khôi phục "' + bookTitle + '" không?',
            confirmText: 'Khôi phục',
            cancelText: 'Hủy'
        });

        if (!confirmed) return;

        btn.disabled = true;
        btn.innerHTML = '<i class="fa-solid fa-circle-notch fa-spin"></i> Đang khôi phục...';

        try {
            const resp = await fetch(API_ENDPOINT, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
                },
                body: new URLSearchParams({
                    action: 'restore',
                    isbn: isbn
                })
            });

            const data = await resp.json();

            if (data.ok) {
                if (row) row.remove();

                if (!tbody.querySelector('tr[data-row-isbn]')) {
                    tbody.innerHTML = '<tr><td class="px-3 py-6 text-center text-gray-500" colspan="4">Không có sách nào đang ở trạng thái DELETED.</td></tr>';
                }

                Toast.success(data.message || 'Khôi phục thành công!');
            } else {
                Toast.error(data.message || 'Khôi phục thất bại!');
                btn.disabled = false;
                btn.innerHTML = '<i class="fa-solid fa-rotate-left"></i> Khôi phục';
            }
        } catch (err) {
            console.error('Restore error:', err);
            Toast.error('Lỗi kết nối! Vui lòng thử lại.');
            btn.disabled = false;
            btn.innerHTML = '<i class="fa-solid fa-rotate-left"></i> Khôi phục';
        }
    });

    // ========== DELETE BOOK ==========
    document.querySelectorAll('.delete-book-btn').forEach(btn => {
        btn.addEventListener('click', async (e) => {
            e.preventDefault();
            
            const isbn = btn.dataset.isbn;
            const bookTitle = btn.dataset.title || 'sách này';
            
            const confirmed = await ConfirmModal.confirm({
                type: 'danger',
                title: 'Xác nhận xóa sách',
                message: 'Bạn có chắc muốn xóa "' + bookTitle + '" không? Sách sẽ được chuyển vào trạng thái DELETED.',
                confirmText: 'Xóa',
                cancelText: 'Hủy'
            });

            if (!confirmed) return;

            const originalHtml = btn.innerHTML;
            btn.disabled = true;
            btn.innerHTML = '<i class="fas fa-spinner fa-spin mr-1"></i> Đang xóa...';

            try {
                const resp = await fetch(API_ENDPOINT, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
                    },
                    body: new URLSearchParams({
                        action: 'delete',
                        isbn: isbn
                    })
                });

                const data = await resp.json();

                if (data.ok) {
                    Toast.success(data.message || 'Xóa sách thành công!');
                    setTimeout(() => {
                        location.reload();
                    }, 1000);
                } else {
                    Toast.error(data.message || 'Không thể xóa sách!');
                    btn.disabled = false;
                    btn.innerHTML = originalHtml;
                }
            } catch (err) {
                console.error('Delete error:', err);
                Toast.error('Lỗi kết nối! Vui lòng thử lại.');
                btn.disabled = false;
                btn.innerHTML = originalHtml;
            }
        });
    });
})();
</script>
<style>
/* ===== MODAL CONFIRMATION ===== */
.confirm-modal-overlay {
    position: fixed;
    inset: 0;
    background: rgba(0, 0, 0, 0.5);
    backdrop-filter: blur(4px);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 9998;
    opacity: 0;
    animation: fadeIn 0.2s ease-out forwards;
}

.confirm-modal-content {
    background: white;
    border-radius: 16px;
    padding: 0;
    max-width: 450px;
    width: 90%;
    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
    transform: scale(0.9);
    animation: scaleIn 0.2s ease-out forwards;
}

.confirm-modal-header {
    padding: 24px 24px 16px 24px;
    display: flex;
    align-items: flex-start;
    gap: 16px;
}

.confirm-modal-icon {
    flex-shrink: 0;
    width: 48px;
    height: 48px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
}

.confirm-modal-icon.warning { background: #fef3c7; color: #d97706; }
.confirm-modal-icon.danger { background: #fee2e2; color: #dc2626; }
.confirm-modal-icon.success { background: #d1fae5; color: #059669; }
.confirm-modal-icon.info { background: #dbeafe; color: #2563eb; }

.confirm-modal-header-text { flex: 1; padding-top: 4px; }
.confirm-modal-title { font-size: 18px; font-weight: 700; color: #111827; margin-bottom: 8px; }
.confirm-modal-message { font-size: 14px; color: #6b7280; line-height: 1.5; }

.confirm-modal-footer {
    padding: 16px 24px 24px 24px;
    display: flex;
    gap: 12px;
    justify-content: flex-end;
}

.confirm-modal-btn {
    padding: 10px 20px;
    border-radius: 8px;
    font-size: 14px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s;
    border: none;
    outline: none;
}

.confirm-modal-btn-cancel {
    background: #f3f4f6;
    color: #374151;
}

.confirm-modal-btn-cancel:hover {
    background: #e5e7eb;
}

.confirm-modal-btn-confirm {
    background: linear-gradient(135deg, #3b82f6, #2563eb);
    color: white;
    box-shadow: 0 2px 8px rgba(59, 130, 246, 0.3);
}

.confirm-modal-btn-confirm:hover {
    box-shadow: 0 4px 12px rgba(59, 130, 246, 0.4);
    transform: translateY(-1px);
}

.confirm-modal-btn-confirm.danger {
    background: linear-gradient(135deg, #ef4444, #dc2626);
    box-shadow: 0 2px 8px rgba(239, 68, 68, 0.3);
}

.confirm-modal-btn-confirm.danger:hover {
    box-shadow: 0 4px 12px rgba(239, 68, 68, 0.4);
}

@keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
}

@keyframes scaleIn {
    from { transform: scale(0.9); opacity: 0; }
    to { transform: scale(1); opacity: 1; }
}

.confirm-modal-overlay.hiding {
    animation: fadeOut 0.2s ease-out forwards;
}

.confirm-modal-overlay.hiding .confirm-modal-content {
    animation: scaleOut 0.2s ease-out forwards;
}

@keyframes fadeOut {
    from { opacity: 1; }
    to { opacity: 0; }
}

@keyframes scaleOut {
    from { transform: scale(1); opacity: 1; }
    to { transform: scale(0.9); opacity: 0; }
}

/* ===== TOAST NOTIFICATION ===== */
.toast-container {
    position: fixed;
    top: 20px;
    right: 20px;
    z-index: 9999;
    display: flex;
    flex-direction: column;
    gap: 10px;
    pointer-events: none;
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

.toast.success { border-left-color: #10b981; }
.toast.error { border-left-color: #ef4444; }
.toast.warning { border-left-color: #f59e0b; }
.toast.info { border-left-color: #3b82f6; }

.toast-icon {
    flex-shrink: 0;
    width: 24px;
    height: 24px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
}

.toast.success .toast-icon { background: #d1fae5; color: #059669; }
.toast.error .toast-icon { background: #fee2e2; color: #dc2626; }
.toast.warning .toast-icon { background: #fef3c7; color: #d97706; }
.toast.info .toast-icon { background: #dbeafe; color: #2563eb; }

.toast-content { flex: 1; }
.toast-title { font-weight: 600; color: #111827; margin-bottom: 2px; font-size: 14px; }
.toast-message { color: #6b7280; font-size: 13px; line-height: 1.4; }

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

.toast-close:hover { background: #f3f4f6; color: #4b5563; }

@keyframes slideInRight {
    from { transform: translateX(400px); opacity: 0; }
    to { transform: translateX(0); opacity: 1; }
}

@keyframes slideOutRight {
    from { transform: translateX(0); opacity: 1; }
    to { transform: translateX(400px); opacity: 0; }
}

.toast.hiding { animation: slideOutRight 0.3s ease-out forwards; }

/* Responsive */
@media (max-width: 640px) {
    .toast-container {
        left: 10px;
        right: 10px;
        top: 10px;
    }
    
    .toast {
        min-width: auto;
        max-width: none;
    }
    
    .confirm-modal-content {
        width: 95%;
    }
}
</style>
<!-- Toast Container -->
<div class="toast-container" id="toastContainer"></div>
</body>
</html>