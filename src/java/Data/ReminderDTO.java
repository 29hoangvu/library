/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package Data;

import java.util.Date;

/**
 *
 * @author nvu08
 */
public class ReminderDTO {
    public int userId;
    public String username;
    public String email;
    // For DUE:
    public Integer borrowId;
    public String bookTitle;
    public Date dueDate;
    // For EXPIRY:
    public Date expiryDate;
}
