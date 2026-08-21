package com.smartev.backend.controllers;

import com.smartev.backend.models.Booking;
import com.smartev.backend.repositories.BookingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/analytics")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class AnalyticsController {

    private final BookingRepository bookingRepository;

    @GetMapping("/station/{stationId}")
    public Map<String, Object> getStationAnalytics(@PathVariable String stationId) {
        List<Booking> bookings = bookingRepository.findByStationId(stationId);

        double totalEnergy = 0.0;
        double totalRevenue = 0.0;
        int completedSessions = 0;
        int totalSessions = bookings.size();

        for (Booking b : bookings) {
            if ("COMPLETED".equalsIgnoreCase(b.getStatus()) || "IN_SESSION".equalsIgnoreCase(b.getStatus()) || "CONFIRMED".equalsIgnoreCase(b.getStatus())) {
                if (b.getKwh() != null) totalEnergy += b.getKwh();
                if (b.getPrice() != null) totalRevenue += b.getPrice();
                if ("COMPLETED".equalsIgnoreCase(b.getStatus())) completedSessions++;
            }
        }

        double successRate = totalSessions > 0 ? (double) completedSessions / totalSessions * 100 : 100.0;
        
        // Generate hourly data based on bookings for today
        // For simplicity, we just distribute the energy across hours if there's any, or provide a realistic curve if empty.
        // Since we want live data, we will map the actual bookings if they have bookingTime, but timeSlotId is what we have right now ("10:00 AM", etc.)
        
        int[] hourlyEnergy = new int[24];
        int[] peakDemand = new int[24];
        
        for (Booking b : bookings) {
            String time = b.getTimeSlotId();
            if (time != null && time.length() >= 7) {
                try {
                    int hour = Integer.parseInt(time.substring(0, 2));
                    if (time.contains("PM") && hour != 12) hour += 12;
                    if (time.contains("AM") && hour == 12) hour = 0;
                    
                    if (hour >= 0 && hour < 24 && b.getKwh() != null) {
                        hourlyEnergy[hour] += b.getKwh().intValue();
                        peakDemand[hour] += (b.getKwh().intValue() * 2); // Roughly
                    }
                } catch (Exception e) {
                    // Ignore parsing errors for live data
                }
            }
        }

        Map<String, Object> response = new HashMap<>();
        response.put("totalEnergy", totalEnergy);
        response.put("totalRevenue", totalRevenue);
        response.put("completedSessions", completedSessions);
        response.put("successRate", Math.round(successRate));
        response.put("hourlyEnergy", hourlyEnergy);
        response.put("peakDemand", peakDemand);

        return response;
    }
}
