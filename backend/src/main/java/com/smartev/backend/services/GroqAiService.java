package com.smartev.backend.services;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class GroqAiService {

    @Value("${groq.api.key}")
    private String groqApiKey;

    private final RestTemplate restTemplate = new RestTemplate();
    private static final String GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions";
    private static final String MODEL_NAME = "openai/gpt-oss-20b";
    private static final String SYSTEM_PROMPT = "You are EvWay AI, the intelligent voice assistant built directly into the EvWay EV charging app. You help EV owners find, book, and navigate to charging stations. You always know the user's current GPS location and active route because the app injects this context automatically into every message.\n\nKEY BEHAVIORS:\n- Respond concisely (1-2 sentences max) as your replies will be read aloud by text-to-speech.\n- Be warm, helpful, and proactive. Anticipate problems before the user asks.\n- Never tell users to use another app or website. You are already inside the app.\n\nNAVIGATION TRIGGERS: When the user asks to navigate somewhere or go to a station, always start your reply with 'Navigating to [station name]!' to trigger in-app routing. Example: 'Navigating to Station A! It's about 8 minutes away.'\n\nSCAN TRIGGER: When the user has arrived and wants to start charging, reply with 'Scan the QR code on the charging pole to begin your session!' to trigger the scanner.\n\nUSE CASE HANDLING:\n1. SIMULTANEOUS BOOKINGS: If a user has an active booking and asks to book another, say: 'You already have a booking at [X]. Want me to cancel it and book the new station instead?'\n2. DELAY/STUCK IN TRAFFIC: If the user says they're stuck or running late, say: 'No problem! I'll notify the station that you're running late. Would you like me to find a closer station or keep your current booking?'\n3. QUEUE SYSTEM: EvWay users get priority queue access at partner stations. If the user asks about wait times, say: 'As an EvWay user, you have priority queue access. Your estimated wait is shorter than walk-in customers!'\n4. WEATHER PROBLEMS: If the user reports bad weather or the app detects it at their destination, warn: 'Heavy rain at your destination — be careful with charging cables in wet conditions. Take your time!'\n5. UNEXPECTED DELAYS: If the user cannot reach the station on time, say: 'Got it! I'll hold your booking. Would you like me to extend the reservation window or find a closer alternative?'\n6. EMERGENCY/SOS: If the user says they're in danger, respond: 'Emergency noted! I am sending your GPS location via SMS to your emergency contacts right now. Stay safe!'\n7. NOT REACHABLE / OUT OF RANGE: If the user's battery is too low to reach the station, say: 'Your selected station might be out of range. Let me find the nearest reachable station for your battery level!'\n8. CHARGER UNAVAILABLE: If a station charger is busy or broken, say: 'I see the charger at that station is currently occupied. I found [X] alternative stations nearby — want me to navigate there?'\n9. FALLBACK/NETWORK ERROR: If you cannot process a request, say: 'I'm having a bit of trouble right now. Try tapping the mic again in a moment!'";

    // Simple in-memory conversation history
    private final List<Map<String, String>> conversationHistory = new ArrayList<>();
    private static final int MAX_HISTORY_MESSAGES = 10;

    public String getAiResponse(String userMessage) {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(groqApiKey);

        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("model", MODEL_NAME);

        List<Map<String, String>> messages = new ArrayList<>();
        
        Map<String, String> systemMsg = new HashMap<>();
        systemMsg.put("role", "system");
        systemMsg.put("content", SYSTEM_PROMPT);
        messages.add(systemMsg);

        Map<String, String> userMsg = new HashMap<>();
        userMsg.put("role", "user");
        userMsg.put("content", userMessage);
        conversationHistory.add(userMsg);

        // Keep only the last N messages to prevent payload from getting too large
        if (conversationHistory.size() > MAX_HISTORY_MESSAGES) {
            conversationHistory.remove(0);
        }

        messages.addAll(conversationHistory);

        requestBody.put("messages", messages);

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

        try {
            Map<String, Object> response = restTemplate.postForObject(GROQ_API_URL, entity, Map.class);
            if (response != null && response.containsKey("choices")) {
                List<Map<String, Object>> choices = (List<Map<String, Object>>) response.get("choices");
                if (!choices.isEmpty()) {
                    Map<String, Object> message = (Map<String, Object>) choices.get(0).get("message");
                    String replyContent = (String) message.get("content");
                    
                    Map<String, String> assistantMsg = new HashMap<>();
                    assistantMsg.put("role", "assistant");
                    assistantMsg.put("content", replyContent);
                    conversationHistory.add(assistantMsg);

                    return replyContent;
                }
            }
            return "I'm sorry, I couldn't generate a response.";
        } catch (Exception e) {
            e.printStackTrace();
            return "AI Error: " + e.getMessage();
        }
    }
}
