package filters;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import util.JwtUtil;

import java.io.IOException;
import java.util.Map;

@WebFilter("/api/*")
public class JwtFilter implements Filter {
    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse resp = (HttpServletResponse) response;

        String auth = req.getHeader("Authorization");
        if (auth != null && auth.startsWith("Bearer ")) {
            String token = auth.substring(7);
            try {
                Map<String,Object> claims = JwtUtil.verify(token);
                // gán attribute để các API đọc
                req.setAttribute("uid", claims.get("uid"));
                req.setAttribute("username", claims.get("username"));
                req.setAttribute("role", claims.get("role"));
                req.setAttribute("roleID", claims.get("roleID"));
            } catch (Exception e) {
                resp.setStatus(401);
                resp.setContentType("application/json;charset=UTF-8");
                resp.getWriter().write("{\"message\":\"Invalid token\"}");
                return;
            }
        }

        chain.doFilter(req, resp);
    }
}
