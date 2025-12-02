<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Tạo Người Dùng Mới</title>
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
    
    .form-input:focus {
      box-shadow: 0 0 0 3px rgba(14, 165, 233, 0.1);
    }
    
    .success-gradient {
      background: linear-gradient(135deg, #10b981 0%, #059669 100%);
    }
    
    .error-gradient {
      background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
    }
  </style>
</head>
<body class="bg-gray-50 min-h-screen">
  <jsp:include page="../includes/header.jsp" />
  
  <div class="container mx-auto px-4 py-8 mt-32">
    <!-- Header Section -->
    <div class="text-center mb-8 animate-fade-in">
      <div class="inline-flex items-center justify-center w-16 h-16 bg-gradient-to-r from-primary-500 to-primary-600 rounded-full text-white mb-4">
        <i class="fas fa-user-plus text-2xl"></i>
      </div>
      <h1 class="text-3xl font-bold text-gray-800 mb-2">Tạo Người Dùng Mới</h1>
      <p class="text-gray-600 max-w-md mx-auto">Thêm người dùng mới vào hệ thống với các thông tin cần thiết</p>
    </div>

    <!-- Form Card -->
    <div class="bg-white rounded-2xl p-8 shadow-medium max-w-4xl mx-auto animate-slide-up">
      <div class="flex items-center gap-3 mb-6 pb-4 border-b border-gray-200">
        <div class="bg-primary-50 p-2 rounded-lg">
          <i class="fas fa-user-edit text-primary-600 text-xl"></i>
        </div>
        <h2 class="text-xl font-semibold text-gray-800">Thông tin người dùng</h2>
      </div>

      <form id="createForm" class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- Username -->
        <div class="space-y-2">
          <label class="block text-sm font-medium text-gray-700">
            <span class="flex items-center gap-1">
              <i class="fas fa-user text-primary-500 text-xs"></i>
              Tên đăng nhập
              <span class="text-red-500">*</span>
            </span>
          </label>
          <div class="relative">
            <input name="username" required 
                   class="w-full border border-gray-300 rounded-xl px-4 py-3 form-input transition-all duration-200 focus:border-primary-500 focus:ring-1 focus:ring-primary-500 pl-10"
                   placeholder="Nhập tên đăng nhập">
            <i class="fas fa-user absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400"></i>
          </div>
        </div>

        <!-- Email -->
        <div class="space-y-2">
          <label class="block text-sm font-medium text-gray-700">
            <span class="flex items-center gap-1">
              <i class="fas fa-envelope text-primary-500 text-xs"></i>
              Email
              <span class="text-red-500">*</span>
            </span>
          </label>
          <div class="relative">
            <input type="email" name="email" required 
                   class="w-full border border-gray-300 rounded-xl px-4 py-3 form-input transition-all duration-200 focus:border-primary-500 focus:ring-1 focus:ring-primary-500 pl-10"
                   placeholder="Nhập địa chỉ email">
            <i class="fas fa-envelope absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400"></i>
          </div>
        </div>

        <!-- Role -->
        <div class="space-y-2">
          <label class="block text-sm font-medium text-gray-700">
            <span class="flex items-center gap-1">
              <i class="fas fa-user-tag text-primary-500 text-xs"></i>
              Vai trò
              <span class="text-red-500">*</span>
            </span>
          </label>
          <div class="relative">
            <select name="roleID" required 
                    class="w-full border border-gray-300 rounded-xl px-4 py-3 form-input transition-all duration-200 focus:border-primary-500 focus:ring-1 focus:ring-primary-500 appearance-none pl-10 pr-10 bg-white">
              <option value="">-- Chọn vai trò --</option>
              <option value="1">Admin</option>
              <option value="2">Librarian</option>
              <option value="3">Member</option>
            </select>
            <i class="fas fa-user-cog absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400"></i>
            <i class="fas fa-chevron-down absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 pointer-events-none"></i>
          </div>
        </div>

        <!-- Full Name -->
        <div class="space-y-2">
          <label class="block text-sm font-medium text-gray-700">
            <span class="flex items-center gap-1">
              <i class="fas fa-id-card text-primary-500 text-xs"></i>
              Họ tên
            </span>
          </label>
          <div class="relative">
            <input name="fullName" 
                   class="w-full border border-gray-300 rounded-xl px-4 py-3 form-input transition-all duration-200 focus:border-primary-500 focus:ring-1 focus:ring-primary-500 pl-10"
                   placeholder="Nhập họ và tên">
            <i class="fas fa-signature absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400"></i>
          </div>
        </div>

        <!-- Gender -->
        <div class="space-y-2">
          <label class="block text-sm font-medium text-gray-700">
            <span class="flex items-center gap-1">
              <i class="fas fa-venus-mars text-primary-500 text-xs"></i>
              Giới tính
            </span>
          </label>
          <div class="relative">
            <select name="gender" 
                    class="w-full border border-gray-300 rounded-xl px-4 py-3 form-input transition-all duration-200 focus:border-primary-500 focus:ring-1 focus:ring-primary-500 appearance-none pl-10 pr-10 bg-white">
              <option value="">-- Chọn giới tính --</option>
              <option>Nam</option>
              <option>Nữ</option>
              <option>Khác</option>
            </select>
            <i class="fas fa-venus-mars absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400"></i>
            <i class="fas fa-chevron-down absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 pointer-events-none"></i>
          </div>
        </div>

        <!-- Birth Date -->
        <div class="space-y-2">
          <label class="block text-sm font-medium text-gray-700">
            <span class="flex items-center gap-1">
              <i class="fas fa-birthday-cake text-primary-500 text-xs"></i>
              Ngày sinh
            </span>
          </label>
          <div class="relative">
            <input type="date" name="birthDate" 
                   class="w-full border border-gray-300 rounded-xl px-4 py-3 form-input transition-all duration-200 focus:border-primary-500 focus:ring-1 focus:ring-primary-500 pl-10">
            <i class="fas fa-calendar-alt absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400"></i>
          </div>
        </div>

        <!-- Phone -->
        <div class="space-y-2">
          <label class="block text-sm font-medium text-gray-700">
            <span class="flex items-center gap-1">
              <i class="fas fa-phone text-primary-500 text-xs"></i>
              Số điện thoại
            </span>
          </label>
          <div class="relative">
            <input name="phone" 
                   class="w-full border border-gray-300 rounded-xl px-4 py-3 form-input transition-all duration-200 focus:border-primary-500 focus:ring-1 focus:ring-primary-500 pl-10"
                   placeholder="Nhập số điện thoại">
            <i class="fas fa-mobile-alt absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400"></i>
          </div>
        </div>

        <!-- Address -->
        <div class="md:col-span-2 space-y-2">
          <label class="block text-sm font-medium text-gray-700">
            <span class="flex items-center gap-1">
              <i class="fas fa-map-marker-alt text-primary-500 text-xs"></i>
              Địa chỉ
            </span>
          </label>
          <div class="relative">
            <input name="address" 
                   class="w-full border border-gray-300 rounded-xl px-4 py-3 form-input transition-all duration-200 focus:border-primary-500 focus:ring-1 focus:ring-primary-500 pl-10"
                   placeholder="Nhập địa chỉ">
            <i class="fas fa-home absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400"></i>
          </div>
        </div>

        <!-- Submit Button -->
        <div class="md:col-span-2 pt-4">
          <div class="flex flex-col sm:flex-row items-center gap-4 justify-end">
            <button type="submit" 
                    class="bg-gradient-to-r from-primary-500 to-primary-600 hover:from-primary-600 hover:to-primary-700 text-white px-8 py-3 rounded-xl font-medium transition-all duration-200 shadow-md hover:shadow-lg flex items-center gap-2 w-full sm:w-auto justify-center">
              <i class="fas fa-user-plus"></i>
              Tạo tài khoản
            </button>
          </div>
        </div>
      </form>
    </div>
  </div>

  <!-- Toast Container -->
  <div id="toastContainer" class="fixed bottom-5 right-5 z-[9999] flex flex-col gap-3 pointer-events-none"></div>

<script>
  const styles = {
    success: "success-gradient text-white",
    error: "error-gradient text-white", 
    warning: "bg-yellow-500 text-black",
    info: "bg-blue-600 text-white"
  };

  function showToast(message, type = "info", duration = 3000) {
    console.log("showToast gọi với:", { message, type });

    // ==== Container ====
    let container = document.getElementById("toastContainer");
    if (!container) {
      container = document.createElement("div");
      container.id = "toastContainer";

      container.style.position = "fixed";
      container.style.bottom = "24px";
      container.style.right = "24px";
      container.style.zIndex = "999999";
      container.style.display = "flex";
      container.style.flexDirection = "column";
      container.style.gap = "12px";
      container.style.pointerEvents = "none";

      document.body.appendChild(container);
    }

    // ==== Toast ====
    const toast = document.createElement("div");
    toast.style.pointerEvents = "auto";
    toast.style.display = "flex";
    toast.style.alignItems = "center";
    toast.style.gap = "12px";
    toast.style.maxWidth = "380px";
    toast.style.padding = "12px 16px";
    toast.style.borderRadius = "16px";
    toast.style.boxShadow = "0 18px 40px rgba(15, 23, 42, 0.4)";
    toast.style.backdropFilter = "blur(10px)";
    toast.style.WebkitBackdropFilter = "blur(10px)";
    toast.style.border = "1px solid rgba(255, 255, 255, 0.14)";
    toast.style.color = "#f9fafb";
    toast.style.fontSize = "14px";
    toast.style.lineHeight = "1.4";
    toast.style.transform = "translateX(20px)";
    toast.style.opacity = "0";
    toast.style.transition = "all 0.25s ease-out";
    toast.style.position = "relative";
    toast.style.overflow = "hidden";

    // gradient theo loại
    let gradient;
    switch (type) {
      case "success":
        gradient = "linear-gradient(135deg, #22c55e, #16a34a)";
        break;
      case "error":
        gradient = "linear-gradient(135deg, #ef4444, #b91c1c)";
        break;
      case "warning":
        gradient = "linear-gradient(135deg, #eab308, #d97706)";
        break;
      default:
        gradient = "linear-gradient(135deg, #0ea5e9, #0369a1)";
    }
    toast.style.backgroundImage = gradient;

    // ==== Thanh progress ====
    const progress = document.createElement("div");
    progress.style.position = "absolute";
    progress.style.left = "0";
    progress.style.bottom = "0";
    progress.style.height = "3px";
    progress.style.width = "100%";
    progress.style.background = "rgba(15,23,42,0.25)";

    const progressBar = document.createElement("div");
    progressBar.style.height = "100%";
    progressBar.style.width = "100%";
    progressBar.style.background = "rgba(248,250,252,0.9)";
    progressBar.style.transformOrigin = "left";
    progressBar.style.transform = "scaleX(1)";
    progressBar.style.transition = `transform ${duration}ms linear`;

    progress.appendChild(progressBar);

    // ==== Icon ====
    const iconWrapper = document.createElement("div");
    iconWrapper.style.width = "34px";
    iconWrapper.style.height = "34px";
    iconWrapper.style.borderRadius = "999px";
    iconWrapper.style.display = "flex";
    iconWrapper.style.alignItems = "center";
    iconWrapper.style.justifyContent = "center";
    iconWrapper.style.background = "rgba(15,23,42,0.28)";
    iconWrapper.style.flexShrink = "0";

    const icon = document.createElement("i");
    icon.style.fontSize = "16px";
    icon.style.color = "#f9fafb";

    let iconClass = "fa-info-circle";
    if (type === "success") iconClass = "fa-check-circle";
    else if (type === "error") iconClass = "fa-exclamation-circle";
    else if (type === "warning") iconClass = "fa-exclamation-triangle";

    icon.className = `fas ${iconClass}`;
    iconWrapper.appendChild(icon);

    // ==== Text ====
    const textWrapper = document.createElement("div");
    textWrapper.style.flex = "1";
    textWrapper.style.display = "flex";
    textWrapper.style.flexDirection = "column";
    textWrapper.style.gap = "2px";

    const title = document.createElement("div");
    title.style.fontWeight = "600";
    title.style.fontSize = "14px";
    title.textContent =
      type === "success" ? "Thành công" :
      type === "error"   ? "Đã xảy ra lỗi" :
      type === "warning" ? "Cảnh báo" :
                           "Thông báo";

    const msg = document.createElement("div");
    msg.textContent = message;

    textWrapper.appendChild(title);
    textWrapper.appendChild(msg);

    // ==== Close button ====
    const closeBtn = document.createElement("button");
    closeBtn.type = "button";
    closeBtn.innerHTML = '<i class="fas fa-times"></i>';
    closeBtn.style.border = "none";
    closeBtn.style.background = "transparent";
    closeBtn.style.color = "rgba(248,250,252,0.85)";
    closeBtn.style.cursor = "pointer";
    closeBtn.style.fontSize = "14px";
    closeBtn.style.display = "flex";
    closeBtn.style.alignItems = "center";
    closeBtn.style.justifyContent = "center";
    closeBtn.style.padding = "2px";
    closeBtn.style.marginLeft = "4px";
    closeBtn.style.flexShrink = "0";

    closeBtn.addEventListener("mouseenter", () => {
      closeBtn.style.color = "#ffffff";
    });
    closeBtn.addEventListener("mouseleave", () => {
      closeBtn.style.color = "rgba(248,250,252,0.85)";
    });

    closeBtn.addEventListener("click", () => {
      hideToast();
    });

    toast.appendChild(iconWrapper);
    toast.appendChild(textWrapper);
    toast.appendChild(closeBtn);
    toast.appendChild(progress);
    container.appendChild(toast);

    // Animate vào
    requestAnimationFrame(() => {
      toast.style.opacity = "1";
      toast.style.transform = "translateX(0)";
      // progress chạy
      requestAnimationFrame(() => {
        progressBar.style.transform = "scaleX(0)";
      });
    });

    // Hàm ẩn + remove
    function hideToast() {
      toast.style.opacity = "0";
      toast.style.transform = "translateX(20px)";
      setTimeout(() => {
        if (toast.parentElement === container) {
          container.removeChild(toast);
        }
        // xoá container nếu không còn toast nào
        if (!container.hasChildNodes()) {
          container.parentElement.removeChild(container);
        }
      }, 250);
    }

    // Auto-hide
    setTimeout(hideToast, duration);
  }

  window.addEventListener("DOMContentLoaded", () => {
    const form = document.getElementById("createForm");
    if (!form) {
      console.error("Không tìm thấy form #createForm");
      return;
    }

    form.addEventListener("submit", async (e) => {
      e.preventDefault(); // CHẶN submit mặc định

      const submitBtn = form.querySelector('button[type="submit"]');
      const originalText = submitBtn.innerHTML;

      submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Đang xử lý...';
      submitBtn.disabled = true;

      const formData = new FormData(form);

      try {
        const response = await fetch("<%=request.getContextPath()%>/api/admin/cre-users", {
          method: "POST",
          body: formData,
          headers: {
            "Accept": "application/json"
            // ,"Authorization": "Bearer " + localStorage.getItem("access_token")
          }
        });

        const data = await response.json().catch(() => ({}));

        console.log("Create user response:", response.status, data);

        if (data && data.ok === true) {
          showToast(data.message || "Tạo tài khoản thành công!", "success");
          form.reset();
        } else {
          const msg = (data && data.message)
            ? data.message
            : `Lỗi: ${response.status}`;
          showToast(msg, "error");
        }
      } catch (error) {
        console.error(error);
        showToast("Không thể kết nối máy chủ. Vui lòng thử lại sau.", "error");
      } finally {
        submitBtn.innerHTML = originalText;
        submitBtn.disabled = false;
      }
    });

    // Real-time validation
    document.querySelectorAll('input[required], select[required]').forEach(input => {
      input.addEventListener('blur', function() {
        if (!this.value) {
          this.classList.add('border-red-300', 'bg-red-50');
        } else {
          this.classList.remove('border-red-300', 'bg-red-50');
        }
      });
    });
  });
</script>

</body>
</html>