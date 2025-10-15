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
            <!-- Kiểm tra thông báo từ URL -->
            <%
                String message = request.getParameter("message");
                String status = request.getParameter("status");
                if (message != null && status != null) {
            %>
            <script>
                window.onload = function () {
                    showAlert("<%= message%>", "<%= status%>");
                };
            </script>
            <%
                }
            %>

            <form action="../../BookItemServlet" method="post" enctype="multipart/form-data" class="bg-white p-8 rounded-lg shadow-md max-w-2xl mx-auto space-y-6">
                <div>
                    <label class="block mb-1 text-sm font-medium text-gray-700">ISBN hoặc Tên sách</label>
                    <input name="bookId" list="bookList" placeholder="Nhập ISBN hoặc tên sách" required
                           class="w-full border border-gray-300 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500">
                    <datalist id="bookList">
                        <%
                            try (Connection con = DBConnection.getConnection(); Statement stmt = con.createStatement(); ResultSet rs = stmt.executeQuery("SELECT isbn, title FROM book")) {
                                while (rs.next()) {
                        %>
                        <option value="<%= rs.getString("isbn")%>">
                            <%= rs.getString("title")%> (<%= rs.getString("isbn")%>)
                        </option>
                        <option value="<%= rs.getString("title")%>">
                            <%= rs.getString("title")%> (<%= rs.getString("isbn")%>)
                        </option>
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
                            try (Connection con = DBConnection.getConnection(); Statement stmt = con.createStatement(); ResultSet rs = stmt.executeQuery("SELECT rack_id, rack_number FROM rack")) {
                                while (rs.next()) {
                        %>
                        <option value="<%= rs.getInt("rack_id")%>">
                            <%= rs.getString("rack_number")%>
                        </option>
                        <%
                                }
                            }
                        %>
                    </select>
                </div>

                <div class="text-center pt-4">
                    <input type="submit" value="Thêm Vị Trí Sách"
                           class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-6 rounded-lg transition duration-200 cursor-pointer" />
                </div>
            </form>
        </div>
    </section>
</main>
</div>
