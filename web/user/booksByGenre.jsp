<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, Servlet.DBConnection" %>
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Sách theo thể loại - Thư viện Sách</title>

  <!-- Tailwind CSS -->
  <script src="https://cdn.tailwindcss.com"></script>

  <!-- Font Awesome -->
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css">

  <!-- Google Fonts -->
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">

  <!-- Favicon -->
  <link rel="icon" href="./images/reading-book.png" type="image/x-icon" />

  <!-- Custom CSS -->
  <link rel="stylesheet" href="style1.css"/>

  <style>
    * {
      font-family: 'Inter', sans-serif;
    }

    /* Card + hover */
    .book-card {
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      will-change: transform, opacity;
    }
    .book-card:hover {
      transform: translateY(-10px) scale(1.02);
      box-shadow: 0 22px 45px rgba(15,23,42,0.35);
    }
    .book-card:hover .book-image {
      transform: scale(1.04);
    }
    .book-image {
      transition: transform 0.4s ease;
      will-change: transform;
    }

    /* Ánh sáng quét */
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
      background: linear-gradient(90deg, transparent, rgba(255,255,255,0.28), transparent);
      transition: left 0.55s;
    }
    .shine-effect:hover::before {
      left: 100%;
    }

    /* Ripple cho nút */
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

    /* Book grid - 5 quyển 1 hàng desktop */
    .book-grid {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 1.25rem;
    }
    @media (min-width: 640px) {
      .book-grid {
        grid-template-columns: repeat(3, minmax(0, 1fr));
      }
    }
    @media (min-width: 1024px) {
      .book-grid {
        grid-template-columns: repeat(4, minmax(0, 1fr));
      }
    }
    @media (min-width: 1280px) {
      .book-grid {
        grid-template-columns: repeat(5, minmax(0, 1fr));
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

  <!-- MAIN -->
  <main class="container-enhanced mx-auto py-10 relative">
    <!-- Page Loader (glass full màn) -->
    <div id="page-loader" role="status" aria-live="polite">
      <div>
        <div class="spinner mb-6"></div>
        <div class="text-center mb-6">
          <div class="loader-title text-xl">Đang tải dữ liệu…</div>
          <div class="loader-sub text-sm">Vui lòng chờ trong giây lát</div>
        </div>

        <!-- Skeleton: 1 hàng sách giả -->
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
          <div class="sk-card"><div class="sk-img shimmer"></div><div class="p-4 space-y-3"><div class="sk-line w1 shimmer relative"></div><div class="sk-line w2 shimmer relative"></div><div class="sk-line w3 shimmer relative"></div></div></div>
          <div class="sk-card"><div class="sk-img shimmer"></div><div class="p-4 space-y-3"><div class="sk-line w1 shimmer relative"></div><div class="sk-line w2 shimmer relative"></div><div class="sk-line w3 shimmer relative"></div></div></div>
          <div class="sk-card"><div class="sk-img shimmer"></div><div class="p-4 space-y-3"><div class="sk-line w1 shimmer relative"></div><div class="sk-line w2 shimmer relative"></div><div class="sk-line w3 shimmer relative"></div></div></div>
        </div>
      </div>
    </div>

    <!-- Nội dung chính -->
    <div id="app-content">
      <%
        request.setCharacterEncoding("UTF-8");
        String genreName = request.getParameter("name");
        if (genreName == null || genreName.trim().isEmpty()) {
      %>
      <!-- Lỗi thiếu param -->
      <div class="glass-effect rounded-2xl p-[1px]">
        <div class="bg-gradient-to-r from-red-50 to-red-100 border-l-4 border-red-500 rounded-2xl p-6 shadow-lg">
          <div class="flex items-center">
            <div class="w-12 h-12 rounded-full bg-red-100 flex items-center justify-center mr-4">
              <i class="fas fa-exclamation-circle text-red-500 text-2xl"></i>
            </div>
            <div>
              <h3 class="text-lg font-semibold text-red-800">Lỗi tham số</h3>
              <p class="text-red-600 mt-1">
                Thiếu tham số
                <code class="bg-red-200 px-2 py-1 rounded text-xs">name</code>
                của thể loại.
              </p>
            </div>
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
      <!-- Không tìm thấy thể loại -->
      <div class="glass-effect rounded-2xl p-[1px]">
        <div class="bg-gradient-to-r from-yellow-50 to-yellow-100 border-l-4 border-yellow-500 rounded-2xl p-6 shadow-lg">
          <div class="flex items-center">
            <div class="w-12 h-12 rounded-full bg-yellow-100 flex items-center justify-center mr-4">
              <i class="fas fa-search text-yellow-500 text-2xl"></i>
            </div>
            <div>
              <h3 class="text-lg font-semibold text-yellow-800">Không tìm thấy</h3>
              <p class="text-yellow-600 mt-1">
                Không tìm thấy thể loại:
                <strong><%= genreName %></strong>
              </p>
            </div>
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
              String sql =
                "SELECT b.isbn, b.title, a.name AS author, b.publicationYear, b.format, b.coverImage " +
                "FROM book b " +
                "JOIN book_genre bg ON bg.book_id = b.id " +
                "LEFT JOIN author a ON a.id = b.authorId " +
                "WHERE bg.genre_id = ? " +
                "ORDER BY " + orderBy + " " +
                "LIMIT ? OFFSET ?";

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
      <div class="breadcrumb mb-4">
        <nav class="flex items-center space-x-2 text-sm font-medium">
          <a href="${pageContext.request.contextPath}/index.jsp"
             class="text-blue-400 hover:text-blue-200 transition-colors flex items-center gap-1">
            <i class="fas fa-home"></i>
            <span>Trang chủ</span>
          </a>
          <i class="fas fa-chevron-right text-slate-400 text-xs"></i>
          <span class="text-slate-100 flex items-center gap-1">
            <i class="fas fa-tags text-xs"></i>
            <span><%= genreName %></span>
          </span>
        </nav>
      </div>

      <!-- Header thể loại trong khung glass -->
      <section class="glass-effect rounded-3xl p-[1px] mb-6">
        <div class="category-header rounded-3xl bg-slate-900/80 border border-slate-700/60 px-6 py-5 shadow-[0_18px_45px_rgba(15,23,42,0.8)]">
          <div class="flex items-center justify-between flex-wrap gap-4">
            <div class="flex items-center space-x-4">
              <div class="w-16 h-16 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-2xl flex items-center justify-center shadow-lg shadow-blue-500/40">
                <i class="fas fa-bookmark text-2xl text-white"></i>
              </div>
              <div>
                <h1 class="text-3xl md:text-4xl font-extrabold text-slate-50 mb-1 tracking-tight">
                  <%= genreName %>
                </h1>
                <p class="text-slate-300 text-sm md:text-base">
                  Khám phá bộ sưu tập
                  <span class="font-semibold"><%= genreName.toLowerCase() %></span>
                  phong phú trong thư viện.
                </p>
              </div>
            </div>

            <div class="flex items-center space-x-4">
              <div class="stats-card bg-slate-900/80 border border-slate-600/60 rounded-2xl px-4 py-3 shadow-lg">
                <div class="text-xs uppercase tracking-wide text-slate-400 mb-1">
                  Tổng số sách
                </div>
                <div class="text-2xl font-bold text-emerald-400">
                  <%= totalBooks %>
                </div>
              </div>
              <a href="${pageContext.request.contextPath}/index.jsp"
                 class="back-button inline-flex items-center gap-2 rounded-full border border-slate-500/70 bg-slate-900/80 text-slate-100 px-4 py-2 text-sm font-semibold shadow-lg hover:bg-slate-800 hover:border-blue-400 hover:text-blue-200 transition-all">
                <i class="fas fa-arrow-left text-xs"></i>
                <span>Quay lại</span>
              </a>
            </div>
          </div>
        </div>
      </section>

      <!-- Filter Form -->
      <section class="glass-effect rounded-2xl p-[1px] mb-8">
        <div class="bg-slate-900/90 rounded-2xl px-5 py-4 flex flex-wrap items-center gap-4 border border-slate-700/80">
          <form class="flex flex-wrap items-center gap-4 w-full" method="get" action="booksByGenre.jsp">
            <input type="hidden" name="name" value="<%= genreName %>">
            <input type="hidden" name="page" value="1">

            <div class="flex items-center gap-2">
              <label class="text-sm font-semibold text-slate-200 flex items-center">
                <i class="fas fa-sort-amount-down mr-2 text-blue-400"></i>
                Sắp xếp
              </label>
              <select name="sort"
                      class="border border-slate-600/80 rounded-lg px-3 py-2 bg-slate-900/80 text-slate-100 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500">
                <option value="newest" <%= "newest".equalsIgnoreCase(sort) || sort == null ? "selected" : "" %>>Mới nhất</option>
                <option value="oldest" <%= "oldest".equalsIgnoreCase(sort) ? "selected" : "" %>>Cũ nhất</option>
                <option value="title"  <%= "title".equalsIgnoreCase(sort) ? "selected" : "" %>>Theo tên</option>
                <option value="year"   <%= "year".equalsIgnoreCase(sort) ? "selected" : "" %>>Theo năm XB</option>
              </select>
            </div>

            <div class="flex items-center gap-2">
              <label class="text-sm font-semibold text-slate-200 flex items-center">
                <i class="fas fa-list mr-2 text-blue-400"></i>
                Mỗi trang
              </label>
              <select name="size"
                      class="border border-slate-600/80 rounded-lg px-3 py-2 bg-slate-900/80 text-slate-100 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500">
                <option <%= booksPerPage == 10 ? "selected" : "" %>>10</option>
                <option <%= booksPerPage == 20 ? "selected" : "" %>>20</option>
                <option <%= booksPerPage == 40 ? "selected" : "" %>>40</option>
                <option <%= booksPerPage == 60 ? "selected" : "" %>>60</option>
              </select>
            </div>

            <button type="submit"
                    class="ml-auto bg-gradient-to-r from-blue-500 to-indigo-600 hover:from-blue-600 hover:to-indigo-700 text-white px-6 py-2 rounded-full text-sm font-semibold shadow-lg hover:shadow-xl transition-all duration-300 transform hover:scale-105 relative overflow-hidden">
              <i class="fas fa-check mr-2"></i>
              Áp dụng
            </button>
          </form>
        </div>
      </section>

      <!-- Books Grid -->
      <section class="glass-effect rounded-3xl p-[1px]">
        <div class="rounded-3xl bg-slate-900/85 border border-slate-700/70 px-4 sm:px-5 py-6">
          <% if (!books.isEmpty()) { %>
          <div class="book-grid">
            <% for (Map<String, Object> book : books) { %>
            <div class="book-card shine-effect rounded-3xl group">
              <a href="bookDetails.jsp?isbn=<%= book.get("isbn") %>" class="block h-full">
                <div class="book-image-container">
                  <img
                      src="<%= request.getContextPath() + "/" + book.get("coverImage") %>"
                      onerror="this.onerror=null; this.src='images/default-cover.jpg'"
                      class="book-image"
                  />
                  <div class="book-overlay">
                    <i class="fas fa-eye text-white text-3xl transform group-hover:scale-110 transition-transform duration-300"></i>
                  </div>
                  <% if ("EBOOK".equals(book.get("format"))) { %>
                  <div class="absolute top-3 right-3 digital-badge">
                    <i class="fas fa-download"></i>
                    <span>Digital</span>
                  </div>
                  <% } %>
                </div>

                <div class="book-info">
                  <h3 class="book-title group-hover:text-blue-300 transition-colors line-clamp-2">
                    <%= book.get("title") %>
                  </h3>
                  <div class="book-meta">
                    <i class="fas fa-user-edit text-blue-400"></i>
                    <span><%= book.get("author") %></span>
                  </div>
                  <div class="book-meta">
                    <i class="fas fa-calendar text-blue-400"></i>
                    <span><%= book.get("publishedYear") %></span>
                  </div>
                  <div class="book-meta">
                    <i class="fas fa-tag text-blue-400"></i>
                    <span class="text-blue-300 font-medium"><%= book.get("format") %></span>
                  </div>
                </div>
              </a>
            </div>
            <% } %>
          </div>
          <% } %>

          <!-- Empty State -->
          <% if (books.isEmpty()) { %>
          <div class="text-center py-16">
            <div class="w-32 h-32 mx-auto mb-6 bg-slate-800 rounded-full flex items-center justify-center shadow-lg shadow-slate-900/80">
              <i class="fas fa-book-open text-4xl text-slate-400"></i>
            </div>
            <h3 class="text-2xl font-bold text-slate-50 mb-2">Không tìm thấy sách</h3>
            <p class="text-slate-400 mb-6">
              Hiện tại chưa có sách nào trong thể loại
              <span class="font-semibold italic"><%= genreName.toLowerCase() %></span>.
            </p>
            <a href="index.jsp"
               class="inline-flex items-center gap-2 bg-slate-800 border border-slate-600 text-slate-100 px-5 py-2.5 rounded-full text-sm font-semibold hover:bg-slate-700 hover:border-blue-400 hover:text-blue-200 transition-all">
              <i class="fas fa-arrow-left"></i>
              <span>Quay lại trang chủ</span>
            </a>
          </div>
          <% } %>
        </div>
      </section>

      <!-- Pagination -->
      <% if (totalPages > 1 && !books.isEmpty()) { %>
      <div class="pagination mt-8 flex justify-center">
        <div class="inline-flex items-center gap-2 bg-slate-900/80 border border-slate-700/70 rounded-full px-3 py-2 shadow-lg">
          <% if (currentPage > 1) { %>
          <a href="?name=<%= java.net.URLEncoder.encode(genreName, "UTF-8") %>&sort=<%= sort == null ? "newest" : sort %>&size=<%= booksPerPage %>&page=<%= currentPage - 1 %>"
             class="px-3 py-1.5 rounded-full text-xs sm:text-sm text-slate-100 border border-slate-600/80 hover:border-blue-400 hover:bg-slate-800 transition-colors flex items-center gap-1">
            <i class="fas fa-chevron-left text-[10px]"></i>
            <span>Trước</span>
          </a>
          <% } %>

          <%
            int startPage = Math.max(1, currentPage - 2);
            int endPage = Math.min(totalPages, currentPage + 2);

            if (startPage > 1) {
          %>
          <a href="?name=<%= java.net.URLEncoder.encode(genreName, "UTF-8") %>&sort=<%= sort == null ? "newest" : sort %>&size=<%= booksPerPage %>&page=1"
             class="page-pill">1</a>
          <% if (startPage > 2) { %>
          <span class="px-1 text-slate-400 text-xs sm:text-sm">…</span>
          <% } %>
          <% } %>

          <% for (int i = startPage; i <= endPage; i++) { %>
            <% if (i == currentPage) { %>
              <span class="px-3 py-1.5 rounded-full text-xs sm:text-sm bg-blue-500 text-white font-semibold">
                <%= i %>
              </span>
            <% } else { %>
              <a href="?name=<%= java.net.URLEncoder.encode(genreName, "UTF-8") %>&sort=<%= sort == null ? "newest" : sort %>&size=<%= booksPerPage %>&page=<%= i %>"
                 class="px-3 py-1.5 rounded-full text-xs sm:text-sm text-slate-100 border border-slate-600/80 hover:border-blue-400 hover:bg-slate-800 transition-colors">
                <%= i %>
              </a>
            <% } %>
          <% } %>

          <% if (endPage < totalPages) { %>
            <% if (endPage < totalPages - 1) { %>
            <span class="px-1 text-slate-400 text-xs sm:text-sm">…</span>
            <% } %>
            <a href="?name=<%= java.net.URLEncoder.encode(genreName, "UTF-8") %>&sort=<%= sort == null ? "newest" : sort %>&size=<%= booksPerPage %>&page=<%= totalPages %>"
               class="px-3 py-1.5 rounded-full text-xs sm:text-sm text-slate-100 border border-slate-600/80 hover:border-blue-400 hover:bg-slate-800 transition-colors">
              <%= totalPages %>
            </a>
          <% } %>

          <% if (currentPage < totalPages) { %>
          <a href="?name=<%= java.net.URLEncoder.encode(genreName, "UTF-8") %>&sort=<%= sort == null ? "newest" : sort %>&size=<%= booksPerPage %>&page=<%= currentPage + 1 %>"
             class="px-3 py-1.5 rounded-full text-xs sm:text-sm text-slate-100 border border-slate-600/80 hover:border-blue-400 hover:bg-slate-800 transition-colors flex items-center gap-1">
            <span>Sau</span>
            <i class="fas fa-chevron-right text-[10px]"></i>
          </a>
          <% } %>
        </div>
      </div>
      <% } %>

      <%
            } // end gid != null
          } catch (SQLException e) {
      %>
      <div class="glass-effect rounded-2xl p-[1px] mt-6">
        <div class="bg-gradient-to-r from-red-50 to-red-100 border-l-4 border-red-500 rounded-2xl p-6 shadow-lg">
          <div class="flex items-center">
            <div class="w-12 h-12 rounded-full bg-red-100 flex items-center justify-center mr-4">
              <i class="fas fa-exclamation-triangle text-red-500 text-2xl"></i>
            </div>
            <div>
              <h3 class="text-lg font-semibold text-red-800">Lỗi kết nối</h3>
              <p class="text-red-600 mt-1"><%= e.getMessage() %></p>
            </div>
          </div>
        </div>
      </div>
      <%
          }
        } // end else has genreName
      %>
    </div> <!-- /#app-content -->
  </main>

  <%@ include file="./layout/footer.jsp" %>

  <!-- Back to Top Button -->
  <button id="backToTop"
          class="fixed bottom-8 right-8 w-12 h-12 bg-gradient-to-r from-blue-500 to-purple-600 text-white rounded-full shadow-lg hover:shadow-xl transition-all duration-300 transform hover:scale-110 opacity-0 invisible flex items-center justify-center">
    <i class="fas fa-arrow-up"></i>
  </button>

  <script>
    // Ẩn loader, show content
    window.addEventListener('load', () => {
      const loader = document.getElementById('page-loader');
      const app = document.getElementById('app-content');
      if (loader) loader.style.display = 'none';
      if (app) app.style.visibility = 'visible';
    });

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
        this.style.position = this.style.position || 'relative';
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
        setTimeout(() => { ripple.remove(); }, 600);
      });
    });

    // Floating elements animation
    const floatingElements = document.querySelectorAll('.floating-book');
    floatingElements.forEach((element, index) => {
      const randomDelay = Math.random() * 2;
      const randomDuration = 6 + Math.random() * 4;
      element.style.animationDelay = randomDelay + 's';
      element.style.animationDuration = randomDuration + 's';
    });
  </script>

  <script src="script.js"></script>
</body>
</html>
