<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <title>Sách đã mượn - Thư viện Sách</title>

  <!-- Tailwind CSS -->
  <script src="https://cdn.tailwindcss.com"></script>

  <!-- Font Awesome -->
  <link rel="stylesheet"
        href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css"/>

  <!-- Google Fonts -->
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap"
        rel="stylesheet"/>

  <!-- Favicon -->
  <link rel="icon" href="<%=request.getContextPath()%>/images/reading-book.png" type="image/x-icon"/>

  <!-- Global theme (dark, glass, shelf, profile, footer, ...) -->
  <link rel="stylesheet" href="style1.css"/>

  <style>
    body {
      font-family: 'Inter', system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    }

    /* Glass khối header chính */
    .borrow-header {
      border-radius: 1.75rem;
      border: 1px solid rgba(148,163,184,0.55);
      background:
              radial-gradient(circle at top left, rgba(59,130,246,0.40), rgba(129,140,248,0.92)),
              radial-gradient(circle at bottom right, rgba(15,23,42,0.98), rgba(15,23,42,1));
      box-shadow: 0 28px 80px rgba(15,23,42,0.95);
      position: relative;
      overflow: hidden;
    }
    .borrow-header::before {
      content: "";
      position: absolute;
      inset: -40%;
      background: radial-gradient(circle at top left, rgba(248,250,252,0.15), transparent 65%);
      opacity: 0.7;
      pointer-events: none;
    }
    .borrow-header-inner {
      position: relative;
      z-index: 1;
    }

    /* Nút back nhỏ – đồng bộ style glass tròn */
    .back-pill {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 0.4rem;
      padding: 0.40rem 0.95rem;
      border-radius: 9999px;
      border: 1px solid rgba(148,163,184,0.7);
      background: radial-gradient(circle at top left, rgba(15,23,42,0.98), rgba(15,23,42,0.92));
      color: #e5e7eb;
      font-size: 0.85rem;
      font-weight: 500;
      box-shadow: 0 16px 40px rgba(15,23,42,0.9);
      text-decoration: none;
      transition: transform 0.2s ease-out, box-shadow 0.2s ease-out, border-color 0.2s ease-out, background 0.2s ease-out;
    }
    .back-pill:hover {
      transform: translateY(-1px) scale(1.02);
      border-color: rgba(129,140,248,0.95);
      background: radial-gradient(circle at top left, rgba(79,70,229,0.98), rgba(37,99,235,0.98));
      box-shadow: 0 22px 55px rgba(37,99,235,0.9);
    }

    /* Stats card – dùng glass, đồng bộ profile-stat nhưng nhỏ hơn */
    .borrow-stat-card {
      border-radius: 1.25rem;
      background: radial-gradient(circle at top left, rgba(15,23,42,0.98), rgba(15,23,42,0.92));
      border: 1px solid rgba(148,163,184,0.45);
      box-shadow: 0 18px 45px rgba(15,23,42,0.9);
      padding: 1.1rem 1.2rem;
      display: flex;
      flex-direction: column;
      gap: 0.25rem;
    }
    .borrow-stat-label {
      font-size: 0.80rem;
      color: #9ca3af;
    }
    .borrow-stat-value {
      font-size: 1.5rem;
      font-weight: 700;
      color: #f9fafb;
    }

    /* Glass container cho table */
    .borrow-table-wrap {
      border-radius: 1.75rem;
      background: radial-gradient(circle at top left, rgba(15,23,42,0.98), rgba(15,23,42,0.92));
      border: 1px solid rgba(148,163,184,0.50);
      box-shadow: 0 26px 70px rgba(15,23,42,0.95);
      overflow: hidden;
    }

    .borrow-table-head {
      background: radial-gradient(circle at top left, rgba(37,99,235,0.95), rgba(30,64,175,1));
      box-shadow: inset 0 -1px 0 rgba(248,250,252,0.16);
    }

    /* Table row hover */
    #borrowTable tbody tr {
      transition: background 0.18s ease-out, transform 0.18s ease-out;
    }
    #borrowTable tbody tr:hover {
      background: rgba(15,23,42,0.9);
      transform: translateY(-1px);
    }

    /* Pagination glass */
    .borrow-pagination-btn {
      border-radius: 9999px;
      border-width: 1px;
      border-style: solid;
      padding: 0.4rem 0.9rem;
      font-size: 0.85rem;
      font-weight: 500;
      transition: all 0.2s ease-out;
    }

    /* Đẩy footer xuống dưới chút */
    main {
      min-height: calc(100vh - 220px);
    }
  </style>
</head>

<body class="page-background">

<!-- Floating Background Elements (nhẹ, đồng bộ các trang khác) -->
<div class="floating-elements">
  <i class="fas fa-book floating-book text-6xl text-blue-500"
     style="top: 10%; left: 82%; animation-delay: 0s;"></i>
  <i class="fas fa-bookmark floating-book text-5xl text-purple-500"
     style="top: 18%; left: 8%; animation-delay: 2s;"></i>
  <i class="fas fa-feather floating-book text-5xl text-emerald-500"
     style="top: 55%; left: 88%; animation-delay: 4s;"></i>
  <i class="fas fa-scroll floating-book text-4xl text-orange-500"
     style="top: 78%; left: 6%; animation-delay: 6s;"></i>
</div>

<jsp:include page="layout/header.jsp"/>

<main class="container-enhanced py-10">
  <div id="app-content" class="space-y-8">

    <!-- Back nhỏ trên cùng -->
    <div class="flex justify-between items-center mb-3">
      <a href="<%=request.getContextPath()%>/index.jsp" class="back-pill">
        <i class="fas fa-arrow-left text-xs"></i>
        <span>Quay lại trang chủ</span>
      </a>
      <!-- chừa chỗ nếu sau này muốn thêm nút gì đó bên phải -->
      <div></div>
    </div>

    <!-- Header glass chính -->
    <section class="borrow-header px-6 py-6 md:px-8 md:py-7">
      <div class="borrow-header-inner flex flex-col md:flex-row md:items-center gap-6">
        <!-- Icon + Title -->
        <div class="flex items-start gap-4 flex-1">
          <div
            class="w-14 h-14 md:w-16 md:h-16 rounded-2xl bg-white/10 border border-blue-200/40 flex items-center justify-center shadow-2xl">
            <i class="fas fa-book-open text-2xl md:text-3xl text-yellow-300"></i>
          </div>
          <div>
            <h1 class="text-3xl md:text-4xl font-extrabold text-white tracking-tight mb-1">
              Sách đã mượn
            </h1>
            <p class="text-slate-200 text-sm md:text-base max-w-xl">
              Theo dõi trạng thái các sách bạn đã đăng ký mượn, đang mượn, quá hạn hoặc đã trả.
            </p>
            <div class="mt-3 flex flex-wrap items-center gap-2 text-xs text-slate-200/80">
              <span class="inline-flex items-center px-3 py-1 rounded-full bg-white/10 border border-white/20">
                <i class="fas fa-layer-group mr-2 text-amber-300"></i>
                Tổng: <span id="totalBorrowCount" class="ml-1 font-semibold">0</span> lượt mượn
              </span>

            </div>
          </div>
        </div>

        <!-- Mini legend -->
        <div class="grid grid-cols-2 gap-3 text-xs text-slate-100 md:w-64">
          <div class="flex items-center gap-2">
            <span class="w-2.5 h-2.5 rounded-full bg-yellow-400"></span>
            <span>Chờ duyệt</span>
          </div>
          <div class="flex items-center gap-2">
            <span class="w-2.5 h-2.5 rounded-full bg-green-400"></span>
            <span>Đang mượn</span>
          </div>
          <div class="flex items-center gap-2">
            <span class="w-2.5 h-2.5 rounded-full bg-red-400"></span>
            <span>Quá hạn</span>
          </div>
          <div class="flex items-center gap-2">
            <span class="w-2.5 h-2.5 rounded-full bg-blue-400"></span>
            <span>Đã trả</span>
          </div>
        </div>
      </div>
    </section>

    <!-- Thống kê -->
    <section>
      <div id="stats"
           class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <!-- JS sẽ render -->
      </div>
    </section>

    <!-- Bảng danh sách mượn -->
    <section class="borrow-table-wrap">
      <!-- Header bảng -->
      <div class="borrow-table-head px-6 py-4">
        <h3 class="text-lg md:text-xl font-semibold text-white flex items-center gap-2">
          <i class="fas fa-list-ul"></i>
          <span>Danh sách sách đã mượn</span>
        </h3>
        <p class="text-xs md:text-sm text-blue-100/90 mt-1">
          Bạn có thể hủy các yêu cầu <span class="font-semibold">chờ duyệt</span> trực tiếp tại đây.
        </p>
      </div>

      <!-- Table -->
      <div class="table-container overflow-x-auto bg-slate-950/40">
        <table class="min-w-full text-sm text-left text-slate-100/90" id="borrowTable">
          <thead class="bg-slate-900/90 text-xs uppercase tracking-wider text-slate-300">
          <tr>
            <th class="px-6 py-3 font-semibold">ISBN</th>
            <th class="px-6 py-3 font-semibold">Tên sách</th>
            <th class="px-6 py-3 font-semibold">Ngày mượn</th>
            <th class="px-6 py-3 font-semibold">Hạn trả</th>
            <th class="px-6 py-3 font-semibold">Ngày trả</th>
            <th class="px-6 py-3 font-semibold">Trạng thái</th>
            <th class="px-6 py-3 font-semibold text-center">Hành động</th>
          </tr>
          </thead>
          <tbody id="borrowBody" class="divide-y divide-slate-800/80">
          <!-- JS render -->
          </tbody>
        </table>
      </div>
    </section>

    <!-- Pagination -->
    <section class="flex justify-center items-center mt-5 mb-10">
      <div id="pagination"
           class="inline-flex flex-wrap justify-center items-center gap-2">
        <!-- JS render -->
      </div>
    </section>

  </div>
</main>

<jsp:include page="layout/footer.jsp"/>

<script>window.CTX = '<%=request.getContextPath()%>';</script>

<script>
const PAGE_SIZE = 10;          // số bản ghi mỗi trang
let allBorrowItems = [];       // mảng đầy đủ để phân trang
let currentPage = 1;

function statusBadge(status) {
  if (status === "Pending Approval") return '<span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-yellow-500/15 text-yellow-300 border border-yellow-400/40"><span class="w-1.5 h-1.5 rounded-full bg-yellow-300 mr-2"></span>Chờ duyệt</span>';
  if (status === "Borrowed")         return '<span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-emerald-500/15 text-emerald-300 border border-emerald-400/40"><span class="w-1.5 h-1.5 rounded-full bg-emerald-300 mr-2"></span>Đang mượn</span>';
  if (status === "Overdue")          return '<span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-red-500/15 text-red-300 border border-red-400/40"><span class="w-1.5 h-1.5 rounded-full bg-red-300 mr-2"></span>Quá hạn</span>';
  if (status === "Returned")         return '<span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-sky-500/15 text-sky-300 border border-sky-400/40"><span class="w-1.5 h-1.5 rounded-full bg-sky-300 mr-2"></span>Đã trả</span>';
  if (status === "Rejected")          return '<span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-red-500/15 text-red-300 border border-red-400/40"><span class="w-1.5 h-1.5 rounded-full bg-red-300 mr-2"></span>Bị từ chối</span>';
  if (status === "Cancelled")          return '<span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-slate-500/20 text-slate-200 border border-slate-400/40"><span class="w-1.5 h-1.5 rounded-full bg-red-300 mr-2"></span>Đã hủy</span>';
  return '<span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-slate-500/20 text-slate-200 border border-slate-400/40">'+(status || 'Không rõ')+'</span>';
}

function fmt(d){
  if (!d) return "—";
  const t = new Date(d);
  return t.toLocaleDateString("vi-VN");
}

function renderStats(items){
  let pending=0, borrowed=0, overdue=0, returned=0;
  items.forEach(it=>{
    if(it.status==="Pending Approval") pending++;
    else if(it.status==="Borrowed") borrowed++;
    else if(it.status==="Overdue") overdue++;
    else if(it.status==="Returned") returned++;
  });
  const total=items.length;

  // cập nhật tổng trên header
  const totalSpan = document.getElementById("totalBorrowCount");
  if (totalSpan) totalSpan.textContent = total;

  document.getElementById("stats").innerHTML = `
    <div class="borrow-stat-card">
      <p class="borrow-stat-label">Tổng số lượt mượn</p>
      <p class="borrow-stat-value">${total}</p>
      <p class="text-xs text-slate-400 mt-1 flex items-center gap-1">
        <i class="fas fa-circle text-emerald-400 text-[6px]"></i>
        Bao gồm tất cả trạng thái
      </p>
    </div>
    <div class="borrow-stat-card">
      <p class="borrow-stat-label">Chờ duyệt</p>
      <p class="borrow-stat-value text-amber-300">${pending}</p>
      <p class="text-xs text-slate-400 mt-1">Yêu cầu đang đợi Admin xác nhận</p>
    </div>
    <div class="borrow-stat-card">
      <p class="borrow-stat-label">Đang mượn</p>
      <p class="borrow-stat-value text-emerald-300">${borrowed}</p>
      <p class="text-xs text-slate-400 mt-1">Sách bạn đang giữ</p>
    </div>
    <div class="borrow-stat-card">
      <p class="borrow-stat-label">Quá hạn</p>
      <p class="borrow-stat-value text-red-300">${overdue}</p>
      <p class="text-xs text-slate-400 mt-1">Cần trả hoặc gia hạn ngay</p>
    </div>
  `;
}

function normalizeItems(rawItems){
  if (!Array.isArray(rawItems)) return [];
  return rawItems.map(it => {
    const borrowId = Number(
      it.borrowId ?? it.borrow_id ?? it.id ?? it.BorrowId ?? it.borrowID ?? 0
    );
    return {
      borrowId: Number.isFinite(borrowId) ? borrowId : 0,
      isbn: it.isbn ?? "",
      title: it.title ?? "",
      borrowedDate: it.borrowedDate ?? it.borrowed_date ?? null,
      dueDate:      it.dueDate ?? it.due_date ?? null,
      returnDate:   it.returnDate ?? it.return_date ?? null,
      status: (it.status ?? "").trim()
    };
  });
}

function renderTable(items){
  const body = document.getElementById("borrowBody");
  if(!Array.isArray(items) || items.length === 0){
    body.innerHTML = `<tr>
        <td colspan="7" class="text-center py-8 text-slate-400">
          Bạn chưa mượn sách nào.
        </td>
      </tr>`;
    return;
  }

  body.innerHTML = items.map(it => {
    const bid = Number(
      it.borrowId ?? it.borrow_id ?? it.id ?? it.BorrowId ?? it.borrowID ?? 0
    );
    const safeBid = Number.isInteger(bid) && bid > 0 ? bid : 0;

    const actionHtml = (it.status === "Pending Approval" && safeBid > 0)
      ? '<button class="btn-cancel px-3 py-1 rounded-full text-xs font-semibold bg-red-500/15 text-red-300 border border-red-400/60 hover:bg-red-500/30 transition" data-borrow-id="'+safeBid+'"><i class="fas fa-times mr-1"></i>Hủy</button>'
      : '<span class="text-slate-500 text-xs">—</span>';

    return `
      <tr>
        <td class="px-6 py-4 font-mono text-xs text-slate-300">\${it.isbn ?? ""}</td>
        <td class="px-6 py-4 text-sm text-slate-100">\${it.title ?? ""}</td>
        <td class="px-6 py-4 text-sm text-slate-200">\${fmt(it.borrowedDate)}</td>
        <td class="px-6 py-4 text-sm text-slate-200">\${fmt(it.dueDate)}</td>
        <td class="px-6 py-4 text-sm text-slate-200">\${it.returnDate ? fmt(it.returnDate) : 'Chưa trả'}</td>
        <td class="px-6 py-4 text-sm">\${statusBadge(it.status)}</td>
        <td class="px-6 py-4 text-center">\${actionHtml}</td>
      </tr>
    `;
  }).join("");
}

function renderPage(page) {
  const total = allBorrowItems.length;
  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  if (total === 0) {
    renderTable([]);
    renderPagination(0);
    return;
  }

  let p = page;
  if (p < 1) p = 1;
  if (p > totalPages) p = totalPages;
  currentPage = p;

  const start = (p - 1) * PAGE_SIZE;
  const end   = start + PAGE_SIZE;
  const pageItems = allBorrowItems.slice(start, end);

  renderTable(pageItems);
  renderPagination(total);
}

function renderPagination(totalItems) {
  const container = document.getElementById("pagination");
  if (!container) return;

  if (!totalItems || totalItems <= 0) {
    container.innerHTML = "";
    return;
  }

  const totalPages = Math.max(1, Math.ceil(totalItems / PAGE_SIZE));
  let html = "";

  // Prev
  const prevPage = currentPage - 1;
  html += '<button data-page="' + prevPage + '" ' +
    (currentPage === 1 ? 'disabled ' : '') +
    'class="borrow-pagination-btn border-slate-600 bg-slate-800 text-slate-200 ' +
    (currentPage === 1 ? 'opacity-40 cursor-not-allowed' : 'hover:bg-slate-700') +
    '">&laquo;</button>';

  // Page numbers
  for (let p = 1; p <= totalPages; p++) {
    html += '<button data-page="' + p + '" class="borrow-pagination-btn ' +
      (p === currentPage
        ? 'bg-blue-600 border-blue-400 text-white shadow-lg'
        : 'bg-slate-800 border-slate-600 text-slate-200 hover:bg-slate-700'
      ) +
      '">' + p + '</button>';
  }

  // Next
  const nextPage = currentPage + 1;
  html += '<button data-page="' + nextPage + '" ' +
    (currentPage === totalPages ? 'disabled ' : '') +
    'class="borrow-pagination-btn border-slate-600 bg-slate-800 text-slate-200 ' +
    (currentPage === totalPages ? 'opacity-40 cursor-not-allowed' : 'hover:bg-slate-700') +
    '">&raquo;</button>';

  container.innerHTML = html;
}

// Click pagination
document.getElementById("pagination").addEventListener("click", (e) => {
  const btn = e.target.closest("button[data-page]");
  if (!btn) return;

  const page = parseInt(btn.dataset.page, 10);
  const totalPages = Math.max(1, Math.ceil(allBorrowItems.length / PAGE_SIZE));

  if (!Number.isInteger(page) || page < 1 || page > totalPages) return;
  renderPage(page);
});

// Delegation cho nút Hủy
document.getElementById("borrowBody").addEventListener("click", async (e) => {
  const btn = e.target.closest(".btn-cancel");
  if (!btn) return;

  const raw = btn.dataset.borrowId ?? btn.getAttribute("data-borrow-id") ?? "";
  const id  = parseInt(raw, 10);

  if (!Number.isInteger(id) || id <= 0) {
    showToast("ID hủy không hợp lệ");
    return;
  }

  const ok = await confirmPopup("Bạn có chắc muốn hủy mượn sách này?");
  if (!ok) return;
  await cancelBorrow(id);
});

// Cancel API
async function cancelBorrow(borrowId) {
  const token = localStorage.getItem("token");
  if (!token) {
    showToast("Bạn cần đăng nhập");
    setTimeout(()=>location.href = CTX + "/user/login.jsp", 1200);
    return;
  }
  try {
    const r = await fetch(CTX + "/api/borrow/cancel", {
      method: "POST",
      headers: {
        "Authorization": "Bearer " + token,
        "Content-Type": "application/json; charset=UTF-8",
        "Accept": "application/json"
      },
      body: JSON.stringify({ borrowId: Number(borrowId) })
    });

    const ct = r.headers.get("content-type") || "";
    const data = ct.includes("application/json") ? await r.json() : { message: await r.text() };

    if (!r.ok) { showToast(data.message || ("Hủy thất bại: " + r.status)); return; }
    showToast(data.message || "Đã hủy yêu cầu mượn");
    setTimeout(()=>location.reload(), 1200);
  } catch (e) {
    console.error(e);
    showToast("Không thể gọi API hủy mượn");
  }
}

// Init
(async function(){
  try{
    const data = await api.apiGet('/borrowed');
    const items = normalizeItems(data?.items);
    allBorrowItems = items;
    renderStats(items);
    renderPage(1);
  }catch(e){
    console.error(e);
    showToast("Không tải được dữ liệu mượn sách");
  }
})();
</script>

<!-- Confirm Modal -->
<div id="confirmModal" class="fixed inset-0 z-[100] hidden opacity-0 transition-opacity duration-300">
  <div class="absolute inset-0 bg-black/60 backdrop-blur-sm transition-opacity duration-300" id="modalBackdrop"></div>
  <div class="absolute inset-0 flex items-center justify-center p-4">
    <div class="bg-slate-900/95 border border-slate-600/80 rounded-2xl shadow-2xl w-full max-w-md transform scale-95 transition-transform duration-300"
         id="modalContent">
      <div class="px-5 py-4 border-b border-slate-700/80 flex items-center gap-2">
        <span
          class="w-8 h-8 rounded-full bg-red-500/15 border border-red-400/60 flex items-center justify-center text-red-300">
          <i class="fas fa-exclamation"></i>
        </span>
        <h3 class="text-lg font-semibold text-slate-50">Xác nhận</h3>
      </div>
      <div class="px-5 py-4">
        <p id="confirmMessage" class="text-slate-200 text-sm">
          Bạn có chắc muốn hủy mượn sách này?
        </p>
      </div>
      <div class="px-5 py-3 border-t border-slate-700/80 flex justify-end gap-2">
        <button id="confirmCancelBtn"
                class="px-4 py-2 rounded-lg bg-slate-800 text-slate-200 hover:bg-slate-700 text-sm transition-colors duration-200">
          Hủy
        </button>
        <button id="confirmOkBtn"
                class="px-4 py-2 rounded-lg bg-red-600 text-white hover:bg-red-700 text-sm transition-colors duration-200">
          Đồng ý
        </button>
      </div>
    </div>
  </div>
</div>

<!-- Toast -->
<div id="toast"
     class="fixed bottom-6 right-6 z-[110] hidden opacity-0 transform translate-x-4 transition-all duration-300">
  <div id="toastCard"
       class="bg-gradient-to-r from-blue-500 to-purple-600 text-white px-6 py-4 rounded-xl shadow-2xl border border-white/20 min-w-[300px] text-center flex items-center justify-center gap-3">
    <i class="fas fa-info-circle text-xl"></i>
    <span id="toastMessage" class="font-medium"></span>
  </div>
</div>

<script>
// Toast
function showToast(message, ms=4000){
  const wrap = document.getElementById('toast');
  const msgSpan = document.getElementById('toastMessage');
  msgSpan.textContent = message;
  wrap.classList.remove('hidden');
  setTimeout(() => {
    wrap.classList.remove('opacity-0', 'translate-x-4');
  }, 10);
  clearTimeout(showToast._t);
  showToast._t = setTimeout(() => {
    wrap.classList.add('opacity-0', 'translate-x-4');
    setTimeout(() => wrap.classList.add('hidden'), 300);
  }, ms);
}

// Confirm popup Promise<boolean>
function confirmPopup(message = "Bạn có chắc?") {
  return new Promise(resolve => {
    const modal = document.getElementById('confirmModal');
    const backdrop = document.getElementById('modalBackdrop');
    const content = document.getElementById('modalContent');
    const msg   = document.getElementById('confirmMessage');
    const btnOk = document.getElementById('confirmOkBtn');
    const btnNo = document.getElementById('confirmCancelBtn');

    function close(v){
      modal.classList.add('opacity-0');
      content.classList.add('scale-95');
      backdrop.classList.add('opacity-0');
      setTimeout(() => {
        modal.classList.add('hidden');
        btnOk.removeEventListener('click', onOk);
        btnNo.removeEventListener('click', onNo);
        resolve(v);
      }, 300);
    }
    function onOk(){ close(true); }
    function onNo(){ close(false); }

    msg.textContent = message;
    modal.classList.remove('hidden');
    setTimeout(() => {
      modal.classList.remove('opacity-0');
      content.classList.remove('scale-95');
      backdrop.classList.remove('opacity-0');
    }, 10);
    btnOk.addEventListener('click', onOk);
    btnNo.addEventListener('click', onNo);
  });
}
</script>

</body>
</html>
