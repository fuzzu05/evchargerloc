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

    @GetMapping
    public List<ChargingStation> getAllStations() {
        return stationRepository.findAll();
    }

    @PostMapping
    public ChargingStation addStation(@RequestBody ChargingStation station) {
        return stationRepository.save(station);
    }
}
