// src/dto/borrow/ReturnBorrowResult.java
package dto.borrow;

public class ReturnBorrowResult {
    public boolean success;
    public double fineAmount;   // tiền phạt (nếu có)
    public String message;      // message cho UI
}
