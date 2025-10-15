<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%
  String ep = request.getParameter("endpoint");
  if (ep == null || ep.isBlank()) ep = request.getContextPath() + "/api/search.jsp";
  String base = request.getContextPath();
%>

<div class="relative hidden md:flex flex-1 max-w-md mx-8" id="searchBox">
  <form action="<%=base%>/index.jsp" method="get" class="w-full" id="searchForm">
    <div class="relative">
      <input type="text" id="searchInput" name="search"
             placeholder="Tìm sách theo tên, tác giả, thể loại, năm"
             value="<%= request.getParameter("search")==null ? "" : request.getParameter("search") %>"
             class="w-full px-4 py-2 pr-12 rounded-full border-2 border-white/20 bg-white/10 text-white placeholder-white/70 focus:outline-none focus:border-white focus:bg-white/20 transition-all duration-300"
             autocomplete="off">
      <button type="submit" class="absolute right-2 top-1/2 -translate-y-1/2 text-white hover:text-yellow-300">
        <i class="fas fa-search"></i>
      </button>
      <div id="searchLoading" class="absolute right-10 top-1/2 -translate-y-1/2 hidden">
        <i class="fas fa-spinner fa-spin text-white"></i>
      </div>
    </div>
  </form>

  <div id="suggestionsBox"
     class="absolute top-full mt-2 w-full bg-white rounded-lg shadow-xl max-h-80 overflow-y-auto hidden z-50 border border-gray-200"
     style="color:#111">   <!-- ép màu chữ mặc định -->
    <div id="suggestionsBoxContent"></div>
    <div id="noResults" class="px-4 py-3 text-gray-500 text-center hidden">
      <i class="fas fa-search mr-2"></i>Không tìm thấy kết quả phù hợp
    </div>
    <div class="px-4 py-2 bg-gray-50 border-t text-xs text-gray-400 flex items-center justify-between">
      <span><i class="fas fa-lightbulb mr-1"></i>Gõ ít nhất 2 ký tự để tìm kiếm</span>
      <span>ESC để đóng</span>
    </div>
  </div>
</div>

<script>
(function () {
  const ENDPOINT = "<%= request.getParameter("endpoint")==null||request.getParameter("endpoint").isBlank() ? request.getContextPath()+"/api/search.jsp" : request.getParameter("endpoint") %>";
  const BASE = "<%= request.getContextPath() %>";

  // Lấy phần tử – có thể KHÔNG tồn tại trên vài trang / kích thước
  const searchInput  = document.getElementById('searchInput');
  const searchBox    = document.getElementById('searchBox');
  const suggestionsBox        = document.getElementById('suggestionsBox');
  const suggestionsBoxContent = document.getElementById('suggestionsBoxContent');
  const noResults             = document.getElementById('noResults');
  const searchLoading         = document.getElementById('searchLoading');

  // Nếu không có ô tìm kiếm trên trang này -> thoát sớm, tránh mọi lỗi
  if (!searchInput || !suggestionsBox || !suggestionsBoxContent || !noResults || !searchLoading) {
    return;
  }

  let t, focus = -1;

  searchInput.addEventListener('input', () => {
    const q = searchInput.value.trim();
    clearTimeout(t);
    if (q.length < 2) { hide(); return; }
    searchLoading.classList.remove('hidden');
    t = setTimeout(() =>
      fetch(ENDPOINT + "?q=" + encodeURIComponent(q) + "&limit=8", {headers:{Accept:'application/json'}})
        .then(r => { if (!r.ok) throw new Error('HTTP '+r.status); return r.json(); })
        .then(list => render(Array.isArray(list) ? list : [], q))
        .catch(() => showEmpty())
        .finally(() => searchLoading.classList.add('hidden')),
    280);
  });

  searchInput.addEventListener('keydown', e => {
    // suggestionsBox luôn tồn tại do guard phía trên
    const items = suggestionsBox.querySelectorAll('.suggestion-item');
    if (!items.length) return;

    if (e.key === 'ArrowDown') { e.preventDefault(); focus = (focus + 1) % items.length; active(items); }
    else if (e.key === 'ArrowUp') { e.preventDefault(); focus = (focus - 1 + items.length) % items.length; active(items); }
    else if (e.key === 'Enter') { if (focus > -1) { e.preventDefault(); items[focus].click(); } }
    else if (e.key === 'Escape') { hide(); searchInput.blur(); }
  });

  function render(items, q) {
    suggestionsBoxContent.innerHTML = '';
    noResults.classList.add('hidden');
    focus = -1;
    if (!items.length) { showEmpty(); return; }
    items.forEach(b => suggestionsBoxContent.appendChild(item(b, q)));
    suggestionsBox.classList.remove('hidden');
  }
  function normCover(path) {
    if (!path || !String(path).trim()) return BASE + "/images/default-cover.jpg";
    if (/^https?:\/\//i.test(path)) return path;              // URL tuyệt đối
    if (path.startsWith(BASE + "/")) return path;             // đã có context
    if (path.startsWith("/")) return BASE + path;             // "/images/..." -> "/Library/images/..."
    return BASE + "/" + path.replace(/^\.?\//, "");           // "images/..." -> "/Library/images/..."
  }
  function item(b, q) {
    const div = document.createElement('div');
    div.className = 'suggestion-item flex items-center gap-3 px-4 py-3 hover:bg-gray-50 cursor-pointer border-b border-gray-100 last:border-b-0';

    const title  = highlight(b.title || '', q);
    const author = highlight(b.author || 'Không rõ tác giả', q);
    const year   = (b.publicationYear ?? 'N/A');

    const coverPath = normCover(b.coverImage); // hàm chuẩn hoá đã nói ở trên
    const altText = String(b.title || '').replace(/"/g, '&quot;');

    div.innerHTML =
        '<div class="flex-shrink-0">' +
          '<img src="' + coverPath + '"' +
               ' alt="' + altText + '"' +
               ' onerror="this.onerror=null; this.src=\'' + BASE + '/images/default-cover.jpg\'"' +
               ' class="w-12 h-16 object-cover rounded-md border border-gray-200">' +
        '</div>' +
        '<div class="flex-1 min-w-0">' +
          '<h4 class="font-medium truncate mb-1 text-gray-900">' + title + '</h4>' +
          '<p class="truncate text-sm text-gray-600"><i class="fas fa-user-edit mr-1"></i>' + author + '</p>' +
          '<p class="truncate text-xs text-gray-500 mt-1"><i class="fas fa-calendar mr-1"></i>' + year + '</p>' +
        '</div>' +
        '<div class="flex-shrink-0 text-gray-400"><i class="fas fa-arrow-right text-xs"></i></div>';

      div.addEventListener('click', () => {
        window.location.href = BASE + "/user/bookDetails.jsp?isbn=" + encodeURIComponent(b.isbn);
      });
    return div;
  }
  
  function highlight(txt, q) {
    if (!q) return txt;
    const safe = q.replace(/[.*+?^\\${}()|[\]\\]/g, '\\$&');
    return String(txt).replace(new RegExp('(' + safe + ')', 'gi'),
      '<mark class="bg-yellow-200 px-1 rounded">$1</mark>');
  }

  function showEmpty() {
    suggestionsBoxContent.innerHTML = '';
    noResults.classList.remove('hidden');
    suggestionsBox.classList.remove('hidden');
  }

  function hide() {
    suggestionsBox.classList.add('hidden');
    focus = -1;
    searchLoading.classList.add('hidden');
  }

  function active(items) {
    items.forEach(it => it.classList.remove('bg-blue-50','border-blue-200'));
    if (focus > -1) {
      items[focus].classList.add('bg-blue-50','border-blue-200');
      items[focus].scrollIntoView({block:'nearest'});
    }
  }

  // Click ngoài hộp -> ẩn (SAFE: guard null)
  document.addEventListener('click', (e) => {
    // nếu không có container searchBox (vì layout khác) thì thôi
    if (!searchBox) return;
    if (!searchBox.contains(e.target)) hide();
  });
})();
</script>

