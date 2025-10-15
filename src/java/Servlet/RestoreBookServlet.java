package Servlet;

import jakarta.servlet.ServletException;

import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;

public class RestoreBookServlet extends HttpServlet {
  @Override
  protected void doPost(HttpServletRequest req, HttpServletResponse resp)
      throws ServletException, IOException {
    req.setCharacterEncoding("UTF-8");
    String isbn = req.getParameter("isbn");

    if (isbn == null || isbn.isBlank()) {
      resp.setStatus(400);
      resp.getWriter().write("Missing isbn");
      return;
    }

    try (Connection conn = DBConnection.getConnection();
         PreparedStatement ps = conn.prepareStatement(
           "UPDATE book SET status='ACTIVE' WHERE isbn=?")) {
      ps.setString(1, isbn);
      int n = ps.executeUpdate();
      if (n == 0) {
        resp.setStatus(404);
        resp.getWriter().write("Not found");
      } else {
        resp.setStatus(200);
        resp.getWriter().write("OK");
      }
    } catch (Exception e) {
      resp.setStatus(500);
      resp.getWriter().write("Error: " + e.getMessage());
    }
  }
}
