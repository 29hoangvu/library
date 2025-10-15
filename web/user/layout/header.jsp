<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="Data.Users, java.sql.*, java.util.*, Servlet.DBConnection" %>
<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.net.URLEncoder" %>

<header class="bg-gradient-to-r from-indigo-600 via-purple-600 to-pink-600 shadow-lg sticky top-0 z-50 backdrop-blur-sm bg-opacity-95">
    <!-- Header chính -->
    <div class="container mx-auto px-4 py-3">
        <div class="flex items-center justify-between">
            
            <!-- Logo và Title -->
            <div class="flex items-center space-x-4">
                <a href="${pageContext.request.contextPath}/index.jsp" class="flex items-center space-x-2 group">
                    <div class="w-10 h-10 bg-white rounded-full flex items-center justify-center shadow-lg group-hover:scale-110 transition-transform duration-300">
                        <i class="fas fa-book text-indigo-600 text-xl"></i>
                    </div>
                    <h1 class="text-2xl font-bold text-white tracking-wide hover:text-yellow-300 transition-colors duration-300">
                        LIBRARY
                    </h1>
                </a>
            </div>

            <!-- NHÚNG UI TÌM KIẾM -->
            <% String endpoint = request.getContextPath() + "/api/search.jsp"; %>
            <jsp:include page="/components/searchUI.jsp">
              <jsp:param name="endpoint" value="<%= endpoint %>"/>
            </jsp:include>
            
            <!-- User Menu và Filter Button -->
            <div class="flex items-center space-x-4">
                <!-- Filter toggle button -->
                <button id="filterBarToggle" 
                        class="text-white hover:text-yellow-300 transition-colors">
                  <i class="fas fa-sliders-h"></i>
                </button>
                <!-- User Menu -->
                <div class="relative">
                    <%
                        Users user = (Users) session.getAttribute("user");
                        if (user != null) {
                            String avatarUrl = "AvatarServlet?userId=" + user.getId();
                            String defaultAvatar = "./images/default-avatar.png";
                    %>
                    <div class="relative">
                        <img src="<%= avatarUrl%>" 
                             onerror="this.onerror=null; this.src='<%= defaultAvatar%>';" 
                             alt="Avatar" 
                             class="w-10 h-10 rounded-full border-2 border-white/30 hover:border-white cursor-pointer transition-all duration-300 shadow-lg"
                             onclick="toggleUserDropdown()">
                        
                        <!-- User Dropdown -->
                        <div id="userDropdown" class="absolute right-0 mt-2 w-64 bg-white rounded-lg shadow-xl py-2 hidden transform opacity-0 scale-95 transition-all duration-200 origin-top-right">
                            <div class="px-4 py-3 border-b border-gray-200">
                                <div class="flex items-center space-x-3">
                                    <img src="<%= avatarUrl%>" 
                                         onerror="this.onerror=null; this.src='<%= defaultAvatar%>';" 
                                         alt="Avatar" 
                                         class="w-12 h-12 rounded-full object-cover">
                                    <div>
                                        <p class="font-semibold text-gray-800"><%= user.getUsername()%></p>
                                        <p class="text-sm text-gray-500">Thành viên</p>
                                    </div>
                                </div>
                            </div>
                            <a href="${pageContext.request.contextPath}/user/profile.jsp" class="block px-4 py-2 text-gray-700 hover:bg-gray-100 transition-colors">
                                <i class="fas fa-user mr-2"></i>Xem thông tin
                            </a>
                            <a href="${pageContext.request.contextPath}/user/borrowedBooks.jsp" class="block px-4 py-2 text-gray-700 hover:bg-gray-100 transition-colors">
                                <i class="fas fa-book-reader mr-2"></i>Sách đã mượn
                            </a>
                            <a href="${pageContext.request.contextPath}/LogOutServlet" class="block px-4 py-2 text-gray-700 hover:bg-gray-100 transition-colors">
                                <i class="fas fa-sign-out-alt mr-2"></i>Đăng xuất
                            </a>
                        </div>
                    </div>
                    <%
                    } else {
                    %>
                    <a href="${pageContext.request.contextPath}/user/login.jsp" class="bg-white/20 hover:bg-white/30 text-white px-4 py-2 rounded-full transition-all duration-300 flex items-center space-x-2">
                        <i class="fas fa-sign-in-alt"></i>
                        <span class="hidden sm:inline">Đăng nhập</span>
                    </a>
                    <%
                        }
                    %>
                </div>               
                <!-- Mobile menu button -->
                <button id="mobileMenuBtn" class="md:hidden text-white hover:text-yellow-300 transition-colors">
                    <i class="fas fa-bars text-xl"></i>
                </button>
            </div>
        </div>

        <!-- Mobile Search -->
        <div id="mobileSearch" class="md:hidden mt-4 hidden">
            <form action="index.jsp" method="get">
                <div class="relative">
                    <input type="text" 
                           name="search" 
                           placeholder="Tìm sách theo tên hoặc tác giả..." 
                           value="<%= request.getParameter("search") != null ? request.getParameter("search") : ""%>"
                           class="w-full px-4 py-2 pr-12 rounded-full border-2 border-white/20 bg-white/10 text-white placeholder-white/70 focus:outline-none focus:border-white focus:bg-white/20 transition-all duration-300">
                    <button type="submit" class="absolute right-2 top-1/2 transform -translate-y-1/2 text-white hover:text-yellow-300 transition-colors">
                        <i class="fas fa-search"></i>
                    </button>
                </div>
            </form>
        </div>
    </div>
     
    <%
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
                       
<style>
  .tab-btn.active { box-shadow: 0 4px 14px rgba(0,0,0,.12); }
  #filterModal.open #filterOverlay { opacity: 1; }
    #filterModal.open #filterDialog  { opacity: 1; transform: translateY(0); }
    /* Trạng thái mặc định modal dialog */
#filterDialog {
  transform: scale(0.9);
  opacity: 0;
  transition: transform 0.25s ease, opacity 0.25s ease;
}

/* Khi modal mở */
#filterModal.open #filterDialog {
  transform: scale(1);
  opacity: 1;
}

</style>
</header>              
<!-- Modal: Filter -->
<div id="filterModal" class="fixed inset-0 z-[80] hidden">  <!-- z cao hơn -->
  <!-- Overlay -->
  <div id="filterOverlay" class="absolute inset-0 bg-black/50 opacity-0 transition-opacity"></div>

  <!-- Dialog container -->
  <div class="absolute inset-0 flex items-start justify-center pt-6 md:pt-12 p-4 md:p-6 overflow-y-auto">
    <div id="filterDialog"
         class="w-11/12 md:w-11/12 lg:w-5/6 xl:w-5/6 max-w-7xl
                bg-white/25 backdrop-blur-md shadow-2xl rounded-2xl
                translate-y-4 opacity-0 transition-all duration-200">
      
      <!-- Header modal -->
      <div class="flex items-center justify-between px-5 py-4 border-b border-white/20">
        <h3 class="text-white text-xl font-semibold flex items-center gap-2">
          <i class="fas fa-sliders-h"></i> Bộ lọc sách
        </h3>
        <button id="filterCloseBtn"
                class="w-9 h-9 rounded-full hover:bg-white/20 text-white flex items-center justify-center"
                aria-label="Đóng bộ lọc">
          <i class="fas fa-times text-lg"></i>
        </button>
      </div>

      <!-- Nội dung (giữ nguyên tabs + content của bạn) -->
      <div class="px-5 py-4">
        <!-- Tabs header -->
        <div class="flex gap-2 md:gap-3">
          <button class="tab-btn active px-4 py-2 rounded-lg text-white font-semibold bg-indigo-600 hover:bg-indigo-700"
                  data-tab="tab-genres">
            <i class="fas fa-tags mr-2"></i>Thể loại
          </button>
          <button class="tab-btn px-4 py-2 rounded-lg text-white font-semibold bg-green-600 hover:bg-green-700"
                  data-tab="tab-years">
            <i class="fas fa-calendar-alt mr-2"></i>Năm xuất bản
          </button>
          <button class="tab-btn px-4 py-2 rounded-lg text-white font-semibold bg-purple-600 hover:bg-purple-700"
                  data-tab="tab-pages">
            <i class="fas fa-file-alt mr-2"></i>Số trang
          </button>
        </div>

        <!-- Tabs content -->
        <div class="mt-4 space-y-6">

          <!-- Thể loại -->
          <div id="tab-genres" class="tab-panel">
            <div class="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-6 lg:grid-cols-8 xl:grid-cols-10 gap-3">
              <a href="<%=request.getContextPath()%>/index.jsp"
                 class="block text-center bg-indigo-600 hover:bg-indigo-700 text-white px-3 py-2 rounded-lg font-medium">
                Tất cả
              </a>
              <% for (Map<String,String> g : genres) { %>
                <a href="<%=request.getContextPath()%>/filterBooks?genreId=<%=g.get("id")%>&genreName=<%=URLEncoder.encode(g.get("name"),"UTF-8")%>"
                   class="block text-center bg-white/20 hover:bg-white/30 text-white 
                        px-3 py-2 rounded-md font-medium text-sm">
                  <%= g.get("name") %>
                </a>
              <% } %>
            </div>
          </div>

          <!-- Năm xuất bản -->
          <div id="tab-years" class="tab-panel hidden">
            <div class="flex flex-wrap gap-2">
              <a class="inline-block bg-white/20 hover:bg-white/30 text-white px-3 py-2 rounded-lg font-medium" href="filterBooks?yearTo=1989">Trước 1990</a>
              <a class="inline-block bg-white/20 hover:bg-white/30 text-white px-3 py-2 rounded-lg font-medium" href="filterBooks?yearFrom=1990&yearTo=1999">1990–1999</a>
              <a class="inline-block bg-white/20 hover:bg-white/30 text-white px-3 py-2 rounded-lg font-medium" href="filterBooks?yearFrom=2000&yearTo=2009">2000–2009</a>
              <a class="inline-block bg-white/20 hover:bg-white/30 text-white px-3 py-2 rounded-lg font-medium" href="filterBooks?yearFrom=2010&yearTo=2019">2010–2019</a>
              <a class="inline-block bg-white/20 hover:bg-white/30 text-white px-3 py-2 rounded-lg font-medium" href="filterBooks?yearFrom=2020&yearTo=2022">2020–2022</a>
              <a class="inline-block bg-white/20 hover:bg-white/30 text-white px-3 py-2 rounded-lg font-medium" href="filterBooks?yearFrom=2023">2023–nay</a>
              <a class="inline-block bg-white/20 hover:bg-white/30 text-white px-3 py-2 rounded-lg font-medium" href="index.jsp">Xóa lọc</a>
            </div>

            <form action="index.jsp" method="get" class="mt-3 flex gap-2 items-center flex-wrap">
              <input type="number" name="yearFrom" placeholder="Từ năm" class="w-28 border px-3 py-2 rounded">
              <span class="text-white/90">—</span>
              <input type="number" name="yearTo" placeholder="Đến năm" class="w-28 border px-3 py-2 rounded">
              <button type="submit" class="px-4 py-2 rounded-lg text-white font-semibold bg-green-600 hover:bg-green-700">
                Lọc
              </button>
            </form>
          </div>

          <!-- Số trang -->
          <div id="tab-pages" class="tab-panel hidden">
            <div class="flex flex-wrap gap-2">
              <a class="inline-block bg-white/20 hover:bg-white/30 text-white px-3 py-2 rounded-lg font-medium" href="filterBooks?pagesMin=500">≥ 500 trang</a>
              <a class="inline-block bg-white/20 hover:bg-white/30 text-white px-3 py-2 rounded-lg font-medium" href="filterBooks?pagesMin=400">≥ 400 trang</a>
              <a class="inline-block bg-white/20 hover:bg-white/30 text-white px-3 py-2 rounded-lg font-medium" href="filterBooks?pagesMin=300">≥ 300 trang</a>
              <a class="inline-block bg-white/20 hover:bg-white/30 text-white px-3 py-2 rounded-lg font-medium" href="filterBooks?pagesMin=200">≥ 200 trang</a>
              <a class="inline-block bg-white/20 hover:bg-white/30 text-white px-3 py-2 rounded-lg font-medium" href="filterBooks?pagesMin=100">≥ 100 trang</a>
              <a class="inline-block bg-white/20 hover:bg-white/30 text-white px-3 py-2 rounded-lg font-medium" href="index.jsp">Xóa lọc</a>
            </div>

            <form action="index.jsp" method="get" class="mt-3 flex gap-2 items-center flex-wrap">
              <input type="number" name="pagesFrom" placeholder="Từ trang" class="w-28 border px-3 py-2 rounded">
              <span class="text-white/90">—</span>
              <input type="number" name="pagesTo" placeholder="Đến trang" class="w-28 border px-3 py-2 rounded">
              <button type="submit" class="px-4 py-2 rounded-lg text-white font-semibold bg-purple-600 hover:bg-purple-700">
                Lọc
              </button>
            </form>
          </div>

        </div>
      </div>
    </div>
  </div>
</div>
<!-- JavaScript for interactions -->
<script>
    (function(){
        const btn = document.getElementById('filterBarToggle');
        const bar = document.getElementById('mainFilterBar');
        if (btn && bar) {
          btn.addEventListener('click', () => {
            bar.classList.toggle('hidden');
          });
        }
      })();

    // Toggle mobile menu
    document.getElementById('mobileMenuBtn').addEventListener('click', function() {
        const mobileSearch = document.getElementById('mobileSearch');
        mobileSearch.classList.toggle('hidden');
    });

    // Toggle user dropdown
    function toggleUserDropdown() {
        const dropdown = document.getElementById('userDropdown');
        if (dropdown.classList.contains('hidden')) {
            dropdown.classList.remove('hidden');
            setTimeout(() => {
                dropdown.classList.remove('opacity-0', 'scale-95');
                dropdown.classList.add('opacity-100', 'scale-100');
            }, 10);
        } else {
            dropdown.classList.remove('opacity-100', 'scale-100');
            dropdown.classList.add('opacity-0', 'scale-95');
            setTimeout(() => {
                dropdown.classList.add('hidden');
            }, 200);
        }
    }

    // Close dropdown when clicking outside
    document.addEventListener('click', function(event) {
        const userDropdown = document.getElementById('userDropdown');
        const avatar = event.target.closest('img[onclick="toggleUserDropdown()"]');
        
        if (!avatar && !userDropdown.contains(event.target)) {
            userDropdown.classList.remove('opacity-100', 'scale-100');
            userDropdown.classList.add('opacity-0', 'scale-95');
            setTimeout(() => {
                userDropdown.classList.add('hidden');
            }, 200);
        }
    });

    // Filter functionality
    document.querySelectorAll('.filter-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            // Remove active class from all buttons
            document.querySelectorAll('.filter-btn').forEach(b => {
                b.classList.remove('active', 'bg-white/20', 'text-white');
                b.classList.add('bg-white/10', 'text-white/80');
            });
            
            // Add active class to clicked button
            this.classList.add('active', 'bg-white/20', 'text-white');
            this.classList.remove('bg-white/10', 'text-white/80');
            
            // Filter logic here
            const filter = this.getAttribute('data-filter');
            filterBooksButtons(filter);
        });
    });

    function filterBooksButtons(category) {
        const bookCards = document.querySelectorAll('.book-card');
        const categories = document.querySelectorAll('.category-section');
        
        if (category === 'all') {
            categories.forEach(cat => cat.style.display = 'block');
            bookCards.forEach(card => card.style.display = 'block');
        } else {
            categories.forEach(cat => {
                if (cat.id === category + '-section') {
                    cat.style.display = 'block';
                } else {
                    cat.style.display = 'none';
                }
            });
        }
    }
    const input = document.getElementById('searchInput');
    const suggestions = document.getElementById('suggestions');

    input.addEventListener('input', () => {
        const value = input.value.toLowerCase();
        const items = suggestions.querySelectorAll('.suggestion-item');
        let hasVisible = false;

        items.forEach(item => {
            const text = item.innerText.toLowerCase();
            const match = text.includes(value);
            item.style.display = match ? 'flex' : 'none';
            if (match) hasVisible = true;
        });

        suggestions.style.display = (value && hasVisible) ? 'block' : 'none';
    });

    document.addEventListener('click', (e) => {
        if (!suggestions.contains(e.target) && e.target !== input) {
            suggestions.style.display = 'none';
        }
    });
    
    //loc sách
    (function () {
        const ctx = '<%= request.getContextPath() %>';
        document.querySelectorAll('.filter-btn').forEach(btn => {
          btn.addEventListener('click', function () {
            const gid   = this.dataset.genreId || '';
            const glabel= this.dataset.label   || 'Tất cả';
            // chuyển hướng để index.jsp render kết quả từ DB
            if (!gid) {
              window.location.href = ctx + '/index.jsp';
            } else {
              window.location.href = ctx + '/index.jsp?genreId=' + encodeURIComponent(gid)
                                                   + '&genreName=' + encodeURIComponent(glabel);
            }
          });
        });
      })();
    (function () {
        const btns = document.querySelectorAll('#mainFilterBar .tab-btn');
        const panels = document.querySelectorAll('#mainFilterBar .tab-panel');
        let activeTab = null;

        function toggleTab(id) {
          if (activeTab === id) {
            // nếu đang mở cùng 1 tab => đóng lại
            document.getElementById(id)?.classList.add('hidden');
            document.querySelector(`#mainFilterBar .tab-btn[data-tab="${id}"]`)?.classList.remove('active');
            activeTab = null;
            localStorage.removeItem('lib_active_tab');
          } else {
            // đóng tất cả, mở tab mới
            panels.forEach(p => p.classList.add('hidden'));
            btns.forEach(b => b.classList.remove('active'));
            document.getElementById(id)?.classList.remove('hidden');
            document.querySelector(`#mainFilterBar .tab-btn[data-tab="${id}"]`)?.classList.add('active');
            activeTab = id;
            localStorage.setItem('lib_active_tab', id);
          }
        }

        btns.forEach(b => {
          b.addEventListener('click', () => toggleTab(b.dataset.tab));
        });

        // khởi tạo theo localStorage nếu có
        const saved = localStorage.getItem('lib_active_tab');
        if (saved) {
          toggleTab(saved);
        }
      })();
       // ===== Modal open/close =====
  (function(){
    const openBtn   = document.getElementById('filterBarToggle');
    const modal     = document.getElementById('filterModal');
    const overlay   = document.getElementById('filterOverlay');
    const dialog    = document.getElementById('filterDialog');
    const closeBtn  = document.getElementById('filterCloseBtn');

    function openModal() {
      modal.classList.remove('hidden');
      // đảm bảo start state (opacity 0, translate-y-6) đã áp sẵn qua classes
      requestAnimationFrame(() => {
        modal.classList.add('open');
        document.documentElement.style.overflow = 'hidden'; // lock scroll
      });
    }

    function closeModal() {
      modal.classList.remove('open');
      document.documentElement.style.overflow = ''; // unlock
      // chờ transition xong rồi mới ẩn
      setTimeout(() => modal.classList.add('hidden'), 200);
    }

    if (openBtn)   openBtn.addEventListener('click', openModal);
    if (closeBtn)  closeBtn.addEventListener('click', closeModal);
    if (overlay)   overlay.addEventListener('click', closeModal);
    document.addEventListener('keydown', (e) => { if (e.key === 'Escape' && !modal.classList.contains('hidden')) closeModal(); });
  })();
  (function(){
    const openBtn   = document.getElementById('filterBarToggle');
    const modal     = document.getElementById('filterModal');
    const overlay   = document.getElementById('filterOverlay');
    const dialog    = document.getElementById('filterDialog');
    const closeBtn  = document.getElementById('filterCloseBtn');

    function openModal() {
        modal.classList.remove('hidden');
        requestAnimationFrame(() => {
          modal.classList.add('open');
          document.documentElement.style.overflow = 'hidden'; // lock scroll
        });
      }

      function closeModal() {
        modal.classList.remove('open');
        document.documentElement.style.overflow = ''; // unlock
        setTimeout(() => modal.classList.add('hidden'), 250); // chờ hiệu ứng xong
      }


    if (openBtn)  openBtn.addEventListener('click', openModal);
    if (closeBtn) closeBtn.addEventListener('click', closeModal);
    if (overlay)  overlay.addEventListener('click', closeModal);

    // Click vào vùng trống quanh dialog cũng đóng
    modal.addEventListener('click', (e) => {
      if (!dialog.contains(e.target)) closeModal();
    });

    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && !modal.classList.contains('hidden')) closeModal();
    });
  })();
  // ===== Tabs trong modal (giữ code cũ, chỉ đổi vùng chứa) =====
  (function () {
    const root   = document.getElementById('filterDialog');
    const btns   = root.querySelectorAll('.tab-btn');
    const panels = root.querySelectorAll('.tab-panel');
    let activeTab = null;

    function toggleTab(id) {
      if (activeTab === id) {
        // đóng panel nếu bấm lại
        root.querySelector('#' + id)?.classList.add('hidden');
        root.querySelector(`.tab-btn[data-tab="${id}"]`)?.classList.remove('active');
        activeTab = null;
        localStorage.removeItem('lib_active_tab');
      } else {
        panels.forEach(p => p.classList.add('hidden'));
        btns.forEach(b => b.classList.remove('active'));
        root.querySelector('#' + id)?.classList.remove('hidden');
        root.querySelector(`.tab-btn[data-tab="${id}"]`)?.classList.add('active');
        activeTab = id;
        localStorage.setItem('lib_active_tab', id);
      }
    }

    btns.forEach(b => b.addEventListener('click', () => toggleTab(b.dataset.tab)));

    // mở lại tab trước đó nếu có
    const saved = localStorage.getItem('lib_active_tab');
    if (saved && root.querySelector('#' + saved)) toggleTab(saved);
    else toggleTab('tab-genres'); // mặc định mở "Thể loại"
  })();
</script>