// filters/CorsFilter.java
package filters;

import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

public class CorsFilter implements Filter {
    @Override public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {
        HttpServletResponse resp = (HttpServletResponse) res;
        resp.setHeader("Access-Control-Allow-Origin", "*"); // hoặc domain cụ thể
        resp.setHeader("Access-Control-Allow-Methods", "GET,POST,PUT,DELETE,OPTIONS");
        resp.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");
        if ("OPTIONS".equalsIgnoreCase(req.getParameter("_method"))) { // hoặc kiểm tra method từ HttpServletRequest
            resp.setStatus(200);
            return;
        }
        chain.doFilter(req, res);
    }
}
