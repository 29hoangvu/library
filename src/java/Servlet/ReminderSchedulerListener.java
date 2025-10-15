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

        ZoneId zone = ZoneId.of("Asia/Ho_Chi_Minh");
        LocalTime runAt = LocalTime.of(8, 0); // 08:00 hằng ngày

        long initialDelay = computeInitialDelay(zone, runAt);
        long period = TimeUnit.DAYS.toSeconds(1);

        scheduler.scheduleAtFixedRate(() -> {
            try {
                // Gọi servlet job nội bộ
                // Cách đơn giản: hit URL bằng HTTP client local
                // Hoặc tách ReminderJob thành class tĩnh rồi gọi trực tiếp
                // Ở đây demo: gọi URL nội bộ
                java.net.URL url = new java.net.URL("http://localhost:8080/Library/cron/reminders");
                try (java.io.InputStream is = url.openStream()) { /* fire & read */ }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }, initialDelay, period, TimeUnit.SECONDS);
    }

    private long computeInitialDelay(ZoneId zone, LocalTime runAt) {
        ZonedDateTime now = ZonedDateTime.now(zone);
        ZonedDateTime next = now.withHour(runAt.getHour()).withMinute(runAt.getMinute()).withSecond(0).withNano(0);
        if (!next.isAfter(now)) next = next.plusDays(1);
        return Duration.between(now, next).getSeconds();
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        if (scheduler != null) scheduler.shutdownNow();
    }
}

