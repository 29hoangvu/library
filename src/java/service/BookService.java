// service/BookService.java
package service;

import Servlet.DBConnection;
import java.sql.*;
import java.util.*;

public class BookService {
    public Map<String,Object> getOne(String isbn) throws Exception {
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(
                 "SELECT isbn, title, publisher, publicationYear, language, numberOfPages, format FROM book WHERE isbn=?")) {
            ps.setString(1, isbn);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                Map<String,Object> m = new LinkedHashMap<>();
                m.put("isbn", rs.getString("isbn"));
                m.put("title", rs.getString("title"));
                m.put("publisher", rs.getString("publisher"));
                m.put("publicationYear", rs.getInt("publicationYear"));
                m.put("language", rs.getString("language"));
                m.put("numberOfPages", rs.getInt("numberOfPages"));
                m.put("format", rs.getString("format"));
                return m;
            }
        }
    }

    public List<Map<String,Object>> search(String q, int page, int size) throws Exception {
        String like = "%" + (q == null ? "" : q.trim()) + "%";
        int off = (page - 1) * size;
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(
                 "SELECT isbn, title, publisher, publicationYear FROM book " +
                 "WHERE title LIKE ? OR isbn LIKE ? ORDER BY title LIMIT ? OFFSET ?")) {
            ps.setString(1, like);
            ps.setString(2, like);
            ps.setInt(3, size);
            ps.setInt(4, off);
            try (ResultSet rs = ps.executeQuery()) {
                List<Map<String,Object>> list = new ArrayList<>();
                while (rs.next()) {
                    Map<String,Object> m = new LinkedHashMap<>();
                    m.put("isbn", rs.getString("isbn"));
                    m.put("title", rs.getString("title"));
                    m.put("publisher", rs.getString("publisher"));
                    m.put("publicationYear", rs.getInt("publicationYear"));
                    list.add(m);
                }
                return list;
            }
        }
    }

    public String create(Map<String,Object> b) throws Exception {
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(
                 "INSERT INTO book(isbn,title,publisher,publicationYear,language,numberOfPages,format) VALUES (?,?,?,?,?,?,?)")) {
            ps.setString(1, (String)b.get("isbn"));
            ps.setString(2, (String)b.get("title"));
            ps.setString(3, (String)b.get("publisher"));
            ps.setObject(4, b.get("publicationYear"));
            ps.setString(5, (String)b.get("language"));
            ps.setObject(6, b.get("numberOfPages"));
            ps.setString(7, (String)b.get("format"));
            ps.executeUpdate();
            return (String)b.get("isbn");
        }
    }
}
