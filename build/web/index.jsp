<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, Servlet.DBConnection, Data.Users, Servlet.RecoClient" %>
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
        <link rel="stylesheet" href="user/home1.css"/>
        <link rel="stylesheet" href="user/banner.css"/>
        <link rel="stylesheet" href="user/loading.css"/>
        <style>
            /* Thanh kệ ngang */
            .shelf {
                display: flex;
                gap: 1.25rem;           /* ~20px */
                overflow-x: auto;
                overflow-y: hidden;
                scroll-behavior: smooth;
                padding-bottom: .25rem; /* tránh cắt bóng đổ */
            }
            .shelf::-webkit-scrollbar {
                height: 10px;
            }
            .shelf::-webkit-scrollbar-thumb {
                background: #c7d2fe;
                border-radius: 9999px;
            }
            .shelf::-webkit-scrollbar-track {
                background: transparent;
            }

            /* Card cố định bề rộng để xếp hàng ngang đẹp */
            .book-card.w-fixed {
                min-width: 200px;
                max-width: 200px;
            }
            @media (min-width: 768px) {
                .book-card.w-fixed {
                    min-width: 220px;
                    max-width: 220px;
                }
            }

            /* Nút điều hướng trái/phải (nếu muốn) */
            .shelf-nav {
                position: relative;
            }
            .shelf-btn {
                position: absolute;
                top: 40%;
                z-index: 10;
                background: rgba(255,255,255,.85);
                border: 1px solid #e5e7eb;
                box-shadow: 0 6px 14px rgba(0,0,0,.08);
            }
            .shelf-btn.left  {
                left: -8px;
            }
            .shelf-btn.right {
                right: -8px;
            }
        </style>
        
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

    <body class="page-background">
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

        <!-- Bọc toàn bộ nội dung trang trong app-content để áp hiệu ứng reveal -->
        <div id="app-content">

            <!-- Floating Background Elements -->
            <div class="floating-elements">
                <i class="fas fa-book floating-book text-8xl text-blue-500" style="top: 5%; left: 80%; animation-delay: 0s;"></i>
                <i class="fas fa-bookmark floating-book text-6xl text-purple-500" style="top: 15%; left: 5%; animation-delay: 2s;"></i>
                <i class="fas fa-feather floating-book text-7xl text-green-500" style="top: 50%; left: 85%; animation-delay: 4s;"></i>
                <i class="fas fa-scroll floating-book text-5xl text-orange-500" style="top: 75%; left: 10%; animation-delay: 6s;"></i>
                <i class="fas fa-glasses floating-book text-6xl text-pink-500" style="top: 35%; left: 90%; animation-delay: 8s;"></i>
            </div>

            <!-- Include Header với Search Component -->
            <jsp:include page="user/layout/header.jsp" />
            
            <!-- Main Content -->
            <main class="container-enhanced py-12">
                <%                
                    Users me = (Users) session.getAttribute("user");                
                    // ===== 1) Lấy đề xuất (nếu đã login) =====
                    List<Map<String, Object>> recBooks = new ArrayList<>();
                    if (me != null) {
                        try (Connection connRec = DBConnection.getConnection()) {
                            List<String> recIsbns = RecoClient.getIsbnForUser(me.getId());
                            if (recIsbns != null && !recIsbns.isEmpty()) {
                                // Khử trùng lặp theo thứ tự
                                List<String> uniq = new ArrayList<>();
                                Set<String> seen = new HashSet<>();
                                for (String s : recIsbns) {
                                    if (s != null && seen.add(s)) {
                                        uniq.add(s);
                                    }
                                }
                                recIsbns = uniq;

                                String placeholders = String.join(",", Collections.nCopies(recIsbns.size(), "?"));
                                String orderBy = String.join(",", recIsbns.stream().map(s -> "?").toArray(String[]::new));

                                String sqlRec
                                        = "SELECT b.isbn, b.title, a.name AS author, b.publicationYear, b.format, b.coverImage "
                                        + "FROM book b "
                                        + "LEFT JOIN author a ON b.authorId = a.id "
                                        + "WHERE b.isbn IN (" + placeholders + ") "
                                        + // LỌC: không lấy sách user đã mượn
                                        "AND NOT EXISTS ( "
                                        + "  SELECT 1 FROM borrow br "
                                        + "  JOIN bookitem bi ON bi.book_item_id = br.book_item_id "
                                        + "  WHERE br.user_id = ? "
                                        + "    AND br.status IN ('Borrowed','Returned','Overdue') "
                                        + "    AND bi.book_isbn = b.isbn "
                                        + ") "
                                        + "ORDER BY FIELD(b.isbn, " + orderBy + ")";

                                try (PreparedStatement psRec = connRec.prepareStatement(sqlRec)) {
                                    int i = 1;
                                    // IN (...)
                                    for (String s : recIsbns) {
                                        psRec.setString(i++, s);
                                    }
                                    // user_id cho NOT EXISTS
                                    psRec.setInt(i++, me.getId());
                                    // FIELD(...)
                                    for (String s : recIsbns) {
                                        psRec.setString(i++, s);
                                    }

                                    try (ResultSet rs = psRec.executeQuery()) {
                                        while (rs.next()) {
                                            Map<String, Object> m = new HashMap<>();
                                            m.put("isbn", rs.getString("isbn"));
                                            m.put("title", rs.getString("title"));
                                            m.put("author", rs.getString("author"));
                                            m.put("publishedYear", rs.getInt("publicationYear"));
                                            m.put("format", rs.getString("format"));
                                            m.put("coverImage",rs.getString("coverImage"));
                                            recBooks.add(m);
                                        }
                                    }
                                }
                            }
                        } catch (Exception ex) {
                            System.err.println("Recommendation error: " + ex.getMessage());
                            // bỏ qua để trang vẫn chạy
                        }
                    }

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

                        // tìm kiếm (nếu có)
                        if (isSearching) {
                            String[] keywords = searchQuery.trim().toLowerCase().split("\\s+");
                            StringBuilder where = new StringBuilder(" WHERE ");
                            for (int i = 0; i < keywords.length; i++) {
                                if (i > 0) {
                                    where.append(" AND ");
                                }
                                where.append("(LOWER(b.title) LIKE ? OR LOWER(a.name) LIKE ?)");
                            }
                            String searchSql = baseSql + where.toString();
                            try (PreparedStatement psSearch = connList.prepareStatement(searchSql)) {
                                int idx = 1;
                                for (String kw : keywords) {
                                    String p = "%" + kw + "%";
                                    psSearch.setString(idx++, p);
                                    psSearch.setString(idx++, p);
                                }
                                try (ResultSet rs = psSearch.executeQuery()) {
                                    while (rs.next()) {
                                        Map<String, Object> book = new HashMap<>();
                                        book.put("isbn", rs.getString("isbn"));
                                        book.put("title", rs.getString("title"));
                                        book.put("author", rs.getString("author"));
                                        book.put("publishedYear", rs.getInt("publicationYear"));
                                        book.put("format", rs.getString("format"));
                                        book.put("coverImage", rs.getString("coverImage"));
                                        searchResults.add(book);
                                    }
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
                        out.println("<div class='glass-effect border border-red-300 text-red-800 px-6 py-4 rounded-2xl mb-6'>"
                                + "<p class='flex items-center'><i class='fas fa-exclamation-triangle mr-3 text-xl'></i>"
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
                %>
                <%
                    // Chỉ hiển thị khi có dữ liệu lọc
                    if ((genreId != null && !genreId.isBlank()) || yearFrom != null || yearTo != null || pagesMin != null) {
                %>
                <section id="filter-results" class="category-section mb-10">
                    <div class="category-header">
                        <div class="flex items-center justify-between">
                            <div class="flex items-center space-x-4">
                                <div class="w-2 h-12 bg-gradient-to-b from-amber-500 to-orange-600 rounded-full"></div>
                                <h2 class="text-4xl font-bold category-title">
                                    Kết quả lọc
                                    <% if (genreName != null) { %> – Thể loại: <%= genreName %> <% } %>
                                    <% if (yearFrom != null || yearTo != null) { %>
                                      – Năm: (<%= yearFrom != null ? yearFrom : "…" %> – <%= yearTo != null ? yearTo : "…" %>)
                                    <% } %>
                                    <% if (pagesMin != null) { %>
                                      – Số trang: ≥ <%= pagesMin %>
                                    <% } %>
                                </h2>
                                <a href="index.jsp" class="expand-button text-blue-700 hover:text-blue-900 font-semibold transition-all duration-300 flex items-center space-x-3 no-underline">Bỏ lọc</a>
                            </div>
                        </div>
                    </div>
                    <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-6">
                        <% for (Map<String,Object> b : filteredBooks) { %>
                          <div class="book-card rounded-3xl shadow-lg hover:shadow-2xl group shine-effect">
                            <a href="./user/bookDetails.jsp?isbn=<%= b.get("isbn")%>" class="block">
                              <div class="book-image-container">
                                <img src="<%= request.getContextPath() + "/" + b.get("coverImage") %>"
                                            alt="<%= b.get("title")%>"
                                            onerror="this.onerror=null; this.src='<%= request.getContextPath() %>/images/default-cover.jpg'"
                                            class="w-full h-auto rounded-xl shadow-lg border border-gray-200 object-cover" />
                                <div class="book-overlay">
                                  <i class="fas fa-eye text-white text-3xl transform group-hover:scale-110 transition-transform duration-300"></i>
                                </div>
                              </div>
                              <div class="book-info">
                                <h3 class="book-title group-hover:text-blue-600 transition-colors line-clamp-2">
                                  <%= b.get("title")%>
                                </h3>
                                <div class="book-meta">
                                  <i class="fas fa-user-edit text-blue-500"></i>
                                  <span><%= b.get("author")%></span>
                                </div>
                                <div class="book-meta">
                                  <i class="fas fa-calendar text-blue-500"></i>
                                  <span><%= b.get("publicationYear")%></span>
                                </div>
                                <div class="book-meta">
                                <i class="fas fa-file-alt text-blue-500"></i>
                                <span><%= b.get("numberOfPages") %> trang</span>
                              </div>
                              </div>                             
                            </a>
                          </div>
                        <% } %>
                      </div>
                </section>
                <%
                    } else {
                %>
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
                                    Hệ thống AI của chúng tôi gợi ý sách phù hợp với sở thích của bạn. 
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
                <!-- Search Results Info -->
                <% if (isSearching) {%>
                <div class="mb-10 p-6 glass-effect border border-blue-300 rounded-2xl">
                    <div class="flex items-center justify-center">
                        <i class="fas fa-search text-blue-600 mr-4 text-xl"></i>
                        <p class="text-blue-900 text-lg font-medium">
                            Kết quả tìm kiếm cho: <strong>"<%= searchQuery%>"</strong> 
                            (<%= searchResults.size()%> kết quả được tìm thấy)
                        </p>
                    </div>
                </div>
                <% } %>

                <!-- Search Results Section -->
                <% if (isSearching) { %>
                <section id="search-results" class="category-section mb-16">
                    <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-6">
                        <% for (Map<String, Object> book : searchResults) {%>
                        <div class="book-card rounded-3xl shadow-lg hover:shadow-2xl group shine-effect">
                            <a href="./user/bookDetails.jsp?isbn=<%= book.get("isbn")%>" class="block">
                                <div class="book-image-container">
                                    <img src="<%= book.get("coverImage")%>" alt="<%= book.get("title")%>"
                                         onerror="this.onerror=null; this.src='images/default-cover.jpg'"
                                         class="book-image" />
                                    <div class="book-overlay">
                                        <i class="fas fa-eye text-white text-3xl transform group-hover:scale-110 transition-transform duration-300"></i>
                                    </div>
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
                                </div>
                            </a>
                        </div>
                        <% } %>
                    </div>
                </section>
                <!--Đề xuất sách-->
                <% } %>
                <% if (me != null && !recBooks.isEmpty()) {%>
                <section id="recommend-section" class="category-section mb-16">
                    <div class="category-header">
                        <div class="flex items-center justify-between">
                            <div class="flex items-center space-x-4">
                                <div class="w-2 h-12 bg-gradient-to-b from-amber-500 to-orange-600 rounded-full"></div>
                                <h2 class="text-4xl font-bold category-title">Gợi ý cho bạn</h2>
                                <span class="count-badge text-amber-800 text-sm font-semibold px-4 py-2 rounded-full">
                                    <%= recBooks.size()%> đề xuất
                                </span>
                            </div>
                        </div>
                    </div>

                    <div class="shelf-nav">
                        <button type="button" class="shelf-btn left rounded-full p-2" data-shelf-prev><i class="fas fa-chevron-left"></i></button>
                        <button type="button" class="shelf-btn right rounded-full p-2" data-shelf-next><i class="fas fa-chevron-right"></i></button>

                        <div class="shelf">
                            <% for (Map<String, Object> book : recBooks) {%>
                            <div class="book-card w-fixed rounded-3xl shadow-lg hover:shadow-2xl group shine-effect">
                                <a href="./user/bookDetails.jsp?isbn=<%= book.get("isbn")%>" class="block">
                                    <div class="book-image-container">
                                        <img src="<%= request.getContextPath() + "/" + book.get("coverImage") %>"
                                            alt="<%= book.get("title")%>"
                                            onerror="this.onerror=null; this.src='<%= request.getContextPath() %>/images/default-cover.jpg'"
                                            class="w-full h-auto rounded-xl shadow-lg border border-gray-200 object-cover" />
                                    </div>
                                    <div class="book-info">
                                        <h3 class="book-title group-hover:text-amber-600 transition-colors line-clamp-2"><%= book.get("title")%></h3>
                                        <div class="book-meta"><i class="fas fa-user-edit text-amber-500"></i><span><%= book.get("author")%></span></div>
                                        <div class="book-meta"><i class="fas fa-calendar text-amber-500"></i><span><%= book.get("publishedYear")%></span></div>
                                    </div>
                                </a>
                            </div>
                            <% } %>
                        </div>
                    </div>

                </section>
                <% } %>

                <!-- Books Categories (hiển thị khi không tìm kiếm HOẶC khi không có dữ liệu) -->
                <% if (!isSearching) { %>

                <!-- Sách Bìa Cứng -->
                <section id="hardcover-section" class="category-section mb-16">
                    <div class="category-header">
                        <div class="flex items-center justify-between">
                            <div class="flex items-center space-x-4">
                                <div class="w-2 h-12 bg-gradient-to-b from-amber-500 to-orange-600 rounded-full"></div>
                                <h2 class="text-4xl font-bold category-title">Sách Bìa Cứng</h2>
                                <span class="count-badge text-blue-800 text-sm font-semibold px-4 py-2 rounded-full">
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
                            <a href="./user/booksByCategory.jsp?category=HARDCOVER" class="expand-button text-blue-700 hover:text-blue-900 font-semibold transition-all duration-300 flex items-center space-x-3 no-underline">
                                    <span>Xem thêm</span>
                                <i class="fas fa-arrow-right transition-transform duration-300 group-hover:translate-x-1"></i>
                            </a>
                        </div>
                    </div>

                    <div class="shelf-nav">
                        <button type="button" class="shelf-btn left rounded-full p-2" data-shelf-prev><i class="fas fa-chevron-left"></i></button>
                        <button type="button" class="shelf-btn right rounded-full p-2" data-shelf-next><i class="fas fa-chevron-right"></i></button>

                        <div class="shelf">
                            <% for (Map<String, Object> book : allBooks) {
                              if ("HARDCOVER".equals(book.get("format"))) {%>
                            <div class="book-card w-fixed rounded-3xl shadow-lg hover:shadow-2xl group shine-effect">
                                <a href="./user/bookDetails.jsp?isbn=<%= book.get("isbn")%>" class="block">
                                    <div class="book-image-container">
                                        <img src="<%= request.getContextPath() + "/" + book.get("coverImage") %>"
                                            alt="<%= book.get("title")%>"
                                            onerror="this.onerror=null; this.src='<%= request.getContextPath() %>/images/default-cover.jpg'"
                                            class="w-full h-auto rounded-xl shadow-lg border border-gray-200 object-cover" />
                                        <div class="book-overlay"><i class="fas fa-eye text-white text-3xl transform group-hover:scale-110 transition-transform"></i></div>
                                    </div>
                                    <div class="book-info">
                                        <h3 class="book-title group-hover:text-blue-600 transition-colors line-clamp-2"><%= book.get("title")%></h3>
                                        <div class="book-meta"><i class="fas fa-user-edit text-blue-500"></i><span><%= book.get("author")%></span></div>
                                        <div class="book-meta"><i class="fas fa-calendar text-blue-500"></i><span><%= book.get("publishedYear")%></span></div>
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
                        <div class="flex items-center justify-between">
                            <div class="flex items-center space-x-4">
                                <div class="w-2 h-12 bg-gradient-to-b from-green-500 to-teal-600 rounded-full"></div>
                                <h2 class="text-4xl font-bold category-title">Sách Bìa Mềm</h2>
                                <span class="count-badge text-green-800 text-sm font-semibold px-4 py-2 rounded-full">
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
                            <a href="./user/booksByCategory.jsp?category=PAPERBACK" class="expand-button text-green-700 hover:text-green-900 font-semibold transition-all duration-300 flex items-center space-x-3 no-underline">
                                <span>Xem thêm</span>
                                <i class="fas fa-arrow-right transition-transform duration-300 group-hover:translate-x-1"></i>
                            </a>
                        </div>
                    </div>

                    <div class="shelf-nav">
                        <button type="button" class="shelf-btn left rounded-full p-2" data-shelf-prev><i class="fas fa-chevron-left"></i></button>
                        <button type="button" class="shelf-btn right rounded-full p-2" data-shelf-next><i class="fas fa-chevron-right"></i></button>

                        <div class="shelf">
                            <% for (Map<String, Object> book : allBooks) {
                              if ("PAPERBACK".equals(book.get("format"))) {%>
                            <div class="book-card w-fixed rounded-3xl shadow-lg hover:shadow-2xl group shine-effect">
                                <a href="./user/bookDetails.jsp?isbn=<%= book.get("isbn")%>" class="block">
                                    <div class="book-image-container">
                                       <img src="<%= request.getContextPath() + "/" + book.get("coverImage") %>"
                                            alt="<%= book.get("title")%>"
                                            onerror="this.onerror=null; this.src='<%= request.getContextPath() %>/images/default-cover.jpg'"
                                            class="w-full h-auto rounded-xl shadow-lg border border-gray-200 object-cover" />

                                        <div class="book-overlay"><i class="fas fa-eye text-white text-3xl transform group-hover:scale-110 transition-transform"></i></div>
                                    </div>
                                    <div class="book-info">
                                        <h3 class="book-title group-hover:text-green-600 transition-colors line-clamp-2"><%= book.get("title")%></h3>
                                        <div class="book-meta"><i class="fas fa-user-edit text-green-500"></i><span><%= book.get("author")%></span></div>
                                        <div class="book-meta"><i class="fas fa-calendar text-green-500"></i><span><%= book.get("publishedYear")%></span></div>
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
                        <div class="flex items-center justify-between">
                            <div class="flex items-center space-x-4">
                                <div class="w-2 h-12 bg-gradient-to-b from-purple-500 to-pink-600 rounded-full"></div>
                                <h2 class="text-4xl font-bold category-title">Ebook</h2>
                                <span class="count-badge text-purple-800 text-sm font-semibold px-4 py-2 rounded-full">
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
                            <a href="./user/booksByCategory.jsp?category=EBOOK" class="expand-button text-purple-700 hover:text-purple-900 font-semibold transition-all duration-300 flex items-center space-x-3 no-underline">
                                <span>Xem thêm</span>
                                <i class="fas fa-arrow-right transition-transform duration-300 group-hover:translate-x-1"></i>
                            </a>
                        </div>
                    </div>

                    <div class="shelf-nav">
                        <button type="button" class="shelf-btn left rounded-full p-2" data-shelf-prev><i class="fas fa-chevron-left"></i></button>
                        <button type="button" class="shelf-btn right rounded-full p-2" data-shelf-next><i class="fas fa-chevron-right"></i></button>

                        <div class="shelf">
                            <% for (Map<String, Object> book : allBooks) {
                              if ("EBOOK".equals(book.get("format"))) {%>
                            <div class="book-card w-fixed rounded-3xl shadow-lg hover:shadow-2xl group shine-effect">
                                <a href="./user/bookDetails.jsp?isbn=<%= book.get("isbn")%>" class="block">
                                    <div class="book-image-container">
                                        <img src="<%= request.getContextPath() + "/" + book.get("coverImage") %>"
                                        alt="<%= book.get("title")%>"
                                        onerror="this.onerror=null; this.src='<%= request.getContextPath() %>/images/default-cover.jpg'"
                                        class="w-full h-auto rounded-xl shadow-lg border border-gray-200 object-cover" />

                                        <div class="book-overlay"><i class="fas fa-eye text-white text-3xl transform group-hover:scale-110 transition-transform"></i></div>
                                        <div class="absolute top-3 right-3 digital-badge"><i class="fas fa-download"></i><span>Digital</span></div>
                                    </div>
                                    <div class="book-info">
                                        <h3 class="book-title group-hover:text-purple-600 transition-colors line-clamp-2"><%= book.get("title")%></h3>
                                        <div class="book-meta"><i class="fas fa-user-edit text-purple-500"></i><span><%= book.get("author")%></span></div>
                                        <div class="book-meta"><i class="fas fa-calendar text-purple-500"></i><span><%= book.get("publishedYear")%></span></div>
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
                        <div class="flex items-center justify-between">
                            <div class="flex items-center space-x-4">
                                <div class="w-2 h-12 bg-gradient-to-b from-indigo-500 to-blue-600 rounded-full"></div>
                                <h2 class="text-4xl font-bold category-title">Sách mới</h2>
                                <span class="count-badge text-indigo-800 text-sm font-semibold px-4 py-2 rounded-full">
                                    <%= recentBooks.size()%> cuốn
                                </span>
                            </div>
                        </div>
                    </div>

                    <div class="shelf-nav">
                        <!-- Nút điều hướng tùy chọn -->
                        <button type="button" class="shelf-btn left rounded-full p-2" data-shelf-prev><i class="fas fa-chevron-left"></i></button>
                        <button type="button" class="shelf-btn right rounded-full p-2" data-shelf-next><i class="fas fa-chevron-right"></i></button>

                        <div class="shelf">
                            <% for (Map<String, Object> book : recentBooks) {%>
                            <div class="book-card w-fixed rounded-3xl shadow-lg hover:shadow-2xl group shine-effect">
                                <a href="./user/bookDetails.jsp?isbn=<%= book.get("isbn")%>" class="block">
                                    <div class="book-image-container">
                                        <img src="<%= request.getContextPath() + "/" + book.get("coverImage") %>"
                                            alt="<%= book.get("title")%>"
                                            onerror="this.onerror=null; this.src='<%= request.getContextPath() %>/images/default-cover.jpg'"
                                            class="w-full h-auto rounded-xl shadow-lg border border-gray-200 object-cover" />

                                        <div class="book-overlay">
                                            <i class="fas fa-bolt text-yellow-300 text-3xl transform group-hover:scale-110 transition-transform"></i>
                                        </div>
                                    </div>
                                    <div class="book-info">
                                        <h3 class="book-title group-hover:text-indigo-600 transition-colors line-clamp-2"><%= book.get("title")%></h3>
                                        <div class="book-meta"><i class="fas fa-user-edit text-indigo-500"></i><span><%= book.get("author")%></span></div>
                                        <div class="book-meta"><i class="fas fa-calendar text-indigo-500"></i><span><%= book.get("publishedYear")%></span></div>
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
                        <div class="flex items-center justify-between">
                            <div class="flex items-center space-x-4">
                                <div class="w-2 h-12 bg-gradient-to-b from-rose-500 to-red-600 rounded-full"></div>
                                <h2 class="text-4xl font-bold category-title">Sách được mượn nhiều</h2>
                                <span class="count-badge text-rose-800 text-sm font-semibold px-4 py-2 rounded-full">
                                    <%= hotBorrowBooks.size()%> tựa sách
                                </span>
                            </div>
                        </div>
                    </div>

                    <div class="shelf-nav">
                        <button type="button" class="shelf-btn left rounded-full p-2" data-shelf-prev><i class="fas fa-chevron-left"></i></button>
                        <button type="button" class="shelf-btn right rounded-full p-2" data-shelf-next><i class="fas fa-chevron-right"></i></button>

                        <div class="shelf">
                            <% for (Map<String, Object> book : hotBorrowBooks) {%>
                            <div class="book-card w-fixed rounded-3xl shadow-lg hover:shadow-2xl group shine-effect">
                                <a href="./user/bookDetails.jsp?isbn=<%= book.get("isbn")%>" class="block">
                                    <div class="book-image-container">
                                        <img src="<%= request.getContextPath() + "/" + book.get("coverImage") %>"
                                            alt="<%= book.get("title")%>"
                                            onerror="this.onerror=null; this.src='<%= request.getContextPath() %>/images/default-cover.jpg'"
                                            class="w-full h-auto rounded-xl shadow-lg border border-gray-200 object-cover" />

                                        <div class="book-overlay"><i class="fas fa-fire text-orange-300 text-3xl transform group-hover:scale-110 transition-transform"></i></div>
                                    </div>
                                    <div class="book-info">
                                        <h3 class="book-title group-hover:text-rose-600 transition-colors line-clamp-2"><%= book.get("title")%></h3>
                                        <div class="book-meta"><i class="fas fa-user-edit text-rose-500"></i><span><%= book.get("author")%></span></div>
                                        <div class="book-meta"><i class="fas fa-calendar text-rose-500"></i><span><%= book.get("publishedYear")%></span></div>
                                    </div>
                                </a>
                            </div>
                            <% } %>
                        </div>
                    </div>

                </section>
                <% } %>
                <% if (!genreSections.isEmpty()) { %>
                <section id="genres-sections" class="space-y-16">
                    <% for (Map.Entry<String, List<Map<String, Object>>> en : genreSections.entrySet()) {
                            String gname = en.getKey();
                            List<Map<String, Object>> glist = en.getValue();
                            if (glist == null || glist.isEmpty())
                                continue;
                    %>
                    <div class="category-section">
                        <div class="category-header">
                            <div class="flex items-center justify-between">
                                <div class="flex items-center space-x-4">
                                    <div class="w-2 h-12 bg-gradient-to-b from-emerald-500 to-teal-600 rounded-full"></div>
                                    <h2 class="text-4xl font-bold category-title"><%= gname%></h2>
                                    <span class="count-badge text-emerald-800 text-sm font-semibold px-4 py-2 rounded-full">
                                        <%= glist.size()%> cuốn
                                    </span>
                                </div>
                                <a href="./user/booksByGenre.jsp?name=<%= java.net.URLEncoder.encode(gname, "UTF-8")%>"
                                   class="expand-button text-emerald-700 hover:text-emerald-900 font-semibold transition-all duration-300 flex items-center space-x-3 no-underline">
                                    <span>Xem thêm</span>
                                    <i class="fas fa-arrow-right transition-transform duration-300 group-hover:translate-x-1"></i>
                                </a>
                            </div>
                        </div>

                        <div class="shelf-nav">
                            <button type="button" class="shelf-btn left rounded-full p-2" data-shelf-prev><i class="fas fa-chevron-left"></i></button>
                            <button type="button" class="shelf-btn right rounded-full p-2" data-shelf-next><i class="fas fa-chevron-right"></i></button>

                            <div class="shelf">
                                <% for (Map<String, Object> book : glist) {%>
                                <div class="book-card w-fixed rounded-3xl shadow-lg hover:shadow-2xl group shine-effect">
                                    <a href="./user/bookDetails.jsp?isbn=<%= book.get("isbn")%>" class="block">
                                        <div class="book-image-container">
                                            <img src="<%= request.getContextPath() + "/" + book.get("coverImage") %>"
                                            alt="<%= book.get("title")%>"
                                            onerror="this.onerror=null; this.src='<%= request.getContextPath() %>/images/default-cover.jpg'"
                                            class="w-full h-auto rounded-xl shadow-lg border border-gray-200 object-cover" />

                                            <div class="book-overlay"><i class="fas fa-tags text-white text-3xl transform group-hover:scale-110 transition-transform"></i></div>
                                        </div>
                                        <div class="book-info">
                                            <h3 class="book-title group-hover:text-emerald-600 transition-colors line-clamp-2"><%= book.get("title")%></h3>
                                            <div class="book-meta"><i class="fas fa-user-edit text-emerald-500"></i><span><%= book.get("author")%></span></div>
                                            <div class="book-meta"><i class="fas fa-calendar text-emerald-500"></i><span><%= book.get("publishedYear")%></span></div>
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
                                @keyframes pulse { 0%,100%{transform:scale(1)} 50%{transform:scale(1.05)} }
                                .line-clamp-2 { display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden; }
                                .rotate-180 { transform: rotate(180deg); }
                                .book-card:hover { animation: pulse 2s infinite; }
                              `;
                    const style = document.createElement('style');
                    style.textContent = css;
                    document.head.appendChild(style);
                })();

                // Parallax effect
                window.addEventListener('scroll', function () {
                    const scrolled = window.pageYOffset;
                    document.querySelectorAll('.floating-book').forEach((el, i) => {
                        const speed = 0.5 + (i * 0.1);
                        el.style.transform = `translateY(${scrolled * speed}px) rotate(${scrolled * 0.1}deg)`;
                    });
                });

                // Lazy/async for images
                (function enableLazyForImages() {
                    document.querySelectorAll('img.book-image').forEach(img => {
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
        </div>
    </body>
</html>