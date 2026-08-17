package com.smartev.backend.models;

import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

@Data
@Document(collection = "users")
public class User {
    @Id
    private String id;
    private String email;
    private String password;
    private String role; // "USER", "OPERATOR", or "ADMIN"
    private String status; // "PENDING" or "APPROVED"
    
    // Vehicle Profile
    private String vehicleModel;
    private String connectorType; // e.g., CCS2, Type2
    private Integer batteryCapacityKwh;
}
