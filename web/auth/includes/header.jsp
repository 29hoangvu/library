<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="Data.Users" %>
<%@ page import="java.sql.*" %>
<%@ page import="Servlet.DBConnection" %>
<script src="<%=request.getContextPath()%>/static/js/api.js"></script>
<script>
(async () => {
  const CTX = "<%=request.getContextPath()%>";
  // Lấy hàm từ UMD: window.api
  const { currentUser, apiGet, clearToken } = window.api || {};

  if (!currentUser) {
    console.error("api.js chưa load đúng (không có window.api).");
    location.href = CTX + "/user/login.jsp";
    return;
  }

  try {
    // 1) Xác thực qua JWT
    const me = await currentUser(); // GET /Library/api/auth/me (đã gắn Bearer trong api.js)
    const rid = (me.roleID ?? me.roleId);

    // Chỉ cho roleID 1 hoặc 2
    if (!(rid === 1 || rid === 2)) {
      location.href = CTX + "/index.jsp";
      return;
    }

    // 2) Render thông tin user lên header
    const username = me.username || "User";
    const email    = me.email    || "user@example.com";
    const initial  = username.charAt(0).toUpperCase();

    const $ = (s) => document.querySelector(s);
    $("#headerAvatarInitial") && ($("#headerAvatarInitial").textContent = initial);
    $("#headerUsername")      && ($("#headerUsername").textContent      = username);
    $("#headerEmail")         && ($("#headerEmail").textContent         = email);

    // ADMIN-only menu
    if (rid === 1) {
      const adminMenu = document.getElementById("adminOnlyMenu");
      adminMenu && adminMenu.classList.remove("hidden");
    }

    // 3) Lấy stats (nếu có API /api/stats)
    try {
      const stats = await apiGet("/stats");
      if (stats) {
        const tb = document.getElementById("totalBooks");
        const br = document.getElementById("totalBorrowed");
        if (tb) tb.textContent = stats.totalBooks ?? 0;
        if (br) br.textContent = stats.totalBorrowed ?? 0;
      }
    } catch (e) {
      console.warn("Không load được stats:", e);
    }

    // 4) Logout: xoá token + về login
    const logout = document.getElementById("logoutBtn");
    if (logout) {
      logout.addEventListener("click", (ev) => {
        ev.preventDefault();
        // dùng clearToken đã destructuring ở trên
        clearToken && clearToken();
        localStorage.removeItem("user");
        location.href = CTX + "/index.jsp";
      });
    }

  } catch (err) {
    console.error("Auth failed:", err);
    // Token hết hạn/chưa đăng nhập
    clearToken && clearToken();
    location.href = CTX + "/index.jsp";
  }
})();
</script>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <title><%= request.getAttribute("pageTitle") != null ? request.getAttribute("pageTitle") : "Trang quản trị"%></title>
    <link rel="icon" href="./images/reading-book.png" type="image/x-icon" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" />
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <link rel="stylesheet" href="../admin.css"/>
</head>

<%@ include file="searchBook.jspf" %>

<body class="admin-gradient">
    <!-- Floating particles -->
    <div class="particle p1"></div>
    <div class="particle p2"></div>
    <div class="particle p3"></div>
    <div class="particle p4"></div>

    <!-- Backdrop overlay cho sidebar -->
    <div id="sidebarBackdrop" class="fixed inset-0 bg-black bg-opacity-40 z-40 hidden"></div>

    <!-- Navbar -->
    <header class="glass-header text-white fixed top-0 left-0 w-full z-50">
        <!-- Main header bar -->
        <div class="px-6 py-4 flex justify-between items-center">
            <div class="flex items-center gap-4">
                <button id="toggleSidebarBtn"
                        class="btn-glow hover-tilt text-white/90 bg-white/5 border border-white/15 px-2 py-2 rounded-xl transition-colors focus:outline-none">
                    <svg class="w-6 h-6 icon-soft-pulse" fill="none" stroke="currentColor" stroke-width="2"
                         viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M4 6h16M4 12h16M4 18h16" />
                    </svg>
                </button>
                <h1 class="text-xl md:text-2xl font-extrabold neon-title flex items-center gap-2">
                    <span class="inline-flex items-center justify-center w-9 h-9 rounded-2xl bg-white/10 shadow-lg shadow-sky-500/40">
                        📚
                    </span>
                    <span>Quản lý thư viện</span>
                </h1>
            </div>

            <!-- Search bar -->
            <div class="hidden md:flex items-center flex-1 max-w-md mx-8">
                <form action="adminDashboard.jsp" method="GET" class="relative w-full glass-card-soft rounded-2xl">
                    <input type="text" name="search"
                           value="<%= request.getParameter("search") != null ? request.getParameter("search") : ""%>"
                           placeholder="Tìm kiếm sách, tác giả..."
                           class="w-full bg-transparent border border-white/10 rounded-2xl px-4 py-2 pl-10 text-sm text-slate-50 placeholder-slate-300/70 focus:outline-none focus:ring-2 focus:ring-sky-300 focus:border-sky-300">

                    <svg class="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-sky-200" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                              d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
                    </svg>
                </form>
            </div>

            <!-- Right side - notifications and user -->
            <div class="flex items-center gap-3">
                <!-- Notifications -->
                <div class="relative">
                    <button onclick="toggleNotifications()"
                            class="btn-glow hover-tilt text-white/90 bg-white/10 border border-white/15 px-2 py-2 rounded-2xl transition-colors focus:outline-none relative">
                        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                  d="M15 17h5l-5 5v-5zM10.07 2.82a8 8 0 0 1 7.9 7.9M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0z"></path>
                        </svg>
                        <span class="absolute -top-1 -right-1 badge-ripple bg-rose-500 text-[10px] rounded-full h-5 w-5 flex items-center justify-center font-semibold shadow-lg shadow-rose-500/70">
                            3
                        </span>
                    </button>
                    <div id="notificationDropdown"
                         class="hidden glass-dropdown absolute right-0 top-12 text-gray-100 rounded-2xl py-2 w-80 z-50 max-h-96 overflow-y-auto">
                        <div class="px-4 py-2 border-b border-white/10 font-semibold text-slate-100 text-sm flex items-center justify-between">
                            <span>Thông báo</span>
                            <span class="text-xs px-2 py-0.5 rounded-full bg-sky-500/20 text-sky-200 border border-sky-400/40">
                                Live
                            </span>
                        </div>
                        <a href="#" class="block px-4 py-3 hover:bg-white/5 border-l-4 border-sky-500 text-sm transition-colors">
                            <div class="font-medium">Sách mới được thêm</div>
                            <div class="text-xs text-sky-200/80 mt-0.5">2 phút trước</div>
                        </a>
                        <a href="#" class="block px-4 py-3 hover:bg-white/5 border-l-4 border-amber-400 text-sm transition-colors">
                            <div class="font-medium">Sách sắp hết hạn trả</div>
                            <div class="text-xs text-slate-300/80 mt-0.5">1 giờ trước</div>
                        </a>
                        <a href="#" class="block px-4 py-3 hover:bg-white/5 border-l-4 border-emerald-400 text-sm transition-colors">
                            <div class="font-medium">Người dùng mới đăng ký</div>
                            <div class="text-xs text-slate-300/80 mt-0.5">3 giờ trước</div>
                        </a>
                        <div class="px-4 py-2 border-t border-white/10 text-center">
                            <a href="#" class="text-sky-300 text-xs hover:underline">Xem tất cả thông báo</a>
                        </div>
                    </div>
                </div>

                <!-- Quick stats -->
                <div class="hidden lg:flex items-center gap-4 px-4 py-2 glass-card-soft rounded-2xl text-slate-50 text-xs border border-white/20">
                    <div class="text-center min-w-[64px]">
                        <div class="text-[11px] text-sky-200/80 uppercase tracking-wide">Sách</div>
                        <div class="font-extrabold text-base mt-0.5" id="totalBooks">0</div>
                    </div>
                    <div class="h-8 w-px bg-white/15"></div>
                    <div class="text-center min-w-[80px]">
                        <div class="text-[11px] text-emerald-200/80 uppercase tracking-wide">Đang mượn</div>
                        <div class="font-extrabold text-base mt-0.5" id="totalBorrowed">0</div>
                    </div>
                </div>

                <!-- User menu -->
                <div class="relative">
                    <div onclick="toggleHeaderUserMenu()"
                         class="cursor-pointer flex items-center gap-2 px-3 py-2 hover:bg-white/10 rounded-2xl transition-colors hover-tilt">
                        <div class="w-9 h-9 bg-gradient-to-br from-indigo-400 via-sky-400 to-fuchsia-500 rounded-full flex items-center justify-center ring-2 ring-sky-200/80 shadow-lg shadow-sky-500/60">
                            <span id="headerAvatarInitial" class="text-sm font-bold text-slate-900">U</span>
                        </div>
                        <div class="hidden sm:block text-left">
                            <div id="headerUsername" class="text-sm font-semibold">User</div>
                            <div class="text-[11px] text-slate-100/80 uppercase tracking-wide">Administrator</div>
                        </div>
                        <span id="headerArrowIcon" class="ml-1 text-xs">▼</span>
                    </div>
                    <div id="headerUserDropdown"
                         class="hidden glass-dropdown absolute right-0 top-12 rounded-2xl py-2 w-56 z-50 text-sm">
                        <div class="px-4 py-3 border-b border-white/10">
                            <div id="headerEmail" class="text-xs text-slate-200/90 break-all">user@example.com</div>
                        </div>
                        <a href="#" class="flex items-center gap-3 px-4 py-2 hover:bg-white/5">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                      d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path>
                            </svg>
                            Thông tin cá nhân
                        </a>
                        <a href="#" class="flex items-center gap-3 px-4 py-2 hover:bg-white/5">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                      d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path>
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                      d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                            </svg>
                            Cài đặt
                        </a>
                        <div class="border-t border-white/10 my-1"></div>
                        <a href="#" id="logoutBtn"
                           class="flex items-center gap-3 px-4 py-2 text-red-400 hover:bg-white/5">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                      d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"></path>
                            </svg>
                            Đăng xuất
                        </a>
                    </div>
                </div>
            </div>
        </div>

        <!-- Breadcrumb bar -->
        <div class="px-6 py-2 glass-breadcrumb">
            <nav class="flex items-center gap-2 text-xs md:text-sm">
                <a href="${pageContext.request.contextPath}/auth/lib/adminDashboard.jsp"
                   class="text-sky-200 hover:text-sky-50 transition-colors flex items-center gap-1">
                    <span>🏠</span>
                    <span>Dashboard</span>
                </a>
                <span class="text-sky-300/70">›</span>
                <span class="text-slate-50 font-medium" id="currentPageBreadcrumb">Thêm sách mới</span>
            </nav>
        </div>
    </header>

    <!-- Sidebar Nổi -->
    <aside id="sidebar"
           class="fixed top-32 left-0 w-64 h-[calc(100%-8rem)] glass-sidebar text-slate-100 transition-transform duration-300 z-50 px-4 py-6 overflow-y-auto border-r border-slate-700/80 transform -translate-x-full rounded-tr-3xl rounded-br-3xl">
        <div class="flex items-center justify-between mb-6 px-1">
            <h2 class="text-xl font-bold text-slate-50 flex items-center gap-2">
                <span class="w-7 h-7 rounded-xl bg-indigo-500/40 flex items-center justify-center text-sm">📘</span>
                <span>Menu</span>
            </h2>
            <button id="closeSidebarBtn"
                    class="lg:hidden text-slate-300 hover:text-slate-50 p-1 rounded-lg bg-slate-900/60 border border-slate-600/80">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                          d="M6 18L18 6M6 6l12 12"></path>
                </svg>
            </button>
        </div>

        <ul class="space-y-2 text-sm font-medium">
            <li>
                <a href="${pageContext.request.contextPath}/auth/lib/adminDashboard.jsp"
                   class="menu-link card-3d flex items-center gap-3 px-4 py-3 rounded-2xl hover:bg-slate-900/80 border border-slate-700/60 transition-colors">
                    <i class="fas fa-tachometer-alt w-4 text-sky-400"></i>
                    <span>Dashboard</span>
                </a>
            </li>

            <li>
                <a href="${pageContext.request.contextPath}/auth/lib/admin.jsp"
                   class="menu-link card-3d flex items-center gap-3 px-4 py-3 rounded-2xl hover:bg-slate-900/80 border border-slate-700/60 transition-colors">
                    <i class="fas fa-plus-circle w-4 text-emerald-400"></i>
                    <span>Thêm sách</span>
                </a>
            </li>

            <li>
                <a href="${pageContext.request.contextPath}/auth/lib/addBookItem.jsp"
                   class="menu-link card-3d flex items-center gap-3 px-4 py-3 rounded-2xl hover:bg-slate-900/80 border border-slate-700/60 transition-colors">
                    <i class="fas fa-map-marker-alt w-4 text-purple-400"></i>
                    <span>Vị trí sách</span>
                </a>
            </li>

            <li id="adminOnlyMenu" class="hidden">
                <details class="group card-3d rounded-2xl border border-slate-700/60 bg-slate-900/60">
                    <summary class="flex items-center justify-between cursor-pointer px-4 py-3 rounded-2xl hover:bg-slate-900/90 transition-colors">
                        <div class="flex items-center gap-3">
                            <i class="fas fa-users-cog w-4 text-orange-400"></i>
                            <span>Quản lý người dùng</span>
                        </div>
                        <i class="fas fa-chevron-down text-xs group-open:rotate-180 transition-transform text-slate-400"></i>
                    </summary>
                    <div class="ml-6 mt-2 space-y-1 border-l-2 border-slate-600 pl-4 pb-3">
                        <a href="../admin/manageUsers.jsp"
                           class="flex items-center gap-2 px-4 py-2 rounded-xl hover:bg-slate-900/80 transition text-xs">
                            <i class="fas fa-list-ul text-indigo-400"></i>
                            <span>Danh sách người dùng</span>
                        </a>
                        <a href="../admin/createUser.jsp"
                           class="flex items-center gap-2 px-4 py-2 rounded-xl hover:bg-slate-900/80 transition text-xs">
                            <i class="fas fa-user-plus text-emerald-400"></i>
                            <span>Tạo tài khoản</span>
                        </a>
                        <a href="../admin/approveUsers.jsp"
                           class="flex items-center gap-2 px-4 py-2 rounded-xl hover:bg-slate-900/80 transition text-xs">
                            <i class="fas fa-user-check text-sky-400"></i>
                            <span>Duyệt tài khoản</span>
                        </a>
                    </div>
                </details>
            </li>

            <!-- Menu có submenu -->
            <li>
                <details class="group card-3d rounded-2xl border border-slate-700/60 bg-slate-900/60">
                    <summary class="flex items-center justify-between cursor-pointer px-4 py-3 rounded-2xl hover:bg-slate-900/90 transition-colors">
                        <div class="flex items-center gap-3">
                            <i class="fas fa-book-reader w-4 text-indigo-400"></i>
                            <span>Quản lý mượn trả sách</span>
                        </div>
                        <i class="fas fa-chevron-down text-xs group-open:rotate-180 transition-transform text-slate-400"></i>
                    </summary>
                    <div class="ml-6 mt-2 space-y-1 border-l-2 border-slate-600 pl-4 pb-3">
                        <a href="${pageContext.request.contextPath}/auth/lib/adminBorrowedBooks.jsp"
                           class="flex items-center gap-2 px-4 py-2 rounded-xl hover:bg-slate-900/80 transition text-xs">
                            <i class="fas fa-book text-teal-300"></i>
                            <span>Mượn/ Trả sách</span>
                        </a>
                        <a href="${pageContext.request.contextPath}/auth/lib/borrowList.jsp"
                           class="flex items-center gap-2 px-4 py-2 rounded-xl hover:bg-slate-900/80 transition text-xs">
                            <i class="fas fa-check-circle text-emerald-300"></i>
                            <span>Duyệt mượn sách</span>
                        </a>
                        <a href="${pageContext.request.contextPath}/auth/lib/adminReports.jsp"
                           class="flex items-center gap-2 px-4 py-2 rounded-xl hover:bg-slate-900/80 transition text-xs">
                            <i class="fas fa-chart-bar text-sky-300"></i>
                            <span>Thống kê</span>
                        </a>
                    </div>
                </details>
            </li>
        </ul>

        <!-- Quick actions ở cuối sidebar -->
        <div class="mt-8 pt-4 border-t border-slate-700/80">
            <p class="text-[11px] text-slate-400 mb-3 px-2 uppercase tracking-wide">Thao tác nhanh</p>
            <div class="space-y-2">
                <button
                    class="shimmer card-3d w-full flex items-center gap-2 px-3 py-2 text-xs bg-gradient-to-r from-indigo-500/80 via-sky-500/80 to-fuchsia-500/80 text-slate-50 rounded-2xl border border-slate-200/40 hover:shadow-xl hover:shadow-indigo-500/50">
                    <i class="fas fa-plus text-[10px]"></i>
                    <span>Tạo mới</span>
                </button>
                <button
                    class="card-3d w-full flex items-center gap-2 px-3 py-2 text-xs bg-slate-900/70 text-slate-100 rounded-2xl border border-slate-700/70 hover:bg-slate-900/90">
                    <i class="fas fa-search text-[10px] text-sky-300"></i>
                    <span>Tìm kiếm</span>
                </button>
            </div>
        </div>
    </aside>

    <script>
        const sidebar = document.getElementById('sidebar');
        const sidebarBackdrop = document.getElementById('sidebarBackdrop');
        const toggleSidebarBtn = document.getElementById('toggleSidebarBtn');
        const closeSidebarBtn = document.getElementById('closeSidebarBtn');
        const headerUserDropdown = document.getElementById('headerUserDropdown');
        const headerArrowIcon = document.getElementById('headerArrowIcon');
        const notificationDropdown = document.getElementById('notificationDropdown');

        // Mở sidebar
        function openSidebar() {
            sidebar.classList.remove('-translate-x-full');
            sidebarBackdrop.classList.remove('hidden');
            document.body.style.overflow = 'hidden'; // Ngăn scroll khi sidebar mở
        }

        // Đóng sidebar
        function closeSidebar() {
            sidebar.classList.add('-translate-x-full');
            sidebarBackdrop.classList.add('hidden');
            document.body.style.overflow = ''; // Khôi phục scroll
        }

        // Toggle sidebar
        toggleSidebarBtn?.addEventListener('click', (e) => {
            e.stopPropagation();
            if (sidebar.classList.contains('-translate-x-full')) {
                openSidebar();
            } else {
                closeSidebar();
            }
        });

        // Đóng sidebar khi click nút close
        closeSidebarBtn?.addEventListener('click', closeSidebar);

        // Đóng sidebar khi click backdrop
        sidebarBackdrop?.addEventListener('click', closeSidebar);

        // Toggle user menu ở header
        function toggleHeaderUserMenu() {
            headerUserDropdown.classList.toggle('hidden');
            headerArrowIcon.textContent = headerUserDropdown.classList.contains('hidden') ? '▼' : '▲';
            // Đóng notification dropdown
            notificationDropdown.classList.add('hidden');
        }

        // Toggle notifications
        function toggleNotifications() {
            notificationDropdown.classList.toggle('hidden');
            // Đóng user dropdown
            headerUserDropdown.classList.add('hidden');
            headerArrowIcon.textContent = '▼';
        }

        // Đóng dropdown khi click bên ngoài
        document.addEventListener('click', (e) => {
            const inUserMenu = e.target.closest('#headerUserDropdown') || e.target.closest('#logoutBtn');
            const inUserToggle = e.target.closest('[onclick*="toggleHeaderUserMenu"]');
            const inNotif = e.target.closest('#notificationDropdown');
            const inNotifToggle = e.target.closest('[onclick*="toggleNotifications"]');
            const isSidebarClick = e.target.closest('#sidebar') || e.target.closest('#toggleSidebarBtn');

            // ngoài user menu + toggle -> đóng user dropdown
            if (!inUserMenu && !inUserToggle) {
                headerUserDropdown.classList.add('hidden');
                headerArrowIcon.textContent = '▼';
            }
            // ngoài notif + toggle -> đóng notif
            if (!inNotif && !inNotifToggle) {
                notificationDropdown.classList.add('hidden');
            }

            // Đóng sidebar khi click bên ngoài (trừ khi click vào sidebar hoặc nút toggle)
            if (!isSidebarClick && !sidebar.classList.contains('-translate-x-full')) {
                closeSidebar();
            }
        });

        // Update breadcrumb based on current page
        function updateBreadcrumb() {
            const currentPage = window.location.pathname.split('/').pop();
            const breadcrumbElement = document.getElementById('currentPageBreadcrumb');

            const pageNames = {
                'admin.jsp': 'Thêm sách mới',
                'adminDashboard.jsp': 'Dashboard',
                'addBookItem.jsp': 'Vị trí sách',
                'createUser.jsp': 'Quản lý người dùng',
                'adminBorrowedBooks.jsp': 'Quản lý mượn trả sách'
            };

            if (breadcrumbElement && pageNames[currentPage]) {
                breadcrumbElement.textContent = pageNames[currentPage];
            }
        }

        // Xử lý phím ESC để đóng sidebar
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && !sidebar.classList.contains('-translate-x-full')) {
                closeSidebar();
            }
        });

        // Khởi tạo
        updateBreadcrumb();

        // Đảm bảo sidebar đóng khi load trang
        window.addEventListener('load', () => {
            closeSidebar();
        });
    </script>
</body>
</html>
