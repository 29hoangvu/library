// util/JwtUtil.java
package util;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.Map;

public class JwtUtil {
    private static final byte[] KEY_BYTES =
            "very-secret-key-change-me-32bytes!".getBytes(StandardCharsets.UTF_8);
    private static final SecretKey KEY = Keys.hmacShaKeyFor(KEY_BYTES);
    private static final long EXPIRE_MS = 1000L * 60 * 60; // 1h

    /** Phát hành token
     * @param claims
     * @return  */
    public static String issue(Map<String, Object> claims) {
        return Jwts.builder()
                .setClaims(claims)                           // với 0.11.5 phải setClaims()
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + EXPIRE_MS))
                .signWith(KEY, SignatureAlgorithm.HS256)     // nhớ chỉ rõ algorithm
                .compact();
    }

    /** Xác thực token và trả claims dạng Map
     * @param token
     * @return  */
    public static Map<String,Object> verify(String token) {
        Jws<Claims> jws = Jwts.parserBuilder()
                .setSigningKey(KEY)
                .build()
                .parseClaimsJws(token);

        Claims c = jws.getBody();
        Map<String,Object> out = new LinkedHashMap<>();
        out.put("uid",     asInt(c.get("uid")));
        out.put("username",c.get("username", String.class));
        out.put("role",    c.get("role",     String.class));
        out.put("roleID",  asInt(c.get("roleID")));
        return out;
    }

    private static Integer asInt(Object v) {
        return (v == null) ? null : ((Number) v).intValue();
    }
}
