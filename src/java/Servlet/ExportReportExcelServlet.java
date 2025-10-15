package Servlet;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

import java.io.IOException;
import java.io.OutputStream;
import java.sql.*;
import java.util.Date;

@WebServlet(name="ExportReportExcelServlet", urlPatterns={"/ExportReportExcelServlet"})
public class ExportReportExcelServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String reportType = nvl(req.getParameter("reportType"), "borrowReport");
        String month      = nvl(req.getParameter("month"), "");
        String year       = nvl(req.getParameter("year"), "");

        try (Workbook wb = new XSSFWorkbook()) {

            // ==== Styles ====
            CellStyle header = wb.createCellStyle();
            Font hfont = wb.createFont(); hfont.setBold(true);
            header.setFont(hfont);
            header.setFillForegroundColor(IndexedColors.GREY_25_PERCENT.getIndex());
            header.setFillPattern(FillPatternType.SOLID_FOREGROUND);
            header.setBorderBottom(BorderStyle.THIN);

            DataFormat df = wb.createDataFormat();
            CellStyle dateStyle = wb.createCellStyle();
            dateStyle.setDataFormat(df.getFormat("yyyy-mm-dd hh:mm"));

            CellStyle moneyStyle = wb.createCellStyle();
            moneyStyle.setDataFormat(df.getFormat("#,##0"));

            // ====================
            // 1) Sheet Summary
            // ====================
            Sheet sum = wb.createSheet("Summary");
            int r = 0;
            Row h = sum.createRow(r++);
            String h1 = "borrowReport".equals(reportType) ? "Lượt mượn theo tháng" : "Tiền phạt theo tháng (VNĐ)";
            h.createCell(0).setCellValue(h1);
            sum.addMergedRegion(new org.apache.poi.ss.util.CellRangeAddress(0,0,0,3));

            Row head = sum.createRow(r++);
            head.createCell(0).setCellValue("Tháng/Năm");
            head.createCell(1).setCellValue("Giá trị");
            head.getCell(0).setCellStyle(header);
            head.getCell(1).setCellStyle(header);

            String sqlMonthly;
            if ("borrowReport".equals(reportType)) {
                sqlMonthly =
                    "SELECT YEAR(borrowed_date) y, MONTH(borrowed_date) m, COUNT(*) v " +
                    "FROM borrow JOIN bookitem ON borrow.book_item_id=bookitem.book_item_id " +
                    "JOIN book ON bookitem.book_isbn=book.isbn " +
                    "WHERE 1=1 " +
                    (isNum(month) ? " AND MONTH(borrowed_date)=? " : "") +
                    (isNum(year)  ? " AND YEAR(borrowed_date)=? "  : "") +
                    "GROUP BY YEAR(borrowed_date), MONTH(borrowed_date) ORDER BY y,m";
            } else {
                sqlMonthly =
                    "SELECT YEAR(borrowed_date) y, MONTH(borrowed_date) m, SUM(fine_amount) v " +
                    "FROM borrow WHERE fine_amount>0 " +
                    (isNum(month) ? " AND MONTH(borrowed_date)=? " : "") +
                    (isNum(year)  ? " AND YEAR(borrowed_date)=? "  : "") +
                    "GROUP BY YEAR(borrowed_date), MONTH(borrowed_date) ORDER BY y,m";
            }

            try (Connection c = DBConnection.getConnection();
                 PreparedStatement ps = c != null ? c.prepareStatement(sqlMonthly) : null) {
                if (ps != null) {
                    int idx=1;
                    if (isNum(month)) ps.setInt(idx++, Integer.parseInt(month));
                    if (isNum(year))  ps.setInt(idx++, Integer.parseInt(year));
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            int y = rs.getInt("y");
                            int m = rs.getInt("m");
                            Number v = (Number) rs.getObject("v");
                            Row row = sum.createRow(r++);
                            row.createCell(0).setCellValue(String.format("%02d/%d", m, y));
                            row.createCell(1).setCellValue(v == null ? 0 : v.doubleValue());
                        }
                    }
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
            autoSize(sum, 2);

            // ====================
            // 2) Sheet Detail
            // ====================
            Sheet detail = wb.createSheet("Detail");
            int d = 0;
            Row dh = detail.createRow(d++);
            String title = "borrowReport".equals(reportType) ? "Bảng mượn chi tiết (gom theo sách/tháng)" : "Bảng tiền phạt chi tiết (gom theo user/tháng)";
            dh.createCell(0).setCellValue(title);
            detail.addMergedRegion(new org.apache.poi.ss.util.CellRangeAddress(0,0,0,5));

            Row dhead = detail.createRow(d++);
            dhead.createCell(0).setCellValue("Tháng");
            dhead.createCell(1).setCellValue("Năm");
            dhead.createCell(2).setCellValue("Đối tượng");
            dhead.createCell(3).setCellValue("Giá trị");
            for (int i=0;i<=3;i++) dhead.getCell(i).setCellStyle(header);

            String sqlDetail;
            if ("borrowReport".equals(reportType)) {
                sqlDetail =
                    "SELECT MONTH(borrowed_date) m, YEAR(borrowed_date) y, book.title t, COUNT(*) v " +
                    "FROM borrow JOIN bookitem ON borrow.book_item_id=bookitem.book_item_id " +
                    "JOIN book ON bookitem.book_isbn=book.isbn " +
                    "WHERE 1=1 " +
                    (isNum(month) ? " AND MONTH(borrowed_date)=? " : "") +
                    (isNum(year)  ? " AND YEAR(borrowed_date)=? "  : "") +
                    "GROUP BY YEAR(borrowed_date), MONTH(borrowed_date), book.title " +
                    "ORDER BY y DESC, m ASC";
            } else {
                sqlDetail =
                    "SELECT MONTH(borrowed_date) m, YEAR(borrowed_date) y, u.username t, SUM(fine_amount) v " +
                    "FROM borrow b JOIN users u ON b.user_id=u.id " +
                    "WHERE fine_amount>0 " +
                    (isNum(month) ? " AND MONTH(b.borrowed_date)=? " : "") +
                    (isNum(year)  ? " AND YEAR(b.borrowed_date)=? "  : "") +
                    "GROUP BY YEAR(borrowed_date), MONTH(borrowed_date), u.username " +
                    "ORDER BY y DESC, m ASC";
            }

            try (Connection c = DBConnection.getConnection();
                 PreparedStatement ps = c != null ? c.prepareStatement(sqlDetail) : null) {
                if (ps != null) {
                    int idx=1;
                    if (isNum(month)) ps.setInt(idx++, Integer.parseInt(month));
                    if (isNum(year))  ps.setInt(idx++, Integer.parseInt(year));
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            int m = rs.getInt("m");
                            int y = rs.getInt("y");
                            String t = rs.getString("t");
                            Number v = (Number) rs.getObject("v");

                            Row row = detail.createRow(d++);
                            row.createCell(0).setCellValue(m);
                            row.createCell(1).setCellValue(y);
                            row.createCell(2).setCellValue(t);
                            Cell cv = row.createCell(3);
                            cv.setCellValue(v == null ? 0 : v.doubleValue());
                            if ("fineReport".equals(reportType)) cv.setCellStyle(moneyStyle);
                        }
                    }
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
            autoSize(detail, 4);

            // ===============================
            // 3) Sheet AllBorrows (Full rows)
            // ===============================
            Sheet all = wb.createSheet("AllBorrows");
            int a = 0;
            Row ah = all.createRow(a++);
            ah.createCell(0).setCellValue("Tất cả lượt mượn (áp dụng bộ lọc nếu có)");
            all.addMergedRegion(new org.apache.poi.ss.util.CellRangeAddress(0,0,0,11));

            Row ahead = all.createRow(a++);
            String[] cols = {
                "Borrow ID", "Username", "Họ tên", "ISBN", "Tựa sách", "BookItemID",
                "Vị trí kệ", "Ngày mượn", "Hạn trả", "Ngày trả", "Trạng thái", "Tiền phạt"
            };
            for (int i = 0; i < cols.length; i++) {
                Cell cHead = ahead.createCell(i);
                cHead.setCellValue(cols[i]);
                cHead.setCellStyle(header);
            }

            // Điều chỉnh cột họ tên theo DB thực tế (nếu không có, trả về null)
            String sqlAll =
                "SELECT b.borrow_id, u.username, u.full_name, bk.isbn, bk.title, bi.book_item_id, r.rack_number, " +
                "       b.borrowed_date, b.due_date, b.returned_date, b.status, b.fine_amount " +
                "FROM borrow b " +
                "JOIN users u     ON b.user_id = u.id " +
                "JOIN bookitem bi ON b.book_item_id = bi.book_item_id " +
                "JOIN book bk     ON bi.book_isbn   = bk.isbn " +
                "LEFT JOIN rack r ON bi.rack_id     = r.rack_id " +
                "WHERE 1=1 " +
                (isNum(month) ? " AND MONTH(b.borrowed_date)=? " : "") +
                (isNum(year)  ? " AND YEAR(b.borrowed_date)=? "  : "") +
                "ORDER BY b.borrowed_date DESC, b.borrow_id DESC";

            try (Connection c = DBConnection.getConnection();
                 PreparedStatement ps = c != null ? c.prepareStatement(sqlAll) : null) {
                if (ps != null) {
                    int idx=1;
                    if (isNum(month)) ps.setInt(idx++, Integer.parseInt(month));
                    if (isNum(year))  ps.setInt(idx++, Integer.parseInt(year));
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            Row row = all.createRow(a++);
                            int col = 0;

                            // Borrow ID
                            row.createCell(col++).setCellValue(rs.getLong("borrow_id"));

                            // Username
                            row.createCell(col++).setCellValue(nvl(rs.getString("username"), ""));

                            // Họ tên (có thể null nếu DB không có cột)
                            row.createCell(col++).setCellValue(nvl(rs.getString("full_name"), ""));

                            // ISBN, Title
                            row.createCell(col++).setCellValue(nvl(rs.getString("isbn"), ""));
                            row.createCell(col++).setCellValue(nvl(rs.getString("title"), ""));

                            // BookItemID
                            row.createCell(col++).setCellValue(nvl(rs.getString("book_item_id"), ""));

                            // Vị trí kệ
                            row.createCell(col++).setCellValue(nvl(rs.getString("rack_number"), ""));

                            // borrowed_date
                            Timestamp tsBorrowed = rs.getTimestamp("borrowed_date");
                            Cell cBorrowed = row.createCell(col++);
                            if (tsBorrowed != null) {
                                cBorrowed.setCellValue(new Date(tsBorrowed.getTime()));
                                cBorrowed.setCellStyle(dateStyle);
                            } else cBorrowed.setCellValue("");

                            // due_date
                            Timestamp tsDue = rs.getTimestamp("due_date");
                            Cell cDue = row.createCell(col++);
                            if (tsDue != null) {
                                cDue.setCellValue(new Date(tsDue.getTime()));
                                cDue.setCellStyle(dateStyle);
                            } else cDue.setCellValue("");

                            // returned_date
                            Timestamp tsReturned = rs.getTimestamp("returned_date");
                            Cell cReturned = row.createCell(col++);
                            if (tsReturned != null) {
                                cReturned.setCellValue(new Date(tsReturned.getTime()));
                                cReturned.setCellStyle(dateStyle);
                            } else cReturned.setCellValue("");

                            // status
                            row.createCell(col++).setCellValue(nvl(rs.getString("status"), ""));

                            // fine_amount
                            Cell cMoney = row.createCell(col++);
                            cMoney.setCellValue(rs.getDouble("fine_amount"));
                            cMoney.setCellStyle(moneyStyle);
                        }
                    }
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
            // Auto-size các cột (0..11)
            for (int i = 0; i <= 11; i++) {
                try { all.autoSizeColumn(i); } catch (Exception ignore) {}
            }

            // ====================
            // Xuất file
            // ====================
            String fname = "borrowReport".equals(reportType) ? "BaoCaoMuon.xlsx" : "BaoCaoPhat.xlsx";
            resp.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
            resp.setHeader("Content-Disposition", "attachment; filename=\"" + fname + "\"");
            try (OutputStream os = resp.getOutputStream()) {
                wb.write(os);
                os.flush();
            }
        }
    }

    private static boolean isNum(String s) {
        if (s == null || s.isEmpty()) return false;
        try { Integer.parseInt(s); return true; } catch (Exception e) { return false; }
    }
    private static String nvl(String s, String d) { return (s == null ? d : s); }
    private static void autoSize(Sheet sh, int cols) {
    if (sh == null) return;
    for (int i = 0; i < cols; i++) {
        try { sh.autoSizeColumn(i); } catch (Exception ignore) {}
    }
}
}
