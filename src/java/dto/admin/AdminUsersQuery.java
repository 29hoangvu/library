// src/main/java/dto/admin/AdminUsersQuery.java
package dto.admin;

public class AdminUsersQuery {
    public String searchUsername;
    public Integer roleId; // null => all
    public int page;
    public int size;
}
