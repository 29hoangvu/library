<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.net.URLDecoder" %>
<%@ page import="Data.Users, Servlet.DBConnection" %>

<%
    Users user = (Users) session.getAttribute("user");
    if (user == null || (user.getRoleID() != 1 && user.getRoleID() != 2)) {
        response.sendRedirect("index.jsp");
        return;
    }
%>

<%
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    String isbn = request.getParameter("isbn");
    if (isbn == null || isbn.isEmpty()) {
        response.sendRedirect("bookList.jsp");
        return;
    }

    String title = "", publisher = "", language = "", format = "Hardcover", description = "", coverImage = "";
    String status = "ACTIVE"; // <-- thêm
    int publicationYear = 0, numberOfPages = 0, quantity = 0;
    int authorID = 0;
    String authorName = "";

    // dữ liệu preload thể loại
    List<Integer> presetGenreIds = new ArrayList<>();
    Map<Integer, String> presetGenreNames = new LinkedHashMap<>();
    //  preload formats (distinct từ thư viện)
    List<String> allFormats = new ArrayList<>();
    try {
        conn = DBConnection.getConnection();

        // book + description
        String q = "SELECT b.title,b.publisher,b.publicationYear,b.language,b.numberOfPages,b.format,b.quantity,b.coverImage,"
                + "       d.description, b.authorID, b.status "
                + "FROM book b LEFT JOIN book_description d ON b.isbn=d.isbn "
                + "WHERE b.isbn=?";
        ps = conn.prepareStatement(q);
        ps.setString(1, isbn);
        rs = ps.executeQuery();
        if (rs.next()) {
            title = rs.getString("title");
            publisher = rs.getString("publisher");
            publicationYear = rs.getInt("publicationYear");
            language = rs.getString("language");
            numberOfPages = rs.getInt("numberOfPages");
            format = rs.getString("format") != null ? rs.getString("format") : "Hardcover";
            quantity = rs.getInt("quantity");
            coverImage = rs.getString("coverImage") != null ? rs.getString("coverImage") : "";
            description = rs.getString("description") != null ? rs.getString("description") : "";
            authorID = rs.getInt("authorID");
            status = rs.getString("status") != null ? rs.getString("status") : "ACTIVE";
        } else {
            response.sendRedirect("bookList.jsp");
            return;
        }
        rs.close();
        ps.close();

        // author name
        ps = conn.prepareStatement("SELECT name FROM author WHERE id=?");
        ps.setInt(1, authorID);
        rs = ps.executeQuery();
        if (rs.next()) {
            authorName = rs.getString("name");
        }
        rs.close();
        ps.close();

        // preload genres
        String gq = "SELECT g.id, g.name "
                + "FROM book_genre bg JOIN genre g ON g.id=bg.genre_id "
                + "JOIN book b ON b.id=bg.book_id WHERE b.isbn=?";
        ps = conn.prepareStatement(gq);
        ps.setString(1, isbn);
        rs = ps.executeQuery();
        while (rs.next()) {
            int gid = rs.getInt("id");
            String gname = rs.getString("name");
            presetGenreIds.add(gid);
            presetGenreNames.put(gid, gname);
        }
        rs.close();
        ps.close();
        // preload formats DISTINCT
        ps = conn.prepareStatement("SELECT DISTINCT format FROM book WHERE format IS NOT NULL AND format<>'' ORDER BY format");
        rs = ps.executeQuery();
        while (rs.next()) {
            allFormats.add(rs.getString(1));
        }
        rs.close(); ps.close();
%>

<!DOCTYPE html>
<html>
    <head>
        <title>Chỉnh sửa thông tin sách</title>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <script src="https://cdn.tailwindcss.com"></script>
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css">
        <style>
            /* Custom styles for enhanced UI */
            .gradient-bg {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            }

            .glass-effect {
                backdrop-filter: blur(10px);
                background: rgba(255, 255, 255, 0.95);
                border: 1px solid rgba(255, 255, 255, 0.2);
            }

            .book-cover-container {
                position: relative;
                width: 200px;
                height: 280px;
                margin: 0 auto;
                overflow: hidden;
                border-radius: 12px;
                box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2);
                transition: transform 0.3s ease;
            }

            .book-cover-container:hover {
                transform: translateY(-5px);
                box-shadow: 0 15px 35px rgba(0, 0, 0, 0.3);
            }

            .book-cover-img {
                width: 100%;
                height: 100%;
                object-fit: cover;
                transition: transform 0.3s ease;
            }

            .book-cover-container:hover .book-cover-img {
                transform: scale(1.05);
            }

            .cover-overlay {
                position: absolute;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                background: linear-gradient(to bottom, transparent 0%, rgba(0,0,0,0.1) 100%);
                opacity: 0;
                transition: opacity 0.3s ease;
            }

            .book-cover-container:hover .cover-overlay {
                opacity: 1;
            }

            .form-card {
                background: white;
                border-radius: 16px;
                box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
                border: 1px solid rgba(0, 0, 0, 0.05);
            }

            .input-field {
                transition: all 0.3s ease;
                border: 2px solid #e5e7eb;
            }

            .input-field:focus {
                border-color: #3b82f6;
                box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
                transform: translateY(-1px);
            }

            .file-input-wrapper {
                position: relative;
                overflow: hidden;
                display: inline-block;
                cursor: pointer;
                background: linear-gradient(135deg, #f3f4f6 0%, #e5e7eb 100%);
                border: 2px dashed #9ca3af;
                border-radius: 8px;
                padding: 20px;
                text-align: center;
                transition: all 0.3s ease;
                width: 100%;
                margin-top: 16px;
            }

            .file-input-wrapper:hover {
                border-color: #3b82f6;
                background: linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%);
            }

            .file-input {
                position: absolute;
                left: -9999px;
            }

            .genre-chip {
                animation: slideIn 0.3s ease;
            }

            @keyframes slideIn {
                from {
                    opacity: 0;
                    transform: translateX(-10px);
                }
                to {
                    opacity: 1;
                    transform: translateX(0);
                }
            }

            .btn-primary {
                background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);
                transition: all 0.3s ease;
                box-shadow: 0 4px 15px rgba(59, 130, 246, 0.3);
            }

            .btn-primary:hover {
                transform: translateY(-2px);
                box-shadow: 0 6px 20px rgba(59, 130, 246, 0.4);
            }

            .header-section {
                background: linear-gradient(135deg, #1f2937 0%, #374151 100%);
                color: white;
                padding: 24px;
                border-radius: 16px 16px 0 0;
                margin: -24px -24px 24px -24px;
            }

            .success-message {
                background: linear-gradient(135deg, #10b981 0%, #059669 100%);
                color: white;
                padding: 16px 24px;
                border-radius: 12px;
                margin-bottom: 24px;
                animation: slideDown 0.5s ease;
            }

            .error-message {
                background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
                color: white;
                padding: 16px 24px;
                border-radius: 12px;
                margin-bottom: 24px;
                animation: slideDown 0.5s ease;
            }

            @keyframes slideDown {
                from {
                    opacity: 0;
                    transform: translateY(-10px);
                }
                to {
                    opacity: 1;
                    transform: translateY(0);
                }
            }

            .section-divider {
                height: 2px;
                background: linear-gradient(90deg, transparent 0%, #e5e7eb 50%, transparent 100%);
                margin: 32px 0;
            }

            /* Responsive improvements */
            @media (max-width: 768px) {
                .book-cover-container {
                    width: 160px;
                    height: 224px;
                }
            }
            /* Cho dot trượt sang phải khi checked */
            /* Dot trượt sang phải */
            #statusSwitch:checked + div #dot {
                transform: translateX(20px);
                background-color: #10b981; /* xanh emerald-500 */
            }

            /* Thanh trượt đổi nền xanh khi bật */
            #statusSwitch:checked + div {
                background-color: #a7f3d0; /* xanh nhạt emerald-200 */
            }


        </style>
    </head>
    <body class="min-h-screen bg-gradient-to-br from-gray-50 via-blue-50 to-indigo-100">
        <jsp:include page="../includes/header.jsp" />

        <%
            String update = request.getParameter("update");
            String error = request.getParameter("error");
            if ("success".equals(update)) {
        %>
        <script>
            document.addEventListener('DOMContentLoaded', function () {
                const successDiv = document.createElement('div');
                successDiv.className = 'success-message fixed top-4 right-4 z-50';
                successDiv.innerHTML = '<i class="fas fa-check-circle mr-2"></i>Cập nhật sách thành công!';
                document.body.appendChild(successDiv);
                setTimeout(() => {
                    successDiv.remove();
                    window.location.href = "adminDashboard.jsp";
                }, 2000);
            });
        </script>
        <%
        } else if (error != null) {
            String decodedError = URLDecoder.decode(error, "UTF-8");
        %>
        <script>
            document.addEventListener('DOMContentLoaded', function () {
                const errorDiv = document.createElement('div');
                errorDiv.className = 'error-message fixed top-4 right-4 z-50';
                errorDiv.innerHTML = '<i class="fas fa-exclamation-circle mr-2"></i>Lỗi: <%= decodedError%>';
                document.body.appendChild(errorDiv);
                setTimeout(() => errorDiv.remove(), 5000);
            });
        </script>
        <%
            }
        %>

        <div class="container mx-auto px-4 py-8 mt-20">
            <div class="max-w-6xl mx-auto">
                <div class="form-card p-6">
                    <div class="header-section">
                        <div class="flex items-center gap-4">
                            <a href="adminDashboard.jsp" 
                               class="text-white hover:text-blue-200 transition-colors duration-300 text-xl">
                                <i class="fas fa-arrow-left"></i>
                            </a>
                            <div>
                                <h1 class="text-3xl font-bold">Chỉnh sửa thông tin sách</h1>
                                <p class="text-blue-200 mt-2">ISBN: <%= isbn%></p>
                            </div>
                        </div>
                    </div>

                    <form action="../../UpdateBookServlet" method="POST" class="space-y-8" enctype="multipart/form-data">
                        <input type="hidden" name="isbn" value="<%= isbn%>">

                        <div class="grid grid-cols-1 lg:grid-cols-4 gap-8">
                            <!-- Book Cover Section -->
                            <div class="lg:col-span-1">
                                <div class="sticky top-8">
                                    <h3 class="text-lg font-semibold text-gray-800 mb-4 text-center">
                                        <i class="fas fa-image mr-2 text-blue-600"></i>Ảnh bìa sách
                                    </h3>

                                    <div class="book-cover-container">
                                        <img id="coverPreview" 
                                             src="<%= (coverImage != null && !coverImage.isEmpty())
                                                     ? (request.getContextPath() + "/" + coverImage)
                                                     : (request.getContextPath() + "/images/default.jpg")%>"
                                             alt="Ảnh bìa sách" 
                                             class="book-cover-img">
                                        <div class="cover-overlay"></div>
                                    </div>

                                    <div class="file-input-wrapper">
                                        <i class="fas fa-cloud-upload-alt text-2xl text-gray-500 mb-2"></i>
                                        <p class="text-sm text-gray-600 mb-2">Chọn ảnh mới</p>
                                        <p class="text-xs text-gray-400">JPG, PNG tối đa 5MB</p>
                                        <input type="file" 
                                               name="coverImage" 
                                               accept="image/*"
                                               class="file-input"
                                               onchange="previewImage(this)">
                                    </div>

                                    <input type="hidden" name="existingCoverImage" value="<%= coverImage%>">
                                </div>
                            </div>

                            <!-- Book Information Section -->
                            <div class="lg:col-span-3">
                                <h3 class="text-lg font-semibold text-gray-800 mb-6">
                                    <i class="fas fa-info-circle mr-2 text-blue-600"></i>Thông tin chi tiết
                                </h3>

                                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                                    <div class="md:col-span-2">
                                        <label class="block text-sm font-medium text-gray-700 mb-2">
                                            <i class="fas fa-book mr-2 text-blue-500"></i>Tiêu đề sách
                                        </label>
                                        <input type="text" 
                                               name="title" 
                                               value="<%= title%>"
                                               class="input-field w-full rounded-lg px-4 py-3 focus:outline-none"
                                               required>
                                    </div>

                                    <div>
                                        <label class="block text-sm font-medium text-gray-700 mb-2">
                                            <i class="fas fa-building mr-2 text-blue-500"></i>Nhà xuất bản
                                        </label>
                                        <input type="text" 
                                               name="publisher" 
                                               value="<%= publisher%>"
                                               class="input-field w-full rounded-lg px-4 py-3 focus:outline-none">
                                    </div>

                                    <div>
                                        <label class="block text-sm font-medium text-gray-700 mb-2">
                                            <i class="fas fa-calendar mr-2 text-blue-500"></i>Năm xuất bản
                                        </label>
                                        <input type="number" 
                                               name="publicationYear" 
                                               value="<%= publicationYear%>" 
                                               min="1000" max="9999"
                                               class="input-field w-full rounded-lg px-4 py-3 focus:outline-none">
                                    </div>

                                    <div>
                                        <label class="block text-sm font-medium text-gray-700 mb-2">
                                            <i class="fas fa-language mr-2 text-blue-500"></i>Ngôn ngữ
                                        </label>
                                        <input type="text" 
                                               name="language" 
                                               value="<%= language%>"
                                               class="input-field w-full rounded-lg px-4 py-3 focus:outline-none">
                                    </div>

                                    <div>
                                        <label class="block text-sm font-medium text-gray-700 mb-2">
                                            <i class="fas fa-file-alt mr-2 text-blue-500"></i>Số trang
                                        </label>
                                        <input type="number" 
                                               name="numberOfPages" 
                                               value="<%= numberOfPages%>" 
                                               min="1"
                                               class="input-field w-full rounded-lg px-4 py-3 focus:outline-none">
                                    </div>

                                    <!-- NEW: Format xem → chỉnh -->
                                    <div>
                                      <div class="flex items-center justify-between mb-2">
                                        <label class="block text-sm font-medium text-gray-700">
                                          <i class="fas fa-tag mr-2 text-blue-500"></i>Định dạng
                                        </label>
                                        <button type="button" id="toggleFormatEdit"
                                                class="px-3 py-1.5 rounded-lg border text-sm hover:bg-gray-50">
                                          Chỉnh sửa định dạng
                                        </button>
                                      </div>

                                      <!-- Chế độ xem -->
                                      <div id="formatView">
                                        <span class="px-3 py-1 rounded-full bg-slate-100 text-slate-700 text-sm inline-flex items-center gap-2">
                                          <i class="fa-solid fa-tag text-slate-500"></i>
                                          <%= format %>
                                        </span>
                                      </div>

                                      <!-- Chế độ chỉnh -->
                                      <div id="formatEdit" class="hidden mt-2">
                                        <select name="format" id="formatSelect"
                                                class="input-field w-full rounded-lg px-4 py-3 focus:outline-none">
                                          <%
                                            Set<String> printed = new HashSet<>();
                                            String[] std = new String[]{"Hardcover","Paperback","Ebook"};
                                            for (String s : std) { printed.add(s.toLowerCase()); %>
                                              <option value="<%= s %>" <%= s.equalsIgnoreCase(format) ? "selected" : "" %>><%= s %></option>
                                          <% }
                                            for (String f : allFormats) {
                                              if (f != null && !printed.contains(f.toLowerCase())) { %>
                                              <option value="<%= f %>" <%= f.equalsIgnoreCase(format) ? "selected" : "" %>><%= f %></option>
                                          <%  } } %>
                                        </select>
                                        <input type="hidden" name="formatEditEnabled" id="formatEditEnabled" value="false">
                                        <p class="text-xs text-gray-500 mt-2">Danh sách lấy từ định dạng đang có trong thư viện (DISTINCT).</p>
                                      </div>
                                    </div>

                                    <div>
                                        <label class="block text-sm font-medium text-gray-700 mb-2">
                                            <i class="fas fa-boxes mr-2 text-blue-500"></i>Số lượng
                                        </label>
                                        <input type="number" 
                                               name="quantity" 
                                               value="<%= quantity%>" 
                                               min="0"
                                               class="input-field w-full rounded-lg px-4 py-3 focus:outline-none">
                                    </div>

                                    <div class="md:col-span-2">
                                        <label class="block text-sm font-medium text-gray-700 mb-2">
                                            <i class="fas fa-user-edit mr-2 text-blue-500"></i>Tác giả
                                        </label>
                                        <input type="text" 
                                               name="authorName" 
                                               id="authorName" 
                                               list="authorList" 
                                               value="<%= authorName%>"
                                               class="input-field w-full rounded-lg px-4 py-3 focus:outline-none" 
                                               required>
                                        <datalist id="authorList">
                                            <%
                                                try (Statement st2 = conn.createStatement(); ResultSet rs2 = st2.executeQuery("SELECT id,name FROM author ORDER BY name")) {
                                                    while (rs2.next()) {
                                            %>
                                            <option value="<%= rs2.getString("name")%>" data-id="<%= rs2.getInt("id")%>"></option>
                                            <%  }
                                                } %>
                                        </datalist>
                                    </div>
                                </div>

                                <div class="section-divider"></div>

                                <!-- Genre Section -->
                                <div>
                                    <label class="block text-sm font-medium text-gray-700 mb-2">
                                        <i class="fas fa-tags mr-2 text-blue-500"></i>Thể loại
                                    </label>
                                    <input type="text" 
                                           id="genreInput" 
                                           list="genreList"
                                           placeholder="Nhập hoặc chọn thể loại rồi nhấn Enter"
                                           class="input-field w-full rounded-lg px-4 py-3 focus:outline-none">
                                    <datalist id="genreList">
                                        <%
                                            try (Statement stg = conn.createStatement(); ResultSet rsg = stg.executeQuery("SELECT id,name FROM genre ORDER BY name")) {
                                                while (rsg.next()) {
                                        %>
                                        <option value="<%= rsg.getString("name")%>" data-id="<%= rsg.getInt("id")%>"></option>
                                        <%  }
                                            }%>
                                    </datalist>

                                    <div id="selectedGenres" class="flex flex-wrap gap-3 mt-4"></div>
                                    <input type="hidden" name="genreIds" id="genreIds">
                                    <input type="hidden" name="newGenres" id="newGenres">
                                </div>

                                <div class="section-divider"></div>
                                <div class="md:col-span-2">
                                    <label class="block text-sm font-medium text-gray-700 mb-1">Trạng thái hoạt động</label>
                                    <div class="flex items-center gap-3">
                                        <!-- Công tắc -->
                                        <label class="inline-flex items-center cursor-pointer">
                                            <input id="statusSwitch" type="checkbox" class="sr-only" <%= !"DELETED".equalsIgnoreCase(status) ? "checked" : ""%> >
                                            <div class="w-11 h-6 bg-gray-200 rounded-full peer-focus:outline-none relative transition-all duration-200"
                                                 style="--dot: translateX(0);">
                                                <span id="dot" class="absolute top-0.5 left-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform duration-200"></span>
                                            </div>
                                        </label>

                                        <!-- Badge hiển thị -->
                                        <span id="statusBadge"
                                              class="px-3 py-1 text-xs font-semibold rounded-full
                                              <%= "DELETED".equalsIgnoreCase(status) ? "bg-red-100 text-red-700" : "bg-emerald-100 text-emerald-700"%>">
                                            <%= "DELETED".equalsIgnoreCase(status) ? "DELETED" : "ACTIVE"%>
                                        </span>
                                    </div>
                                    <!-- input ẩn để submit lên server -->
                                    <input type="hidden" name="status" id="statusField" value="<%= "DELETED".equalsIgnoreCase(status) ? "DELETED" : "ACTIVE"%>">
                                </div>
                                <!-- Description Section -->
                                <div>
                                    <label class="block text-sm font-medium text-gray-700 mb-2">
                                        <i class="fas fa-align-left mr-2 text-blue-500"></i>Mô tả sách
                                    </label>
                                    <textarea name="description" 
                                              rows="5"
                                              placeholder="Nhập mô tả về nội dung sách..."
                                              class="input-field w-full rounded-lg px-4 py-3 focus:outline-none resize-none"><%= description%></textarea>
                                </div>
                            </div>
                        </div>

                        <div class="flex justify-end pt-6 border-t border-gray-200">
                            <button type="submit"
                                    class="btn-primary text-white font-semibold px-8 py-3 rounded-lg flex items-center gap-2">
                                <i class="fas fa-save"></i>
                                Lưu thay đổi
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>

        <script>
            // Image preview function
            function previewImage(input) {
                if (input.files && input.files[0]) {
                    const reader = new FileReader();
                    reader.onload = function (e) {
                        document.getElementById('coverPreview').src = e.target.result;
                    };
                    reader.readAsDataURL(input.files[0]);
                }
            }

            // Genre management script
            document.addEventListener("DOMContentLoaded", () => {
                const input = document.getElementById("genreInput");
                const list = document.getElementById("genreList");
                const wrap = document.getElementById("selectedGenres");
                const idsEl = document.getElementById("genreIds");
                const newEl = document.getElementById("newGenres");

                const nameMap = new Map();
                Array.from(list.options).forEach(opt => {
                    const name = (opt.value || "").trim();
                    const id = opt.getAttribute("data-id");
                    if (name)
                        nameMap.set(name.toLowerCase(), {id, name});
                });

                const selectedKnown = new Map(); // id -> name
                const newNames = new Set();

                function render() {
                    wrap.innerHTML = "";

                    // Thể loại cũ (từ database) - màu xanh dương với icon database
                    selectedKnown.forEach((name, id) => {
                        const chip = document.createElement("span");
                        chip.className = "genre-chip px-4 py-2 rounded-full bg-gradient-to-r from-blue-100 to-blue-200 text-blue-800 text-sm flex items-center gap-2 whitespace-nowrap font-medium shadow-sm border border-blue-200";

                        const icon = document.createElement("i");
                        icon.className = "fas fa-database text-xs";
                        icon.title = "Thể loại có sẵn";

                        const label = document.createElement("span");
                        label.textContent = name;

                        const btn = document.createElement("button");
                        btn.type = "button";
                        btn.className = "remove bg-blue-300 hover:bg-blue-400 rounded-full w-5 h-5 flex items-center justify-center text-xs font-bold transition-colors";
                        btn.setAttribute("data-type", "id");
                        btn.setAttribute("data-val", id);
                        btn.innerHTML = "&times;";

                        chip.appendChild(icon);
                        chip.appendChild(label);
                        chip.appendChild(btn);
                        wrap.appendChild(chip);
                    });

                    // Thể loại mới (thêm mới) - màu cam với icon plus
                    newNames.forEach(name => {
                        const chip = document.createElement("span");
                        chip.className = "genre-chip px-4 py-2 rounded-full bg-gradient-to-r from-orange-100 to-orange-200 text-orange-800 text-sm flex items-center gap-2 whitespace-nowrap font-medium shadow-sm border border-orange-200";

                        const icon = document.createElement("i");
                        icon.className = "fas fa-plus-circle text-xs";
                        icon.title = "Thể loại mới thêm";

                        const label = document.createElement("span");
                        label.textContent = name;

                        const btn = document.createElement("button");
                        btn.type = "button";
                        btn.className = "remove bg-orange-300 hover:bg-orange-400 rounded-full w-5 h-5 flex items-center justify-center text-xs font-bold transition-colors";
                        btn.setAttribute("data-type", "new");
                        btn.setAttribute("data-val", name);
                        btn.innerHTML = "&times;";

                        chip.appendChild(icon);
                        chip.appendChild(label);
                        chip.appendChild(btn);
                        wrap.appendChild(chip);
                    });

                    idsEl.value = Array.from(selectedKnown.keys()).join(",");
                    newEl.value = Array.from(newNames).join(",");

                    // Thêm chú thích nếu có thể loại
                    if (selectedKnown.size > 0 || newNames.size > 0) {
                        if (!document.getElementById('genre-legend')) {
                            const legend = document.createElement("div");
                            legend.id = "genre-legend";
                            legend.className = "mt-2 text-xs text-gray-600 flex items-center gap-4";
                            legend.innerHTML = `
                <div class="flex items-center gap-1">
                    <i class="fas fa-database text-blue-600"></i>
                    <span>Thể loại có sẵn</span>
                </div>
                <div class="flex items-center gap-1">
                    <i class="fas fa-plus-circle text-orange-600"></i>
                    <span>Thể loại mới thêm</span>
                </div>
            `;
                            wrap.parentNode.appendChild(legend);
                        }
                    }
                }

                function addFromInput() {
                    const val = (input.value || "").trim();
                    if (!val)
                        return;
                    const found = nameMap.get(val.toLowerCase());
                    if (found && found.id)
                        selectedKnown.set(String(found.id), found.name);
                    else
                        newNames.add(val);
                    input.value = "";
                    render();
                }

                input.addEventListener("keydown", e => {
                    if (e.key === "Enter" || e.key === ",") {
                        e.preventDefault();
                        addFromInput();
                    }
                });
                input.addEventListener("change", addFromInput);

                wrap.addEventListener("click", e => {
                    if (!e.target.classList.contains("remove"))
                        return;
                    const type = e.target.dataset.type, val = e.target.dataset.val;
                    if (type === "id")
                        selectedKnown.delete(String(val));
                    else
                        newNames.delete(val);
                    render();
                });

                // Preload genres from server
                const presetIds = <%= presetGenreIds.toString()%>;
                const presetMap = {};
            <% for (Map.Entry<Integer, String> en : presetGenreNames.entrySet()) {%>
                presetMap["<%= en.getKey()%>"] = "<%= en.getValue().replace("\"", "\\\"")%>";
            <% } %>
                (presetIds || []).forEach(id => {
                    const name = presetMap[String(id)];
                    if (name)
                        selectedKnown.set(String(id), name);
                });
                render();
                const sw = document.getElementById("statusSwitch");
                const badge = document.getElementById("statusBadge");
                const field = document.getElementById("statusField");

                function applyStatusUI() {
                    const active = sw.checked;
                    field.value = active ? "ACTIVE" : "DELETED";
                    badge.textContent = field.value;
                    badge.className = "px-3 py-1 text-xs font-semibold rounded-full " +
                            (active ? "bg-emerald-100 text-emerald-700" : "bg-red-100 text-red-700");
                }

                if (sw)
                    sw.addEventListener("change", applyStatusUI);
                applyStatusUI();
            });

            // Add smooth scrolling and form validation
            document.querySelector('form').addEventListener('submit', function (e) {
                const requiredFields = this.querySelectorAll('[required]');
                let isValid = true;

                requiredFields.forEach(field => {
                    if (!field.value.trim()) {
                        isValid = false;
                        field.style.borderColor = '#ef4444';
                        field.focus();
                    } else {
                        field.style.borderColor = '#e5e7eb';
                    }
                });

                if (!isValid) {
                    e.preventDefault();
                    alert('Vui lòng điền đầy đủ các trường bắt buộc!');
                }
            });
            document.addEventListener('DOMContentLoaded', function () {
                const wrapper = document.querySelector('.file-input-wrapper');
                const fileInput = document.querySelector('.file-input');
                if (wrapper && fileInput) {
                    wrapper.addEventListener('click', function (e) {
                        // tránh click khi đang kéo chọn text
                        if (e.target.tagName !== 'INPUT') {
                            fileInput.click();
                        }
                    });
                }
            });
            document.addEventListener("DOMContentLoaded", () => {
            const btnFmt   = document.getElementById("toggleFormatEdit");
            const viewFmt  = document.getElementById("formatView");
            const editFmt  = document.getElementById("formatEdit");
            const flagFmt  = document.getElementById("formatEditEnabled");

            btnFmt.addEventListener("click", () => {
              const goingEdit = editFmt.classList.contains("hidden");
              if (goingEdit) {
                viewFmt.classList.add("hidden");
                editFmt.classList.remove("hidden");
                flagFmt.value = "true";
                btnFmt.textContent = "Xong";
              } else {
                viewFmt.classList.remove("hidden");
                editFmt.classList.add("hidden");
                flagFmt.value = "false";
                btnFmt.textContent = "Chỉnh sửa định dạng";
              }
            });
          });
        </script>
    </body>
</html>

<%
    } finally {
        try {
            if (rs != null) {
                rs.close();
            }
        } catch (Exception ignore) {
        }
        try {
            if (ps != null) {
                ps.close();
            }
        } catch (Exception ignore) {
        }
        try {
            if (conn != null) {
                conn.close();
            }
        } catch (Exception ignore) {
        }
    }
%>