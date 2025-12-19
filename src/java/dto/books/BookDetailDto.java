// dto/book/BookDetailDto.java
package dto.books;

import java.util.List;

public class BookDetailDto {
    public String isbn;
    public String title;
    public String author;
    public String description;
    public String format;
    public String coverImage;
    public String rackNumber;
    public Integer publicationYear;
    public int viewsTotal;
    
    // Cho sách giấy
    public int totalQuantity;
    public int reservedCount;
    public int availableCount;
    
    // Thể loại
    public List<String> genres;
    
    public boolean isEbook() {
        return format != null && "EBOOK".equalsIgnoreCase(format);
    }
    
    public boolean isAvailable() {
        return isEbook() || availableCount > 0;
    }
}