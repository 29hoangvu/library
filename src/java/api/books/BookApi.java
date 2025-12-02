// api/books/BookApi.java
package api.books;

import api.BaseApiServlet;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import service.BookService;
import util.JsonUtil;

import java.util.*;

@WebServlet(name="BookApi", urlPatterns={"/api/books/*"})
public class BookApi extends BaseApiServlet {
    private final BookService svc = new BookService();

    @Override protected void doGet(HttpServletRequest req, HttpServletResponse resp) {
        try {
            String path = req.getPathInfo(); // may be null or like "/{isbn}"
            if (path != null && path.length() > 1) {
                String isbn = path.substring(1);
                var one = svc.getOne(isbn);
                if (one == null) { resp.setStatus(404); JsonUtil.writeJson(resp, 404, Map.of("message","Not Found")); return; }
                ok(resp, one);
                return;
            }
            String q = req.getParameter("q");
            int page = parseInt(req.getParameter("page"), 1);
            int size = parseInt(req.getParameter("size"), 20);
            ok(resp, svc.search(q, page, size));
        } catch (Exception e) {
            safe500(resp, e);
        }
    }

    @Override protected void doPost(HttpServletRequest req, HttpServletResponse resp) {
        
        try {
            Map body = readJson(req, Map.class);
            String isbn = svc.create(body);
            created(resp, Map.of("isbn", isbn));
        } catch (Exception e) {
            safe500(resp, e);
        }
    }

    private int parseInt(String s, int def) {
        try { return s == null ? def : Integer.parseInt(s); } catch(Exception e){ return def; }
    }
}
