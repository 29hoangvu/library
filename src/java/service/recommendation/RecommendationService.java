package service.recommendation;


import Servlet.DBConnection;
import Servlet.RecoClient;
import dto.recommendation.RecommendationItemDto;

import java.sql.*;
import java.util.*;

public class RecommendationService {

    /**
     * Lấy danh sách sách gợi ý cho userId:
     * - Gọi RecoClient để lấy list ISBN
     * - Khử trùng lặp giữ thứ tự
     * - Lọc bỏ sách user đã mượn (Borrowed/Returned/Overdue)
     * - Trả về list DTO theo đúng thứ tự gợi ý
     */
    public List<RecommendationItemDto> getRecommendationsForUser(int userId) throws Exception {
        // 1) Gọi service gợi ý để lấy danh sách ISBN
        List<String> recIsbns = RecoClient.getIsbnForUser(userId);
        if (recIsbns == null || recIsbns.isEmpty()) {
            return Collections.emptyList();
        }

        // Khử trùng lặp theo thứ tự
        LinkedHashSet<String> uniq = new LinkedHashSet<>(recIsbns);
        recIsbns = new ArrayList<>(uniq);

        // 2) Query DB lấy thông tin sách (giữ thứ tự bằng FIELD)
        String placeholders = String.join(",", Collections.nCopies(recIsbns.size(), "?"));
        String orderBy      = String.join(",", Collections.nCopies(recIsbns.size(), "?"));

        String sql =
            "SELECT b.isbn, b.title, a.name AS author, b.publicationYear, b.format, b.coverImage " +
            "FROM book b " +
            "LEFT JOIN author a ON b.authorId = a.id " +
            "WHERE b.isbn IN (" + placeholders + ") " +
            "AND NOT EXISTS ( " +
            "  SELECT 1 FROM borrow br " +
            "  JOIN bookitem bi ON bi.book_item_id = br.book_item_id " +
            "  WHERE br.user_id = ? " +
            "    AND br.status IN ('Borrowed','Returned','Overdue') " +
            "    AND bi.book_isbn = b.isbn " +
            ") " +
            "ORDER BY FIELD(b.isbn, " + orderBy + ")";

        List<RecommendationItemDto> items = new ArrayList<>();

        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {

            int i = 1;
            // IN(...)
            for (String s : recIsbns) {
                ps.setString(i++, s);
            }
            // user_id
            ps.setInt(i++, userId);
            // FIELD(...)
            for (String s : recIsbns) {
                ps.setString(i++, s);
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    RecommendationItemDto dto = new RecommendationItemDto();
                    dto.isbn          = rs.getString("isbn");
                    dto.title         = rs.getString("title");
                    dto.author        = rs.getString("author");
                    dto.publishedYear = rs.getInt("publicationYear");
                    dto.format        = rs.getString("format");
                    dto.coverImage    = rs.getString("coverImage");
                    items.add(dto);
                }
            }
        }

        return items;
    }
}
