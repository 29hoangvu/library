// src/main/java/dto/admin/PendingUsersPage.java
package dto.admin;

import java.util.List;

public class PendingUsersPage {
    public boolean ok;
    public String message;

    public int page;
    public int size;
    public long total;
    public int totalPages;

    public List<PendingUserItem> items;
}
