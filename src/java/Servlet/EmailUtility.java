package Servlet;

import java.io.UnsupportedEncodingException;
import java.util.Properties;
import jakarta.mail.*;
import jakarta.mail.internet.*;

public final class EmailUtility {

    static void sendEmail(String email, String subject, String content) {
        throw new UnsupportedOperationException("Not supported yet."); // Generated from nbfs://nbhost/SystemFileSystem/Templates/Classes/Code/GeneratedMethodBody
    }

    private EmailUtility() {} // utility class - không cho new

    // === HẰNG SỐ (IN HOA) ===
    private static final String SENDER_EMAIL     = "librarynhv@gmail.com";
    private static final String SENDER_PASSWORD  = "xcqy bwsh xqqn eoab"; // App Password
    private static final String SENDER_PERSONAL  = "Thư Viện Số";
    private static final String SMTP_HOST        = "smtp.gmail.com";
    private static final String SMTP_PORT        = "587";

    private static Session getSession() {
        Properties props = new Properties();
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.starttls.enable", "true");
        props.put("mail.smtp.host", SMTP_HOST);
        props.put("mail.smtp.port", SMTP_PORT);

        return Session.getInstance(props, new Authenticator() {
            @Override
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(SENDER_EMAIL, SENDER_PASSWORD);
            }
        });
    }

    /** Gửi email TEXT thuần */
    public static void sendTextEmail(String to, String subject, String text) {
        try {
            Message msg = new MimeMessage(getSession());
            msg.setFrom(new InternetAddress(SENDER_EMAIL, SENDER_PERSONAL, "UTF-8"));
            msg.setRecipients(Message.RecipientType.TO, InternetAddress.parse(to));
            msg.setSubject(subject);
            msg.setText(text);
            Transport.send(msg);
        } catch (MessagingException | UnsupportedEncodingException e) {
            e.printStackTrace();
        }
    }

    /** Gửi email HTML */
    public static void sendHtmlEmail(String to, String subject, String html) {
        try {
            Message msg = new MimeMessage(getSession());
            msg.setFrom(new InternetAddress(SENDER_EMAIL, SENDER_PERSONAL, "UTF-8"));
            msg.setRecipients(Message.RecipientType.TO, InternetAddress.parse(to));
            msg.setSubject(subject);
            msg.setContent(html, "text/html; charset=UTF-8");
            Transport.send(msg);
        } catch (MessagingException | UnsupportedEncodingException e) {
            e.printStackTrace();
        }
    }

    /** Gửi email HTML + replyTo (tuỳ chọn) */
    public static void sendHtmlEmail(String to, String subject, String html, String replyTo) {
        try {
            Message msg = new MimeMessage(getSession());
            msg.setFrom(new InternetAddress(SENDER_EMAIL, SENDER_PERSONAL, "UTF-8"));
            msg.setRecipients(Message.RecipientType.TO, InternetAddress.parse(to));
            if (replyTo != null && !replyTo.isBlank()) {
                msg.setReplyTo(InternetAddress.parse(replyTo));
            }
            msg.setSubject(subject);
            msg.setContent(html, "text/html; charset=UTF-8");
            Transport.send(msg);
        } catch (MessagingException | UnsupportedEncodingException e) {
            e.printStackTrace();
        }
    }
}
