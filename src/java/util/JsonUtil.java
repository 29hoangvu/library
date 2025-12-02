// util/JsonUtil.java
package util;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.ByteArrayOutputStream;

public class JsonUtil {
    public static final ObjectMapper MAPPER = new ObjectMapper()
        .enable(SerializationFeature.INDENT_OUTPUT)
        .setSerializationInclusion(JsonInclude.Include.NON_NULL);
    
    public static void writeJson(HttpServletResponse resp, int status, Object data) throws IOException {
        // 1) Serialize vào bộ nhớ trước
        ByteArrayOutputStream buf = new ByteArrayOutputStream(4096);
        MAPPER.writeValue(buf, data);
        byte[] payload = buf.toByteArray();

        // 2) Set header rõ ràng (tránh chunked)
        resp.resetBuffer(); // xóa mọi thứ đã ghi (nếu có) trước khi commit
        resp.setStatus(status);
        resp.setCharacterEncoding("UTF-8");
        resp.setContentType("application/json; charset=UTF-8");
        resp.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        resp.setHeader("Pragma", "no-cache");
        resp.setDateHeader("Expires", 0);
        resp.setContentLength(payload.length);

        // 3) Ghi đúng 1 lần
        resp.getOutputStream().write(payload);
        resp.getOutputStream().flush();
        // KHÔNG đóng OutputStream (container quản lý), KHÔNG ghi thêm gì sau đây
    }
}
