// /static/js/api.js (UMD, robust)
(function (global) {
  // ====== Token helpers ======
  function setToken(t){ localStorage.setItem('token', t); }
  function getToken(){ return localStorage.getItem('token'); }
  function clearToken(){ localStorage.removeItem('token'); }

  // ====== Base URL (không hard-code /Library) ======
  // Nếu server luôn mount app ở contextPath cố định, JSP có thể gán window.CTX = '<%=request.getContextPath()%>';
  var CTX = global.CTX || (function () {
    // Suy đoán contextPath: lấy phần đầu tiên của pathname ("/Library/..." -> "/Library")
    var m = location.pathname.match(/^\/[^/]+/);
    return m ? m[0] : '';
  })();

  // ====== Core fetch with timeout + safe JSON parse ======
  async function apiRequest(method, path, body) {
    // Abort sau 20s để tránh treo
    var controller = new AbortController();
    var timer = setTimeout(() => controller.abort(), 20000);

    try {
      var headers = { 'Accept': 'application/json' };
      var token = getToken();
      if (token) headers['Authorization'] = 'Bearer ' + token;
      if (body !== undefined) headers['Content-Type'] = 'application/json';

      var res = await fetch(CTX + '/api' + path, {
        method: method,
        headers: headers,
        body: body !== undefined ? JSON.stringify(body) : undefined,
        credentials: 'include',      // nếu dùng cookie phiên; giữ cũng không hại
        signal: controller.signal
      });

      // Đọc text trước, rồi mới parse JSON (tránh crash khi body rỗng/hỏng)
      var text = await res.text();
      var data;
      try { data = text ? JSON.parse(text) : {}; }
      catch { data = { message: text }; }

      // 401: clear token, trả lỗi nhất quán
      if (res.status === 401) {
        clearToken();
        // endpoint /auth/me thì nên trả null thay vì throw để UI ẩn menu
        if (path === '/auth/me') return null;
        throw new Error(data?.message || 'Unauthorized');
      }

      if (!res.ok) {
        // Ném lỗi có message rõ ràng
        var msg = (data && (data.message || data.error || data.msg)) || ('HTTP ' + res.status);
        var err = new Error(msg);
        err.status = res.status;
        err.payload = data;
        throw err;
      }

      return data;

    } finally {
      clearTimeout(timer);
    }
  }

  // ====== Public API ======
  async function apiGet(path){ return apiRequest('GET', path); }
  async function apiPost(path, body){ return apiRequest('POST', path, body); }
  async function apiPut(path, body){ return apiRequest('PUT', path, body); }
  async function apiDelete(path, body){ return apiRequest('DELETE', path, body); }

  async function currentUser(){
    // Trả null khi chưa có token để UI biết ẩn menu
    if (!getToken()) return null;
    return apiRequest('GET', '/auth/me'); // đã xử lý 401 -> null ở trên
  }

  global.api = { setToken, getToken, clearToken, apiGet, apiPost, apiPut, apiDelete, currentUser };
})(window);
