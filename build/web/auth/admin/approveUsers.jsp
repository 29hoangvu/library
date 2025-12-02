<%@ page contentType="text/html; charset=UTF-8" language="java"
         buffer="64kb" autoFlush="true" errorPage="/error.jsp" %>
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Duyệt Tài Khoản</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
  <script>
    tailwind.config = {
      theme: {
        extend: {
          colors: {
            primary: {
              50: '#f0f9ff',
              100: '#e0f2fe',
              500: '#0ea5e9',
              600: '#0284c7',
              700: '#0369a1',
            }
          },
          boxShadow: {
            'soft': '0 4px 20px -2px rgba(0, 0, 0, 0.08)',
            'medium': '0 8px 30px rgba(0, 0, 0, 0.12)',
          },
          animation: {
            'fade-in': 'fadeIn 0.5s ease-in-out',
            'slide-up': 'slideUp 0.4s ease-out',
            'pulse-subtle': 'pulseSubtle 2s ease-in-out infinite',
          }
        }
      }
    }
  </script>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');
    body {
      font-family: 'Inter', sans-serif;
    }
    
    @keyframes fadeIn {
      from { opacity: 0; transform: translateY(10px); }
      to { opacity: 1; transform: translateY(0); }
    }
    
    @keyframes slideUp {
      from { opacity: 0; transform: translateY(20px); }
      to { opacity: 1; transform: translateY(0); }
    }
    
    @keyframes pulseSubtle {
      0%, 100% { opacity: 1; }
      50% { opacity: 0.8; }
    }
    
    .status-badge {
      animation: pulseSubtle 2s ease-in-out infinite;
    }
    
    .table-row-hover:hover {
      transform: translateY(-1px);
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
    }
  </style>
</head>
<body class="bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-50 min-h-screen">
  <%@ include file="../includes/header.jsp" %>

  <div class="container mx-auto px-4 py-8 mt-24">
    <!-- Header Section -->
    <div class="text-center mb-8 animate-fade-in">
      <div class="inline-flex items-center justify-center w-20 h-20 bg-gradient-to-r from-indigo-500 to-purple-600 rounded-full text-white mb-4 shadow-lg">
        <i class="fas fa-user-check text-2xl"></i>
      </div>
      <h1 class="text-3xl font-bold bg-gradient-to-r from-purple-600 to-blue-600 bg-clip-text text-transparent mb-2">
        Duyệt Đơn Đăng Ký
      </h1>
      <p class="text-gray-600 max-w-md mx-auto">Quản lý và phê duyệt tài khoản người dùng mới đăng ký</p>
    </div>

    <!-- Main Card -->
    <div class="max-w-6xl mx-auto bg-white/90 backdrop-blur rounded-2xl shadow-medium overflow-hidden animate-slide-up">
      <!-- Card Header -->
      <div class="flex flex-col sm:flex-row items-center justify-between px-6 py-4 bg-gradient-to-r from-indigo-500 to-purple-600 text-white">
        <div class="flex items-center gap-3 mb-3 sm:mb-0">
          <div class="bg-white/20 p-2 rounded-lg">
            <i class="fas fa-clipboard-list text-lg"></i>
          </div>
          <div>
            <h2 class="font-semibold text-lg">Danh sách chờ duyệt</h2>
            <p class="text-white/80 text-sm">Các tài khoản mới đang chờ xét duyệt</p>
          </div>
        </div>
        <div id="pending-count" class="status-badge bg-white/20 px-4 py-2 rounded-full font-medium flex items-center gap-2">
          <i class="fas fa-clock"></i>
          <span>Đang tải...</span>
        </div>
      </div>

      <!-- Table Section -->
      <div class="p-6">
        <!-- Stats Overview -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
          <div class="bg-gradient-to-br from-blue-50 to-indigo-50 border border-blue-100 rounded-xl p-4 text-center">
            <div class="text-2xl font-bold text-blue-600" id="total-pending">0</div>
            <div class="text-sm text-blue-600 font-medium">Tổng đơn chờ</div>
          </div>
          <div class="bg-gradient-to-br from-green-50 to-emerald-50 border border-green-100 rounded-xl p-4 text-center">
            <div class="text-2xl font-bold text-green-600" id="approved-today">0</div>
            <div class="text-sm text-green-600 font-medium">Đã duyệt hôm nay</div>
          </div>
          <div class="bg-gradient-to-br from-amber-50 to-orange-50 border border-amber-100 rounded-xl p-4 text-center">
            <div class="text-2xl font-bold text-amber-600" id="avg-processing">0h</div>
            <div class="text-sm text-amber-600 font-medium">Thời gian xử lý TB</div>
          </div>
        </div>

        <div class="overflow-x-auto rounded-xl border border-gray-200 shadow-sm">
          <table class="w-full text-sm">
            <thead class="bg-gradient-to-r from-gray-50 to-gray-100">
              <tr>
                <th class="text-left px-6 py-4 font-semibold text-gray-700 uppercase text-xs">
                  <div class="flex items-center gap-2">
                    <i class="fas fa-hashtag text-gray-500"></i>
                    ID
                  </div>
                </th>
                <th class="text-left px-6 py-4 font-semibold text-gray-700 uppercase text-xs">
                  <div class="flex items-center gap-2">
                    <i class="fas fa-user text-gray-500"></i>
                    Tên người dùng
                  </div>
                </th>
                <th class="text-left px-6 py-4 font-semibold text-gray-700 uppercase text-xs">
                  <div class="flex items-center gap-2">
                    <i class="fas fa-envelope text-gray-500"></i>
                    Email
                  </div>
                </th>
                <th class="text-left px-6 py-4 font-semibold text-gray-700 uppercase text-xs">
                  <div class="flex items-center gap-2">
                    <i class="fas fa-calendar text-gray-500"></i>
                    Ngày đăng ký
                  </div>
                </th>
                <th class="text-center px-6 py-4 font-semibold text-gray-700 uppercase text-xs">
                  <div class="flex items-center gap-2 justify-center">
                    <i class="fas fa-cog text-gray-500"></i>
                    Hành động
                  </div>
                </th>
              </tr>
            </thead>
            <tbody id="tbody" class="divide-y divide-gray-200"></tbody>
          </table>
        </div>

        <!-- Empty State -->
        <div id="emptyState" class="hidden text-center py-12">
          <div class="bg-gradient-to-br from-gray-100 to-gray-200 w-20 h-20 rounded-full flex items-center justify-center mx-auto mb-4">
            <i class="fas fa-user-check text-3xl text-gray-400"></i>
          </div>
          <h3 class="text-lg font-semibold text-gray-600 mb-2">Không có đơn đăng ký nào</h3>
          <p class="text-gray-500 max-w-sm mx-auto">Tất cả các đơn đăng ký đã được xử lý. Vui lòng kiểm tra lại sau.</p>
        </div>

        <!-- Pagination -->
        <div class="flex flex-col sm:flex-row items-center justify-between mt-6 gap-4">
          <div id="pagInfo" class="text-sm text-gray-600 bg-gray-50 px-4 py-2 rounded-lg"></div>
          <div class="flex items-center gap-2">
            <button id="prevBtn" class="px-4 py-2 border border-gray-300 rounded-lg bg-white hover:bg-gray-50 transition-colors flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed">
              <i class="fas fa-chevron-left"></i>
              <span>Trước</span>
            </button>
            <div id="pageNums" class="flex items-center gap-1"></div>
            <button id="nextBtn" class="px-4 py-2 border border-gray-300 rounded-lg bg-white hover:bg-gray-50 transition-colors flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed">
              <span>Sau</span>
              <i class="fas fa-chevron-right"></i>
            </button>
            <div class="ml-3 flex items-center gap-2">
              <span class="text-sm text-gray-600">Hiển thị:</span>
              <select id="sizeSel" class="px-3 py-2 border border-gray-300 rounded-lg bg-white focus:ring-2 focus:ring-primary-500 focus:border-primary-500">
                <option>10</option><option>20</option><option>50</option>
              </select>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- Toast Container -->
  <div id="toastContainer" class="fixed bottom-5 right-5 z-[9999] flex flex-col gap-3 pointer-events-none"></div>

  <script>
    const CTX = "<%=request.getContextPath()%>";
    const apiList  = CTX + "/api/admin/pending-users";
    const apiReview = CTX + "/api/admin/review-user";

    // state
    let page = 1, size = 10, totalPages = 1, total = 0;

    const tbody = document.getElementById("tbody");
    const pagInfo = document.getElementById("pagInfo");
    const prevBtn = document.getElementById("prevBtn");
    const nextBtn = document.getElementById("nextBtn");
    const pageNums = document.getElementById("pageNums");
    const sizeSel = document.getElementById("sizeSel");
    const emptyState = document.getElementById("emptyState");
    sizeSel.value = String(size);

    // Toast function
    function showToast(message, type = "info", duration = 3000) {
        const container = document.getElementById("toastContainer");
        const toast = document.createElement("div");

        const styles = {
          success: "bg-gradient-to-r from-green-500 to-emerald-600 text-white",
          error:   "bg-gradient-to-r from-red-500 to-rose-600 text-white",
          warning: "bg-gradient-to-r from-amber-500 to-orange-500 text-white",
          info:    "bg-gradient-to-r from-blue-500 to-indigo-600 text-white"
        };
        const icons = {
          success: "fa-check-circle",
          error:   "fa-exclamation-triangle",
          warning: "fa-exclamation-circle",
          info:    "fa-info-circle"
        };

        toast.className =
          "pointer-events-auto max-w-sm rounded-xl shadow-lg px-4 py-3 ring-1 ring-black/10 " +
          (styles[type] || styles.info) +
          " transition-all duration-300 opacity-0 translate-y-3 animate-fade-in";

        toast.innerHTML =
          '<div class="flex items-center gap-3">' +
            '<i class="fas ' + (icons[type] || icons.info) + ' text-lg"></i>' +
            '<span class="flex-1">' + message + '</span>' +
            '<button class="text-white/80 hover:text-white ml-2" onclick="this.parentElement.parentElement.remove()">' +
              '<i class="fas fa-times"></i>' +
            '</button>' +
          '</div>';

        container.appendChild(toast);
        requestAnimationFrame(function () {
          toast.classList.remove("opacity-0","translate-y-3");
          toast.classList.add("opacity-100","translate-y-0");
        });
        setTimeout(function(){
          toast.classList.add("opacity-0","translate-y-3");
          setTimeout(function(){ toast.remove(); }, 300);
        }, duration);
    }

    async function fetchList() {
        try {
            const url = new URL(apiList, location.origin);
            url.search = new URLSearchParams({ page: String(page), size: String(size) }).toString();

            const token = localStorage.getItem("token");
            const data = await fetchJson(url.href, {
              headers: {
                "Accept": "application/json",
                ...(token ? { "Authorization": "Bearer " + token } : {})
              }
            });

            console.log("[data]", data);

            total = data.total || 0;
            totalPages = data.totalPages || 1;

            // Update counters
            const pc = document.getElementById("pending-count");
            if (pc) {
                pc.innerHTML = '<i class="fas fa-clock"></i><span>' + total + ' đang chờ</span>';
              }

            // Update stats (mock data - bạn có thể thay bằng dữ liệu thực từ API)
            document.getElementById("total-pending").textContent = total;
            document.getElementById("approved-today").textContent = Math.floor(total * 0.3); // Mock
            document.getElementById("avg-processing").textContent = "2.5h"; // Mock

            renderRows(data.items || []);
            renderPag();

        } catch (e) {
          console.error(e);
          const pc = document.getElementById("pending-count");
          if (pc) pc.innerHTML = '<i class="fas fa-exclamation-triangle"></i><span>Lỗi tải</span>';
          showToast(e.message || "Không tải được danh sách", "error");
        }
    }

    function renderRows(items){
        tbody.innerHTML = "";
        if (!Array.isArray(items) || items.length === 0){
          emptyState.classList.remove("hidden");
          return;
        }
        emptyState.classList.add("hidden");

        items.forEach(function(u, idx){
          var id       = (u && (u.id || u.ID || u.userID)) || "";
          var username = (u && (u.username || u.userName || u.fullname || u.fullName)) || "";
          var email    = (u && (u.email || u.mail)) || "";
          var regDate  = (u && (u.registrationDate || u.createdAt || u.createdDate)) || "N/A";

          var tr = document.createElement("tr");
          tr.className = "bg-white hover:bg-blue-50 transition-all duration-200 table-row-hover animate-fade-in";
          tr.style.animationDelay = (idx * 0.05) + "s";

          tr.innerHTML =
            '<td class="px-6 py-4 font-medium text-gray-900">' +
              '<div class="flex items-center gap-2">' +
                '<span class="bg-primary-100 text-primary-800 px-2 py-1 rounded text-xs font-mono">#' + String(id) + '</span>' +
              '</div>' +
            '</td>' +
            '<td class="px-6 py-4">' +
              '<div class="flex items-center gap-3">' +
                '<div class="w-8 h-8 bg-gradient-to-r from-primary-500 to-primary-600 rounded-full flex items-center justify-center text-white text-sm">' +
                  (username ? username.charAt(0).toUpperCase() : '?') +
                '</div>' +
                '<span class="font-medium text-gray-800">' + String(username) + '</span>' +
              '</div>' +
            '</td>' +
            '<td class="px-6 py-4 text-gray-600">' + String(email) + '</td>' +
            '<td class="px-6 py-4 text-gray-500 text-sm">' + formatDate(regDate) + '</td>' +
            '<td class="px-6 py-4">' +
              '<div class="flex items-center justify-center gap-2">' +
                '<button class="approve px-4 py-2 rounded-lg bg-gradient-to-r from-emerald-500 to-green-600 text-white font-medium hover:from-emerald-600 hover:to-red-700 transition-all duration-200 shadow-md hover:shadow-lg flex items-center gap-2 group">' +
                  '<i class="fas fa-check group-hover:scale-110 transition-transform"></i>' +
                  '<span>Duyệt</span>' +
                '</button>' +
                '<button class="reject px-4 py-2 rounded-lg bg-gradient-to-r from-rose-500 to-red-600 text-white font-medium hover:from-rose-600 hover:to-red-700 transition-all duration-200 shadow-md hover:shadow-lg flex items-center gap-2 group">' +
                  '<i class="fas fa-times group-hover:scale-110 transition-transform"></i>' +
                  '<span>Từ chối</span>' +
                '</button>' +
              '</div>' +
            '</td>';

          tr.querySelector(".approve").addEventListener("click", function(){ review(id, "approve"); });
          tr.querySelector(".reject").addEventListener("click",  function(){ review(id, "reject");  });
          tbody.appendChild(tr);
        });
      }


    function formatDate(dateString) {
      if (!dateString || dateString === "N/A") return "N/A";
      try {
        const date = new Date(dateString);
        return date.toLocaleDateString('vi-VN');
      } catch {
        return dateString;
      }
    }

    function renderPag(){
        const start = total === 0 ? 0 : ((page - 1) * size + 1);
        const end   = Math.min(page * size, total);
        pagInfo.textContent = "Hiển thị " + start + "-" + end + " / " + total;

        prevBtn.disabled = page <= 1;
        nextBtn.disabled = page >= totalPages || totalPages === 0;

        pageNums.innerHTML = "";
        const win = calcWindow(page, totalPages, 7);
        win.forEach(p => {
          if (p === "…") {
            const span = document.createElement("span");
            span.className = "px-3 py-2 text-gray-400";
            span.textContent = "…";
            pageNums.appendChild(span);
          } else {
            const b = document.createElement("button");
            b.textContent = p;
            b.className =
              "px-3 py-2 border rounded-lg transition-all duration-200 " +
              (p === page ? 
                "bg-gradient-to-r from-primary-500 to-primary-600 text-white border-primary-600 shadow-md" : 
                "bg-white hover:bg-gray-50 border-gray-300");
            b.addEventListener("click", () => { 
              page = p; 
              fetchList(); 
              window.scrollTo({ top: 0, behavior: "smooth" }); 
            });
            pageNums.appendChild(b);
          }
        });
    }

    async function fetchJson(url, opt) {
        const r = await fetch(url, opt);
        const ct = (r.headers.get('content-type') || '').toLowerCase();
        console.log("[fetchJson]", r.status, r.url, ct);

        if (!ct.includes('application/json')) {
          const text = await r.text();
          console.warn("== Response preview ==", text.slice(0, 400));
          throw new Error(`Server trả về ${r.status}. Không phải JSON.`);
        }
        const data = await r.json();
        if (!r.ok || (data && data.ok === false)) {
          throw new Error((data && data.message) ? data.message : `HTTP ${r.status}`);
        }
        return data;
    }
      
    function calcWindow(cur,total,width){
      if (total<=width) return Array.from({length: total}, (_,i)=> i+1);
      const half = Math.floor(width/2);
      let start = Math.max(1, cur-half);
      let end   = Math.min(total, start+width-1);
      start = Math.max(1, end-width+1);
      const a=[];
      if (start>1){ a.push(1); if (start>2) a.push("…"); }
      for(let i=start;i<=end;i++) a.push(i);
      if (end<total){ if (end<total-1) a.push("…"); a.push(total); }
      return a;
    }

    async function review(userID, action) {
        try {
          const url = new URL(apiReview, location.origin);
          const token = localStorage.getItem("token");
          const body = new URLSearchParams({ userID: String(userID), action: String(action) });

          const data = await fetchJson(url.href, {
            method: "POST",
            headers: {
              "Accept": "application/json",
              "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
              ...(token ? { "Authorization": "Bearer " + token } : {})
            },
            body: body.toString()
          });

          showToast(data.message || "Thao tác thành công", "success");
          fetchList();
        } catch (e) {
          console.error(e);
          showToast(e.message || "Không thể kết nối máy chủ", "error");
        }
    }

    // Event listeners
    prevBtn.addEventListener("click", ()=>{ if (page>1){ page--; fetchList(); } });
    nextBtn.addEventListener("click", ()=>{ if (page<totalPages){ page++; fetchList(); } });
    sizeSel.addEventListener("change", ()=>{ size = parseInt(sizeSel.value,10)||10; page=1; fetchList(); });
    
    // Initialize
    fetchList();
  </script>
</body>
</html>