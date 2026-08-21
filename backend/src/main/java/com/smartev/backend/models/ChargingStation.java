package com.smartev.backend.models;

import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;

@Data
@Document(collection = "stations")
public class ChargingStation {
    @Id
    private String id;
    private String operatorId;
    private String name;
    private String address;
    private GeoJsonPoint location; // For geospatial queries
    private Double pricePerKwh; // Display purposes only
    
    // Settings & Configuration
    private String gridPower = "200 kW (3-Phase HT Connection)";
    
    // Amenities
    private Boolean hasCafe = true;
    private Boolean hasWifi = true;
    private Boolean hasRestroom = true;
    private Boolean hasSecurity = true;
    private Boolean hasStore = false;
    
    // Operating Hours
    private Boolean is247 = true;
    private String openTime = "06:00";
    private String closeTime = "23:00";
    
    // Auto-Slot
    private String defaultSlot = "30 mins [Default]";
    private String bufferGrace = "5 mins";
    private String autoCancel = "After 10 mins";
    
    // Tariff & Payments
    private Double idlePenalty = 5.0;
    private Boolean peakPricing = false;
    private Boolean payCash = true;
    private Boolean payWallet = true;
    private Boolean payCorporate = true;
    
    // Emergency Protocols
    private Boolean emergencyStop = false;
    private Boolean outageMode = false;
    private Boolean manualOtp = false;
}
