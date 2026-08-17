package com.smartev.backend.models;

import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import java.time.LocalDateTime;

@Data
@Document(collection = "time_slots")
public class TimeSlot {
    @Id
    private String id;
    private String chargerId;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private String status; // "AVAILABLE", "RESERVED"
    private String bookingId; // Null if available
}
