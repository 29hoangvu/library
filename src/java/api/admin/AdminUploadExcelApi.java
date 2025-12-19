package api.admin;

import com.google.gson.Gson;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import service.admin.ExcelImportService;
import service.admin.ExcelImportServiceImpl;

import java.io.InputStream;
import java.util.Map;

@WebServlet("/api/admin/upload-excel")
@MultipartConfig(maxFileSize = 20 * 1024 * 1024)
public class AdminUploadExcelApi extends HttpServlet {

    private final ExcelImportService service = new ExcelImportServiceImpl();
    private final Gson gson = new Gson();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) {
        resp.setContentType("application/json;charset=UTF-8");

        try {
            Part filePart = req.getPart("excelFile");
            if (filePart == null || filePart.getSize() == 0) {
                resp.setStatus(400);
                resp.getWriter().write("{\"success\":false,\"message\":\"Chưa chọn file Excel\"}");
                return;
            }

            try (InputStream is = filePart.getInputStream()) {
                Map<String, Object> result = service.importExcel(is);
                resp.getWriter().write(gson.toJson(result));
            }
        } catch (Exception e) {
            try {
                resp.setStatus(500);
                resp.getWriter().write(
                    gson.toJson(Map.of(
                        "success", false,
                        "message", e.getMessage()
                    ))
                );
            } catch (Exception ignore) {}
        }
    }
}
