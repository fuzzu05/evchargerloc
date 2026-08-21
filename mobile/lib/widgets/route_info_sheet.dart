import 'package:flutter/material.dart';
import '../models/nav_step.dart';

/// Bottom sheet that lists all upcoming navigation steps.
class RouteInfoSheet extends StatelessWidget {
  final List<NavStep> steps;
  final int currentStepIndex;
  final String totalDuration;
  final String totalDistance;
  final VoidCallback onClose;

  const RouteInfoSheet({
    super.key,
    required this.steps,
    required this.currentStepIndex,
    required this.totalDuration,
    required this.totalDistance,
    required this.onClose,
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
      default:
        return Icons.straight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Route Info',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$totalDuration  •  $totalDistance',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.redAccent),
                  onPressed: onClose,
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12),

          // Step list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: steps.length,
              itemBuilder: (context, index) {
                final step = steps[index];
                final isCurrent = index == currentStepIndex;
                final isPast = index < currentStepIndex;

                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? Colors.greenAccent.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isCurrent
                        ? Border.all(
                            color: Colors.greenAccent.withValues(alpha: 0.4),
                          )
                        : null,
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? Colors.greenAccent.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _maneuverIcon(step.maneuver),
                        color: isCurrent
                            ? Colors.greenAccent
                            : isPast
                            ? Colors.white24
                            : Colors.white54,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      step.instruction,
                      style: TextStyle(
                        color: isCurrent
                            ? Colors.white
                            : isPast
                            ? Colors.white30
                            : Colors.white70,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: isCurrent
                        ? Text(
                            '${step.formattedDistance} ahead',
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : Text(
                            step.formattedDistance,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                    trailing: isPast
                        ? const Icon(
                            Icons.check_circle,
                            color: Colors.greenAccent,
                            size: 16,
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
