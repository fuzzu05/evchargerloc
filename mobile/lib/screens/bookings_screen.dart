import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock bookings matching the design
    final bookings = [
      {
        'station': 'Equinox Business Park',
        'power': '15 kWh',
        'type': 'CCS2',
        'status': 'Confirmed',
        'time': 'Today, 4:00 PM',
        'statusColor': const Color(0xFF00FF88),
        'statusBg': const Color(0xFF00FF88).withValues(alpha: 0.15),
        'statusTextColor': const Color(0xFF00FF88),
      },
      {
        'station': 'Tata Power Station',
        'power': '50 kWh',
        'type': 'CHAdeMO',
        'status': 'Completed',
        'time': 'Yesterday, 2:30 PM',
        'statusColor': Colors.white38,
        'statusBg': Colors.white.withValues(alpha: 0.05),
        'statusTextColor': Colors.white54,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF090A0C),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Header
              Text(
                'My bookings',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 32),

              // Bookings List
              Expanded(
                child: ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final b = bookings[index];
                    final isConfirmed = b['status'] == 'Confirmed';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14161C),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isConfirmed
                              ? const Color(0xFF00FF88).withValues(alpha: 0.2)
                              : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Station Name & Status Pill
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                b['station'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: b['statusBg'] as Color,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  b['status'] as String,
                                  style: GoogleFonts.inter(
                                    color: b['statusTextColor'] as Color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Power & Type (JetBrains Mono)
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isConfirmed
                                      ? const Color(0xFF00FF88)
                                      : const Color(0xFF7A9BFF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${b['power']}  •  ${b['type']}',
                                style: GoogleFonts.jetBrainsMono(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Time
                          Text(
                            b['time'] as String,
                            style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
