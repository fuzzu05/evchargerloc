package com.smartev.backend.controllers;

import com.smartev.backend.models.Booking;
import com.smartev.backend.repositories.BookingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/bookings")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class BookingController {
    
    private final BookingRepository bookingRepository;

    @GetMapping("/user/{userId}")
    public List<Booking> getUserBookings(@PathVariable String userId) {
        return bookingRepository.findByUserId(userId);
    }

    @PostMapping
    public Booking createBooking(@RequestBody Booking booking) {
        if (booking.getBookingTime() == null) {
            booking.setBookingTime(LocalDateTime.now());
        }
        if (booking.getStatus() == null) {
            booking.setStatus("CONFIRMED");
        }
        return bookingRepository.save(booking);
    }
    
    @GetMapping("/station/{stationId}")
    public List<Booking> getStationBookings(@PathVariable String stationId) {
        return bookingRepository.findByStationId(stationId);
    }

    @DeleteMapping("/{id}")
    public void deleteBooking(@PathVariable String id) {
        bookingRepository.deleteById(id);
    }
}
