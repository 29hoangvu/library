package Data;

import java.util.Date;

public class Users {
    private int id;
    private String username;
    private String password;
    private String status;
    private Date expiryDate;
    private int roleID;
    private String email;
    public Users(int id, String username, String password, String status, Date expiryDate, int roleID) {
        this.id = id;
        this.username = username;
        this.password = password;
        this.status = status;
        this.expiryDate = expiryDate;
        this.roleID = roleID;
    }
    public Users(int id, String username, int roleID, String status, Date expiryDate) {
        this.id = id;
        this.username = username;
        this.roleID = roleID;
        this.status = status;
        this.expiryDate = expiryDate;
    }   
    public Users(int id, String username, String password, String status, Date expiryDate, int roleID, String email) {
        this.id = id;
        this.username = username;
        this.password = password;
        this.status = status;
        this.expiryDate = expiryDate;
        this.roleID = roleID;
        this.email = email;
    }
    public Users(){}
    // Getters & Setters
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Date getExpiryDate() { return expiryDate; }
    public void setExpiryDate(Date expiryDate) { this.expiryDate = expiryDate; }

    public int getRoleID() { return roleID; }
    public void setRoleID(int roleID) { this.roleID = roleID; }
    
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
}
