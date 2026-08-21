import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mobile/models/station.dart';
import 'package:mobile/models/booking.dart';
import 'package:mobile/services/booking_service.dart';
import 'package:mobile/services/auth_service.dart';

class SlotBookingScreen extends StatefulWidget {
  final ChargingStation station;
  const SlotBookingScreen({super.key, required this.station});

  @override
  State<SlotBookingScreen> createState() => _SlotBookingScreenState();
}

class _SlotBookingScreenState extends State<SlotBookingScreen> {
  String _selectedSlot = '6:30';
  bool _isBooking = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Slot booking',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              'confirm',
              style: GoogleFonts.jetBrainsMono(color: Colors.white54),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress bar mock
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(height: 2, color: const Color(0xFF00FF88)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: Container(height: 2, color: Colors.white24),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.station.name,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${widget.station.pricePerKwh}/kWh • ${widget.station.gridPower}',
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 40),

                // Day selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Tomorrow',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF00FF88),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF00FF88),
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Time grid
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 2.2,
                  physics: const NeverScrollableScrollPhysics(),
                  children: ['6:00', '6:30', '7:00', '7:30', '8:00', '8:30']
                      .map((time) {
                        final isSelected = _selectedSlot == time;
                        // Mock disabled for 8:00
                        final isDisabled = time == '8:00';
                        return GestureDetector(
                          onTap: isDisabled
                              ? null
                              : () => setState(() => _selectedSlot = time),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF00FF88)
                                  : const Color(0xFF14161C),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : Colors.white12,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              time,
                              style: GoogleFonts.jetBrainsMono(
                                color: isSelected
                                    ? const Color(0xFF090A0C)
                                    : isDisabled
                                    ? Colors.white24
                                    : Colors.white,
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      })
                      .toList(),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Bottom summary
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Slot',
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$_selectedSlot - 7:00 PM',
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Estimated cost',
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '₹210',
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: const Color(0xFF00FF88),
                      foregroundColor: const Color(0xFF090A0C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isBooking ? null : _confirmBooking,
                    child: _isBooking
                        ? const CircularProgressIndicator(
                            color: Color(0xFF090A0C),
                          )
                        : Text(
                            'Confirm booking',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmBooking() async {
    setState(() => _isBooking = true);
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) throw Exception('Not logged in');

      final booking = Booking(
        id: '', // Will be assigned by backend
        userId: userId,
        stationId: widget.station.id,
        chargerId: 'charger_1',
        timeSlotId: _selectedSlot,
        bookingTime: DateTime.now(),
        status: 'CONFIRMED',
      );

      await BookingService.createBooking(booking);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking Confirmed!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Go back to Map
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to book: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }
}
