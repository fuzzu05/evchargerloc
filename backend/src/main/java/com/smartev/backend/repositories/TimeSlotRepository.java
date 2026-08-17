package com.smartev.backend.repositories;

import com.smartev.backend.models.TimeSlot;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.List;

public interface TimeSlotRepository extends MongoRepository<TimeSlot, String> {
    List<TimeSlot> findByChargerId(String chargerId);
}
