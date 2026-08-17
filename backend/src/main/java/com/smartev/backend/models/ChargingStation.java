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
}
