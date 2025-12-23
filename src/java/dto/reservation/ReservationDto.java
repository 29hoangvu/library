package dto.reservation;

/**
 * DTO cho API reservation
 * ❗ KHÔNG dùng java.time
 * 
 * ✅ GIẢI PHÁP: Dùng PUBLIC FIELD để Gson tự động serialize
 */
public class ReservationDto {
    // ✅ FIX: Đổi thành public để Gson serialize
    public Integer id;
    
    private Integer userId;
    public String isbn;
    public String reservationDate; // yyyy-MM-dd HH:mm:ss
    public String status;
    private String notifiedDate;
    private String expiryDate;
    private String notes;
    private String userName;
    private String userEmail;
    public String bookTitle;
    public String bookCover;
    public String authorName;
    public Integer queuePosition;
    public Integer totalWaiting;
    private Integer availableCount;
    private String createdAt;
    private String updatedAt;

    // ===== getters & setters =====
    
    public Integer getId() { 
        return id; 
    }
    
    public void setId(Integer id) { 
        this.id = id; 
    }

    public Integer getUserId() { return userId; }
    public void setUserId(Integer userId) { this.userId = userId; }

    public String getIsbn() { return isbn; }
    public void setIsbn(String isbn) { this.isbn = isbn; }

    public String getReservationDate() { return reservationDate; }
    public void setReservationDate(String reservationDate) { this.reservationDate = reservationDate; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getNotifiedDate() { return notifiedDate; }
    public void setNotifiedDate(String notifiedDate) { this.notifiedDate = notifiedDate; }

    public String getExpiryDate() { return expiryDate; }
    public void setExpiryDate(String expiryDate) { this.expiryDate = expiryDate; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public String getUserName() { return userName; }
    public void setUserName(String userName) { this.userName = userName; }

    public String getUserEmail() { return userEmail; }
    public void setUserEmail(String userEmail) { this.userEmail = userEmail; }

    public String getBookTitle() { return bookTitle; }
    public void setBookTitle(String bookTitle) { this.bookTitle = bookTitle; }

    public String getBookCover() { return bookCover; }
    public void setBookCover(String bookCover) { this.bookCover = bookCover; }

    public String getAuthorName() { return authorName; }
    public void setAuthorName(String authorName) { this.authorName = authorName; }

    public Integer getQueuePosition() { return queuePosition; }
    public void setQueuePosition(Integer queuePosition) { this.queuePosition = queuePosition; }

    public Integer getTotalWaiting() { return totalWaiting; }
    public void setTotalWaiting(Integer totalWaiting) { this.totalWaiting = totalWaiting; }

    public Integer getAvailableCount() { return availableCount; }
    public void setAvailableCount(Integer availableCount) { this.availableCount = availableCount; }

    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }

    public String getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(String updatedAt) { this.updatedAt = updatedAt; }
    public int getReservationId() {
        return this.id;
    }
}