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
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css">

        <!-- Google Fonts -->
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">

        <!-- Favicon -->
        <link rel="icon" href="./images/reading-book.png" type="image/x-icon" />

        <!-- Custom CSS -->
        <link rel="stylesheet" href="style.css"/>
        <link rel="stylesheet" href="loading.css"/>       
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

        <!-- Include Header -->
        <%@ include file="../user/layout/header.jsp" %>

        <!-- Main Content -->
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
            <%            String category = request.getParameter("category");
                if (category == null) {
                    category = "ALL";
                }

                String categoryDisplayName = "";
                String categoryIcon = "";
                String categoryColor = "";

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
                        categoryColor = "gray";
                }

                Connection conn = null;
                List<Map<String, Object>> books = new ArrayList<>();
                String searchQuery = request.getParameter("search");

                // Pagination
                int currentPage = 1;
                int booksPerPage = 12;
                int totalBooks = 0;

                try {
                    String pageParam = request.getParameter("page");
                    if (pageParam != null) {
                        currentPage = Integer.parseInt(pageParam);
                    }
                } catch (NumberFormatException e) {
                    currentPage = 1;
                }

                int offset = (currentPage - 1) * booksPerPage;

                try {
                    conn = DBConnection.getConnection();

                    // Count total books for pagination - Only ACTIVE books
                    String countSql = "SELECT COUNT(*) as total FROM book b LEFT JOIN author a ON b.authorId = a.id WHERE b.status = 'ACTIVE'";
                    if (!category.equals("ALL")) {
                        countSql += " AND b.format = ?";
                    }

                    PreparedStatement countStmt = conn.prepareStatement(countSql);
                    if (!category.equals("ALL")) {
                        countStmt.setString(1, category);
                    }
                    ResultSet countRs = countStmt.executeQuery();
                    if (countRs.next()) {
                        totalBooks = countRs.getInt("total");
                    }

                    // Get books with pagination - Only ACTIVE books
                    String sql = "SELECT b.isbn, b.title, a.name AS author, b.publicationYear, b.format, b.coverImage "
                            + "FROM book b "
                            + "LEFT JOIN author a ON b.authorId = a.id "
                            + "WHERE b.status = 'ACTIVE'";

                    if (!category.equals("ALL")) {
                        sql += " AND b.format = ?";
                    }

                    sql += " ORDER BY b.title LIMIT ? OFFSET ?";

                    PreparedStatement stmt = conn.prepareStatement(sql);
                    int paramIndex = 1;

                    if (!category.equals("ALL")) {
                        stmt.setString(paramIndex++, category);
                    }
                    stmt.setInt(paramIndex++, booksPerPage);
                    stmt.setInt(paramIndex, offset);

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
                    if (conn != null) {
                        try {
                            conn.close();
                        } catch (SQLException e) {
                            e.printStackTrace();
                        }
                    }
                }

                int totalPages = (int) Math.ceil((double) totalBooks / booksPerPage);
            %>
            <div id="app-content">
            <!-- Breadcrumb -->
            <div class="breadcrumb">
                <nav class="flex items-center space-x-2 text-sm font-medium">
                    <a href="${pageContext.request.contextPath}/index.jsp" class="text-blue-600 hover:text-blue-800 transition-colors">
                        <i class="fas fa-home mr-1"></i>Trang chủ
                    </a>
                    <i class="fas fa-chevron-right text-gray-400"></i>
                    <span class="text-gray-700">
                        <i class="<%= categoryIcon%> mr-1"></i><%= categoryDisplayName%>
                    </span>
                </nav>
            </div>

            <!-- Category Header -->
            <div class="category-header">
                <div class="flex items-center justify-between flex-wrap gap-4">
                    <div class="flex items-center space-x-4">
                        <div class="w-16 h-16 bg-gradient-to-br from-<%= categoryColor%>-500 to-<%= categoryColor%>-600 rounded-full flex items-center justify-center">
                            <i class="<%= categoryIcon%> text-2xl text-white"></i>
                        </div>
                        <div>
                            <h1 class="text-4xl font-bold text-gray-800 mb-2"><%= categoryDisplayName%></h1>
                            <p class="text-gray-600 text-lg">Khám phá bộ sưu tập <%= categoryDisplayName.toLowerCase()%> phong phú</p>
                        </div>
                    </div>

                    <div class="flex items-center space-x-4">
                        <div class="stats-card">
                            <div class="text-2xl font-bold text-<%= categoryColor%>-600"><%= totalBooks%></div>
                            <div class="text-sm text-gray-600">Tổng số sách</div>
                        </div>
                        <a href="../index.jsp" class="back-button">
                            <i class="fas fa-arrow-left"></i>
                            <span>Quay lại</span>
                        </a>
                    </div>
                </div>
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
                            <h3 class="book-title group-hover:text-<%= categoryColor%>-600 transition-colors line-clamp-2">
                                <%= book.get("title")%>
                            </h3>
                            <div class="book-meta">
                                <i class="fas fa-user-edit text-<%= categoryColor%>-500"></i>
                                <span><%= book.get("author")%></span>
                            </div>
                            <div class="book-meta">
                                <i class="fas fa-calendar text-<%= categoryColor%>-500"></i>
                                <span><%= book.get("publishedYear")%></span>
                            </div>
                            <div class="book-meta">
                                <i class="fas fa-tag text-<%= categoryColor%>-500"></i>
                                <span class="text-<%= categoryColor%>-600 font-medium"><%= book.get("format")%></span>
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
                <a href="?category=<%= category%>&page=<%= currentPage - 1%>">
                    <i class="fas fa-chevron-left mr-1"></i>Trước
                </a>
                <% } %>

                <%
                    int startPage = Math.max(1, currentPage - 2);
                    int endPage = Math.min(totalPages, currentPage + 2);

                    if (startPage > 1) {
                %>
                <a href="?category=<%= category%>&page=1">1</a>
                <% if (startPage > 2) { %>
                <span>...</span>
                <% } %>
                <% } %>

                <% for (int i = startPage; i <= endPage; i++) { %>
                <% if (i == currentPage) {%>
                <span class="current"><%= i%></span>
                <% } else {%>
                <a href="?category=<%= category%>&page=<%= i%>"><%= i%></a>
                <% } %>
                <% } %>

                <% if (endPage < totalPages) { %>
                <% if (endPage < totalPages - 1) { %>
                <span>...</span>
                <% }%>
                <a href="?category=<%= category%>&page=<%= totalPages%>"><%= totalPages%></a>
                <% } %>

                <% if (currentPage < totalPages) {%>
                <a href="?category=<%= category%>&page=<%= currentPage + 1%>">
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
                <p class="text-gray-500 mb-6">Hiện tại chưa có sách nào trong danh mục <%= categoryDisplayName.toLowerCase()%>.</p>
                <a href="library.jsp" class="back-button">
                    <i class="fas fa-arrow-left mr-2"></i>Quay lại trang chủ
                </a>
            </div>
            <% }%>
        </main>

        <!-- Enhanced Footer -->
        <jsp:include page="layout/footer.jsp" />

        <!-- Back to Top Button -->
        <button id="backToTop" class="fixed bottom-8 right-8 w-12 h-12 bg-gradient-to-r from-blue-500 to-purple-600 text-white rounded-full shadow-lg hover:shadow-xl transition-all duration-300 transform hover:scale-110 opacity-0 invisible">
            <i class="fas fa-arrow-up"></i>
        </button>

        <!-- JavaScript -->
        <script>
            // Back to top functionality
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
                window.scrollTo({
                    top: 0,
                    behavior: 'smooth'
                });
            });

            // Smooth scrolling for anchor links
            document.querySelectorAll('a[href^="#"]').forEach(anchor => {
                anchor.addEventListener('click', function (e) {
                    e.preventDefault();
                    const target = document.querySelector(this.getAttribute('href'));
                    if (target) {
                        target.scrollIntoView({
                            behavior: 'smooth'
                        });
                    }
                });
            });

            // Add loading animation to book cards
            const bookCards = document.querySelectorAll('.book-card');
            const observerOptions = {
                threshold: 0.1,
                rootMargin: '0px 0px -50px 0px'
            };

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

            // Add ripple effect to buttons
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

                    setTimeout(() => {
                        ripple.remove();
                    }, 600);
                });
            });

            // Enhanced floating elements animation
            const floatingElements = document.querySelectorAll('.floating-book');
            floatingElements.forEach((element, index) => {
                const randomDelay = Math.random() * 2;
                const randomDuration = 6 + Math.random() * 4;
                element.style.animationDelay = randomDelay + 's';
                element.style.animationDuration = randomDuration + 's';
            });
        </script>

        <!-- Additional CSS for animations -->
        <style>
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

            .book-card {
                will-change: transform, opacity;
            }

            .book-image {
                will-change: transform;
            }

            /* Enhanced hover effects */
            .book-card:hover {
                transform: translateY(-12px) scale(1.03);
                box-shadow: 0 25px 50px rgba(0,0,0,0.15);
            }

            .book-card:hover .book-image {
                transform: scale(1.1);
            }

            /* Improved responsive design */
            @media (max-width: 640px) {
                .book-grid {
                    grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
                    gap: 1rem;
                }

                .book-image-container {
                    height: 240px;
                }

                .category-header {
                    padding: 1rem;
                }

                .stats-card {
                    padding: 1rem;
                }
            }
        </style>
        </div>
        <script src="script.js"></script>
    </body>
</html>