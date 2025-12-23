package service;

import Servlet.DBConnection;
import dto.reservation.ReservationDto;
import dto.reservation.ReservationResult;
import dto.reservation.ReservationStatus;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class ReservationService {

    /* =====================================================
     * 1️⃣ USER ĐÃ CÓ ĐẶT TRƯỚC CHƯA
     * ===================================================== */
    public boolean hasActiveReservation(int userId, String isbn) {

        String sql = """
            SELECT 1
            FROM book_reservations
            WHERE user_id = ?
              AND isbn = ?
              AND status IN ('PENDING', 'NOTIFIED')
            LIMIT 1
        """;

        try (
            Connection conn = DBConnection.getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)
        ) {
            ps.setInt(1, userId);
            ps.setString(2, isbn);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    /* =====================================================
     * 2️⃣ TỔNG SỐ NGƯỜI ĐANG CHỜ
     * ===================================================== */
    public int getWaitingCount(String isbn) {

        String sql = """
            SELECT COUNT(*)
            FROM book_reservations
            WHERE isbn = ?
              AND status = 'PENDING'
        """;

        try (
            Connection conn = DBConnection.getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)
        ) {
            ps.setString(1, isbn);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    /* =====================================================
     * 3️⃣ VỊ TRÍ HÀNG CHỜ
     * ===================================================== */
    public Integer getQueuePosition(int userId, String isbn) {
        String sql = """
            SELECT queue_position
            FROM v_user_reservations
            WHERE user_id = ?
              AND isbn = ?
              AND status IN ('PENDING','NOTIFIED')
        """;

        try (
            Connection conn = DBConnection.getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)
        ) {
            ps.setInt(1, userId);
            ps.setString(2, isbn);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt("queue_position") : null;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    /* =====================================================
     * 4️⃣ STATUS ĐẶT TRƯỚC (API /status)
     * ===================================================== */
    public ReservationStatus getReservationStatus(int userId, String isbn) {

        String sql = """
            SELECT status, queue_position, total_waiting
            FROM v_user_reservations
            WHERE user_id = ?
              AND isbn = ?
              AND status IN ('PENDING', 'NOTIFIED')
            LIMIT 1
        """;

        try (
            Connection conn = DBConnection.getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)
        ) {
            ps.setInt(1, userId);
            ps.setString(2, isbn);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    ReservationStatus st = new ReservationStatus();
                    st.setHasReservation(true);
                    st.setStatus(rs.getString("status"));
                    st.setQueuePosition(rs.getInt("queue_position"));
                    st.setWaitingCount(rs.getInt("total_waiting"));
                    return st;
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    /* =====================================================
     * 5️⃣ TẠO ĐẶT TRƯỚC
     * ===================================================== */
    public ReservationResult createReservation(int userId, String isbn) {

        String sql = "{CALL sp_create_reservation(?, ?, ?, ?)}";

        try (
            Connection conn = DBConnection.getConnection();
            var cs = conn.prepareCall(sql)
        ) {
            cs.setInt(1, userId);
            cs.setString(2, isbn);
            cs.registerOutParameter(3, java.sql.Types.INTEGER);
            cs.registerOutParameter(4, java.sql.Types.VARCHAR);

            cs.execute();
            return new ReservationResult(cs.getInt(3), cs.getString(4));

        } catch (SQLException e) {
            e.printStackTrace();
            return new ReservationResult(-99, "Lỗi hệ thống");
        }
    }

    /* =====================================================
     * 6️⃣ HỦY ĐẶT TRƯỚC
     * ===================================================== */
    public ReservationResult cancelReservation(int reservationId, int userId) {

        String sql = "{CALL sp_cancel_reservation(?, ?, ?, ?)}";

        try (
            Connection conn = DBConnection.getConnection();
            var cs = conn.prepareCall(sql)
        ) {
            cs.setInt(1, reservationId);
            cs.setInt(2, userId);
            cs.registerOutParameter(3, java.sql.Types.INTEGER);
            cs.registerOutParameter(4, java.sql.Types.VARCHAR);

            cs.execute();
            return new ReservationResult(cs.getInt(3), cs.getString(4));

        } catch (SQLException e) {
            e.printStackTrace();
            return new ReservationResult(-99, "Lỗi hệ thống");
        }
    }

    /* =====================================================
     * 7️⃣ TẤT CẢ ĐẶT TRƯỚC CỦA USER
     * ===================================================== */
    public List<ReservationDto> getUserReservations(int userId) {

        List<ReservationDto> list = new ArrayList<>();

        String sql = """
            SELECT *
            FROM v_user_reservations
            WHERE user_id = ?
            ORDER BY reservation_date DESC
        """;

        try (
            Connection conn = DBConnection.getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)
        ) {
            ps.setInt(1, userId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ReservationDto dto = mapReservation(rs);
                    list.add(dto);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    /* =====================================================
     * 8️⃣ ĐẶT TRƯỚC ĐANG HIỆU LỰC
     * ===================================================== */
    public List<ReservationDto> getUserActiveReservations(int userId) {

        List<ReservationDto> list = new ArrayList<>();

        String sql = """
            SELECT *
            FROM v_user_reservations
            WHERE user_id = ?
              AND status IN ('PENDING', 'NOTIFIED')
            ORDER BY reservation_date ASC
        """;

        try (
            Connection conn = DBConnection.getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)
        ) {
            ps.setInt(1, userId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ReservationDto dto = mapReservation(rs);
                    list.add(dto);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }
    public ReservationResult cancelByIsbn(int userId, String isbn) {

        String sql = """
            SELECT reservation_id
            FROM book_reservations
            WHERE user_id = ?
              AND isbn = ?
              AND status IN ('PENDING','NOTIFIED')
            LIMIT 1
        """;

        try (
            Connection c = DBConnection.getConnection();
            PreparedStatement ps = c.prepareStatement(sql)
        ) {
            ps.setInt(1, userId);
            ps.setString(2, isbn);

            ResultSet rs = ps.executeQuery();
            if (!rs.next()) {
                return new ReservationResult(-1, "Không tìm thấy đặt trước");
            }

            int reservationId = rs.getInt("reservation_id");
            return cancelReservation(reservationId, userId);

        } catch (Exception e) {
            e.printStackTrace();
            return new ReservationResult(-99, "Lỗi hệ thống");
        }
    }

    /* =====================================================
     * 🔧 MAP RESULTSET → DTO (STRING DATE)
     * ✅ FIX: Sử dụng setId() thay vì gán trực tiếp reservationId
     * ===================================================== */
    private ReservationDto mapReservation(ResultSet rs) throws SQLException {

        ReservationDto dto = new ReservationDto();

        // ✅ FIX: Set ID đúng cách
        dto.setId(rs.getInt("reservation_id"));
        dto.setUserId(rs.getInt("user_id"));
        dto.setIsbn(rs.getString("isbn"));

        dto.setReservationDate(rs.getString("reservation_date"));
        dto.setStatus(rs.getString("status"));
        dto.setNotifiedDate(rs.getString("notified_date"));
        dto.setExpiryDate(rs.getString("expiry_date"));
        dto.setNotes(rs.getString("notes"));

        dto.setUserName(rs.getString("user_name"));
        dto.setUserEmail(rs.getString("user_email"));

        dto.setBookTitle(rs.getString("book_title"));
        dto.setBookCover(rs.getString("book_cover"));
        dto.setAuthorName(rs.getString("author_name"));

        dto.setQueuePosition(rs.getObject("queue_position", Integer.class));
        dto.setTotalWaiting(rs.getObject("total_waiting", Integer.class));
        dto.setAvailableCount(rs.getObject("available_count", Integer.class));

        dto.setCreatedAt(rs.getString("created_at"));
        dto.setUpdatedAt(rs.getString("updated_at"));

        return dto;
    }
}