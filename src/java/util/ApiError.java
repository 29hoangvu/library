// util/ApiError.java
package util;

public class ApiError {
    public final String message;
    public final String code;

    public ApiError(String message, String code) {
        this.message = message;
        this.code = code;
    }

    public static ApiError of(String message) { return new ApiError(message, "BAD_REQUEST"); }
}

