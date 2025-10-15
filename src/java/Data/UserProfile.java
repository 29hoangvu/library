package Data;

import java.util.Date;

public class UserProfile {
    private int userID;
    private String fullName;
    private String gender;
    private Date birthDate;
    private String phone;
    private String address;

    public UserProfile() {}

    public UserProfile(int userID, String fullName, String gender, Date birthDate, String phone, String address) {
        this.userID = userID;
        this.fullName = fullName;
        this.gender = gender;
        this.birthDate = birthDate;
        this.phone = phone;
        this.address = address;
    }

    // Getters & setters
    public int getUserID() { return userID; }
    public void setUserID(int userID) { this.userID = userID; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getGender() { return gender; }
    public void setGender(String gender) { this.gender = gender; }

    public Date getBirthDate() { return birthDate; }
    public void setBirthDate(Date birthDate) { this.birthDate = birthDate; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }
}
