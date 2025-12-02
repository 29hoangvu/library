// src/dto/borrow/BorrowRegisterResult.java
//Kết quả đăng ký mượn
package dto.borrow;

public class BorrowRegisterResult {
    public int borrowId;
    public int bookItemId;
    public String status;  // ví dụ: "Pending Approval"
    public int days;
}
