<%@ page contentType="text/html; charset=UTF-8" language="java"
         buffer="64kb" autoFlush="true" errorPage="/error.jsp" %>
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Quản lý Người Dùng</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
  <script>
    tailwind.config = {
      theme: {
        extend: {
          colors: {
            primary: {
              50: '#f0f9ff',
              100: '#e0f2fe',
              500: '#0ea5e9',
              600: '#0284c7',
              700: '#0369a1',
            }
          },
          boxShadow: {
            'soft': '0 4px 20px -2px rgba(0, 0, 0, 0.08)',
            'medium': '0 8px 30px rgba(0, 0, 0, 0.12)',
          }
        }
      }
    }
  </script>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');
    body {
      font-family: 'Inter', sans-serif;
    }

    .gradient-bg {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    }

    .table-row-hover:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
    }

    .fade-in {
      animation: fadeIn 0.5s ease-in-out;
    }

    @keyframes fadeIn {
      from { opacity: 0; transform: translateY(10px); }
      to { opacity: 1; transform: translateY(0); }
    }
  </style>
</head>
<body class="bg-gray-50 min-h-screen">
  <jsp:include page="../includes/header.jsp" />

  <div class="container mx-auto px-4 py-8 mt-32">
    <!-- Header Card -->
    <div class="bg-gradient-to-r from-primary-600 to-purple-600 rounded-2xl p-8 shadow-medium text-white mb-8 fade-in">
      <div class="flex flex-col md:flex-row md:items-center justify-between">
        <div class="flex items-center gap-4 mb-4 md:mb-0">
          <div class="bg-white/20 p-3 rounded-xl">
            <i class="fas fa-users text-2xl"></i>
          </div>
          <div>
            <h1 class="text-2xl font-bold">Quản lý Người Dùng</h1>
            <p class="opacity-90">Quản lý và theo dõi tất cả người dùng trong hệ thống</p>
          </div>
        </div>
        <div class="flex items-center gap-2 bg-white/10 px-4 py-2 rounded-lg">
          <i class="fas fa-database"></i>
          <span>Tổng số: <span id="totalUsers" class="font-semibold">0</span> người dùng</span>
        </div>
      </div>
    </div>

    <!-- Main Content Card -->
    <div class="bg-white rounded-2xl p-6 shadow-soft fade-in">
      <!-- Filter Section -->
      <div class="bg-gradient-to-br from-gray-50 to-gray-100 rounded-xl p-6 mb-8 border border-gray-200">
        <div class="flex items-center gap-2 mb-4">
          <i class="fas fa-filter text-primary-600"></i>
          <h3 class="text-lg font-semibold text-gray-800">Bộ lọc & Tìm kiếm</h3>
        </div>

        <form id="filterForm" class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div>
            <label for="searchUsername" class="block text-sm font-medium text-gray-700 mb-2">
              <i class="fas fa-search mr-1 text-primary-500"></i>Tìm kiếm theo tên đăng nhập
            </label>
            <div class="relative">
              <input type="text" id="searchUsername" name="searchUsername"
                     placeholder="Nhập tên đăng nhập..."
                     class="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-primary-500 focus:border-primary-500 transition-all duration-200 bg-white">
              <i class="fas fa-user absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400"></i>
            </div>
          </div>

          <div>
            <label for="filterRole" class="block text-sm font-medium text-gray-700 mb-2">
              <i class="fas fa-user-tag mr-1 text-primary-500"></i>Lọc theo vai trò
            </label>
            <div class="relative">
              <select id="filterRole" name="filterRole"
                      class="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-primary-500 focus:border-primary-500 transition-all duration-200 bg-white appearance-none">
                <option value="">Tất cả vai trò</option>
                <option value="1">Admin</option>
                <option value="2">Librarian</option>
                <option value="3">Member</option>
              </select>
              <i class="fas fa-user-cog absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 pointer-events-none"></i>
              <i class="fas fa-chevron-down absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 pointer-events-none"></i>
            </div>
          </div>

          <div class="flex items-end gap-3">
            <button type="submit"
                    class="flex-1 bg-gradient-to-r from-primary-500 to-primary-600 text-white rounded-xl py-3 px-4 font-medium hover:from-primary-600 hover:to-primary-700 transition-all duration-200 shadow-md hover:shadow-lg flex items-center justify-center gap-2">
              <i class="fas fa-search"></i>
              <span>Tìm kiếm</span>
            </button>
            <button type="button" id="clearBtn"
                    class="flex-1 bg-gradient-to-r from-gray-500 to-gray-600 text-white rounded-xl py-3 px-4 font-medium hover:from-gray-600 hover:to-gray-700 transition-all duration-200 shadow-md hover:shadow-lg flex items-center justify-center gap-2">
              <i class="fas fa-redo"></i>
              <span>Xóa bộ lọc</span>
            </button>
          </div>
        </form>
      </div>

      <!-- Table Section -->
      <div class="rounded-xl overflow-hidden border border-gray-200 shadow-sm">
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead class="bg-gradient-to-r from-primary-600 to-purple-600 text-white">
              <tr>
                <th class="px-6 py-4 text-left font-semibold uppercase text-sm">
                  <div class="flex items-center gap-2">
                    <i class="fas fa-hashtag text-sm"></i>
                    <span>ID</span>
                  </div>
                </th>
                <th class="px-6 py-4 text-left font-semibold uppercase text-sm">
                  <div class="flex items-center gap-2">
                    <i class="fas fa-user text-sm"></i>
                    <span>Tên người dùng</span>
                  </div>
                </th>
                <th class="px-6 py-4 text-left font-semibold uppercase text-sm">
                  <div class="flex items-center gap-2">
                    <i class="fas fa-user-tag text-sm"></i>
                    <span>Vai trò</span>
                  </div>
                </th>
                <th class="px-6 py-4 text-left font-semibold uppercase text-sm">
                  <div class="flex items-center gap-2">
                    <i class="fas fa-circle text-sm"></i>
                    <span>Trạng thái</span>
                  </div>
                </th>
                <th class="px-6 py-4 text-left font-semibold uppercase text-sm">
                  <div class="flex items-center gap-2">
                    <i class="fas fa-calendar-alt text-sm"></i>
                    <span>Ngày hết hạn</span>
                  </div>
                </th>
                <th class="px-6 py-4 text-left font-semibold uppercase text-sm">
                  <div class="flex items-center gap-2">
                    <i class="fas fa-tools text-sm"></i>
                    <span>Thao tác</span>
                  </div>
                </th>
              </tr>
            </thead>
            <tbody id="userTbody" class="divide-y divide-gray-200"></tbody>
          </table>
        </div>
      </div>

      <!-- Pagination -->
      <div id="pagination" class="flex flex-col sm:flex-row items-center justify-between mt-8 gap-4">
        <div id="pagInfo" class="text-sm text-gray-600 bg-gray-50 px-4 py-2 rounded-lg"></div>
        <div class="flex items-center gap-2">
          <button id="prevBtn" class="px-4 py-2 rounded-lg border border-gray-300 bg-white hover:bg-gray-50 transition-colors flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed">
            <i class="fas fa-chevron-left"></i>
            <span>Trước</span>
          </button>
          <div id="pageNums" class="flex items-center gap-1"></div>
          <button id="nextBtn" class="px-4 py-2 rounded-lg border border-gray-300 bg-white hover:bg-gray-50 transition-colors flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed">
            <span>Sau</span>
            <i class="fas fa-chevron-right"></i>
          </button>
          <div class="ml-3 flex items-center gap-2">
            <span class="text-sm text-gray-600">Hiển thị:</span>
            <select id="sizeSel" class="px-3 py-2 border border-gray-300 rounded-lg bg-white focus:ring-2 focus:ring-primary-500 focus:border-primary-500">
              <option>10</option><option>20</option><option>50</option>
            </select>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- Modal Xem / Sửa user -->
  <div id="userModal" class="fixed inset-0 bg-black/40 z-[9998] hidden items-center justify-center">
    <div class="bg-white rounded-2xl shadow-2xl w-full max-w-lg mx-4">
      <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200">
        <div class="flex items-center gap-3">
          <div class="h-9 w-9 rounded-full bg-primary-100 flex items-center justify-center text-primary-600">
            <i class="fas fa-user-cog"></i>
          </div>
          <div>
            <h3 id="modalTitle" class="text-lg font-semibold text-gray-800">Thông tin người dùng</h3>
            <p id="modalSubtitle" class="text-xs text-gray-500"></p>
          </div>
        </div>
        <button id="modalCloseBtn" class="text-gray-400 hover:text-gray-600">
          <i class="fas fa-times"></i>
        </button>
      </div>
      <div class="px-6 py-5 space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Tên đăng nhập</label>
          <input id="modalUsername" type="text" disabled
                 class="w-full px-3 py-2 rounded-lg border border-gray-300 bg-gray-100 text-gray-700">
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Email</label>
          <input id="modalEmail" type="email"
                 class="w-full px-3 py-2 rounded-lg border border-gray-300 focus:ring-2 focus:ring-primary-500 focus:border-primary-500">
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Vai trò</label>
            <select id="modalRole"
                    class="w-full px-3 py-2 rounded-lg border border-gray-300 focus:ring-2 focus:ring-primary-500 focus:border-primary-500">
              <option value="1">Admin</option>
              <option value="2">Librarian</option>
              <option value="3">Member</option>
            </select>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Trạng thái</label>
            <select id="modalStatus"
                    class="w-full px-3 py-2 rounded-lg border border-gray-300 focus:ring-2 focus:ring-primary-500 focus:border-primary-500">
              <option value="ACTIVE">ACTIVE</option>
              <option value="PENDING">PENDING</option>
              <option value="BANNED">BANNED</option>
            </select>
          </div>
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Ngày hết hạn</label>
          <input id="modalExpiry" type="text" disabled
                 class="w-full px-3 py-2 rounded-lg border border-gray-300 bg-gray-100 text-gray-700">
        </div>
      </div>
      <div class="px-6 py-4 border-t border-gray-200 flex items-center justify-between">
        <p class="text-xs text-gray-500">* Reset mật khẩu dùng nút "Reset" ở bảng danh sách.</p>
        <div class="flex items-center gap-2">
          <button id="modalCancelBtn"
                  class="px-4 py-2 rounded-lg border border-gray-300 bg-white text-gray-700 hover:bg-gray-50 text-sm">
            Đóng
          </button>
          <button id="modalSaveBtn"
                  class="px-4 py-2 rounded-lg bg-primary-600 text-white text-sm font-medium hover:bg-primary-700 shadow-md">
            Lưu thay đổi
          </button>
        </div>
      </div>
    </div>
  </div>

  <!-- Popup thông báo reset mật khẩu -->
  <div id="pwPopup"
       class="fixed inset-0 bg-black/40 backdrop-blur-sm hidden items-center justify-center z-50">
    <div class="bg-white rounded-2xl shadow-xl p-6 max-w-sm text-center fade-in">
      <h2 class="text-xl font-semibold text-gray-800 mb-3">Reset mật khẩu</h2>
      <p id="pwMsg" class="text-gray-600 mb-5"></p>
      <button onclick="closePwPopup()"
              class="px-5 py-2 bg-blue-600 text-white rounded-xl hover:bg-blue-500">
        Đóng
      </button>
    </div>
  </div>

  <!-- Popup confirm chung -->
  <div id="confirmPopup"
       class="fixed inset-0 bg-black/40 backdrop-blur-sm hidden items-center justify-center z-50">
    <div class="bg-white rounded-2xl shadow-xl p-6 max-w-sm text-center fade-in">
      <h2 class="text-lg font-semibold text-gray-800 mb-3">Xác nhận</h2>
      <p id="confirmMsg" class="text-gray-600 mb-5"></p>
      <div class="flex items-center justify-center gap-3">
        <button id="confirmCancelBtn"
                class="px-4 py-2 rounded-xl border border-gray-300 bg-white text-gray-700 hover:bg-gray-50">
          Hủy
        </button>
        <button id="confirmOkBtn"
                class="px-4 py-2 rounded-xl bg-red-600 text-white hover:bg-red-500">
          Xác nhận
        </button>
      </div>
    </div>
  </div>

  <!-- Toast nhỏ gọn -->
  <div id="toastContainer" class="fixed bottom-5 right-5 z-[9999] flex flex-col gap-3 pointer-events-none"></div>

  <script>
    // popup reset password
    const pwPopup = document.getElementById("pwPopup");
    const pwMsg   = document.getElementById("pwMsg");
    function showPwPopup(msg){
      pwMsg.textContent = msg;
      pwPopup.classList.remove("hidden");
      pwPopup.classList.add("flex");
    }
    function closePwPopup(){
      pwPopup.classList.add("hidden");
      pwPopup.classList.remove("flex");
    }

    // popup confirm chung
    const confirmPopup     = document.getElementById("confirmPopup");
    const confirmMsg       = document.getElementById("confirmMsg");
    const confirmOkBtn     = document.getElementById("confirmOkBtn");
    const confirmCancelBtn = document.getElementById("confirmCancelBtn");
    let confirmCallback    = null;

    function showConfirm(message, cb){
      confirmMsg.textContent = message;
      confirmCallback = cb || null;
      confirmPopup.classList.remove("hidden");
      confirmPopup.classList.add("flex");
    }
    function closeConfirm(){
      confirmPopup.classList.add("hidden");
      confirmPopup.classList.remove("flex");
      confirmCallback = null;
    }

    confirmCancelBtn.addEventListener("click", closeConfirm);
    confirmOkBtn.addEventListener("click", function(){
      const cb = confirmCallback;
      closeConfirm();
      if (typeof cb === "function") {
        cb();
      }
    });

    // toast
    const styles = {
      success: "bg-green-600 text-white",
      error:   "bg-red-600 text-white",
      warning: "bg-yellow-500 text-black",
      info:    "bg-blue-600 text-white"
    };
    function showToast(message, type="info", duration=2500){
      const c = document.getElementById("toastContainer");
      const t = document.createElement("div");
      var dyn = styles[type] || styles.info;
      t.className = 'pointer-events-auto max-w-sm rounded-lg shadow-lg px-4 py-3 ring-1 ring-black/10 '
                + dyn
                + ' transition opacity-0 translate-y-3 fade-in';
      var icon = (type==='success') ? 'check-circle'
         : (type==='error')   ? 'exclamation-triangle'
         : (type==='warning') ? 'exclamation-circle'
         : 'info-circle';

      var safeMsg = (typeof escapeHtml==="function") ? escapeHtml(message) : message;

      t.innerHTML = '<div class="flex items-center gap-2">'
                +   '<i class="fas fa-' + icon + '"></i>'
                +   '<span>' + safeMsg + '</span>'
                + '</div>';
      c.appendChild(t);
      requestAnimationFrame(()=>{ t.classList.remove("opacity-0","translate-y-3"); t.classList.add("opacity-100","translate-y-0");});
      setTimeout(()=>{ t.classList.add("opacity-0","translate-y-3"); setTimeout(()=>t.remove(),200); }, duration);
    }
  </script>

  <script>
  (function(){
    const ctx     = '<%=request.getContextPath()%>';
    const apiList = ctx + '/api/admin/users';      // API phân trang
    const apiUser = ctx + '/api/admin/am-users';   // API xem / sửa / xóa / reset

    // DOM
    const tbody      = document.getElementById('userTbody');
    const filterForm = document.getElementById('filterForm');
    const searchInp  = document.getElementById('searchUsername');
    const roleSel    = document.getElementById('filterRole');
    const clearBtn   = document.getElementById('clearBtn');
    const prevBtn    = document.getElementById('prevBtn');
    const nextBtn    = document.getElementById('nextBtn');
    const sizeSel    = document.getElementById('sizeSel');
    const pageNums   = document.getElementById('pageNums');
    const pagInfo    = document.getElementById('pagInfo');
    const totalUsers = document.getElementById('totalUsers');

    // Modal DOM
    const userModal      = document.getElementById('userModal');
    const modalTitle     = document.getElementById('modalTitle');
    const modalSubtitle  = document.getElementById('modalSubtitle');
    const modalCloseBtn  = document.getElementById('modalCloseBtn');
    const modalCancelBtn = document.getElementById('modalCancelBtn');
    const modalSaveBtn   = document.getElementById('modalSaveBtn');

    const modalUsername  = document.getElementById('modalUsername');
    const modalEmail     = document.getElementById('modalEmail');
    const modalRole      = document.getElementById('modalRole');
    const modalStatus    = document.getElementById('modalStatus');
    const modalExpiry    = document.getElementById('modalExpiry');

    let currentUserId = null;
    let modalMode = 'view'; // 'view' | 'edit'

    // State từ URL
    const url = new URL(location.href);
    let page = parseInt(url.searchParams.get('page')||'1',10);
    let size = parseInt(url.searchParams.get('size')||'10',10);
    let searchUsername = url.searchParams.get('searchUsername') || '';
    let filterRole = url.searchParams.get('filterRole') || '';

    // set form inputs
    searchInp.value = searchUsername;
    roleSel.value   = filterRole;
    sizeSel.value   = String(size);

    function setQuery(params){
      const u = new URL(location.href);
      Object.keys(params).forEach(k=>{
        const v = params[k];
        if (v===undefined || v===null || v==='') u.searchParams.delete(k);
        else u.searchParams.set(k, v);
      });
      history.replaceState({}, "", u.toString());
    }

    function escapeHtml(s){
      return (s??'').replace(/[&<>"']/g, m=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[m]));
    }
    function escapeReg(s){
      const cls = "[.*+?^" + "$" + "{}()|[\\]\\\\]"; // ký tự đặc biệt regex
      return s.replace(new RegExp(cls, "g"), "\\$&");
    }
    function mark(str, q){
      if (!q) return escapeHtml(str);
      const re = new RegExp('(' + escapeReg(q) + ')', 'ig');
      return escapeHtml(str).replace(re, "<mark class='bg-yellow-200 px-1 rounded'>$1</mark>");
    }
    // cho showToast dùng được
    window.escapeHtml = escapeHtml;

    async function fetchUsers(){
      try{
        const params = new URLSearchParams();
        if (searchUsername) params.set("searchUsername", searchUsername);
        if (filterRole)     params.set("filterRole", filterRole);
        params.set("page", page);
        params.set("size", size);

        const r = await fetch(apiList + "?" + params.toString(), {
          headers: { "Accept": "application/json" }
        });

        const data = await r.json();

        if (!r.ok || !data.ok) throw new Error((data && data.message) ? data.message : ("HTTP " + r.status));

        renderTable(data.items || []);
        renderPagination(data.page, data.size, data.total, data.totalPages);
        setQuery({ searchUsername: searchUsername, filterRole: filterRole, page: page, size: size });

        // Update total users count
        totalUsers.textContent = data.total || 0;

        if (!(data.items || []).length){
          showToast("Không có kết quả phù hợp.", "warning");
        }
      } catch(e){
        console.error(e);
        showToast(e.message || "Không tải được danh sách.", "error");
      }
    }

    function renderTable(items){
      tbody.innerHTML = '';
      if (!items.length){
        var msg = (searchUsername || filterRole)
          ? "Không tìm thấy người dùng nào phù hợp với điều kiện lọc"
          : "Chưa có người dùng nào";

        var linkAll = '';
        if (searchUsername || filterRole){
          linkAll = '<a href="?" class="text-primary-600 hover:text-primary-800 underline mt-2 inline-flex items-center gap-1"><i class="fas fa-list"></i> Xem tất cả người dùng</a>';
        }

        var html =
          '<tr>' +
            '<td colspan="6" class="px-6 py-12 text-center text-gray-500">' +
              '<div class="flex flex-col items-center gap-3">' +
                '<div class="bg-gray-100 p-4 rounded-full"><i class="fas fa-users text-4xl text-gray-400"></i></div>' +
                '<p class="text-lg">' + msg + '</p>' +
                linkAll +
              '</div>' +
            '</td>' +
          '</tr>';
        tbody.innerHTML = html;
        return;
      }
      items.forEach(function(u, idx){
        var roleCls= (u.roleID===1)?'bg-red-100 text-red-800':(u.roleID===2)?'bg-blue-100 text-blue-800':'bg-green-100 text-green-800';
        var stCls  = (u.status==='ACTIVE')?'bg-green-100 text-green-800':(u.status==='PENDING')?'bg-yellow-100 text-yellow-800':'bg-red-100 text-red-800';
        var exp    = (!u.expiryDate || u.expiryDate==='') ? "<span class='text-primary-600 font-medium'>Vĩnh viễn</span>" : escapeHtml(u.expiryDate);

        var delay = (idx * 0.05) + 's';
        var roleIcon = (u.roleID===1) ? 'crown' : (u.roleID===2) ? 'user-shield' : 'user';
        var statusIcon = (u.status==='ACTIVE') ? 'check-circle' : (u.status==='PENDING') ? 'clock' : 'exclamation-circle';

        var row  = ''
          + '<tr class="table-row-hover transition-all duration-200 fade-in" style="animation-delay: ' + delay + '">'
          +   '<td class="px-6 py-4 font-medium text-gray-900">' + u.id + '</td>'
          +   '<td class="px-6 py-4 text-gray-800">' + mark(u.username||'', searchUsername) + '</td>'
          +   '<td class="px-6 py-4">'
          +     '<span class="px-3 py-1.5 rounded-full text-sm font-medium ' + roleCls + ' inline-flex items-center gap-1">'
          +       '<i class="fas fa-' + roleIcon + ' text-xs"></i>' + (u.roleText||'')
          +     '</span>'
          +   '</td>'
          +   '<td class="px-6 py-4">'
          +     '<span class="px-3 py-1.5 rounded-full text-sm font-medium ' + stCls + ' inline-flex items-center gap-1">'
          +       '<i class="fas fa-' + statusIcon + ' text-xs"></i>' + escapeHtml(u.status||'')
          +     '</span>'
          +   '</td>'
          +   '<td class="px-6 py-4 text-gray-600">' + exp + '</td>'
          +   '<td class="px-6 py-4 text-right space-x-2">'
          +     '<button onclick="viewUser('+u.id+')" class="px-2 py-1 text-blue-600 hover:underline text-sm"><i class="fas fa-eye mr-1"></i>Xem</button>'
          +     '<button onclick="editUser('+u.id+')" class="px-2 py-1 text-yellow-600 hover:underline text-sm"><i class="fas fa-edit mr-1"></i>Sửa</button>'
          +     '<button onclick="resetPw('+u.id+')" class="px-2 py-1 text-purple-600 hover:underline text-sm"><i class="fas fa-key mr-1"></i>Reset</button>'
          +   '</td>'
          + '</tr>';
        tbody.insertAdjacentHTML('beforeend', row);
      });
    }

    function renderPagination(curPage, curSize, total, totalPages){
      const start = total===0 ? 0 : ((curPage-1)*curSize + 1);
      const end   = Math.min(curPage*curSize, total);
      pagInfo.textContent = 'Hiển thị ' + start + '-' + end + ' / ' + total;

      prevBtn.disabled = (curPage<=1);
      nextBtn.disabled = (curPage>=totalPages || totalPages===0);

      pageNums.innerHTML = "";
      const pages = calcWindow(curPage, totalPages, 7);
      pages.forEach(p=>{
        if (p==="…"){
          pageNums.insertAdjacentHTML("beforeend", '<span class="px-3 py-2 text-gray-400">…</span>');
        } else {
          const btn = document.createElement("button");
          btn.textContent = p;
          btn.className = "px-3 py-2 rounded-lg border transition-all duration-200 " + (p===curPage ? "bg-primary-600 text-white border-primary-600 shadow-md" : "bg-white hover:bg-gray-50 border-gray-300");
          btn.addEventListener("click", ()=>{ page = p; fetchUsers(); window.scrollTo({top:0,behavior:'smooth'}); });
          pageNums.appendChild(btn);
        }
      });
    }
    function calcWindow(cur, total, width){
      if (total<=width) return Array.from({length: total}, (_,i)=> i+1);
      const half = Math.floor(width/2);
      let start = Math.max(1, cur - half);
      let end   = Math.min(total, start + width -1);
      start = Math.max(1, end - width + 1);

      const arr = [];
      if (start>1){ arr.push(1); if (start>2) arr.push("…"); }
      for(let i=start;i<=end;i++) arr.push(i);
      if (end<total){ if (end<total-1) arr.push("…"); arr.push(total); }
      return arr;
    }

    // -------- Modal helpers --------
    function openModal(){
      userModal.classList.remove('hidden');
      userModal.classList.add('flex');
    }
    function closeModal(){
      userModal.classList.add('hidden');
      userModal.classList.remove('flex');
    }
    function setupModalMode(mode, user){
      modalMode = mode;
      modalSubtitle.textContent = 'User ID: ' + user.id;
      modalUsername.value = user.username || '';
      modalEmail.value    = user.email || '';
      modalRole.value     = String(user.roleID || 3);
      modalStatus.value   = user.status || 'ACTIVE';
      modalExpiry.value   = user.expiryDate ? user.expiryDate : 'Vĩnh viễn';

      const isView = (mode === 'view');
      modalTitle.textContent = isView ? 'Thông tin người dùng' : 'Chỉnh sửa người dùng';

      modalEmail.disabled  = isView;
      modalRole.disabled   = isView;
      modalStatus.disabled = isView;

      modalEmail.classList.toggle('bg-gray-100', isView);
      modalRole.classList.toggle('bg-gray-100', isView);
      modalStatus.classList.toggle('bg-gray-100', isView);

      if (isView){
        modalSaveBtn.classList.add('hidden');
      } else {
        modalSaveBtn.classList.remove('hidden');
      }
    }

    async function openUserModal(id, mode){
      try{
        const r = await fetch(apiUser + "/" + id, { headers: {"Accept":"application/json"} });
        const d = await r.json();
        if (!r.ok || !d || d.ok === false){
          showToast((d && d.message) || 'Không lấy được thông tin user', 'error');
          return;
        }
        currentUserId = d.id;
        setupModalMode(mode, d);
        openModal();
      } catch(e){
        console.error(e);
        showToast('Lỗi khi tải thông tin người dùng', 'error');
      }
    }

    // -------- Các hàm gọi API, gán ra window để onclick dùng được --------
    window.viewUser = function(id){
      openUserModal(id, 'view');
    };

    window.editUser = function(id){
      openUserModal(id, 'edit');
    };

    window.resetPw = function(id){
      showConfirm("Reset mật khẩu user này?\nMật khẩu mới sẽ được gửi qua email.", async function(){
        try{
          const r = await fetch(apiUser + "/reset/" + id, { method:"POST" });
          const d = await r.json();

          if(!r.ok){
            showToast((d && d.message) || "Reset mật khẩu thất bại","error");
          } else {
            showPwPopup("Đã reset mật khẩu. Vui lòng kiểm tra email.");
            showToast("Đã reset mật khẩu","success");
          }
        } catch(e){
          console.error(e);
          showToast("Lỗi khi reset mật khẩu","error");
        }
      });
    };

    window.deleteUser = function(id){
      showConfirm("Bạn chắc chắn xóa user này?", async function(){
        try{
          const r = await fetch(apiUser + "/" + id, { method:"DELETE" });
          const d = await r.json();
          if(!r.ok){
            showToast((d && d.message) || "Xóa thất bại","error");
          } else{
            showToast("Đã xóa user","success");
            fetchUsers();
          }
        }catch(e){
          console.error(e);
          showToast("Lỗi khi xóa user","error");
        }
      });
    };

    // lưu trong modal (edit mode)
    async function saveUserEdit(){
      if (!currentUserId) return;
      const email  = modalEmail.value.trim();
      const status = modalStatus.value.trim();
      const roleID = Number(modalRole.value);

      if (!email){
        showToast("Email không được để trống","warning");
        return;
      }

      try{
        const r = await fetch(apiUser + "/" + currentUserId, {
          method: "PUT",
          headers: {
            "Content-Type": "application/json"
          },
          body: JSON.stringify({ email, status, roleID })
        });
        const d = await r.json();
        if(!r.ok){
          showToast((d && d.message) || "Cập nhật thất bại","error");
        } else{
          showToast("Cập nhật thành công","success");
          closeModal();
          fetchUsers();
        }
      }catch(e){
        console.error(e);
        showToast("Lỗi khi cập nhật user","error");
      }
    }

    // events modal
    modalCloseBtn.addEventListener('click', closeModal);
    modalCancelBtn.addEventListener('click', closeModal);
    modalSaveBtn.addEventListener('click', saveUserEdit);
    userModal.addEventListener('click', (e)=>{
      if (e.target === userModal) closeModal();
    });

    // events filter / paging
    filterForm.addEventListener("submit", (e)=>{
      e.preventDefault();
      searchUsername = searchInp.value.trim();
      filterRole = roleSel.value.trim();
      page = 1;
      fetchUsers();
    });
    roleSel.addEventListener("change", ()=> filterForm.requestSubmit());

    clearBtn.addEventListener("click", ()=>{
      searchInp.value=""; roleSel.value="";
      searchUsername=""; filterRole=""; page=1;
      fetchUsers();
    });

    prevBtn.addEventListener("click", ()=>{
      if (page>1){ page--; fetchUsers(); }
    });
    nextBtn.addEventListener("click", ()=>{
      page++; fetchUsers();
    });

    sizeSel.addEventListener("change", ()=>{
      size = parseInt(sizeSel.value, 10) || 10;
      page = 1;
      fetchUsers();
    });

    // khởi động
    fetchUsers();
  })();
  </script>
</body>
</html>
