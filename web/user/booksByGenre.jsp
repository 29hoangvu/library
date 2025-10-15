<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, Servlet.DBConnection" %>
<!DOCTYPE html>
<html lang="vi">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Sách theo thể loại</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css">
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
        <link rel="icon" href="./images/reading-book.png" type="image/x-icon" />
        <link rel="stylesheet" href="style.css"/>
        <link rel="stylesheet" href="loading.css"/>
        <style>
            * {
                font-family: 'Inter', sans-serif;
            }
            .book-card {
                transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
                will-change: transform, opacity;
            }
            .book-card:hover {
                transform: translateY(-12px) scale(1.03);
                box-shadow: 0 25px 50px rgba(0,0,0,0.15);
            }
            .book-card:hover .book-image {
                transform: scale(1.1);
            }
            .book-image {
                transition: transform 0.4s ease;
                will-change: transform;
            }
            .shine-effect {
                position: relative;
                overflow: hidden;
            }
            .shine-effect::before {
                content: '';
                position: absolute;
                top: 0;
                left: -100%;
                width: 100%;
                height: 100%;
                background: linear-gradient(90deg, transparent, rgba(255,255,255,0.3), transparent);
                transition: left 0.5s;
            }
            .shine-effect:hover::before {
                left: 100%;
            }
            .ripple {
                position: absolute;
                border-radius: 50%;
                background: rgba(255, 255, 255, 0.6);
                transform: scale(0);
                animation: ripple-animation 0.6s linear;
                pointer-events: none;
            }
            @keyframes ripple-animation {
                to {
                    transform: scale(4);
                    opacity: 0;
                }
            }
        </style>
    </head>

    <body class="page-background">
        <!-- Floating Background Elements -->
        <div class="floating-elements">
            <i class="fas fa-book floating-book text-8xl text-blue-500" style="top: 5%; left: 80%; animation-delay: 0s;"></i>
            <i class="fas fa-bookmark floating-book text-6xl text-purple-500" style="top: 15%; left: 5%; animation-delay: 2s;"></i>
            <i class="fas fa-feather floating-book text-7xl text-green-500" style="top: 50%; left: 85%; animation-delay: 4s;"></i>
            <i class="fas fa-scroll floating-book text-5xl text-orange-500" style="top: 75%; left: 10%; animation-delay: 6s;"></i>
            <i class="fas fa-glasses floating-book text-6xl text-pink-500" style="top: 35%; left: 90%; animation-delay: 8s;"></i>
        </div>

        <%@ include file="layout/header.jsp" %>

        <main class="max-w-7xl mx-auto px-4 py-8">
            <!-- Page Loader -->
            <div id="page-loader" role="status" aria-live="polite">
                <div class="spinner mb-6"></div>
                <div class="text-center mb-6">
                    <div class="loader-title text-xl">Đang tải dữ liệu…</div>
                    <div class="loader-sub text-sm">Vui lòng chờ trong giây lát</div>
                </div>

                <!-- Skeleton: 1 hàng sách giả để người dùng có gì đó nhìn -->
                <div class="shelf-skeleton px-6">
                    <!-- lặp vài thẻ giả (5–7 cái) -->
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
            <div id="app-content">
            <%
                request.setCharacterEncoding("UTF-8");
                String genreName = request.getParameter("name");
                if (genreName == null || genreName.trim().isEmpty()) {
            %>
            <div class="bg-gradient-to-r from-red-50 to-red-100 border-l-4 border-red-500 rounded-xl p-6 shadow-lg">
                <div class="flex items-center">
                    <i class="fas fa-exclamation-circle text-red-500 text-3xl mr-4"></i>
                    <div>
                        <h3 class="text-lg font-semibold text-red-800">Lỗi tham số</h3>
                        <p class="text-red-600">Thiếu tham số <code class="bg-red-200 px-2 py-1 rounded">name</code> của thể loại.</p>
                    </div>
                </div>
            </div>
            <%
            } else {
                // Pagination
                int booksPerPage = 12;
                try {
                    booksPerPage = Math.max(1, Math.min(60, Integer.parseInt(request.getParameter("size"))));
                } catch (Exception ignore) {}
                
                int currentPage = 1;
                try {
                    currentPage = Math.max(1, Integer.parseInt(request.getParameter("page")));
                } catch (Exception ignore) {}
                
                int offset = (currentPage - 1) * booksPerPage;

                // Sort
                String sort = request.getParameter("sort");
                String orderBy = "b.id DESC";
                if ("oldest".equalsIgnoreCase(sort)) {
                    orderBy = "b.id ASC";
                } else if ("title".equalsIgnoreCase(sort)) {
                    orderBy = "b.title ASC";
                } else if ("year".equalsIgnoreCase(sort)) {
                    orderBy = "b.publicationYear DESC";
                }

                int totalBooks = 0;
                int totalPages = 1;
                List<Map<String, Object>> books = new ArrayList<>();

                try (Connection conn = DBConnection.getConnection()) {
                    Integer gid = null;
                    try (PreparedStatement ps = conn.prepareStatement("SELECT id FROM genre WHERE name=?")) {
                        ps.setString(1, genreName);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) {
                                gid = rs.getInt(1);
                            }
                        }
                    }

                    if (gid == null) {
            %>
            <div class="bg-gradient-to-r from-yellow-50 to-yellow-100 border-l-4 border-yellow-500 rounded-xl p-6 shadow-lg">
                <div class="flex items-center">
                    <i class="fas fa-search text-yellow-500 text-3xl mr-4"></i>
                    <div>
                        <h3 class="text-lg font-semibold text-yellow-800">Không tìm thấy</h3>
                        <p class="text-yellow-600">Không tìm thấy thể loại: <strong><%= genreName%></strong></p>
                    </div>
                </div>
            </div>
            <%
                    } else {
                        // Count
                        try (PreparedStatement ps = conn.prepareStatement(
                                "SELECT COUNT(*) FROM book b JOIN book_genre bg ON bg.book_id=b.id WHERE bg.genre_id=?"
                        )) {
                            ps.setInt(1, gid);
                            try (ResultSet rs = ps.executeQuery()) {
                                if (rs.next()) {
                                    totalBooks = rs.getInt(1);
                                }
                            }
                        }
                        totalPages = Math.max(1, (totalBooks + booksPerPage - 1) / booksPerPage);

                        // Get books
                        String sql = "SELECT b.isbn, b.title, a.name AS author, b.publicationYear, b.format, b.coverImage "
                                + "FROM book b "
                                + "JOIN book_genre bg ON bg.book_id = b.id "
                                + "LEFT JOIN author a ON a.id = b.authorId "
                                + "WHERE bg.genre_id = ? "
                                + "ORDER BY " + orderBy + " "
                                + "LIMIT ? OFFSET ?";
                        try (PreparedStatement ps = conn.prepareStatement(sql)) {
                            ps.setInt(1, gid);
                            ps.setInt(2, booksPerPage);
                            ps.setInt(3, offset);
                            try (ResultSet rs = ps.executeQuery()) {
                                while (rs.next()) {
                                    Map<String, Object> m = new HashMap<>();
                                    m.put("isbn", rs.getString("isbn"));
                                    m.put("title", rs.getString("title"));
                                    m.put("author", rs.getString("author"));
                                    m.put("publishedYear", rs.getInt("publicationYear"));
                                    m.put("format", rs.getString("format"));
                                    m.put("coverImage", rs.getString("coverImage"));
                                    books.add(m);
                                }
                            }
                        }
            %>

            <!-- Breadcrumb -->
            <div class="breadcrumb">
                <nav class="flex items-center space-x-2 text-sm font-medium">
                    <a href="${pageContext.request.contextPath}/index.jsp" class="text-blue-600 hover:text-blue-800 transition-colors">
                        <i class="fas fa-home mr-1"></i>Trang chủ
                    </a>
                    <i class="fas fa-chevron-right text-gray-400"></i>
                    <span class="text-gray-700">
                        <i class="fas fa-tags mr-1"></i><%= genreName%>
                    </span>
                </nav>
            </div>

            <!-- Category Header -->
            <div class="category-header">
                <div class="flex items-center justify-between flex-wrap gap-4">
                    <div class="flex items-center space-x-4">
                        <div class="w-16 h-16 bg-gradient-to-br from-blue-500 to-blue-600 rounded-full flex items-center justify-center">
                            <i class="fas fa-bookmark text-2xl text-white"></i>
                        </div>
                        <div>
                            <h1 class="text-4xl font-bold text-gray-800 mb-2"><%= genreName%></h1>
                            <p class="text-gray-600 text-lg">Khám phá bộ sưu tập <%= genreName.toLowerCase()%> phong phú</p>
                        </div>
                    </div>

                    <div class="flex items-center space-x-4">
                        <div class="stats-card">
                            <div class="text-2xl font-bold text-blue-600"><%= totalBooks%></div>
                            <div class="text-sm text-gray-600">Tổng số sách</div>
                        </div>
                        <a href="../index.jsp" class="back-button">
                            <i class="fas fa-arrow-left"></i>
                            <span>Quay lại</span>
                        </a>
                    </div>
                </div>
            </div>

            <!-- Filter Form -->
            <div class="bg-white rounded-2xl shadow-md p-6 mb-8">
                <form class="flex flex-wrap items-center gap-4" method="get" action="booksByGenre.jsp">
                    <input type="hidden" name="name" value="<%= genreName%>">
                    <input type="hidden" name="page" value="1">

                    <div class="flex items-center gap-2">
                        <label class="text-sm font-semibold text-gray-700 flex items-center">
                            <i class="fas fa-sort-amount-down mr-2 text-blue-500"></i>
                            Sắp xếp
                        </label>
                        <select name="sort" class="border-2 border-gray-200 rounded-lg px-4 py-2 focus:border-blue-500 focus:outline-none transition-colors bg-white">
                            <option value="newest" <%= "newest".equalsIgnoreCase(sort) || sort == null ? "selected" : ""%>>Mới nhất</option>
                            <option value="oldest" <%= "oldest".equalsIgnoreCase(sort) ? "selected" : ""%>>Cũ nhất</option>
                            <option value="title"  <%= "title".equalsIgnoreCase(sort) ? "selected" : ""%>>Theo tên</option>
                            <option value="year"   <%= "year".equalsIgnoreCase(sort) ? "selected" : ""%>>Theo năm XB</option>
                        </select>
                    </div>

                    <div class="flex items-center gap-2">
                        <label class="text-sm font-semibold text-gray-700 flex items-center">
                            <i class="fas fa-list mr-2 text-blue-500"></i>
                            Mỗi trang
                        </label>
                        <select name="size" class="border-2 border-gray-200 rounded-lg px-4 py-2 focus:border-blue-500 focus:outline-none transition-colors bg-white">
                            <option <%= booksPerPage == 10 ? "selected" : ""%>>10</option>
                            <option <%= booksPerPage == 20 ? "selected" : ""%>>20</option>
                            <option <%= booksPerPage == 40 ? "selected" : ""%>>40</option>
                            <option <%= booksPerPage == 60 ? "selected" : ""%>>60</option>
                        </select>
                    </div>

                    <button type="submit" class="bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 text-white px-6 py-2 rounded-lg font-semibold shadow-md hover:shadow-lg transition-all duration-300 transform hover:scale-105">
                        <i class="fas fa-check mr-2"></i>
                        Áp dụng
                    </button>
                </form>
            </div>

            <!-- Books Grid -->
            <div class="book-grid">
                <% for (Map<String, Object> book : books) {%>
                <div class="book-card rounded-3xl shadow-lg hover:shadow-2xl group shine-effect">
                    <a href="bookDetails.jsp?isbn=<%= book.get("isbn")%>" class="block">
                        <div class="book-image-container">
                            <img src="<%= request.getContextPath() + "/" + book.get("coverImage") %>"
                                 onerror="this.onerror=null; this.src='images/default-cover.jpg'"
                                 class="book-image" />
                            <div class="book-overlay">
                                <i class="fas fa-eye text-white text-3xl transform group-hover:scale-110 transition-transform duration-300"></i>
                            </div>
                            <% if ("EBOOK".equals(book.get("format"))) { %>
                            <div class="absolute top-3 right-3 digital-badge">
                                <i class="fas fa-download"></i>
                                <span>Digital</span>
                            </div>
                            <% }%>
                        </div>
                        <div class="book-info">
                            <h3 class="book-title group-hover:text-blue-600 transition-colors line-clamp-2">
                                <%= book.get("title")%>
                            </h3>
                            <div class="book-meta">
                                <i class="fas fa-user-edit text-blue-500"></i>
                                <span><%= book.get("author")%></span>
                            </div>
                            <div class="book-meta">
                                <i class="fas fa-calendar text-blue-500"></i>
                                <span><%= book.get("publishedYear")%></span>
                            </div>
                            <div class="book-meta">
                                <i class="fas fa-tag text-blue-500"></i>
                                <span class="text-blue-600 font-medium"><%= book.get("format")%></span>
                            </div>
                        </div>
                    </a>
                </div>
                <% } %>
            </div>

            <!-- Pagination -->
            <% if (totalPages > 1) { %>
            <div class="pagination">
                <% if (currentPage > 1) {%>
                <a href="?name=<%= java.net.URLEncoder.encode(genreName, "UTF-8")%>&sort=<%= sort == null ? "newest" : sort%>&size=<%= booksPerPage%>&page=<%= currentPage - 1%>">
                    <i class="fas fa-chevron-left mr-1"></i>Trước
                </a>
                <% } %>

                <%
                    int startPage = Math.max(1, currentPage - 2);
                    int endPage = Math.min(totalPages, currentPage + 2);

                    if (startPage > 1) {
                %>
                <a href="?name=<%= java.net.URLEncoder.encode(genreName, "UTF-8")%>&sort=<%= sort == null ? "newest" : sort%>&size=<%= booksPerPage%>&page=1">1</a>
                <% if (startPage > 2) { %>
                <span>...</span>
                <% } %>
                <% } %>

                <% for (int i = startPage; i <= endPage; i++) { %>
                <% if (i == currentPage) {%>
                <span class="current"><%= i%></span>
                <% } else {%>
                <a href="?name=<%= java.net.URLEncoder.encode(genreName, "UTF-8")%>&sort=<%= sort == null ? "newest" : sort%>&size=<%= booksPerPage%>&page=<%= i%>"><%= i%></a>
                <% } %>
                <% } %>

                <% if (endPage < totalPages) { %>
                <% if (endPage < totalPages - 1) { %>
                <span>...</span>
                <% }%>
                <a href="?name=<%= java.net.URLEncoder.encode(genreName, "UTF-8")%>&sort=<%= sort == null ? "newest" : sort%>&size=<%= booksPerPage%>&page=<%= totalPages%>"><%= totalPages%></a>
                <% } %>

                <% if (currentPage < totalPages) {%>
                <a href="?name=<%= java.net.URLEncoder.encode(genreName, "UTF-8")%>&sort=<%= sort == null ? "newest" : sort%>&size=<%= booksPerPage%>&page=<%= currentPage + 1%>">
                    Sau<i class="fas fa-chevron-right ml-1"></i>
                </a>
                <% } %>
            </div>
            <% } %>

            <!-- Empty State -->
            <% if (books.isEmpty()) {%>
            <div class="text-center py-16">
                <div class="w-32 h-32 mx-auto mb-6 bg-gray-100 rounded-full flex items-center justify-center">
                    <i class="fas fa-book-open text-4xl text-gray-400"></i>
                </div>
                <h3 class="text-2xl font-bold text-gray-700 mb-2">Không tìm thấy sách</h3>
                <p class="text-gray-500 mb-6">Hiện tại chưa có sách nào trong thể loại <%= genreName.toLowerCase()%>.</p>
                <a href="index.jsp" class="back-button">
                    <i class="fas fa-arrow-left mr-2"></i>Quay lại trang chủ
                </a>
            </div>
            <% }%>

            <%
                    }
                } catch (SQLException e) {
            %>
            <div class="bg-gradient-to-r from-red-50 to-red-100 border-l-4 border-red-500 rounded-xl p-6 shadow-lg">
                <div class="flex items-center">
                    <i class="fas fa-exclamation-triangle text-red-500 text-3xl mr-4"></i>
                    <div>
                        <h3 class="text-lg font-semibold text-red-800">Lỗi kết nối</h3>
                        <p class="text-red-600"><%= e.getMessage()%></p>
                    </div>
                </div>
            </div>
            <%
                        }
                    }
            %>
        </main>

        <%@ include file="./layout/footer.jsp" %>

        <!-- Back to Top Button -->
        <button id="backToTop" class="fixed bottom-8 right-8 w-12 h-12 bg-gradient-to-r from-blue-500 to-purple-600 text-white rounded-full shadow-lg hover:shadow-xl transition-all duration-300 transform hover:scale-110 opacity-0 invisible">
            <i class="fas fa-arrow-up"></i>
        </button>

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

            // Book cards animation
            const bookCards = document.querySelectorAll('.book-card');
            const observerOptions = {threshold: 0.1, rootMargin: '0px 0px -50px 0px'};
            const observer = new IntersectionObserver((entries) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        entry.target.style.opacity = '1';
                        entry.target.style.transform = 'translateY(0)';
                    }
                });
            }, observerOptions);

            bookCards.forEach(card => {
                card.style.opacity = '0';
                card.style.transform = 'translateY(20px)';
                card.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
                observer.observe(card);
            });

            // Ripple effect
            document.querySelectorAll('a, button').forEach(button => {
                button.addEventListener('click', function (e) {
                    const ripple = document.createElement('span');
                    const rect = this.getBoundingClientRect();
                    const size = Math.max(rect.width, rect.height);
                    const x = e.clientX - rect.left - size / 2;
                    const y = e.clientY - rect.top - size / 2;
                    ripple.style.width = ripple.style.height = size + 'px';
                    ripple.style.left = x + 'px';
                    ripple.style.top = y + 'px';
                    ripple.classList.add('ripple');
                    this.appendChild(ripple);
                    setTimeout(() => {ripple.remove();}, 600);
                });
            });

            // Floating elements
            const floatingElements = document.querySelectorAll('.floating-book');
            floatingElements.forEach((element, index) => {
                const randomDelay = Math.random() * 2;
                const randomDuration = 6 + Math.random() * 4;
                element.style.animationDelay = randomDelay + 's';
                element.style.animationDuration = randomDuration + 's';
            });
        </script>
        </div>
        <<script src="script.js"></script>
    </body>
    
</html>