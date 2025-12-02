<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Thông tin cá nhân - Thư viện Sách</title>

  <!-- Tailwind -->
  <script src="https://cdn.tailwindcss.com"></script>
  <!-- Font Awesome -->
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css">
  <!-- Fonts -->
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
  <!-- Favicon -->
  <link rel="icon" href="<%=request.getContextPath()%>/images/reading-book.png" type="image/x-icon" />
  <!-- Main style (đã chứa mọi thứ của index + PROFILE PAGE section) -->
  <link rel="stylesheet" href="style1.css"/>
</head>

<body class="page-background">
  <!-- Hoa văn bay -->
  <div class="floating-elements">
    <i class="fas fa-book floating-book text-6xl text-blue-500" style="top:10%;left:85%"></i>
    <i class="fas fa-bookmark floating-book text-4xl text-purple-500" style="top:20%;left:10%"></i>
    <i class="fas fa-feather floating-book text-5xl text-green-500" style="top:60%;left:90%"></i>
    <i class="fas fa-scroll floating-book text-4xl text-orange-500" style="top:80%;left:5%"></i>
  </div>

  <!-- Header -->
  <%@ include file="layout/header.jsp" %>

  <!-- Main -->
  <main class="container-enhanced mx-auto py-10 profile-page" id="app-content">
    <!-- Profile Header – glass + gradient -->
    <section class="glass-effect rounded-3xl p-[2px] mb-8">
      <div class="profile-gradient profile-header-card p-8 text-white relative overflow-hidden">

        <div class="absolute top-0 right-0 w-32 h-32 bg-white opacity-10 rounded-full -translate-y-16 translate-x-16"></div>
        <div class="absolute bottom-0 left-0 w-24 h-24 bg-white opacity-10 rounded-full translate-y-12 -translate-x-12"></div>

        <div class="relative z-10 flex flex-col md:flex-row items-center gap-6">
          <!-- Avatar chữ cái đầu -->
          <div id="avatarInitial"
               class="floating-avatar w-24 h-24 rounded-full flex items-center justify-center text-4xl font-bold">
            U
          </div>

          <!-- Tên + trạng thái -->
          <div class="text-center md:text-left">
            <h1 id="displayName" class="text-3xl md:text-4xl font-extrabold mb-2">Người dùng</h1>
            <div class="mt-3">
              <span id="statusBadge"
                    class="px-4 py-2 rounded-full text-sm font-semibold text-white shadow-lg status-inactive inline-flex items-center gap-2">
                <i id="statusIcon" class="fas fa-clock"></i>
                <span id="statusText">Đang cập nhật…</span>
              </span>
            </div>
          </div>

          <!-- Nút cập nhật -->
          <div class="mt-4 md:mt-0 md:ml-auto">
            <button onclick="openEditModal()"
                    class=" bg-white/20 hover:bg-white/30 backdrop-blur-sm border border-white/30 text-white px-6 py-3 rounded-xl font-semibold transition-all duration-300 hover:scale-105 flex items-center gap-2">
              <i class="fas fa-edit"></i>
              <span>Cập nhật thông tin</span>
            </button>
          </div>
        </div>
      </div>
    </section>

    <!-- Cards -->
    <section class="grid grid-cols-1 lg:grid-cols-2 gap-8">
      <!-- Personal -->
      <div class="profile-stat info-card profile-card card-hover p-6">
        <div class="flex items-center mb-6">
          <div class="w-12 h-12 bg-gradient-to-r from-blue-500 to-purple-600 rounded-xl flex items-center justify-center mr-4 text-white">
            <i class="fas fa-user text-xl"></i>
          </div>
          <h2 class="text-2xl font-bold text-slate-50">Thông tin cá nhân</h2>
        </div>

        <div class="space-y-4">
          <div class="profile-row flex items-center gap-3">
            <i class="fas fa-signature text-blue-400 w-5"></i>
            <div>
              <p class="text-xs uppercase tracking-wide text-gray-400">Họ và tên</p>
              <p id="fullName" class="font-semibold text-slate-50 mt-0.5">—</p>
            </div>
          </div>

          <div class="profile-row flex items-center gap-3">
            <i class="fas fa-venus-mars text-pink-400 w-5"></i>
            <div>
              <p class="text-xs uppercase tracking-wide text-gray-400">Giới tính</p>
              <p id="gender" class="font-semibold text-slate-50 mt-0.5">—</p>
            </div>
          </div>

          <div class="profile-row flex items-center gap-3">
            <i class="fas fa-birthday-cake text-orange-400 w-5"></i>
            <div>
              <p class="text-xs uppercase tracking-wide text-gray-400">Ngày sinh</p>
              <p id="birthDate" class="font-semibold text-slate-50 mt-0.5">—</p>
            </div>
          </div>
        </div>
      </div>

      <!-- Contact -->
      <div class="profile-stat info-card profile-card card-hover p-6">
        <div class=" flex items-center mb-6">
          <div class="w-12 h-12 bg-gradient-to-r from-green-500 to-teal-600 rounded-xl flex items-center justify-center mr-4 text-white">
            <i class="fas fa-address-book text-xl"></i>
          </div>
          <h2 class="text-2xl font-bold text-slate-50">Thông tin liên hệ</h2>
        </div>

        <div class="space-y-4">
          <div class="profile-row flex items-center gap-3">
            <i class="fas fa-phone text-green-400 w-5"></i>
            <div>
              <p class="text-xs uppercase tracking-wide text-gray-400">Số điện thoại</p>
              <p id="phone" class="font-semibold text-slate-50 mt-0.5">—</p>
            </div>
          </div>

          <div class="profile-row flex items-center gap-3">
            <i class="fas fa-envelope text-blue-400 w-5"></i>
            <div>
              <p class="text-xs uppercase tracking-wide text-gray-400">Email</p>
              <p id="email" class="font-semibold text-slate-50 mt-0.5 break-all">—</p>
            </div>
          </div>

          <div class="profile-row flex items-start gap-3">
            <i class="fas fa-map-marker-alt text-red-400 w-5 mt-1"></i>
            <div class="flex-1">
              <p class="text-xs uppercase tracking-wide text-gray-400">Địa chỉ</p>
              <p id="address" class="font-semibold text-slate-50 mt-0.5">—</p>
            </div>
          </div>
        </div>
      </div>

      <!-- Account -->
      <div class="info-card profile-card card-hover p-6 lg:col-span-2">
        <div class="flex items-center mb-6">
          <div class="w-12 h-12 bg-gradient-to-r from-purple-500 to-indigo-600 rounded-xl flex items-center justify-center mr-4 text-white">
            <i class="fas fa-user-cog text-xl"></i>
          </div>
          <h2 class="text-2xl font-bold text-slate-50">Thông tin tài khoản</h2>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div class="profile-stat profile-stat--blue text-center p-4 rounded-xl">
            <i class="fas fa-user-circle text-3xl mb-2 text-sky-300"></i>
            <p class="text-sm text-gray-300">Tên đăng nhập</p>
            <p id="username" class="font-bold text-slate-50 mt-1">—</p>
          </div>

          <div class="profile-stat profile-stat--green text-center p-4 rounded-xl">
            <i class="fas fa-shield-alt text-3xl mb-2 text-emerald-300"></i>
            <p class="text-sm text-gray-300">Trạng thái</p>
            <p id="statusTextCard" class="font-bold text-slate-50 mt-1">—</p>
          </div>

          <div class="profile-stat profile-stat--orange text-center p-4 rounded-xl">
            <i class="fas fa-calendar-alt text-3xl mb-2 text-orange-300"></i>
            <p class="text-sm text-gray-300">Hạn sử dụng</p>
            <p id="expiryDate" class="font-bold text-slate-50 mt-1">—</p>
          </div>
        </div>
      </div>
    </section>

    <!-- Edit Profile Modal -->
    <div id="editModal" class="fixed inset-0 z-[9999] hidden">
      <!-- Nền mờ -->
      <div class="modal-backdrop absolute inset-0 bg-black/60 backdrop-blur-sm" onclick="closeEditModal()"></div>

      <!-- Wrapper flex để canh giữa -->
      <div class="relative w-full h-full flex items-center justify-center p-4">
        <!-- Thân modal -->
        <div class="modal-enter bg-white rounded-2xl shadow-2xl max-w-2xl w-full 
                    max-h-[90vh] overflow-y-auto relative z-[10001]">

          <!-- Header modal -->
          <div class="modal-content modal-header-gradient p-6 text-white rounded-t-2xl">
            <div class="flex items-center justify-between">
              <h3 class="text-2xl font-bold flex items-center gap-2">
                <i class="fas fa-edit"></i>
                <span>Cập nhật thông tin cá nhân</span>
              </h3>
              <button type="button" onclick="closeEditModal()" class="text-white/80 hover:text-white text-2xl">
                <i class="fas fa-times"></i>
              </button>
            </div>
          </div>

        <!-- Body modal -->
        <form id="updateProfileForm" class="p-6 space-y-6">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label class="block text-sm font-semibold mb-2">
                <i class="fas fa-signature mr-2 text-blue-400"></i>Họ và tên
              </label>
              <input type="text" id="f_fullName" name="fullName"
                     class="w-full px-4 py-3 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent">
            </div>

            <div>
              <label class="block text-sm font-semibold mb-2">
                <i class="fas fa-venus-mars mr-2 text-pink-400"></i>Giới tính
              </label>
              <select id="f_gender" name="gender"
                      class="w-full px-4 py-3 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                <option value="">Chọn giới tính</option>
                <option value="Nam">Nam</option>
                <option value="Nữ">Nữ</option>
                <option value="Khác">Khác</option>
              </select>
            </div>

            <div>
              <label class="block text-sm font-semibold mb-2">
                <i class="fas fa-birthday-cake mr-2 text-orange-400"></i>Ngày sinh
              </label>
              <input type="date" id="f_birthDate" name="birthDate"
                     class="w-full px-4 py-3 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent">
            </div>

            <div>
              <label class="block text-sm font-semibold mb-2">
                <i class="fas fa-phone mr-2 text-green-400"></i>Số điện thoại
              </label>
              <input type="tel" id="f_phone" name="phone"
                     class="w-full px-4 py-3 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                     placeholder="Nhập số điện thoại">
            </div>
          </div>

          <div>
            <label class="block text-sm font-semibold mb-2">
              <i class="fas fa-map-marker-alt mr-2 text-red-400"></i>Địa chỉ
            </label>
            <textarea id="f_address" name="address" rows="3"
                      class="w-full px-4 py-3 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      placeholder="Nhập địa chỉ của bạn"></textarea>
          </div>

          <div class="flex gap-4 pt-6">
            <button type="submit"
                    class="flex-1 bg-gradient-to-r from-blue-500 to-purple-600 text-white px-6 py-3 rounded-lg font-semibold hover:from-blue-600 hover:to-purple-700 transition-all duration-300 transform hover:scale-105 flex items-center justify-center gap-2">
              <i class="fas fa-save"></i>
              <span>Lưu thay đổi</span>
            </button>
            <button type="button" onclick="closeEditModal()"
                    class="px-6 py-3 border border-gray-300 rounded-lg font-semibold text-gray-700 hover:bg-gray-50 transition-all duration-300 flex items-center gap-2">
              <i class="fas fa-times"></i>
              <span>Hủy</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  </main>

  <%@ include file="layout/footer.jsp" %>

  <script>
    const CTX = '<%=request.getContextPath()%>';

    // ===== Helper =====
    function fmtDate(d){
      if(!d) return 'Chưa cập nhật';
      const t = new Date(d);
      return String(t.getDate()).padStart(2,'0') + '/'
           + String(t.getMonth()+1).padStart(2,'0') + '/'
           + t.getFullYear();
    }

    function statusMap(status){
      const s = (status||'').toUpperCase();
      if (s === 'ACTIVE')   return {cls:'status-active',   icon:'fas fa-check-circle', text:'Đang hoạt động'};
      if (s === 'INACTIVE') return {cls:'status-inactive', icon:'fas fa-times-circle', text:'Tạm khóa'};
      return {cls:'status-expired', icon:'fas fa-clock', text:'Hết hạn'};
    }

    function setText(id, val){
      const el = document.getElementById(id);
      if (el) el.textContent = (val ?? 'Chưa cập nhật');
    }

    // ===== Load profile by JWT =====
    (async function initProfile(){
      try {
        const p = await api.apiGet('/profile');   // api.js gắn Authorization

        const name = p.fullName || p.username || 'Người dùng';
        setText('displayName', name);
        document.getElementById('avatarInitial').textContent = (name||'U').charAt(0).toUpperCase();

        const sm = statusMap(p.status);
        document.getElementById('statusBadge').className =
          'px-4 py-2 rounded-full text-sm font-semibold text-white shadow-lg inline-flex items-center gap-2 ' + sm.cls;
        document.getElementById('statusIcon').className = sm.icon;
        document.getElementById('statusText').textContent = sm.text;

        setText('fullName', p.fullName);
        setText('gender', p.gender);
        setText('birthDate', fmtDate(p.birthDate));
        setText('phone', p.phone);
        setText('email', p.email);
        setText('address', p.address);
        setText('username', p.username);
        setText('statusTextCard', sm.text);
        setText('expiryDate', fmtDate(p.expiryDate));

        // Prefill modal
        document.getElementById('f_fullName').value  = p.fullName  || '';
        document.getElementById('f_gender').value    = p.gender    || '';
        document.getElementById('f_birthDate').value = p.birthDate ? new Date(p.birthDate).toISOString().slice(0,10) : '';
        document.getElementById('f_phone').value     = p.phone     || '';
        document.getElementById('f_address').value   = p.address   || '';
      } catch(err){
        console.error('Load profile failed:', err);
        location.href = CTX + '/user/login.jsp';
      }
    })();

    // ===== Modal =====
    function openEditModal() {
      const modal = document.getElementById('editModal');
      modal.classList.add('show');
      modal.classList.remove('hidden'); // đề phòng còn class hidden của Tailwind
      document.body.style.overflow = 'hidden'; // khóa scroll nền
    }

    function closeEditModal() {
      const modal = document.getElementById('editModal');
      modal.classList.remove('show');
      modal.classList.add('hidden');
      document.body.style.overflow = 'auto'; // trả lại scroll nền
    }



    // ===== Submit update to /api/profile =====
    document.getElementById('updateProfileForm').addEventListener('submit', async (e)=>{
      e.preventDefault();
      const fd   = new FormData(e.currentTarget);
      const body = new URLSearchParams(fd);

      const btn = e.currentTarget.querySelector('button[type="submit"]');
      const old = btn.innerHTML;
      btn.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i>Đang lưu...';
      btn.disabled  = true;

      try{
        const r = await fetch(CTX + '/api/profile', {
          method:'POST',
          headers:{
            'Content-Type':'application/x-www-form-urlencoded; charset=UTF-8',
            'Accept':'application/json',
            'Authorization':'Bearer ' + api.getToken()
          },
          body: body.toString()
        });
        if(!r.ok) throw new Error('HTTP '+r.status);
        toast('Cập nhật thông tin thành công!', true);
        closeEditModal();
        setTimeout(()=>location.reload(), 800);
      }catch(err){
        console.error(err);
        toast('Có lỗi xảy ra khi cập nhật!', false);
      }finally{
        btn.innerHTML = old;
        btn.disabled  = false;
      }
    });

    // Toast nhỏ
    function toast(msg, ok=true){
      const el = document.createElement('div');
      el.className = 'fixed top-4 right-4 z-[10050] px-6 py-3 rounded-lg text-white shadow-lg transition-all';
      el.style.background = ok ? '#059669' : '#dc2626';
      el.textContent = msg;
      el.style.transform = 'translateX(120%)';
      el.style.opacity   = '0';
      document.body.appendChild(el);
      requestAnimationFrame(()=>{
        el.style.transition = 'all .25s';
        el.style.transform  = 'translateX(0)';
        el.style.opacity    = '1';
      });
      setTimeout(()=>{
        el.style.transform = 'translateX(120%)';
        el.style.opacity   = '0';
        setTimeout(()=>el.remove(), 250);
      }, 2500);
    }

    // Parallax nhẹ cho icon bay
    window.addEventListener('scroll', function () {
      const scrolled = window.pageYOffset;
      document.querySelectorAll('.floating-book').forEach((el, i)=>{
        const speed = 0.5 + (i * 0.1);
        el.style.transform = `translateY(${scrolled * speed}px) rotate(${scrolled * 0.1}deg)`;
      });
    });
    
    // Reveal on scroll
    const cards = document.querySelectorAll('.profile-card');

    function revealOnScroll(){
      cards.forEach(card=>{
        const rect = card.getBoundingClientRect();
        if(rect.top < window.innerHeight - 60){
          card.classList.add('reveal');
        }
      });
    }

    window.addEventListener('scroll', revealOnScroll);
    window.addEventListener('load', revealOnScroll);

    let ticking = false;

    window.addEventListener('scroll', () => {
      if (!ticking) {
        window.requestAnimationFrame(()=>{
          const scrolled = window.pageYOffset;
          document.querySelectorAll('.floating-book').forEach((el, i)=>{
            const speed = 0.2 + (i * 0.05);
            el.style.transform =
              `translateY(${scrolled * speed}px) rotate(${scrolled * 0.03}deg)`;
          });

          ticking = false;
        });
        ticking = true;
      }
    });

  </script>
</body>
</html>
