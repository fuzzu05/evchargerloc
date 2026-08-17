package com.smartev.backend.models;

import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

@Data
@Document(collection = "chargers")
public class Charger {
    @Id
    private String id;
    private String stationId;
    private String name; // e.g. "Charger 1"
    private String type; // e.g., "CCS2", "CHAdeMO"
    private Double powerKw;
    private String status; // "AVAILABLE", "CHARGING", "RESERVED", "MAINTENANCE"
}
