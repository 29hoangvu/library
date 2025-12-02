<%@ page contentType="text/html; charset=UTF-8" isErrorPage="true" %>
<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Lỗi</title>
<style>body{font-family:ui-sans-serif,system-ui;padding:16px} pre{white-space:pre-wrap;background:#fafafa;border:1px solid #eee;padding:12px}</style>
</head><body>
  <h2>Đã có lỗi xảy ra</h2>
  <p><b>Exception:</b> <%= exception == null ? "(null)" : exception.getClass().getName() %></p>
  <p><b>Message:</b> <%= exception == null ? "" : exception.getMessage() %></p>
  <%
    Throwable root = exception;
    if (root instanceof jakarta.servlet.ServletException) {
      Throwable rc = ((jakarta.servlet.ServletException) root).getRootCause();
      if (rc != null) root = rc;
    }
  %>
  <p><b>Root cause:</b> <%= root == null ? "(null)" : root.getClass().getName() + ": " + root.getMessage() %></p>
  <h3>Stacktrace</h3>
  <pre><%
    if (root != null) {
      java.io.StringWriter sw = new java.io.StringWriter();
      java.io.PrintWriter  pw = new java.io.PrintWriter(sw);
      root.printStackTrace(pw);
      out.print(sw.toString());
    }
  %></pre>
</body></html>
