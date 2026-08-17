package com.smartev.backend.controllers;

import com.smartev.backend.models.Charger;
import com.smartev.backend.repositories.ChargerRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/chargers")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class ChargerController {

    private final ChargerRepository chargerRepository;
    private final SimpMessagingTemplate messagingTemplate;

    @GetMapping("/station/{stationId}")
    public List<Charger> getChargersByStation(@PathVariable String stationId) {
        return chargerRepository.findByStationId(stationId);
    }

    @PostMapping
    public Charger addCharger(@RequestBody Charger charger) {
        return chargerRepository.save(charger);
    }

    @PutMapping("/{id}/status")
    public Charger updateChargerStatus(@PathVariable String id, @RequestParam String status) {
        Charger charger = chargerRepository.findById(id).orElseThrow();
        charger.setStatus(status);
        Charger updatedCharger = chargerRepository.save(charger);
        
        // Broadcast the updated charger to all connected WebSocket clients
        messagingTemplate.convertAndSend("/topic/chargers", updatedCharger);
        
        return updatedCharger;
    }
}
