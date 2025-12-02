// filters/AuthFilter.java  (JJWT 0.11.5)
package filters;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jws;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import util.JsonUtil;
import util.JwtUtil;

import java.io.IOException;
import java.util.Map;

public class AuthFilter implements Filter {
    @Override public void doFilter(ServletRequest r, ServletResponse s, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) r;
        HttpServletResponse resp = (HttpServletResponse) s;

        String path = req.getRequestURI();
        String ctx  = req.getContextPath();

        if (path.startsWith(ctx + "/api/auth/")) { chain.doFilter(r, s); return; }
        if (!path.startsWith(ctx + "/api/"))     { chain.doFilter(r, s); return; }

        String auth = req.getHeader("Authorization");
        if (auth == null || !auth.startsWith("Bearer ")) {
            JsonUtil.writeJson(resp, 401, Map.of("message","Missing or invalid Authorization header"));
            return;
        }
        try {
            Jws<Claims> jws = (Jws<Claims>) JwtUtil.verify(auth.substring(7));
            Claims c = jws.getBody();

            // uid có thể là Integer/Long -> lấy Number rồi intValue()
            Number uidNum = c.get("uid", Number.class);
            Number roleIdNum = c.get("roleID", Number.class);

            req.setAttribute("uid", uidNum == null ? null : uidNum.intValue());
            req.setAttribute("username", c.get("username", String.class));
            req.setAttribute("role", c.get("role", String.class));
            req.setAttribute("roleID", roleIdNum == null ? null : roleIdNum.intValue());
            // alias để FE dùng me.roleId cũng được
            req.setAttribute("roleId", roleIdNum == null ? null : roleIdNum.intValue());

            chain.doFilter(r, s);
        } catch (Exception e) {
            JsonUtil.writeJson(resp, 401, Map.of("message","Invalid token"));
        }
    }
}
