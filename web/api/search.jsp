<%@ page contentType="application/json; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*,java.util.*,Servlet.DBConnection" %>
<%
  response.setCharacterEncoding("UTF-8");
  response.setHeader("Cache-Control","no-store, no-cache, must-revalidate, proxy-revalidate");
  response.setHeader("Pragma","no-cache");
  response.setDateHeader("Expires", 0L);

  String q = request.getParameter("q");
  String limitS = request.getParameter("limit");
  int limit = 8; try { if (limitS!=null) limit = Math.max(1, Math.min(50, Integer.parseInt(limitS))); } catch(Exception ignore){}

  List<Map<String,Object>> rows = new ArrayList<>();

  try (Connection conn = DBConnection.getConnection()) {
    if (q == null || q.trim().length() < 2) {
      // ❌ MySQL KHÔNG có NULLS LAST -> dùng mẹo sắp xếp NULL cuối
      String sql =
        "SELECT b.isbn,b.title,a.name AS author,b.coverImage,b.publicationYear " +
        "FROM book b LEFT JOIN author a ON a.id=b.authorId " +
        "WHERE UPPER(COALESCE(b.status,''))<>'DELETED' " +
        "ORDER BY (b.publicationYear IS NULL), b.publicationYear DESC " + // ✅ NULL cuối
        "LIMIT ?";
      try (PreparedStatement ps = conn.prepareStatement(sql)) {
        ps.setInt(1, limit);
        try (ResultSet rs = ps.executeQuery()) {
          while (rs.next()) {
            Map<String,Object> m = new HashMap<>();
            m.put("isbn", rs.getString("isbn"));
            m.put("title", rs.getString("title"));
            m.put("author", rs.getString("author"));
            m.put("coverImage", rs.getString("coverImage"));
            m.put("publicationYear", rs.getObject("publicationYear"));
            rows.add(m);
          }
        }
      }
    } else {
        String qraw   = q.trim();
        String qlower = qraw.toLowerCase(Locale.ROOT);
        String like   = "%" + qlower + "%";
        String starts = qlower + "%";

        // bắt "từ 200 trang", ">=200 trang", "200 trang", "ít nhất 200 trang"
        Integer pagesMin = null;
        java.util.regex.Matcher mPages = java.util.regex.Pattern.compile(
            "(?:>=|>\\s*=?|t(?:u|ừ)|it\\s*nhat|ít\\s*nhất)?\\s*(\\d{2,4})\\s*(?:trang|page|pages?)",
            java.util.regex.Pattern.CASE_INSENSITIVE | java.util.regex.Pattern.UNICODE_CASE
        ).matcher(qlower);
        if (mPages.find()) {
          try { pagesMin = Integer.valueOf(mPages.group(1)); } catch(Exception ignore){}
        }

        // nếu người dùng gõ năm 4 chữ số thì thêm điều kiện
        Integer yearEq = null;
        java.util.regex.Matcher mYear = java.util.regex.Pattern
            .compile("(?:năm\\s*)?(\\d{4})")
            .matcher(qlower);
        if (mYear.find()) {
          try {
            int y = Integer.parseInt(mYear.group(1));
            if (y >= 1400 && y <= 2100) yearEq = y;
          } catch(Exception ignore){}
        }

        // chọn collation accent-insensitive
        final String AI = "utf8mb4_general_ci"; 

        List<String> conds = new ArrayList<>();
        List<Object> params = new ArrayList<>();

        // text search: title / author / genre / format / pages-as-text / year-as-text
        conds.add(
          "(LOWER(b.title) COLLATE " + AI + " LIKE ? " +
          " OR LOWER(COALESCE(a.name,'')) COLLATE " + AI + " LIKE ? " +
          " OR EXISTS ( " +
          "     SELECT 1 FROM book_genre bg " +
          "     JOIN genre g ON g.id = bg.genre_id " +
          "     WHERE bg.book_id = b.id " +
          "       AND LOWER(g.name) COLLATE " + AI + " LIKE ? " +
          " ) " +
          " OR LOWER(COALESCE(b.format,'')) COLLATE " + AI + " LIKE ? " +
          " OR CAST(COALESCE(b.numberOfPages,0) AS CHAR) LIKE ? " +
          " OR CAST(COALESCE(b.publicationYear,0) AS CHAR) LIKE ? " +
          ")"
        );
        params.add(like); // title
        params.add(like); // author
        params.add(like); // genre
        params.add(like); // format
        params.add(like); // pages as text
        params.add(like); // year as text

        if (pagesMin != null) { conds.add("COALESCE(b.numberOfPages,0) >= ?"); params.add(pagesMin); }
        if (yearEq   != null) { conds.add("COALESCE(b.publicationYear,0) = ?"); params.add(yearEq); }

        String sql =
          "SELECT DISTINCT b.isbn, b.title, a.name AS author, b.coverImage, b.publicationYear " +
          "FROM book b " +
          "LEFT JOIN author a ON a.id = b.authorId " +
          "WHERE UPPER(COALESCE(b.status,'')) <> 'DELETED' " +
          "  AND (" + String.join(" AND ", conds) + ") " +
          "ORDER BY " +
          "  CASE WHEN LOWER(b.title)   COLLATE " + AI + " LIKE ? THEN 1 " +
          "       WHEN LOWER(COALESCE(a.name,'')) COLLATE " + AI + " LIKE ? THEN 2 " +
          "       ELSE 3 END, b.title " +
          "LIMIT ?";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
          int i = 1;
          // block LIKEs
          ps.setString(i++, like);
          ps.setString(i++, like);
          ps.setString(i++, like);
          ps.setString(i++, like);
          ps.setString(i++, like);
          ps.setString(i++, like);
          // optional filters
          if (pagesMin != null) ps.setInt(i++, pagesMin);
          if (yearEq   != null) ps.setInt(i++, yearEq);
          // ORDER BY ưu tiên
          ps.setString(i++, starts);
          ps.setString(i++, starts);
          // LIMIT
          ps.setInt(i++, limit);

          try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
              Map<String,Object> m = new HashMap<>();
              m.put("isbn", rs.getString("isbn"));
              m.put("title", rs.getString("title"));
              m.put("author", rs.getString("author"));
              m.put("coverImage", rs.getString("coverImage"));
              m.put("publicationYear", rs.getObject("publicationYear"));
              rows.add(m);
            }
          }
        }
      }
  } catch (Exception e) {
    e.printStackTrace();
    response.setStatus(500);
    out.print("{\"error\":true,\"message\":\"" + e.getClass().getSimpleName() + ": " +
              (e.getMessage()==null?"":e.getMessage().replace("\"","\\\"")) + "\"}");
    return;
  }

  // JSON thủ công
  StringBuilder json = new StringBuilder("[");
  for (int i=0;i<rows.size();i++){
    Map<String,Object> b = rows.get(i);
    if (i>0) json.append(',');
    json.append("{")
      .append("\"isbn\":\"").append(esc(String.valueOf(b.get("isbn")))).append("\",")
      .append("\"title\":\"").append(esc(String.valueOf(b.get("title")))).append("\",")
      .append("\"author\":\"").append(esc(String.valueOf(b.get("author")))).append("\",")
      .append("\"coverImage\":\"").append(esc(String.valueOf(b.get("coverImage")))).append("\",")
      .append("\"publicationYear\":").append(b.get("publicationYear")==null?"null":b.get("publicationYear"))
      .append("}");
  }
  json.append("]");
  out.print(json.toString());
%>
<%!
  private String esc(String s){
    if (s==null || "null".equals(s)) return "";
    return s.replace("\\","\\\\").replace("\"","\\\"")
            .replace("\b","\\b").replace("\f","\\f")
            .replace("\n","\\n").replace("\r","\\r").replace("\t","\\t");
  }
%>
