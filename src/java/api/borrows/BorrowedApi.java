package api.borrows;

import api.BaseApiServlet;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.*;

import dto.borrow.BorrowedItemDto;
import service.BorrowService;
import util.JsonUtil;

@WebServlet(name = "BorrowedApi", urlPatterns = {"/api/borrowed"})
public class BorrowedApi extends BaseApiServlet {

    private final BorrowService borrowService = new BorrowService();
    private static final SimpleDateFormat ISO = new SimpleDateFormat("yyyy-MM-dd");

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Integer uid = safeGetUid(req.getAttribute("uid"));
        if (uid == null) {
            JsonUtil.writeJson(resp, 401, Map.of(
                    "ok", false,
                    "message", "Unauthorized"
            ));
            return;
        }

        try {
            List<BorrowedItemDto> list = borrowService.listBorrowedByUser(uid);
            List<Map<String,Object>> items = new ArrayList<>();

            for (BorrowedItemDto dto : list) {
                Map<String,Object> row = new LinkedHashMap<>();
                row.put("borrowId",    dto.borrowId);
                row.put("isbn",        dto.isbn);
                row.put("title",       dto.title);
                row.put("borrowedDate", toIso(dto.borrowedDate));
                row.put("dueDate",      toIso(dto.dueDate));
                row.put("returnDate",   toIso(dto.returnDate));
                row.put("status",       normStatus(dto.status));
                items.add(row);
            }

            JsonUtil.writeJson(resp, 200, Map.of(
                    "ok", true,
                    "count", items.size(),
                    "items", items
            ));

        } catch (Exception e) {
            e.printStackTrace();
            JsonUtil.writeJson(resp, 500, Map.of(
                    "ok", false,
                    "message", "Internal error"
            ));
        }
    }

    // ===== helpers =====
    private Integer safeGetUid(Object uidObj) {
        if (uidObj == null) return null;
        try {
            if (uidObj instanceof Integer i) return i;
            if (uidObj instanceof Long l) return Math.toIntExact(l);
            if (uidObj instanceof String s) return Integer.parseInt(s);
        } catch (Exception ignored) {}
        return null;
    }

    private String toIso(java.sql.Date d) {
        return d == null ? null : ISO.format(d);
    }

    private String normStatus(String s) {
        return s == null ? "" : s.trim();
    }
}
