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
        
        // ✅ CORS headers
        resp.setHeader("Access-Control-Allow-Origin", "*");
        resp.setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
        resp.setHeader("Access-Control-Allow-Headers", "Authorization, Content-Type");
        
        // ✅ Handle OPTIONS preflight
        if ("OPTIONS".equalsIgnoreCase(req.getMethod())) {
            resp.setStatus(HttpServletResponse.SC_OK);
            return;
        }
        
        // ✅ LOG REQUEST
        String path = req.getRequestURI();
        String method = req.getMethod();
        System.out.println("🔍 JwtFilter: " + method + " " + path);
        
        // ✅ Extract token
        String auth = req.getHeader("Authorization");
        System.out.println("  📋 Authorization header: " + (auth != null ? "Present" : "Missing"));
        
        if (auth != null && auth.startsWith("Bearer ")) {
            String token = auth.substring(7);
            System.out.println("  🎟️ Token extracted: " + token.substring(0, Math.min(20, token.length())) + "...");
            
            try {
                Map<String, Object> claims = JwtUtil.verify(token);
                
                // ✅ Gán attribute để các API đọc
                Object uid = claims.get("uid");
                Object username = claims.get("username");
                Object role = claims.get("role");
                Object roleID = claims.get("roleID");
                
                req.setAttribute("uid", uid);
                req.setAttribute("username", username);
                req.setAttribute("role", role);
                req.setAttribute("roleID", roleID);
                
                System.out.println("  ✅ JWT Valid - uid: " + uid + ", username: " + username + ", role: " + role);
                
            } catch (Exception e) {
                System.out.println("  ❌ JWT Invalid: " + e.getMessage());
                resp.setStatus(401);
                resp.setContentType("application/json;charset=UTF-8");
                resp.getWriter().write("{\"success\":false,\"message\":\"Invalid token\"}");
                return;
            }
        } else {
            System.out.println("  ⚠️ No Bearer token found - continuing anyway");
        }
        
        System.out.println("  ➡️ Passing to next filter/servlet");
        chain.doFilter(req, resp);
    }
    
    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        System.out.println("🚀 JwtFilter initialized - protecting /api/*");
    }
    
    @Override
    public void destroy() {
        System.out.println("🛑 JwtFilter destroyed");
    }
}