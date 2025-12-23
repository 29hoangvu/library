<%@ page contentType="text/html; charset=UTF-8" language="java"
         buffer="64kb" autoFlush="true" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <title>Đặt Trước Của Tôi - Thư viện</title>

    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="icon" href="./images/reading-book.png" type="image/x-icon"/>
    <link rel="stylesheet" href="style1.css"/>

    <style>
        .status-badge { display:inline-flex;align-items:center;padding:4px 10px;border-radius:999px;font-size:12px;font-weight:600 }
        .status-PENDING{background:rgba(59,130,246,.2);color:#93c5fd;border:1px solid rgba(59,130,246,.4)}
        .status-NOTIFIED{background:rgba(16,185,129,.2);color:#6ee7b7;border:1px solid rgba(16,185,129,.4)}
        .status-FULFILLED{background:rgba(168,85,247,.2);color:#d8b4fe;border:1px solid rgba(168,85,247,.4)}
        .status-CANCELLED{background:rgba(107,114,128,.2);color:#d1d5db;border:1px solid rgba(107,114,128,.4)}
        .status-EXPIRED{background:rgba(239,68,68,.2);color:#fca5a5;border:1px solid rgba(239,68,68,.4)}
        
        .loading-spinner {
            border: 3px solid rgba(148, 163, 184, 0.3);
            border-top-color: #3b82f6;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
        }
        
        @keyframes spin {
            to { transform: rotate(360deg); }
        }
    </style>
</head>

<body class="page-background">
<%@ include file="layout/header.jsp" %>

<main class="container-enhanced py-10 relative z-[1]">

    <!-- HEADER -->
    <div class="mb-8">
        <div class="flex items-center justify-between mb-4">
            <div>
                <h1 class="text-3xl md:text-4xl font-extrabold text-slate-50 mb-2">
                    <i class="fas fa-clock mr-3 text-amber-400"></i>
                    Sách Đặt Trước
                </h1>
                <p class="text-slate-400 text-sm">
                    Quản lý các sách bạn đã đặt trước khi hết sẵn
                </p>
            </div>
            <a href="user/myAccount.jsp"
               class="inline-flex items-center gap-2 px-4 py-2 rounded-xl border border-slate-600 bg-slate-900/80 text-slate-200 text-sm font-medium hover:border-sky-400 hover:text-white hover:bg-slate-800/90 transition">
                <i class="fas fa-arrow-left"></i>
                <span>Quay lại</span>
            </a>
        </div>
    </div>

    <!-- STATS -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
        <div class="glass-effect rounded-2xl p-[2px]"><div class="rounded-[1.3rem] bg-slate-950/95 p-5">
            <p class="text-slate-400 text-sm">Đang chờ</p>
            <p id="stat-pending" class="text-2xl font-bold text-slate-100">0</p>
        </div></div>
        <div class="glass-effect rounded-2xl p-[2px]"><div class="rounded-[1.3rem] bg-slate-950/95 p-5">
            <p class="text-slate-400 text-sm">Đã thông báo</p>
            <p id="stat-notified" class="text-2xl font-bold text-slate-100">0</p>
        </div></div>
        <div class="glass-effect rounded-2xl p-[2px]"><div class="rounded-[1.3rem] bg-slate-950/95 p-5">
            <p class="text-slate-400 text-sm">Đã hoàn thành</p>
            <p id="stat-fulfilled" class="text-2xl font-bold text-slate-100">0</p>
        </div></div>
        <div class="glass-effect rounded-2xl p-[2px]"><div class="rounded-[1.3rem] bg-slate-950/95 p-5">
            <p class="text-slate-400 text-sm">Tổng</p>
            <p id="stat-total" class="text-2xl font-bold text-slate-100">0</p>
        </div></div>
    </div>

    <!-- LIST -->
    <div class="glass-effect rounded-3xl p-[2px]">
        <div class="rounded-[1.5rem] bg-slate-950/95 p-6">
            <!-- Loading state -->
            <div id="loadingState" class="text-center py-12">
                <div class="loading-spinner mx-auto mb-4"></div>
                <p class="text-slate-400">Đang tải dữ liệu...</p>
            </div>

            <!-- Error state -->
            <div id="errorState" class="hidden text-center py-12">
                <i class="fas fa-exclamation-circle text-red-400 text-5xl mb-4"></i>
                <p id="errorMessage" class="text-red-300 text-lg mb-4">Có lỗi xảy ra</p>
                <button onclick="location.reload()" 
                        class="px-6 py-2.5 rounded-xl bg-gradient-to-r from-blue-500 to-indigo-600 text-white font-semibold">
                    <i class="fas fa-redo mr-2"></i>Thử lại
                </button>
            </div>

            <!-- Empty state -->
            <div id="emptyState" class="hidden text-center py-12 text-slate-400">
                <i class="fas fa-inbox text-slate-500 text-5xl mb-4"></i>
                <p class="text-lg mb-2">Chưa có đặt trước nào</p>
                <p class="text-sm mb-6">Bạn chưa đặt trước sách nào. Hãy khám phá thư viện!</p>
                <a href="index.jsp"
                   class="inline-flex gap-2 mt-6 px-6 py-2.5 rounded-xl bg-gradient-to-r from-blue-500 to-indigo-600 text-white font-semibold hover:from-blue-600 hover:to-indigo-700 transition">
                    <i class="fas fa-book"></i> Khám phá sách
                </a>
            </div>

            <!-- List -->
            <div id="reservationList" class="space-y-4 hidden"></div>
        </div>
    </div>
</main>

<!-- Toast notification -->
<div id="toast"
     class="fixed bottom-6 right-6 px-4 py-3 rounded-lg shadow-lg border flex items-center space-x-3 bg-slate-900/95 hidden z-50">
    <span id="toast-icon" class="text-xl"></span>
    <div>
        <p id="toast-message" class="font-medium text-slate-100"></p>
    </div>
</div>

<%@ include file="./layout/footer.jsp" %>

<script>
const CTX = "<%=request.getContextPath()%>";
const token = localStorage.getItem("token");

// Toast helper
let toastTimeout = null;
function showToast(type, message) {
    const toast = document.getElementById('toast');
    const toastIcon = document.getElementById('toast-icon');
    const toastMsg = document.getElementById('toast-message');
    
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

/* ========= CHECK AUTH ========= */
if (!token) {
    location.href = CTX + "/user/login.jsp";
}

/* ========= FETCH DATA ========= */
async function loadReservations() {
    const loadingState = document.getElementById('loadingState');
    const errorState = document.getElementById('errorState');
    const emptyState = document.getElementById('emptyState');
    const listContainer = document.getElementById('reservationList');
    const errorMessage = document.getElementById('errorMessage');

    try {
        const response = await fetch(CTX + "/api/reservation/my-list", {
            method: 'GET',
            headers: { 
                "Authorization": "Bearer " + token,
                "Accept": "application/json"
            }
        });

        // Hide loading
        loadingState.classList.add('hidden');

        if (response.status === 401) {
            localStorage.removeItem("token");
            location.href = CTX + "/user/login.jsp";
            return;
        }

        if (!response.ok) {
            throw new Error('HTTP ' + response.status);
        }

        const text = await response.text();
        console.log('API Response:', text); // Debug
        
        let data;
        try {
            data = JSON.parse(text);
        } catch (e) {
            console.error('JSON Parse Error:', e);
            throw new Error('Invalid JSON response');
        }

        // Check if data is array
        if (!Array.isArray(data)) {
            console.error('Expected array, got:', typeof data);
            throw new Error('Invalid data format');
        }

        if (data.length === 0) {
            emptyState.classList.remove('hidden');
            return;
        }

        renderReservations(data);
        
    } catch (err) {
        console.error('Load Error:', err);
        loadingState.classList.add('hidden');
        errorState.classList.remove('hidden');
        errorMessage.textContent = 'Không thể tải dữ liệu: ' + err.message;
    }
}

/* ========= RENDER ========= */
function renderReservations(list) {
    const listContainer = document.getElementById('reservationList');
    
    // Update stats
    document.getElementById("stat-total").innerText = list.length;
    document.getElementById("stat-pending").innerText = list.filter(r => r.status === "PENDING").length;
    document.getElementById("stat-notified").innerText = list.filter(r => r.status === "NOTIFIED").length;
    document.getElementById("stat-fulfilled").innerText = list.filter(r => r.status === "FULFILLED").length;

    // Render list
    listContainer.innerHTML = "";
    listContainer.classList.remove('hidden');

    list.forEach(r => {
        let cancelBtn = "";
        if (r.status === "PENDING" || r.status === "NOTIFIED") {
            cancelBtn = `
                <button onclick="cancelReservation(${r.id})"
                    class="px-4 py-2 rounded-lg bg-red-500/10 text-red-300 border border-red-500/40 hover:bg-red-500/20 transition text-sm font-medium">
                    <i class="fas fa-times mr-1"></i>Hủy đặt trước
                </button>
            `;
        }

        const card = document.createElement('div');
        card.className = 'profile-card p-5 hover:border-slate-600 transition';
        card.innerHTML = `
            <div class="flex gap-5">
                <a href="bookDetails.jsp?isbn=${r.isbn}" class="flex-shrink-0">
                    <img src="${CTX}/${r.bookCover || 'images/default-cover.jpg'}"
                         onerror="this.onerror=null; this.src='${CTX}/images/default-cover.jpg'"
                         class="w-24 h-32 rounded-lg object-cover border border-slate-700 hover:border-sky-400 transition"/>
                </a>

                <div class="flex-1 min-w-0">
                    <div class="flex justify-between items-start mb-2 gap-3">
                        <a href="bookDetails.jsp?isbn=${r.isbn}"
                           class="text-lg font-semibold text-slate-100 hover:text-sky-400 transition line-clamp-2">
                            ${r.bookTitle}
                        </a>
                        <span class="status-badge status-${r.status} flex-shrink-0">
                            ${mapStatus(r.status)}
                        </span>
                    </div>

                    <p class="text-sm text-slate-400 mb-2">
                        <i class="fas fa-user-pen mr-1"></i>${r.authorName || 'Không rõ'}
                    </p>

                    <p class="text-sm text-slate-400 mb-3">
                        <i class="fas fa-calendar mr-1"></i>Đặt lúc: ${formatDate(r.reservationDate)}
                    </p>
                    
                    \${r.notifiedDate && r.status === 'NOTIFIED' ? `
                        <p class="text-sm text-emerald-400 mb-3">
                            <i class="fas fa-bell mr-1"></i>Đã thông báo: ${formatDate(r.notifiedDate)}
                        </p>
                    ` : ''}
                    
                    \${r.fulfilledDate && r.status === 'FULFILLED' ? `
                        <p class="text-sm text-purple-400 mb-3">
                            <i class="fas fa-check mr-1"></i>Hoàn thành: ${formatDate(r.fulfilledDate)}
                        </p>
                    ` : ''}

                    <div class="flex gap-2">
                        ${cancelBtn}
                        <a href="bookDetails.jsp?isbn=${r.isbn}"
                           class="px-4 py-2 rounded-lg bg-slate-700/50 text-slate-200 border border-slate-600 hover:bg-slate-700 transition text-sm font-medium">
                            <i class="fas fa-eye mr-1"></i>Xem chi tiết
                        </a>
                    </div>
                </div>
            </div>
        `;
        
        listContainer.appendChild(card);
    });
}

function mapStatus(s) {
    const statusMap = {
        PENDING: "Đang chờ",
        NOTIFIED: "Đã thông báo",
        FULFILLED: "Hoàn thành",
        CANCELLED: "Đã hủy",
        EXPIRED: "Hết hạn"
    };
    return statusMap[s] || s;
}

function formatDate(dateStr) {
    if (!dateStr) return 'Không rõ';
    try {
        return new Date(dateStr).toLocaleString("vi-VN", {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        });
    } catch (e) {
        return dateStr;
    }
}

/* ========= CANCEL ========= */
async function cancelReservation(id) {
    if (!confirm("Bạn có chắc chắn muốn hủy đặt trước này?")) return;
    
    try {
        const response = await fetch(CTX + "/api/reservation/cancel", {
            method: "POST",
            headers: {
                "Authorization": "Bearer " + token,
                "Content-Type": "application/json",
                "Accept": "application/json"
            },
            body: JSON.stringify({ reservationId: id })
        });
        
        const data = await response.json();
        
        if (response.ok) {
            showToast('success', data.message || 'Hủy đặt trước thành công!');
            setTimeout(() => location.reload(), 1000);
        } else {
            showToast('error', data.message || 'Không thể hủy đặt trước');
        }
    } catch (err) {
        console.error('Cancel Error:', err);
        showToast('error', 'Có lỗi xảy ra khi hủy đặt trước');
    }
}

// Load data on page load
loadReservations();
</script>

</body>
</html>
