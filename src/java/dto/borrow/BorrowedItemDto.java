package dto.borrow;

import java.sql.Date;

public class BorrowedItemDto {
    public int borrowId;
    public String isbn;
    public String title;
    public Date borrowedDate;
    public Date dueDate;
    public Date returnDate;
    public String status;
}
