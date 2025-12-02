// api/borrows/BorrowApi.java
package api.borrows;

import api.BaseApiServlet;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.io.OutputStream;
import java.text.SimpleDateFormat;
import java.util.*;

import service.BorrowService;
import dto.borrow.BorrowHistoryItem;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

@WebServlet(name = "BorrowApi", urlPatterns = {"/api/borrow"})
public class BorrowApi extends BaseApiServlet {
    private static final Gson GSON = new GsonBuilder().disableHtmlEscaping().create();
    private static final SimpleDateFormat ISO = new SimpleDateFormat("yyyy-MM-dd");

    private final BorrowService borrowService = new BorrowService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setCharacterEncoding("UTF-8");
        resp.setContentType("application/json; charset=UTF-8");

        try {
            Object uidObj = req.getAttribute("uid");
            if (uidObj == null) {
                writeJson(resp, Map.of("message", "Unauthorized"), 401);
                return;
            }
            int uid = (Integer) uidObj;

            // nếu có role trong JWT thì có thể cho admin xem tất cả
            String role = (String) req.getAttribute("role");
            boolean isAdmin = "ADMIN".equalsIgnoreCase(role);

            List<BorrowHistoryItem> list = borrowService.listUserBorrows(uid, isAdmin);

            List<Map<String,Object>> items = new ArrayList<>();
            for (BorrowHistoryItem b : list) {
                Map<String,Object> row = new LinkedHashMap<>();
                row.put("borrowId", b.borrowId);
                row.put("isbn",     b.isbn);
                row.put("title",    b.title);
                row.put("status",   b.status);
                row.put("borrowedDate", toIso(b.borrowedDate));
                row.put("dueDate",     toIso(b.dueDate));
                row.put("returnDate",  toIso(b.returnDate));
                items.add(row);
            }

            Map<String,Object> payload = Map.of(
                    "count", items.size(),
                    "items", items
            );
            writeJson(resp, payload, 200);

        } catch (Exception ex) {
            ex.printStackTrace();
            writeJson(resp, Map.of("message", "Internal error"), 500);
        }
    }

    private String toIso(java.util.Date d) {
        return d == null ? null : ISO.format(d);
    }

    private void writeJson(HttpServletResponse resp, Object obj, int status) throws IOException {
        String json = GSON.toJson(obj);
        byte[] data = json.getBytes(java.nio.charset.StandardCharsets.UTF_8);

        resp.setStatus(status);
        resp.setCharacterEncoding("UTF-8");
        resp.setContentType("application/json; charset=UTF-8");
        resp.setContentLength(data.length);

        try (OutputStream os = resp.getOutputStream()) {
            os.write(data);
            os.flush();
        }
    }
}
