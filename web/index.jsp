<%@ page contentType="text/html; charset=UTF-8" language="java"
         buffer="64kb" autoFlush="true" errorPage="/error.jsp" %>
<%@ page import="java.sql.*, java.util.*, Servlet.DBConnection, java.text.Normalizer" %>
<!DOCTYPE html>
<html lang="vi">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Thư viện Sách</title>

        <!-- Tailwind CSS -->
        <script src="https://cdn.tailwindcss.com"></script>

        <!-- Font Awesome -->
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css">

        <!-- Google Fonts -->
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">

        <!-- Favicon -->
        <link rel="icon" href="./images/reading-book.png" type="image/x-icon" />

        <!-- Custom CSS -->
        <link rel="stylesheet" href="user/banner.css"/>
        <link rel="stylesheet" href="user/style1.css"/>

        <script>
            // Wheel -> scroll ngang cho mọi .shelf
            document.addEventListener('DOMContentLoaded', () => {
                document.querySelectorAll('.shelf').forEach(shelf => {
                    shelf.addEventListener('wheel', (e) => {
                        // Giữ cảm giác tự nhiên: cuộn ngang là mặc định, giữ Shift để cuộn dọc
                        if (!e.shiftKey) {
                            e.preventDefault();
                            shelf.scrollLeft += (e.deltaY || e.deltaX);
                        }
                    }, {passive: false});

                    // Kéo-để-cuộn (drag scroll) cho chuột / touch
                    let isDown = false, startX = 0, scrollLeft = 0;
                    shelf.addEventListener('mousedown', (e) => {
                        isDown = true;
                        startX = e.pageX - shelf.offsetLeft;
                        scrollLeft = shelf.scrollLeft;
                        shelf.classList.add('cursor-grabbing');
                    });
                    shelf.addEventListener('mouseleave', () => {
                        isDown = false;
                        shelf.classList.remove('cursor-grabbing');
                    });
                    shelf.addEventListener('mouseup', () => {
                        isDown = false;
                        shelf.classList.remove('cursor-grabbing');
                    });
                    shelf.addEventListener('mousemove', (e) => {
                        if (!isDown)
                            return;
                        e.preventDefault();
                        const x = e.pageX - shelf.offsetLeft;
                        shelf.scrollLeft = scrollLeft - (x - startX);
                    });
                    // Nút next/prev nếu dùng .shelf-nav
                    const parent = shelf.closest('.shelf-nav');
                    if (parent) {
                        const prev = parent.querySelector('[data-shelf-prev]');
                        const next = parent.querySelector('[data-shelf-next]');
                        if (prev)
                            prev.addEventListener('click', () => shelf.scrollBy({left: -600, behavior: 'smooth'}));
                        if (next)
                            next.addEventListener('click', () => shelf.scrollBy({left: 600, behavior: 'smooth'}));
                    }
                });
            });
        </script>

    </head>

    <body class="page-background min-h-screen text-slate-50">
        <!-- Page Loader -->
        <div id="page-loader" role="status" aria-live="polite" class="flex flex-col items-center justify-center text-center px-4">
            <div class="flex flex-col items-center justify-center bg-slate-900/70 border border-slate-500/60 rounded-3xl px-8 py-10 shadow-2xl max-w-xl w-full">
                <div class="spinner mb-6"></div>
                <div class="text-center mb-6">
                    <div class="loader-title text-xl mb-1">Đang tải dữ liệu…</div>
                    <div class="loader-sub text-sm">Vui lòng chờ trong giây lát</div>
                </div>

                <!-- Skeleton: 1 hàng sách giả để người dùng có gì đó nhìn -->
                <div class="shelf-skeleton px-1">
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
        </div>

        <!-- Bọc toàn bộ nội dung trang trong app-content để áp hiệu ứng reveal -->
        <div id="app-content" class="opacity-0 transition-opacity duration-300 ease-out">

            <!-- Floating Background Elements -->
            <div class="floating-elements">
                <i class="fas fa-book floating-book text-7xl md:text-8xl text-blue-500/80" style="top: 5%; left: 80%; animation-delay: 0s;"></i>
                <i class="fas fa-bookmark floating-book text-5xl md:text-6xl text-purple-500/80" style="top: 15%; left: 5%; animation-delay: 2s;"></i>
                <i class="fas fa-feather floating-book text-6xl md:text-7xl text-green-500/80" style="top: 50%; left: 85%; animation-delay: 4s;"></i>
                <i class="fas fa-scroll floating-book text-4xl md:text-5xl text-orange-500/80" style="top: 75%; left: 10%; animation-delay: 6s;"></i>
                <i class="fas fa-glasses floating-book text-5xl md:text-6xl text-pink-500/80" style="top: 35%; left: 90%; animation-delay: 8s;"></i>
            </div>

            <!-- Include Header với Search Component -->
            <jsp:include page="user/layout/header.jsp" />
            
            <!-- Main Content -->
            <main class="container-enhanced py-10 lg:py-14 space-y-10 lg:space-y-12">
                <%
                    // ===== 2) Lấy tất cả sách / tìm kiếm =====
                    List<Map<String, Object>> allBooks = new ArrayList<>();
                    List<Map<String, Object>> searchResults = new ArrayList<>();
                    String searchQuery = request.getParameter("search");
                    boolean isSearching = (searchQuery != null && !searchQuery.trim().isEmpty());
                                      
                    List<Map<String, Object>> recentBooks = new ArrayList<>();
                    List<Map<String, Object>> hotBorrowBooks = new ArrayList<>();
                    Map<String, List<Map<String, Object>>> genreSections = new LinkedHashMap<>();

                    try (Connection connList = DBConnection.getConnection()) {
                        String baseSql
                                = "SELECT b.isbn, b.title, a.name AS author, b.publicationYear, b.format, b.coverImage "
                                + "FROM book b LEFT JOIN author a ON b.authorId = a.id";

                        // tất cả sách
                        try (PreparedStatement psAll = connList.prepareStatement(baseSql); ResultSet rsAll = psAll.executeQuery()) {
                            while (rsAll.next()) {
                                Map<String, Object> book = new HashMap<>();
                                book.put("isbn", rsAll.getString("isbn"));
                                book.put("title", rsAll.getString("title"));
                                book.put("author", rsAll.getString("author"));
                                book.put("publishedYear", rsAll.getInt("publicationYear"));
                                book.put("format", rsAll.getString("format"));
                                book.put("coverImage", rsAll.getString("coverImage"));
                                allBooks.add(book);
                            }
                        }

                        // tìm kiếm (nếu có) – fuzzy + không dấu dựa trên allBooks
                        if (isSearching) {
                            String qraw = searchQuery.trim();

                            for (Map<String, Object> book : allBooks) {
                                String title  = book.get("title")  == null ? "" : String.valueOf(book.get("title"));
                                String author = book.get("author") == null ? "" : String.valueOf(book.get("author"));
                                String text   = title + " " + author;

                                if (fuzzyMatch(text, qraw)) {
                                    searchResults.add(book);
                                }
                            }
                        }
                      
                        // ===== 3) Sách mới thêm (dựa vào bookitem.date_of_purchase) ====
                        {
                            // Lấy ISBN có lần nhập gần nhất, rồi join ra thông tin sách
                            String sqlRecent
                                    = "SELECT b.isbn, b.title, a.name AS author, b.publicationYear, b.format, b.coverImage, t.last_purchase "
                                    + "FROM ( "
                                    + "   SELECT bi.book_isbn, MAX(bi.date_of_purchase) AS last_purchase "
                                    + "   FROM bookitem bi "
                                    + "   WHERE bi.date_of_purchase IS NOT NULL "
                                    + // bỏ nếu muốn cho phép NULL
                                    "   GROUP BY bi.book_isbn "
                                    + ") t "
                                    + "JOIN book b ON b.isbn = t.book_isbn "
                                    + "LEFT JOIN author a ON a.id = b.authorId "
                                    + "ORDER BY t.last_purchase DESC "
                                    + "LIMIT 12";

                            try (PreparedStatement ps = connList.prepareStatement(sqlRecent); ResultSet rs = ps.executeQuery()) {
                                while (rs.next()) {
                                    Map<String, Object> m = new HashMap<>();
                                    m.put("isbn", rs.getString("isbn"));
                                    m.put("title", rs.getString("title"));
                                    m.put("author", rs.getString("author"));
                                    m.put("publishedYear", rs.getInt("publicationYear"));
                                    m.put("format", rs.getString("format"));
                                    m.put("coverImage", rs.getString("coverImage"));
                                    // Nếu muốn hiển thị ngày nhập dưới thumbnail:
                                    m.put("lastPurchase", rs.getDate("last_purchase"));
                                    recentBooks.add(m);
                                }
                            }
                        }
                        // ===== 4) Sách được mượn nhiều =====
                        // Tính theo số lượt mượn (Borrowed/Returned/Overdue)
                        {
                            // Lấy top ISBN theo lượt mượn
                            List<String> topIsbns = new ArrayList<>();
                            String sqlTop
                                    = "SELECT bi.book_isbn AS isbn, COUNT(*) AS cnt "
                                    + "FROM borrow br JOIN bookitem bi ON bi.book_item_id = br.book_item_id "
                                    + "WHERE br.status IN ('Borrowed','Returned','Overdue') "
                                    + "GROUP BY bi.book_isbn ORDER BY cnt DESC LIMIT 12";
                            try (PreparedStatement ps = connList.prepareStatement(sqlTop); ResultSet rs = ps.executeQuery()) {
                                while (rs.next()) {
                                    topIsbns.add(rs.getString("isbn"));
                                }
                            }
                            if (!topIsbns.isEmpty()) {
                                String placeholders = String.join(",", Collections.nCopies(topIsbns.size(), "?"));
                                String orderBy = String.join(",", Collections.nCopies(topIsbns.size(), "?")); // dùng FIELD để giữ thứ tự top
                                String sqlBooks
                                        = "SELECT b.isbn, b.title, a.name AS author, b.publicationYear, b.format, b.coverImage "
                                        + "FROM book b LEFT JOIN author a ON b.authorId = a.id "
                                        + "WHERE b.isbn IN (" + placeholders + ") "
                                        + "ORDER BY FIELD(b.isbn, " + orderBy + ")";
                                try (PreparedStatement ps = connList.prepareStatement(sqlBooks)) {
                                    int i = 1;
                                    for (String s : topIsbns) {
                                        ps.setString(i++, s);           // IN (...)
                                    }
                                    for (String s : topIsbns) {
                                        ps.setString(i++, s);           // FIELD(...)
                                    }
                                    try (ResultSet rs = ps.executeQuery()) {
                                        while (rs.next()) {
                                            Map<String, Object> m = new HashMap<>();
                                            m.put("isbn", rs.getString("isbn"));
                                            m.put("title", rs.getString("title"));
                                            m.put("author", rs.getString("author"));
                                            m.put("publishedYear", rs.getInt("publicationYear"));
                                            m.put("format", rs.getString("format"));
                                            m.put("coverImage", rs.getString("coverImage"));
                                            hotBorrowBooks.add(m);
                                        }
                                    }
                                }
                            }
                        }

                        // ===== 5) Các mục theo THỂ LOẠI (lấy top 3 thể loại có nhiều sách nhất) =====
                        {
                            List<Integer> topGenreIds = new ArrayList<>();
                            Map<Integer, String> topGenreNames = new LinkedHashMap<>();

                            String sqlTopGenres
                                    = "SELECT g.id, g.name, COUNT(*) AS cnt "
                                    + "FROM book_genre bg JOIN genre g ON g.id = bg.genre_id "
                                    + "GROUP BY g.id, g.name "
                                    + "ORDER BY cnt DESC LIMIT 3";
                            try (PreparedStatement ps = connList.prepareStatement(sqlTopGenres); ResultSet rs = ps.executeQuery()) {
                                while (rs.next()) {
                                    int gid = rs.getInt("id");
                                    String gname = rs.getString("name");
                                    topGenreIds.add(gid);
                                    topGenreNames.put(gid, gname);
                                }
                            }

                            // Với mỗi thể loại → lấy tối đa 10 sách
                            String sqlBooksByGenre
                                    = "SELECT b.isbn, b.title, a.name AS author, b.publicationYear, b.format, b.coverImage "
                                    + "FROM book b "
                                    + "JOIN book_genre bg ON bg.book_id = b.id "
                                    + "LEFT JOIN author a ON a.id = b.authorId "
                                    + "WHERE bg.genre_id = ? "
                                    + "ORDER BY b.id DESC LIMIT 10"; // mới nhất trong thể loại

                            try (PreparedStatement ps = connList.prepareStatement(sqlBooksByGenre)) {
                                for (Integer gid : topGenreIds) {
                                    ps.setInt(1, gid);
                                    List<Map<String, Object>> list = new ArrayList<>();
                                    try (ResultSet rs = ps.executeQuery()) {
                                        while (rs.next()) {
                                            Map<String, Object> m = new HashMap<>();
                                            m.put("isbn", rs.getString("isbn"));
                                            m.put("title", rs.getString("title"));
                                            m.put("author", rs.getString("author"));
                                            m.put("publishedYear", rs.getInt("publicationYear"));
                                            m.put("format", rs.getString("format"));
                                            m.put("coverImage", rs.getString("coverImage"));
                                            list.add(m);
                                        }
                                    }
                                    genreSections.put(topGenreNames.get(gid), list);
                                }
                            }
                        }
                    } catch (SQLException e) {
                        e.printStackTrace();
                        out.println("<div class='glass-effect border border-red-300 text-red-200 px-6 py-4 rounded-2xl mb-6'>" 
                                + "<p class='flex items-center'><i class='fas fa-exclamation-triangle mr-3 text-xl text-red-300'></i>" 
                                + "Lỗi khi lấy dữ liệu sách: " + e.getMessage() + "</p></div>");
                    }
                %>
                <%
                    List<Map<String,Object>> filteredBooks =
                        (List<Map<String,Object>>) request.getAttribute("filteredBooks");
                    Integer yearFrom = (Integer) request.getAttribute("yearFrom");
                    Integer yearTo   = (Integer) request.getAttribute("yearTo");
                    Integer pagesMin = (Integer) request.getAttribute("pagesMin");
                    String genreId   = (String) request.getAttribute("genreId");
                    String genreName = request.getParameter("genreName");
                    
                    // ===== Phân trang KẾT QUẢ LỌC =====
                    int filterPageSize = 12; // đổi số này nếu muốn nhiều/ít hơn
                    int filterCurrentPage = 1;
                    int filterTotal = 0;
                    int filterTotalPages = 1;

                    if (filteredBooks != null) {
                        filterTotal = filteredBooks.size();
                        String filterPageParam = request.getParameter("pageFilter");
                        if (filterPageParam != null) {
                            try {
                                filterCurrentPage = Integer.parseInt(filterPageParam);
                            } catch (NumberFormatException ignore) {}
                        }
                        if (filterCurrentPage < 1) filterCurrentPage = 1;
                        filterTotalPages = (int) Math.ceil(filterTotal / (double) filterPageSize);
                        if (filterTotalPages == 0) filterTotalPages = 1;
                        if (filterCurrentPage > filterTotalPages) filterCurrentPage = filterTotalPages;
                    }

                    int filterStartIndex = (filterCurrentPage - 1) * filterPageSize;
                    int filterEndIndex = Math.min(filterStartIndex + filterPageSize, filterTotal);

                    // build base URL giữ nguyên điều kiện lọc
                    StringBuilder filterBaseUrl = new StringBuilder("index.jsp?");
                    if (genreId != null && !genreId.isBlank()) {
                        filterBaseUrl.append("genreId=").append(genreId).append("&");
                    }
                    if (genreName != null && !genreName.isBlank()) {
                        filterBaseUrl.append("genreName=").append(java.net.URLEncoder.encode(genreName, "UTF-8")).append("&");
                    }
                    if (yearFrom != null) {
                        filterBaseUrl.append("yearFrom=").append(yearFrom).append("&");
                    }
                    if (yearTo != null) {
                        filterBaseUrl.append("yearTo=").append(yearTo).append("&");
                    }
                    if (pagesMin != null) {
                        filterBaseUrl.append("pagesMin=").append(pagesMin).append("&");
                    }

                    // ===== Phân trang KẾT QUẢ TÌM KIẾM =====
                    int searchPageSize = 12;
                    int searchCurrentPage = 1;
                    int searchTotal = searchResults != null ? searchResults.size() : 0;
                    int searchTotalPages = 1;
                    String baseSearchUrl = null;

                    if (isSearching && searchResults != null) {
                        String searchPageParam = request.getParameter("pageSearch");
                        if (searchPageParam != null) {
                            try {
                                searchCurrentPage = Integer.parseInt(searchPageParam);
                            } catch (NumberFormatException ignore) {}
                        }
                        if (searchCurrentPage < 1) searchCurrentPage = 1;
                        searchTotalPages = (int) Math.ceil(searchTotal / (double) searchPageSize);
                        if (searchTotalPages == 0) searchTotalPages = 1;
                        if (searchCurrentPage > searchTotalPages) searchCurrentPage = searchTotalPages;

                        baseSearchUrl = "index.jsp?search=" + java.net.URLEncoder.encode(searchQuery, "UTF-8") + "&";
                    }

                    int searchStartIndex = (searchCurrentPage - 1) * searchPageSize;
                    int searchEndIndex = Math.min(searchStartIndex + searchPageSize, searchTotal);
                %>
                <%
                    // Chỉ hiển thị khi có dữ liệu lọc
                    if ((genreId != null && !genreId.isBlank()) || yearFrom != null || yearTo != null || pagesMin != null) {
                %>
                <section id="filter-results" class="category-section mb-10">
                    <div class="category-header">
                        <div class="flex items-center justify-between gap-4 flex-wrap">
                            <div class="flex items-center space-x-4">
                                <div class="w-2 h-12 bg-gradient-to-b from-amber-500 to-orange-600 rounded-full"></div>
                                <h2 class="text-3xl md:text-4xl font-bold category-title">
                                    Kết quả lọc
                                    <% if (genreName != null) { %> – Thể loại: <%= genreName %> <% } %>
                                    <% if (yearFrom != null || yearTo != null) { %>
                                      – Năm: (<%= yearFrom != null ? yearFrom : "…" %> – <%= yearTo != null ? yearTo : "…" %>)
                                    <% } %>
                                    <% if (pagesMin != null) { %>
                                      – Số trang: ≥ <%= pagesMin %>
                                    <% } %>
                                </h2>
                            </div>
                            <div class="flex items-center gap-3">
                                <span class="text-sm text-slate-300 hidden md:inline">
                                    Trang <span class="font-semibold"><%= filterCurrentPage %></span>/<span><%= filterTotalPages %></span>
                                    • Tổng <span class="font-semibold"><%= filterTotal %></span> sách
                                </span>
                                <a href="index.jsp" class="expand-button text-blue-100 hover:text-white font-semibold transition-all duration-300 flex items-center space-x-3 no-underline">
                                    <span>Bỏ lọc</span>
                                    <i class="fas fa-xmark text-sm"></i>
                                </a>
                            </div>
                        </div>
                    </div>

                    <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-5 md:gap-6">
                        <% 
                           if (filteredBooks != null) {
                             for (int i = filterStartIndex; i < filterEndIndex; i++) {
                               Map<String,Object> b = filteredBooks.get(i);
                        %>
                          <div class="book-card rounded-3xl shadow-lg hover:shadow-2xl group shine-effect">
                            <a href="./user/bookDetails.jsp?isbn=<%= b.get("isbn")%>" class="block h-full">
                              <div class="book-image-container">
                                <img src="<%= request.getContextPath() + "/" + b.get("coverImage") %>"
                                            alt="<%= b.get("title")%>"
                                            onerror="this.onerror=null; this.src='<%= request.getContextPath() %>/images/default-cover.jpg'"
                                            class="w-full h-full rounded-xl object-cover" />
                                <div class="book-overlay">
                                  <i class="fas fa-eye text-white text-2xl md:text-3xl transform group-hover:scale-110 transition-transform duration-300 ease-out"></i>
                                </div>
                              </div>
                              <div class="book-info">
                                <h3 class="book-title group-hover:text-blue-300 transition-colors duration-200 ease-out line-clamp-2">
                                  <%= b.get("title")%>
                                </h3>
                                <div class="book-meta">
                                  <i class="fas fa-user-edit text-blue-400"></i>
                                  <span><%= b.get("author")%></span>
                                </div>
                                <div class="book-meta">
                                  <i class="fas fa-calendar text-blue-400"></i>
                                  <span><%= b.get("publicationYear")%></span>
                                </div>
                                <div class="book-meta">
                                  <i class="fas fa-file-alt text-blue-400"></i>
                                  <span><%= b.get("numberOfPages") %> trang</span>
                                </div>
                              </div>                             
                            </a>
                          </div>
                        <% 
                             } // end for
                           } // end if
                        %>
                    </div>

                    <% if (filterTotalPages > 1) { %>
                    <div class="mt-6 flex justify-center">
                        <nav class="inline-flex items-center space-x-1 bg-slate-900/70 border border-slate-600/80 rounded-full px-2 py-1 shadow-lg">
                            <!-- Prev -->
                            <% if (filterCurrentPage > 1) { %>
                            <a href="<%= filterBaseUrl.toString() %>pageFilter=<%= filterCurrentPage - 1 %>" 
                               class="px-3 py-1.5 text-xs md:text-sm rounded-full text-slate-100 hover:bg-slate-700/80 transition-colors duration-200 flex items-center gap-1">
                                <i class="fas fa-chevron-left text-[10px]"></i>
                                <span class="hidden sm:inline">Trước</span>
                            </a>
                            <% } else { %>
                            <span class="px-3 py-1.5 text-xs md:text-sm rounded-full text-slate-500 cursor-default flex items-center gap-1">
                                <i class="fas fa-chevron-left text-[10px]"></i>
                                <span class="hidden sm:inline">Trước</span>
                            </span>
                            <% } %>

                            <!-- page numbers -->
                            <%
                               int filterStartPage = Math.max(1, filterCurrentPage - 2);
                               int filterEndPage = Math.min(filterTotalPages, filterCurrentPage + 2);
                               for (int p = filterStartPage; p <= filterEndPage; p++) {
                            %>
                                <a href="<%= filterBaseUrl.toString() %>pageFilter=<%= p %>"
                                   class="px-3 py-1.5 text-xs md:text-sm rounded-full <%= (p == filterCurrentPage ? "bg-slate-100 text-slate-900 font-semibold" : "text-slate-200 hover:bg-slate-700/80") %> transition-colors duration-200">
                                    <%= p %>
                                </a>
                            <% } %>

                            <!-- Next -->
                            <% if (filterCurrentPage < filterTotalPages) { %>
                            <a href="<%= filterBaseUrl.toString() %>pageFilter=<%= filterCurrentPage + 1 %>" 
                               class="px-3 py-1.5 text-xs md:text-sm rounded-full text-slate-100 hover:bg-slate-700/80 transition-colors duration-200 flex items-center gap-1">
                                <span class="hidden sm:inline">Sau</span>
                                <i class="fas fa-chevron-right text-[10px]"></i>
                            </a>
                            <% } else { %>
                            <span class="px-3 py-1.5 text-xs md:text-sm rounded-full text-slate-500 cursor-default flex items-center gap-1">
                                <span class="hidden sm:inline">Sau</span>
                                <i class="fas fa-chevron-right text-[10px]"></i>
                            </span>
                            <% } %>
                        </nav>
                    </div>
                    <% } %>
                </section>
                <%
                    } else {
                %>

                    <% if (!isSearching) { %>
                <div class="hero-banner">
                    <!-- Slide 1: Sách Mới -->
                    <div class="banner-slide active gradient-overlay-1">
                        <div class="particles" id="particles-1"></div>
                        <div class="deco-shape deco-1"></div>
                        <div class="deco-shape deco-2"></div>

                        <div class="banner-content">
                            <div class="banner-text">
                                <div class="banner-badge">
                                    <i class="fas fa-sparkles"></i>
                                    <span>Vừa Mới Ra Mắt</span>
                                </div>
                                <h1 class="banner-title">Khám Phá<br/>Sách Mới Nhất</h1>
                                <p class="banner-description">
                                    Những đầu sách mới nhất vừa được bổ sung vào thư viện. 
                                    Đừng bỏ lỡ cơ hội trải nghiệm những tác phẩm đỉnh cao!
                                </p>
                                <div class="banner-stats">
                                    <div class="stat-item">
                                        <div class="stat-number">156</div>
                                        <div class="stat-label">Sách Mới</div>
                                    </div>
                                    <div class="stat-item">
                                        <div class="stat-number">24</div>
                                        <div class="stat-label">Tác Giả</div>
                                    </div>
                                    <div class="stat-item">
                                        <div class="stat-number">12</div>
                                        <div class="stat-label">Thể Loại</div>
                                    </div>
                                </div>
                                <div class="banner-buttons">
                                    <a href="#" class="btn-primary">
                                        <i class="fas fa-book-open"></i>
                                        Xem Ngay
                                    </a>
                                    <a href="#" class="btn-secondary">
                                        <i class="fas fa-heart"></i>
                                        Yêu Thích
                                    </a>
                                </div>
                            </div>
                            <div class="banner-book">
                                <div class="book-showcase">
                                    <div class="book-glow"></div>
                                    <img src="https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=400&h=600&fit=crop" 
                                         alt="New Book" class="book-cover">
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Slide 2: Top Mượn -->
                    <div class="banner-slide gradient-overlay-2">
                        <div class="particles" id="particles-2"></div>
                        <div class="deco-shape deco-1"></div>
                        <div class="deco-shape deco-2"></div>

                        <div class="banner-content">
                            <div class="banner-text">
                                <div class="banner-badge">
                                    <i class="fas fa-fire"></i>
                                    <span>Hot Nhất Tháng</span>
                                </div>
                                <h1 class="banner-title">Top Sách<br/>Được Yêu Thích</h1>
                                <p class="banner-description">
                                    Những cuốn sách được mượn nhiều nhất. 
                                    Cùng khám phá lý do tại sao chúng lại thu hút độc giả đến vậy!
                                </p>
                                <div class="banner-stats">
                                    <div class="stat-item">
                                        <div class="stat-number">2.8K</div>
                                        <div class="stat-label">Lượt Mượn</div>
                                    </div>
                                    <div class="stat-item">
                                        <div class="stat-number">4.9</div>
                                        <div class="stat-label">Đánh Giá</div>
                                    </div>
                                    <div class="stat-item">
                                        <div class="stat-number">892</div>
                                        <div class="stat-label">Reviews</div>
                                    </div>
                                </div>
                                <div class="banner-buttons">
                                    <a href="#" class="btn-primary">
                                        <i class="fas fa-trophy"></i>
                                        Xem Top
                                    </a>
                                    <a href="#" class="btn-secondary">
                                        <i class="fas fa-bookmark"></i>
                                        Lưu Lại
                                    </a>
                                </div>
                            </div>
                            <div class="banner-book">
                                <div class="book-showcase">
                                    <div class="book-glow"></div>
                                    <img src="https://images.unsplash.com/photo-1589829085413-56de8ae18c73?w=400&h=600&fit=crop" 
                                         alt="Popular Book" class="book-cover">
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Slide 3: Bestseller -->
                    <div class="banner-slide gradient-overlay-3">
                        <div class="particles" id="particles-3"></div>
                        <div class="deco-shape deco-1"></div>
                        <div class="deco-shape deco-2"></div>

                        <div class="banner-content">
                            <div class="banner-text">
                                <div class="banner-badge">
                                    <i class="fas fa-crown"></i>
                                    <span>Bestseller</span>
                                </div>
                                <h1 class="banner-title">Bán Chạy<br/>Nhất Năm</h1>
                                <p class="banner-description">
                                    Những tác phẩm bán chạy nhất được yêu thích bởi hàng triệu độc giả. 
                                    Đọc ngay để không bỏ lỡ xu hướng!
                                </p>
                                <div class="banner-stats">
                                    <div class="stat-item">
                                        <div class="stat-number">5.2K</div>
                                        <div class="stat-label">Đã Bán</div>
                                    </div>
                                    <div class="stat-item">
                                        <div class="stat-number">98%</div>
                                        <div class="stat-label">Hài Lòng</div>
                                    </div>
                                    <div class="stat-item">
                                        <div class="stat-number">1.5K</div>
                                        <div class="stat-label">Bình Luận</div>
                                    </div>
                                </div>
                                <div class="banner-buttons">
                                    <a href="#" class="btn-primary">
                                        <i class="fas fa-star"></i>
                                        Khám Phá
                                    </a>
                                    <a href="#" class="btn-secondary">
                                        <i class="fas fa-share-alt"></i>
                                        Chia Sẻ
                                    </a>
                                </div>
                            </div>
                            <div class="banner-book">
                                <div class="book-showcase">
                                    <div class="book-glow"></div>
                                    <img src="https://images.unsplash.com/photo-1543002588-bfa74002ed7e?w=400&h=600&fit=crop" 
                                         alt="Bestseller Book" class="book-cover">
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Slide 4: Gợi Ý -->
                    <div class="banner-slide gradient-overlay-4">
                        <div class="particles" id="particles-4"></div>
                        <div class="deco-shape deco-1"></div>
                        <div class="deco-shape deco-2"></div>

                        <div class="banner-content">
                            <div class="banner-text">
                                <div class="banner-badge">
                                    <i class="fas fa-magic"></i>
                                    <span>Dành Riêng Cho Bạn</span>
                                </div>
                                <h1 class="banner-title">Gợi Ý<br/>Thông Minh</h1>
                                <p class="banner-description">
                                    Hệ thống của chúng tôi gợi ý sách phù hợp với sở thích của bạn. 
                                    Khám phá những cuốn sách bạn sẽ yêu thích!
                                </p>
                                <div class="banner-stats">
                                    <div class="stat-item">
                                        <div class="stat-number">95%</div>
                                        <div class="stat-label">Chính Xác</div>
                                    </div>
                                    <div class="stat-item">
                                        <div class="stat-number">3.2K</div>
                                        <div class="stat-label">Đề Xuất</div>
                                    </div>
                                    <div class="stat-item">
                                        <div class="stat-number">4.8</div>
                                        <div class="stat-label">Rating</div>
                                    </div>
                                </div>
                                <div class="banner-buttons">
                                    <a href="#" class="btn-primary">
                                        <i class="fas fa-robot"></i>
                                        Nhận Gợi Ý
                                    </a>
                                    <a href="#" class="btn-secondary">
                                        <i class="fas fa-cog"></i>
                                        Tùy Chỉnh
                                    </a>
                                </div>
                            </div>
                            <div class="banner-book">
                                <div class="book-showcase">
                                    <div class="book-glow"></div>
                                    <img src="https://images.unsplash.com/photo-1512820790803-83ca734da794?w=400&h=600&fit=crop" 
                                         alt="Recommended Book" class="book-cover">
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Navigation Arrows -->
                    <button class="nav-arrow left" onclick="prevSlide()">
                        <i class="fas fa-chevron-left"></i>
                    </button>
                    <button class="nav-arrow right" onclick="nextSlide()">
                        <i class="fas fa-chevron-right"></i>
                    </button>

                    <!-- Navigation Dots -->
                    <div class="banner-nav">
                        <div class="nav-dot active" onclick="goToSlide(0)"></div>
                        <div class="nav-dot" onclick="goToSlide(1)"></div>
                        <div class="nav-dot" onclick="goToSlide(2)"></div>
                        <div class="nav-dot" onclick="goToSlide(3)"></div>
                    </div>
                </div>
                <% } %>
                <!-- Search Results Info -->
                <% if (isSearching) {%>
                <div class="mb-10 p-5 md:p-6 glass-effect border border-blue-300 rounded-2xl">
                    <div class="flex flex-col md:flex-row items-center justify-center gap-3 text-center md:text-left">
                        <i class="fas fa-search text-blue-300 mr-0 md:mr-4 text-xl md:text-2xl"></i>
                        <p class="text-blue-100 text-base md:text-lg font-medium">
                            Kết quả tìm kiếm cho: <strong class="text-white">"<%= searchQuery%>"</strong> 
                            (<span class="text-blue-200"><%= searchResults.size()%></span> kết quả được tìm thấy)
                        </p>
                    </div>
                </div>
                <% } %>

                <!-- Search Results Section -->
                <% if (isSearching) { %>
                <section id="search-results" class="category-section mb-16">
                    <div class="category-header mb-4">
                        <div class="flex items-center justify-between gap-4 flex-wrap">
                            <h2 class="text-2xl md:text-3xl font-semibold text-slate-100">
                                Kết quả tìm kiếm
                            </h2>
                            <span class="text-sm text-slate-300">
                                Trang <span class="font-semibold"><%= searchCurrentPage %></span>/<span><%= searchTotalPages %></span>
                                • Tổng <span class="font-semibold"><%= searchTotal %></span> sách
                            </span>
                        </div>
                    </div>

                    <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-5 md:gap-6">
                        <%
                           if (searchResults != null) {
                             for (int i = searchStartIndex; i < searchEndIndex; i++) {
                               Map<String, Object> book = searchResults.get(i);
                        %>
                        <div class="book-card rounded-3xl shadow-lg hover:shadow-2xl group shine-effect">
                            <a href="./user/bookDetails.jsp?isbn=<%= book.get("isbn")%>" class="block h-full">
                                <div class="book-image-container">
                                    <img src="<%= request.getContextPath() + "/" + book.get("coverImage") %>"
                                            alt="<%= book.get("title")%>"
                                            onerror="this.onerror=null; this.src='<%= request.getContextPath() %>/images/default-cover.jpg'"
                                            class="w-full h-full rounded-xl object-cover" />
                                    <div class="book-overlay">
                                        <i class="fas fa-eye text-white text-2xl md:text-3xl transform group-hover:scale-110 transition-transform duration-300 ease-out"></i>
                                    </div>
                                </div>
                                <div class="book-info">
                                    <h3 class="book-title group-hover:text-blue-300 transition-colors duration-200 ease-out line-clamp-2">
                                        <%= book.get("title")%>
                                    </h3>
                                    <div class="book-meta">
                                        <i class="fas fa-user-edit text-blue-400"></i>
                                        <span><%= book.get("author")%></span>
                                    </div>
                                    <div class="book-meta">
                                        <i class="fas fa-calendar text-blue-400"></i>
                                        <span><%= book.get("publishedYear")%></span>
                                    </div>
                                </div>
                            </a>
                        </div>
                        <%
                             } // end for
                           } // end if
                        %>
                    </div>

                    <% if (searchTotalPages > 1) { %>
                    <div class="mt-6 flex justify-center">
                        <nav class="inline-flex items-center space-x-1 bg-slate-900/70 border border-slate-600/80 rounded-full px-2 py-1 shadow-lg">
                            <!-- Prev -->
                            <% if (searchCurrentPage > 1) { %>
                            <a href="<%= baseSearchUrl %>pageSearch=<%= searchCurrentPage - 1 %>" 
                               class="px-3 py-1.5 text-xs md:text-sm rounded-full text-slate-100 hover:bg-slate-700/80 transition-colors duration-200 flex items-center gap-1">
                                <i class="fas fa-chevron-left text-[10px]"></i>
                                <span class="hidden sm:inline">Trước</span>
                            </a>
                            <% } else { %>
                            <span class="px-3 py-1.5 text-xs md:text-sm rounded-full text-slate-500 cursor-default flex items-center gap-1">
                                <i class="fas fa-chevron-left text-[10px]"></i>
                                <span class="hidden sm:inline">Trước</span>
                            </span>
                            <% } %>

                            <!-- page numbers -->
                            <%
                               int searchStartPage = Math.max(1, searchCurrentPage - 2);
                               int searchEndPage = Math.min(searchTotalPages, searchCurrentPage + 2);
                               for (int p = searchStartPage; p <= searchEndPage; p++) {
                            %>
                                <a href="<%= baseSearchUrl %>pageSearch=<%= p %>"
                                   class="px-3 py-1.5 text-xs md:text-sm rounded-full <%= (p == searchCurrentPage ? "bg-slate-100 text-slate-900 font-semibold" : "text-slate-200 hover:bg-slate-700/80") %> transition-colors duration-200">
                                    <%= p %>
                                </a>
                            <% } %>

                            <!-- Next -->
                            <% if (searchCurrentPage < searchTotalPages) { %>
                            <a href="<%= baseSearchUrl %>pageSearch=<%= searchCurrentPage + 1 %>" 
                               class="px-3 py-1.5 text-xs md:text-sm rounded-full text-slate-100 hover:bg-slate-700/80 transition-colors duration-200 flex items-center gap-1">
                                <span class="hidden sm:inline">Sau</span>
                                <i class="fas fa-chevron-right text-[10px]"></i>
                            </a>
                            <% } else { %>
                            <span class="px-3 py-1.5 text-xs md:text-sm rounded-full text-slate-500 cursor-default flex items-center gap-1">
                                <span class="hidden sm:inline">Sau</span>
                                <i class="fas fa-chevron-right text-[10px]"></i>
                            </span>
                            <% } %>
                        </nav>
                    </div>
                    <% } %>
                </section>
                <% } %>


                <% if (!isSearching) { %>
                <!-- Recommendations (render bằng JS sau khi có JWT) -->
                <section id="recommend-section" class="category-section mb-16 hidden">
                  <div class="category-header">
                    <div class="flex items-center justify-between gap-4 flex-wrap">
                      <div class="flex items-center space-x-4">
                        <div class="w-2 h-12 bg-gradient-to-b from-amber-500 to-orange-600 rounded-full"></div>
                        <h2 class="text-3xl md:text-4xl font-bold category-title">Gợi ý cho bạn</h2>
                        <span id="recommend-count" class="count-badge text-amber-100 text-sm font-semibold px-4 py-2 rounded-full">0 đề xuất</span>
                      </div>
                    </div>
                  </div>

                  <div class="shelf-nav">
                    <button type="button" class="shelf-btn left" data-shelf-prev><i class="fas fa-chevron-left text-xs"></i></button>
                    <button type="button" class="shelf-btn right" data-shelf-next><i class="fas fa-chevron-right text-xs"></i></button>

                    <div id="recommend-shelf" class="shelf">
                      <!-- JS sẽ đổ card vào đây -->
                    </div>
                  </div>
                </section>
                <% } %>

                <!-- Books Categories (hiển thị khi không tìm kiếm HOẶC khi không có dữ liệu) -->
                <% if (!isSearching) { %>

                <!-- Sách Bìa Cứng -->
                <section id="hardcover-section" class="category-section mb-16">
                    <div class="category-header">
                        <div class="flex items-center justify-between gap-4 flex-wrap">
                            <div class="flex items-center space-x-4">
                                <div class="w-2 h-12 bg-gradient-to-b from-amber-500 to-orange-600 rounded-full"></div>
                                <h2 class="text-3xl md:text-4xl font-bold category-title">Sách Bìa Cứng</h2>
                                <span class="count-badge text-blue-100 text-sm font-semibold px-4 py-2 rounded-full">
                                    <%
                                        int hardcoverCount = 0;
                                        for (Map<String, Object> book : allBooks) {
                                            if ("HARDCOVER".equals(book.get("format"))) {
                                                hardcoverCount++;
                                            }
                                        }
                                    %>
                                    <%= hardcoverCount%> cuốn sách
                                </span>
                            </div>
                            <a href="./user/booksByCategory.jsp?category=HARDCOVER" class="expand-button text-blue-100 hover:text-white font-semibold transition-all duration-300 flex items-center space-x-3 no-underline">
                                    <span>Xem thêm</span>
                                <i class="fas fa-arrow-right text-xs"></i>
                            </a>
                        </div>
                    </div>

                    <div class="shelf-nav">
                        <button type="button" class="shelf-btn left" data-shelf-prev><i class="fas fa-chevron-left text-xs"></i></button>
                        <button type="button" class="shelf-btn right" data-shelf-next><i class="fas fa-chevron-right text-xs"></i></button>

                        <div class="shelf">
                            <% for (Map<String, Object> book : allBooks) {
                              if ("HARDCOVER".equals(book.get("format"))) {%>
                            <div class="book-card w-fixed rounded-3xl shadow-lg hover:shadow-2xl group shine-effect">
                                <a href="./user/bookDetails.jsp?isbn=<%= book.get("isbn")%>" class="block h-full">
                                    <div class="book-image-container">
                                        <img src="<%= request.getContextPath() + "/" + book.get("coverImage") %>"
                                            alt="<%= book.get("title")%>"
                                            onerror="this.onerror=null; this.src='<%= request.getContextPath() %>/images/default-cover.jpg'"
                                            class="w-full h-full rounded-xl object-cover" />
                                        <div class="book-overlay"><i class="fas fa-eye text-white text-2xl md:text-3xl transform group-hover:scale-110 transition-transform duration-300 ease-out"></i></div>
                                    </div>
                                    <div class="book-info">
                                        <h3 class="book-title group-hover:text-blue-300 transition-colors duration-200 ease-out line-clamp-2"><%= book.get("title")%></h3>
                                        <div class="book-meta"><i class="fas fa-user-edit text-blue-400"></i><span><%= book.get("author")%></span></div>
                                        <div class="book-meta"><i class="fas fa-calendar text-blue-400"></i><span><%= book.get("publishedYear")%></span></div>
                                    </div>
                                </a>
                            </div>
                            <% }
                          } %>
                        </div>
                    </div>

                </section>

                <!-- Sách Bìa Mềm -->
                <section id="paperback-section" class="category-section mb-16">
                    <div class="category-header">
                        <div class="flex items-center justify-between gap-4 flex-wrap">
                            <div class="flex items-center space-x-4">
                                <div class="w-2 h-12 bg-gradient-to-b from-green-500 to-teal-600 rounded-full"></div>
                                <h2 class="text-3xl md:text-4xl font-bold category-title">Sách Bìa Mềm</h2>
                                <span class="count-badge text-green-100 text-sm font-semibold px-4 py-2 rounded-full">
                                    <%
                                        int paperbackCount = 0;
                                        for (Map<String, Object> book : allBooks) {
                                            if ("PAPERBACK".equals(book.get("format"))) {
                                                paperbackCount++;
                                            }
                                        }
                                    %>
                                    <%= paperbackCount%> cuốn sách
                                </span>
                            </div>
                            <a href="./user/booksByCategory.jsp?category=PAPERBACK" class="expand-button text-green-100 hover:text-white font-semibold transition-all duration-300 flex items-center space-x-3 no-underline">
                                <span>Xem thêm</span>
                                <i class="fas fa-arrow-right text-xs"></i>
                            </a>
                        </div>
                    </div>

                    <div class="shelf-nav">
                        <button type="button" class="shelf-btn left" data-shelf-prev><i class="fas fa-chevron-left text-xs"></i></button>
                        <button type="button" class="shelf-btn right" data-shelf-next><i class="fas fa-chevron-right text-xs"></i></button>

                        <div class="shelf">
                            <% for (Map<String, Object> book : allBooks) {
                              if ("PAPERBACK".equals(book.get("format"))) {%>
                            <div class="book-card w-fixed rounded-3xl shadow-lg hover:shadow-2xl group shine-effect">
                                <a href="./user/bookDetails.jsp?isbn=<%= book.get("isbn")%>" class="block h-full">
                                    <div class="book-image-container">
                                       <img src="<%= request.getContextPath() + "/" + book.get("coverImage") %>"
                                            alt="<%= book.get("title")%>"
                                            onerror="this.onerror=null; this.src='<%= request.getContextPath() %>/images/default-cover.jpg'"



                                            class="w-full h-full rounded-xl object-cover" />

                                        <div class="book-overlay"><i class="fas fa-eye text-white text-2xl md:text-3xl transform group-hover:scale-110 transition-transform duration-300 ease-out"></i></div>
                                    </div>
                                    <div class="book-info">
                                        <h3 class="book-title group-hover:text-green-300 transition-colors duration-200 ease-out line-clamp-2"><%= book.get("title")%></h3>
                                        <div class="book-meta"><i class="fas fa-user-edit text-green-400"></i><span><%= book.get("author")%></span></div>
                                        <div class="book-meta"><i class="fas fa-calendar text-green-400"></i><span><%= book.get("publishedYear")%></span></div>
                                    </div>
                                </a>
                            </div>
                            <% }
                          } %>
                        </div>
                    </div>
                </section>

                <!-- Ebook -->
                <section id="ebook-section" class="category-section mb-16">
                    <div class="category-header">
                        <div class="flex items-center justify-between gap-4 flex-wrap">
                            <div class="flex items-center space-x-4">
                                <div class="w-2 h-12 bg-gradient-to-b from-purple-500 to-pink-600 rounded-full"></div>
                                <h2 class="text-3xl md:text-4xl font-bold category-title">Ebook</h2>
                                <span class="count-badge text-purple-100 text-sm font-semibold px-4 py-2 rounded-full">
                                    <%
                                        int ebookCount = 0;
                                        for (Map<String, Object> book : allBooks) {
                                            if ("EBOOK".equals(book.get("format"))) {
                                                ebookCount++;
                                            }
                                        }
                                    %>
                                    <%= ebookCount%> cuốn sách
                                </span>
                            </div>
                            <a href="./user/booksByCategory.jsp?category=EBOOK" class="expand-button text-purple-100 hover:text-white font-semibold transition-all duration-300 flex items-center space-x-3 no-underline">
                                <span>Xem thêm</span>
                                <i class="fas fa-arrow-right text-xs"></i>
                            </a>
                        </div>
                    </div>

                    <div class="shelf-nav">
                        <button type="button" class="shelf-btn left" data-shelf-prev><i class="fas fa-chevron-left text-xs"></i></button>
                        <button type="button" class="shelf-btn right" data-shelf-next><i class="fas fa-chevron-right text-xs"></i></button>

                        <div class="shelf">
                            <% for (Map<String, Object> book : allBooks) {
                              if ("EBOOK".equals(book.get("format"))) {%>
                            <div class="book-card w-fixed rounded-3xl shadow-lg hover:shadow-2xl group shine-effect">
                                <a href="./user/bookDetails.jsp?isbn=<%= book.get("isbn")%>" class="block h-full">
                                    <div class="book-image-container">
                                        <img src="<%= request.getContextPath() + "/" + book.get("coverImage") %>"
                                        alt="<%= book.get("title")%>"
                                        onerror="this.onerror=null; this.src='<%= request.getContextPath() %>/images/default-cover.jpg'"
                                        class="w-full h-full rounded-xl object-cover" />

                                        <div class="book-overlay"><i class="fas fa-eye text-white text-2xl md:text-3xl transform group-hover:scale-110 transition-transform duration-300 ease-out"></i></div>
                                        <div class="absolute top-3 right-3 digital-badge"><i class="fas fa-download"></i><span>Digital</span></div>
                                    </div>
                                    <div class="book-info">
                                        <h3 class="book-title group-hover:text-purple-300 transition-colors duration-200 ease-out line-clamp-2"><%= book.get("title")%></h3>
                                        <div class="book-meta"><i class="fas fa-user-edit text-purple-400"></i><span><%= book.get("author")%></span></div>
                                        <div class="book-meta"><i class="fas fa-calendar text-purple-400"></i><span><%= book.get("publishedYear")%></span></div>
                                    </div>
                                </a>
                            </div>
                            <% }
                          } %>
                        </div>
                    </div>
                </section>
                <% if (!recentBooks.isEmpty()) {%>
                <section id="recent-section" class="category-section mb-16">
                    <div class="category-header">
                        <div class="flex items-center justify-between gap-4 flex-wrap">
                            <div class="flex items-center space-x-4">
                                <div class="w-2 h-12 bg-gradient-to-b from-indigo-500 to-blue-600 rounded-full"></div>
                                <h2 class="text-3xl md:text-4xl font-bold category-title">Sách mới</h2>
                                <span class="count-badge text-indigo-100 text-sm font-semibold px-4 py-2 rounded-full">
                                    <%= recentBooks.size()%> cuốn
                                </span>
                            </div>
                        </div>
                    </div>

                    <div class="shelf-nav">
                        <!-- Nút điều hướng tùy chọn -->
                        <button type="button" class="shelf-btn left" data-shelf-prev><i class="fas fa-chevron-left text-xs"></i></button>
                        <button type="button" class="shelf-btn right" data-shelf-next><i class="fas fa-chevron-right text-xs"></i></button>

                        <div class="shelf">
                            <% for (Map<String, Object> book : recentBooks) {%>
                            <div class="book-card w-fixed rounded-3xl shadow-lg hover:shadow-2xl group shine-effect">
                                <a href="./user/bookDetails.jsp?isbn=<%= book.get("isbn")%>" class="block h-full">
                                    <div class="book-image-container">
                                        <img src="<%= request.getContextPath() + "/" + book.get("coverImage") %>"
                                            alt="<%= book.get("title")%>"
                                            onerror="this.onerror=null; this.src='<%= request.getContextPath() %>/images/default-cover.jpg'"
                                            class="w-full h-full rounded-xl object-cover" />

                                        <div class="book-overlay">
                                            <i class="fas fa-bolt text-yellow-300 text-2xl md:text-3xl transform group-hover:scale-110 transition-transform duration-300 ease-out"></i>
                                        </div>
                                    </div>
                                    <div class="book-info">
                                        <h3 class="book-title group-hover:text-indigo-300 transition-colors duration-200 ease-out line-clamp-2"><%= book.get("title")%></h3>
                                        <div class="book-meta"><i class="fas fa-user-edit text-indigo-400"></i><span><%= book.get("author")%></span></div>
                                        <div class="book-meta"><i class="fas fa-calendar text-indigo-400"></i><span><%= book.get("publishedYear")%></span></div>
                                    </div>
                                </a>
                            </div>
                            <% } %>
                        </div>
                    </div>
                </section>
                        
                <% } %>
                <% if (!hotBorrowBooks.isEmpty()) {%>
                <section id="hot-borrow-section" class="category-section mb-16">
                    <div class="category-header">
                        <div class="flex items-center justify-between gap-4 flex-wrap">
                            <div class="flex items-center space-x-4">
                                <div class="w-2 h-12 bg-gradient-to-b from-rose-500 to-red-600 rounded-full"></div>
                                <h2 class="text-3xl md:text-4xl font-bold category-title">Sách được mượn nhiều</h2>
                                <span class="count-badge text-rose-100 text-sm font-semibold px-4 py-2 rounded-full">
                                    <%= hotBorrowBooks.size()%> tựa sách
                                </span>
                            </div>
                        </div>
                    </div>

                    <div class="shelf-nav">
                        <button type="button" class="shelf-btn left" data-shelf-prev><i class="fas fa-chevron-left text-xs"></i></button>
                        <button type="button" class="shelf-btn right" data-shelf-next><i class="fas fa-chevron-right text-xs"></i></button>

                        <div class="shelf">
                            <% for (Map<String, Object> book : hotBorrowBooks) {%>
                            <div class="book-card w-fixed rounded-3xl shadow-lg hover:shadow-2xl group shine-effect">
                                <a href="./user/bookDetails.jsp?isbn=<%= book.get("isbn")%>" class="block h-full">
                                    <div class="book-image-container">
                                        <img src="<%= request.getContextPath() + "/" + book.get("coverImage") %>"
                                            alt="<%= book.get("title")%>"
                                            onerror="this.onerror=null; this.src='<%= request.getContextPath() %>/images/default-cover.jpg'"
                                            class="w-full h-full rounded-xl object-cover" />

                                        <div class="book-overlay"><i class="fas fa-fire text-orange-300 text-2xl md:text-3xl transform group-hover:scale-110 transition-transform duration-300 ease-out"></i></div>
                                    </div>
                                    <div class="book-info">
                                        <h3 class="book-title group-hover:text-rose-300 transition-colors duration-200 ease-out line-clamp-2"><%= book.get("title")%></h3>
                                        <div class="book-meta"><i class="fas fa-user-edit text-rose-400"></i><span><%= book.get("author")%></span></div>
                                        <div class="book-meta"><i class="fas fa-calendar text-rose-400"></i><span><%= book.get("publishedYear")%></span></div>
                                    </div>
                                </a>
                            </div>
                            <% } %>
                        </div>
                    </div>

                </section>
                <% } %>
                <% if (!genreSections.isEmpty()) { %>
                <section id="genres-sections" class="space-y-12 lg:space-y-16">
                    <% for (Map.Entry<String, List<Map<String, Object>>> en : genreSections.entrySet()) {
                            String gname = en.getKey();
                            List<Map<String, Object>> glist = en.getValue();
                            if (glist == null || glist.isEmpty())
                                continue;
                    %>
                    <div class="category-section">
                        <div class="category-header">
                            <div class="flex items-center justify-between gap-4 flex-wrap">
                                <div class="flex items-center space-x-4">
                                    <div class="w-2 h-12 bg-gradient-to-b from-emerald-500 to-teal-600 rounded-full"></div>
                                    <h2 class="text-3xl md:text-4xl font-bold category-title"><%= gname%></h2>
                                    <span class="count-badge text-emerald-100 text-sm font-semibold px-4 py-2 rounded-full">
                                        <%= glist.size()%> cuốn
                                    </span>
                                </div>
                                <a href="./user/booksByGenre.jsp?name=<%= java.net.URLEncoder.encode(gname, "UTF-8")%>"
                                   class="expand-button text-emerald-100 hover:text-white font-semibold transition-all duration-300 flex items-center space-x-3 no-underline">
                                    <span>Xem thêm</span>
                                    <i class="fas fa-arrow-right text-xs"></i>
                                </a>
                            </div>
                        </div>

                        <div class="shelf-nav">
                            <button type="button" class="shelf-btn left" data-shelf-prev><i class="fas fa-chevron-left text-xs"></i></button>
                            <button type="button" class="shelf-btn right" data-shelf-next><i class="fas fa-chevron-right text-xs"></i></button>

                            <div class="shelf">
                                <% for (Map<String, Object> book : glist) {%>
                                <div class="book-card w-fixed rounded-3xl shadow-lg hover:shadow-2xl group shine-effect">
                                    <a href="./user/bookDetails.jsp?isbn=<%= book.get("isbn")%>" class="block h-full">
                                        <div class="book-image-container">
                                            <img src="<%= request.getContextPath() + "/" + book.get("coverImage") %>"
                                            alt="<%= book.get("title")%>"
                                            onerror="this.onerror=null; this.src='<%= request.getContextPath() %>/images/default-cover.jpg'"
                                            class="w-full h-full rounded-xl object-cover" />

                                            <div class="book-overlay"><i class="fas fa-tags text-white text-2xl md:text-3xl transform group-hover:scale-110 transition-transform duration-300 ease-out"></i></div>
                                        </div>
                                        <div class="book-info">
                                            <h3 class="book-title group-hover:text-emerald-300 transition-colors duration-200 ease-out line-clamp-2"><%= book.get("title")%></h3>
                                            <div class="book-meta"><i class="fas fa-user-edit text-emerald-400"></i><span><%= book.get("author")%></span></div>
                                            <div class="book-meta"><i class="fas fa-calendar text-emerald-400"></i><span><%= book.get("publishedYear")%></span></div>
                                        </div>
                                    </a>
                                </div>
                                <% } %>
                            </div>
                        </div>
                    </div>
                    <% } %>
                </section>
                <% } %>

                <% }%>
                <% } %>
            </main>

            <!-- Enhanced Footer -->
            <jsp:include page="user/layout/footer.jsp" />
            <script>
                // Toggle category expansion with smooth animations (SAFE)
                function toggleCategory(categoryId, button) {
                  const container = categoryId ? document.getElementById(categoryId) : null;
                  if (!container) return; // không có section -> thôi

                  const icon = button ? button.querySelector('i') : null;
                  const buttonText = button ? button.querySelector('span') : null;

                  container.style.transition = 'max-height 0.6s cubic-bezier(0.4, 0, 0.2, 1)';

                  const isCollapsed = container.classList.contains('max-h-[600px]');
                  if (isCollapsed) {
                    container.classList.remove('max-h-[600px]', 'overflow-hidden');
                    container.style.maxHeight = 'none';
                    if (icon) icon.classList.add('rotate-180');
                    if (buttonText) buttonText.textContent = 'Thu gọn';
                  } else {
                    container.classList.add('max-h-[600px]', 'overflow-hidden');
                    container.style.maxHeight = '600px';
                    if (icon) icon.classList.remove('rotate-180');
                    if (buttonText) buttonText.textContent = 'Xem thêm';
                  }
                }

                /* Ủy quyền click: chỉ phản hồi khi bấm vào phần tử có data-toggle-category
                   Ví dụ nút:
                   <button class="expand-button" data-toggle-category="hardcover-section">
                     <span>Xem thêm</span> <i class="fas fa-chevron-down"></i>
                   </button>
                */
                document.addEventListener('click', (e) => {
                  const btn = e.target.closest('[data-toggle-category]');
                  if (!btn) return; // bấm chỗ trống -> không làm gì
                  const id = btn.getAttribute('data-toggle-category');
                  if (!id) return;
                  toggleCategory(id, btn);
                });

                // Reveal animation on scroll
                document.addEventListener('DOMContentLoaded', function () {
                    const observerOptions = {threshold: 0.1, rootMargin: '0px 0px -100px 0px'};
                    const observer = new IntersectionObserver((entries) => {
                        entries.forEach(entry => {
                            if (entry.isIntersecting) {
                                entry.target.style.animation = 'fadeInUp 0.8s ease-out';
                            }
                        });
                    }, observerOptions);
                    document.querySelectorAll('.category-section').forEach(section => {
                        observer.observe(section);
                    });
                });

                // Filter sections
                function filterBooksSections(category) {
                    const sections = document.querySelectorAll('.category-section');
                    sections.forEach(section => {
                        section.style.transition = 'all 0.5s ease';
                    });
                    if (category === 'all') {
                        sections.forEach(section => {
                            section.style.display = 'block';
                            section.style.opacity = '1';
                            section.style.transform = 'translateY(0)';
                        });
                    } else {
                        sections.forEach(section => {
                            if (section.id === category + '-section') {
                                section.style.display = 'block';
                                section.style.opacity = '1';
                                section.style.transform = 'translateY(0)';
                                setTimeout(() => {
                                    section.scrollIntoView({behavior: 'smooth', block: 'start'});
                                }, 200);
                            } else {
                                section.style.opacity = '0.3';
                                section.style.transform = 'translateY(20px)';
                                setTimeout(() => {
                                    section.style.display = 'none';
                                }, 500);
                            }
                        });
                    }
                }

                // Fade-in images
                document.addEventListener('DOMContentLoaded', function () {
                    const bookImages = document.querySelectorAll('.book-image');
                    bookImages.forEach(img => {
                        img.style.opacity = '0';
                        img.addEventListener('load', function () {
                            this.style.transition = 'opacity 0.6s ease';
                            this.style.opacity = '1';
                        });
                    });
                });

                // Custom animations CSS injection
                (function injectCustomKeyframes() {
                    const css = `
                                @keyframes fadeInUp {
                                  from { opacity: 0; transform: translateY(30px); }
                                  to { opacity: 1; transform: translateY(0); }
                                }
                                @keyframes pulse { 0%,100%{transform:scale(1)} 50%{transform:scale(1.03)} }
                                .line-clamp-2 { display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden; }
                                .rotate-180 { transform: rotate(180deg); }
                                .book-card {
                                  transition: transform 0.28s ease-out, box-shadow 0.28s ease-out, background 0.28s ease-out, border-color 0.28s ease-out;
                                }
                                .book-card:hover {
                                  transform: translateY(-4px) scale(1.02);
                                }
                              `;
                    const style = document.createElement('style');
                    style.textContent = css;
                    document.head.appendChild(style);
                })();

                // Parallax effect
                window.addEventListener('scroll', function () {
                    const scrolled = window.pageYOffset;
                    document.querySelectorAll('.floating-book').forEach((el, i) => {
                        const speed = 0.25 + (i * 0.05);
                        el.style.transform = `translateY(${scrolled * speed}px) rotate(${scrolled * 0.06}deg)`;
                    });
                });

                // Lazy/async for images
                (function enableLazyForImages() {
                    document.querySelectorAll('img.book-image, .book-image-container img').forEach(img => {
                        if (!img.hasAttribute('loading'))
                            img.setAttribute('loading', 'lazy');
                        if (!img.hasAttribute('decoding'))
                            img.setAttribute('decoding', 'async');
                    });
                })();

                // ===== FIX: Ẩn loader không chờ tất cả ảnh lazy =====
                (function pageLoading() {
                    const loader = document.getElementById('page-loader');
                    const app = document.getElementById('app-content');
                    if (!loader || !app)
                        return;

                    let finished = false;
                    function hide() {
                        if (finished)
                            return;
                        finished = true;
                        loader.style.opacity = '0';
                        loader.style.transition = 'opacity .25s ease';
                        setTimeout(() => {
                            loader.style.display = 'none';
                        }, 260);
                        app.classList.add('loaded'); // lớp này nằm trong loading.css bạn đã link
                        app.style.opacity = '1';
                    }

                    // 1) Ẩn khi toàn trang load xong (CSS/JS/ảnh trên-fold)
                    window.addEventListener('load', hide, {once: true});

                    // 2) Dù sao cũng ẩn sau 2000ms để không kẹt vì ảnh lazy
                    setTimeout(hide, 2000);
                })();
                
                let currentSlide = 0;
                let autoPlayInterval;
                const slides = document.querySelectorAll('.banner-slide');
                const dots = document.querySelectorAll('.nav-dot');
                const totalSlides = slides.length;

                function createParticles(containerId, count = 20) {
                    const container = document.getElementById(containerId);
                    if (!container) return;

                    for (let i = 0; i < count; i++) {
                        const particle = document.createElement('div');
                        particle.className = 'particle';
                        const size = Math.random() * 60 + 20;
                        particle.style.width = size + 'px';
                        particle.style.height = size + 'px';
                        particle.style.left = Math.random() * 100 + '%';
                        particle.style.animationDelay = Math.random() * 20 + 's';
                        particle.style.animationDuration = (Math.random() * 10 + 15) + 's';
                        container.appendChild(particle);
                    }
                }

                function showSlide(index) {
                    slides[currentSlide].classList.remove('active');
                    slides[currentSlide].classList.add('prev');
                    dots[currentSlide].classList.remove('active');

                    currentSlide = (index + totalSlides) % totalSlides;

                    slides[currentSlide].classList.remove('prev');
                    slides[currentSlide].classList.add('active');
                    dots[currentSlide].classList.add('active');
                }

                function nextSlide() {
                    showSlide(currentSlide + 1);
                    resetAutoPlay();
                }

                function prevSlide() {
                    showSlide(currentSlide - 1);
                    resetAutoPlay();
                }

                function goToSlide(index) {
                    showSlide(index);
                    resetAutoPlay();
                }

                function startAutoPlay() {
                    autoPlayInterval = setInterval(() => {
                        showSlide(currentSlide + 1);
                    }, 5000);
                }

                function resetAutoPlay() {
                    clearInterval(autoPlayInterval);
                    startAutoPlay();
                }

                // Initialize
                document.addEventListener('DOMContentLoaded', () => {
                    createParticles('particles-1');
                    createParticles('particles-2');
                    createParticles('particles-3');
                    createParticles('particles-4');
                    startAutoPlay();
                });

                // Pause on hover
                document.querySelector('.hero-banner').addEventListener('mouseenter', () => {
                    clearInterval(autoPlayInterval);
                });

                document.querySelector('.hero-banner').addEventListener('mouseleave', () => {
                    startAutoPlay();
                });

                // Keyboard navigation
                document.addEventListener('keydown', (e) => {
                    if (e.key === 'ArrowLeft') prevSlide();
                    if (e.key === 'ArrowRight') nextSlide();
                });
            </script>
<script>
(function () {
  const CTX = '<%=request.getContextPath()%>';          // /Library
  const DEFAULT_COVER = CTX + '/images/default-cover.jpg';

  async function loadRecommendations() {
    try {
      const userRaw = localStorage.getItem('user');
      const token   = localStorage.getItem('token');

      if (!userRaw || !token) {
        console.debug('[recommend] no user/token -> skip');
        return;
      }

      let me = null;
      try { me = JSON.parse(userRaw); } catch (e) {}
      if (!me || !me.uid) {
        console.debug('[recommend] invalid user in localStorage');
        return;
      }

      const resp = await fetch(CTX + '/api/recommendations', {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ' + token
        }
      });

      if (!resp.ok) {
        console.error('[recommend] HTTP', resp.status);
        return;
      }

      const data = await resp.json();
      console.log('[recommend] response:', data);

      if (!data || !Array.isArray(data.items) || data.items.length === 0) {
        console.debug('[recommend] empty items');
        return;
      }

      const section = document.getElementById('recommend-section');
      const shelf   = document.getElementById('recommend-shelf');
      const countEl = document.getElementById('recommend-count');
      if (!section || !shelf || !countEl) return;

      shelf.innerHTML = '';

      data.items.forEach((book, idx) => {
        console.log('[recommend] item', idx, book);

        const isbn   = book.isbn || '';
        const title  = book.title || '';
        const author = book.author || '';
        const year   = book.publishedYear || book.publicationYear || '';

        if (!isbn) {
          console.warn('[recommend] missing isbn for item', book);
        }

        let coverImage = book.coverImage || 'images/default-cover.jpg';
        if (coverImage.startsWith('/')) {
          coverImage = CTX + coverImage;      // /Library/images/...
        } else {
          coverImage = CTX + '/' + coverImage;
        }

        // ==== Tạo DOM thủ công, không dùng template literal ====
        const card = document.createElement('div');
        card.className = 'book-card w-fixed rounded-3xl shadow-lg hover:shadow-2xl group shine-effect';

        const link = document.createElement('a');
        link.className = 'block h-full';
        link.href = CTX + '/user/bookDetails.jsp?isbn=' + encodeURIComponent(isbn);

        const imgContainer = document.createElement('div');
        imgContainer.className = 'book-image-container';

        const img = document.createElement('img');
        img.src = coverImage;
        img.alt = title;
        img.className = 'w-full h-full rounded-xl shadow-lg border border-gray-200 object-cover book-image';
        img.onerror = function () {
          this.onerror = null;
          this.src = DEFAULT_COVER;
        };

        const overlay = document.createElement('div');
        overlay.className = 'book-overlay';
        overlay.innerHTML = '<i class="fas fa-eye text-white text-3xl transform group-hover:scale-110 transition-transform duration-300 ease-out"></i>';

        imgContainer.appendChild(img);
        imgContainer.appendChild(overlay);

        const info = document.createElement('div');
        info.className = 'book-info';

        const h3 = document.createElement('h3');
        h3.className = 'book-title group-hover:text-amber-300 transition-colors duration-200 ease-out line-clamp-2';
        h3.textContent = title;

        const metaAuthor = document.createElement('div');
        metaAuthor.className = 'book-meta';
        metaAuthor.innerHTML = '<i class="fas fa-user-edit text-amber-400"></i> ';
        const spanAuthor = document.createElement('span');
        spanAuthor.textContent = author;
        metaAuthor.appendChild(spanAuthor);

        const metaYear = document.createElement('div');
        metaYear.className = 'book-meta';
        metaYear.innerHTML = '<i class="fas fa-calendar text-amber-400"></i> ';
        const spanYear = document.createElement('span');
        spanYear.textContent = year;
        metaYear.appendChild(spanYear);

        info.appendChild(h3);
        info.appendChild(metaAuthor);
        info.appendChild(metaYear);

        link.appendChild(imgContainer);
        link.appendChild(info);

        card.appendChild(link);
        shelf.appendChild(card);
      });

      countEl.textContent = data.items.length + ' đề xuất';
      section.classList.remove('hidden');
    } catch (e) {
      console.error('recommendations error:', e);
    }
  }

  document.addEventListener('DOMContentLoaded', loadRecommendations);
})();
<%!
    // Chuẩn hoá tiếng Việt: bỏ dấu + map đ/Đ -> d, rồi lower-case
    private String normalizeVi(String s) {
        if (s == null) return "";
        String r = Normalizer.normalize(s, Normalizer.Form.NFD);
        // bỏ toàn bộ dấu (combining marks)
        r = r.replaceAll("\\p{InCombiningDiacriticalMarks}+", "");
        // đ/Đ -> d
        r = r.replace('đ', 'd').replace('Đ', 'D');
        return r.toLowerCase(java.util.Locale.ROOT);
    }

    /**
     * fuzzyMatch: các "từ" trong query phải xuất hiện
     * theo thứ tự trong text (sau khi normalizeVi)
     * Ví dụ:
     *   text:  "Đắc Nhân Tâm Dale Carnegie"
     *   query: "dac nhan"  -> true
     *   query: "nhan tam dale" -> true
     *   query: "tam nhan" -> vẫn true (vì theo thứ tự trong chuỗi normalize)
     */
    private boolean fuzzyMatch(String text, String q) {
        text = normalizeVi(text);
        q    = normalizeVi(q);

        if (q.isEmpty()) return true;

        String[] parts = q.split("\\s+");
        int pos = 0;
        for (String part : parts) {
            if (part.isEmpty()) continue;
            pos = text.indexOf(part, pos);
            if (pos == -1) return false;
            pos += part.length();
        }
        return true;
    }
%>

</script>
        </div>
    </body>
</html>
