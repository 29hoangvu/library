// service/BookService.java
package service;

import Servlet.DBConnection;
import dto.books.BookDetailDto;
import dto.books.RelatedBookDto;

import java.sql.*;
import java.util.*;

public class BookDetailService {

    /**
     * Lấy thông tin chi tiết sách bao gồm availability
     */
    public BookDetailDto getBookDetail(String isbn) throws SQLException {
        if (isbn == null || isbn.trim().isEmpty()) {
            throw new IllegalArgumentException("ISBN không được để trống");
        }

        BookDetailDto book = new BookDetailDto();
        book.isbn = isbn;
        book.genres = new ArrayList<>();

        try (Connection conn = DBConnection.getConnection()) {
            // 1) Query thông tin cơ bản
            String sql = """
                SELECT b.title, a.name AS author, b.publicationYear, b.format, 
                       b.coverImage, bd.description, r.rack_number, g.name AS genre, 
                       b.quantity,
                       (SELECT COUNT(*) FROM ebook_read_log l WHERE l.isbn = b.isbn) AS views_total
                FROM book b
                JOIN author a ON b.authorId = a.id
                LEFT JOIN book_description bd ON b.isbn = bd.isbn
                LEFT JOIN bookitem bi ON b.isbn = bi.book_isbn
                LEFT JOIN rack r ON bi.rack_id = r.rack_id
                LEFT JOIN book_genre bg ON b.id = bg.book_id
                LEFT JOIN genre g ON bg.genre_id = g.id
                WHERE b.isbn = ?
            """;

            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setString(1, isbn);
                try (ResultSet rs = stmt.executeQuery()) {
                    boolean found = false;
                    while (rs.next()) {
                        if (!found) {
                            book.title = rs.getString("title");
                            book.author = rs.getString("author");
                            book.description = rs.getString("description");
                            book.format = rs.getString("format");
                            book.coverImage = rs.getString("coverImage");
                            book.rackNumber = rs.getString("rack_number");
                            
                            int pubY = rs.getInt("publicationYear");
                            book.publicationYear = pubY > 0 ? pubY : null;
                            
                            book.totalQuantity = rs.getInt("quantity");
                            book.viewsTotal = rs.getInt("views_total");
                            
                            found = true;
                        }
                        
                        String genre = rs.getString("genre");
                        if (genre != null && !book.genres.contains(genre)) {
                            book.genres.add(genre);
                        }
                    }
                    
                    if (!found) {
                        return null; // Không tìm thấy sách
                    }
                }
            }

            // 2) Tính availability cho sách giấy
            if (!book.isEbook()) {
                String availSql = """
                    SELECT COALESCE(COUNT(br.borrow_id), 0) AS reserved
                    FROM bookitem bi
                    LEFT JOIN borrow br ON bi.book_item_id = br.book_item_id 
                        AND br.status IN ('Borrowed', 'Pending Approval')
                    WHERE bi.book_isbn = ?
                """;
                
                try (PreparedStatement ps = conn.prepareStatement(availSql)) {
                    ps.setString(1, isbn);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            book.reservedCount = rs.getInt("reserved");
                        }
                    }
                }
                
                book.availableCount = book.totalQuantity - book.reservedCount;
                if (book.availableCount < 0) {
                    book.availableCount = 0;
                }
                
                System.out.println("=== BOOK AVAILABILITY ===");
                System.out.println("ISBN: " + isbn);
                System.out.println("Total: " + book.totalQuantity);
                System.out.println("Reserved: " + book.reservedCount);
                System.out.println("Available: " + book.availableCount);
            }
        }

        return book;
    }

    /**
     * Lấy sách liên quan cùng thể loại
     */
    public List<RelatedBookDto> getRelatedBooks(String isbn, String genreName, int limit) throws SQLException {
        List<RelatedBookDto> result = new ArrayList<>();
        
        if (genreName == null || genreName.trim().isEmpty()) {
            return result;
        }

        String sql = """
            SELECT DISTINCT b.isbn, b.title, b.coverImage, a.name AS author
            FROM book b
            JOIN book_genre bg ON bg.book_id = b.id
            JOIN genre g ON g.id = bg.genre_id
            LEFT JOIN author a ON a.id = b.authorId
            WHERE g.name = ? AND b.isbn <> ? AND b.status = 'ACTIVE'
            ORDER BY b.id DESC
            LIMIT ?
        """;

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setString(1, genreName);
            ps.setString(2, isbn);
            ps.setInt(3, limit);
            
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    RelatedBookDto book = new RelatedBookDto();
                    book.isbn = rs.getString("isbn");
                    book.title = rs.getString("title");
                    book.coverImage = rs.getString("coverImage");
                    book.author = rs.getString("author");
                    result.add(book);
                }
            }
        }

        return result;
    }
}