<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, Data.Users, Servlet.DBConnection" %>
<%
    Users user = (Users) session.getAttribute("user");
    if (user == null || user.getRoleID() != 1) {
        response.sendRedirect("adminDashboard.jsp");
        return;
    }
    
    // Lấy tham số lọc từ request
    String searchUsername = request.getParameter("searchUsername");
    String filterRole = request.getParameter("filterRole");
    
    if (searchUsername == null) searchUsername = "";
    if (filterRole == null) filterRole = "";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <title>Quản lý Người Dùng</title>
  <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-50 min-h-screen">
  <jsp:include page="../includes/header.jsp" />

  <div class="container mx-auto px-4 py-8 mt-32">

    <div class="bg-white rounded-2xl p-8 shadow-xl">
      <div class="flex items-center gap-3 mb-6">
        <span class="text-3xl">📋</span>
        <h2 class="text-2xl font-bold text-gray-800">Danh sách Người Dùng</h2>
      </div>

      <!-- Bộ lọc và Tìm kiếm -->
      <div class="bg-gray-50 rounded-xl p-6 mb-6">
        <form method="GET" class="flex flex-wrap items-center gap-4">
          <!-- Thanh tìm kiếm -->
          <div class="flex-1 min-w-64">
            <label for="searchUsername" class="block text-sm font-medium text-gray-700 mb-2">
              🔍 Tìm kiếm theo tên đăng nhập
            </label>
            <input 
              type="text" 
              id="searchUsername" 
              name="searchUsername" 
              value="<%= searchUsername %>"
              placeholder="Nhập tên đăng nhập..."
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-colors"
            >
          </div>

          <!-- Bộ lọc vai trò -->
          <div class="min-w-48">
            <label for="filterRole" class="block text-sm font-medium text-gray-700 mb-2">
              👤 Lọc theo vai trò
            </label>
            <select 
              id="filterRole" 
              name="filterRole"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-colors bg-white"
            >
              <option value="" <%= filterRole.equals("") ? "selected" : "" %>>Tất cả vai trò</option>
              <option value="1" <%= filterRole.equals("1") ? "selected" : "" %>>Admin</option>
              <option value="2" <%= filterRole.equals("2") ? "selected" : "" %>>Librarian</option>
              <option value="3" <%= filterRole.equals("3") ? "selected" : "" %>>Member</option>
            </select>
          </div>

          <!-- Nút hành động -->
          <div class="flex gap-2 mt-6">
            <button 
              type="submit"
              class="px-6 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors font-medium"
            >
              🔍 Tìm kiếm
            </button>
            <a 
              href="?searchUsername=&filterRole="
              class="px-6 py-2 bg-gray-500 text-white rounded-lg hover:bg-gray-600 transition-colors font-medium"
            >
              🔄 Xóa bộ lọc
            </a>
          </div>
        </form>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full bg-white rounded-xl overflow-hidden shadow">
          <thead class="bg-gradient-to-r from-indigo-500 to-purple-600 text-white">
          <tr>
            <th class="px-6 py-4 text-left font-semibold">ID</th>
            <th class="px-6 py-4 text-left font-semibold">Tên người dùng</th>
            <th class="px-6 py-4 text-left font-semibold">Vai trò</th>
            <th class="px-6 py-4 text-left font-semibold">Trạng thái</th>
            <th class="px-6 py-4 text-left font-semibold">Ngày hết hạn</th>
          </tr>
          </thead>
          <tbody>
          <%
              Connection conn = null;
              PreparedStatement stmt = null;
              ResultSet rs = null;
              try {
                  conn = DBConnection.getConnection();
                  
                  // Xây dựng câu truy vấn động với điều kiện lọc
                  StringBuilder sql = new StringBuilder("SELECT id, username, roleID, status, expiryDate FROM users WHERE 1=1");
                  
                  if (!searchUsername.trim().isEmpty()) {
                      sql.append(" AND username LIKE ?");
                  }
                  
                  if (!filterRole.isEmpty()) {
                      sql.append(" AND roleID = ?");
                  }
                  
                  sql.append(" ORDER BY id DESC");
                  
                  stmt = conn.prepareStatement(sql.toString());
                  
                  int paramIndex = 1;
                  if (!searchUsername.trim().isEmpty()) {
                      stmt.setString(paramIndex++, "%" + searchUsername.trim() + "%");
                  }
                  
                  if (!filterRole.isEmpty()) {
                      stmt.setInt(paramIndex++, Integer.parseInt(filterRole));
                  }
                  
                  rs = stmt.executeQuery();
                  int row = 0;
                  while (rs.next()) {
                      row++;
                      String trCls = (row % 2 == 0) ? "bg-gray-50" : "bg-white";
                      int roleID = rs.getInt("roleID");
                      String roleText = roleID==1?"Admin": roleID==2?"Librarian":"Member";
                      String roleCls  = roleID==1?"bg-red-100 text-red-800": roleID==2?"bg-blue-100 text-blue-800":"bg-green-100 text-green-800";
                      String st = rs.getString("status");
                      String stCls = "ACTIVE".equals(st)?"bg-green-100 text-green-800": "PENDING".equals(st)?"bg-yellow-100 text-yellow-800":"bg-red-100 text-red-800";
          %>
          <tr class="<%= trCls %> hover:bg-blue-50 transition-colors duration-200">
            <td class="px-6 py-4 font-medium text-gray-900"><%= rs.getInt("id") %></td>
            <td class="px-6 py-4 text-gray-800">
              <%
                String username = rs.getString("username");
                if (!searchUsername.trim().isEmpty() && username.toLowerCase().contains(searchUsername.toLowerCase())) {
                    // Highlight search term
                    String highlighted = username.replaceAll("(?i)(" + searchUsername + ")", "<mark class='bg-yellow-200'>$1</mark>");
                    out.print(highlighted);
                } else {
                    out.print(username);
                }
              %>
            </td>
            <td class="px-6 py-4">
              <span class="px-3 py-1 rounded-full text-sm font-medium <%= roleCls %>"><%= roleText %></span>
            </td>
            <td class="px-6 py-4">
              <span class="px-3 py-1 rounded-full text-sm font-medium <%= stCls %>"><%= st %></span>
            </td>
            <td class="px-6 py-4 text-gray-600">
              <%
                String exp = rs.getString("expiryDate");
                out.print((exp==null||exp.isEmpty())?"<span class='text-blue-600 font-medium'>Vĩnh viễn</span>":exp);
              %>
            </td>
          </tr>
          <%  }
              if (row==0) { 
                  String noResultMessage = "Chưa có người dùng nào";
                  if (!searchUsername.trim().isEmpty() || !filterRole.isEmpty()) {
                      noResultMessage = "Không tìm thấy người dùng nào phù hợp với điều kiện lọc";
                  }
          %>
          <tr>
            <td colspan="5" class="px-6 py-8 text-center text-gray-500">
              <div class="flex flex-col items-center gap-2">
                <span class="text-4xl">👤</span>
                <p><%= noResultMessage %></p>
                <% if (!searchUsername.trim().isEmpty() || !filterRole.isEmpty()) { %>
                <a href="?" class="text-indigo-600 hover:text-indigo-800 underline mt-2">
                  Xem tất cả người dùng
                </a>
                <% } %>
              </div>
            </td>
          </tr>
          <%  }
            } catch (Exception e) { %>
          <tr>
            <td colspan="5" class="px-6 py-4">
              <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded-lg">
                <strong>Lỗi:</strong> <%= e.getMessage() %>
              </div>
            </td>
          </tr>
          <% } finally {
                 try { if (rs!=null) rs.close(); } catch(Exception ig){}
                 try { if (stmt!=null) stmt.close(); } catch(Exception ig){}
                 try { if (conn!=null) conn.close(); } catch(Exception ig){}
             } %>
          </tbody>
        </table>
      </div>

      <!-- Thông tin tổng quan -->
      <% if (!searchUsername.trim().isEmpty() || !filterRole.isEmpty()) { %>
      <div class="mt-6 p-4 bg-blue-50 rounded-lg">
        <p class="text-sm text-blue-800">
          <span class="font-medium">🔍 Đang hiển thị kết quả lọc:</span>
          <% if (!searchUsername.trim().isEmpty()) { %>
            Tìm kiếm: "<strong><%= searchUsername %></strong>"
          <% } %>
          <% if (!filterRole.isEmpty()) { %>
            <% if (!searchUsername.trim().isEmpty()) { %> | <% } %>
            Vai trò: <strong><%= filterRole.equals("1") ? "Admin" : filterRole.equals("2") ? "Librarian" : "Member" %></strong>
          <% } %>
        </p>
      </div>
      <% } %>
    </div>
  </div>

  <script>
    // Tự động submit form khi thay đổi bộ lọc vai trò
    document.getElementById('filterRole').addEventListener('change', function() {
      this.form.submit();
    });

    // Enter key cho thanh tìm kiếm
    document.getElementById('searchUsername').addEventListener('keypress', function(e) {
      if (e.key === 'Enter') {
        e.preventDefault();
        this.form.submit();
      }
    });
  </script>
</body>
</html>