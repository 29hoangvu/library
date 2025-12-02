// dto/admin/AdminCreateUserRequest.java
package dto.admin;

public class AdminCreateUserRequest {
    public String username;
    public String email;
    public int roleId;

    // optional profile
    public String fullName;
    public String gender;
    public String birthDate; // yyyy-MM-dd
    public String phone;
    public String address;
}
