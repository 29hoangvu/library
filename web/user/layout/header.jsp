<%@ page contentType="text/html; charset=UTF-8" language="java"
         buffer="64kb" autoFlush="true" %>
<%@ page import="java.sql.*, java.util.*, java.net.URLEncoder" %>
<%@ page import="Servlet.DBConnection" %>

<!-- HEADER: glass + gradient, 3-zone layout (logo – search – user) -->
<header class="sticky top-0 z-50 bg-slate-950/90 backdrop-blur-xl border-b border-white/10 shadow-[0_10px_35px_rgba(15,23,42,0.85)]">
  <div class="max-w-7xl mx-auto px-3 sm:px-4 lg:px-6">
    <div class="flex items-center justify-between gap-3 py-2.5 sm:py-3">

      <!-- Logo -->
      <a href="<%=request.getContextPath()%>/index.jsp"
         class="flex items-center gap-2 group rounded-full px-1.5 sm:px-2 py-1 hover:bg-white/5 transition-colors">
        <div class="w-10 h-10 sm:w-11 sm:h-11 bg-gradient-to-br from-amber-300 via-white to-blue-200 rounded-full flex items-center justify-center shadow-lg shadow-amber-500/25 group-hover:scale-110 group-hover:shadow-xl group-hover:shadow-amber-400/40 transition-transform duration-200 ease-out">
          <i class="fas fa-book-open text-indigo-700 text-lg sm:text-xl"></i>
        </div>
        <div class="flex flex-col leading-tight">
          <span class="text-xs tracking-[0.2em] text-white/70 uppercase">Smart</span>
          <h1 class="text-xl sm:text-2xl font-extrabold tracking-tight text-white group-hover:text-amber-300 transition-colors duration-200">
            LIBRARY
          </h1>
        </div>
      </a>

      <!-- SEARCH (desktop/tablet) – giữ nguyên include, chỉ bọc layout -->
      <div class="hidden md:flex flex-1 justify-center px-1 lg:px-8">
        <!-- Outer ring + glass pill -->
        <div class="w-full max-w-3xl">
          <div class="relative rounded-full bg-gradient-to-r from-slate-100/10 via-slate-100/5 to-slate-100/10 p-[2px] shadow-[0_14px_45px_rgba(15,23,42,0.85)]">
            <div class="rounded-full bg-slate-900/90 border border-white/10 px-4 py-1.5 backdrop-blur-xl flex items-center">
              <% String endpoint = request.getContextPath() + "/api/search.jsp"; %>
              <jsp:include page="/components/searchUI.jsp">
                <jsp:param name="endpoint" value="<%= endpoint %>"/>
              </jsp:include>
            </div>
          </div>
        </div>
      </div>

      <!-- User + Filter -->
      <div class="flex items-center gap-2 sm:gap-3">

        <!-- Nút mở Modal Filter -->
        <button id="filterOpenBtn"
                class="relative inline-flex h-10 w-10 items-center justify-center rounded-full border border-white/15 bg-white/5 text-white/80 shadow-lg shadow-slate-900/50 hover:bg-white/10 hover:text-amber-300 hover:border-amber-300/60 focus:outline-none focus:ring-2 focus:ring-amber-300/70 focus:ring-offset-2 focus:ring-offset-slate-900 transition-all"
                title="Bộ lọc">
          <span class="absolute -top-1 -right-1 inline-flex items-center justify-center rounded-full bg-amber-400 text-[10px] font-semibold text-slate-900 px-1.5 py-[1px] shadow-md shadow-amber-500/50">
            Lọc
          </span>
          <i class="fas fa-sliders-h text-sm"></i>
        </button>

        <!-- Nút login (ẩn khi đã đăng nhập) -->
        <a id="loginBtn"
           href="<%=request.getContextPath()%>/user/login.jsp"
           class="hidden md:inline-flex items-center gap-2 rounded-full bg-white/10 px-4 py-2 text-sm font-semibold text-white shadow-lg shadow-slate-900/50 hover:bg-white/20 hover:text-amber-200 border border-white/20 focus:outline-none focus:ring-2 focus:ring-amber-300/70 focus:ring-offset-2 focus:ring-offset-slate-900 transition-all">
          <i class="fas fa-sign-in-alt text-xs"></i>
          <span>Đăng nhập</span>
        </a>

        <!-- User menu (ẩn mặc định, hiện khi có token) -->
        <div id="userMenu" class="hidden relative">
          <button type="button"
                  class="relative rounded-full ring-2 ring-emerald-300/60 ring-offset-2 ring-offset-slate-900 shadow-lg shadow-slate-900/70 hover:ring-emerald-200/90 hover:scale-[1.02] transition-all duration-200">
            <img id="userAvatar"
                 src="<%=request.getContextPath()%>/images/default-avatar.png"
                 class="w-10 h-10 sm:w-11 sm:h-11 rounded-full object-cover cursor-pointer"
                 alt="Avatar"
                 onclick="toggleUserDropdown()">
          </button>

          <!-- Dropdown -->
          <div id="userDropdown"
               class="absolute right-0 mt-3 w-72 origin-top-right bg-slate-900/95 backdrop-blur-xl rounded-2xl shadow-2xl shadow-slate-900/80 border border-white/10 py-2 hidden">
            <div class="px-4 py-3 border-b border-white/10 bg-gradient-to-r from-slate-900/80 via-slate-900/60 to-slate-900/80 rounded-t-2xl">
              <div class="flex items-center gap-3">
                <div class="relative">
                  <img id="dropdownAvatar"
                       src="<%=request.getContextPath()%>/images/default-avatar.png"
                       class="w-12 h-12 rounded-full object-cover border border-emerald-400/60 shadow-md shadow-emerald-500/40"
                       alt="Avatar">
                  <span class="absolute -bottom-1 -right-1 inline-flex h-5 w-5 items-center justify-center rounded-full bg-emerald-400 text-[10px] text-slate-900 font-semibold shadow-md shadow-emerald-500/50">
                    <i class="fas fa-check"></i>
                  </span>
                </div>
                <div class="space-y-0.5">
                  <p id="dropdownUsername" class="font-semibold text-white text-sm line-clamp-1">User</p>
                  <p id="dropdownRole" class="text-xs text-emerald-300/90 font-medium">Thành viên</p>
                </div>
              </div>
            </div>
            <a href="<%=request.getContextPath()%>/user/profile.jsp"
               class="block px-4 py-2.5 text-sm text-slate-100 hover:bg-white/5 flex items-center gap-2 transition-colors">
              <span class="inline-flex h-7 w-7 items-center justify-center rounded-full bg-white/5 text-emerald-300">
                <i class="fas fa-user text-xs"></i>
              </span>
              <span>Thông tin cá nhân</span>
            </a>
            <a href="<%=request.getContextPath()%>/user/borrowedBooks.jsp"
               class="block px-4 py-2.5 text-sm text-slate-100 hover:bg-white/5 flex items-center gap-2 transition-colors">
              <span class="inline-flex h-7 w-7 items-center justify-center rounded-full bg-white/5 text-indigo-300">
                <i class="fas fa-book-reader text-xs"></i>
              </span>
              <span>Sách đã mượn</span>
            </a>
            <a href="<%=request.getContextPath()%>/user/myReservations.jsp"
               class="block px-4 py-2.5 text-sm text-slate-100 hover:bg-white/5 flex items-center gap-2 transition-colors">
              <span class="inline-flex h-7 w-7 items-center justify-center rounded-full bg-white/5 text-indigo-300">
                <i class="fas fa-book-reader text-xs"></i>
              </span>
              <span>Sách đã đăng ký</span>
            </a>
            <a href="#"
               onclick="logout()"
               class="block px-4 py-2.5 text-sm text-rose-300 hover:bg-rose-500/10 flex items-center gap-2 transition-colors rounded-b-2xl">
              <span class="inline-flex h-7 w-7 items-center justify-center rounded-full bg-rose-500/15 text-rose-300">
                <i class="fas fa-sign-out-alt text-xs"></i>
              </span>
              <span>Đăng xuất</span>
            </a>
          </div>
        </div>

        <!-- Mobile login button (chỉ icon) -->
        <a id="loginBtnMobile"
           href="<%=request.getContextPath()%>/user/login.jsp"
           class="md:hidden hidden h-9 w-9 items-center justify-center rounded-full bg-white/10 text-white/90 border border-white/20 shadow-md shadow-slate-900/60 hover:bg-white/20 hover:text-amber-200 transition-all">
          <i class="fas fa-sign-in-alt text-xs"></i>
        </a>

        <!-- Mobile search toggle -->
        <button id="mobileMenuBtn"
                class="md:hidden inline-flex h-9 w-9 items-center justify-center rounded-full bg-white/5 border border-white/15 text-white/80 hover:bg-white/15 hover:text-amber-200 shadow-md shadow-slate-900/60 transition-all">
          <i class="fas fa-search text-sm"></i>
        </button>
      </div>
    </div>

    <!-- Mobile Search -->
    <div id="mobileSearch" class="md:hidden mt-2 mb-2 hidden">
      <form action="<%=request.getContextPath()%>/index.jsp" method="get">
        <div class="relative">
          <input type="text" name="search"
                 placeholder="Tìm sách theo tên hoặc tác giả..."
                 class="w-full rounded-full border border-white/20 bg-slate-900/80 px-4 py-2.5 pr-11 text-sm text-white placeholder-white/60 shadow-inner shadow-slate-900/40 focus:outline-none focus:ring-2 focus:ring-amber-300/70 focus:border-transparent focus:bg-slate-900/90 transition">
          <button type="submit"
                  class="absolute right-2 top-1/2 -translate-y-1/2 inline-flex h-8 w-8 items-center justify-center rounded-full bg-amber-400 text-slate-900 shadow-md shadow-amber-500/60 hover:bg-amber-300 transition-colors">
            <i class="fas fa-search text-sm"></i>
          </button>
        </div>
      </form>
    </div>
  </div>
</header>

<script src="<%=request.getContextPath()%>/static/js/api.js"></script>
<script>
  // Khởi tạo UI user theo token + localStorage
  (async () => {
    try {
      const loginBtn        = document.getElementById("loginBtn");
      const loginBtnMobile  = document.getElementById("loginBtnMobile");
      const userMenu        = document.getElementById("userMenu");
      const userAvatar      = document.getElementById("userAvatar");
      const dropdownAvatar  = document.getElementById("dropdownAvatar");
      const dropdownUsername= document.getElementById("dropdownUsername");
      const dropdownRole    = document.getElementById("dropdownRole");

      let me = null;

      // 1) Ưu tiên đọc user từ localStorage (nếu login đã lưu)
      const stored = localStorage.getItem("user");
      if (stored) {
        try {
          me = JSON.parse(stored);
          console.debug("[header] dùng user từ localStorage:", me);
        } catch (e) {
          console.warn("[header] parse localStorage.user lỗi:", e);
        }
      }

      // 2) Nếu chưa có mà vẫn còn token -> gọi /auth/me
      if (!me && window.api && typeof api.currentUser === "function") {
        const token = api.getToken && api.getToken();
        if (token) {
          try {
            me = await api.currentUser();
            console.debug("[header] dùng user từ api.currentUser():", me);
            if (me) {
              localStorage.setItem("user", JSON.stringify(me));
            }
          } catch (e) {
            console.warn("[header] api.currentUser() lỗi:", e);
          }
        }
      }

      if (me) {
        // ==== ĐÃ ĐĂNG NHẬP ====
        if (loginBtn) {
          // Ẩn cả base + md
          loginBtn.classList.add("hidden", "md:hidden");
          loginBtn.classList.remove("md:inline-flex");
        }
        if (loginBtnMobile) {
          loginBtnMobile.classList.add("hidden");
        }
        userMenu && userMenu.classList.remove("hidden");

        const uid = me.uid ?? me.id;
        const avatarUrl = "<%=request.getContextPath()%>/AvatarServlet?userId=" + encodeURIComponent(uid);

        if (userAvatar)       userAvatar.src       = avatarUrl;
        if (dropdownAvatar)   dropdownAvatar.src   = avatarUrl;
        if (dropdownUsername) dropdownUsername.textContent = me.username ?? "User";
        if (dropdownRole)     dropdownRole.textContent     = me.role ?? (me.roleName ?? "Thành viên");

      } else {
        // ==== CHƯA ĐĂNG NHẬP ====
        if (loginBtn) {
          loginBtn.classList.remove("hidden", "md:hidden");
          loginBtn.classList.add("md:inline-flex");
        }
        if (loginBtnMobile) {
          loginBtnMobile.classList.remove("hidden");
        }
        userMenu && userMenu.classList.add("hidden");
      }
    } catch (err) {
      console.error("[header] init user UI error:", err);
      document.getElementById("loginBtn")?.classList.remove("hidden", "md:hidden");
      document.getElementById("loginBtnMobile")?.classList.remove("hidden");
      document.getElementById("userMenu")?.classList.add("hidden");
    }
  })();

  function toggleUserDropdown(){
    const dd = document.getElementById("userDropdown");
    dd?.classList.toggle("hidden");
  }

  // Đăng xuất (xoá token)
  function logout(){
    api.clearToken && api.clearToken();
    localStorage.removeItem("user");

    document.getElementById("userMenu")?.classList.add("hidden");

    const loginBtn       = document.getElementById("loginBtn");
    const loginBtnMobile = document.getElementById("loginBtnMobile");

    if (loginBtn) {
      loginBtn.classList.remove("hidden", "md:hidden");
      loginBtn.classList.add("md:inline-flex");
    }
    if (loginBtnMobile) {
      loginBtnMobile.classList.remove("hidden");
    }

    location.href = "<%=request.getContextPath()%>/index.jsp";
  }

  // Đóng dropdown khi click ngoài
  document.addEventListener('click', (e) => {
    const dropdown = document.getElementById('userDropdown');
    const hitAvatar = e.target.closest('#userAvatar');
    if (!hitAvatar && dropdown && !dropdown.contains(e.target)) {
      dropdown.classList.add('hidden');
    }
  });
</script>


<%
  // ===== Lấy danh sách thể loại cho Tab "Thể loại" =====
  List<Map<String,String>> genres = new ArrayList<>();
  try (Connection conn = DBConnection.getConnection();
       Statement st = conn.createStatement();
       ResultSet rs = st.executeQuery("SELECT id, name FROM genre ORDER BY name")) {
    while (rs.next()) {
      Map<String,String> g = new HashMap<>();
      g.put("id", rs.getString("id"));
      g.put("name", rs.getString("name"));
      genres.add(g);
    }
  } catch (Exception e) {
    e.printStackTrace();
  }
%>

<!-- ============ Modal Filter (Portal) ============ -->
<div id="filterModal"
     class="fixed inset-0 z-[9999] hidden opacity-0 pointer-events-none transition-opacity duration-200 ease-out">
  <!-- Overlay: tối, hơi blur, không bị trắng -->
  <div id="filterOverlay"
       class="absolute inset-0 bg-slate-950/90 backdrop-blur-[2px] opacity-0 transition-opacity duration-200 ease-out"></div>

  <!-- Dialog (căn giữa tuyệt đối) -->
  <div id="filterDialog"
       class="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2
              w-[min(92vw,1120px)] max-h-[85vh] overflow-auto
              rounded-3xl shadow-[0_24px_80px_rgba(15,23,42,0.95)]
              bg-gradient-to-br from-slate-900/98 via-slate-950 to-slate-900/98
              border border-white/10
              scale-95 opacity-0 transition-all duration-200 ease-out">
    <!-- Header modal -->
    <div class="flex items-center justify-between gap-3 px-5 py-4 border-b border-white/10 sticky top-0 bg-slate-950/95 backdrop-blur-xl rounded-t-3xl">
      <div class="flex items-center gap-2">
        <div class="h-9 w-9 flex items-center justify-center rounded-2xl bg-amber-400/15 border border-amber-300/60 text-amber-300 shadow-md shadow-amber-500/40">
          <i class="fas fa-sliders-h text-sm"></i>
        </div>
        <div>
          <h3 class="text-white text-lg sm:text-xl font-semibold">
            Bộ lọc sách
          </h3>
          <p class="text-xs text-white/60 hidden sm:block">Chọn nhanh thể loại, năm xuất bản hoặc số trang phù hợp.</p>
        </div>
      </div>
      <button id="filterCloseBtn"
              class="w-9 h-9 rounded-full border border-white/10 bg-white/5 hover:bg-white/15 text-white flex items-center justify-center shadow-md shadow-slate-900/60 focus:outline-none focus:ring-2 focus:ring-amber-300/70 focus:ring-offset-2 focus:ring-offset-slate-900 transition-all"
              aria-label="Đóng bộ lọc">
        <i class="fas fa-times text-sm"></i>
      </button>
    </div>

    <!-- Nội dung -->
    <div class="px-5 py-4">
      <!-- Tabs header -->
      <div class="flex flex-wrap gap-2 mb-4">
        <button class="tab-btn active px-4 py-2 rounded-xl text-sm sm:text-base text-white font-semibold bg-indigo-600 shadow-md shadow-indigo-500/40 hover:bg-indigo-500 transition-all flex items-center gap-2"
                data-tab="tab-genres">
          <i class="fas fa-tags text-xs"></i><span>Thể loại</span>
        </button>
        <button class="tab-btn px-4 py-2 rounded-xl text-sm sm:text-base text-white font-semibold bg-emerald-600 shadow-md shadow-emerald-500/40 hover:bg-emerald-500 transition-all flex items-center gap-2"
                data-tab="tab-years">
          <i class="fas fa-calendar-alt text-xs"></i><span>Năm xuất bản</span>
        </button>
        <button class="tab-btn px-4 py-2 rounded-xl text-sm sm:text-base text-white font-semibold bg-purple-600 shadow-md shadow-purple-500/40 hover:bg-purple-500 transition-all flex items-center gap-2"
                data-tab="tab-pages">
          <i class="fas fa-file-alt text-xs"></i><span>Số trang</span>
        </button>
      </div>

      <div class="mt-2 space-y-6 text-sm">

        <!-- Tab: Thể loại -->
        <div id="tab-genres" class="tab-panel">
          <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 xl:grid-cols-8 gap-2.5">
            <a href="<%=request.getContextPath()%>/index.jsp"
               class="block text-center bg-indigo-600 hover:bg-indigo-500 text-white px-3 py-2 rounded-xl font-medium shadow-md shadow-indigo-500/40 transition">
              Tất cả
            </a>
            <% for (Map<String,String> g : genres) { %>
              <a href="<%=request.getContextPath()%>/filterBooks?genreId=<%=g.get("id")%>&genreName=<%=URLEncoder.encode(g.get("name"),"UTF-8")%>"
                 class="block text-center bg-white/5 hover:bg-white/10 text-white/90 px-3 py-2 rounded-xl font-medium text-xs sm:text-sm border border-white/10 shadow-sm shadow-slate-900/60 transition">
                <%= g.get("name") %>
              </a>
            <% } %>
          </div>
        </div>

        <!-- Tab: Năm xuất bản -->
        <div id="tab-years" class="tab-panel hidden">
          <div class="flex flex-wrap gap-2.5">
            <a class="inline-block bg-white/5 hover:bg-white/10 text-white px-3 py-2 rounded-xl font-medium border border-white/10 shadow-sm shadow-slate-900/60 transition"
               href="filterBooks?yearTo=1989">Trước 1990</a>
            <a class="inline-block bg-white/5 hover:bg-white/10 text-white px-3 py-2 rounded-xl font-medium border border-white/10 shadow-sm shadow-slate-900/60 transition"
               href="filterBooks?yearFrom=1990&yearTo=1999">1990–1999</a>
            <a class="inline-block bg-white/5 hover:bg-white/10 text-white px-3 py-2 rounded-xl font-medium border border-white/10 shadow-sm shadow-slate-900/60 transition"
               href="filterBooks?yearFrom=2000&yearTo=2009">2000–2009</a>
            <a class="inline-block bg-white/5 hover:bg-white/10 text-white px-3 py-2 rounded-xl font-medium border border-white/10 shadow-sm shadow-slate-900/60 transition"
               href="filterBooks?yearFrom=2010&yearTo=2019">2010–2019</a>
            <a class="inline-block bg-white/5 hover:bg-white/10 text-white px-3 py-2 rounded-xl font-medium border border-white/10 shadow-sm shadow-slate-900/60 transition"
               href="filterBooks?yearFrom=2020&yearTo=2022">2020–2022</a>
            <a class="inline-block bg-white/5 hover:bg-white/10 text-white px-3 py-2 rounded-xl font-medium border border-white/10 shadow-sm shadow-slate-900/60 transition"
               href="filterBooks?yearFrom=2023">2023–nay</a>
            <a class="inline-block bg-rose-500/15 hover:bg-rose-500/25 text-rose-200 px-3 py-2 rounded-xl font-medium border border-rose-400/40 shadow-sm shadow-rose-500/40 transition"
               href="index.jsp">Xóa lọc</a>
          </div>
        </div>

        <!-- Tab: Số trang -->
        <div id="tab-pages" class="tab-panel hidden">
          <div class="flex flex-wrap gap-2.5">
            <a class="inline-block bg-white/5 hover:bg-white/10 text-white px-3 py-2 rounded-xl font-medium border border-white/10 shadow-sm shadow-slate-900/60 transition"
               href="filterBooks?pagesMin=500">≥ 500 trang</a>
            <a class="inline-block bg-white/5 hover:bg-white/10 text-white px-3 py-2 rounded-xl font-medium border border-white/10 shadow-sm shadow-slate-900/60 transition"
               href="filterBooks?pagesMin=400">≥ 400 trang</a>
            <a class="inline-block bg-white/5 hover:bg-white/10 text-white px-3 py-2 rounded-xl font-medium border border-white/10 shadow-sm shadow-slate-900/60 transition"
               href="filterBooks?pagesMin=300">≥ 300 trang</a>
            <a class="inline-block bg-white/5 hover:bg-white/10 text-white px-3 py-2 rounded-xl font-medium border border-white/10 shadow-sm shadow-slate-900/60 transition"
               href="filterBooks?pagesMin=200">≥ 200 trang</a>
            <a class="inline-block bg-white/5 hover:bg-white/10 text-white px-3 py-2 rounded-xl font-medium border border-white/10 shadow-sm shadow-slate-900/60 transition"
               href="filterBooks?pagesMin=100">≥ 100 trang</a>
            <a class="inline-block bg-rose-500/15 hover:bg-rose-500/25 text-rose-200 px-3 py-2 rounded-xl font-medium border border-rose-400/40 shadow-sm shadow-rose-500/40 transition"
               href="index.jsp">Xóa lọc</a>
          </div>
        </div>

      </div>
    </div>
  </div>
</div>

<style>
  .tab-btn.active {
    box-shadow: 0 10px 30px rgba(15, 23, 42, 0.6);
    transform: translateY(-1px);
  }

  /* Đảm bảo modal luôn ở top nhất */
  #filterModal { position: fixed; inset: 0; z-index: 2147483647; }

  /* Overlay & Dialog đã fixed trong code của bạn, giữ nguyên vị trí */
  #filterOverlay { position: absolute; inset: 0; }
  #filterDialog  { position: fixed; left: 50%; top: 50%; transform: translate(-50%, -50%); }
</style>

<script>
  // Mobile search toggle
  document.getElementById('mobileMenuBtn')?.addEventListener('click', () => {
    document.getElementById('mobileSearch')?.classList.toggle('hidden');
  });

  (function(){
    const openBtn   = document.getElementById('filterOpenBtn');
    const modal     = document.getElementById('filterModal');
    const overlay   = document.getElementById('filterOverlay');
    const dialog    = document.getElementById('filterDialog');
    const closeBtn  = document.getElementById('filterCloseBtn');

    let scrollPosition = 0;

    function lockScroll(lock) {
      if (lock) {
        scrollPosition = window.pageYOffset;
        document.body.style.position = 'fixed';
        document.body.style.top = `-${scrollPosition}px`;
        document.body.style.width = '100%';
        document.body.style.overflow = 'hidden';
      } else {
        document.body.style.position = '';
        document.body.style.top = '';
        document.body.style.width = '';
        document.body.style.overflow = '';
        window.scrollTo(0, scrollPosition);
      }
    }

    function openModal() {
      // Reset modal position
      modal.scrollTop = 0;
      dialog.scrollTop = 0;

      modal.classList.remove('hidden');
      modal.classList.remove('pointer-events-none');

      requestAnimationFrame(() => {
        modal.classList.remove('opacity-0');
        overlay.classList.remove('opacity-0');
        dialog.classList.remove('opacity-0','scale-95');
      });

      lockScroll(true);
    }

    function closeModal() {
      modal.classList.add('opacity-0');
      overlay.classList.add('opacity-0');
      dialog.classList.add('opacity-0','scale-95');

      setTimeout(() => {
        modal.classList.add('hidden');
        modal.classList.add('pointer-events-none');
        lockScroll(false);
      }, 200);
    }

    openBtn?.addEventListener('click', openModal);
    closeBtn?.addEventListener('click', closeModal);
    overlay?.addEventListener('click', closeModal);
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && !modal.classList.contains('hidden')) closeModal();
    });

    // Tabs
    const root   = document.getElementById('filterDialog');
    const btns   = root.querySelectorAll('.tab-btn');
    const panels = root.querySelectorAll('.tab-panel');

    function setActive(id){
      panels.forEach(p => p.classList.add('hidden'));
      btns.forEach(b => b.classList.remove('active'));
      root.querySelector('#'+id)?.classList.remove('hidden');
      root.querySelector(`.tab-btn[data-tab="${id}"]`)?.classList.add('active');
    }
    btns.forEach(b => b.addEventListener('click', () => setActive(b.dataset.tab)));
    setActive('tab-genres');
  })();
</script>

<script>
  // === Biến Filter Modal thành portal gắn thẳng vào <body> ===
  document.addEventListener('DOMContentLoaded', () => {
    const modal = document.getElementById('filterModal');
    if (modal && modal.parentNode !== document.body) {
      document.body.appendChild(modal);
    }
  });
</script>
