package dto.books;

public class BookUpdateRequest {
    public String isbn;

    public String title;
    public String publisher;
    public String language;
    public String description;
    public String authorName;
    public String status;             // ACTIVE / DELETED
    public String format;
    public boolean formatEditEnabled;

    public String genreIdsCsv;        // "1,2,3"
    public String newGenresCsv;       // "Tiểu thuyết,Khoa học"

    public int publicationYear;
    public int numberOfPages;
    public int quantity;

    public String coverImagePath;     // "images/xxx.jpg" hoặc null
}
