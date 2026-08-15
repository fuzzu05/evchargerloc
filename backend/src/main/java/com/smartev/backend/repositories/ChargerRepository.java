package com.smartev.backend.repositories;

import com.smartev.backend.models.Charger;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.List;

public interface ChargerRepository extends MongoRepository<Charger, String> {
    List<Charger> findByStationId(String stationId);
}
