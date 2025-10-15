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
                                    <a href="DeleteBookServlet?isbn=<%= book.get("isbn")%>" 
                                       class="inline-flex items-center px-3 py-2 border border-transparent text-sm leading-4 font-medium rounded-md text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 transition-colors duration-200"
                                       onclick="return confirm('Bạn có chắc muốn xóa sách này không?');">
                                        <i class="fas fa-trash-alt mr-1"></i>
                                        Xóa
                                    </a>
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
    // Sửa lại phần JavaScript để xử lý đóng modal
    (function () {
        const ctx = '<%= request.getContextPath()%>'; // ví dụ: /LV-Library
        const modal = document.getElementById('deletedBooksModal');
        const openBtn = document.getElementById('openDeletedModalBtn');
        const tbody = document.getElementById('deletedBooksTbody');
        const toast = document.getElementById('toast');

        // Lấy tất cả các elements có thể đóng modal
        const closeButtons = modal?.querySelectorAll('[data-close]');

        function openModal() {
            modal.classList.remove('hidden');
        }

        function closeModal() {
            modal.classList.add('hidden');
        }

        function showToast(msg, ok = true) {
            toast.textContent = msg;
            toast.className = "fixed top-6 right-6 z-[60] px-4 py-2 rounded-md text-white shadow-lg " + (ok ? "bg-emerald-600" : "bg-red-600");
            toast.classList.remove('hidden');
            setTimeout(() => toast.classList.add('hidden'), 2500);
        }

        // Mở modal
        if (openBtn) {
            openBtn.addEventListener('click', openModal);
        }

        // Đóng modal bằng cách click vào backdrop hoặc nút close
        if (modal) {
            modal.addEventListener('click', (e) => {
                // Kiểm tra nếu click vào backdrop (element có data-close)
                if (e.target.hasAttribute('data-close')) {
                    closeModal();
                }
            });
        }

        // Đóng modal bằng các nút close (bao gồm nút X)
        if (closeButtons) {
            closeButtons.forEach(btn => {
                btn.addEventListener('click', (e) => {
                    e.preventDefault();
                    e.stopPropagation();
                    closeModal();
                });
            });
        }

        // Đóng modal bằng phím Escape
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && !modal?.classList.contains('hidden')) {
                closeModal();
            }
        });

        // Khôi phục: POST tới servlet (SỬA TẠI ĐÂY)
        tbody?.addEventListener('click', async (e) => {
            const btn = e.target.closest('.restore-btn');
            if (!btn)
                return;

            const isbn = btn.dataset.isbn;
            btn.disabled = true;
            btn.innerHTML = '<i class="fa-solid fa-circle-notch fa-spin"></i> Đang khôi phục...';

            try {
                const resp = await fetch(ctx + '/RestoreBookServlet', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'},
                    body: new URLSearchParams({isbn})
                });

                if (!resp.ok)
                    throw new Error('HTTP ' + resp.status);

                // Xóa dòng khỏi bảng
                const row = tbody.querySelector('tr[data-row-isbn="' + isbn + '"]');
                if (row)
                    row.remove();

                if (!tbody.querySelector('tr')) {
                    const tr = document.createElement('tr');
                    tr.innerHTML = '<td class="px-3 py-6 text-center text-gray-500" colspan="4">Không có sách nào đang ở trạng thái DELETED.</td>';
                    tbody.appendChild(tr);
                }

                showToast('Khôi phục thành công!');
            } catch (err) {
                console.error(err);
                showToast('Khôi phục thất bại!', false);
                btn.disabled = false;
                btn.innerHTML = '<i class="fa-solid fa-rotate-left"></i> Khôi phục';
            }
        });
    })();
</script>
</body>
</html>