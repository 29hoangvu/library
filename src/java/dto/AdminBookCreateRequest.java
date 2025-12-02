// src/dto/AdminBookCreateRequest.java
package dto;

import java.time.LocalDate;

public class AdminBookCreateRequest {
    public String isbn;
    public String title;
    public String publisher;
    public int    publicationYear;
    public String language;
    public int    numberOfPages;
    public String format;

    public String authorName;
    public String isNewAuthor;      // "true"/"false"/null
    public String authorIdParam;    // id tác giả cũ, nếu có

    public String genreIdsCsv;      // "1,2,3"
    public String newGenresCsv;     // "Tiểu thuyết, Khoa học"

    public int    quantity;
    public double price;
    public LocalDate dateOfPurchase;

    public String coverImagePath;   // "images/xxx.jpg"
    public EbookAssetInfo ebookAsset; // có thể null nếu không phải EBOOK
}
