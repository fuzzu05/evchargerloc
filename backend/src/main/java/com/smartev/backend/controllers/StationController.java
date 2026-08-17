package com.smartev.backend.controllers;

import com.smartev.backend.models.ChargingStation;
import com.smartev.backend.repositories.ChargingStationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/stations")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class StationController {
    
    private final ChargingStationRepository stationRepository;
    private final com.smartev.backend.services.OpenChargeMapService openChargeMapService;

    @GetMapping
    public List<ChargingStation> getAllStations() {
        return stationRepository.findAll();
    }

    @GetMapping("/my-stations")
    public List<ChargingStation> getMyStations(org.springframework.security.core.Authentication authentication) {
        com.smartev.backend.security.CustomUserDetails userDetails = (com.smartev.backend.security.CustomUserDetails) authentication.getPrincipal();
        return stationRepository.findByOperatorId(userDetails.getUser().getId());
    }

    @PostMapping
    public ChargingStation addStation(@RequestBody ChargingStation station, org.springframework.security.core.Authentication authentication) {
        if (authentication != null && authentication.getPrincipal() instanceof com.smartev.backend.security.CustomUserDetails) {
            com.smartev.backend.security.CustomUserDetails userDetails = (com.smartev.backend.security.CustomUserDetails) authentication.getPrincipal();
            station.setOperatorId(userDetails.getUser().getId());
        }
        return stationRepository.save(station);
    }
    
    @PostMapping("/sync")
    public List<ChargingStation> syncStations(
            @RequestParam double lat, 
            @RequestParam double lng, 
            @RequestParam(defaultValue = "10.0") double distance) {
        return openChargeMapService.syncStationsNearLocation(lat, lng, distance);
    }
}
