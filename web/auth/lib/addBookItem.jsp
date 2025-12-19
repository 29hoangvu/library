<!-- addBookItem.jsp -->
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.util.*" %>
<%@ page import="Servlet.DBConnection, Data.Users" %>

<%
  request.setAttribute("pageTitle", "Thêm vị trí sách");
%>
<%@ include file="../includes/header.jsp" %>

<main class="transition-all duration-300 pt-32" id="mainContent">
  <section class="bg-gray-100 py-10 px-6">
    <div class="max-w-4xl mx-auto bg-white p-8 rounded-lg shadow-md">
      <h2 class="text-2xl font-bold mb-6 text-center text-gray-800">Thêm Vị Trí Sách</h2>

      <!-- FORM -->
      <form id="bookItemForm" action="<%=request.getContextPath()%>/api/admin/book-items" 
            method="post" class="bg-white p-8 rounded-lg shadow-md max-w-2xl mx-auto space-y-6">

        <div>
          <label class="block mb-1 text-sm font-medium text-gray-700">ISBN hoặc Tên sách</label>
          <input name="bookId" list="bookList" placeholder="Nhập ISBN hoặc tên sách" required
                 class="w-full border border-gray-300 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500">
          <datalist id="bookList">
            <%
              try (Connection con = DBConnection.getConnection();
                   Statement stmt = con.createStatement();
                   ResultSet rs = stmt.executeQuery("SELECT isbn, title FROM book")) {
                while (rs.next()) {
            %>
              <option value="<%= rs.getString("isbn") %>"><%= rs.getString("title") %> (<%= rs.getString("isbn") %>)</option>
              <option value="<%= rs.getString("title") %>"><%= rs.getString("title") %> (<%= rs.getString("isbn") %>)</option>
            <%
                }
              }
            %>
          </datalist>
        </div>

        <div>
          <label class="block mb-1 text-sm font-medium text-gray-700">Vị trí (Kệ)</label>
          <select name="rackId" required
                  class="w-full border border-gray-300 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500">
            <option value="">-- Chọn kệ --</option>
            <%
              try (Connection con = DBConnection.getConnection();
                   Statement stmt = con.createStatement();
                   ResultSet rs = stmt.executeQuery("SELECT rack_id, rack_number FROM rack")) {
                while (rs.next()) {
            %>
              <option value="<%= rs.getInt("rack_id") %>"><%= rs.getString("rack_number") %></option>
            <%
                }
              }
            %>
          </select>
        </div>

        <div class="text-center pt-4">
          <button type="submit"
                  class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-6 rounded-lg transition duration-200">
            Thêm Vị Trí Sách
          </button>
        </div>
      </form>
    </div>
  </section>
</main>

<!-- Toast container: GÓC PHẢI DƯỚI -->
<div id="toastContainer" class="fixed bottom-5 right-5 z-[9999] flex flex-col gap-3 pointer-events-none"></div>

<script>
// Toast: success xanh lá, error đỏ, warning vàng, info xanh dương
const styles = {
  success: "bg-green-600 text-white",
  error:   "bg-red-600 text-white",
  warning: "bg-yellow-500 text-black",
  info:    "bg-blue-600 text-white"
};

function showToast(message, type = "info", duration = 3000) {
  const container = document.getElementById("toastContainer");
  if (!container) return;

  const toast = document.createElement("div");
  toast.className = `pointer-events-auto max-w-sm rounded-lg shadow-lg px-4 py-3 ring-1 ring-black/10 ${styles[type] || styles.info} transition-all transform opacity-0 translate-y-3`;
  toast.textContent = message;

  container.appendChild(toast);
  requestAnimationFrame(() => {
    toast.classList.remove("opacity-0", "translate-y-3");
    toast.classList.add("opacity-100", "translate-y-0");
  });

  setTimeout(() => {
    toast.classList.add("opacity-0", "translate-y-3");
    setTimeout(() => toast.remove(), 250);
  }, duration);
}
</script>

<!-- Popup Confirm -->
<div id="confirmPopup" class="fixed inset-0 z-[9998] hidden items-center justify-center bg-black/40">
  <div class="bg-white rounded-lg shadow-xl p-6 max-w-sm w-full">
    <h3 class="text-lg font-semibold mb-4">Xác nhận</h3>
    <p id="confirmMessage" class="text-gray-700 mb-6"></p>
    <div class="flex justify-end gap-3">
      <button id="confirmCancel" class="px-4 py-2 bg-gray-200 rounded hover:bg-gray-300">Hủy</button>
      <button id="confirmOk" class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">Đồng ý</button>
    </div>
  </div>
</div>

<script>
function showConfirm(message) {
  return new Promise(resolve => {
    const popup = document.getElementById("confirmPopup");
    const msgEl = document.getElementById("confirmMessage");
    const okBtn = document.getElementById("confirmOk");
    const cancelBtn = document.getElementById("confirmCancel");

    msgEl.textContent = message;
    popup.classList.remove("hidden");
    popup.classList.add("flex");

    function close(result) {
      popup.classList.add("hidden");
      popup.classList.remove("flex");
      okBtn.removeEventListener("click", okHandler);
      cancelBtn.removeEventListener("click", cancelHandler);
      resolve(result);
    }

    function okHandler() { close(true); }
    function cancelHandler() { close(false); }

    okBtn.addEventListener("click", okHandler);
    cancelBtn.addEventListener("click", cancelHandler);
  });
}
</script>

<script>
document.addEventListener('DOMContentLoaded', () => {
  const form = document.getElementById('bookItemForm');
  if (!form) return;

  form.addEventListener('submit', async (e) => {
    e.preventDefault();

    const ok = await showConfirm("Xác nhận cập nhật vị trí kệ cho sách này?");
    if (!ok) return showToast("Đã hủy thao tác.", "warning");

    // Lấy dữ liệu và chuyển sang x-www-form-urlencoded
    const fd = new FormData(form);
    const body = new URLSearchParams(fd); // ✅ quan trọng: KHÔNG dùng FormData trực tiếp

    try {
      const r = await fetch(form.action, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
          'Accept': 'application/json'
        },
        body
      });

      const data = await r.json().catch(() => ({}));
      if (r.ok && data.ok) {
        showToast(data.message || "Cập nhật vị trí kệ thành công!", "success");
        // form.reset();
      } else {
        showToast(data.message || `Lỗi: ${r.status}`, "error");
      }
    } catch (err) {
      console.error(err);
      showToast("Không thể kết nối máy chủ.", "error");
    }
  });
});
</script>
