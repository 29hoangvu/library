<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <title>Đăng nhập</title>

    <!-- Tailwind -->
    <script src="https://cdn.tailwindcss.com"></script>

    <!-- Icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css">

    <!-- Font -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">

    <!-- Favicon -->
    <link rel="icon" href="../images/reading-book.png" type="image/x-icon"/>

    <!-- Global theme (đồng bộ 100%) -->
    <link rel="stylesheet" href="style1.css"/>

    <style>
        body {
            font-family: 'Inter', sans-serif;
        }

        /* Glass card login */
        .login-card {
            border-radius: 1.75rem;
            background: radial-gradient(circle at top left, rgba(15,23,42,0.98), rgba(15,23,42,0.92));
            border: 1px solid rgba(148,163,184,0.45);
            box-shadow: 0 28px 80px rgba(15,23,42,0.95);
            backdrop-filter: blur(16px);
        }

        .dark-input {
            background: rgba(15,23,42,0.95);
            border: 1px solid rgba(148,163,184,0.45);
            color: #e5e7eb;
        }

        .dark-input::placeholder {
            color: #6b7280;
        }

        .btn-login {
            background: radial-gradient(circle at top left, rgba(79,70,229,0.95), rgba(37,99,235,0.95));
            border: 1px solid rgba(191,219,254,0.55);
            color: #f9fafb;
            box-shadow: 0 20px 55px rgba(37,99,235,0.85);
        }
        .btn-login:hover {
            transform: translateY(-1px) scale(1.02);
            background: radial-gradient(circle at top left, rgba(99,102,241,1), rgba(59,130,246,1));
        }

        .back-pill {
            display: inline-flex;
            align-items: center;
            gap: .45rem;
            padding: .45rem .9rem;
            border-radius: 9999px;
            border: 1px solid rgba(148,163,184,0.6);
            background: radial-gradient(circle at top left, rgba(15,23,42,0.95), rgba(15,23,42,0.9));
            color: #e5e7eb;
            box-shadow: 0 16px 40px rgba(15,23,42,0.85);
            transition: .2s;
        }
        .back-pill:hover {
            background: rgba(59,130,246,0.95);
            border-color: rgba(191,219,254,1);
            transform: translateY(-1px) scale(1.03);
        }
        
    </style>
</head>

<body class="page-background min-h-screen flex items-center justify-center p-4">

<!-- Floating icons -->
<div class="floating-elements">
    <i class="fas fa-book floating-book text-6xl text-blue-500" style="top: 10%; left: 85%; animation-delay: 0s;"></i>
    <i class="fas fa-bookmark floating-book text-5xl text-purple-500" style="top: 18%; left: 7%; animation-delay: 2s;"></i>
    <i class="fas fa-feather floating-book text-5xl text-emerald-500" style="top: 55%; left: 88%; animation-delay: 4s;"></i>
    <i class="fas fa-scroll floating-book text-4xl text-orange-500" style="top: 78%; left: 6%; animation-delay: 6s;"></i>
</div>

<!-- LOGIN BOX -->
<div class="login-card w-full max-w-md p-8 relative z-10">

    <!-- Header -->
    <div class="flex items-center justify-between mb-6">
        <a href="../index.jsp" class="back-pill text-sm">
            <i class="fa fa-arrow-left text-xs"></i> Trang chủ
        </a>
        <h2 class="text-2xl font-bold text-slate-100">Đăng nhập</h2>
        <div></div>
    </div>

    <!-- Form -->
    <form id="loginForm" class="space-y-5">
        <div>
            <label for="username" class="text-slate-200 text-sm font-medium mb-1 block">Tên đăng nhập</label>
            <input autofocus type="text" id="username" required
                   class="w-full px-4 py-2 rounded-lg dark-input focus:ring-2 focus:ring-indigo-500 outline-none">
        </div>

        <div>
            <label for="password" class="text-slate-200 text-sm font-medium mb-1 block">Mật khẩu</label>
            <input type="password" id="password" required
                   class="w-full px-4 py-2 rounded-lg dark-input focus:ring-2 focus:ring-indigo-500 outline-none">
        </div>

        <button type="submit"
                class="btn-login w-full py-2 rounded-lg font-semibold transition">
            Đăng nhập
        </button>
    </form>

    <p class="text-center text-slate-300 text-sm mt-6">
        Chưa có tài khoản?
        <a href="register.jsp" class="text-indigo-400 hover:underline">Đăng ký ngay</a>
    </p>
</div>

<!-- API JS -->
<script src="<%=request.getContextPath()%>/static/js/api.js"></script>

<script>
document.getElementById('loginForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const username = document.getElementById('username').value.trim();
    const password = document.getElementById('password').value.trim();

    try {
        const res = await fetch('/Library/api/auth/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
            body: JSON.stringify({ username, password })
        });

        const data = await res.json();
        if (!res.ok) {
            showToast(data.message || 'Đăng nhập thất bại');
            return;
        }

        api.setToken(data.token);
        localStorage.setItem('user', JSON.stringify(data.user));

        const rid = data.user.roleID ?? data.user.roleId;
        if (rid === 1 || rid === 2) location.href = '/Library/auth/lib/adminDashboard.jsp';
        else location.href = '/Library/index.jsp';

    } catch (err) {
        alert(err.message || 'Lỗi hệ thống');
    }
});
</script>
<!-- TOAST -->
<div id="toast"
     class="fixed top-5 right-5 px-4 py-3 rounded-xl shadow-xl border
            border-red-400/40 bg-red-600/90 text-white text-sm flex items-center gap-3
            opacity-0 pointer-events-none transition-all duration-300 z-[9999]">
    <i class="fa fa-circle-exclamation text-lg"></i>
    <span id="toastMsg">Có lỗi xảy ra</span>
</div>
<script>
function showToast(msg) {
    const t = document.getElementById('toast');
    const m = document.getElementById('toastMsg');
    m.textContent = msg;

    t.classList.remove('opacity-0', 'pointer-events-none');
    t.classList.add('opacity-100');

    setTimeout(() => {
        t.classList.add('opacity-0');
        t.classList.remove('opacity-100');
        setTimeout(() => t.classList.add('pointer-events-none'), 300);
    }, 2500);
}
</script>

<script src="script.js"></script>
</body>
</html>
