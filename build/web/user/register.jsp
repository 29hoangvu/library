<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <title>Đăng ký tài khoản</title>

    <!-- Tailwind -->
    <script src="https://cdn.tailwindcss.com"></script>

    <!-- Icons -->
    <link rel="stylesheet"
          href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css"/>

    <!-- Font -->
    <link rel="stylesheet"
          href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap"/>

    <!-- Favicon -->
    <link rel="icon" href="<%=request.getContextPath()%>/images/reading-book.png" type="image/x-icon"/>

    <!-- Global theme (file bạn gửi ở trên) -->
    <link rel="stylesheet" href="style1.css"/>

    <style>
        /* Chỉ thêm chút style riêng cho trang đăng ký để không trùng với index.css */

        /* Nút quay lại nhỏ */
        .auth-back-pill {
            position: absolute;
            top: 1.25rem;
            left: 1.25rem;
            display: inline-flex;
            align-items: center;
            gap: 0.4rem;
            padding: 0.35rem 0.8rem;
            border-radius: 9999px;
            border: 1px solid rgba(148, 163, 184, 0.7);
            background: radial-gradient(circle at top left, rgba(15, 23, 42, 0.98), rgba(15, 23, 42, 0.9));
            color: #e5e7eb;
            font-size: 0.8rem;
            font-weight: 500;
            box-shadow: 0 16px 40px rgba(15, 23, 42, 0.9);
            text-decoration: none;
            transition: all 0.2s ease-out;
        }

        .auth-back-pill:hover {
            transform: translateY(-1px) scale(1.02);
            border-color: rgba(129, 140, 248, 0.95);
            background: radial-gradient(circle at top left, rgba(79, 70, 229, 0.98), rgba(37, 99, 235, 0.98));
            box-shadow: 0 22px 55px rgba(37, 99, 235, 0.9);
        }

        .auth-logo-circle {
            width: 3.25rem;
            height: 3.25rem;
            border-radius: 9999px;
            background: radial-gradient(circle at top left, rgba(59, 130, 246, 0.25), rgba(15, 23, 42, 0.9));
            border: 1px solid rgba(148, 163, 184, 0.7);
            display: flex;
            align-items: center;
            justify-content: center;
            box-shadow: 0 14px 40px rgba(15, 23, 42, 0.9);
            margin: 0 auto 1rem auto;
        }

        /* Input dùng nền dark theo theme */
        .auth-input {
            width: 100%;
            padding: 0.8rem 0.9rem;
            border-radius: 0.9rem;
            border: 1px solid rgba(148, 163, 184, 0.6);
            background: rgba(15, 23, 42, 0.95);
            color: #f9fafb;
            font-size: 0.92rem;
            transition: all 0.25s ease;
        }

        .auth-input::placeholder {
            color: rgba(148, 163, 184, 0.9);
        }

        .auth-input:focus {
            border-color: #c084fc;
            box-shadow:
                    0 0 0 1px rgba(192, 132, 252, 0.8),
                    0 0 20px rgba(129, 140, 248, 0.7);
            transform: translateY(-1px);
            outline: none;
        }

        .auth-error {
            color: #fca5a5;
            font-size: 0.8rem;
            min-height: 18px;
        }

        .auth-footer-text {
            font-size: 0.85rem;
            color: #9ca3af;
        }

        /* Spinner nhỏ dùng cho check username/email + submit */
        .loading-spinner {
            width: 18px;
            height: 18px;
            border: 2px solid #fff;
            border-top: 2px solid transparent;
            border-radius: 50%;
            animation: spin 0.8s linear infinite;
            display: none;
        }

        @keyframes spin {
            to {
                transform: rotate(360deg);
            }
        }

        .success-icon {
            display: none;
        }

        .error-icon {
            display: none;
        }

        /* Lắc khi lỗi */
        .error-shake {
            animation: shake 0.45s ease-in-out;
        }

        @keyframes shake {
            0%, 100% { transform: translateX(0); }
            20%, 60% { transform: translateX(-4px); }
            40%, 80% { transform: translateX(4px); }
        }
    </style>
</head>

<body class="page-background">
<!-- Floating icons dùng chung theme -->
<div class="floating-elements">
    <i class="fas fa-book floating-book text-6xl text-blue-500" style="top: 10%; left: 85%; --float-duration: 13s;"></i>
    <i class="fas fa-bookmark floating-book text-5xl text-purple-500" style="top: 18%; left: 7%; --float-duration: 15s;"></i>
    <i class="fas fa-feather floating-book text-5xl text-emerald-500" style="top: 55%; left: 88%; --float-duration: 17s;"></i>
    <i class="fas fa-scroll floating-book text-4xl text-orange-500" style="top: 78%; left: 6%; --float-duration: 19s;"></i>
</div>

<div id="app-content ">
    <div class="container-enhanced flex items-center justify-center min-h-screen">
        <div class="relative w-full max-w-md">
            <!-- Nút quay lại -->
            <a href="<%=request.getContextPath()%>/index.jsp" class="auth-back-pill">
                <i class="fas fa-arrow-left text-xs"></i>
                <span>Trang chủ</span>
            </a>

            <!-- Card form -->
            <div class="glass-effect rounded-2xl px-8 py-7 shadow-2xl">
                <div class="text-center mb-5 mt-3">
                    <div class="auth-logo-circle">
                        <i class="fas fa-book-reader text-xl text-sky-300"></i>
                    </div>
                    <h1 class="text-2xl font-extrabold bg-clip-text text-transparent bg-gradient-to-r from-purple-300 to-sky-300">
                        Đăng ký tài khoản
                    </h1>
                    <p class="text-sm text-slate-300 mt-1">
                        Trở thành thành viên thư viện số để mượn sách, đọc ebook và nhiều tiện ích khác.
                    </p>
                </div>

                <form id="registrationForm"
                      action="<%=request.getContextPath()%>/vnpay_jsp/vnpay_pay.jsp"
                      method="post"
                      accept-charset="UTF-8">

                    <!-- Username -->
                    <div class="mb-5">
                        <label class="block text-sm font-medium text-slate-100 mb-1.5">
                            <i class="fas fa-user mr-2 text-indigo-300"></i>
                            Tên đăng nhập
                        </label>
                        <div class="relative">
                            <input type="text"
                                   id="username"
                                   name="username"
                                   class="auth-input pr-10"
                                   placeholder="Nhập tên đăng nhập"
                                   required>
                            <div class="absolute inset-y-0 right-0 flex items-center pr-3 gap-1">
                                <div class="loading-spinner" id="usernameSpinner"></div>
                                <svg class="success-icon w-5 h-5 text-emerald-400" id="usernameSuccess"
                                     fill="currentColor" viewBox="0 0 20 20">
                                    <path fill-rule="evenodd"
                                          d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                                          clip-rule="evenodd"></path>
                                </svg>
                                <svg class="error-icon w-5 h-5 text-red-400" id="usernameError"
                                     fill="currentColor" viewBox="0 0 20 20">
                                    <path fill-rule="evenodd"
                                          d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
                                          clip-rule="evenodd"></path>
                                </svg>
                            </div>
                        </div>
                        <div class="auth-error mt-1" id="usernameErrorMsg">
                            <%
                                String errUser = (String) request.getAttribute("errorUsername");
                                if (errUser != null) {
                            %>
                            <%= errUser %>
                            <% } %>
                        </div>
                    </div>

                    <!-- Password -->
                    <div class="mb-5">
                        <label class="block text-sm font-medium text-slate-100 mb-1.5">
                            <i class="fas fa-lock mr-2 text-indigo-300"></i>
                            Mật khẩu
                        </label>
                        <div class="relative">
                            <input type="password"
                                   id="password"
                                   name="password"
                                   class="auth-input pr-10"
                                   placeholder="Nhập mật khẩu"
                                   required>
                            <button type="button"
                                    class="absolute inset-y-0 right-0 pr-3 flex items-center text-slate-400 hover:text-slate-200"
                                    onclick="togglePassword('password', 'passwordToggle')">
                                <svg class="w-5 h-5" id="passwordToggle"
                                     fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                          d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                          d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path>
                                </svg>
                            </button>
                        </div>
                        <div class="text-xs text-slate-400 mt-1">
                            Mật khẩu tối thiểu 6 ký tự.
                        </div>
                    </div>

                    <!-- Email -->
                    <div class="mb-5">
                        <label class="block text-sm font-medium text-slate-100 mb-1.5">
                            <i class="fas fa-envelope mr-2 text-indigo-300"></i>
                            Email
                        </label>
                        <div class="relative">
                            <input type="email"
                                   id="email"
                                   name="email"
                                   class="auth-input pr-10"
                                   placeholder="Nhập địa chỉ email"
                                   required>
                            <div class="absolute inset-y-0 right-0 flex items-center pr-3 gap-1">
                                <div class="loading-spinner" id="emailSpinner"></div>
                                <svg class="success-icon w-5 h-5 text-emerald-400" id="emailSuccess"
                                     fill="currentColor" viewBox="0 0 20 20">
                                    <path fill-rule="evenodd"
                                          d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                                          clip-rule="evenodd"></path>
                                </svg>
                                <svg class="error-icon w-5 h-5 text-red-400" id="emailError"
                                     fill="currentColor" viewBox="0 0 20 20">
                                    <path fill-rule="evenodd"
                                          d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
                                          clip-rule="evenodd"></path>
                                </svg>
                            </div>
                        </div>
                        <div class="auth-error mt-1" id="emailErrorMsg">
                            <%
                                String errEmail = (String) request.getAttribute("errorEmail");
                                if (errEmail != null) {
                            %>
                            <%= errEmail %>
                            <% } %>
                        </div>
                    </div>

                    <!-- Years -->
                    <div class="mb-5">
                        <label class="block text-sm font-medium text-slate-100 mb-1.5">
                            <i class="fas fa-calendar-alt mr-2 text-indigo-300"></i>
                            Số năm đăng ký
                        </label>
                        <select name="years"
                                id="years"
                                class="auth-input"
                                required
                                onchange="updateTotal()">
                            <option value="1">1 năm</option>
                            <option value="2">2 năm</option>
                            <option value="3">3 năm</option>
                        </select>
                        <div class="mt-3 bg-slate-900/70 border border-indigo-500/50 rounded-xl p-3 text-sm flex justify-between items-center">
                            <span class="text-slate-200">
                                Lệ phí: <span class="font-semibold text-indigo-300">100.000đ/năm</span>
                            </span>
                            <span class="font-semibold text-amber-300" id="totalAmount">100.000đ</span>
                        </div>
                    </div>

                    <!-- Payment -->
                    <div class="mb-6">
                        <label class="block text-sm font-medium text-slate-100 mb-1.5">
                            <i class="fas fa-credit-card mr-2 text-indigo-300"></i>
                            Hình thức thanh toán
                        </label>
                        <div class="space-y-3 text-sm">
                            <label class="flex items-center p-3.5 border border-slate-600 rounded-xl cursor-pointer hover:border-indigo-400 hover:bg-slate-900/70 transition-all">
                                <input type="radio" name="paymentMethod" value="online" class="mr-3" checked>
                                <div class="flex-1">
                                    <div class="font-semibold text-slate-50">Thanh toán online (VNPAY)</div>
                                    <div class="text-xs text-slate-400">Thanh toán qua thẻ ATM, Visa, MasterCard</div>
                                </div>
                                <div class="w-12 h-7 bg-red-600 text-white text-[0.65rem] flex items-center justify-center rounded font-semibold">
                                    VNPAY
                                </div>
                            </label>
                            <label class="flex items-center p-3.5 border border-slate-600 rounded-xl cursor-pointer hover:border-indigo-400 hover:bg-slate-900/70 transition-all">
                                <input type="radio" name="paymentMethod" value="offline" class="mr-3">
                                <div class="flex-1">
                                    <div class="font-semibold text-slate-50">Nộp tại thư viện</div>
                                    <div class="text-xs text-slate-400">Thanh toán trực tiếp tại quầy</div>
                                </div>
                                <i class="fas fa-building-columns text-slate-400 text-lg"></i>
                            </label>
                        </div>
                    </div>

                    <!-- Submit -->
                    <button type="submit"
                            id="submitBtn"
                            class="w-full bg-gradient-to-r from-indigo-500 via-purple-500 to-sky-500 text-white font-semibold py-3.5 rounded-xl hover:from-indigo-400 hover:to-sky-400 focus:outline-none focus:ring-4 focus:ring-indigo-500/60 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center shadow-xl shadow-indigo-900/50 transition-all">
                        <span id="submitText">Đăng ký tài khoản</span>
                        <div class="loading-spinner ml-2" id="submitSpinner"></div>
                    </button>
                </form>

                <div class="mt-5 text-center auth-footer-text">
                    Đã có tài khoản?
                    <a href="login.jsp" class="text-indigo-300 hover:text-indigo-100 font-semibold">
                        Đăng nhập ngay
                    </a>
                </div>
            </div>
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
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
            d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.878 9.878L3 3m6.878 6.878L12 12m0 0l3.878 3.878M12 12l3.878-3.878"></path>
    `;
  } else {
    input.type = 'password';
    toggle.innerHTML = `
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
            d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
            d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path>
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

    if (!res.ok) {
      return { ok: false, error: `HTTP ${res.status}`, available: null };
    }

    const json = await res.json();
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
  document.getElementById('totalAmount').textContent =
      new Intl.NumberFormat('vi-VN').format(total) + 'đ';
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
      const errorMsg = field === 'username'
        ? 'Tên đăng nhập đã được sử dụng!'
        : 'Email đã được đăng ký!';
      document.getElementById(field + 'ErrorMsg').textContent = errorMsg;
      document.getElementById(field).classList.add('error-shake');
      setTimeout(() => document.getElementById(field).classList.remove('error-shake'), 450);
      if (field === 'username') usernameValid = false;
      if (field === 'email') emailValid = false;

    } else {
      document.getElementById(field + 'Spinner').style.display = 'none';
      document.getElementById(field + 'Success').style.display = 'none';
      document.getElementById(field + 'Error').style.display = 'none';
      document.getElementById(field + 'ErrorMsg').textContent =
          'Không kiểm tra được. Vui lòng thử lại.';
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

document.getElementById('password').addEventListener('input', () => {
  updateSubmitButton();
});

// Form submission
document.getElementById('registrationForm').addEventListener('submit', (e) => {
  const submitBtn = document.getElementById('submitBtn');
  const submitText = document.getElementById('submitText');
  const submitSpinner = document.getElementById('submitSpinner');

  if (!usernameValid || !emailValid) {
    e.preventDefault();
    alert('Vui lòng kiểm tra lại tên đăng nhập và email!');
    return;
  }

  submitBtn.disabled = true;
  submitText.textContent = 'Đang xử lý...';
  submitSpinner.style.display = 'block';
});

// Init
updateTotal();
updateSubmitButton();
</script>
</body>
</html>
