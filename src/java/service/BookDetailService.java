package service;

import Servlet.DBConnection;
import dto.books.BookDetailDto;
import dto.books.RelatedBookDto;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class BookDetailService {

    /* =====================================================
     * LẤY CHI TIẾT SÁCH – KHỚP 100% bookDetails.jsp
     * ===================================================== */
    public BookDetailDto getBookDetail(String isbn) {

        BookDetailDto book = null;

        String sql = """
            SELECT
                b.id                AS book_id,
                b.isbn,
                b.title,
                a.name              AS author,
                b.publicationYear,
                b.format,
                b.coverImage,
                b.quantity          AS total_quantity,
                bd.description,
                r.rack_number,

                /* ===== ĐANG MƯỢN / CHỜ ===== */
                (
                    SELECT COUNT(*)
                    FROM borrow br
                    JOIN bookitem bi2 ON br.book_item_id = bi2.book_item_id
                    WHERE bi2.book_isbn = b.isbn
                      AND br.status IN ('PENDING','APPROVED','BORROWED')
                ) AS reserved_count,

                /* ===== LƯỢT ĐỌC EBOOK ===== */
                (
                    SELECT COUNT(*)
                    FROM ebook_read_log l
                    WHERE l.isbn = b.isbn
                ) AS views_total,

                g.name AS genre

            FROM book b
            JOIN author a ON b.authorId = a.id
            LEFT JOIN book_description bd ON b.isbn = bd.isbn
            LEFT JOIN bookitem bi ON b.isbn = bi.book_isbn
            LEFT JOIN rack r ON bi.rack_id = r.rack_id
            LEFT JOIN book_genre bg ON b.id = bg.book_id
            LEFT JOIN genre g ON bg.genre_id = g.id
            WHERE b.isbn = ?
        """;

        try (
            Connection conn = DBConnection.getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)
        ) {
            ps.setString(1, isbn);

            try (ResultSet rs = ps.executeQuery()) {

                List<String> genres = new ArrayList<>();

                while (rs.next()) {

                    // Lần đầu → khởi tạo object
                    if (book == null) {
                        book = new BookDetailDto();

                        book.isbn = rs.getString("isbn");
                        book.title = rs.getString("title");
                        book.author = rs.getString("author");
                        book.description = rs.getString("description");
                        book.format = rs.getString("format");
                        book.coverImage = rs.getString("coverImage");
                        book.publicationYear = rs.getInt("publicationYear");
                        book.viewsTotal = rs.getInt("views_total");

                        // ===== LOGIC CŨ GIỮ NGUYÊN =====
                        book.totalQuantity = rs.getInt("total_quantity");
                        book.reservedCount = rs.getInt("reserved_count");
                        book.availableCount =
                                Math.max(0, book.totalQuantity - book.reservedCount);

                        String rack = rs.getString("rack_number");
                        book.rackNumber = (rack != null ? rack : "Chưa sắp xếp");
                    }


                    // Gom genre (tránh trùng)
                    String g = rs.getString("genre");
                    if (g != null && !genres.contains(g)) {
                        genres.add(g);
                    }
                }

                if (book != null) {
                    book.genres.addAll(genres);
                }
            }

        } catch (SQLException e) {
            throw new RuntimeException("Lỗi lấy chi tiết sách: " + e.getMessage(), e);
        }

        return book;
    }

    /* =====================================================
     * LẤY SÁCH LIÊN QUAN – KHỚP JSP (sidebar)
     * ===================================================== */
    public List<RelatedBookDto> getRelatedBooks(String excludeIsbn, String genre, int limit) {

        List<RelatedBookDto> list = new ArrayList<>();
        if (genre == null) return list;

        String sql = """
            SELECT DISTINCT
                b.isbn,
                b.title,
                b.coverImage,
                a.name AS author
            FROM book b
            JOIN book_genre bg ON bg.book_id = b.id
            JOIN genre g ON g.id = bg.genre_id
            LEFT JOIN author a ON a.id = b.authorId
            WHERE g.name = ?
              AND b.isbn <> ?
              AND b.status = 'ACTIVE'
            ORDER BY b.id DESC
            LIMIT ?
        """;

        try (
            Connection conn = DBConnection.getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)
        ) {
            ps.setString(1, genre);
            ps.setString(2, excludeIsbn);
            ps.setInt(3, limit);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    RelatedBookDto rb = new RelatedBookDto();
                    rb.isbn = rs.getString("isbn");
                    rb.title = rs.getString("title");
                    rb.coverImage = rs.getString("coverImage");
                    rb.author = rs.getString("author");
                    list.add(rb);
                }
            }

        } catch (SQLException e) {
            throw new RuntimeException("Lỗi lấy sách liên quan: " + e.getMessage(), e);
        }

        return list;
    }
    
}
