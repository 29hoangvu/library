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
                            class="px-3 py-2 rounded-md text-white bg-green-600 hover:bg-green-700 focus:outline-none transition duration-200 shadow-sm hover:shadow-md">
                      Duyệt
                    </button>
                    <button onclick="rejectBorrow(<%= rs.getInt("borrow_id") %>)"
                            class="px-3 py-2 rounded-md text-white bg-red-600 hover:bg-red-700 focus:outline-none transition duration-200 shadow-sm hover:shadow-md">
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
                  <div class="flex flex-col items-center">
                    <svg class="w-12 h-12 text-gray-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
                    </svg>
                    <p class="text-lg font-medium">Không có yêu cầu chờ duyệt</p>
                    <p class="text-sm">Không có yêu cầu nào phù hợp với điều kiện tìm kiếm</p>
                  </div>
                </td>
              </tr>
<%
                }
            }
        } catch (SQLException e) {
%>
              <tr>
                <td colspan="5" class="px-6 py-10 text-center text-red-600">
                  <div class="flex flex-col items-center">
                    <svg class="w-12 h-12 text-red-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                    </svg>
                    <p class="text-lg font-medium">Lỗi tải dữ liệu</p>
                    <p class="text-sm"><%= e.getMessage() %></p>
                  </div>
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

  <!-- Toast Container -->
  <div id="toastContainer" class="fixed bottom-5 right-5 z-[2147483647] flex flex-col-reverse gap-3 pointer-events-none"></div>

  <!-- Confirmation Popup for Approve -->
  <div id="confirmApprovePopup" class="fixed inset-0 z-[9998] hidden items-center justify-center bg-black/40 backdrop-blur-sm">
    <div class="bg-white rounded-xl shadow-2xl p-6 max-w-sm w-full mx-4 transform transition-all duration-300 scale-95 opacity-0">
      <div class="flex items-center justify-center w-12 h-12 mx-auto mb-4 bg-green-100 rounded-full">
        <svg class="w-6 h-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
        </svg>
      </div>
      <h3 class="text-lg font-bold text-gray-900 mb-2 text-center">Xác nhận duyệt</h3>
      <p class="text-gray-700 mb-6 text-center">Bạn có chắc chắn muốn duyệt yêu cầu mượn sách này không?</p>
      <div class="flex justify-center gap-3">
        <button id="confirmApproveCancel" class="px-5 py-2.5 bg-gray-200 rounded-lg hover:bg-gray-300 text-gray-700 font-medium transition-colors">Hủy</button>
        <button id="confirmApproveOk" class="px-5 py-2.5 bg-gradient-to-r from-green-600 to-green-700 text-white rounded-lg hover:from-green-700 hover:to-green-800 font-medium transition-all duration-300">Duyệt</button>
      </div>
    </div>
  </div>

  <!-- Confirmation Popup for Reject -->
  <div id="confirmRejectPopup" class="fixed inset-0 z-[9998] hidden items-center justify-center bg-black/40 backdrop-blur-sm">
    <div class="bg-white rounded-xl shadow-2xl p-6 max-w-md w-full mx-4 transform transition-all duration-300 scale-95 opacity-0">
      <div class="flex items-center justify-center w-12 h-12 mx-auto mb-4 bg-red-100 rounded-full">
        <svg class="w-6 h-6 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
        </svg>
      </div>
      <h3 class="text-lg font-bold text-gray-900 mb-2 text-center">Từ chối yêu cầu</h3>
      <p class="text-gray-700 mb-4 text-center">Vui lòng nhập lý do từ chối:</p>
      <textarea id="rejectReason" 
                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500 resize-none" 
                rows="3" 
                placeholder="Nhập lý do từ chối..."></textarea>
      <div class="flex justify-center gap-3 mt-4">
        <button id="confirmRejectCancel" class="px-5 py-2.5 bg-gray-200 rounded-lg hover:bg-gray-300 text-gray-700 font-medium transition-colors">Hủy</button>
        <button id="confirmRejectOk" class="px-5 py-2.5 bg-gradient-to-r from-red-600 to-red-700 text-white rounded-lg hover:from-red-700 hover:to-red-800 font-medium transition-all duration-300">Từ chối</button>
      </div>
    </div>
  </div>
</main>

<script>
const ADMIN_BORROW_API = '<%=request.getContextPath()%>/api/admin/am-borrows';

function showToast(message, type = "info", duration = 3000) {
    const container = document.getElementById("toastContainer");
    if (!container) return;

    const styles = {
        success: "bg-gradient-to-r from-green-500 to-emerald-600 text-white",
        error:   "bg-gradient-to-r from-red-500 to-rose-600 text-white",
        warning: "bg-gradient-to-r from-yellow-400 to-amber-500 text-black",
        info:    "bg-gradient-to-r from-blue-500 to-indigo-600 text-white"
    };

    const icons = {
        success: '<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>',
        error: '<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>',
        warning: '<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path></svg>',
        info: '<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>'
    };

    const toast = document.createElement("div");
    toast.className = `
        pointer-events-auto rounded-xl shadow-xl px-5 py-4
        ${styles[type] || styles.info}
        transition-all duration-300 ease-out
        opacity-0 translate-y-3 ring-1 ring-black/10
        flex items-center gap-3
    `;
    toast.innerHTML = `
        <div class="flex-shrink-0">${icons[type] || icons.info}</div>
        <span class="font-medium">${message}</span>
    `;

    container.appendChild(toast);

    requestAnimationFrame(() => {
        toast.classList.remove("opacity-0", "translate-y-3");
        toast.classList.add("opacity-100", "translate-y-0");
    });

    const hide = () => {
        toast.classList.add("opacity-0", "translate-y-3");
        setTimeout(() => toast.remove(), 250);
    };
    const timer = setTimeout(hide, duration);

    toast.addEventListener("click", () => {
        clearTimeout(timer);
        hide();
    });
}

// Approve popup
let currentApproveBorrowId = null;
let currentApproveBookItemId = null;

function approveBorrow(borrowId, bookItemId) {
    currentApproveBorrowId = borrowId;
    currentApproveBookItemId = bookItemId;
    
    const popup = document.getElementById("confirmApprovePopup");
    const popupContent = popup.querySelector('.transform');
    
    popup.classList.remove("hidden");
    popup.classList.add("flex");
    
    setTimeout(() => {
        popupContent.classList.remove("scale-95", "opacity-0");
        popupContent.classList.add("scale-100", "opacity-100");
    }, 50);
}

function closeApprovePopup() {
    const popup = document.getElementById("confirmApprovePopup");
    const popupContent = popup.querySelector('.transform');
    
    popupContent.classList.remove("scale-100", "opacity-100");
    popupContent.classList.add("scale-95", "opacity-0");
    
    setTimeout(() => {
        popup.classList.add("hidden");
        popup.classList.remove("flex");
        currentApproveBorrowId = null;
        currentApproveBookItemId = null;
    }, 300);
}

document.getElementById("confirmApproveCancel").addEventListener("click", () => {
    closeApprovePopup();
    showToast("Đã hủy thao tác", "warning");
});

document.getElementById("confirmApproveOk").addEventListener("click", async () => {
    if (!currentApproveBorrowId || !currentApproveBookItemId) return;
    
    closeApprovePopup();
    
    const token = localStorage.getItem('token');
    if (!token) {
        showToast('Không tìm thấy token đăng nhập. Vui lòng đăng nhập lại.', 'error');
        return;
    }

    const body = new URLSearchParams();
    body.append('action', 'approve');
    body.append('borrowId', currentApproveBorrowId);
    body.append('bookItemId', currentApproveBookItemId);

    try {
        const response = await fetch(ADMIN_BORROW_API, {
            method: 'POST',
            headers: {
                "Accept": "application/json",
                "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
                "Authorization": "Bearer " + token
            },
            body: body.toString()
        });
        
        const data = await response.json();
        
        if (data.ok) {
            showToast(data.message || 'Đã duyệt yêu cầu thành công!', 'success');
            setTimeout(() => location.reload(), 1500);
        } else {
            showToast(data.message || 'Không thể duyệt yêu cầu', 'error');
        }
    } catch (err) {
        console.error(err);
        showToast('Không kết nối được server', 'error');
    }
});

// Reject popup
let currentRejectBorrowId = null;

function rejectBorrow(borrowId) {
    currentRejectBorrowId = borrowId;
    
    const popup = document.getElementById("confirmRejectPopup");
    const popupContent = popup.querySelector('.transform');
    const reasonInput = document.getElementById("rejectReason");
    
    reasonInput.value = "";
    popup.classList.remove("hidden");
    popup.classList.add("flex");
    
    setTimeout(() => {
        popupContent.classList.remove("scale-95", "opacity-0");
        popupContent.classList.add("scale-100", "opacity-100");
        reasonInput.focus();
    }, 50);
}

function closeRejectPopup() {
    const popup = document.getElementById("confirmRejectPopup");
    const popupContent = popup.querySelector('.transform');
    
    popupContent.classList.remove("scale-100", "opacity-100");
    popupContent.classList.add("scale-95", "opacity-0");
    
    setTimeout(() => {
        popup.classList.add("hidden");
        popup.classList.remove("flex");
        currentRejectBorrowId = null;
        document.getElementById("rejectReason").value = "";
    }, 300);
}

document.getElementById("confirmRejectCancel").addEventListener("click", () => {
    closeRejectPopup();
    showToast("Đã hủy thao tác", "warning");
});

document.getElementById("confirmRejectOk").addEventListener("click", async () => {
    const reason = document.getElementById("rejectReason").value.trim();
    
    if (!reason) {
        showToast("Vui lòng nhập lý do từ chối", "warning");
        return;
    }
    
    if (!currentRejectBorrowId) return;
    
    closeRejectPopup();
    
    const token = localStorage.getItem('token');
    if (!token) {
        showToast('Không tìm thấy token đăng nhập. Vui lòng đăng nhập lại.', 'error');
        return;
    }

    const body = new URLSearchParams();
    body.append('action', 'reject');
    body.append('borrowId', currentRejectBorrowId);
    body.append('reason', reason);

    try {
        const response = await fetch(ADMIN_BORROW_API, {
            method: 'POST',
            headers: {
                "Accept": "application/json",
                "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
                "Authorization": "Bearer " + token
            },
            body: body.toString()
        });
        
        const data = await response.json();
        
        if (data.ok) {
            showToast(data.message || 'Đã từ chối yêu cầu!', 'success');
            setTimeout(() => location.reload(), 1500);
        } else {
            showToast(data.message || 'Không thể từ chối yêu cầu', 'error');
        }
    } catch (err) {
        console.error(err);
        showToast('Không kết nối được server', 'error');
    }
});

function searchBorrow() {
  const searchValue = document.getElementById('searchInput').value || '';
  const url = new URL(window.location);
  url.searchParams.set('search', searchValue);
  url.searchParams.set('page', '1');
  window.location.href = url.toString();
}

function refreshData() {
  window.location.href = window.location.pathname;
}
</script>

<style>
.overflow-x-auto::-webkit-scrollbar{height:6px}
.overflow-x-auto::-webkit-scrollbar-track{background:#f1f1f1;border-radius:3px}
.overflow-x-auto::-webkit-scrollbar-thumb{background:#c1c1c1;border-radius:3px}
.overflow-x-auto::-webkit-scrollbar-thumb:hover{background:#a8a8a8}
</style>
