package Data;

import java.util.Date;

public class Books {
    private String isbn;
    private String title;
    private String subject;
    private String publisher;
    private Date publicationDate;
    private String language;
    private int numberOfPages;
    private String format;
    private int authorId;
    private int quantity;
    public Books(String isbn, String title, String subject, String publisher, Date publicationDate, String language, int numberOfPages, String format, int authorId) {
        this.isbn = isbn;
        this.title = title;
        this.subject = subject;
        this.publisher = publisher;
        this.publicationDate = publicationDate;
        this.language = language;
        this.numberOfPages = numberOfPages;
        this.format = format;
        this.authorId = authorId;
        this.quantity = quantity;
    }

    // Getters & Setters
    public String getIsbn() { return isbn; }
    public void setIsbn(String isbn) { this.isbn = isbn; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getSubject() { return subject; }
    public void setSubject(String subject) { this.subject = subject; }

    public String getPublisher() { return publisher; }
    public void setPublisher(String publisher) { this.publisher = publisher; }

    public Date getPublicationDate() { return publicationDate; }
    public void setPublicationDate(Date publicationDate) { this.publicationDate = publicationDate; }

    public String getLanguage() { return language; }
    public void setLanguage(String language) { this.language = language; }

    public int getNumberOfPages() { return numberOfPages; }
    public void setNumberOfPages(int numberOfPages) { this.numberOfPages = numberOfPages; }

    public String getFormat() { return format; }
    public void setFormat(String format) { this.format = format; }

    public int getAuthorId() { return authorId; }
    public void setAuthorId(int authorId) { this.authorId = authorId; }
    
    public int getQuantity(){ return quantity;}
    public void setQuantity(int quantity){ this.quantity= quantity; }
}
