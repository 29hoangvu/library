<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*" %>
<%@ page import="Servlet.DBConnection, Data.Users" %>
<!DOCTYPE html>
<html lang="vi">
  <head>
    <meta charset="UTF-8">
    <title>Chi Tiết Sách</title>
    <!-- Tailwind CSS -->
    <script src="https://cdn.tailwindcss.com"></script>

    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css">

    <!-- Google Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">

    <!-- Favicon -->
    <link rel="icon" href="./images/reading-book.png" type="image/x-icon" />
    <link rel="stylesheet" href="home1.css"/>
  </head>
  <body class="page-background">
    <!-- Floating Background Elements -->
    <div class="floating-elements">
      <i class="fas fa-book floating-book text-6xl text-blue-500" style="top: 10%; left: 85%; animation-delay: 0s;"></i>
      <i class="fas fa-bookmark floating-book text-4xl text-purple-500" style="top: 20%; left: 10%; animation-delay: 2s;"></i>
      <i class="fas fa-feather floating-book text-5xl text-green-500" style="top: 60%; left: 90%; animation-delay: 4s;"></i>
      <i class="fas fa-scroll floating-book text-4xl text-orange-500" style="top: 80%; left: 5%; animation-delay: 6s;"></i>
    </div>

    <!-- Include Header -->
    <%@ include file="./layout/header.jsp" %>

    <main class="container-enhanced py-12">
      <%
        String isbn = request.getParameter("isbn");
        if (isbn == null || isbn.trim().isEmpty()) {
            out.println("<p class='text-red-600'>Lỗi: Không tìm thấy ISBN.</p>");
            return;
        }

        Map<String, Object> book = new HashMap<>();
        List<String> bgenres = new ArrayList<>();

        try (Connection conn = DBConnection.getConnection()) {

            String sql =
                "SELECT b.title, a.name AS author, b.publicationYear, b.format, b.coverImage, " +
                "       bd.description, r.rack_number, g.name AS genre, b.quantity, " +
                "       (SELECT COUNT(*) FROM ebook_read_log l WHERE l.isbn = b.isbn) AS views_total " +
                "FROM book b " +
                "JOIN author a ON b.authorId = a.id " +
                "LEFT JOIN book_description bd ON b.isbn = bd.isbn " +
                "LEFT JOIN bookitem bi ON b.isbn = bi.book_isbn " +
                "LEFT JOIN rack r ON bi.rack_id = r.rack_id " +
                "LEFT JOIN book_genre bg ON b.id = bg.book_id " +
                "LEFT JOIN genre g ON bg.genre_id = g.id " +
                "WHERE b.isbn = ?";

            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setString(1, isbn);
                try (ResultSet rs = stmt.executeQuery()) {
                    while (rs.next()) {
                        book.put("title", rs.getString("title"));
                        book.put("author", rs.getString("author"));
                        book.put("description", rs.getString("description"));
                        book.put("format", rs.getString("format"));
                        book.put("coverImage", rs.getString("coverImage"));
                        book.put("rack", rs.getString("rack_number") != null ? rs.getString("rack_number") : "Chưa sắp xếp");
                        // giữ null nếu năm = 0
                        int pubY = rs.getInt("publicationYear");
                        book.put("publicationYear", pubY > 0 ? pubY : null);
                        // quantity có thể null -> getObject
                        book.put("quantity", rs.getObject("quantity"));
                        book.put("views_total", rs.getInt("views_total"));

                        String g = rs.getString("genre");
                        if (g != null && !bgenres.contains(g)) {
                            bgenres.add(g);
                        }
                    }
                }
            }
        } catch (SQLException e) {
            out.println("<p class='text-red-600'>Lỗi kết nối CSDL: " + e.getMessage() + "</p>");
        }
      %>

      <div class="max-w-6xl mx-auto bg-white p-8 rounded-xl shadow-md">
        <div class="grid grid-cols-1 lg:grid-cols-5 gap-8">
          <!-- Hình ảnh sách - 2 cột -->
          <div class="lg:col-span-2 flex flex-col items-center">
            <div class="w-full max-w-sm">
              <img src="<%= request.getContextPath() + "/" + book.get("coverImage") %>"
                   alt="<%= book.get("title")%>"
                   onerror="this.onerror=null; this.src='<%= request.getContextPath() %>/images/default-cover.jpg'"
                   class="w-full h-auto rounded-xl shadow-lg border border-gray-200 object-cover" />
            </div>

            <!-- Action buttons -->
            <div class="mt-6 flex flex-col sm:flex-row gap-3 w-full max-w-sm">
              <%
                String format = (String) book.get("format");
                boolean isEbook = format != null && "EBOOK".equalsIgnoreCase(format);
              %>
              <% if (isEbook) { %>
                <a href="readBook.jsp?isbn=<%= isbn%>"
                   class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-3 rounded-lg transition text-center font-medium flex-1">
                  <i class="fas fa-book-open mr-2"></i>Đọc online
                </a>
                <a href="<%= request.getContextPath() %>/ebook?isbn=<%= isbn %>&download=true"
                   class="bg-green-600 hover:bg-green-700 text-white px-4 py-3 rounded-lg transition text-center font-medium flex-1">
                  <i class="fas fa-download mr-2"></i>Tải về
                </a>
              <% } else { %>
                <a href="../BorrowBookServlet?isbn=<%= isbn%>"
                   class="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-3 rounded-lg transition text-center font-medium w-full">
                  <i class="fas fa-hand-holding mr-2"></i>Đăng ký mượn
                </a>
              <% } %>
            </div>
          </div>

          <!-- Thông tin sách - 3 cột -->
          <div class="lg:col-span-3 flex flex-col justify-start space-y-6">
            <!-- Tiêu đề -->
            <div>
              <h1 class="text-4xl font-bold text-gray-800 leading-tight mb-2">
                <%= book.get("title")%>
              </h1>
              <p class="text-xl text-gray-600">
                Tác giả: <span class="font-semibold text-gray-700"><%= book.get("author")%></span>
              </p>
            </div>

            <!-- Thông tin chi tiết -->
            <%
              // chuẩn hóa format -> tiếng Việt
              String formatVi;
              if (format == null) {
                  formatVi = "Không rõ";
              } else {
                  switch (format) {
                      case "HARDCOVER": formatVi = "Bìa cứng"; break;
                      case "PAPERBACK": formatVi = "Bìa mềm"; break;
                      case "EBOOK":     formatVi = "Sách điện tử"; break;
                      default:          formatVi = format;
                  }
              }

              // quantity an toàn kiểu Number
              Number qtyNum = null;
              Object qObj = book.get("quantity");
              if (qObj instanceof Number) qtyNum = (Number) qObj;
              int qty = (qtyNum == null ? 0 : qtyNum.intValue());

              // views_total an toàn kiểu Number
              int viewsTotal;
              Object vObj = book.get("views_total");
              if (vObj instanceof Number) viewsTotal = ((Number) vObj).intValue();
              else viewsTotal = 0;
            %>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <!-- Năm xuất bản -->
              <div class="bg-gray-50 p-4 rounded-lg">
                <div class="flex items-center mb-2">
                  <i class="fas fa-calendar-alt text-blue-500 mr-2"></i>
                  <span class="font-semibold text-gray-700">Năm xuất bản</span>
                </div>
                <p class="text-gray-600 ml-6"><%= book.get("publicationYear") %></p>
              </div>

              <!-- Định dạng -->
              <div class="bg-gray-50 p-4 rounded-lg">
                <div class="flex items-center mb-2">
                  <i class="fas fa-file-alt text-green-500 mr-2"></i>
                  <span class="font-semibold text-gray-700">Định dạng</span>
                </div>
                <p class="text-gray-600 ml-6"><%= formatVi %></p>
              </div>

              <% if (isEbook) { %>
                <!-- Chỉ hiện với EBOOK: Lượt đọc -->
                <div class="bg-gray-50 p-4 rounded-lg">
                  <div class="flex items-center mb-2">
                    <i class="fas fa-eye text-indigo-500 mr-2"></i>
                    <span class="font-semibold text-gray-700">Lượt đọc</span>
                  </div>
                  <p class="text-gray-600 ml-6">
                    <span class="font-bold text-lg"><%= viewsTotal %></span>
                  </p>
                </div>
              <% } else { %>
                <!-- Chỉ hiện với sách giấy: Số lượng còn lại -->
                <div class="bg-gray-50 p-4 rounded-lg">
                  <div class="flex items-center mb-2">
                    <i class="fas fa-warehouse text-orange-500 mr-2"></i>
                    <span class="font-semibold text-gray-700">Số lượng còn lại</span>
                  </div>
                  <p class="text-gray-600 ml-6">
                    <span class="font-bold text-lg <%= qty > 0 ? "text-green-600" : "text-red-600" %>">
                      <%= qtyNum == null ? "0" : String.valueOf(qty) %>
                    </span>
                  </p>
                </div>

                <!-- Chỉ hiện với sách giấy: Vị trí kệ -->
                <div class="bg-gray-50 p-4 rounded-lg">
                  <div class="flex items-center mb-2">
                    <i class="fas fa-map-marker-alt text-purple-500 mr-2"></i>
                    <span class="font-semibold text-gray-700">Vị trí kệ</span>
                  </div>
                  <p class="text-gray-600 ml-6"><%= book.get("rack") %></p>
                </div>
              <% } %>
            </div>

            <!-- Thể loại -->
            <div class="bg-gray-50 p-4 rounded-lg">
              <div class="flex items-center mb-3">
                <i class="fas fa-tags text-pink-500 mr-2"></i>
                <span class="font-semibold text-gray-700">Thể loại</span>
              </div>
              <div class="flex flex-wrap gap-2 ml-6">
                <% for (String genre : bgenres) { %>
                  <span class="inline-block bg-yellow-100 text-yellow-800 text-sm font-medium px-3 py-1 rounded-full shadow-sm border border-yellow-200">
                    <%= genre %>
                  </span>
                <% } %>
              </div>
            </div>
          </div>
        </div>

        <!-- Mô tả sách -->
        <div class="mt-10 border-t pt-8">
          <h3 class="text-2xl font-semibold mb-4 flex items-center">
            <i class="fas fa-align-left text-blue-500 mr-3"></i>
            Mô tả sách
          </h3>
          <div class="bg-gray-50 p-6 rounded-lg">
            <p class="text-gray-700 leading-relaxed text-lg">
              <%= book.get("description") != null ? book.get("description") : "Chưa có mô tả cho cuốn sách này."%>
            </p>
          </div>
        </div>

        <!-- Navigation -->
        <div class="mt-8 pt-6 border-t">
          <a href="index.jsp" class="inline-flex items-center text-blue-600 hover:text-blue-800 hover:underline transition-colors">
            <i class="fas fa-arrow-left mr-2"></i>
            Quay lại danh sách sách
          </a>
        </div>
      </div>
    </main>

    <%@ include file="./layout/footer.jsp" %>
  </body>
</html>
