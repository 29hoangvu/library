<%@ page contentType="application/json; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*,java.util.*,Servlet.DBConnection" %>

<%
  response.setCharacterEncoding("UTF-8");
  response.setHeader("Cache-Control","no-store, no-cache, must-revalidate, proxy-revalidate");
  response.setHeader("Pragma","no-cache");
  response.setDateHeader("Expires", 0L);

  String q = request.getParameter("q");
  String limitS = request.getParameter("limit");
  int limit = 8; 
  try { if (limitS!=null) limit = Math.max(1, Math.min(50, Integer.parseInt(limitS))); } catch(Exception ignore){}

  List<Map<String,Object>> rows = new ArrayList<>();

  try (Connection conn = DBConnection.getConnection()) {

    // Nếu không gõ gì / < 2 ký tự thì gợi ý mới nhất (giống cũ)
    if (q == null || q.trim().length() < 2) {
      String sql =
        "SELECT b.isbn,b.title,a.name AS author,b.coverImage,b.publicationYear " +
        "FROM book b LEFT JOIN author a ON a.id=b.authorId " +
        "WHERE UPPER(COALESCE(b.status,''))<>'DELETED' " +
        "ORDER BY (b.publicationYear IS NULL), b.publicationYear DESC " +
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
      // =========================================
      //   TRƯỜNG HỢP CÓ QUERY: LỌC FUZZY + KHÔNG DẤU
      // =========================================
      String qraw = q.trim();

      // Bắt số trang / năm giống code cũ
      String qlower = qraw.toLowerCase(Locale.ROOT);

      Integer pagesMin = null;
      java.util.regex.Matcher mPages = java.util.regex.Pattern.compile(
          "(?:>=|>\\s*=?|t(?:u|ừ)|it\\s*nhat|ít\\s*nhất)?\\s*(\\d{2,4})\\s*(?:trang|page|pages?)",
          java.util.regex.Pattern.CASE_INSENSITIVE | java.util.regex.Pattern.UNICODE_CASE
      ).matcher(qlower);
      if (mPages.find()) {
        try { pagesMin = Integer.valueOf(mPages.group(1)); } catch(Exception ignore){}
      }

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

      // --- SQL: chỉ lọc theo status + (pages/year nếu có), KHÔNG lọc theo text ---
      List<String> conds = new ArrayList<>();
      List<Object> params = new ArrayList<>();

      if (pagesMin != null) { 
        conds.add("COALESCE(b.numberOfPages,0) >= ?"); 
        params.add(pagesMin); 
      }
      if (yearEq != null) { 
        conds.add("COALESCE(b.publicationYear,0) = ?"); 
        params.add(yearEq); 
      }

      String whereExtra = conds.isEmpty() ? "" : (" AND " + String.join(" AND ", conds));

      String sql =
        "SELECT DISTINCT b.isbn, b.title, a.name AS author, b.coverImage, b.publicationYear " +
        "FROM book b " +
        "LEFT JOIN author a ON a.id = b.authorId " +
        "WHERE UPPER(COALESCE(b.status,'')) <> 'DELETED' " +
           whereExtra + " " +
        "ORDER BY (b.publicationYear IS NULL), b.publicationYear DESC " +
        "LIMIT 200";  // lấy rộng rồi tự lọc fuzzy ở Java

      List<Map<String,Object>> candidates = new ArrayList<>();

      try (PreparedStatement ps = conn.prepareStatement(sql)) {
        int i = 1;
        for (Object p : params) {
          if (p instanceof Integer) ps.setInt(i++, (Integer)p);
          else ps.setObject(i++, p);
        }

        try (ResultSet rs = ps.executeQuery()) {
          while (rs.next()) {
            Map<String,Object> m = new HashMap<>();
            m.put("isbn", rs.getString("isbn"));
            m.put("title", rs.getString("title"));
            m.put("author", rs.getString("author"));
            m.put("coverImage", rs.getString("coverImage"));
            m.put("publicationYear", rs.getObject("publicationYear"));
            candidates.add(m);
          }
        }
      }

      // --- Lọc fuzzy + không dấu ở Java ---
      for (Map<String,Object> b : candidates) {
        String title  = b.get("title")  == null ? "" : String.valueOf(b.get("title"));
        String author = b.get("author") == null ? "" : String.valueOf(b.get("author"));
        String text   = title + " " + author;

        if (fuzzyMatch(text, qraw)) {
          rows.add(b);
          if (rows.size() >= limit) break;
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
  // escape chuỗi trong JSON
  private String esc(String s){
    if (s==null || "null".equals(s)) return "";
    return s.replace("\\","\\\\").replace("\"","\\\"")
            .replace("\b","\\b").replace("\f","\\f")
            .replace("\n","\\n").replace("\r","\\r").replace("\t","\\t");
  }

  // Chuẩn hoá tiếng Việt: bỏ dấu + map đ/Đ -> d
  private String normalizeVi(String s) {
    if (s == null) return "";
    String r = java.text.Normalizer.normalize(s, java.text.Normalizer.Form.NFD);
    r = r.replaceAll("\\p{InCombiningDiacriticalMarks}+",""); // bỏ dấu
    r = r.replace('đ','d').replace('Đ','D');                  // đ -> d
    return r.toLowerCase(java.util.Locale.ROOT);
  }

  // fuzzy: các từ trong q phải xuất hiện theo thứ tự trong text
  private boolean fuzzyMatch(String text, String q) {
    text = normalizeVi(text);
    q    = normalizeVi(q);

    if (q.isEmpty()) return true;

    String[] parts = q.split("\\s+");
    int pos = 0;
    for (String part : parts) {
      if (part.isEmpty()) continue;
      pos = text.indexOf(part, pos);
      if (pos == -1) return false;
      pos += part.length();
    }
    return true;
  }
%>
