package com.smartev.backend.repositories;

import com.smartev.backend.models.ChargingStation;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface ChargingStationRepository extends MongoRepository<ChargingStation, String> {
}
