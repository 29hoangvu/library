<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*" %>
<%@ page import="Servlet.DBConnection, Data.Users" %>
<!DOCTYPE html>
<html lang="vi">
  <head>
    <meta charset="UTF-8">
    <title>Chi Tiết Sách - Thư viện</title>

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
  </head>

  <body class="page-background">
    <!-- Floating Background Elements -->
    <div class="floating-elements">
      <i class="fas fa-book floating-book text-6xl text-blue-500" style="top: 10%; left: 85%; animation-delay: 0s;"></i>
      <i class="fas fa-bookmark floating-book text-4xl text-purple-500" style="top: 20%; left: 10%; animation-delay: 2s;"></i>
      <i class="fas fa-feather floating-book text-5xl text-green-500" style="top: 60%; left: 90%; animation-delay: 4s;"></i>
      <i class="fas fa-scroll floating-book text-4xl text-orange-500" style="top: 80%; left: 5%; animation-delay: 6s;"></i>
    </div>

    <!-- Header -->
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

      Map<String, Object> book = new HashMap<>();
      List<String> bgenres = new ArrayList<>();
      List<Map<String, Object>> relatedBooks = new ArrayList<>();

      try (Connection conn = DBConnection.getConnection()) {
          String sql =
              "SELECT b.title, a.name AS author, b.publicationYear, b.format, b.coverImage, " +
              "       bd.description, r.rack_number, g.name AS genre, b.quantity, " +
              "       (SELECT COUNT(*) FROM ebook_read_log l WHERE l.isbn = b.isbn) AS views_total " +
              "FROM book b " +
              "JOIN author a ON b.authorId = a.id " +
              "LEFT JOIN book_description bd ON b.isbn = bd.isbn " +
              "LEFT JOIN bookitem bi ON b.isbn = bi.book_isbn " +
              "LEFT JOIN rack r ON bi.rack_id = r.rack_id " +
              "LEFT JOIN book_genre bg ON b.id = bg.book_id " +
              "LEFT JOIN genre g ON bg.genre_id = g.id " +
              "WHERE b.isbn = ?";

          try (PreparedStatement stmt = conn.prepareStatement(sql)) {
              stmt.setString(1, isbn);
              try (ResultSet rs = stmt.executeQuery()) {
                  while (rs.next()) {
                      book.put("title", rs.getString("title"));
                      book.put("author", rs.getString("author"));
                      book.put("description", rs.getString("description"));
                      book.put("format", rs.getString("format"));
                      book.put("coverImage", rs.getString("coverImage"));
                      book.put("rack", rs.getString("rack_number") != null ? rs.getString("rack_number") : "Chưa sắp xếp");

                      int pubY = rs.getInt("publicationYear");
                      book.put("publicationYear", pubY > 0 ? pubY : null);

                      book.put("quantity", rs.getObject("quantity"));
                      book.put("views_total", rs.getInt("views_total"));

                      String g = rs.getString("genre");
                      if (g != null && !bgenres.contains(g)) {
                          bgenres.add(g);
                      }
                  }
              }
          }
      } catch (SQLException e) {
    %>
        <main class="container-enhanced py-12 relative z-[1]">
          <div class="glass-effect rounded-3xl p-8 text-red-200">
            <p class="text-lg font-semibold mb-2">
              <i class="fas fa-exclamation-triangle mr-2"></i>Lỗi kết nối CSDL:
            </p>
            <p class="text-sm"><%= e.getMessage() %></p>
          </div>
        </main>
    <%
        return;
      }

      String title = (String) book.get("title");
      if (title == null) {
    %>
      <main class="container-enhanced py-12 relative z-[1]">
        <div class="glass-effect rounded-3xl p-8 text-center">
          <p class="text-yellow-200 text-lg font-semibold mb-2">
            <i class="fas fa-search mr-2"></i>Không tìm thấy sách với ISBN: <span class="font-mono"><%= isbn %></span>
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

      // Lấy sách cùng thể loại (dựa vào genre đầu tiên)
      String primaryGenre = bgenres.isEmpty() ? null : bgenres.get(0);
      if (primaryGenre != null) {
          try (Connection conn2 = DBConnection.getConnection()) {
              String relSql =
                  "SELECT DISTINCT b.isbn, b.title, b.coverImage, a.name AS author " +
                  "FROM book b " +
                  "JOIN book_genre bg ON bg.book_id = b.id " +
                  "JOIN genre g ON g.id = bg.genre_id " +
                  "LEFT JOIN author a ON a.id = b.authorId " +
                  "WHERE g.name = ? AND b.isbn <> ? AND b.status = 'ACTIVE' " +
                  "ORDER BY b.id DESC LIMIT 8";

              try (PreparedStatement ps2 = conn2.prepareStatement(relSql)) {
                  ps2.setString(1, primaryGenre);
                  ps2.setString(2, isbn);
                  try (ResultSet rs2 = ps2.executeQuery()) {
                      while (rs2.next()) {
                          Map<String, Object> rb = new HashMap<>();
                          rb.put("isbn", rs2.getString("isbn"));
                          rb.put("title", rs2.getString("title"));
                          rb.put("coverImage", rs2.getString("coverImage"));
                          rb.put("author", rs2.getString("author"));
                          relatedBooks.add(rb);
                      }
                  }
              }
          } catch (SQLException ignore) {}
      }
    %>

    <!-- Main -->
    <main class="container-enhanced py-10 relative z-[1]">
      <!-- Back button (mũi tên ở trên) -->
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
          <span class="font-mono tracking-wider">ISBN: <%= isbn %></span>
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
                  <img src="<%= request.getContextPath() + "/" + book.get("coverImage") %>"
                       alt="<%= title %>"
                       onerror="this.onerror=null; this.src='<%= request.getContextPath() %>/images/default-cover.jpg'"
                       class="book-image" />
                  <div class="book-overlay">
                    <i class="fas fa-book-open text-white text-3xl"></i>
                  </div>
                </div>
              </div>

              <!-- Action buttons -->
              <div class="w-full max-w-sm flex flex-col sm:flex-row gap-3">
                <%
                  String format = (String) book.get("format");
                  boolean isEbook = format != null && "EBOOK".equalsIgnoreCase(format);
                %>
                <% if (isEbook) { %>
                  <a href="readBook.jsp?isbn=<%= isbn%>"
                     class="flex-1 inline-flex items-center justify-center gap-2 px-4 py-3 rounded-xl bg-gradient-to-r from-sky-500 to-emerald-400 text-slate-900 font-semibold shadow-lg hover:shadow-xl hover:from-sky-400 hover:to-emerald-300 transition-transform duration-200 hover:-translate-y-0.5">
                    <i class="fas fa-book-open"></i>
                    <span>Đọc online</span>
                  </a>
                  <a href="<%= request.getContextPath() %>/ebook?isbn=<%= isbn %>&download=true"
                     class="flex-1 inline-flex items-center justify-center gap-2 px-4 py-3 rounded-xl bg-slate-900/90 border border-emerald-500/70 text-emerald-200 font-semibold shadow-lg hover:shadow-xl hover:bg-slate-900 hover:border-emerald-300 transition-transform duration-200 hover:-translate-y-0.5">
                    <i class="fas fa-download"></i>
                    <span>Tải về</span>
                  </a>
                <% } else { %>
                  <button id="btnBorrow"
                          class="w-full inline-flex items-center justify-center gap-2 px-4 py-3 rounded-xl bg-gradient-to-r from-indigo-500 to-blue-500 text-white font-semibold shadow-lg hover:shadow-xl hover:from-indigo-400 hover:to-blue-400 transition-transform duration-200 hover:-translate-y-0.5">
                    <i class="fas fa-hand-holding"></i>
                    <span>Đăng ký mượn</span>
                  </button>
                <% } %>
              </div>
            </div>

            <%
              String formatVi;
              if (format == null) {
                  formatVi = "Không rõ";
              } else {
                  switch (format) {
                      case "HARDCOVER": formatVi = "Bìa cứng"; break;
                      case "PAPERBACK": formatVi = "Bìa mềm"; break;
                      case "EBOOK":     formatVi = "Sách điện tử"; break;
                      default:          formatVi = format;
                  }
              }

              Number qtyNum = null;
              Object qObj = book.get("quantity");
              if (qObj instanceof Number) qtyNum = (Number) qObj;
              int qty = (qtyNum == null ? 0 : qtyNum.intValue());

              int viewsTotal;
              Object vObj = book.get("views_total");
              if (vObj instanceof Number) viewsTotal = ((Number) vObj).intValue();
              else viewsTotal = 0;

              Object pubYObj = book.get("publicationYear");
              String pubYearText = (pubYObj == null) ? "Chưa cập nhật" : String.valueOf(pubYObj);
            %>

            <!-- Cột giữa: thông tin (2 cột) -->
            <div class="lg:col-span-2 flex flex-col gap-7">
              <!-- Tiêu đề + tác giả -->
              <header class="space-y-3">
                <h1 class="text-3xl md:text-4xl font-extrabold tracking-tight text-slate-50">
                  <%= title %>
                </h1>
                <p class="text-lg text-slate-300 flex items-center gap-2">
                  <span class="inline-flex h-8 w-8 items-center justify-center rounded-full bg-slate-800/90 border border-slate-600 text-sky-400 shadow-md">
                    <i class="fas fa-user-pen"></i>
                  </span>
                  <span>
                    Tác giả:
                    <span class="font-semibold text-slate-100"><%= book.get("author") %></span>
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
                  <p class="text-slate-300 ml-6 text-sm md:text-base"><%= pubYearText %></p>
                </div>

                <!-- Định dạng -->
                <div class="profile-row">
                  <div class="flex items-center mb-1.5">
                    <i class="fas fa-file-alt text-emerald-400 mr-2"></i>
                    <span class="font-semibold text-slate-100 text-sm">Định dạng</span>
                  </div>
                  <p class="text-slate-300 ml-6 text-sm md:text-base"><%= formatVi %></p>
                </div>

                <% if (isEbook) { %>
                  <!-- EBOOK: lượt đọc -->
                  <div class="profile-row">
                    <div class="flex items-center mb-1.5">
                      <i class="fas fa-eye text-indigo-400 mr-2"></i>
                      <span class="font-semibold text-slate-100 text-sm">Lượt đọc</span>
                    </div>
                    <p class="text-slate-200 ml-6 text-base font-semibold">
                      <span class="text-lg"><%= viewsTotal %></span>
                    </p>
                  </div>
                <% } else { %>
                  <!-- Sách giấy: số lượng -->
                  <div class="profile-row">
                    <div class="flex items-center mb-1.5">
                      <i class="fas fa-warehouse text-amber-400 mr-2"></i>
                      <span class="font-semibold text-slate-100 text-sm">Số lượng còn lại</span>
                    </div>
                    <p class="ml-6 text-base font-semibold <%= qty > 0 ? "text-emerald-400" : "text-red-400" %>">
                      <%= qtyNum == null ? "0" : String.valueOf(qty) %>
                    </p>
                  </div>

                  <!-- Sách giấy: vị trí kệ -->
                  <div class="profile-row">
                    <div class="flex items-center mb-1.5">
                      <i class="fas fa-map-marker-alt text-fuchsia-400 mr-2"></i>
                      <span class="font-semibold text-slate-100 text-sm">Vị trí kệ</span>
                    </div>
                    <p class="text-slate-300 ml-6 text-sm md:text-base"><%= book.get("rack") %></p>
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
                  <% if (bgenres.isEmpty()) { %>
                    <span class="text-xs text-slate-400 italic">Chưa có thông tin thể loại.</span>
                  <% } else { 
                       for (String genre : bgenres) { %>
                        <span class="inline-flex items-center bg-yellow-100/10 text-amber-200 text-xs md:text-sm font-medium px-3 py-1 rounded-full shadow-sm border border-amber-400/40">
                          <i class="fas fa-tag mr-1.5 text-amber-300"></i><%= genre %>
                        </span>
                  <%   }
                     } %>
                </div>
              </section>
            </div>

            <!-- Cột phải: Sidebar gợi ý (1 cột) -->
            <div class="hidden lg:block lg:col-span-1">
              <aside class="profile-card p-4 sticky top-24">
                <div class="flex items-center justify-between mb-3">
                  <div class="flex items-center gap-2">
                    <span class="inline-flex h-8 w-8 items-center justify-center rounded-full bg-slate-900/80 border border-slate-700 shadow-md">
                      <i class="fas fa-lightbulb text-yellow-300"></i>
                    </span>
                    <div class="flex flex-col">
                      <span class="text-sm font-semibold text-slate-100">Gợi ý cùng thể loại</span>
                      <span class="text-[11px] text-slate-400">Dựa trên: <%= primaryGenre != null ? primaryGenre : "Chung" %></span>
                    </div>
                  </div>
                  <span class="text-[10px] px-2 py-0.5 rounded-full bg-slate-900/80 border border-slate-600 text-slate-300">
                    <%= relatedBooks.size() %>
                  </span>
                </div>

                <% if (relatedBooks.isEmpty()) { %>
                  <p class="text-xs text-slate-400 leading-relaxed">
                    Hiện chưa có gợi ý thêm cho thể loại này. Thử xem các sách khác trong thư viện nhé.
                  </p>
                <% } else { %>
                  <div class="flex flex-col gap-3 mt-1">
                    <% for (Map<String, Object> rb : relatedBooks) { %>
                      <a href="bookDetails.jsp?isbn=<%= rb.get("isbn") %>"
                         class="group flex gap-3 items-center px-2 py-2 rounded-xl bg-slate-900/70 border border-slate-700 hover:border-sky-400 hover:bg-slate-900/90 transition-colors">
                        <div class="w-10 h-14 rounded-md overflow-hidden border border-slate-700 bg-slate-900/80 flex-shrink-0">
                          <img src="<%= request.getContextPath() + "/" + rb.get("coverImage") %>"
                               onerror="this.onerror=null; this.src='<%= request.getContextPath() %>/images/default-cover.jpg'"
                               class="w-full h-full object-cover" />
                        </div>
                        <div class="flex-1 min-w-0">
                          <p class="text-xs font-semibold text-slate-50 line-clamp-2 group-hover:text-sky-400">
                            <%= rb.get("title") %>
                          </p>
                          <p class="text-[11px] text-slate-400 truncate mt-0.5">
                            <i class="fas fa-user-pen text-[10px] mr-1"></i><%= rb.get("author") %>
                          </p>
                        </div>
                      </a>
                    <% } %>
                  </div>
                <% } %>
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
                <%= book.get("description") != null ? book.get("description") : "Chưa có mô tả cho cuốn sách này." %>
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

    <!-- Footer -->
    <%@ include file="./layout/footer.jsp" %>

    <!-- Scripts -->
    <script>
      const CTX = '<%=request.getContextPath()%>';

      function handleBack() {
        if (document.referrer && document.referrer !== '') {
          history.back();
        } else {
          window.location.href = CTX + '/index.jsp';
        }
      }

      (function(){
        const btnBorrow   = document.getElementById('btnBorrow');
        const modal       = document.getElementById('borrow-modal');
        const btnCancel   = document.getElementById('borrow-cancel');
        const btnConfirm  = document.getElementById('borrow-confirm');
        const toast       = document.getElementById('toast');
        const toastIcon   = document.getElementById('toast-icon');
        const toastMsg    = document.getElementById('toast-message');

        const isbn = '<%= request.getParameter("isbn") %>';
        const token = localStorage.getItem('token');

        if (!btnBorrow) return; // Ebook thì không có nút mượn

        // Modal
        function openModal() {
          if (!token) {
            showToast('error', 'Bạn cần đăng nhập trước khi mượn sách.');
            setTimeout(() => {
              window.location.href = CTX + '/user/login.jsp';
            }, 1000);
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

          if (toastTimeout) clearTimeout(toastTimeout);
          toastTimeout = setTimeout(() => {
            toast.style.opacity = '0';
            setTimeout(() => {
              toast.classList.add('hidden');
            }, 300);
          }, 3000);
        }

        // Click "Đăng ký mượn"
        btnBorrow.addEventListener('click', (e) => {
          e.preventDefault();
          openModal();
        });

        // Hủy modal
        btnCancel.addEventListener('click', () => {
          closeModal();
        });

        // Click ra ngoài panel
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
              body: JSON.stringify({ isbn })
            });

            let data = {};
            try {
              data = await resp.json();
            } catch (e) {
              console.error('parse JSON error', e);
            }

            if (resp.ok) {
              showToast('success', data.message || 'Đăng ký mượn thành công!');
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
