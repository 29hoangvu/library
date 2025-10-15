<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="Servlet.DBConnection" %>
<%
  String isbn = request.getParameter("isbn");
  if (isbn == null || isbn.isBlank()) { out.println("Missing isbn"); return; }

  String mime = null;
  String filePath = null;

  try (Connection c = DBConnection.getConnection();
       PreparedStatement ps = c.prepareStatement(
         "SELECT mime_type, file_path FROM ebook_asset WHERE book_isbn=?")) {
    ps.setString(1, isbn);
    try (ResultSet rs = ps.executeQuery()) {
      if (rs.next()) {
        mime = rs.getString("mime_type");
        filePath = rs.getString("file_path");
      }
    }
  } catch (Exception e) { out.println("DB error: " + e.getMessage()); return; }

  if (mime == null || mime.isBlank()) {
    String low = (filePath == null ? "" : filePath.toLowerCase());
    if (low.endsWith(".epub")) mime = "application/epub+zip";
    else mime = "application/pdf";
  }

  String fileUrl = request.getContextPath() + "/ebook?isbn=" + java.net.URLEncoder.encode(isbn, "UTF-8");
%>
<script>
(function(){
  var isbn = "<%= isbn %>";
  var mark = "read_ping_" + isbn + "_" + new Date().toISOString().slice(0,10); // key theo ngày

  if (!sessionStorage.getItem(mark)) {
    try {
      var params = new URLSearchParams();
      params.append("isbn", isbn);
      fetch("<%= request.getContextPath() %>/trackRead", {
        method: "POST",
        body: params,
        headers: { "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8" },
        keepalive: true
      });
      sessionStorage.setItem(mark, "1");
    } catch (e) { /* ignore */ }
  }
})();
</script>

<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Đọc online - <%= isbn %></title>
  <script src="https://cdn.tailwindcss.com"></script>
  <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
  <% if ("application/pdf".equalsIgnoreCase(mime)) { %>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js"></script>
  <% } %>
  <style>
    html, body { 
      height: 100%; 
      margin: 0; 
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    }
    
    .reader-container {
      background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%);
      min-height: 100vh;
    }
    
    .toolbar-glass {
      backdrop-filter: blur(20px);
      background: rgba(15, 23, 42, 0.85);
      border: 1px solid rgba(148, 163, 184, 0.2);
      box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
    }
    
    .control-btn {
      transition: all 0.2s ease;
      border: 1px solid rgba(148, 163, 184, 0.2);
    }
    
    .control-btn:hover {
      background: rgba(59, 130, 246, 0.8);
      border-color: rgba(59, 130, 246, 0.5);
      transform: translateY(-1px);
      box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);
    }
    
    .back-btn:hover {
      background: rgba(239, 68, 68, 0.8);
      border-color: rgba(239, 68, 68, 0.5);
      box-shadow: 0 4px 12px rgba(239, 68, 68, 0.3);
    }
    
    .download-btn:hover {
      background: rgba(16, 185, 129, 0.8);
      border-color: rgba(16, 185, 129, 0.5);
      box-shadow: 0 4px 12px rgba(16, 185, 129, 0.3);
    }
    
    .viewer-frame {
      background: rgba(255, 255, 255, 0.98);
      border-radius: 12px;
      box-shadow: 
        0 25px 50px -12px rgba(0, 0, 0, 0.5),
        0 0 0 1px rgba(255, 255, 255, 0.1);
      backdrop-filter: blur(20px);
    }
    
    .page-info {
      background: rgba(0, 0, 0, 0.6);
      backdrop-filter: blur(10px);
      border-radius: 20px;
      padding: 6px 12px;
      font-size: 0.875rem;
    }
    
    .loading-spinner { animation: spin 1s linear infinite; }
    @keyframes spin { from { transform: rotate(0deg);} to { transform: rotate(360deg);} }
    
    .custom-scrollbar::-webkit-scrollbar { width: 8px; }
    .custom-scrollbar::-webkit-scrollbar-track { background: rgba(148, 163, 184, 0.1); border-radius: 4px; }
    .custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(148, 163, 184, 0.4); border-radius: 4px; }
    .custom-scrollbar::-webkit-scrollbar-thumb:hover { background: rgba(148, 163, 184, 0.6); }
    
    .toolbar-hidden { transform: translate(-50%, -100%) !important; opacity: 0; pointer-events: none; }
    .toolbar-visible { transform: translate(-50%, 0) !important; opacity: 1; pointer-events: all; }
    #toolbar { transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); }
    
    @media (max-width: 768px) {
      .toolbar-mobile { position: fixed; bottom: 20px; left: 50%; transform: translateX(-50%); top: auto; flex-direction: column; gap: 8px; }
      .toolbar-mobile.toolbar-hidden { transform: translate(-50%, 100%) !important; }
      .viewer-mobile { padding-top: 20px; padding-bottom: 120px; }
      .control-btn { width: 100%; justify-content: center; }
    }
    
    .control-btn:focus, select:focus { outline: 2px solid rgba(59, 130, 246, 0.6); outline-offset: 2px; }
    .custom-select { background: rgba(30, 41, 59, 0.9); border: 1px solid rgba(148, 163, 184, 0.2); color: #e2e8f0; transition: all 0.2s ease; }
    .custom-select:hover { border-color: rgba(59, 130, 246, 0.5); background: rgba(30, 41, 59, 1); }

    /* ==== PDF Thumbnails ==== */
    .pdf-shell { display: flex; gap: 16px; }
    #pdfThumbs {
      width: 160px; max-height: 70vh; overflow: auto;
      background: rgba(255,255,255,0.98); border-radius: 12px; padding: 8px;
      box-shadow: 0 10px 25px rgba(0,0,0,.15);
    }
    .thumb {
      position: relative; margin: 6px 4px; padding: 6px; border-radius: 8px;
      cursor: pointer; transition: transform .1s ease, background .2s ease;
      border: 1px solid #e5e7eb; background: #fff;
    }
    .thumb:hover { transform: translateY(-1px); background: #f8fafc; }
    .thumb.active { outline: 2px solid #3b82f6; outline-offset: 2px; }
    .thumb .label {
      position: absolute; bottom: 6px; right: 10px; background: rgba(0,0,0,.65);
      color: #fff; font-size: 12px; padding: 2px 6px; border-radius: 10px;
    }
    #pdfThumbs.hidden { display: none; }
  </style>
</head>
<body class="reader-container">
  <!-- Enhanced Toolbar -->
  <div id="toolbar" class="fixed top-6 left-1/2 toolbar-visible z-50 md:toolbar-mobile">
    <div class="toolbar-glass px-6 py-3 rounded-2xl flex flex-wrap items-center justify-center gap-3">
      <!-- Back button -->
      <a href="<%= request.getContextPath() %>/user/bookDetails.jsp?isbn=<%= isbn %>" 
         class="control-btn back-btn flex items-center gap-2 px-4 py-2 rounded-xl text-white font-medium">
        <i class="fas fa-arrow-left text-sm"></i>
        <span class="hidden sm:inline">Quay lại</span>
      </a>
      
      <!-- Download button -->
      <a href="<%= fileUrl %>&download=true" 
         class="control-btn download-btn flex items-center gap-2 px-4 py-2 rounded-xl text-white font-medium">
        <i class="fas fa-download text-sm"></i>
        <span class="hidden sm:inline">Tải về</span>
      </a>
      
      <!-- PDF Controls -->
      <button id="zoomOut" class="control-btn px-3 py-2 rounded-xl text-white font-bold hidden" title="Thu nhỏ (-)">
        <i class="fas fa-search-minus"></i>
      </button>
      <button id="zoomIn" class="control-btn px-3 py-2 rounded-xl text-white font-bold hidden" title="Phóng to (+)">
        <i class="fas fa-search-plus"></i>
      </button>
      
      <!-- Page Info -->
      <div id="pageInfo" class="page-info text-white font-medium hidden lg:block"></div>
    </div>

  <!-- Auto-hide Toolbar Script -->
  <script>
    (function() {
      let lastScrollY = window.scrollY;
      let ticking = false;
      let isToolbarVisible = true;
      let hideTimeout = null;
      const toolbar = document.getElementById('toolbar');
      
      function updateToolbar() {
        const currentScrollY = window.scrollY;
        const scrollDifference = currentScrollY - lastScrollY;
        if (scrollDifference < 0 || currentScrollY < 100) {
          if (!isToolbarVisible) {
            toolbar.classList.remove('toolbar-hidden');
            toolbar.classList.add('toolbar-visible');
            isToolbarVisible = true;
          }
          if (hideTimeout) { clearTimeout(hideTimeout); hideTimeout = null; }
          hideTimeout = setTimeout(() => {
            if (currentScrollY > 100) {
              toolbar.classList.remove('toolbar-visible');
              toolbar.classList.add('toolbar-hidden');
              isToolbarVisible = false;
            }
          }, 3000);
        } else if (scrollDifference > 0 && currentScrollY > 100) {
          if (isToolbarVisible) {
            toolbar.classList.remove('toolbar-visible');
            toolbar.classList.add('toolbar-hidden');
            isToolbarVisible = false;
          }
          if (hideTimeout) { clearTimeout(hideTimeout); hideTimeout = null; }
        }
        lastScrollY = currentScrollY;
        ticking = false;
      }
      function requestTick() { if (!ticking) { requestAnimationFrame(updateToolbar); ticking = true; } }
      window.addEventListener('scroll', requestTick, { passive: true });
      document.addEventListener('mousemove', (e) => {
        if (e.clientY < 100 && !isToolbarVisible) {
          toolbar.classList.remove('toolbar-hidden'); toolbar.classList.add('toolbar-visible'); isToolbarVisible = true;
          setTimeout(() => {
            if (window.scrollY > 100) { toolbar.classList.remove('toolbar-visible'); toolbar.classList.add('toolbar-hidden'); isToolbarVisible = false; }
          }, 2000);
        }
      });
      toolbar.addEventListener('mouseenter', () => { if (hideTimeout) { clearTimeout(hideTimeout); hideTimeout = null; } toolbar.classList.remove('toolbar-hidden'); toolbar.classList.add('toolbar-visible'); isToolbarVisible = true; });
      toolbar.addEventListener('mouseleave', () => {
        if (window.scrollY > 100) {
          hideTimeout = setTimeout(() => { toolbar.classList.remove('toolbar-visible'); toolbar.classList.add('toolbar-hidden'); isToolbarVisible = false; }, 1000);
        }
      });
      window.addEventListener('resize', () => { toolbar.classList.remove('toolbar-hidden'); toolbar.classList.add('toolbar-visible'); isToolbarVisible = true; });
      toolbar.classList.add('toolbar-visible');
    })();
  </script>
  </div>

  <!-- Main Content Area -->
  <div class="pt-24 pb-8 px-4 md:px-8 min-h-screen">
    <div class="max-w-6xl mx-auto">
      <!-- Loading State -->
      <div id="loadingState" class="viewer-frame p-8 text-center text-gray-600">
        <div class="loading-spinner inline-block w-8 h-8 border-4 border-blue-500 border-t-transparent rounded-full mb-4"></div>
        <p class="text-lg">Đang tải sách...</p>
      </div>

      <!-- PDF Viewer Shell (thumbs + canvas) -->
      <div id="pdfShell" class="viewer-frame viewer-mobile custom-scrollbar pdf-shell hidden" style="min-height: 70vh;">
        <div id="pdfThumbs" class="custom-scrollbar"></div>
        <div id="pdfViewer" class="custom-scrollbar" style="flex:1; overflow:auto;"></div>
      </div>
      
      <!-- EPUB Viewer Container -->
      <div id="epubViewer" class="viewer-frame viewer-mobile custom-scrollbar hidden" style="min-height: 70vh; overflow:auto;"></div>
    </div>
  </div>

  <!-- Error Modal -->
  <div id="errorModal" class="fixed inset-0 bg-black bg-opacity-50 z-50 hidden flex items-center justify-center p-4">
    <div class="bg-white rounded-2xl p-6 max-w-md w-full">
      <div class="text-center">
        <i class="fas fa-exclamation-triangle text-red-500 text-4xl mb-4"></i>
        <h3 class="text-xl font-bold text-gray-800 mb-2">Lỗi tải sách</h3>
        <p id="errorMessage" class="text-gray-600 mb-4"></p>
        <button id="closeError" class="bg-red-500 text-white px-6 py-2 rounded-xl hover:bg-red-600 transition">
          Đóng
        </button>
      </div>
    </div>
  </div>

  <% if ("application/pdf".equalsIgnoreCase(mime)) { %>
  <!-- ===== PDF MODE ===== -->
  <script>
    (function () {
      var url = "<%= fileUrl %>";
      var shell = document.getElementById('pdfShell');
      var thumbs = document.getElementById('pdfThumbs');
      var viewer = document.getElementById('pdfViewer');
      var loadingState = document.getElementById('loadingState');

      var pdfDoc = null, pageNum = 1, scale = 1.2, rendering = false;

      var canvas = document.createElement('canvas');
      canvas.className = "block mx-auto shadow-lg rounded-lg mb-4";
      viewer.appendChild(canvas);
      var ctx = canvas.getContext('2d');

      pdfjsLib.GlobalWorkerOptions.workerSrc =
        "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js";

      function showError(message) {
        document.getElementById('errorMessage').textContent = message;
        document.getElementById('errorModal').classList.remove('hidden');
      }

      function renderPage(num){
        rendering = true;
        pdfDoc.getPage(num).then(function(page){
          var viewport = page.getViewport({scale: scale});
          canvas.width = viewport.width;
          canvas.height = viewport.height;

          var renderTask = page.render({ canvasContext: ctx, viewport: viewport });
          return renderTask.promise.then(function(){
            rendering = false;
            document.getElementById('pageInfo').textContent =
              'Trang ' + pageNum + '/' + pdfDoc.numPages;
            highlightThumb(pageNum);
            viewer.scrollTop = 0;
          });
        }).catch(function(err){
          showError("Lỗi khi render trang: " + err.message);
        });
      }

      function queueRenderPage(num){ rendering ? setTimeout(()=>queueRenderPage(num),120) : renderPage(num); }
      function nextPage(){ if (pageNum < pdfDoc.numPages){ pageNum++; queueRenderPage(pageNum);} }
      function prevPage(){ if (pageNum > 1){ pageNum--; queueRenderPage(pageNum);} }

      // === THUMBNAILS ===
      function buildThumbs(pdf){
        thumbs.innerHTML = "";
        const io = new IntersectionObserver(entries => {
          entries.forEach(entry => {
            if (entry.isIntersecting) {
              const div = entry.target;
              const p = parseInt(div.dataset.page, 10);
              if (!div.dataset.rendered) {
                renderThumb(p, div);
                div.dataset.rendered = "1";
              }
            }
          });
        }, { root: thumbs, threshold: 0.1 });

        for (let p=1; p<=pdf.numPages; p++){
          const wrap = document.createElement('div');
          wrap.className = "thumb";
          wrap.dataset.page = p;

          const c = document.createElement("canvas");
          c.style.width = "100%"; c.style.display = "block";
          wrap.appendChild(c);

          const lb = document.createElement("div");
          lb.className = "label"; lb.textContent = p;
          wrap.appendChild(lb);

          wrap.onclick = () => { if (pageNum!==p){ pageNum = p; queueRenderPage(pageNum);} };
          thumbs.appendChild(wrap);
          io.observe(wrap);
        }
      }

      async function renderThumb(p, wrap){
        try {
          const page = await pdfDoc.getPage(p);
          const vw = page.getViewport({scale: 1});
          const targetW = 120;
          const thumbScale = targetW / vw.width;
          const vp = page.getViewport({scale: thumbScale});

          const c = wrap.querySelector('canvas');
          c.width = vp.width; c.height = vp.height;
          const ctxT = c.getContext('2d');
          await page.render({ canvasContext: ctxT, viewport: vp }).promise;
        } catch(e) { /* ignore */ }
      }

      function highlightThumb(p){
        const prev = thumbs.querySelector('.thumb.active');
        if (prev) prev.classList.remove('active');
        const cur = thumbs.querySelector(`.thumb[data-page="${p}"]`);
        if (cur) {
          cur.classList.add('active');
          const tTop = cur.offsetTop, tBot = tTop + cur.offsetHeight;
          const sTop = thumbs.scrollTop, sBot = sTop + thumbs.clientHeight;
          if (tTop < sTop) thumbs.scrollTop = tTop - 8;
          else if (tBot > sBot) thumbs.scrollTop = tBot - thumbs.clientHeight + 8;
        }
      }

      // === LOAD PDF ===
      pdfjsLib.getDocument({url: url}).promise.then(function(pdf){
        pdfDoc = pdf;
        loadingState.classList.add('hidden');
        shell.classList.remove('hidden');

        // show toolbar controls
        document.getElementById('zoomOut').classList.remove('hidden');
        document.getElementById('zoomIn').classList.remove('hidden');
        document.getElementById('pageInfo').classList.remove('hidden');

        // add toolbar navigation + toggle thumbnails
        const tb = document.getElementById("toolbar").querySelector('.toolbar-glass');
        const nav = document.createElement("div");
        nav.className = "flex items-center gap-2 ml-4 pl-4 border-l border-gray-600";

        const toggle = document.createElement("button");
        toggle.className = "control-btn px-3 py-2 rounded-xl text-white font-medium";
        toggle.innerHTML = '<i class="fas fa-columns"></i> <span class="hidden sm:inline">Thu nhỏ</span>';
        toggle.onclick = () => thumbs.classList.toggle('hidden');
        nav.appendChild(toggle);

        const prevBtn = document.createElement("button");
        prevBtn.className = "control-btn px-3 py-2 rounded-xl text-white font-medium";
        prevBtn.innerHTML = '<i class="fas fa-chevron-left"></i> <span class="hidden sm:inline">Trước</span>';
        prevBtn.onclick = prevPage;
        nav.appendChild(prevBtn);

        const nextBtn = document.createElement("button");
        nextBtn.className = "control-btn px-3 py-2 rounded-xl text-white font-medium";
        nextBtn.innerHTML = '<span class="hidden sm:inline">Sau</span> <i class="fas fa-chevron-right"></i>';
        nextBtn.onclick = nextPage;
        nav.appendChild(nextBtn);

        tb.appendChild(nav);

        buildThumbs(pdfDoc);
        renderPage(pageNum);
      }).catch(function(error) {
        showError('Không thể tải file PDF: ' + error.message);
      });

      // Zoom
      document.getElementById('zoomIn').onclick = function(){ 
        scale = Math.min(5, scale + 0.1); 
        queueRenderPage(pageNum); 
      };
      document.getElementById('zoomOut').onclick = function(){ 
        scale = Math.max(0.4, scale - 0.1); 
        queueRenderPage(pageNum); 
      };

      // Keyboard
      document.addEventListener('keydown', function(e){
        if (!pdfDoc) return;
        if (e.key === 'ArrowRight') nextPage();
        if (e.key === 'ArrowLeft')  prevPage();
        if (e.key === '+') { scale = Math.min(5, scale + 0.1); queueRenderPage(pageNum); }
        if (e.key === '-') { scale = Math.max(0.4, scale - 0.1); queueRenderPage(pageNum); }
      });

      // Close error modal
      document.getElementById('closeError').onclick = function() {
        document.getElementById('errorModal').classList.add('hidden');
      };
    })();
  </script>
  <% } else { %>
  <!-- ===== EPUB MODE ===== -->
  <script>
    var fileUrl = "<%= fileUrl %>";

    function showError(message) {
      document.getElementById('errorMessage').textContent = message;
      document.getElementById('errorModal').classList.remove('hidden');
    }

    function loadScript(src) {
      return new Promise(function (resolve, reject) {
        var s = document.createElement("script");
        s.src = src;
        s.onload = resolve;
        s.onerror = function(){ reject(new Error("Load script fail: " + src)); };
        document.head.appendChild(s);
      });
    }

    (async function () {
      try {
        // Load libraries
        await loadScript("https://cdnjs.cloudflare.com/ajax/libs/jszip/3.10.1/jszip.min.js");
        try {
          await loadScript("https://cdnjs.cloudflare.com/ajax/libs/epub.js/0.3.93/epub.min.js");
        } catch (e) {
          await loadScript("https://unpkg.com/epubjs/dist/epub.min.js");
        }
        if (typeof window.ePub !== "function") throw new Error("epub.js chưa sẵn sàng");

        // Fetch EPUB
        var res = await fetch(fileUrl, { cache: "no-store" });
        if (!res.ok) throw new Error("Không tải được ebook: HTTP " + res.status);
        var buf = await res.arrayBuffer();

        // Initialize book
        var book = ePub(buf);
        var rendition = book.renderTo("epubViewer", {
          width: "100%",
          height: "100%",
          flow: "scrolled-doc",
          allowScriptedContent: false
        });
        
        // Theming
        rendition.themes.default({
          "body": { 
            "background": "#ffffff", 
            "color": "#1f2937", 
            "line-height": "1.8", 
            "padding": "2rem",
            "font-family": "'Segoe UI', Tahoma, Geneva, Verdana, sans-serif",
            "font-size": "16px"
          },
          "img": { "max-width": "100%", "height": "auto", "border-radius": "8px" },
          "h1, h2, h3, h4, h5, h6": { "color": "#111827", "margin": "1.5rem 0 1rem 0" },
          "p": { "margin": "0 0 1rem 0", "text-align": "justify" },
          "a": { "color": "#3b82f6", "text-decoration": "none" }
        });

        // Display first chapter (skip cover)
        await book.loaded.spine;
        var firstNonCover = book.spine.items.find(function(it){
          var h = (it.href || "").toLowerCase();
          var id = (it.idref || "").toLowerCase();
          return !/cover/.test(h) && !/cover/.test(id);
        });
        await rendition.display(firstNonCover ? firstNonCover.href : undefined);

        // Show viewer
        document.getElementById('loadingState').classList.add('hidden');
        document.getElementById('epubViewer').classList.remove('hidden');
        
        // === EPUB Zoom (font-size) ===
        var currentFontPct = 100; // % cỡ chữ
        function applyFontSize(){
          rendition.themes.fontSize(currentFontPct + '%');
        }

        // hiển thị nút zoom, ẩn pageInfo nếu có
        document.getElementById('zoomIn').classList.remove('hidden');
        document.getElementById('zoomOut').classList.remove('hidden');
        var pageInfoEl = document.getElementById('pageInfo');
        if (pageInfoEl) pageInfoEl.classList.add('hidden');

        // gán sự kiện cho nút
        document.getElementById('zoomIn').onclick = function(){
          currentFontPct = Math.min(220, currentFontPct + 10);
          applyFontSize();
        };
        document.getElementById('zoomOut').onclick = function(){
          currentFontPct = Math.max(60, currentFontPct - 10);
          applyFontSize();
        };

        // phím tắt +/-
        document.addEventListener('keydown', function(e){
          if (e.key === '+'){
            currentFontPct = Math.min(220, currentFontPct + 10);
            applyFontSize();
          }
          if (e.key === '-'){
            currentFontPct = Math.max(60, currentFontPct - 10);
            applyFontSize();
          }
        });

        // áp dụng cỡ chữ ban đầu
        applyFontSize();

        // Keyboard
        document.addEventListener("keydown", function(e) {
          if (e.key === "ArrowRight") rendition.next();
          if (e.key === "ArrowLeft")  rendition.prev();
        });

        // Toolbar navigation
        var tb = document.getElementById("toolbar").querySelector('.toolbar-glass');
        var navContainer = document.createElement("div");
        navContainer.className = "flex items-center gap-2 ml-4 pl-4 border-l border-gray-600";
        
        var prevBtn = document.createElement("button");
        prevBtn.className = "control-btn px-3 py-2 rounded-xl text-white font-medium flex items-center gap-1";
        prevBtn.innerHTML = '<i class="fas fa-chevron-left text-sm"></i><span class="hidden sm:inline">Trước</span>';
        prevBtn.onclick = function(){ rendition.prev(); };
        navContainer.appendChild(prevBtn);

        var nextBtn = document.createElement("button");
        nextBtn.className = "control-btn px-3 py-2 rounded-xl text-white font-medium flex items-center gap-1";
        nextBtn.innerHTML = '<span class="hidden sm:inline">Sau</span><i class="fas fa-chevron-right text-sm"></i>';
        nextBtn.onclick = function(){ rendition.next(); };
        navContainer.appendChild(nextBtn);

        var tocSelect = document.createElement("select");
        tocSelect.className = "custom-select ml-2 px-3 py-2 rounded-xl text-sm max-w-48";
        var def = document.createElement("option");
        def.text = "— Mục lục —"; def.value = "";
        tocSelect.appendChild(def);
        navContainer.appendChild(tocSelect);
        tb.appendChild(navContainer);

        book.loaded.navigation.then(function(nav){
          var toc = (nav && nav.toc) ? nav.toc : [];
          toc.forEach(function(n){
            var opt = document.createElement("option");
            opt.value = n.href;
            opt.text = (n.label || "").replace(/<[^>]*>/g, "").substring(0, 50);
            tocSelect.appendChild(opt);
          });
        });

        tocSelect.addEventListener("change", function(){
          if (this.value) { rendition.display(this.value); this.value = ""; }
        });

      } catch (err) {
        console.error(err);
        showError(err && err.message ? err.message : 'Lỗi không xác định');
      }
    })();

    // Close error modal
    document.getElementById('closeError').onclick = function() {
      document.getElementById('errorModal').classList.add('hidden');
    };
  </script>
  <% } %>

</body>
</html>
