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
    
    @PutMapping("/{id}")
    public ChargingStation updateStation(@PathVariable String id, @RequestBody ChargingStation stationDetails, org.springframework.security.core.Authentication authentication) {
        ChargingStation existingStation = stationRepository.findById(id).orElseThrow();
        
        // Ensure user owns station
        com.smartev.backend.security.CustomUserDetails userDetails = (com.smartev.backend.security.CustomUserDetails) authentication.getPrincipal();
        if (!existingStation.getOperatorId().equals(userDetails.getUser().getId())) {
            throw new RuntimeException("Unauthorized");
        }
        
        // Update fields
        existingStation.setName(stationDetails.getName());
        existingStation.setAddress(stationDetails.getAddress());
        existingStation.setPricePerKwh(stationDetails.getPricePerKwh());
        existingStation.setGridPower(stationDetails.getGridPower());
        
        existingStation.setHasCafe(stationDetails.getHasCafe());
        existingStation.setHasWifi(stationDetails.getHasWifi());
        existingStation.setHasRestroom(stationDetails.getHasRestroom());
        existingStation.setHasSecurity(stationDetails.getHasSecurity());
        existingStation.setHasStore(stationDetails.getHasStore());
        
        existingStation.setIs247(stationDetails.getIs247());
        existingStation.setOpenTime(stationDetails.getOpenTime());
        existingStation.setCloseTime(stationDetails.getCloseTime());
        
        existingStation.setDefaultSlot(stationDetails.getDefaultSlot());
        existingStation.setBufferGrace(stationDetails.getBufferGrace());
        existingStation.setAutoCancel(stationDetails.getAutoCancel());
        
        existingStation.setIdlePenalty(stationDetails.getIdlePenalty());
        existingStation.setPeakPricing(stationDetails.getPeakPricing());
        existingStation.setPayCash(stationDetails.getPayCash());
        existingStation.setPayWallet(stationDetails.getPayWallet());
        existingStation.setPayCorporate(stationDetails.getPayCorporate());
        
        existingStation.setEmergencyStop(stationDetails.getEmergencyStop());
        existingStation.setOutageMode(stationDetails.getOutageMode());
        existingStation.setManualOtp(stationDetails.getManualOtp());
        
        return stationRepository.save(existingStation);
    }
    
    @PostMapping("/sync")
    public List<ChargingStation> syncStations(
            @RequestParam double lat, 
            @RequestParam double lng, 
            @RequestParam(defaultValue = "10.0") double distance) {
        return openChargeMapService.syncStationsNearLocation(lat, lng, distance);
    }
}
