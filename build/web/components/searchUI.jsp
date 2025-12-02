<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%
  String ep = request.getParameter("endpoint");
  if (ep == null || ep.isBlank()) ep = request.getContextPath() + "/api/search.jsp";
  String base = request.getContextPath();
%>

<!-- CHỈ LÀ PHẦN RUỘT CỦA Ô SEARCH – KHÔNG TỰ ẨN/HIỆN MD Ở ĐÂY -->
<div class="relative w-full" id="searchBox">
  <form action="<%=base%>/index.jsp" method="get" class="w-full" id="searchForm">
    <div class="relative flex items-center">
      <input
        type="text"
        id="searchInput"
        name="search"
        placeholder="Tìm sách theo tên, tác giả, thể loại, năm"
        value="<%= request.getParameter("search")==null ? "" : request.getParameter("search") %>"
        autocomplete="off"
        class="w-full bg-transparent border-0 outline-none
               px-4 pr-11 py-2
               text-sm md:text-base text-white placeholder-white/60
               focus:ring-0 focus:outline-none"
      >
      <!-- Nút search hình tròn ở mép phải -->
      <button
        type="submit"
        class="absolute right-2 top-1/2 -translate-y-1/2
               inline-flex items-center justify-center
               h-8 w-8 rounded-full
               bg-amber-400 text-slate-900
               shadow-md shadow-amber-500/60
               hover:bg-amber-300 transition-colors"
      >
        <i class="fas fa-search text-sm"></i>
      </button>

      <!-- icon loading -->
      <div
        id="searchLoading"
        class="absolute right-12 top-1/2 -translate-y-1/2 hidden"
      >
        <i class="fas fa-spinner fa-spin text-white text-sm"></i>
      </div>
    </div>
  </form>

  <!-- Hộp gợi ý kết quả -->
  <div
     id="suggestionsBox"
     class="absolute top-full mt-2 w-full bg-white rounded-lg shadow-xl
            max-h-80 overflow-y-auto hidden z-50 border border-gray-200"
     style="color:#111;"
  >
    <div id="suggestionsBoxContent"></div>

    <div id="noResults"
         class="px-4 py-3 text-gray-500 text-center hidden">
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
  const ENDPOINT = "<%= request.getParameter("endpoint")==null||request.getParameter("endpoint").isBlank()
                      ? request.getContextPath()+"/api/search.jsp"
                      : request.getParameter("endpoint") %>";
  const BASE = "<%= request.getContextPath() %>";

  const searchInput  = document.getElementById('searchInput');
  const searchBox    = document.getElementById('searchBox');
  const suggestionsBox        = document.getElementById('suggestionsBox');
  const suggestionsBoxContent = document.getElementById('suggestionsBoxContent');
  const noResults             = document.getElementById('noResults');
  const searchLoading         = document.getElementById('searchLoading');

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
    const items = suggestionsBox.querySelectorAll('.suggestion-item');
    if (!items.length) return;

    if (e.key === 'ArrowDown') { e.preventDefault(); focus = (focus + 1) % items.length; active(items); }
    else if (e.key === 'ArrowUp') { e.preventDefault(); focus = (focus - 1 + items.length) % items.length; active(items); }
    else if (e.key === 'Enter') { if (focus > -1) { e.preventDefault(); items[focus].click(); } }
    else if (e.key === 'Escape') { hide(); searchInput.blur(); }
  });

  function normCover(path) {
    if (!path || !String(path).trim()) return BASE + "/images/default-cover.jpg";
    if (/^https?:\/\//i.test(path)) return path;
    if (path.startsWith(BASE + "/")) return path;
    if (path.startsWith("/")) return BASE + path;
    return BASE + "/" + path.replace(/^\.?\//, "");
  }
  
  function normalize(str) {
    return str
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "") // bỏ dấu
      .replace(/đ/g, "d")
      .replace(/Đ/g, "d")
      .toLowerCase();
  }

  function fuzzyMatch(text, query) {
    text  = normalize(text);
    query = normalize(query);
    const parts = query.split(/\s+/).filter(Boolean);
    let pos = 0;
    for (const part of parts) {
      pos = text.indexOf(part, pos);
      if (pos === -1) return false;
      pos += part.length;
    }
    return true;
  }

  function render(items, q) {
    suggestionsBoxContent.innerHTML = '';
    noResults.classList.add('hidden');
    focus = -1;
    if (!items.length) { showEmpty(); return; }

    const filtered = items.filter(b => {
      const t = (b.title || "") + " " + (b.author || "");
      return fuzzyMatch(t, q);
    });

    if (!filtered.length) { showEmpty(); return; }

    filtered.forEach(b => suggestionsBoxContent.appendChild(item(b, q)));
    suggestionsBox.classList.remove('hidden');
  }
  
  function item(b, q) {
    const div = document.createElement('div');
    div.className = 'suggestion-item flex items-center gap-3 px-4 py-3 hover:bg-gray-50 cursor-pointer border-b border-gray-100 last:border-b-0';

    const title  = highlight(b.title || '', q);
    const author = highlight(b.author || 'Không rõ tác giả', q);
    const year   = (b.publicationYear ?? 'N/A');

    const coverPath = normCover(b.coverImage);
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

    const normTxt = normalize(txt);
    const normQ = normalize(q);

    const idx = normTxt.indexOf(normQ);
    if (idx === -1) return txt;

    return (
      txt.substring(0, idx) +
      '<mark class="bg-yellow-300 text-slate-900 px-1 rounded">' +
      txt.substring(idx, idx + q.length) +
      '</mark>' +
      txt.substring(idx + q.length)
    );
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
      items[focus].scrollIntoView({ block: 'nearest' });
    }
  }


  document.addEventListener('click', (e) => {
    if (!searchBox) return;
    if (!searchBox.contains(e.target)) hide();
  });
})();

</script>
