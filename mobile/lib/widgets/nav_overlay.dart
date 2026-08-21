import 'package:flutter/material.dart';
import '../models/nav_step.dart';

/// Floating navigation overlay card shown at the top of the map
/// when turn-by-turn navigation is active.
class NavOverlay extends StatelessWidget {
  final NavStep currentStep;
  final int stepIndex;
  final int totalSteps;
  final String eta;
  final String totalDistance;
  final bool isMuted;
  final VoidCallback onMuteToggle;
  final VoidCallback onCancelRoute;
  final VoidCallback onShowRouteInfo;

  const NavOverlay({
    super.key,
    required this.currentStep,
    required this.stepIndex,
    required this.totalSteps,
    required this.eta,
    required this.totalDistance,
    required this.isMuted,
    required this.onMuteToggle,
    required this.onCancelRoute,
    required this.onShowRouteInfo,
  });

  IconData _maneuverIcon(String maneuver) {
    switch (maneuver) {
      case 'turn-left':
        return Icons.turn_left;
      case 'turn-right':
        return Icons.turn_right;
      case 'turn-slight-left':
        return Icons.turn_slight_left;
      case 'turn-slight-right':
        return Icons.turn_slight_right;
      case 'turn-sharp-left':
        return Icons.turn_sharp_left;
      case 'turn-sharp-right':
        return Icons.turn_sharp_right;
      case 'roundabout-left':
        return Icons.roundabout_left;
      case 'roundabout-right':
        return Icons.roundabout_right;
      case 'uturn-left':
        return Icons.u_turn_left;
      case 'uturn-right':
        return Icons.u_turn_right;
      case 'merge':
        return Icons.merge;
      case 'ramp-left':
      case 'fork-left':
        return Icons.turn_slight_left;
      case 'ramp-right':
      case 'fork-right':
        return Icons.turn_slight_right;
      default:
        return Icons.straight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 52, 16, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.95),
              Colors.black.withValues(alpha: 0.85),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          children: [
            // ── Top Row: ETA + Distance + Controls ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eta,
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$totalDistance  •  Step ${stepIndex + 1}/$totalSteps',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _IconBtn(
                      icon: isMuted ? Icons.volume_off : Icons.volume_up,
                      color: isMuted ? Colors.redAccent : Colors.white,
                      onTap: onMuteToggle,
                    ),
                    const SizedBox(width: 8),
                    _IconBtn(
                      icon: Icons.list_alt,
                      color: Colors.white,
                      onTap: onShowRouteInfo,
                    ),
                    const SizedBox(width: 8),
                    _IconBtn(
                      icon: Icons.close,
                      color: Colors.redAccent,
                      onTap: onCancelRoute,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Main Instruction Card ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.greenAccent.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.greenAccent.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _maneuverIcon(currentStep.maneuver),
                      color: Colors.greenAccent,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentStep.instruction,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentStep.formattedDistance,
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
