// src/main/java/dto/admin/AdminUserItem.java
package dto.admin;

public class AdminUserItem {
    public int id;
    public String username;
    public int roleId;
    public String roleText;
    public String status;
    public String expiryDate; // String cho dễ JSON (ISO / null)
}
