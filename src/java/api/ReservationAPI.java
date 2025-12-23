package api;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import dto.reservation.ReservationDto;
import service.ReservationService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;
import dto.reservation.ReservationResult;

// ✅ CRITICAL: Annotation này BẮT BUỘC phải có!
@WebServlet(name = "ReservationAPI", urlPatterns = {"/api/reservation/*"})
public class ReservationAPI extends HttpServlet {

    private final Gson gson = new Gson();
    private final ReservationService reservationService = new ReservationService();

    @Override
    public void init() throws ServletException {
        super.init();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String pathInfo = request.getPathInfo();

        if (pathInfo == null || pathInfo.equals("/")) {
            sendErrorResponse(response, 400, "Missing endpoint");
            return;
        }

        // ✅ LẤY USER ID TỪ JWT FILTER
        Object uidObj = request.getAttribute("uid");
        
        if (uidObj == null) {
            sendErrorResponse(response, 401, "Unauthorized - Token required");
            return;
        }
        
        int userId;
        try {
            userId = ((Number) uidObj).intValue();
        } catch (Exception e) {
            sendErrorResponse(response, 401, "Invalid user ID");
            return;
        }

        try {
            switch (pathInfo) {
                case "/my-list":
                    handleGetMyReservations(request, response, userId);
                    break;
                case "/status":
                    
                    handleCheckReservationStatus(request, response, userId);
                    break;
                case "/check":
                    handleCheckReservationStatus(request, response, userId);
                    break;
                default:
                    sendErrorResponse(response, 404, "Endpoint not found: " + pathInfo);
            }
        } catch (Exception e) {
            System.out.println("💥 Exception in doGet: " + e.getMessage());
            e.printStackTrace();
            sendErrorResponse(response, 500, "Internal server error: " + e.getMessage());
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String pathInfo = request.getPathInfo();

        if (pathInfo == null || pathInfo.equals("/")) {
            sendErrorResponse(response, 400, "Missing endpoint");
            return;
        }

        // ✅ LẤY USER ID TỪ JWT FILTER
        Object uidObj = request.getAttribute("uid");
        
        if (uidObj == null) {
            sendErrorResponse(response, 401, "Unauthorized - Token required");
            return;
        }
        
        int userId;
        try {
            userId = ((Number) uidObj).intValue();
        } catch (Exception e) {
            sendErrorResponse(response, 401, "Invalid user ID");
            return;
        }

        try {
            switch (pathInfo) {
                case "/create":
                    handleCreateReservation(request, response, userId);
                    break;
                case "/cancel":
                    handleCancelReservation(request, response, userId);
                    break;
                default:
                    sendErrorResponse(response, 404, "Endpoint not found: " + pathInfo);
            }
        } catch (Exception e) {
            e.printStackTrace();
            sendErrorResponse(response, 500, "Internal server error: " + e.getMessage());
        }
    }

    /* ====================== HANDLERS ====================== */

    private void handleCreateReservation(HttpServletRequest request,
                                         HttpServletResponse response,
                                         int userId) throws IOException {

        JsonObject jsonRequest = parseRequestBody(request);
        if (jsonRequest == null || !jsonRequest.has("isbn")) {
            sendErrorResponse(response, 400, "Missing ISBN in request body");
            return;
        }

        String isbn = jsonRequest.get("isbn").getAsString().trim();
        
        if (isbn.isEmpty()) {
            sendErrorResponse(response, 400, "ISBN cannot be empty");
            return;
        }

        ReservationResult result = reservationService.createReservation(userId, isbn);

        if (result.isSuccess()) {
            sendSuccessResponse(response, result.getMessage());
        } else {
            sendErrorResponse(response, 400, result.getMessage());
        }
    }

    private void handleCancelReservation(HttpServletRequest request,
                                         HttpServletResponse response,
                                         int userId) throws IOException {

        JsonObject jsonRequest = parseRequestBody(request);
        if (jsonRequest == null || !jsonRequest.has("reservationId")) {
            sendErrorResponse(response, 400, "Missing reservationId in request body");
            return;
        }

        int reservationId;
        try {
            reservationId = jsonRequest.get("reservationId").getAsInt();
        } catch (Exception e) {
            sendErrorResponse(response, 400, "Invalid reservationId format");
            return;
        }

        ReservationResult result = reservationService.cancelReservation(reservationId, userId);

        if (result.isSuccess()) {
            sendSuccessResponse(response, result.getMessage());
        } else {
            sendErrorResponse(response, 400, result.getMessage());
        }
    }

    private void handleGetMyReservations(HttpServletRequest request,
                                         HttpServletResponse response,
                                         int userId) throws IOException {

        boolean activeOnly = "true".equalsIgnoreCase(request.getParameter("active"));
        List<ReservationDto> reservations = activeOnly
                ? reservationService.getUserActiveReservations(userId)
                : reservationService.getUserReservations(userId);

        if (reservations == null) {
            reservations = new java.util.ArrayList<>();
        }

        sendJsonResponse(response, 200, reservations);
    }

    private void handleCheckReservationStatus(HttpServletRequest request,
                                              HttpServletResponse response,
                                              int userId) throws IOException {

        String isbn = request.getParameter("isbn");
        if (isbn == null || isbn.trim().isEmpty()) {
            sendErrorResponse(response, 400, "Missing ISBN parameter");
            return;
        }

        isbn = isbn.trim();
        System.out.println("🔍 Checking reservation status - userId: " + userId + ", isbn: " + isbn);

        boolean hasReservation = reservationService.hasActiveReservation(userId, isbn);
        int waitingCount = reservationService.getWaitingCount(isbn);

        JsonObject result = new JsonObject();
        result.addProperty("hasReservation", hasReservation);
        result.addProperty("waitingCount", waitingCount);

        if (hasReservation) {
            Integer queuePosition = reservationService.getQueuePosition(userId, isbn);
            if (queuePosition != null) {
                result.addProperty("queuePosition", queuePosition);
            }
            result.addProperty("status", "PENDING");
        }

        System.out.println("✅ Status checked - hasReservation: " + hasReservation + ", waiting: " + waitingCount);
        sendJsonResponse(response, 200, result);
    }

    /* ====================== UTILS ====================== */

    private JsonObject parseRequestBody(HttpServletRequest request) throws IOException {
        StringBuilder sb = new StringBuilder();
        try (BufferedReader reader = request.getReader()) {
            String line;
            while ((line = reader.readLine()) != null) {
                sb.append(line);
            }
        }
        
        String body = sb.toString().trim();
        if (body.isEmpty()) {
            return null;
        }
        
        try {
            return gson.fromJson(body, JsonObject.class);
        } catch (Exception e) {
            throw new IOException("Invalid JSON format: " + e.getMessage());
        }
    }

    private void sendSuccessResponse(HttpServletResponse response, String message) throws IOException {
        JsonObject json = new JsonObject();
        json.addProperty("success", true);
        json.addProperty("message", message);
        sendJsonResponse(response, 200, json);
    }

    private void sendErrorResponse(HttpServletResponse response, int statusCode, String message)
            throws IOException {
        JsonObject json = new JsonObject();
        json.addProperty("success", false);
        json.addProperty("message", message);
        sendJsonResponse(response, statusCode, json);
    }

    private void sendJsonResponse(HttpServletResponse response, int statusCode, Object data)
            throws IOException {
        response.setContentType("application/json; charset=UTF-8");
        response.setCharacterEncoding("UTF-8");
        response.setStatus(statusCode);
        
        response.setHeader("Access-Control-Allow-Origin", "*");
        response.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
        response.setHeader("Access-Control-Allow-Headers", "Authorization, Content-Type");
        
        PrintWriter out = response.getWriter();
        out.print(gson.toJson(data));
        out.flush();
    }
    
    @Override
    protected void doOptions(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setHeader("Access-Control-Allow-Origin", "*");
        response.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
        response.setHeader("Access-Control-Allow-Headers", "Authorization, Content-Type");
        response.setStatus(HttpServletResponse.SC_OK);
    }
}