package Data;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import Servlet.DBConnection;

public class BookDAO {
    public boolean addBook(Books book) {
        String sql = "INSERT INTO Book (ISBN, title, subject, publisher, publicationDate, language, numberOfPages, format, authorId) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, book.getIsbn());
            pstmt.setString(2, book.getTitle());
            pstmt.setString(3, book.getSubject());
            pstmt.setString(4, book.getPublisher());
            pstmt.setDate(5, new java.sql.Date(book.getPublicationDate().getTime()));
            pstmt.setString(6, book.getLanguage());
            pstmt.setInt(7, book.getNumberOfPages());
            pstmt.setString(8, book.getFormat());
            pstmt.setInt(9, book.getAuthorId());

            return pstmt.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
}
