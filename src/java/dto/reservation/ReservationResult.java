package dto.reservation;

public class ReservationResult {

    private final int result;
    private final String message;

    public ReservationResult(int result, String message) {
        this.result = result;
        this.message = message;
    }

    /** result > 0 = success */
    public boolean isSuccess() {
        return result > 0;
    }

    public int getResult() {
        return result;
    }

    public String getMessage() {
        return message;
    }
}
