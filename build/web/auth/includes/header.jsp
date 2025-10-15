<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="Data.Users" %>
<%@ page import="java.sql.*" %>
<%@ page import="Servlet.DBConnection" %>
<%
    Users user = (Users) session.getAttribute("user");
    if (user == null || (user.getRoleID() != 1 && user.getRoleID() != 2)) {
        response.sendRedirect("../../index.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="vi">
    <head>
        <meta charset="UTF-8">
        <title><%= request.getAttribute("pageTitle") != null ? request.getAttribute("pageTitle") : "Trang quản trị"%></title>
        <link rel="icon" href="./images/reading-book.png" type="image/x-icon" />
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" />
        <script src="https://cdn.tailwindcss.com"></script>
        <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

    </head>

    <%@ include file="headerData.jspf" %>
    <%@ include file="searchBook.jspf" %>

    <body class="bg-gray-100">
        <!-- Backdrop overlay cho sidebar -->
        <div id="sidebarBackdrop" class="fixed inset-0 bg-black bg-opacity-50 z-40 hidden"></div>

        <!-- Navbar -->
        <header class="bg-gradient-to-r from-blue-700 to-blue-800 text-white shadow-lg fixed top-0 left-0 w-full z-50">
            <!-- Main header bar -->
            <div class="px-6 py-4 flex justify-between items-center">
                <div class="flex items-center gap-4">
                    <button id="toggleSidebarBtn" class="text-white hover:bg-blue-600 p-2 rounded-lg transition-colors focus:outline-none">
                        <svg class="w-6 h-6" fill="none" stroke="currentColor" stroke-width="2"
                             viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M4 6h16M4 12h16M4 18h16" />
                        </svg>
                    </button>
                    <h1 class="text-xl font-bold">📚 Quản lý thư viện</h1>
                </div>

                <!-- Search bar -->
                <div class="hidden md:flex items-center flex-1 max-w-md mx-8">
                    <form action="adminDashboard.jsp" method="GET" class="relative w-full">
                        <input type="text" name="search"
                               value="<%= request.getParameter("search") != null ? request.getParameter("search") : ""%>"
                               placeholder="Tìm kiếm sách, tác giả..." 
                               class="w-full bg-blue-600 bg-opacity-50 border border-blue-500 rounded-lg px-4 py-2 pl-10 text-white placeholder-blue-200 focus:outline-none focus:ring-2 focus:ring-blue-300 focus:bg-opacity-70">

                        <svg class="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-blue-200" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
                        </svg>
                    </form>
                </div>

                <!-- Right side - notifications and user -->
                <div class="flex items-center gap-3">
                    <!-- Notifications -->
                    <div class="relative">
                        <button onclick="toggleNotifications()" class="text-white hover:bg-blue-600 p-2 rounded-lg transition-colors focus:outline-none relative">
                            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-5 5v-5zM10.07 2.82a8 8 0 0 1 7.9 7.9M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0z"></path>
                            </svg>
                            <span class="absolute -top-1 -right-1 bg-red-500 text-xs rounded-full h-5 w-5 flex items-center justify-center">3</span>
                        </button>
                        <div id="notificationDropdown" class="hidden absolute right-0 top-12 bg-white text-gray-800 rounded-lg shadow-lg py-2 w-80 z-50 max-h-96 overflow-y-auto">
                            <div class="px-4 py-2 border-b font-semibold text-gray-700">Thông báo</div>
                            <a href="#" class="block px-4 py-3 hover:bg-gray-50 border-l-4 border-blue-500">
                                <div class="text-sm font-medium">Sách mới được thêm</div>
                                <div class="text-xs text-gray-500">2 phút trước</div>
                            </a>
                            <a href="#" class="block px-4 py-3 hover:bg-gray-50 border-l-4 border-yellow-500">
                                <div class="text-sm font-medium">Sách sắp hết hạn trả</div>
                                <div class="text-xs text-gray-500">1 giờ trước</div>
                            </a>
                            <a href="#" class="block px-4 py-3 hover:bg-gray-50 border-l-4 border-green-500">
                                <div class="text-sm font-medium">Người dùng mới đăng ký</div>
                                <div class="text-xs text-gray-500">3 giờ trước</div>
                            </a>
                            <div class="px-4 py-2 border-t text-center">
                                <a href="#" class="text-blue-600 text-sm hover:underline">Xem tất cả thông báo</a>
                            </div>
                        </div>
                    </div>

                    <!-- Quick stats -->
                    <div class="hidden lg:flex items-center gap-4 px-4 py-2 bg-blue-600 bg-opacity-50 rounded-lg text-white">
                        <div class="text-center">
                            <div class="text-xs text-blue-200">Sách</div>
                            <div class="font-bold"><%= request.getAttribute("totalBooks")%></div>
                        </div>
                        <div class="text-center border-l border-blue-500 pl-4">
                            <div class="text-xs text-blue-200">Đang mượn</div>
                            <div class="font-bold"><%= request.getAttribute("totalBorrowed")%></div>
                        </div>
                    </div>


                    <!-- User menu -->
                    <div class="relative">
                        <div onclick="toggleHeaderUserMenu()" class="cursor-pointer flex items-center gap-2 px-3 py-2 hover:bg-blue-600 rounded-lg transition-colors">
                            <div class="w-9 h-9 bg-gradient-to-br from-blue-400 to-blue-600 rounded-full flex items-center justify-center ring-2 ring-blue-300">
                                <span class="text-sm font-bold"><%= user != null ? user.getUsername().substring(0, 1).toUpperCase() : "U"%></span>
                            </div>
                            <div class="hidden sm:block text-left">
                                <div class="text-sm font-medium"><%= user != null ? user.getUsername() : "User"%></div>
                                <div class="text-xs text-blue-200">Administrator</div>
                            </div>
                            <span id="headerArrowIcon" class="ml-1">▼</span>
                        </div>
                        <div id="headerUserDropdown" class="hidden absolute right-0 top-12 bg-white text-gray-800 rounded-lg shadow-lg py-2 w-56 z-50">
                            <div class="px-4 py-2 border-b">
                                <div class="font-medium"><%= user != null ? user.getUsername() : "User"%></div>
                                <div class="text-sm text-gray-500">admin@library.com</div>
                            </div>
                            <a href="#" class="flex items-center gap-3 px-4 py-2 text-sm hover:bg-gray-100">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path>
                                </svg>
                                Thông tin cá nhân
                            </a>
                            <a href="#" class="flex items-center gap-3 px-4 py-2 text-sm hover:bg-gray-100">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path>
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                                </svg>
                                Cài đặt
                            </a>
                            <div class="border-t my-1"></div>
                            <a href="../../LogOutServlet" class="flex items-center gap-3 px-4 py-2 text-sm text-red-500 hover:bg-gray-100">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"></path>
                                </svg>
                                Đăng xuất
                            </a>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Breadcrumb bar -->
            <div class="px-6 py-2 bg-blue-800 bg-opacity-50 border-t border-blue-600">
                <nav class="flex items-center gap-2 text-sm">
                    <a href="${pageContext.request.contextPath}/auth/lib/adminDashboard.jsp" class="text-blue-200 hover:text-white transition-colors">🏠 Dashboard</a>
                    <span class="text-blue-300">›</span>
                    <span class="text-white font-medium" id="currentPageBreadcrumb">Thêm sách mới</span>
                </nav>
            </div>
        </header>

        <!-- Sidebar Nổi -->
        <aside id="sidebar"
               class="fixed top-32 left-0 w-64 h-full bg-white shadow-2xl transition-transform duration-300 z-50 px-4 py-6 overflow-y-auto border-r border-gray-200 transform -translate-x-full">
            <div class="flex items-center justify-between mb-6">
                <h2 class="text-xl font-bold text-gray-700 pl-2">📘 Menu</h2>
                <button id="closeSidebarBtn" class="lg:hidden text-gray-500 hover:text-gray-700 p-1 rounded">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                    </svg>
                </button>
            </div>

            <ul class="space-y-2 text-gray-700 text-sm font-medium">
                <li>
                    <a href="${pageContext.request.contextPath}/auth/lib/adminDashboard.jsp" class="flex items-center gap-3 px-4 py-3 rounded-lg hover:bg-blue-100 transition-colors group">
                        <i class="fas fa-tachometer-alt w-4 text-blue-600 group-hover:text-blue-700"></i> 
                        <span>Dashboard</span>
                    </a>
                </li>

                <li>
                    <a href="${pageContext.request.contextPath}/auth/lib/admin.jsp" class="flex items-center gap-3 px-4 py-3 rounded-lg hover:bg-blue-100 transition-colors group">
                        <i class="fas fa-plus-circle w-4 text-green-600 group-hover:text-green-700"></i> 
                        <span>Thêm sách</span>
                    </a>
                </li>

                <li>
                    <a href="${pageContext.request.contextPath}/auth/lib/addBookItem.jsp" class="flex items-center gap-3 px-4 py-3 rounded-lg hover:bg-blue-100 transition-colors group">
                        <i class="fas fa-map-marker-alt w-4 text-purple-600 group-hover:text-purple-700"></i> 
                        <span>Vị trí sách</span>
                    </a>
                </li>

                <% if (user != null && user.getRoleID() == 1) { %>
                <li>
                    <details class="group">
                        <summary class="flex items-center justify-between cursor-pointer px-4 py-3 rounded-lg hover:bg-blue-100 transition-colors">
                            <div class="flex items-center gap-3">
                                <i class="fas fa-users-cog w-4 text-orange-600 group-hover:text-orange-700"></i>
                                <span>Quản lý người dùng</span>
                            </div>
                            <i class="fas fa-chevron-down text-xs group-open:rotate-180 transition-transform text-gray-400"></i>
                        </summary>
                        <div class="ml-6 mt-2 space-y-1 border-l-2 border-gray-200 pl-4">
                            <a href="../admin/manageUsers.jsp"
                               class="flex items-center gap-2 px-4 py-2 rounded hover:bg-blue-50 transition text-sm">
                                <i class="fas fa-list-ul text-indigo-500"></i>
                                <span>Danh sách người dùng</span>
                            </a>
                            <a href="../admin/createUser.jsp"
                               class="flex items-center gap-2 px-4 py-2 rounded hover:bg-blue-50 transition text-sm">
                                <i class="fas fa-user-plus text-green-500"></i>
                                <span>Tạo tài khoản</span>
                            </a>
                            <a href="../admin/approveUsers.jsp"
                               class="flex items-center gap-2 px-4 py-2 rounded hover:bg-blue-50 transition text-sm">
                                <i class="fas fa-user-check text-blue-500"></i>
                                <span>Duyệt tài khoản</span>
                            </a>
                        </div>
                    </details>
                </li>
                <% }%>


                <!-- Menu có submenu -->
                <li>
                    <details class="group">
                        <summary class="flex items-center justify-between cursor-pointer px-4 py-3 rounded-lg hover:bg-blue-100 transition-colors">
                            <div class="flex items-center gap-3">
                                <i class="fas fa-book-reader w-4 text-indigo-600 group-hover:text-indigo-700"></i> 
                                <span>Quản lý mượn trả sách</span>
                            </div>
                            <i class="fas fa-chevron-down text-xs group-open:rotate-180 transition-transform text-gray-400"></i>
                        </summary>
                        <div class="ml-6 mt-2 space-y-1 border-l-2 border-gray-200 pl-4">
                            <a href="${pageContext.request.contextPath}/auth/lib/adminBorrowedBooks.jsp" class="flex items-center gap-2 px-4 py-2 rounded hover:bg-blue-50 transition text-sm">
                                <i class="fas fa-book text-teal-500"></i> 
                                <span>Mượn/ Trả sách</span>
                            </a>
                            <a href="${pageContext.request.contextPath}/auth/lib/borrowList.jsp" class="flex items-center gap-2 px-4 py-2 rounded hover:bg-blue-50 transition text-sm">
                                <i class="fas fa-check-circle text-green-500"></i> 
                                <span>Duyệt mượn sách</span>
                            </a>
                            <a href="${pageContext.request.contextPath}/auth/lib/adminReports.jsp" class="flex items-center gap-2 px-4 py-2 rounded hover:bg-blue-50 transition text-sm">
                                <i class="fas fa-chart-bar text-blue-500"></i> 
                                <span>Thống kê</span>
                            </a>
                        </div>
                    </details>
                </li>
            </ul>

            <!-- Quick actions ở cuối sidebar -->
            <div class="mt-8 pt-4 border-t border-gray-200">
                <p class="text-xs text-gray-500 mb-3 px-2">Thao tác nhanh</p>
                <div class="space-y-2">
                    <button class="w-full flex items-center gap-2 px-3 py-2 text-sm bg-blue-50 text-blue-700 rounded-lg hover:bg-blue-100 transition-colors">
                        <i class="fas fa-plus text-xs"></i>
                        <span>Tạo mới</span>
                    </button>
                    <button class="w-full flex items-center gap-2 px-3 py-2 text-sm bg-gray-50 text-gray-700 rounded-lg hover:bg-gray-100 transition-colors">
                        <i class="fas fa-search text-xs"></i>
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
                const userMenuContainer = e.target.closest('.relative');
                const isNotificationButton = e.target.closest('button')?.onclick?.toString().includes('toggleNotifications');
                const isSidebarClick = e.target.closest('#sidebar') || e.target.closest('#toggleSidebarBtn');

                if (!userMenuContainer && !isNotificationButton) {
                    headerUserDropdown.classList.add('hidden');
                    notificationDropdown.classList.add('hidden');
                    headerArrowIcon.textContent = '▼';
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
