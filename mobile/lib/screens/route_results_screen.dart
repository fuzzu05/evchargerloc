import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RouteResultsScreen extends StatelessWidget {
  const RouteResultsScreen({super.key});

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
          'Route results',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                'recommended',
                style: GoogleFonts.jetBrainsMono(color: Colors.white54),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chargers on your route',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'To Andheri • 20% battery • CCS2 compatible',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 32),

            // Best Match Card
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF14161C),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF00FF88).withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Stack(
                children: [
                  // Best match tag
                  Positioned(
                    top: -1,
                    left: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00FF88),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        'BEST MATCH',
                        style: GoogleFonts.jetBrainsMono(
                          color: const Color(0xFF090A0C),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Station A — JVLR',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '₹18/kWh',
                              style: GoogleFonts.jetBrainsMono(
                                color: const Color(0xFF00FF88),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'CCS2 • Fast charger',
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMetric('1.8 km', 'distance'),
                            _buildMetric('2 free', 'chargers'),
                            _buildMetric('6 min', 'wait'),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Recommended: closest compatible fast charger with the shortest wait on your route.',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF7A9BFF),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Standard Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF14161C),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mahakali Station',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹14/kWh',
                        style: GoogleFonts.jetBrainsMono(
                          color: const Color(0xFF00FF88),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Type 2 • Standard',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetric('2.6 km', 'distance'),
                      _buildMetric('1 free', 'chargers'),
                      _buildMetric('15 min', 'wait'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}
