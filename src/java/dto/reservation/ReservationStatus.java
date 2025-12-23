package dto.reservation;

public class ReservationStatus {

    private boolean hasReservation;
    private String status;
    private Integer queuePosition;
    private Integer waitingCount;

    public boolean isHasReservation() {
        return hasReservation;
    }

    public void setHasReservation(boolean hasReservation) {
        this.hasReservation = hasReservation;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Integer getQueuePosition() {
        return queuePosition;
    }

    public void setQueuePosition(Integer queuePosition) {
        this.queuePosition = queuePosition;
    }

    public Integer getWaitingCount() {
        return waitingCount;
    }

    public void setWaitingCount(Integer waitingCount) {
        this.waitingCount = waitingCount;
    }
}
