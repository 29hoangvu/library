package Servlet;

import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.util.*;
import com.google.gson.*; // add gson-*.jar vào WEB-INF/lib

public class RecoClient {

    private static final String BASE = "http://localhost:8000";

    public static List<String> getIsbnForUser(int userId) throws IOException {
        URL url = new URL(BASE + "/recommend/" + userId);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("GET");
        conn.setConnectTimeout(3000);
        conn.setReadTimeout(4000);

        try (InputStream is = conn.getInputStream(); InputStreamReader isr = new InputStreamReader(is, StandardCharsets.UTF_8); BufferedReader br = new BufferedReader(isr)) {

            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = br.readLine()) != null) {
                sb.append(line);
            }

            JsonObject obj = JsonParser.parseString(sb.toString()).getAsJsonObject();
            List<String> out = new ArrayList<>();

            if (obj.has("isbns")) {
                JsonArray arr = obj.getAsJsonArray("isbns");
                for (int i = 0; i < arr.size(); i++) {
                    out.add(arr.get(i).getAsString());
                }
                return out;
            }
            if (obj.has("items")) {
                JsonArray items = obj.getAsJsonArray("items");
                for (JsonElement el : items) {
                    JsonObject it = el.getAsJsonObject();
                    if (it.has("isbn")) {
                        out.add(it.get("isbn").getAsString());
                    }
                }
            }
            return out;
        } finally {
            conn.disconnect();
        }
    }

}
