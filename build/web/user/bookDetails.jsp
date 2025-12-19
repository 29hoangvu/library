<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*" %>
<%@ page import="Servlet.DBConnection, Data.Users" %>
<%@ page import="service.BookDetailService" %>
<%@ page import="dto.books.BookDetailDto, dto.books.RelatedBookDto" %>
<!DOCTYPE html>
<html lang="vi">
    <head>
        <meta charset="UTF-8">
        <title>Chi Tiết Sách - Thư viện</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css">
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
        <link rel="icon" href="./images/reading-book.png" type="image/x-icon" />
        <link rel="stylesheet" href="style1.css"/>
    </head>

    <body class="page-background">
        <div class="floating-elements">
            <i class="fas fa-book floating-book text-6xl text-blue-500" style="top: 10%; left: 85%; animation-delay: 0s;"></i>
            <i class="fas fa-bookmark floating-book text-4xl text-purple-500" style="top: 20%; left: 10%; animation-delay: 2s;"></i>
            <i class="fas fa-feather floating-book text-5xl text-green-500" style="top: 60%; left: 90%; animation-delay: 4s;"></i>
            <i class="fas fa-scroll floating-book text-4xl text-orange-500" style="top: 80%; left: 5%; animation-delay: 6s;"></i>
        </div>

        <%@ include file="./layout/header.jsp" %>

        <%
            String isbn = request.getParameter("isbn");
            if (isbn == null || isbn.trim().isEmpty()) {
        %>
        <main class="container-enhanced py-12 relative z-[1]">
            <div class="glass-effect rounded-3xl p-8 text-center">
                <p class="text-red-300 text-lg font-semibold mb-2">
                    <i class="fas fa-exclamation-circle mr-2"></i>Lỗi: Không tìm thấy ISBN.
                </p>
                <a href="index.jsp"
                   class="inline-flex items-center mt-4 px-4 py-2 rounded-full bg-gradient-to-r from-blue-500 to-indigo-600 text-white text-sm font-medium shadow-lg hover:shadow-xl hover:from-blue-600 hover:to-indigo-700 transition">
                    <i class="fas fa-arrow-left mr-2"></i>Quay lại trang chủ
                </a>
            </div>
        </main>
        <%
                return;
            }

            // === GỌI SERVICE ===
            BookDetailService bookService = new BookDetailService();
            BookDetailDto book = null;
            List<RelatedBookDto> relatedBooks = new ArrayList<>();
            String errorMessage = null;

            try {
                book = bookService.getBookDetail(isbn);

                if (book == null) {
        %>
        <main class="container-enhanced py-12 relative z-[1]">
            <div class="glass-effect rounded-3xl p-8 text-center">
                <p class="text-yellow-200 text-lg font-semibold mb-2">
                    <i class="fas fa-search mr-2"></i>Không tìm thấy sách với ISBN: <span class="font-mono"><%= isbn%></span>
                </p>
                <a href="index.jsp"
                   class="inline-flex items-center mt-4 px-4 py-2 rounded-full bg-gradient-to-r from-blue-500 to-indigo-600 text-white text-sm font-medium shadow-lg hover:shadow-xl hover:from-blue-600 hover:to-indigo-700 transition">
                    <i class="fas fa-arrow-left mr-2"></i>Quay lại trang chủ
                </a>
            </div>
        </main>
        <%
                return;
            }

            // Lấy sách liên quan
            String primaryGenre = book.genres.isEmpty() ? null : book.genres.get(0);
            if (primaryGenre != null) {
                relatedBooks = bookService.getRelatedBooks(isbn, primaryGenre, 8);
            }

        } catch (SQLException e) {
            errorMessage = e.getMessage();
            e.printStackTrace();
        %>
        <main class="container-enhanced py-12 relative z-[1]">
            <div class="glass-effect rounded-3xl p-8 text-red-200">
                <p class="text-lg font-semibold mb-2">
                    <i class="fas fa-exclamation-triangle mr-2"></i>Lỗi kết nối CSDL:
                </p>
                <p class="text-sm"><%= errorMessage%></p>
            </div>
        </main>
        <%
                return;
            }

            // Convert format sang tiếng Việt
            String formatVi;
            switch (book.format != null ? book.format : "") {
                case "HARDCOVER":
                    formatVi = "Bìa cứng";
                    break;
                case "PAPERBACK":
                    formatVi = "Bìa mềm";
                    break;
                case "EBOOK":
                    formatVi = "Sách điện tử";
                    break;
                default:
                    formatVi = book.format != null ? book.format : "Không rõ";
            }
        %>

        <!-- Main -->
        <main class="container-enhanced py-10 relative z-[1]">
            <!-- Back button -->
            <div class="mb-5 flex items-center justify-between gap-4">
                <button type="button"
                        onclick="handleBack()"
                        class="inline-flex items-center gap-2 px-3 py-1.5 rounded-full border border-slate-600 bg-slate-900/80 text-slate-200 text-sm font-medium shadow-lg hover:border-sky-400 hover:text-white hover:bg-slate-800/90 transition">
                    <span class="inline-flex h-6 w-6 items-center justify-center rounded-full bg-slate-800/80">
                        <i class="fas fa-arrow-left text-xs"></i>
                    </span>
                    <span>Quay lại</span>
                </button>

                <span class="hidden md:inline-flex items-center text-xs text-slate-400 gap-2">
                    <i class="fas fa-barcode text-slate-500"></i>
                    <span class="font-mono tracking-wider">ISBN: <%= isbn%></span>
                </span>
            </div>

            <!-- Glass Card chính -->
            <section class="glass-effect rounded-3xl p-[2px]">
                <div class="rounded-[1.5rem] bg-slate-950/95 px-5 py-7 md:px-8 md:py-8 text-slate-100">
                    <div class="grid grid-cols-1 lg:grid-cols-5 gap-8 lg:gap-10">
                        <!-- Cột trái: ảnh + action (2 cột) -->
                        <div class="lg:col-span-2 flex flex-col items-center gap-6">
                            <div class="w-full max-w-sm">
                                <div class="book-image-container">
                                    <img src="<%= request.getContextPath() + "/" + book.coverImage%>"
                                         alt="<%= book.title%>"
                                         onerror="this.onerror=null; this.src='<%= request.getContextPath()%>/images/default-cover.jpg'"
                                         class="book-image" />
                                    <div class="book-overlay">
                                        <i class="fas fa-book-open text-white text-3xl"></i>
                                    </div>
                                </div>
                            </div>

                            <!-- Action buttons -->
                            <div class="w-full max-w-sm flex flex-col sm:flex-row gap-3">
                                <% if (book.isEbook()) {%>
                                <a href="readBook.jsp?isbn=<%= isbn%>"
                                   class="flex-1 inline-flex items-center justify-center gap-2 px-4 py-3 rounded-xl bg-gradient-to-r from-sky-500 to-emerald-400 text-slate-900 font-semibold shadow-lg hover:shadow-xl hover:from-sky-400 hover:to-emerald-300 transition-transform duration-200 hover:-translate-y-0.5">
                                    <i class="fas fa-book-open"></i>
                                    <span>Đọc online</span>
                                </a>
                                <a href="<%= request.getContextPath()%>/ebook?isbn=<%= isbn%>&download=true"
                                   class="flex-1 inline-flex items-center justify-center gap-2 px-4 py-3 rounded-xl bg-slate-900/90 border border-emerald-500/70 text-emerald-200 font-semibold shadow-lg hover:shadow-xl hover:bg-slate-900 hover:border-emerald-300 transition-transform duration-200 hover:-translate-y-0.5">
                                    <i class="fas fa-download"></i>
                                    <span>Tải về</span>
                                </a>
                                <% } else {%>
                                <button id="btnBorrow"
                                        <%= book.availableCount <= 0 ? "disabled" : ""%>
                                        class="w-full inline-flex items-center justify-center gap-2 px-4 py-3 rounded-xl <%= book.availableCount > 0 ? "bg-gradient-to-r from-indigo-500 to-blue-500 text-white hover:from-indigo-400 hover:to-blue-400 hover:-translate-y-0.5" : "bg-slate-700 text-slate-400 cursor-not-allowed"%> font-semibold shadow-lg hover:shadow-xl transition-transform duration-200">
                                    <i class="fas fa-hand-holding"></i>
                                    <span><%= book.availableCount > 0 ? "Đăng ký mượn" : "Tạm hết sách"%></span>
                                </button>
                                <% }%>
                            </div>
                        </div>

                        <!-- Cột giữa: thông tin (2 cột) -->
                        <div class="lg:col-span-2 flex flex-col gap-7">
                            <!-- Tiêu đề + tác giả -->
                            <header class="space-y-3">
                                <h1 class="text-3xl md:text-4xl font-extrabold tracking-tight text-slate-50">
                                    <%= book.title%>
                                </h1>
                                <p class="text-lg text-slate-300 flex items-center gap-2">
                                    <span class="inline-flex h-8 w-8 items-center justify-center rounded-full bg-slate-800/90 border border-slate-600 text-sky-400 shadow-md">
                                        <i class="fas fa-user-pen"></i>
                                    </span>
                                    <span>
                                        Tác giả:
                                        <span class="font-semibold text-slate-100"><%= book.author%></span>
                                    </span>
                                </p>
                            </header>

                            <!-- Grid thông tin nhanh -->
                            <section class="grid grid-cols-1 md:grid-cols-2 gap-4">
                                <!-- Năm xuất bản -->
                                <div class="profile-row">
                                    <div class="flex items-center mb-1.5">
                                        <i class="fas fa-calendar-alt text-blue-400 mr-2"></i>
                                        <span class="font-semibold text-slate-100 text-sm">Năm xuất bản</span>
                                    </div>
                                    <p class="text-slate-300 ml-6 text-sm md:text-base">
                                        <%= book.publicationYear != null ? book.publicationYear : "Chưa cập nhật"%>
                                    </p>
                                </div>

                                <!-- Định dạng -->
                                <div class="profile-row">
                                    <div class="flex items-center mb-1.5">
                                        <i class="fas fa-file-alt text-emerald-400 mr-2"></i>
                                        <span class="font-semibold text-slate-100 text-sm">Định dạng</span>
                                    </div>
                                    <p class="text-slate-300 ml-6 text-sm md:text-base"><%= formatVi%></p>
                                </div>

                                <% if (book.isEbook()) {%>
                                <!-- EBOOK: lượt đọc -->
                                <div class="profile-row">
                                    <div class="flex items-center mb-1.5">
                                        <i class="fas fa-eye text-indigo-400 mr-2"></i>
                                        <span class="font-semibold text-slate-100 text-sm">Lượt đọc</span>
                                    </div>
                                    <p class="text-slate-200 ml-6 text-base font-semibold">
                                        <span class="text-lg"><%= book.viewsTotal%></span>
                                    </p>
                                </div>
                                <% } else {%>
                                <!-- Sách giấy: Tổng số lượng -->
                                <div class="profile-row">
                                    <div class="flex items-center mb-1.5">
                                        <i class="fas fa-boxes text-amber-400 mr-2"></i>
                                        <span class="font-semibold text-slate-100 text-sm">Tổng số lượng</span>
                                    </div>
                                    <p class="text-slate-300 ml-6 text-sm md:text-base">
                                        <%= book.totalQuantity%>
                                    </p>
                                </div>

                                <!-- Đang mượn/chờ duyệt -->
                                <div class="profile-row">
                                    <div class="flex items-center mb-1.5">
                                        <i class="fas fa-clock text-orange-400 mr-2"></i>
                                        <span class="font-semibold text-slate-100 text-sm">Đang mượn/chờ</span>
                                    </div>
                                    <p class="text-slate-300 ml-6 text-sm md:text-base">
                                        <%= book.reservedCount%>
                                    </p>
                                </div>

                                <!-- Còn lại (Available) -->
                                <div class="profile-row">
                                    <div class="flex items-center mb-1.5">
                                        <i class="fas fa-check-circle <%= book.availableCount > 0 ? "text-emerald-400" : "text-red-400"%> mr-2"></i>
                                        <span class="font-semibold text-slate-100 text-sm">Còn lại</span>
                                    </div>
                                    <p class="ml-6 text-base font-bold <%= book.availableCount > 0 ? "text-emerald-400" : "text-red-400"%>">
                                        <%= book.availableCount%>
                                        <% if (book.availableCount <= 0) { %>
                                        <span class="text-xs font-normal text-red-300 ml-2">(Tạm hết)</span>
                                        <% }%>
                                    </p>
                                </div>

                                <!-- Vị trí kệ -->
                                <div class="profile-row">
                                    <div class="flex items-center mb-1.5">
                                        <i class="fas fa-map-marker-alt text-fuchsia-400 mr-2"></i>
                                        <span class="font-semibold text-slate-100 text-sm">Vị trí kệ</span>
                                    </div>
                                    <p class="text-slate-300 ml-6 text-sm md:text-base">
                                        <%= book.rackNumber != null ? book.rackNumber : "Chưa sắp xếp"%>
                                    </p>
                                </div>
                                <% } %>
                            </section>

                            <!-- Thể loại -->
                            <section class="profile-card p-4 md:p-5">
                                <div class="flex items-center mb-3">
                                    <span class="inline-flex items-center justify-center h-8 w-8 rounded-full bg-slate-900/80 border border-slate-700 mr-2 shadow-md">
                                        <i class="fas fa-tags text-pink-400"></i>
                                    </span>
                                    <span class="font-semibold text-slate-100 text-sm md:text-base">Thể loại</span>
                                </div>
                                <div class="flex flex-wrap gap-2 ml-1 md:ml-6">
                                    <% if (book.genres.isEmpty()) { %>
                                    <span class="text-xs text-slate-400 italic">Chưa có thông tin thể loại.</span>
                                    <% } else {
                                        for (String genre : book.genres) {%>
                                    <span class="inline-flex items-center bg-yellow-100/10 text-amber-200 text-xs md:text-sm font-medium px-3 py-1 rounded-full shadow-sm border border-amber-400/40">
                                        <i class="fas fa-tag mr-1.5 text-amber-300"></i><%= genre%>
                                    </span>
                                    <%   }
                                        } %>
                                </div>
                            </section>
                        </div>

                        <!-- Cột phải: Sidebar gợi ý (1 cột) -->
                        <div class="hidden lg:block lg:col-span-1">
                            <aside class="profile-card p-4 sticky top-24">
                                <%
                                    String primaryGenre = book.genres.isEmpty() ? null : book.genres.get(0);
                                %>
                                <div class="flex items-center justify-between mb-3">
                                    <div class="flex items-center gap-2">
                                        <span class="inline-flex h-8 w-8 items-center justify-center rounded-full bg-slate-900/80 border border-slate-700 shadow-md">
                                            <i class="fas fa-lightbulb text-yellow-300"></i>
                                        </span>
                                        <div class="flex flex-col">
                                            <span class="text-sm font-semibold text-slate-100">Gợi ý cùng thể loại</span>
                                            <span class="text-[11px] text-slate-400">Dựa trên: <%= primaryGenre != null ? primaryGenre : "Chung"%></span>
                                        </div>
                                    </div>
                                    <span class="text-[10px] px-2 py-0.5 rounded-full bg-slate-900/80 border border-slate-600 text-slate-300">
                                        <%= relatedBooks.size()%>
                                    </span>
                                </div>

                                <% if (relatedBooks.isEmpty()) { %>
                                <p class="text-xs text-slate-400 leading-relaxed">
                                    Hiện chưa có gợi ý thêm cho thể loại này. Thử xem các sách khác trong thư viện nhé.
                                </p>
                                <% } else { %>
                                <div class="flex flex-col gap-3 mt-1">
                                    <% for (RelatedBookDto rb : relatedBooks) {%>
                                    <a href="bookDetails.jsp?isbn=<%= rb.isbn%>"
                                       class="group flex gap-3 items-center px-2 py-2 rounded-xl bg-slate-900/70 border border-slate-700 hover:border-sky-400 hover:bg-slate-900/90 transition-colors">
                                        <div class="w-10 h-14 rounded-md overflow-hidden border border-slate-700 bg-slate-900/80 flex-shrink-0">
                                            <img src="<%= request.getContextPath() + "/" + rb.coverImage%>"
                                                 onerror="this.onerror=null; this.src='<%= request.getContextPath()%>/images/default-cover.jpg'"
                                                 class="w-full h-full object-cover" />
                                        </div>
                                        <div class="flex-1 min-w-0">
                                            <p class="text-xs font-semibold text-slate-50 line-clamp-2 group-hover:text-sky-400">
                                                <%= rb.title%>
                                            </p>
                                            <p class="text-[11px] text-slate-400 truncate mt-0.5">
                                                <i class="fas fa-user-pen text-[10px] mr-1"></i><%= rb.author%>
                                            </p>
                                        </div>
                                    </a>
                                    <% } %>
                                </div>
                                <% }%>
                            </aside>
                        </div>
                    </div>

                    <!-- Mô tả sách -->
                    <section class="mt-9 lg:mt-10 border-t border-slate-800 pt-7">
                        <h3 class="text-xl md:text-2xl font-semibold mb-4 flex items-center text-slate-50">
                            <span class="inline-flex h-9 w-9 items-center justify-center rounded-full bg-slate-900/90 border border-slate-700 mr-3 shadow-md">
                                <i class="fas fa-align-left text-sky-400"></i>
                            </span>
                            <span>Mô tả sách</span>
                        </h3>
                        <div class="bg-slate-900/70 border border-slate-700 rounded-2xl p-5 md:p-6 shadow-inner">
                            <p class="text-slate-200 leading-relaxed text-sm md:text-base">
                                <%= book.description != null ? book.description : "Chưa có mô tả cho cuốn sách này."%>
                            </p>
                        </div>
                    </section>
                </div>
            </section>
        </main>

        <!-- Toast notification -->
        <div id="toast"
             class="fixed bottom-6 right-6 px-4 py-3 rounded-lg shadow-lg border flex items-center space-x-3 bg-slate-900/95 hidden z-50">
            <span id="toast-icon" class="text-xl"></span>
            <div>
                <p id="toast-message" class="font-medium text-slate-100"></p>
            </div>
        </div>

        <!-- Popup xác nhận mượn sách -->
        <div id="borrow-modal"
             class="fixed inset-0 bg-black/50 flex items-center justify-center z-40 hidden">
            <div class="glass-effect w-full max-w-md rounded-2xl p-[2px]" style="animation: modalEnter 0.22s ease-out;">
                <div class="rounded-[1.3rem] bg-slate-950/95 p-6">
                    <h3 class="text-xl font-semibold mb-3 flex items-center text-slate-50">
                        <span class="inline-flex h-9 w-9 items-center justify-center rounded-full bg-slate-900/90 border border-slate-700 mr-3 shadow-md">
                            <i class="fas fa-question-circle text-indigo-400"></i>
                        </span>
                        <span>Xác nhận mượn sách</span>
                    </h3>
                    <p class="text-slate-300 mb-6 text-sm md:text-base">
                        Bạn có chắc chắn muốn đăng ký mượn cuốn sách này không?
                    </p>
                    <div class="flex justify-end space-x-3">
                        <button id="borrow-cancel"
                                class="px-4 py-2 rounded-xl border border-slate-600 text-slate-200 bg-slate-900/80 hover:bg-slate-800 hover:border-slate-400 text-sm font-medium transition">
                            Hủy
                        </button>
                        <button id="borrow-confirm"
                                class="px-4 py-2 rounded-xl bg-gradient-to-r from-indigo-500 to-blue-500 text-white text-sm font-semibold hover:from-indigo-400 hover:to-blue-400 shadow-md hover:shadow-lg transition">
                            Đồng ý
                        </button>
                    </div>
                </div>
            </div>
        </div>
        <%@ include file="./layout/footer.jsp" %>

        <!-- Scripts -->
        <script>
    const CTX = '<%=request.getContextPath()%>';
    const isbn = '<%= isbn%>';
    const isAvailable = <%= !book.isEbook() && book.availableCount > 0%>;

    function handleBack() {
        if (document.referrer && document.referrer !== '') {
            history.back();
        } else {
            window.location.href = CTX + '/index.jsp';
        }
    }

    (function () {
        const btnBorrow = document.getElementById('btnBorrow');
        if (!btnBorrow)
            return; // Ebook không có nút mượn

        const modal = document.getElementById('borrow-modal');
        const btnCancel = document.getElementById('borrow-cancel');
        const btnConfirm = document.getElementById('borrow-confirm');
        const toast = document.getElementById('toast');
        const toastIcon = document.getElementById('toast-icon');
        const toastMsg = document.getElementById('toast-message');
        const token = localStorage.getItem('token');

        // Modal
        function openModal() {
            if (!token) {
                showToast('error', 'Bạn cần đăng nhập trước khi mượn sách.');
                setTimeout(() => {
                    window.location.href = CTX + '/user/login.jsp';
                }, 1000);
                return;
            }

            if (!isAvailable) {
                showToast('error', 'Sách hiện tại đã hết. Vui lòng quay lại sau.');
                return;
            }

            modal.classList.remove('hidden');
        }

        function closeModal() {
            modal.classList.add('hidden');
        }

        // Toast helper
        let toastTimeout = null;
        function showToast(type, message) {
            let iconHtml = '';
            let borderClass = '';
            let textClass = '';

            switch (type) {
                case 'success':
                    iconHtml = '<i class="fas fa-check-circle text-emerald-400"></i>';
                    borderClass = 'border-emerald-500/60';
                    textClass = 'text-emerald-100';
                    break;
                case 'error':
                    iconHtml = '<i class="fas fa-exclamation-circle text-red-400"></i>';
                    borderClass = 'border-red-500/60';
                    textClass = 'text-red-100';
                    break;
                default:
                    iconHtml = '<i class="fas fa-info-circle text-sky-400"></i>';
                    borderClass = 'border-sky-500/60';
                    textClass = 'text-sky-100';
            }

            toast.className = 'fixed bottom-6 right-6 px-4 py-3 rounded-lg shadow-lg border flex items-center space-x-3 bg-slate-900/95 z-50';
            toast.classList.add(borderClass);
            toastMsg.className = 'font-medium ' + textClass;

            toastIcon.innerHTML = iconHtml;
            toastMsg.textContent = message;

            toast.classList.remove('hidden');
            toast.style.opacity = '1';

            if (toastTimeout)
                clearTimeout(toastTimeout);
            toastTimeout = setTimeout(() => {
                toast.style.opacity = '0';
                setTimeout(() => {
                    toast.classList.add('hidden');
                }, 300);
            }, 3000);
        }

        // Event listeners
        btnBorrow.addEventListener('click', (e) => {
            e.preventDefault();
            openModal();
        });

        btnCancel.addEventListener('click', () => {
            closeModal();
        });

        modal.addEventListener('click', (e) => {
            if (e.target === modal) {
                closeModal();
            }
        });

        // Đồng ý mượn
        btnConfirm.addEventListener('click', async () => {
            if (!token) {
                showToast('error', 'Bạn cần đăng nhập.');
                setTimeout(() => {
                    window.location.href = CTX + '/user/login.jsp';
                }, 1000);
                return;
            }

            try {
                btnConfirm.disabled = true;
                btnConfirm.classList.add('opacity-60', 'cursor-not-allowed');
                btnConfirm.textContent = 'Đang xử lý...';

                const resp = await fetch(CTX + '/api/borrow/request', {
                    method: 'POST',
                    headers: {
                        'Authorization': 'Bearer ' + token,
                        'Content-Type': 'application/json; charset=UTF-8',
                        'Accept': 'application/json'
                    },
                    body: JSON.stringify({isbn})
                });

                let data = {};
                try {
                    data = await resp.json();
                } catch (e) {
                    console.error('parse JSON error', e);
                }

                if (resp.ok) {
                    showToast('success', data.message || 'Đăng ký mượn thành công!');
                    // Reload sau 1.5s để cập nhật số lượng
                    setTimeout(() => {
                        location.reload();
                    }, 1500);
                } else {
                    showToast('error', data.message || ('Lỗi mượn sách: ' + resp.status));
                }
            } catch (err) {
                console.error(err);
                showToast('error', 'Không thể gọi API. Vui lòng thử lại sau.');
            } finally {
                btnConfirm.disabled = false;
                btnConfirm.classList.remove('opacity-60', 'cursor-not-allowed');
                btnConfirm.textContent = 'Đồng ý';
                closeModal();
            }
        });
    })();
        </script>
    </body>
</html>
