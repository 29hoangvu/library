<%@ page contentType="application/json; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, Servlet.DBConnection" %>
<%
    response.setCharacterEncoding("UTF-8");
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0");

    // Query & filters
    String q         = request.getParameter("q");            // chuỗi tìm kiếm
    String genre     = request.getParameter("genre");        // tên thể loại muốn lọc (vd: "Fantasy")
    String format    = request.getParameter("format");       // 'HARDCOVER' | 'PAPERBACK' | 'EBOOK'
    String minPagesS = request.getParameter("minPages");
    String maxPagesS = request.getParameter("maxPages");
    String yearFromS = request.getParameter("yearFrom");
    String yearToS   = request.getParameter("yearTo");
    String limitS    = request.getParameter("limit");

    Integer minPages = (minPagesS != null && !minPagesS.isBlank()) ? Integer.valueOf(minPagesS) : null;
    Integer maxPages = (maxPagesS != null && !maxPagesS.isBlank()) ? Integer.valueOf(maxPagesS) : null;
    Integer yearFrom = (yearFromS != null && !yearFromS.isBlank()) ? Integer.valueOf(yearFromS) : null;
    Integer yearTo   = (yearToS   != null && !yearToS.isBlank())   ? Integer.valueOf(yearToS)   : null;
    int limit        = (limitS    != null && !limitS.isBlank())    ? Integer.parseInt(limitS)    : 8;

    boolean hasQuery = (q != null && q.trim().length() >= 2);
    q = (q == null) ? "" : q.trim().toLowerCase();

    StringBuilder sql = new StringBuilder();
    List<Object> params = new ArrayList<>();

    if (!hasQuery) {
        // Không có chuỗi q hoặc < 2 ký tự: trả sách mới nhất
        sql.append(
          "SELECT b.isbn, b.title, a.name AS author, b.coverImage, b.publicationYear, " +
          "       GROUP_CONCAT(DISTINCT g.name ORDER BY g.name SEPARATOR ', ') AS genres " +
          "FROM book b " +
          "LEFT JOIN author a     ON a.id = b.authorId " +
          "LEFT JOIN book_genre bg ON bg.book_id = b.id " +
          "LEFT JOIN genre g       ON g.id = bg.genre_id " +
          "WHERE (b.status IS NULL OR UPPER(b.status) <> 'DELETED') "
        );

        // filters vẫn áp dụng được
        if (format != null && !format.isBlank()) { sql.append("AND b.`format` = ? "); params.add(format); }
        if (minPages != null)                    { sql.append("AND b.numberOfPages >= ? "); params.add(minPages); }
        if (maxPages != null)                    { sql.append("AND b.numberOfPages <= ? "); params.add(maxPages); }
        if (yearFrom != null)                    { sql.append("AND b.publicationYear >= ? "); params.add(yearFrom); }
        if (yearTo != null)                      { sql.append("AND b.publicationYear <= ? "); params.add(yearTo); }
        if (genre != null && !genre.isBlank())   { sql.append("AND EXISTS (SELECT 1 FROM book_genre bg2 JOIN genre g2 ON g2.id=bg2.genre_id WHERE bg2.book_id=b.id AND LOWER(g2.name) LIKE ?) ");
                                                   params.add("%" + genre.toLowerCase() + "%"); }

        sql.append("GROUP BY b.id ");
        sql.append("ORDER BY b.publicationYear DESC ");
        sql.append("LIMIT ? ");
        params.add(limit);

    } else {
        // Có chuỗi q: tìm ở title/author/genre/format/numberOfPages/publicationYear
        sql.append(
          "SELECT b.isbn, b.title, a.name AS author, b.coverImage, b.publicationYear, " +
          "       GROUP_CONCAT(DISTINCT g.name ORDER BY g.name SEPARATOR ', ') AS genres " +
          "FROM book b " +
          "LEFT JOIN author a     ON a.id = b.authorId " +
          "LEFT JOIN book_genre bg ON bg.book_id = b.id " +
          "LEFT JOIN genre g       ON g.id = bg.genre_id " +
          "WHERE (b.status IS NULL OR UPPER(b.status) <> 'DELETED') " +
          "  AND ( " +
          "        LOWER(b.title) LIKE ? " +
          "     OR LOWER(a.name)  LIKE ? " +
          "     OR LOWER(COALESCE(g.name,'')) LIKE ? " +
          "     OR LOWER(COALESCE(b.`format`,'')) LIKE ? " +
          "     OR CAST(COALESCE(b.numberOfPages,0) AS CHAR) LIKE ? " +
          "     OR CAST(COALESCE(b.publicationYear,0) AS CHAR) LIKE ? " +
          "      ) "
        );
        String like = "%" + q + "%";
        params.add(like); // title
        params.add(like); // author
        params.add(like); // genre name (qua join)
        params.add(like); // format
        params.add(like); // pages
        params.add(like); // year

        // filters bổ sung
        if (format != null && !format.isBlank()) { sql.append("AND b.`format` = ? "); params.add(format); }
        if (minPages != null)                    { sql.append("AND b.numberOfPages >= ? "); params.add(minPages); }
        if (maxPages != null)                    { sql.append("AND b.numberOfPages <= ? "); params.add(maxPages); }
        if (yearFrom != null)                    { sql.append("AND b.publicationYear >= ? "); params.add(yearFrom); }
        if (yearTo != null)                      { sql.append("AND b.publicationYear <= ? "); params.add(yearTo); }
        if (genre != null && !genre.isBlank())   { sql.append("AND EXISTS (SELECT 1 FROM book_genre bg2 JOIN genre g2 ON g2.id=bg2.genre_id WHERE bg2.book_id=b.id AND LOWER(g2.name) LIKE ?) ");
                                                   params.add("%" + genre.toLowerCase() + "%"); }

        sql.append("GROUP BY b.id ");
        // Ưu tiên khớp đầu chuỗi cho title/author
        sql.append(
          "ORDER BY CASE " +
          "           WHEN LOWER(b.title) LIKE ? THEN 1 " +
          "           WHEN LOWER(a.name)  LIKE ? THEN 2 " +
          "           ELSE 3 " +
          "         END, b.title "
        );
        params.add(q.toLowerCase() + "%"); // head match title
        params.add(q.toLowerCase() + "%"); // head match author
        sql.append("LIMIT ? ");
        params.add(limit);
    }

    List<Map<String,Object>> rows = new ArrayList<>();
    try (Connection conn = DBConnection.getConnection();
         PreparedStatement ps = conn.prepareStatement(sql.toString())) {

        for (int i = 0; i < params.size(); i++) {
            Object p = params.get(i);
            if (p instanceof Integer) ps.setInt(i + 1, (Integer)p);
            else                      ps.setString(i + 1, String.valueOf(p));
        }

        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String,Object> m = new LinkedHashMap<>();
                m.put("isbn", rs.getString("isbn"));
                m.put("title", rs.getString("title"));
                m.put("author", rs.getString("author"));
                m.put("coverImage", rs.getString("coverImage"));
                Object y = rs.getObject("publicationYear");
                m.put("publicationYear", (y == null) ? "" : y);
                m.put("genres", rs.getString("genres")); // chuỗi "A, B, C"
                rows.add(m);
            }
        }
    } catch (SQLException e) {
        e.printStackTrace();
    }

    // JSON
    StringBuilder json = new StringBuilder(256 + rows.size() * 160);
    json.append("[");
    for (int i = 0; i < rows.size(); i++) {
        Map<String,Object> b = rows.get(i);
        if (i > 0) json.append(",");
        json.append("{")
            .append("\"isbn\":\"").append(escapeJson(String.valueOf(b.get("isbn")))).append("\",")
            .append("\"title\":\"").append(escapeJson(String.valueOf(b.get("title")))).append("\",")
            .append("\"author\":\"").append(escapeJson(String.valueOf(b.get("author")))).append("\",")
            .append("\"coverImage\":\"").append(escapeJson(String.valueOf(b.get("coverImage")))).append("\",")
            .append("\"publicationYear\":\"").append(escapeJson(String.valueOf(b.get("publicationYear")))).append("\",")
            .append("\"genres\":\"").append(escapeJson(String.valueOf(b.get("genres")))).append("\"")
            .append("}");
    }
    json.append("]");
    out.print(json.toString());
    out.flush();
%>
<%!
    private String escapeJson(String s) {
        if (s == null || "null".equals(s)) return "";
        StringBuilder sb = new StringBuilder(s.length()+16);
        for (int i=0;i<s.length();i++){
            char c=s.charAt(i);
            switch(c){
                case '\\': sb.append("\\\\"); break;
                case '"':  sb.append("\\\""); break;
                case '\b': sb.append("\\b");  break;
                case '\f': sb.append("\\f");  break;
                case '\n': sb.append("\\n");  break;
                case '\r': sb.append("\\r");  break;
                case '\t': sb.append("\\t");  break;
                default:   sb.append(c);
            }
        }
        return sb.toString();
    }
%>
