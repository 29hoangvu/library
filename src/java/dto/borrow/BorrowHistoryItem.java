// src/dto/borrow/BorrowHistoryItem.java
//item lịch sử mượn
package dto.borrow;

import java.sql.Date;

public class BorrowHistoryItem {
    public int  borrowId;
    public String isbn;
    public String title;
    public String status;
    public Date borrowedDate;
    public Date dueDate;
    public Date returnDate;
}
