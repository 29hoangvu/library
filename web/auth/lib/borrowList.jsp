<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.net.URLEncoder" %>
<%@ page import="Servlet.DBConnection" %>

<%
    // ==== INPUT PARAMS (đổi tên để không trùng với file include khác) ====
    String searchTerm = request.getParameter("search");
    if (searchTerm == null) searchTerm = "";
    final String STATUS_ONLY = "Pending Approval"; // Chỉ hiện chờ duyệt

    int recordsPerPage = 10;
    int pageNum = 1; // không đụng implicit object "page"
    try {
        String p = request.getParameter("page");
        if (p != null && !p.isEmpty()) pageNum = Integer.parseInt(p);
        if (pageNum < 1) pageNum = 1;
    } catch (NumberFormatException ignore) {}

    int totalRecords = 0;
    int totalPages   = 1;
    int offset       = 0;

    // Stats (chỉ chờ duyệt)
    int pending = 0;

    boolean dbOk = true;
    String dbError = null;

    try (Connection conn = DBConnection.getConnection()) {
        // Đếm số chờ duyệt
        String statsSql = "SELECT COUNT(*) AS pending FROM borrow WHERE status = ?";
        try (PreparedStatement ps = conn.prepareStatement(statsSql)) {
            ps.setString(1, STATUS_ONLY);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) pending = rs.getInt("pending");
            }
        }

        // Count query chỉ với Pending + search
        StringBuilder countSql = new StringBuilder(
            "SELECT COUNT(*) AS total FROM borrow b " +
            "JOIN users u   ON b.user_id = u.id " +
            "JOIN bookitem bi ON b.book_item_id = bi.book_item_id " +
            "JOIN book bk  ON bi.book_isbn = bk.isbn " +
            "WHERE b.status = ?"
        );
        if (!searchTerm.isEmpty()) countSql.append(" AND u.username LIKE ?");

        try (PreparedStatement cps = conn.prepareStatement(countSql.toString())) {
            int idx = 1;
            cps.setString(idx++, STATUS_ONLY);
            if (!searchTerm.isEmpty())  cps.setString(idx++, "%" + searchTerm + "%");

            try (ResultSet rs = cps.executeQuery()) {
                if (rs.next()) totalRecords = rs.getInt("total");
            }
        }

        totalPages = Math.max(1, (int)Math.ceil((double)totalRecords / recordsPerPage));
        if (pageNum > totalPages) pageNum = totalPages;
        offset = (pageNum - 1) * recordsPerPage;

        request.setAttribute("offset", offset);
        request.setAttribute("recordsPerPage", recordsPerPage);
        request.setAttribute("searchTerm", searchTerm);
    } catch (SQLException e) {
        dbOk = false;
        dbError = e.getMessage();
        e.printStackTrace();
    }

    String encSearch = URLEncoder.encode(searchTerm, "UTF-8");
%>

<%@ include file="../includes/header.jsp" %>
<main class="transition-all duration-300 pt-32" id="mainContent">
  <div class="min-h-screen bg-gradient-to-br from-blue-50 via-white to-indigo-50 p-6">
    <div class="max-w-7xl mx-auto">
      <!-- Header -->
      <div class="mb-8">
        <div class="text-center mb-6">
          <h1 class="text-4xl font-bold text-gray-800 mb-2">Quản lý duyệt mượn sách</h1>
          <p class="text-gray-600">Chỉ hiển thị các yêu cầu <strong>Chờ duyệt</strong></p>
        </div>

        <!-- Search -->
        <div class="bg-white rounded-xl shadow-lg p-6 mb-6">
          <div class="flex flex-col lg:flex-row gap-4 items-center justify-between">
            <div class="flex-1 max-w-md">
              <div class="relative">
                <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <svg class="h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
                  </svg>
                </div>
                <input
                  type="text"
                  id="searchInput"
                  class="block w-full pl-10 pr-3 py-3 border border-gray-300 rounded-lg leading-5 bg-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition"
                  placeholder="Tìm kiếm theo tên người mượn..."
                  value="<%= searchTerm %>"
                  onkeyup="if(event.key==='Enter'){searchBorrow();}"
                />
              </div>
            </div>

            <div class="flex gap-3">
              <button onclick="searchBorrow()"
                      class="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition duration-200">
                Tìm kiếm
              </button>
              <button onclick="refreshData()"
                      class="px-6 py-3 bg-gray-600 text-white rounded-lg hover:bg-gray-700 focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 transition duration-200">
                Làm mới
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Stats (chỉ chờ duyệt) -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
        <div class="bg-white rounded-xl shadow-lg p-6 border-l-4 border-yellow-400">
          <div class="flex items-center">
            <div class="w-8 h-8 bg-yellow-100 rounded-full flex items-center justify-center">
              <svg class="w-5 h-5 text-yellow-600" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clip-rule="evenodd"></path>
              </svg>
            </div>
            <div class="ml-5">
              <div class="text-sm font-medium text-gray-500">Chờ duyệt</div>
              <div class="text-lg font-semibold text-gray-900"><%= pending %></div>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-xl shadow-lg p-6 border-l-4 border-blue-400 md:col-span-2">
          <div class="text-gray-600">Chỉ các yêu cầu đang chờ duyệt được liệt kê bên dưới. Bạn có thể duyệt hoặc từ chối từng yêu cầu.</div>
        </div>
      </div>

      <!-- Bảng -->
      <div class="bg-white rounded-xl shadow-lg overflow-hidden">
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200" id="borrowTable">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Người mượn</th>
                <th class="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Thông tin sách</th>
                <th class="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Thời gian</th>
                <th class="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Trạng thái</th>
                <th class="px-6 py-4 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">Hành động</th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200" id="tableBody">
<%
    if (!dbOk) {
%>
              <tr>
                <td colspan="5" class="px-6 py-10 text-center text-red-600">
                  Không thể tải dữ liệu: <%= dbError %>
                </td>
              </tr>
<%
    } else {
        // Render rows: chỉ Pending Approval
        try (Connection conn2 = DBConnection.getConnection()) {
            int offsetQ = (Integer)request.getAttribute("offset");
            int limitQ  = (Integer)request.getAttribute("recordsPerPage");

            StringBuilder sql = new StringBuilder(
              "SELECT b.borrow_id, u.username, u.email, bk.title, bk.isbn, " +
              "b.borrowed_date, b.due_date, b.status, b.book_item_id " +
              "FROM borrow b " +
              "JOIN users u ON b.user_id = u.id " +
              "JOIN bookitem bi ON b.book_item_id = bi.book_item_id " +
              "JOIN book bk ON bi.book_isbn = bk.isbn " +
              "WHERE b.status = ?"
            );
            if (!searchTerm.isEmpty()) sql.append(" AND u.username LIKE ?");
            sql.append(" ORDER BY b.borrowed_date DESC LIMIT ? OFFSET ?");

            try (PreparedStatement stmt = conn2.prepareStatement(sql.toString())) {
                int idx = 1;
                stmt.setString(idx++, STATUS_ONLY);
                if (!searchTerm.isEmpty()) stmt.setString(idx++, "%" + searchTerm + "%");
                stmt.setInt(idx++, limitQ);
                stmt.setInt(idx++, offsetQ);

                int count = 0;
                try (ResultSet rs = stmt.executeQuery()) {
                    while (rs.next()) {
                        count++;
%>
              <tr class="hover:bg-gray-50 transition-colors">
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="flex items-center">
                    <div class="h-10 w-10 rounded-full bg-gradient-to-r from-blue-400 to-blue-600 flex items-center justify-center text-white font-medium">
                      <%= rs.getString("username").substring(0,1).toUpperCase() %>
                    </div>
                    <div class="ml-4">
                      <div class="text-sm font-medium text-gray-900"><%= rs.getString("username") %></div>
                      <div class="text-sm text-gray-500"><%= rs.getString("email")==null?"N/A":rs.getString("email") %></div>
                    </div>
                  </div>
                </td>
                <td class="px-6 py-4">
                  <div class="text-sm text-gray-900 font-medium"><%= rs.getString("title") %></div>
                  <div class="text-sm text-gray-500">ISBN: <%= rs.getString("isbn") %></div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  <div class="space-y-1">
                    <div><span class="text-gray-600">Ngày mượn:</span> <span class="font-medium"><%= rs.getDate("borrowed_date") %></span></div>
                    <div><span class="text-gray-600">Hạn trả:</span> <span class="font-medium"><%= rs.getDate("due_date") %></span></div>
                  </div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span class="inline-flex px-3 py-1 text-xs font-semibold rounded-full text-yellow-700 bg-yellow-100">Chờ duyệt</span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-center text-sm font-medium">
                  <div class="flex justify-center space-x-2">
                    <button onclick="approveBorrow(<%= rs.getInt("borrow_id") %>, <%= rs.getInt("book_item_id") %>)"
                            class="px-3 py-2 rounded-md text-white bg-green-600 hover:bg-green-700 focus:outline-none">
                      Duyệt
                    </button>
                    <button onclick="rejectBorrow(<%= rs.getInt("borrow_id") %>)"
                            class="px-3 py-2 rounded-md text-white bg-red-600 hover:bg-red-700 focus:outline-none">
                      Từ chối
                    </button>
                  </div>
                </td>
              </tr>
<%
                    } // while
                }
                if (count == 0) {
%>
              <tr>
                <td colspan="5" class="px-6 py-12 text-center text-gray-500">
                  Không có yêu cầu chờ duyệt phù hợp.
                </td>
              </tr>
<%
                }
            }
        } catch (SQLException e) {
%>
              <tr>
                <td colspan="5" class="px-6 py-10 text-center text-red-600">
                  Lỗi tải dữ liệu: <%= e.getMessage() %>
                </td>
              </tr>
<%
        }
    }
%>
            </tbody>
          </table>
        </div>

        <!-- Pagination -->
<%
    if (totalPages > 1) {
%>
        <div class="bg-white px-4 py-3 flex items-center justify-between border-t border-gray-200 sm:px-6">
          <div class="hidden sm:block text-sm text-gray-700">
            Hiển thị
            <span class="font-medium"><%= Math.min(offset + 1, totalRecords) %></span>
            đến
            <span class="font-medium"><%= Math.min(offset + recordsPerPage, totalRecords) %></span>
            trong tổng số
            <span class="font-medium"><%= totalRecords %></span>
            yêu cầu chờ duyệt
          </div>
          <div>
            <nav class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px" aria-label="Pagination">
<%
      if (pageNum > 1) {
%>
              <a href="?page=<%= (pageNum-1) %>&search=<%= encSearch %>"
                 class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50">‹</a>
<%
      } else {
%>
              <span class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-gray-100 text-sm font-medium text-gray-400">‹</span>
<%
      }

      int startPage = Math.max(1, pageNum - 2);
      int endPage   = Math.min(totalPages, pageNum + 2);

      if (startPage > 1) {
%>
              <a href="?page=1&search=<%= encSearch %>" class="relative inline-flex items-center px-4 py-2 border bg-white text-sm text-gray-700 hover:bg-gray-50">1</a>
<%
          if (startPage > 2) {
%>
              <span class="relative inline-flex items-center px-4 py-2 border bg-white text-sm text-gray-700">…</span>
<%
          }
      }
      for (int i = startPage; i <= endPage; i++) {
          if (i == pageNum) {
%>
              <span class="relative inline-flex items-center px-4 py-2 border border-blue-500 bg-blue-50 text-sm font-medium text-blue-600"><%= i %></span>
<%
          } else {
%>
              <a href="?page=<%= i %>&search=<%= encSearch %>" class="relative inline-flex items-center px-4 py-2 border bg-white text-sm text-gray-700 hover:bg-gray-50"><%= i %></a>
<%
          }
      }
      if (endPage < totalPages) {
          if (endPage < totalPages - 1) {
%>
              <span class="relative inline-flex items-center px-4 py-2 border bg-white text-sm text-gray-700">…</span>
<%
          }
%>
              <a href="?page=<%= totalPages %>&search=<%= encSearch %>" class="relative inline-flex items-center px-4 py-2 border bg-white text-sm text-gray-700 hover:bg-gray-50"><%= totalPages %></a>
<%
      }

      if (pageNum < totalPages) {
%>
              <a href="?page=<%= (pageNum+1) %>&search=<%= encSearch %>"
                 class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50">›</a>
<%
      } else {
%>
              <span class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-gray-100 text-sm font-medium text-gray-400">›</span>
<%
      }
%>
            </nav>
          </div>
        </div>
<%
    } // end pagination
%>
      </div>
    </div>
  </div>
    <!-- Modal -->
    <div id="messageModal" class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full hidden z-50">
      <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
        <div class="mt-3 text-center">
          <div id="modalIcon" class="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-blue-100">
            <svg class="h-6 w-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
            </svg>
          </div>
          <h3 id="modalTitle" class="text-lg font-medium text-gray-900 mt-2"></h3>
          <div class="mt-2 px-7 py-3"><p id="modalMessage" class="text-sm text-gray-500"></p></div>
          <div class="items-center px-4 py-3">
            <button id="modalCloseBtn" class="px-4 py-2 bg-blue-500 text-white text-base font-medium rounded-md w-full hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-300">Đóng</button>
          </div>
        </div>
      </div>
    </div>
    <!-- Toast Container -->
    <div class="toast-container" id="toastContainer"></div>
</main>
<script>
const ADMIN_BORROW_API = '<%=request.getContextPath()%>/api/admin/am-borrows';

function searchBorrow() {
  const searchValue = document.getElementById('searchInput').value || '';
  const url = new URL(window.location);
  url.searchParams.set('search', searchValue);
  url.searchParams.set('page', '1'); // reset về trang 1
  window.location.href = url.toString();
}

function refreshData() {
  window.location.href = window.location.pathname;
}

document.getElementById('modalCloseBtn').addEventListener('click', ()=>{
  document.getElementById('messageModal').classList.add('hidden')
});
// ========== Modal System ==========
const Modal = {
    show: function(options) {
        var type = options.type || 'warning';
        var title = options.title || 'Xác nhận';
        var message = options.message || 'Bạn có chắc chắn muốn thực hiện hành động này?';
        var confirmText = options.confirmText || 'Xác nhận';
        var cancelText = options.cancelText || 'Hủy';
        var onConfirm = options.onConfirm || function() {};
        var onCancel = options.onCancel || function() {};
        var showInput = options.showInput || false;
        var inputPlaceholder = options.inputPlaceholder || '';
        
        var icons = {
            warning: '<svg class="w-6 h-6" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"></path></svg>',
            danger: '<svg class="w-6 h-6" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"></path></svg>',
            success: '<svg class="w-6 h-6" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path></svg>',
            info: '<svg class="w-6 h-6" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd"></path></svg>'
        };
        
        var overlay = document.createElement('div');
        overlay.className = 'modal-overlay';
        
        var confirmBtnClass = 'modal-btn modal-btn-confirm';
        if (type === 'danger') confirmBtnClass += ' danger';
        if (type === 'success') confirmBtnClass += ' success';
        
        var inputHtml = showInput ? '<input type="text" class="modal-input" placeholder="' + inputPlaceholder + '" id="modalInput">' : '';
        
        overlay.innerHTML = '<div class="modal-content">' +
                '<div class="modal-header">' +
                    '<div class="modal-icon ' + type + '">' +
                        icons[type] +
                    '</div>' +
                    '<div class="modal-header-text">' +
                        '<h3 class="modal-title">' + title + '</h3>' +
                        '<p class="modal-message">' + message + '</p>' +
                        inputHtml +
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
        
        var self = this;
        
        overlay.querySelector('[data-action="cancel"]').addEventListener('click', function() {
            self.hide(overlay);
            onCancel();
        });
        
        overlay.querySelector('[data-action="confirm"]').addEventListener('click', function() {
            var inputValue = '';
            if (showInput) {
                var input = document.getElementById('modalInput');
                inputValue = input ? input.value : '';
            }
            self.hide(overlay);
            onConfirm(inputValue);
        });
        
        overlay.addEventListener('click', function(e) {
            if (e.target === overlay) {
                self.hide(overlay);
                onCancel();
            }
        });
        
        var escHandler = function(e) {
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
            var originalOnConfirm = options.onConfirm || function() {};
            var originalOnCancel = options.onCancel || function() {};

            options.onConfirm = function(value) {
                originalOnConfirm(value);
                // FIX: Trả về true nếu không có input
                if (value === undefined || value === '') {
                    resolve(true);
                } else {
                    resolve(value);
                }
            };
            options.onCancel = function() {
                originalOnCancel();
                resolve(false);
            };

            Modal.show(options);
        });
    }
};

function showModal(title, message){
  const modal = document.getElementById('messageModal');
  document.getElementById('modalTitle').textContent = title;
  document.getElementById('modalMessage').textContent = message;
  modal.classList.remove('hidden');
}
// ========== Toast Notification System ==========
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
        
        var type = options.type || 'info';
        var title = options.title || '';
        var message = options.message || '';
        var duration = options.duration !== undefined ? options.duration : 4000;
        
        var toast = document.createElement('div');
        toast.className = 'toast ' + type;
        
        var icons = {
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
        
        var self = this;
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
function approveBorrow(borrowId, bookItemId) {
    Modal.confirm({
        type: 'success',
        title: 'Xác nhận duyệt',
        message: 'Bạn có chắc chắn muốn duyệt yêu cầu mượn sách này không?',
        confirmText: 'Duyệt',
        cancelText: 'Hủy'
    }).then(function(confirmed) {
        if (confirmed === false) {  // Chỉ reject khi === false
            return;
        }
        
        var token = localStorage.getItem('token');
        
        if (!token) {
            Toast.error('Không tìm thấy token đăng nhập. Vui lòng đăng nhập lại.', 'Lỗi xác thực');
            return;
        }
        
        var processingToast = Toast.info('Đang xử lý yêu cầu...', 'Vui lòng đợi', 0);
        
        var body = new URLSearchParams();
        body.append('action', 'approve');
        body.append('borrowId', borrowId);
        body.append('bookItemId', bookItemId);
        
        fetch(ADMIN_BORROW_API, {
            method: 'POST',
            headers: {
                "Accept": "application/json",
                "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
                "Authorization": "Bearer " + token
            },
            body: body.toString()
        })
        .then(function(r) {

            return r.text();
        })
        .then(function(text) {
            try {
                var d = JSON.parse(text);
                
                Toast.hide(processingToast);
                
                if (d.ok) {
                    Toast.success(d.message || 'Đã duyệt yêu cầu mượn sách thành công!', 'Hoàn tất');
                    setTimeout(function() { location.reload(); }, 1500);
                } else {
                    Toast.error(d.message || 'Không thể duyệt yêu cầu. Vui lòng thử lại.', 'Thất bại');
                }
            } catch (parseError) {
                console.error("JSON parse error:", parseError);
                console.error("Attempted to parse:", text);
                Toast.hide(processingToast);
                Toast.error('Lỗi phản hồi từ server: ' + text.substring(0, 100), 'Lỗi');
            }
        })
        .catch(function(err) {
            console.error("=== FETCH ERROR ===");
            console.error("Error object:", err);
            console.error("Error message:", err.message);
            console.error("Error stack:", err.stack);
            
            Toast.hide(processingToast);
            Toast.error('Đã xảy ra lỗi khi kết nối với máy chủ: ' + err.message, 'Lỗi kết nối');
        });
    });
}

function rejectBorrow(borrowId) {

    
    Modal.confirm({
        type: 'danger',
        title: 'Từ chối yêu cầu',
        message: 'Vui lòng nhập lý do từ chối yêu cầu mượn sách:',
        confirmText: 'Từ chối',
        cancelText: 'Hủy',
        showInput: true,
        inputPlaceholder: 'Nhập lý do từ chối...'
    }).then(function(reason) {
        
        if (!reason || reason === false) {
            return;
        }
        
        if (!reason.trim()) {
            Toast.warning('Vui lòng nhập lý do từ chối.', 'Thiếu thông tin');
            return;
        }
        
        var token = localStorage.getItem('token');        
        if (!token) {
            Toast.error('Không tìm thấy token đăng nhập. Vui lòng đăng nhập lại.', 'Lỗi xác thực');
            return;
        }
        
        var processingToast = Toast.info('Đang xử lý yêu cầu...', 'Vui lòng đợi', 0);
        
        var body = new URLSearchParams();
        body.append('action', 'reject');
        body.append('borrowId', borrowId);
        body.append('reason', reason);
       

        fetch(ADMIN_BORROW_API, {
            method: 'POST',
            headers: {
                "Accept": "application/json",
                "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
                "Authorization": "Bearer " + token
            },
            body: body.toString()
        })
        .then(function(r) {
            return r.text();
        })
        .then(function(text) {
            try {
                var d = JSON.parse(text);
                
                Toast.hide(processingToast);
                
                if (d.ok) {
                    Toast.success(d.message || 'Đã từ chối yêu cầu mượn sách!', 'Hoàn tất');
                    setTimeout(function() { location.reload(); }, 1500);
                } else {
                    Toast.error(d.message || 'Không thể từ chối yêu cầu. Vui lòng thử lại.', 'Thất bại');
                }
            } catch (parseError) {
                console.error("JSON parse error:", parseError);
                console.error("Attempted to parse:", text);
                Toast.hide(processingToast);
                Toast.error('Lỗi phản hồi từ server: ' + text.substring(0, 100), 'Lỗi');
            }
        })
        .catch(function(err) {
            console.error("=== FETCH ERROR ===");
            console.error("Error object:", err);
            console.error("Error message:", err.message);
            console.error("Error stack:", err.stack);
            
            Toast.hide(processingToast);
            Toast.error('Đã xảy ra lỗi khi kết nối với máy chủ: ' + err.message, 'Lỗi kết nối');
        });
    });
}
</script>

<style>
.overflow-x-auto::-webkit-scrollbar{height:6px}
.overflow-x-auto::-webkit-scrollbar-track{background:#f1f1f1;border-radius:3px}
.overflow-x-auto::-webkit-scrollbar-thumb{background:#c1c1c1;border-radius:3px}
.overflow-x-auto::-webkit-scrollbar-thumb:hover{background:#a8a8a8}
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

.modal-icon.warning { background: #fef3c7; color: #d97706; }
.modal-icon.danger { background: #fee2e2; color: #dc2626; }
.modal-icon.success { background: #d1fae5; color: #059669; }
.modal-icon.info { background: #dbeafe; color: #2563eb; }

.modal-header-text { flex: 1; padding-top: 4px; }
.modal-title { font-size: 18px; font-weight: 700; color: #111827; margin-bottom: 8px; }
.modal-message { font-size: 14px; color: #6b7280; line-height: 1.5; }

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

.modal-btn-confirm.success {
    background: linear-gradient(135deg, #10b981, #059669);
    box-shadow: 0 2px 8px rgba(16, 185, 129, 0.3);
}

.modal-btn-confirm.success:hover {
    box-shadow: 0 4px 12px rgba(16, 185, 129, 0.4);
}

/* Input Modal */
.modal-input {
    width: 100%;
    padding: 12px;
    border: 1px solid #d1d5db;
    border-radius: 8px;
    font-size: 14px;
    transition: all 0.2s;
    margin-top: 12px;
}

.modal-input:focus {
    outline: none;
    border-color: #3b82f6;
    box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.modal-input::placeholder {
    color: #9ca3af;
}

@keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
}

@keyframes scaleIn {
    from { transform: scale(0.9); opacity: 0; }
    to { transform: scale(1); opacity: 1; }
}

@keyframes fadeOut {
    from { opacity: 1; }
    to { opacity: 0; }
}

@keyframes scaleOut {
    from { transform: scale(1); opacity: 1; }
    to { transform: scale(0.9); opacity: 0; }
}

.modal-overlay.hiding {
    animation: fadeOut 0.2s ease-out forwards;
}

.modal-overlay.hiding .modal-content {
    animation: scaleOut 0.2s ease-out forwards;
}

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
    
    .modal-content {
        width: 95%;
    }
}
</style>
