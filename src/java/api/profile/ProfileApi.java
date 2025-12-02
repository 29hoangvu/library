package api.profile;

import api.BaseApiServlet;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import util.JsonUtil;

import dto.profile.ProfileDto;
import dto.profile.ProfileUpdateRequest;
import service.profile.ProfileService;

import java.io.IOException;
import java.sql.Date;
import java.util.*;
import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet(name="ProfileApi", urlPatterns={"/api/profile"})
public class ProfileApi extends BaseApiServlet {

    private final ProfileService profileService = new ProfileService();

    // ===== GET: lấy thông tin hồ sơ theo uid từ JWT =====
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Object uidAttr = req.getAttribute("uid");
        if (uidAttr == null) {
            JsonUtil.writeJson(resp, 401, Map.of("message", "Unauthorized"));
            return;
        }
        int uid = (uidAttr instanceof Number)
                ? ((Number) uidAttr).intValue()
                : Integer.parseInt(String.valueOf(uidAttr));

        try {
            ProfileDto dto = profileService.getProfileByUserId(uid);
            if (dto == null) {
                JsonUtil.writeJson(resp, 404, Map.of("message", "User not found"));
                return;
            }

            // Map DTO -> JSON (giữ nguyên key như cũ)
            Map<String, Object> out = new LinkedHashMap<>();
            out.put("uid", dto.uid);
            out.put("username", dto.username);
            out.put("email", dto.email);
            out.put("status", dto.status);
            out.put("expiryDate", asIsoDate(dto.expiryDate));

            out.put("fullName", dto.fullName);
            out.put("gender", dto.gender);
            out.put("birthDate", asIsoDate(dto.birthDate));
            out.put("phone", dto.phone);
            out.put("address", dto.address);

            JsonUtil.writeJson(resp, 200, out);

        } catch (Exception e) {
            try {
                e.printStackTrace();
                JsonUtil.writeJson(resp, 500, Map.of("message", "Internal Error"));
            } catch (IOException ex) {
                Logger.getLogger(ProfileApi.class.getName()).log(Level.SEVERE, null, ex);
            }
        }
    }

    // ===== POST: cập nhật hồ sơ theo uid từ JWT =====
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        try {
            req.setCharacterEncoding("UTF-8");
            Object uidAttr = req.getAttribute("uid");
            if (uidAttr == null) {
                JsonUtil.writeJson(resp, 401, Map.of("message", "Unauthorized"));
                return;
            }
            int uid = (uidAttr instanceof Number)
                    ? ((Number) uidAttr).intValue()
                    : Integer.parseInt(String.valueOf(uidAttr));

            String fullName   = trimOrNull(req.getParameter("fullName"));
            String gender     = trimOrNull(req.getParameter("gender"));
            String birthDateS = trimOrNull(req.getParameter("birthDate"));
            String phone      = trimOrNull(req.getParameter("phone"));
            String address    = trimOrNull(req.getParameter("address"));

            Date birthDate = null;
            if (birthDateS != null && !birthDateS.isEmpty()) {
                // nhận "yyyy-MM-dd" từ <input type="date">
                birthDate = Date.valueOf(birthDateS); // có thể ném IllegalArgumentException
            }

            ProfileUpdateRequest dto = new ProfileUpdateRequest();
            dto.fullName  = fullName;
            dto.gender    = gender;
            dto.birthDate = birthDate;
            dto.phone     = phone;
            dto.address   = address;

            profileService.upsertProfile(uid, dto);

            JsonUtil.writeJson(resp, 200, Map.of("ok", true));

        } catch (IllegalArgumentException badDate) {
            JsonUtil.writeJson(resp, 400, Map.of("ok", false, "message", "Invalid date format"));
        } catch (Exception e) {
            e.printStackTrace();
            JsonUtil.writeJson(resp, 500, Map.of("ok", false, "message", "Internal Error"));
        }
    }

    // ===== helpers =====
    private static String asIsoDate(Date d) {
        return (d == null) ? null : d.toString(); // yyyy-MM-dd
    }
    private static String trimOrNull(String s) {
        if (s == null) return null;
        String t = s.trim();
        return t.isEmpty() ? null : t;
    }
}
