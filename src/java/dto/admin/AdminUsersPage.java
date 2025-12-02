// src/main/java/dto/admin/AdminUsersPage.java
package dto.admin;

import java.util.List;

public class AdminUsersPage {
    public boolean ok;
    public String message;

    public int page;
    public int size;
    public long total;
    public int totalPages;

    public java.util.List<AdminUserItem> items;
}
