package api.recommendations;

import api.BaseApiServlet;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import dto.recommendation.RecommendationItemDto;
import service.recommendation.RecommendationService;
import util.JsonUtil;

import java.io.IOException;
import java.util.*;

@WebServlet(name="RecommendApi", urlPatterns={"/api/recommendations"})
public class RecommendApi extends BaseApiServlet {

    private final RecommendationService recommendationService = new RecommendationService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        try {
            Object uidObj = req.getAttribute("uid");
            if (uidObj == null) {
                // Chưa login / thiếu JWT
                JsonUtil.writeJson(resp, 401, Map.of("message", "Unauthorized"));
                return;
            }

            int uid;
            if (uidObj instanceof Number n) {
                uid = n.intValue();
            } else {
                uid = Integer.parseInt(String.valueOf(uidObj));
            }

            // Gọi service lấy danh sách gợi ý
            List<RecommendationItemDto> items = recommendationService.getRecommendationsForUser(uid);

            Map<String, Object> out = new LinkedHashMap<>();
            out.put("count", items.size());
            out.put("items", items);

            // Dùng helper của BaseApiServlet
            ok(resp, out);

        } catch (Exception e) {
            // Dùng helper safe500 để log + trả 500 JSON
            safe500(resp, e);
        }
    }
}

