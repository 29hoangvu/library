<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*" %>
<%@ page import="service.BookDetailService, service.ReservationService" %>
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
            ReservationService reservationService = new ReservationService();
            BookDetailDto book = null;
            List<RelatedBookDto> relatedBooks = new ArrayList<>();
            String errorMessage = null;
            
            // Biến để lưu thông tin đặt trước (sẽ fetch từ client-side qua API)
            int waitingCount = 0;
            
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
            
            // Lấy số người chờ (public info, không cần auth)
            if (!book.isEbook()) {
                waitingCount = reservationService.getWaitingCount(isbn);
            }

        } catch (Exception e) {
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

            <!-- Thông báo nếu user đã đặt trước (sẽ được hiển thị qua JavaScript) -->
            <div id="reservation-banner" class="mb-5 glass-effect rounded-2xl p-[2px] hidden">
                <div class="rounded-[1.3rem] bg-gradient-to-r from-amber-900/30 to-orange-900/30 px-4 py-3">
                    <div class="flex items-center gap-3">
                        <div class="flex-shrink-0">
                            <div class="w-10 h-10 rounded-full bg-amber-500/20 flex items-center justify-center">
                                <i class="fas fa-clock text-amber-400 text-lg"></i>
                            </div>
                        </div>
                        <div class="flex-1">
                            <p class="text-amber-200 font-semibold text-sm">
                                Bạn đang trong hàng chờ đặt trước
                            </p>
                            <p class="text-amber-300/80 text-xs mt-0.5">
                                Vị trí: <span id="queue-position" class="font-bold">-</span> / <span id="total-waiting">-</span> người đang chờ
                            </p>
                        </div>
                        <button id="btnCancelReservation"
                                data-reservation-isbn="<%= isbn %>"
                                class="flex-shrink-0 px-3 py-1.5 rounded-lg bg-slate-800/50 border border-slate-600 text-slate-300 text-xs font-medium hover:bg-slate-700/50 hover:border-slate-500 transition">
                            Hủy đặt trước
                        </button>
                    </div>
                </div>
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
                            <div id="action-buttons-container" class="w-full max-w-sm flex flex-col sm:flex-row gap-3">
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
                                    <!-- Buttons sẽ được render động bởi JavaScript dựa trên reservation status -->
                                    <% if (book.availableCount > 0) { %>
                                    <button id="btnBorrow"
                                            class="w-full inline-flex items-center justify-center gap-2 px-4 py-3 rounded-xl bg-gradient-to-r from-indigo-500 to-blue-500 text-white hover:from-indigo-400 hover:to-blue-400 hover:-translate-y-0.5 font-semibold shadow-lg hover:shadow-xl transition-transform duration-200">
                                        <i class="fas fa-hand-holding"></i>
                                        <span>Đăng ký mượn</span>
                                    </button>
                                    <% } else { %>
                                    <!-- Template cho nút đặt trước - sẽ được toggle bởi JS -->
                                    <button id="btnReserve"
                                            class="w-full inline-flex items-center justify-center gap-2 px-4 py-3 rounded-xl bg-gradient-to-r from-amber-500 to-orange-500 text-white hover:from-amber-400 hover:to-orange-400 hover:-translate-y-0.5 font-semibold shadow-lg hover:shadow-xl transition-transform duration-200">
                                        <i class="fas fa-clock"></i>
                                        <span id="reserve-btn-text">Đặt trước</span>
                                    </button>
                                    <button id="btnAlreadyReserved" style="display: none;"
                                            disabled
                                            class="w-full inline-flex items-center justify-center gap-2 px-4 py-3 rounded-xl bg-slate-700 text-slate-400 cursor-not-allowed font-semibold shadow-lg">
                                        <i class="fas fa-check-circle"></i>
                                        <span>Đã đặt trước</span>
                                    </button>
                                    <% } %>
                                <% }%>
                            </div>
                            
                            <!-- Hiển thị số người đang chờ -->
                            <% if (!book.isEbook() && book.availableCount == 0) { %>
                            <div id="waiting-count-display" class="w-full max-w-sm text-center" style="display: none;">
                                <div class="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-slate-800/50 border border-slate-700 text-slate-300 text-sm">
                                    <i class="fas fa-users text-amber-400"></i>
                                    <span id="waiting-count-text"><%= waitingCount %> người đang chờ đặt trước</span>
                                </div>
                            </div>
                            <% } %>
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
                                    String primaryGenreSidebar = book.genres.isEmpty() ? null : book.genres.get(0);
                                %>
                                <div class="flex items-center justify-between mb-3">
                                    <div class="flex items-center gap-2">
                                        <span class="inline-flex h-8 w-8 items-center justify-center rounded-full bg-slate-900/80 border border-slate-700 shadow-md">
                                            <i class="fas fa-lightbulb text-yellow-300"></i>
                                        </span>
                                        <div class="flex flex-col">
                                            <span class="text-sm font-semibold text-slate-100">Gợi ý cùng thể loại</span>
                                            <span class="text-[11px] text-slate-400">Dựa trên: <%= primaryGenreSidebar != null ? primaryGenreSidebar : "Chung"%></span>
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
        
        <!-- Popup xác nhận đặt trước -->
        <div id="reserve-modal"
             class="fixed inset-0 bg-black/50 flex items-center justify-center z-40 hidden">
            <div class="glass-effect w-full max-w-md rounded-2xl p-[2px]" style="animation: modalEnter 0.22s ease-out;">
                <div class="rounded-[1.3rem] bg-slate-950/95 p-6">
                    <h3 class="text-xl font-semibold mb-3 flex items-center text-slate-50">
                        <span class="inline-flex h-9 w-9 items-center justify-center rounded-full bg-slate-900/90 border border-slate-700 mr-3 shadow-md">
                            <i class="fas fa-clock text-amber-400"></i>
                        </span>
                        <span>Xác nhận đặt trước sách</span>
                    </h3>
                    <div class="text-slate-300 mb-6 text-sm md:text-base space-y-3">
                        <p>Sách hiện tại đã hết. Bạn có muốn đặt trước không?</p>
                        <div class="bg-slate-800/50 border border-slate-700 rounded-lg p-3 text-xs space-y-2">
                            <p class="flex items-start gap-2">
                                <i class="fas fa-info-circle text-blue-400 mt-0.5"></i>
                                <span>Khi có sách trống, bạn sẽ được thông báo qua email (trong vòng 72 giờ)</span>
                            </p>
                            <p id="reserve-modal-waiting" class="flex items-start gap-2" style="display: none;">
                                <i class="fas fa-users text-amber-400 mt-0.5"></i>
                                <span>Hiện có <strong id="reserve-modal-waiting-count">0</strong> người đang chờ trước bạn</span>
                            </p>
                        </div>
                    </div>
                    <div class="flex justify-end space-x-3">
                        <button id="reserve-cancel"
                                class="px-4 py-2 rounded-xl border border-slate-600 text-slate-200 bg-slate-900/80 hover:bg-slate-800 hover:border-slate-400 text-sm font-medium transition">
                            Hủy
                        </button>
                        <button id="reserve-confirm"
                                class="px-4 py-2 rounded-xl bg-gradient-to-r from-amber-500 to-orange-500 text-white text-sm font-semibold hover:from-amber-400 hover:to-orange-400 shadow-md hover:shadow-lg transition">
                            Đồng ý đặt trước
                        </button>
                    </div>
                </div>
            </div>
        </div>
        <!-- Cancel Reservation Modal -->
        <div id="cancel-reservation-modal"
             class="fixed inset-0 bg-black/50 flex items-center justify-center z-40 hidden">
            <div class="glass-effect w-full max-w-md rounded-2xl p-[2px]"
                 style="animation: modalEnter 0.22s ease-out;">
                <div class="rounded-[1.3rem] bg-slate-950/95 p-6">
                    <h3 class="text-xl font-semibold mb-3 flex items-center text-slate-50">
                        <span class="inline-flex h-9 w-9 items-center justify-center rounded-full
                                     bg-slate-900/90 border border-slate-700 mr-3 shadow-md">
                            <i class="fas fa-exclamation-triangle text-red-400"></i>
                        </span>
                        <span>Xác nhận hủy đặt trước</span>
                    </h3>

                    <p class="text-slate-300 mb-6 text-sm md:text-base">
                        Bạn có chắc chắn muốn <span class="text-red-400 font-medium">hủy đặt trước</span>
                        cuốn sách này không? Hành động này không thể hoàn tác.
                    </p>

                    <div class="flex justify-end space-x-3">
                        <button id="cancel-reservation-cancel"
                                class="px-4 py-2 rounded-xl border border-slate-600
                                       text-slate-200 bg-slate-900/80
                                       hover:bg-slate-800 hover:border-slate-400
                                       text-sm font-medium transition">
                            Hủy
                        </button>
                        <button id="cancel-reservation-confirm"
                                class="px-4 py-2 rounded-xl
                                       bg-gradient-to-r from-red-500 to-rose-500
                                       text-white text-sm font-semibold
                                       hover:from-red-400 hover:to-rose-400
                                       shadow-md hover:shadow-lg transition">
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
    const isEbook = <%= book.isEbook() %>;

    function handleBack() {
        if (document.referrer && document.referrer !== '') {
            history.back();
        } else {
            window.location.href = CTX + '/index.jsp';
        }
    }
    function confirmCancelReservation() {
        return new Promise(resolve => {
            const modal = document.getElementById('cancel-reservation-modal');
            const btnOk = document.getElementById('cancel-reservation-confirm');
            const btnCancel = document.getElementById('cancel-reservation-cancel');

            modal.classList.remove('hidden');

            const cleanup = () => {
                modal.classList.add('hidden');
                btnOk.onclick = null;
                btnCancel.onclick = null;
            };

            btnOk.onclick = () => {
                cleanup();
                resolve(true);
            };

            btnCancel.onclick = () => {
                cleanup();
                resolve(false);
            };
        });
    }

    (function () {
        const btnBorrow = document.getElementById('btnBorrow');
        const btnReserve = document.getElementById('btnReserve');
        const btnAlreadyReserved = document.getElementById('btnAlreadyReserved');
        const btnCancelReservation = document.getElementById('btnCancelReservation');
        
        const borrowModal = document.getElementById('borrow-modal');
        const reserveModal = document.getElementById('reserve-modal');
        const toast = document.getElementById('toast');
        const toastIcon = document.getElementById('toast-icon');
        const toastMsg = document.getElementById('toast-message');
        const token = localStorage.getItem('token');
        
        const reservationBanner = document.getElementById('reservation-banner');
        const queuePositionEl = document.getElementById('queue-position');
        const totalWaitingEl = document.getElementById('total-waiting');
        const waitingCountDisplay = document.getElementById('waiting-count-display');
        const waitingCountText = document.getElementById('waiting-count-text');
        const reserveBtnText = document.getElementById('reserve-btn-text');
        const reserveModalWaiting = document.getElementById('reserve-modal-waiting');
        const reserveModalWaitingCount = document.getElementById('reserve-modal-waiting-count');

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
        
        // === FETCH RESERVATION STATUS ===
        async function checkReservationStatus() {
            if (!token || isEbook || isAvailable) {
                // Nếu không có token hoặc là ebook hoặc còn sách → không cần check
                // Hiện số người chờ nếu hết sách
                if (!isEbook && !isAvailable && waitingCountDisplay) {
                    waitingCountDisplay.style.display = 'block';
                }
                return;
            }
            
            try {
                const resp = await fetch(CTX + '/api/reservation/status?isbn=' + isbn, {
                    method: 'GET',
                    headers: {
                        'Authorization': 'Bearer ' + token,
                        'Accept': 'application/json'
                    }
                });
                
                if (!resp.ok) {
                    console.error('Failed to fetch reservation status:', resp.status);
                    return;
                }
                
                const data = await resp.json();
                
                if (data.hasReservation) {
                    // User đã đặt trước → hiện banner + đổi button
                    reservationBanner.classList.remove('hidden');
                    if (queuePositionEl) queuePositionEl.textContent = data.queuePosition || '-';
                    if (totalWaitingEl) totalWaitingEl.textContent = data.waitingCount || 0;
                    
                    // Ẩn nút đặt trước, hiện nút đã đặt trước
                    if (btnReserve) btnReserve.style.display = 'none';
                    if (btnAlreadyReserved) btnAlreadyReserved.style.display = 'flex';
                } else {
                    // User chưa đặt trước
                    const waitingCount = data.waitingCount || 0;
                    
                    // Update nút đặt trước
                    if (reserveBtnText && waitingCount > 0) {
                        reserveBtnText.textContent = 'Đặt trước (' + waitingCount + ' người chờ)';
                    }
                    
                    // Update modal
                    if (reserveModalWaitingCount) {
                        reserveModalWaitingCount.textContent = waitingCount;
                    }
                    if (reserveModalWaiting && waitingCount > 0) {
                        reserveModalWaiting.style.display = 'flex';
                    }
                    
                    // Hiện số người chờ
                    if (waitingCountDisplay && waitingCount > 0) {
                        waitingCountText.textContent = waitingCount + ' người đang chờ đặt trước';
                        waitingCountDisplay.style.display = 'block';
                    }
                }
            } catch (err) {
                console.error('Error checking reservation status:', err);
            }
        }
        
        // Check status khi load page
        if (!isEbook && !isAvailable) {
            checkReservationStatus();
        }
        
        // === MƯỢN SÁCH ===
        if (btnBorrow) {
            const btnBorrowCancel = document.getElementById('borrow-cancel');
            const btnBorrowConfirm = document.getElementById('borrow-confirm');
            
            btnBorrow.addEventListener('click', (e) => {
                e.preventDefault();
                if (!token) {
                    showToast('error', 'Bạn cần đăng nhập trước khi mượn sách.');
                    setTimeout(() => {
                        window.location.href = CTX + '/user/login.jsp';
                    }, 1000);
                    return;
                }
                borrowModal.classList.remove('hidden');
            });

            btnBorrowCancel.addEventListener('click', () => {
                borrowModal.classList.add('hidden');
            });

            borrowModal.addEventListener('click', (e) => {
                if (e.target === borrowModal) {
                    borrowModal.classList.add('hidden');
                }
            });

            btnBorrowConfirm.addEventListener('click', async () => {
                try {
                    btnBorrowConfirm.disabled = true;
                    btnBorrowConfirm.classList.add('opacity-60', 'cursor-not-allowed');
                    btnBorrowConfirm.textContent = 'Đang xử lý...';

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
                    btnBorrowConfirm.disabled = false;
                    btnBorrowConfirm.classList.remove('opacity-60', 'cursor-not-allowed');
                    btnBorrowConfirm.textContent = 'Đồng ý';
                    borrowModal.classList.add('hidden');
                }
            });
        }
        
        // === ĐẶT TRƯỚC ===
        if (btnReserve) {
            const btnReserveCancel = document.getElementById('reserve-cancel');
            const btnReserveConfirm = document.getElementById('reserve-confirm');
            
            btnReserve.addEventListener('click', (e) => {
                e.preventDefault();
                if (!token) {
                    showToast('error', 'Bạn cần đăng nhập trước khi đặt trước sách.');
                    setTimeout(() => {
                        window.location.href = CTX + '/user/login.jsp';
                    }, 1000);
                    return;
                }
                reserveModal.classList.remove('hidden');
            });

            btnReserveCancel.addEventListener('click', () => {
                reserveModal.classList.add('hidden');
            });

            reserveModal.addEventListener('click', (e) => {
                if (e.target === reserveModal) {
                    reserveModal.classList.add('hidden');
                }
            });

            btnReserveConfirm.addEventListener('click', async () => {
                try {
                    btnReserveConfirm.disabled = true;
                    btnReserveConfirm.classList.add('opacity-60', 'cursor-not-allowed');
                    btnReserveConfirm.textContent = 'Đang xử lý...';

                    const resp = await fetch(CTX + '/api/reservation/create', {
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
                        showToast('success', data.message || 'Đặt trước thành công!');
                        setTimeout(() => {
                            location.reload();
                        }, 1500);
                    } else {
                        showToast('error', data.message || ('Lỗi đặt trước: ' + resp.status));
                    }
                } catch (err) {
                    console.error(err);
                    showToast('error', 'Không thể gọi API. Vui lòng thử lại sau.');
                } finally {
                    btnReserveConfirm.disabled = false;
                    btnReserveConfirm.classList.remove('opacity-60', 'cursor-not-allowed');
                    btnReserveConfirm.textContent = 'Đồng ý đặt trước';
                    reserveModal.classList.add('hidden');
                }
            });
        }
        
        // === HỦY ĐẶT TRƯỚC (WITH DEBUG LOGS) ===
if (btnCancelReservation) {
    btnCancelReservation.addEventListener('click', async (e) => {
        e.preventDefault();

        const ok = await confirmCancelReservation();
        if (!ok) return;

        if (!token) {
            showToast('error', 'Bạn cần đăng nhập.');
            return;
        }

        try {
            btnCancelReservation.disabled = true;
            btnCancelReservation.textContent = 'Đang xử lý...';

            // ✅ BƯỚC 1: Fetch danh sách đặt trước
            console.log('🔍 Step 1: Fetching reservation list for ISBN:', isbn);
            
            const listResp = await fetch(CTX + '/api/reservation/my-list?active=true', {
                headers: {
                    'Authorization': 'Bearer ' + token,
                    'Accept': 'application/json'
                }
            });

            if (!listResp.ok) {
                console.error('❌ Failed to fetch list:', listResp.status);
                throw new Error('Không thể lấy danh sách đặt trước');
            }

            // ✅ BƯỚC 2: Parse response
            const reservations = await listResp.json();
            console.log('📋 Step 2: Full reservation list:', reservations);
            console.log('📋 Total reservations:', reservations.length);

            // ✅ BƯỚC 3: Tìm reservation theo ISBN
            console.log('🔍 Step 3: Looking for ISBN:', isbn);
            const reservation = reservations.find(r => {
                console.log('  - Checking reservation:', {
                    isbn: r.isbn,
                    id: r.id,
                    reservationId: r.reservationId,
                    status: r.status
                });
                return r.isbn === isbn;
            });

            if (!reservation) {
                console.error('❌ Step 3 Failed: No reservation found for ISBN:', isbn);
                console.log('Available ISBNs in list:', reservations.map(r => r.isbn));
                showToast('error', 'Không tìm thấy đặt trước này');
                return;
            }

            console.log('✅ Step 3 Success: Found reservation:', reservation);

            // ✅ BƯỚC 4: Lấy ID
            const reservationId = reservation.id || reservation.reservationId;
            console.log('🆔 Step 4: Extracted ID:', reservationId);

            if (!reservationId) {
                console.error('❌ Step 4 Failed: No ID found in reservation object:', reservation);
                showToast('error', 'Lỗi: Không tìm thấy ID đặt trước');
                return;
            }

            // ✅ BƯỚC 5: Gọi API hủy
            console.log('📤 Step 5: Calling cancel API with ID:', reservationId);
            
            const resp = await fetch(CTX + '/api/reservation/cancel', {
                method: 'POST',
                headers: {
                    'Authorization': 'Bearer ' + token,
                    'Content-Type': 'application/json; charset=UTF-8',
                    'Accept': 'application/json'
                },
                body: JSON.stringify({ reservationId: reservationId })
            });

            console.log('📥 Step 5: API Response status:', resp.status);

            const data = await resp.json().catch(() => ({}));
            console.log('📥 Step 5: API Response data:', data);

            if (resp.ok) {
                console.log('✅ Success: Reservation cancelled');
                showToast('success', data.message || 'Hủy đặt trước thành công!');
                setTimeout(() => location.reload(), 1500);
            } else {
                console.error('❌ Failed:', data);
                showToast('error', data.message || ('Lỗi hủy đặt trước: ' + resp.status));
            }

        } catch (err) {
            console.error('💥 Exception:', err);
            showToast('error', 'Không thể gọi API. Vui lòng thử lại sau.');
        } finally {
            btnCancelReservation.disabled = false;
            btnCancelReservation.textContent = 'Hủy đặt trước';
        }
    });
}

    })();
        </script>
    </body>
</html>
