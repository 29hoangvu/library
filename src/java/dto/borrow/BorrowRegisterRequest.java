// src/dto/borrow/BorrowRegisterRequest.java
//Request đăng ký mượn
package dto.borrow;

public class BorrowRegisterRequest {
    public int userId;    // từ JWT
    public String isbn;   // sách cần mượn
    public int days;      // số ngày mượn (vd 7)
}
