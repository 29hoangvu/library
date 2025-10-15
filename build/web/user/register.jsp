<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <title>Đăng ký</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <style>
    .gradient-bg {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    }
    
    .glass-effect {
      background: rgba(255, 255, 255, 0.95);
      backdrop-filter: blur(10px);
      border: 1px solid rgba(255, 255, 255, 0.2);
    }
    
    .input-focus {
      transition: all 0.3s ease;
    }
    
    .input-focus:focus {
      transform: translateY(-2px);
      box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
    }
    
    .btn-hover {
      transition: all 0.3s ease;
    }
    
    .btn-hover:hover {
      transform: translateY(-2px);
      box-shadow: 0 10px 25px rgba(59, 130, 246, 0.3);
    }
    
    .error-shake {
      animation: shake 0.5s ease-in-out;
    }
    
    @keyframes shake {
      0%, 20%, 40%, 60%, 80% { transform: translateX(0); }
      10%, 30%, 50%, 70% { transform: translateX(-10px); }
      15%, 35%, 55%, 75% { transform: translateX(10px); }
    }
    
    .loading-spinner {
      display: none;
      width: 20px;
      height: 20px;
      border: 2px solid #ffffff;
      border-top: 2px solid transparent;
      border-radius: 50%;
      animation: spin 1s linear infinite;
    }
    
    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
    
    .success-icon {
      display: none;
    }
    
    .error-icon {
      display: none;
    }
  </style>
</head>
<body class="gradient-bg min-h-screen py-10">
<div class="max-w-md mx-auto">
  <!-- Header -->
  <div class="text-center mb-8">
    <div class="inline-flex items-center justify-center w-16 h-16 bg-white rounded-full shadow-lg mb-4">
      <svg class="w-8 h-8 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.746 0 3.332.477 4.5 1.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"></path>
      </svg>
    </div>
    <h1 class="text-3xl font-bold text-white mb-2">Thư Viện Số</h1>
    <p class="text-white text-opacity-80">Đăng ký tài khoản thành viên</p>
  </div>

  <!-- Form Card -->
  <div class="glass-effect p-8 rounded-2xl shadow-xl">
    <form id="registrationForm" action="<%=request.getContextPath()%>/vnpay_jsp/vnpay_pay.jsp" method="post" accept-charset="UTF-8">
      
      <!-- Username Field -->
      <div class="mb-6">
        <label class="block text-gray-700 font-semibold mb-2">
          <svg class="inline w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path>
          </svg>
          Tên đăng nhập
        </label>
        <div class="relative">
          <input type="text" 
                 id="username" 
                 name="username" 
                 class="input-focus w-full border-2 border-gray-200 rounded-xl p-3 pl-4 pr-10 focus:outline-none focus:border-blue-500" 
                 placeholder="Nhập tên đăng nhập"
                 required>
          <div class="absolute inset-y-0 right-0 flex items-center pr-3">
            <div class="loading-spinner" id="usernameSpinner"></div>
            <svg class="success-icon w-5 h-5 text-green-500" id="usernameSuccess" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
            </svg>
            <svg class="error-icon w-5 h-5 text-red-500" id="usernameError" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"></path>
            </svg>
          </div>
        </div>
        <div class="error-message text-red-500 text-sm mt-2 min-h-[20px]" id="usernameErrorMsg">
          <%
            String errUser = (String) request.getAttribute("errorUsername");
            if (errUser != null) {
          %>
            <%= errUser %>
          <% } %>
        </div>
      </div>

      <!-- Password Field -->
      <div class="mb-6">
        <label class="block text-gray-700 font-semibold mb-2">
          <svg class="inline w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"></path>
          </svg>
          Mật khẩu
        </label>
        <div class="relative">
          <input type="password" 
                 id="password" 
                 name="password" 
                 class="input-focus w-full border-2 border-gray-200 rounded-xl p-3 pl-4 pr-10 focus:outline-none focus:border-blue-500" 
                 placeholder="Nhập mật khẩu"
                 required>
          <button type="button" 
                  class="absolute inset-y-0 right-0 pr-3 flex items-center"
                  onclick="togglePassword('password', 'passwordToggle')">
            <svg class="w-5 h-5 text-gray-400" id="passwordToggle" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path>
            </svg>
          </button>
        </div>
        <div class="text-gray-500 text-sm mt-1">Ít nhất 6 ký tự</div>
      </div>

      <!-- Email Field -->
      <div class="mb-6">
        <label class="block text-gray-700 font-semibold mb-2">
          <svg class="inline w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 12a4 4 0 10-8 0 4 4 0 008 0zm0 0v1.5a2.5 2.5 0 005 0V12a9 9 0 10-9 9m4.5-1.206a8.959 8.959 0 01-4.5 1.207"></path>
          </svg>
          Email
        </label>
        <div class="relative">
          <input type="email" 
                 id="email" 
                 name="email" 
                 class="input-focus w-full border-2 border-gray-200 rounded-xl p-3 pl-4 pr-10 focus:outline-none focus:border-blue-500" 
                 placeholder="Nhập địa chỉ email"
                 required>
          <div class="absolute inset-y-0 right-0 flex items-center pr-3">
            <div class="loading-spinner" id="emailSpinner"></div>
            <svg class="success-icon w-5 h-5 text-green-500" id="emailSuccess" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
            </svg>
            <svg class="error-icon w-5 h-5 text-red-500" id="emailError" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"></path>
            </svg>
          </div>
        </div>
        <div class="error-message text-red-500 text-sm mt-2 min-h-[20px]" id="emailErrorMsg">
          <%
            String errEmail = (String) request.getAttribute("errorEmail");
            if (errEmail != null) {
          %>
            <%= errEmail %>
          <% } %>
        </div>
      </div>

      <!-- Years Selection -->
      <div class="mb-6">
        <label class="block text-gray-700 font-semibold mb-2">
          <svg class="inline w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
          </svg>
          Số năm đăng ký
        </label>
        <select name="years" 
                id="years"
                class="input-focus w-full border-2 border-gray-200 rounded-xl p-3 focus:outline-none focus:border-blue-500" 
                required
                onchange="updateTotal()">
          <option value="1">1 năm</option>
          <option value="2">2 năm</option>
          <option value="3">3 năm</option>
        </select>
        <div class="bg-blue-50 border border-blue-200 rounded-lg p-3 mt-3">
          <div class="flex justify-between text-sm">
            <span class="text-gray-600">Lệ phí: 100.000đ/năm</span>
            <span class="font-semibold text-blue-600" id="totalAmount">100.000đ</span>
          </div>
        </div>
      </div>

      <!-- Payment Method -->
      <div class="mb-8">
        <label class="block text-gray-700 font-semibold mb-3">
          <svg class="inline w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"></path>
          </svg>
          Hình thức thanh toán
        </label>
        <div class="space-y-3">
          <label class="flex items-center p-4 border-2 border-gray-200 rounded-xl cursor-pointer hover:bg-blue-50 hover:border-blue-300 transition-all">
            <input type="radio" name="paymentMethod" value="online" class="mr-3" checked>
            <div class="flex-1">
              <div class="font-semibold">Thanh toán online (VNPAY)</div>
              <div class="text-sm text-gray-500">Thanh toán qua thẻ ATM, Visa, MasterCard</div>
            </div>
            <div class="w-12 h-8 bg-red-600 text-white text-xs flex items-center justify-center rounded">VNPAY</div>
          </label>
          <label class="flex items-center p-4 border-2 border-gray-200 rounded-xl cursor-pointer hover:bg-blue-50 hover:border-blue-300 transition-all">
            <input type="radio" name="paymentMethod" value="offline" class="mr-3">
            <div class="flex-1">
              <div class="font-semibold">Nộp tại thư viện</div>
              <div class="text-sm text-gray-500">Thanh toán trực tiếp tại quầy</div>
            </div>
            <svg class="w-6 h-6 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"></path>
            </svg>
          </label>
        </div>
      </div>

      <!-- Submit Button -->
      <button type="submit" 
              id="submitBtn"
              class="btn-hover w-full bg-gradient-to-r from-blue-600 to-purple-600 text-white font-bold py-4 rounded-xl hover:from-blue-700 hover:to-purple-700 focus:outline-none focus:ring-4 focus:ring-blue-300 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center">
        <span id="submitText">Đăng ký tài khoản</span>
        <div class="loading-spinner ml-2" id="submitSpinner"></div>
      </button>
    </form>

    <div class="mt-6 text-center">
      <p class="text-gray-600 text-sm">
        Đã có tài khoản? 
        <a href="login.jsp" class="text-blue-600 hover:text-blue-800 font-semibold">Đăng nhập ngay</a>
      </p>
    </div>
  </div>
</div>

<script>

let usernameValid = false;
let emailValid = false;
let debounceTimer = null;

// Toggle password visibility
function togglePassword(inputId, toggleId) {
  const input = document.getElementById(inputId);
  const toggle = document.getElementById(toggleId);
  
  if (input.type === 'password') {
    input.type = 'text';
    toggle.innerHTML = `
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.878 9.878L3 3m6.878 6.878L12 12m0 0l3.878 3.878M12 12l3.878-3.878"></path>
    `;
  } else {
    input.type = 'password';
    toggle.innerHTML = `
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path>
    `;
  }
}

// Show loading spinner
function showSpinner(field) {
  document.getElementById(field + 'Spinner').style.display = 'block';
  document.getElementById(field + 'Success').style.display = 'none';
  document.getElementById(field + 'Error').style.display = 'none';
}

// Show success icon
function showSuccess(field) {
  document.getElementById(field + 'Spinner').style.display = 'none';
  document.getElementById(field + 'Success').style.display = 'block';
  document.getElementById(field + 'Error').style.display = 'none';
}

// Show error icon
function showError(field) {
  document.getElementById(field + 'Spinner').style.display = 'none';
  document.getElementById(field + 'Success').style.display = 'none';
  document.getElementById(field + 'Error').style.display = 'block';
}

// Gọi API chung
async function callAvailabilityAPI(type, value) {
  const url = '<%= request.getContextPath() %>/CheckAvailabilityServlet';
  const params = new URLSearchParams();
  params.append('type', type);
  params.append('value', value);

  try {
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
      body: params.toString()
    });

    // Nếu server trả HTML lỗi (500/404), parse json sẽ văng, ta bắt ở catch
    if (!res.ok) {
      return { ok: false, error: `HTTP ${res.status}`, available: null };
    }

    const json = await res.json();
    // Kỳ vọng có {ok:boolean, available:boolean}
    if (typeof json.available !== 'boolean') {
      return { ok: false, error: 'invalid json', available: null };
    }
    return json;

  } catch (err) {
    return { ok: false, error: err?.message || 'fetch error', available: null };
  }
}

function checkUsername(username) {
  return new Promise(async (resolve) => {
    const json = await callAvailabilityAPI('username', username);
    // chỉ khi ok==true mới quyết định; còn lại coi như “không biết”
    resolve(json.ok ? json.available : null);
  });
}

function checkEmail(email) {
  return new Promise(async (resolve) => {
    const json = await callAvailabilityAPI('email', email);
    resolve(json.ok ? json.available : null);
  });
}




// Update total amount
function updateTotal() {
  const years = document.getElementById('years').value;
  const total = years * 100000;
  document.getElementById('totalAmount').textContent = new Intl.NumberFormat('vi-VN').format(total) + 'đ';
}

// Validate field with debounce
function validateField(field, value, validator) {
  clearTimeout(debounceTimer);

  if (value.length < 3) {
    document.getElementById(field + 'ErrorMsg').textContent = '';
    document.getElementById(field + 'Success').style.display = 'none';
    document.getElementById(field + 'Error').style.display = 'none';
    if (field === 'username') usernameValid = false;
    if (field === 'email') emailValid = false;
    updateSubmitButton();
    return;
  }

  showSpinner(field);

  debounceTimer = setTimeout(async () => {
    const result = await validator(value); // true | false | null

    if (result === true) {
      showSuccess(field);
      document.getElementById(field + 'ErrorMsg').textContent = '';
      if (field === 'username') usernameValid = true;
      if (field === 'email') emailValid = true;

    } else if (result === false) {
      showError(field);
      const errorMsg = field === 'username' ? 
        'Tên đăng nhập đã được sử dụng!' : 
        'Email đã được đăng ký!';
      document.getElementById(field + 'ErrorMsg').textContent = errorMsg;
      document.getElementById(field).classList.add('error-shake');
      setTimeout(() => document.getElementById(field).classList.remove('error-shake'), 500);
      if (field === 'username') usernameValid = false;
      if (field === 'email') emailValid = false;

    } else { // null -> API lỗi
      // Ẩn icon success/error, hiện thông báo không kiểm tra được
      document.getElementById(field + 'Spinner').style.display = 'none';
      document.getElementById(field + 'Success').style.display = 'none';
      document.getElementById(field + 'Error').style.display = 'none';
      document.getElementById(field + 'ErrorMsg').textContent = 'Không kiểm tra được. Vui lòng thử lại.';
      if (field === 'username') usernameValid = false;
      if (field === 'email') emailValid = false;
    }

    updateSubmitButton();
  }, 500);
}



// Update submit button state
function updateSubmitButton() {
  const submitBtn = document.getElementById('submitBtn');
  const isFormValid = usernameValid && emailValid && 
    document.getElementById('password').value.length >= 6;
  
  submitBtn.disabled = !isFormValid;
  submitBtn.classList.toggle('opacity-50', !isFormValid);
}

// Event listeners
document.getElementById('username').addEventListener('input', (e) => {
  validateField('username', e.target.value, checkUsername);
});

document.getElementById('email').addEventListener('input', (e) => {
  validateField('email', e.target.value, checkEmail);
});

document.getElementById('password').addEventListener('input', (e) => {
  updateSubmitButton();
});

// Form submission
document.getElementById('registrationForm').addEventListener('submit', (e) => {
  const submitBtn = document.getElementById('submitBtn');
  const submitText = document.getElementById('submitText');
  const submitSpinner = document.getElementById('submitSpinner');
  
  if (!usernameValid || !emailValid) {
    e.preventDefault();
    alert('Vui lòng kiểm tra lại thông tin đăng nhập và email!');
    return;
  }
  
  // Show loading state
  submitBtn.disabled = true;
  submitText.textContent = 'Đang xử lý...';
  submitSpinner.style.display = 'block';
});

// Initialize
updateTotal();
updateSubmitButton();
</script>

</body>
</html>