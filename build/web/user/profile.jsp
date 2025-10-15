<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*" %>
<%@ page import="Servlet.DBConnection, Data.Users" %>
<%@ page import="java.text.SimpleDateFormat" %>
<!DOCTYPE html>
<html lang="vi">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Thông tin cá nhân - Thư viện Sách</title>

        <!-- Tailwind CSS -->
        <script src="https://cdn.tailwindcss.com"></script>

        <!-- Font Awesome -->
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css">

        <!-- Google Fonts -->
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">

        <!-- Favicon -->
        <link rel="icon" href="./images/reading-book.png" type="image/x-icon" />

        <!-- Custom CSS -->
        <link rel="stylesheet" href="home1.css"/>
<!--        <link rel="stylesheet" href="loading.css"/>-->
        <style>
            .profile-gradient {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            }

            .card-hover {
                transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            }

            .card-hover:hover {
                transform: translateY(-4px);
                box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
            }

            .modal-backdrop {
                background-color: rgba(0, 0, 0, 0.5);
                backdrop-filter: blur(4px);
                z-index: 9998;
            }

            .modal-content {
                position: relative;
                z-index: 10002;
                pointer-events: all;
            }

            .modal-enter {
                animation: modalEnter 0.3s ease-out;
            }

            @keyframes modalEnter {
                from {
                    opacity: 0;
                    transform: scale(0.9) translate(-50%, -50%);
                }
                to {
                    opacity: 1;
                    transform: scale(1) translate(-50%, -50%);
                }
            }

            #editModal {
                display: flex !important;
                align-items: center !important;
                justify-content: center !important;
            }

            #editModal.hidden {
                display: none !important;
            }

            .status-active {
                background: linear-gradient(135deg, #10b981, #059669);
            }

            .status-inactive {
                background: linear-gradient(135deg, #ef4444, #dc2626);
            }

            .status-expired {
                background: linear-gradient(135deg, #f59e0b, #d97706);
            }

            .info-card {
                background: linear-gradient(135deg, #f8fafc 0%, #ffffff 100%);
                border: 1px solid #e2e8f0;
            }

            .floating-avatar {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                animation: float 3s ease-in-out infinite;
            }

            @keyframes float {
                0%, 100% {
                    transform: translateY(0px);
                }
                50% {
                    transform: translateY(-10px);
                }
            }
        </style>
    </head>

    <body class="page-background">
        <!-- Floating Background Elements -->
        <div class="floating-elements">
            <i class="fas fa-book floating-book text-6xl text-blue-500" style="top: 10%; left: 85%; animation-delay: 0s;"></i>
            <i class="fas fa-bookmark floating-book text-4xl text-purple-500" style="top: 20%; left: 10%; animation-delay: 2s;"></i>
            <i class="fas fa-feather floating-book text-5xl text-green-500" style="top: 60%; left: 90%; animation-delay: 4s;"></i>
            <i class="fas fa-scroll floating-book text-4xl text-orange-500" style="top: 80%; left: 5%; animation-delay: 6s;"></i>
        </div>

        <!-- Include Header với Search Component -->
        <%@ include file="layout/header.jsp" %>

        <!-- Main Content -->
        <main class="container-enhanced py-12">
<!--             Page Loader 
            <div id="page-loader" role="status" aria-live="polite">
                <div class="spinner mb-6"></div>
                <div class="text-center mb-6">
                    <div class="loader-title text-xl">Đang tải dữ liệu…</div>
                    <div class="loader-sub text-sm">Vui lòng chờ trong giây lát</div>
                </div>

                 Skeleton: 1 hàng sách giả để người dùng có gì đó nhìn 
                <div class="shelf-skeleton px-6">
                     lặp vài thẻ giả (5–7 cái) 
                    <div class="sk-card">
                        <div class="sk-img shimmer"></div>
                        <div class="p-4 space-y-3">
                            <div class="sk-line w1 shimmer relative"></div>
                            <div class="sk-line w2 shimmer relative"></div>
                            <div class="sk-line w3 shimmer relative"></div>
                        </div>
                    </div>
                    <div class="sk-card">
                        <div class="sk-img shimmer"></div>
                        <div class="p-4 space-y-3">
                            <div class="sk-line w1 shimmer relative"></div>
                            <div class="sk-line w2 shimmer relative"></div>
                            <div class="sk-line w3 shimmer relative"></div>
                        </div>
                    </div>
                    <div class="sk-card"><div class="sk-img shimmer"></div><div class="p-4 space-y-3"><div class="sk-line w1 shimmer relative"></div><div class="sk-line w2 shimmer relative"></div><div class="sk-line w3 shimmer relative"></div></div></div>
                    <div class="sk-card"><div class="sk-img shimmer"></div><div class="p-4 space-y-3"><div class="sk-line w1 shimmer relative"></div><div class="sk-line w2 shimmer relative"></div><div class="sk-line w3 shimmer relative"></div></div></div>
                    <div class="sk-card"><div class="sk-img shimmer"></div><div class="p-4 space-y-3"><div class="sk-line w1 shimmer relative"></div><div class="sk-line w2 shimmer relative"></div><div class="sk-line w3 shimmer relative"></div></div></div>
                </div>
            </div>
            <div id="app-content">-->
            <%            
                SimpleDateFormat df = new SimpleDateFormat("dd/MM/yyyy");
                Connection conn = DBConnection.getConnection();
                Users currentUser = (Users) session.getAttribute("user");
                if (currentUser == null) {
                    response.sendRedirect("index.jsp");
                    return;
                }

                int currentUserId = currentUser.getId();

                PreparedStatement ps = conn.prepareStatement(
                        "SELECT u.username, u.email, u.status, u.expiryDate, p.fullName, p.gender, p.birthDate, p.phone, p.address "
                        + "FROM users u LEFT JOIN user_profile p ON u.id = p.userID WHERE u.id = ?"
                );
                ps.setInt(1, currentUserId);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
            %>

            <!-- Profile Header -->
            <div class="profile-gradient rounded-2xl shadow-2xl p-8 mb-8 text-white relative overflow-hidden">
                <div class="absolute top-0 right-0 w-32 h-32 bg-white opacity-10 rounded-full -translate-y-16 translate-x-16"></div>
                <div class="absolute bottom-0 left-0 w-24 h-24 bg-white opacity-10 rounded-full translate-y-12 -translate-x-12"></div>

                <div class="relative z-10 flex flex-col md:flex-row items-center gap-6">
                    <div class="floating-avatar w-24 h-24 rounded-full flex items-center justify-center text-4xl font-bold shadow-lg">
                        <%= rs.getString("fullName") != null ? rs.getString("fullName").substring(0, 1).toUpperCase() : rs.getString("username").substring(0, 1).toUpperCase()%>
                    </div>

                    <div class="text-center md:text-left">
                        <h1 class="text-3xl font-bold mb-2">
                            <%= rs.getString("fullName") != null ? rs.getString("fullName") : rs.getString("username")%>
                        </h1>

                        <!-- Status Badge -->
                        <div class="mt-4">
                            <%
                                String status = rs.getString("status");
                                String statusClass = "";
                                String statusText = "";
                                String statusIcon = "";

                                if ("ACTIVE".equals(status)) {
                                    statusClass = "status-active";
                                    statusText = "Đang hoạt động";
                                    statusIcon = "fas fa-check-circle";
                                } else if ("inactive".equals(status)) {
                                    statusClass = "status-inactive";
                                    statusText = "Tạm khóa";
                                    statusIcon = "fas fa-times-circle";
                                } else {
                                    statusClass = "status-expired";
                                    statusText = "Hết hạn";
                                    statusIcon = "fas fa-clock";
                                }
                            %>
                            <span class="<%= statusClass%> px-4 py-2 rounded-full text-sm font-semibold text-white shadow-lg">
                                <i class="<%= statusIcon%> mr-2"></i><%= statusText%>
                            </span>
                        </div>
                    </div>

                    <div class="ml-auto">
                        <button onclick="openEditModal()" class="bg-white/20 hover:bg-white/30 backdrop-blur-sm border border-white/30 text-white px-6 py-3 rounded-xl font-semibold transition-all duration-300 hover:scale-105">
                            <i class="fas fa-edit mr-2"></i>Cập nhật thông tin
                        </button>
                    </div>
                </div>
            </div>

            <!-- Profile Information Cards -->
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
                <!-- Personal Information -->
                <div class="info-card card-hover rounded-2xl shadow-lg p-6">
                    <div class="flex items-center mb-6">
                        <div class="w-12 h-12 bg-gradient-to-r from-blue-500 to-purple-600 rounded-lg flex items-center justify-center mr-4">
                            <i class="fas fa-user text-white text-xl"></i>
                        </div>
                        <h2 class="text-2xl font-bold text-gray-800">Thông tin cá nhân</h2>
                    </div>

                    <div class="space-y-4">
                        <div class="flex items-center p-3 bg-gray-50 rounded-lg">
                            <i class="fas fa-signature text-blue-500 w-5 mr-3"></i>
                            <div>
                                <p class="text-sm text-gray-500">Họ và tên</p>
                                <p class="font-semibold text-gray-800">
                                    <%= rs.getString("fullName") != null ? rs.getString("fullName") : "Chưa cập nhật"%>
                                </p>
                            </div>
                        </div>

                        <div class="flex items-center p-3 bg-gray-50 rounded-lg">
                            <i class="fas fa-venus-mars text-pink-500 w-5 mr-3"></i>
                            <div>
                                <p class="text-sm text-gray-500">Giới tính</p>
                                <p class="font-semibold text-gray-800">
                                    <%= rs.getString("gender") != null ? rs.getString("gender") : "Chưa cập nhật"%>
                                </p>
                            </div>
                        </div>

                        <div class="flex items-center p-3 bg-gray-50 rounded-lg">
                            <i class="fas fa-birthday-cake text-orange-500 w-5 mr-3"></i>
                            <div>
                                <p class="text-sm text-gray-500">Ngày sinh</p>
                                <p class="font-semibold text-gray-800">
                                    <%= rs.getDate("birthDate") != null ? df.format(rs.getDate("birthDate")) : "Chưa cập nhật" %>
                                </p>

                            </div>
                        </div>
                    </div>
                </div>

                <!-- Contact Information -->
                <div class="info-card card-hover rounded-2xl shadow-lg p-6">
                    <div class="flex items-center mb-6">
                        <div class="w-12 h-12 bg-gradient-to-r from-green-500 to-teal-600 rounded-lg flex items-center justify-center mr-4">
                            <i class="fas fa-address-book text-white text-xl"></i>
                        </div>
                        <h2 class="text-2xl font-bold text-gray-800">Thông tin liên hệ</h2>
                    </div>

                    <div class="space-y-4">
                        <div class="flex items-center p-3 bg-gray-50 rounded-lg">
                            <i class="fas fa-phone text-green-500 w-5 mr-3"></i>
                            <div>
                                <p class="text-sm text-gray-500">Số điện thoại</p>
                                <p class="font-semibold text-gray-800">
                                    <%= rs.getString("phone") != null ? rs.getString("phone") : "Chưa cập nhật"%>
                                </p>
                            </div>
                        </div>

                        <div class="flex items-center p-3 bg-gray-50 rounded-lg">
                            <i class="fas fa-envelope text-blue-500 w-5 mr-3"></i>
                            <div>
                                <p class="text-sm text-gray-500">Email</p>
                                <p class="font-semibold text-gray-800"><%= rs.getString("email") != null ? rs.getString("email") : "Chưa cập nhật"%></p>
                            </div>
                        </div>

                        <div class="flex items-start p-3 bg-gray-50 rounded-lg">
                            <i class="fas fa-map-marker-alt text-red-500 w-5 mr-3 mt-1"></i>
                            <div class="flex-1">
                                <p class="text-sm text-gray-500">Địa chỉ</p>
                                <p class="font-semibold text-gray-800">
                                    <%= rs.getString("address") != null ? rs.getString("address") : "Chưa cập nhật"%>
                                </p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Account Information -->
                <div class="info-card card-hover rounded-2xl shadow-lg p-6 lg:col-span-2">
                    <div class="flex items-center mb-6">
                        <div class="w-12 h-12 bg-gradient-to-r from-purple-500 to-indigo-600 rounded-lg flex items-center justify-center mr-4">
                            <i class="fas fa-user-cog text-white text-xl"></i>
                        </div>
                        <h2 class="text-2xl font-bold text-gray-800">Thông tin tài khoản</h2>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                        <div class="text-center p-4 bg-gradient-to-r from-blue-50 to-indigo-50 rounded-lg">
                            <i class="fas fa-user-circle text-3xl text-blue-500 mb-2"></i>
                            <p class="text-sm text-gray-500">Tên đăng nhập</p>
                            <p class="font-bold text-gray-800"><%= rs.getString("username")%></p>
                        </div>

                        <div class="text-center p-4 bg-gradient-to-r from-green-50 to-emerald-50 rounded-lg">
                            <i class="fas fa-shield-alt text-3xl text-green-500 mb-2"></i>
                            <p class="text-sm text-gray-500">Trạng thái</p>
                            <p class="font-bold text-gray-800"><%= statusText%></p>
                        </div>

                        <div class="text-center p-4 bg-gradient-to-r from-orange-50 to-red-50 rounded-lg">
                            <i class="fas fa-calendar-alt text-3xl text-orange-500 mb-2"></i>
                            <p class="text-sm text-gray-500">Hạn sử dụng</p>
                            <p class="font-bold text-gray-800">
                                <%= rs.getDate("expiryDate") != null ? df.format(rs.getDate("expiryDate")) : "Chưa cập nhật" %>
                            </p>

                        </div>
                    </div>
                </div>
            </div>

            <!-- Edit Profile Modal -->
            <div id="editModal" class="fixed inset-0 z-[9999] hidden flex items-center justify-center p-4">
                <div class="modal-backdrop absolute inset-0" onclick="closeEditModal()"></div>
                <div class="modal-enter bg-white rounded-2xl shadow-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto relative z-[10001] mx-auto my-auto">
                    <div class="modal-content profile-gradient p-6 text-white">
                        <div class="flex items-center justify-between">
                            <h3 class="text-2xl font-bold">
                                <i class="fas fa-edit mr-2"></i>Cập nhật thông tin cá nhân
                            </h3>
                            <button onclick="closeEditModal()" class="text-white/80 hover:text-white text-2xl">
                                <i class="fas fa-times"></i>
                            </button>
                        </div>
                    </div>

                    <form action="../UpdateProfileServlet" id="updateProfileForm" class="p-6 space-y-6">
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                            <div>
                                <label class="block text-sm font-semibold text-gray-700 mb-2">
                                    <i class="fas fa-signature mr-2 text-blue-500"></i>Họ và tên
                                </label>
                                <input type="text" id="fullName" name="fullName" 
                                       value="<%= rs.getString("fullName") != null ? rs.getString("fullName") : ""%>"
                                       class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-300">
                            </div>

                            <div>
                                <label class="block text-sm font-semibold text-gray-700 mb-2">
                                    <i class="fas fa-venus-mars mr-2 text-pink-500"></i>Giới tính
                                </label>
                                <select id="gender" name="gender" class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-300">
                                    <option value="">Chọn giới tính</option>
                                    <option value="Nam" <%= "Nam".equals(rs.getString("gender")) ? "selected" : ""%>>Nam</option>
                                    <option value="Nữ" <%= "Nữ".equals(rs.getString("gender")) ? "selected" : ""%>>Nữ</option>
                                    <option value="Khác" <%= "Khác".equals(rs.getString("gender")) ? "selected" : ""%>>Khác</option>
                                </select>
                            </div>

                            <div>
                                <label class="block text-sm font-semibold text-gray-700 mb-2">
                                    <i class="fas fa-birthday-cake mr-2 text-orange-500"></i>Ngày sinh
                                </label>
                               <%
                                    java.sql.Date bd = rs.getDate("birthDate");
                                    String birthDateVal = (bd != null) ? bd.toString() : "";
                                %>
                                <input type="date" id="birthDate" name="birthDate"
                                       value="<%= birthDateVal %>"
                                       class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-300">
                            </div>

                            <div>
                                <label class="block text-sm font-semibold text-gray-700 mb-2">
                                    <i class="fas fa-phone mr-2 text-green-500"></i>Số điện thoại
                                </label>
                                <input type="tel" id="phone" name="phone" 
                                       value="<%= rs.getString("phone") != null ? rs.getString("phone") : ""%>"
                                       class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-300"
                                       placeholder="Nhập số điện thoại">
                            </div>
                        </div>

                        <div>
                            <label class="block text-sm font-semibold text-gray-700 mb-2">
                                <i class="fas fa-map-marker-alt mr-2 text-red-500"></i>Địa chỉ
                            </label>
                            <textarea id="address" name="address" rows="3" 
                                      class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-300"
                                      placeholder="Nhập địa chỉ của bạn"><%= rs.getString("address") != null ? rs.getString("address") : ""%></textarea>
                        </div>

                        <div class="flex gap-4 pt-6">
                            <button type="submit" class="flex-1 bg-gradient-to-r from-blue-500 to-purple-600 text-white px-6 py-3 rounded-lg font-semibold hover:from-blue-600 hover:to-purple-700 transition-all duration-300 transform hover:scale-105">
                                <i class="fas fa-save mr-2"></i>Lưu thay đổi
                            </button>
                            <button type="button" onclick="closeEditModal()" class="px-6 py-3 border border-gray-300 rounded-lg font-semibold text-gray-700 hover:bg-gray-50 transition-all duration-300">
                                <i class="fas fa-times mr-2"></i>Hủy
                            </button>
                        </div>
                    </form>
                </div>
            </div>

            <%
                }
                rs.close();
                ps.close();
                conn.close();
            %>
        </main>    

        <%@ include file="layout/footer.jsp" %>

        <!-- Enhanced JavaScript -->
        <script>
            // Modal functions
            function openEditModal() {
                const modal = document.getElementById('editModal');
                modal.classList.remove('hidden');
                document.body.style.overflow = 'hidden';

                // Center the modal
                modal.style.display = 'flex';
                modal.style.alignItems = 'center';
                modal.style.justifyContent = 'center';
                modal.style.pointerEvents = 'all';
            }

            function closeEditModal() {
                const modal = document.getElementById('editModal');
                modal.classList.add('hidden');
                modal.style.display = 'none';
                document.body.style.overflow = 'auto';
            }

            // Handle form submission
            document.getElementById('updateProfileForm').addEventListener('submit', function (e) {
                e.preventDefault();

                const formData = new FormData(this);
                const data = new URLSearchParams(); // 🟢 Phần này bạn đang thiếu

                for (const pair of formData.entries()) {
                    data.append(pair[0], pair[1]);
                }

                const submitBtn = this.querySelector('button[type="submit"]');
                const originalText = submitBtn.innerHTML;
                submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i>Đang lưu...';
                submitBtn.disabled = true;

                fetch('<%= request.getContextPath()%>/UpdateProfileServlet', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded'
                    },
                    body: data.toString() // 🔁 Phải gọi .toString() để gửi đúng format
                })
                        .then(response => {
                            if (response.ok) {
                                showNotification('Cập nhật thông tin thành công!', 'success');
                                closeEditModal();
                                setTimeout(() => {
                                    location.reload();
                                }, 1500);
                            } else {
                                throw new Error('Lỗi cập nhật');
                            }
                        })
                        .catch(() => {
                            showNotification('Có lỗi xảy ra khi cập nhật!', 'error');
                        })
                        .finally(() => {
                            submitBtn.innerHTML = originalText;
                            submitBtn.disabled = false;
                        });
            });



            // Notification function
            function showNotification(message, type = 'info') {
                const notification = document.createElement('div');
                notification.className = `fixed top-4 right-4 z-50 px-6 py-3 rounded-lg shadow-lg transition-all duration-500 transform translate-x-full`;

                if (type === 'success') {
                    notification.classList.add('bg-green-500', 'text-white');
                    notification.innerHTML = `<i class="fas fa-check-circle mr-2"></i>${message}`;
                } else if (type === 'error') {
                    notification.classList.add('bg-red-500', 'text-white');
                    notification.innerHTML = `<i class="fas fa-exclamation-circle mr-2"></i>${message}`;
                } else {
                    notification.classList.add('bg-blue-500', 'text-white');
                    notification.innerHTML = `<i class="fas fa-info-circle mr-2"></i>${message}`;
                }

                document.body.appendChild(notification);

                setTimeout(() => {
                    notification.classList.remove('translate-x-full');
                }, 100);

                setTimeout(() => {
                    notification.classList.add('translate-x-full');
                    setTimeout(() => {
                        document.body.removeChild(notification);
                    }, 500);
                }, 3000);
            }

            // Close modal when clicking outside - with better event handling
            document.addEventListener('click', function (e) {
                const modal = document.getElementById('editModal');
                const modalContent = modal.querySelector('.bg-white');

                if (!modal.classList.contains('hidden') &&
                        !modalContent.contains(e.target) &&
                        e.target.classList.contains('modal-backdrop')) {
                    closeEditModal();
                }
            });

            // Prevent modal content clicks from closing modal
            document.addEventListener('DOMContentLoaded', function () {
                const modalContent = document.querySelector('#editModal .bg-white');
                if (modalContent) {
                    modalContent.addEventListener('click', function (e) {
                        e.stopPropagation();
                    });
                }
            });

            // Close modal with Escape key
            document.addEventListener('keydown', function (e) {
                if (e.key === 'Escape' && !document.getElementById('editModal').classList.contains('hidden')) {
                    closeEditModal();
                }
            });

            // Enhanced animations on page load
            document.addEventListener('DOMContentLoaded', function () {
                const cards = document.querySelectorAll('.card-hover');
                cards.forEach((card, index) => {
                    card.style.opacity = '0';
                    card.style.transform = 'translateY(20px)';

                    setTimeout(() => {
                        card.style.transition = 'all 0.6s ease';
                        card.style.opacity = '1';
                        card.style.transform = 'translateY(0)';
                    }, index * 200);
                });
            });

            // Add parallax effect to floating elements
            window.addEventListener('scroll', function () {
                const scrolled = window.pageYOffset;
                const parallaxElements = document.querySelectorAll('.floating-book');

                parallaxElements.forEach((element, index) => {
                    const speed = 0.5 + (index * 0.1);
                    element.style.transform = `translateY(${scrolled * speed}px) rotate(${scrolled * 0.1}deg)`;
                });
            });
        </script>
<!--        <script src="script.js"></script>
        </div>-->
    </body>
</html>