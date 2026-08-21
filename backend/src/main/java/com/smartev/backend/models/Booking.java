package com.smartev.backend.models;

import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import java.time.LocalDateTime;

@Data
@Document(collection = "bookings")
public class Booking {
    @Id
    private String id;
    private String userId;
    private String stationId;
    private String chargerId;
    private String timeSlotId;
    private LocalDateTime bookingTime;
    private String status; // "CONFIRMED", "CANCELLED", "COMPLETED", "BLOCKED", "IN_SESSION"
    
    // Additional fields for operator dashboard
    private String userName; // For walk-ins
    private String vehicle;
    private Double kwh;
    private Double price;
}
