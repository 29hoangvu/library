package dto.books;

import java.util.ArrayList;
import java.util.List;

public class BookDetailDto {

    public String isbn;
    public String title;
    public String description;
    public String coverImage;
    public String author;

    public String format;              // HARDCOVER / PAPERBACK / EBOOK
    public Integer publicationYear;
    public Integer viewsTotal;

    // Sách giấy
    public int totalQuantity;
    public int reservedCount;
    public int availableCount;
    public String rackNumber;

    public List<String> genres = new ArrayList<>();

    public boolean isEbook() {
        return "EBOOK".equalsIgnoreCase(format);
    }
}
