package com.smartev.backend.services;

import com.smartev.backend.models.Charger;
import com.smartev.backend.models.ChargingStation;
import com.smartev.backend.repositories.ChargerRepository;
import com.smartev.backend.repositories.ChargingStationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class OpenChargeMapService {

    private final ChargingStationRepository stationRepository;
    private final ChargerRepository chargerRepository;
    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${ocm.api.key}")
    private String ocmApiKey;

    public List<ChargingStation> syncStationsNearLocation(double lat, double lng, double distanceKm) {
        String url = String.format("https://api.openchargemap.io/v3/poi/?key=%s&latitude=%s&longitude=%s&distance=%s&distanceunit=KM&maxresults=10",
                ocmApiKey, lat, lng, distanceKm);

        List<Map<String, Object>> response = restTemplate.getForObject(url, List.class);
        List<ChargingStation> savedStations = new ArrayList<>();

        if (response == null) return savedStations;

        for (Map<String, Object> poi : response) {
            Map<String, Object> addressInfo = (Map<String, Object>) poi.get("AddressInfo");
            if (addressInfo == null) continue;

            String stationName = (String) addressInfo.get("Title");
            String address = (String) addressInfo.get("AddressLine1");
            Double poiLat = (Double) addressInfo.get("Latitude");
            Double poiLng = (Double) addressInfo.get("Longitude");

            // Check if station already exists by name
            List<ChargingStation> existing = stationRepository.findAll();
            boolean exists = existing.stream().anyMatch(s -> s.getName().equals(stationName));
            
            if (!exists) {
                ChargingStation station = new ChargingStation();
                station.setName(stationName);
                station.setAddress(address != null ? address : "Unknown Address");
                station.setLocation(new GeoJsonPoint(poiLng, poiLat));
                station.setOperatorId("OCM_SYNCED");
                station.setPricePerKwh(15.0); // Dummy price
                
                ChargingStation savedStation = stationRepository.save(station);
                savedStations.add(savedStation);

                // Add chargers for this station
                List<Map<String, Object>> connections = (List<Map<String, Object>>) poi.get("Connections");
                if (connections != null) {
                    int chargerCount = 1;
                    for (Map<String, Object> conn : connections) {
                        Charger charger = new Charger();
                        charger.setStationId(savedStation.getId());
                        charger.setName("Charger " + chargerCount++);
                        
                        Map<String, Object> connType = (Map<String, Object>) conn.get("ConnectionType");
                        charger.setType(connType != null ? (String) connType.get("Title") : "Unknown Type");
                        
                        Object powerObj = conn.get("PowerKW");
                        Double power = 0.0;
                        if (powerObj instanceof Integer) {
                            power = ((Integer) powerObj).doubleValue();
                        } else if (powerObj instanceof Double) {
                            power = (Double) powerObj;
                        }
                        charger.setPowerKw(power);
                        charger.setStatus("AVAILABLE"); // Default status

                        chargerRepository.save(charger);
                    }
                }
            }
        }
        return savedStations;
    }
}
