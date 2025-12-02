package Servlet;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebListener;

import java.time.*;
import java.util.concurrent.*;

@WebListener
public class ReminderSchedulerListener implements ServletContextListener {

    private ScheduledExecutorService scheduler;

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        scheduler = Executors.newSingleThreadScheduledExecutor();

        // Chạy ngay lúc start (delay 0), sau đó mỗi 30s
        scheduler.scheduleWithFixedDelay(() -> {
            try {
                // GỌI SERVLET ReminderJobServlet QUA HTTP
                java.net.URL url = new java.net.URL("http://localhost:8080/Library/cron/reminders");
                try (java.io.InputStream is = url.openStream()) {
                    // đọc cho đủ, hoặc bỏ trống cũng được
                }
                System.out.println("[ReminderScheduler] executed at " + java.time.LocalTime.now());
            } catch (Exception e) {
                e.printStackTrace();
            }
        }, 0, 30, TimeUnit.SECONDS);   // 0 = chạy ngay, 30 = delay sau khi job trước kết thúc
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        if (scheduler != null) scheduler.shutdownNow();
    }
}
