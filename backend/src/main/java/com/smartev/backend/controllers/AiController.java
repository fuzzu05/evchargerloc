package com.smartev.backend.controllers;

import com.smartev.backend.dto.ChatRequest;
import com.smartev.backend.dto.ChatResponse;
import com.smartev.backend.services.GroqAiService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/chat")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class AiController {

    private final GroqAiService groqAiService;

    @PostMapping
    public ResponseEntity<ChatResponse> chat(@RequestBody ChatRequest request) {
        String aiResponse = groqAiService.getAiResponse(request.getMessage());
        return ResponseEntity.ok(new ChatResponse(aiResponse));
    }
}
