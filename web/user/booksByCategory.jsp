<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, Servlet.DBConnection, Data.Users" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sách theo danh mục - Thư viện</title>

    <!-- Tailwind CSS -->
    <script src="https://cdn.tailwindcss.com"></script>

    <!-- Font Awesome -->
    <link rel="stylesheet"
          href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css">

    <!-- Google Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap"
          rel="stylesheet">

    <!-- Favicon -->
    <link rel="icon" href="../images/reading-book.png" type="image/x-icon"/>

    <!-- Custom CSS -->
    <link rel="stylesheet" href="style1.css"/>

</head>
<body class="page-background">
<!-- Floating Background Elements -->
<div class="floating-elements">
    <i class="fas fa-book floating-book text-8xl text-blue-500" style="top: 5%; left: 80%;"></i>
    <i class="fas fa-bookmark floating-book text-6xl text-purple-500" style="top: 15%; left: 5%;"></i>
    <i class="fas fa-feather floating-book text-7xl text-green-500" style="top: 50%; left: 85%;"></i>
    <i class="fas fa-scroll floating-book text-5xl text-orange-500" style="top: 75%; left: 10%;"></i>
    <i class="fas fa-glasses floating-book text-6xl text-pink-500" style="top: 35%; left: 90%;"></i>
</div>

<!-- Header -->
<%@ include file="../user/layout/header.jsp" %>

<%
    String category = request.getParameter("category");
    if (category == null) category = "ALL";

    String categoryDisplayName;
    String categoryIcon;
    String categoryColor;

    switch (category) {
        case "HARDCOVER":
            categoryDisplayName = "Sách Bìa Cứng";
            categoryIcon = "fas fa-book";
            categoryColor = "blue";
            break;
        case "PAPERBACK":
            categoryDisplayName = "Sách Bìa Mềm";
            categoryIcon = "fas fa-book-open";
            categoryColor = "green";
            break;
        case "EBOOK":
            categoryDisplayName = "Ebook";
            categoryIcon = "fas fa-tablet-alt";
            categoryColor = "purple";
            break;
        default:
            categoryDisplayName = "Tất cả sách";
            categoryIcon = "fas fa-books";
            categoryColor = "sky";
    }

    Connection conn = null;
    List<Map<String, Object>> books = new ArrayList<>();

    int currentPage = 1;
    int booksPerPage = 15;
    int totalBooks = 0;

    try {
        String pageParam = request.getParameter("page");
        if (pageParam != null) currentPage = Integer.parseInt(pageParam);
    } catch (NumberFormatException e) {
        currentPage = 1;
    }

    int offset = (currentPage - 1) * booksPerPage;

    try {
        conn = DBConnection.getConnection();

        String countSql =
                "SELECT COUNT(*) AS total " +
                "FROM book b " +
                "LEFT JOIN author a ON b.authorId = a.id " +
                "WHERE b.status = 'ACTIVE'";

        if (!"ALL".equals(category)) {
            countSql += " AND b.format = ?";
        }

        PreparedStatement countStmt = conn.prepareStatement(countSql);
        if (!"ALL".equals(category)) {
            countStmt.setString(1, category);
        }
        ResultSet countRs = countStmt.executeQuery();
        if (countRs.next()) totalBooks = countRs.getInt("total");

        String sql =
                "SELECT b.isbn, b.title, a.name AS author, b.publicationYear, b.format, b.coverImage " +
                "FROM book b " +
                "LEFT JOIN author a ON b.authorId = a.id " +
                "WHERE b.status = 'ACTIVE'";

        if (!"ALL".equals(category)) {
            sql += " AND b.format = ?";
        }

        sql += " ORDER BY b.title LIMIT ? OFFSET ?";

        PreparedStatement stmt = conn.prepareStatement(sql);
        int idx = 1;
        if (!"ALL".equals(category)) {
            stmt.setString(idx++, category);
        }
        stmt.setInt(idx++, booksPerPage);
        stmt.setInt(idx, offset);

        ResultSet rs = stmt.executeQuery();
        while (rs.next()) {
            Map<String, Object> book = new HashMap<>();
            book.put("isbn", rs.getString("isbn"));
            book.put("title", rs.getString("title"));
            book.put("author", rs.getString("author"));
            book.put("publishedYear", rs.getInt("publicationYear"));
            book.put("format", rs.getString("format"));
            book.put("coverImage", rs.getString("coverImage"));
            books.add(book);
        }
    } catch (SQLException e) {
        e.printStackTrace();
    } finally {
        if (conn != null) try { conn.close(); } catch (SQLException ignore) {}
    }

    int totalPages = (int) Math.ceil((double) totalBooks / booksPerPage);
%>

<!-- Page Loader (reuse style từ index.css) -->
<div id="page-loader" role="status" aria-live="polite">
    <div class="spinner mb-6"></div>
    <div class="text-center mb-6">
        <div class="loader-title text-xl">Đang tải dữ liệu…</div>
        <div class="loader-sub text-sm">Vui lòng chờ trong giây lát</div>
    </div>

    <div class="shelf-skeleton px-6">
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
        <div class="sk-card">
            <div class="sk-img shimmer"></div>
            <div class="p-4 space-y-3">
                <div class="sk-line w1 shimmer relative"></div>
                <div class="sk-line w2 shimmer relative"></div>
                <div class="sk-line w3 shimmer relative"></div>
            </div>
        </div>
    </div>
</div>

<div id="app-content">
    <main class="container-enhanced mx-auto py-10 space-y-8">

        <!-- Breadcrumb -->
        <section class="mb-4">
            <div class="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-slate-900/70 border border-slate-700/70 shadow-lg shadow-slate-900/70 backdrop-blur">
                <a href="${pageContext.request.contextPath}/index.jsp"
                   class="flex items-center gap-1 text-xs sm:text-sm text-slate-200 hover:text-amber-300 transition-colors">
                    <i class="fas fa-home text-[10px]"></i>
                    <span>Trang chủ</span>
                </a>
                <i class="fas fa-chevron-right text-[10px] text-slate-400"></i>
                <span class="flex items-center gap-1 text-xs sm:text-sm text-slate-100/90">
                    <i class="<%= categoryIcon %> text-[11px]"></i>
                    <span><%= categoryDisplayName %></span>
                </span>
            </div>
        </section>

        <!-- Category Hero -->
        <section class="category-section mb-6">
            <div class="flex flex-col lg:flex-row gap-6 items-start lg:items-center justify-between">
                <div class="flex items-start gap-4">
                    <div class="w-16 h-16 rounded-2xl flex items-center justify-center shadow-xl shadow-slate-900/80
                                bg-gradient-to-br from-<%= categoryColor %>-500 to-<%= categoryColor %>-700 border border-white/20">
                        <i class="<%= categoryIcon %> text-2xl text-white"></i>
                    </div>
                    <div>
                        <h1 class="text-2xl sm:text-3xl md:text-4xl font-extrabold text-slate-50 tracking-tight mb-1">
                            <%= categoryDisplayName %>
                        </h1>
                        <p class="text-sm sm:text-base text-slate-300/90 max-w-xl">
                            Khám phá bộ sưu tập <span class="font-semibold lowercase"><%= categoryDisplayName %></span> được chọn lọc kỹ càng dành riêng cho bạn.
                        </p>
                        <div class="mt-3 flex flex-wrap gap-3 text-xs sm:text-sm">
                            <div class="inline-flex items-center gap-2 rounded-full border border-<%= categoryColor %>-300/60 bg-<%= categoryColor %>-500/10 px-3 py-1 text-<%= categoryColor %>-100 shadow-sm shadow-<%= categoryColor %>-500/40">
                                <i class="fas fa-layer-group text-[11px]"></i>
                                <span><%= totalBooks %> đầu sách đang có</span>
                            </div>
                            <div class="inline-flex items-center gap-2 rounded-full border border-slate-600/70 bg-slate-900/70 px-3 py-1 text-slate-200/90">
                                <i class="fas fa-info-circle text-[11px] text-sky-300"></i>
                                <span>Chỉ hiển thị sách đang hoạt động</span>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="flex flex-col sm:flex-row gap-3 items-stretch sm:items-center">
                    <div class="stats-card min-w-[180px] bg-slate-900/80 border border-slate-600/60 rounded-2xl px-4 py-3 shadow-xl shadow-slate-900/70">
                        <div class="text-xs text-slate-400 mb-1 flex items-center gap-1">
                            <i class="fas fa-chart-bar text-[11px] text-<%= categoryColor %>-300"></i>
                            <span>Thống kê nhanh</span>
                        </div>
                        <div class="flex items-end gap-2">
                            <div class="text-2xl font-bold text-<%= categoryColor %>-300 leading-none"><%= totalBooks %></div>
                            <div class="text-[11px] text-slate-400 mb-0.5">sách<br/>trong mục này</div>
                        </div>
                    </div>

                    <a href="${pageContext.request.contextPath}/index.jsp"
                       class="back-button inline-flex items-center justify-center gap-2 rounded-2xl border border-slate-500/70 bg-slate-900/80 px-4 py-3 text-sm font-semibold text-slate-100 hover:text-amber-200 hover:border-amber-300/70 hover:bg-slate-900 transition-all shadow-lg shadow-slate-900/70">
                        <i class="fas fa-arrow-left text-xs"></i>
                        <span>Quay về trang chủ</span>
                    </a>
                </div>
            </div>
        </section>

        <!-- Books Grid -->
        <section class="glass-effect rounded-3xl p-5 sm:p-6 lg:p-7">
            <% if (books.isEmpty()) { %>
                <div class="text-center py-12 sm:py-16">
                    <div class="w-28 h-28 mx-auto mb-6 rounded-full bg-slate-900/90 border border-slate-600 flex items-center justify-center shadow-xl shadow-slate-900/80">
                        <i class="fas fa-book-open text-4xl text-slate-400"></i>
                    </div>
                    <h3 class="text-2xl font-bold text-slate-50 mb-2">Không tìm thấy sách</h3>
                    <p class="text-slate-300/80 mb-6 max-w-xl mx-auto text-sm sm:text-base">
                        Hiện tại chưa có sách nào trong danh mục <span class="font-semibold lowercase"><%= categoryDisplayName %></span>.
                    </p>
                    <a href="${pageContext.request.contextPath}/index.jsp"
                       class="inline-flex items-center gap-2 rounded-full bg-amber-400 text-slate-900 px-6 py-2.5 text-sm font-semibold shadow-lg shadow-amber-500/50 hover:bg-amber-300 transition-all">
                        <i class="fas fa-arrow-left text-xs"></i>
                        <span>Quay lại</span>
                    </a>
                </div>
            <% } else { %>
                <div class="flex items-center justify-between gap-3 mb-4">
                    <div class="text-xs sm:text-sm text-slate-300/80">
                        Hiển thị
                        <span class="font-semibold text-amber-300">
                            <%= Math.min(booksPerPage, totalBooks - offset) %>
                        </span>
                        / <span class="font-semibold"><%= totalBooks %></span> sách
                    </div>
                </div>

                <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-5 sm:gap-6">
                    <% for (Map<String, Object> book : books) { %>
                        <div class="book-card w-full shine-effect group">
                            <a href="bookDetails.jsp?isbn=<%= book.get("isbn") %>" class="flex flex-col h-full">
                                <div class="book-image-container">
                                    <img src="<%= request.getContextPath() + "/" + book.get("coverImage") %>"
                                         onerror="this.onerror=null; this.src='<%= request.getContextPath() %>/images/default-cover.jpg';"
                                         alt="<%= book.get("title") %>"
                                         class="book-image transition-transform duration-300 group-hover:scale-105"/>

                                    <div class="book-overlay">
                                        <div class="inline-flex items-center gap-2 rounded-full bg-slate-900/80 px-3 py-1.5 border border-slate-500/70">
                                            <i class="fas fa-eye text-xs text-amber-300"></i>
                                            <span class="text-xs text-slate-100">Xem chi tiết</span>
                                        </div>
                                    </div>

                                    <% if ("EBOOK".equals(book.get("format"))) { %>
                                        <div class="absolute top-3 right-3 digital-badge">
                                            <i class="fas fa-download text-xs"></i>
                                            <span>Digital</span>
                                        </div>
                                    <% } %>
                                </div>

                                <div class="book-info">
                                    <h3 class="book-title line-clamp-2 group-hover:text-<%= categoryColor %>-300 transition-colors">
                                        <%= book.get("title") %>
                                    </h3>

                                    <div class="book-meta">
                                        <i class="fas fa-user-edit text-<%= categoryColor %>-300"></i>
                                        <span class="truncate"><%= book.get("author") %></span>
                                    </div>

                                    <div class="book-meta">
                                        <i class="fas fa-calendar text-<%= categoryColor %>-300"></i>
                                        <span><%= book.get("publishedYear") %></span>
                                    </div>

                                    <div class="book-meta">
                                        <i class="fas fa-tag text-<%= categoryColor %>-300"></i>
                                        <span class="uppercase tracking-wide text-[11px] text-<%= categoryColor %>-200 font-semibold">
                                            <%= book.get("format") %>
                                        </span>
                                    </div>
                                </div>
                            </a>
                        </div>
                    <% } %>
                </div>

                <!-- Pagination -->
                <% if (totalPages > 1) { %>
                    <div class="mt-8 flex justify-center">
                        <div class="inline-flex items-center gap-1 sm:gap-2 rounded-full bg-slate-900/80 border border-slate-600/70 px-3 sm:px-4 py-2 shadow-lg shadow-slate-900/80 text-xs sm:text-sm text-slate-200">
                            <% if (currentPage > 1) { %>
                                <a href="?category=<%= category %>&page=<%= currentPage - 1 %>"
                                   class="px-2 py-1 rounded-full hover:bg-slate-800/90 flex items-center gap-1">
                                    <i class="fas fa-chevron-left text-[10px]"></i>
                                    <span class="hidden sm:inline">Trước</span>
                                </a>
                            <% } %>

                            <%
                                int startPage = Math.max(1, currentPage - 2);
                                int endPage = Math.min(totalPages, currentPage + 2);

                                if (startPage > 1) {
                            %>
                                <a href="?category=<%= category %>&page=1"
                                   class="px-2 py-1 rounded-full hover:bg-slate-800/90">1</a>
                                <% if (startPage > 2) { %>
                                    <span class="px-1 text-slate-500">…</span>
                                <% } %>
                            <% } %>

                            <% for (int i = startPage; i <= endPage; i++) { %>
                                <% if (i == currentPage) { %>
                                    <span class="px-2 py-1 rounded-full bg-amber-400 text-slate-900 font-semibold">
                                        <%= i %>
                                    </span>
                                <% } else { %>
                                    <a href="?category=<%= category %>&page=<%= i %>"
                                       class="px-2 py-1 rounded-full hover:bg-slate-800/90">
                                        <%= i %>
                                    </a>
                                <% } %>
                            <% } %>

                            <% if (endPage < totalPages) { %>
                                <% if (endPage < totalPages - 1) { %>
                                    <span class="px-1 text-slate-500">…</span>
                                <% } %>
                                <a href="?category=<%= category %>&page=<%= totalPages %>"
                                   class="px-2 py-1 rounded-full hover:bg-slate-800/90">
                                    <%= totalPages %>
                                </a>
                            <% } %>

                            <% if (currentPage < totalPages) { %>
                                <a href="?category=<%= category %>&page=<%= currentPage + 1 %>"
                                   class="px-2 py-1 rounded-full hover:bg-slate-800/90 flex items-center gap-1">
                                    <span class="hidden sm:inline">Sau</span>
                                    <i class="fas fa-chevron-right text-[10px]"></i>
                                </a>
                            <% } %>
                        </div>
                    </div>
                <% } %>
            <% } %>
        </section>
    </main>
</div>

<!-- Footer -->
<jsp:include page="layout/footer.jsp"/>

<!-- Back to Top -->
<button id="backToTop"
        class="fixed bottom-8 right-8 w-11 h-11 bg-gradient-to-r from-blue-500 to-purple-600 text-white rounded-full shadow-lg hover:shadow-2xl transition-all duration-300 transform hover:scale-110 opacity-0 invisible flex items-center justify-center z-[60]">
    <i class="fas fa-arrow-up text-sm"></i>
</button>

<!-- Page script -->
<script>
    // Back to top
    const backToTopButton = document.getElementById('backToTop');
    window.addEventListener('scroll', () => {
        if (window.pageYOffset > 300) {
            backToTopButton.classList.remove('opacity-0', 'invisible');
            backToTopButton.classList.add('opacity-100', 'visible');
        } else {
            backToTopButton.classList.add('opacity-0', 'invisible');
            backToTopButton.classList.remove('opacity-100', 'visible');
        }
    });
    backToTopButton.addEventListener('click', () => {
        window.scrollTo({top: 0, behavior: 'smooth'});
    });

    // Animate book cards
    const bookCards = document.querySelectorAll('.book-card');
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, {threshold: 0.1, rootMargin: '0px 0px -50px 0px'});

    bookCards.forEach(card => {
        card.style.opacity = '0';
        card.style.transform = 'translateY(18px)';
        card.style.transition = 'opacity 0.55s ease, transform 0.55s ease';
        observer.observe(card);
    });

    // Floating elements parallax nhẹ
    window.addEventListener('scroll', function () {
        const scrolled = window.pageYOffset;
        document.querySelectorAll('.floating-book').forEach((el, i) => {
            const speed = 0.4 + (i * 0.08);
            el.style.transform = `translateY(${scrolled * speed}px) rotate(${scrolled * 0.05}deg)`;
        });
    });
</script>

<!-- Ripple effect + một chút override nhỏ -->
<style>
    .book-card {
        will-change: transform, opacity;
    }
    .book-card .book-image {
        will-change: transform;
    }
    /* nhỏ lại grid trên mobile */
    @media (max-width: 640px) {
        .glass-effect .grid {
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 0.85rem;
        }
    }
</style>

<script src="script.js"></script>
</body>
</html>
