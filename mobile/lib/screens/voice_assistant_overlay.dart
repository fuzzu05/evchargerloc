import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VoiceAssistantOverlay extends StatefulWidget {
  final bool isListening;
  final String userSpokenText;
  final String aiResponseText;
  final VoidCallback onToggleListening;

  const VoiceAssistantOverlay({
    super.key,
    required this.isListening,
    required this.userSpokenText,
    required this.aiResponseText,
    required this.onToggleListening,
  });

  @override
  State<VoiceAssistantOverlay> createState() => _VoiceAssistantOverlayState();
}

class _VoiceAssistantOverlayState extends State<VoiceAssistantOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isListening) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant VoiceAssistantOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isListening && oldWidget.isListening) {
      _pulseController.stop();
      _pulseController.animateTo(1.0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF090A0C).withValues(alpha: 0.95),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Voice assistant',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.isListening ? 'listening' : 'ready',
                    style: GoogleFonts.jetBrainsMono(
                      color: widget.isListening
                          ? const Color(0xFF7A9BFF)
                          : Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 1),

            // Status Pill
            if (widget.isListening)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF7A9BFF).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Listening in English',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF7A9BFF),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // Audio Wave Visualization Placeholder
            if (widget.isListening)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  7,
                  (index) => AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final heights = [
                        10.0,
                        20.0,
                        35.0,
                        50.0,
                        35.0,
                        20.0,
                        10.0,
                      ];
                      final height = heights[index] * _pulseAnimation.value;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 6,
                        height: height,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7A9BFF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    },
                  ),
                ),
              ),

            const SizedBox(height: 48),

            // Chat Bubbles
            Expanded(
              flex: 3,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  if (widget.userSpokenText.isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16, left: 40),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14161C),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '"${widget.userSpokenText}"',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  if (widget.aiResponseText.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(right: 40),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2D3E),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VOLT AI',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF7A9BFF),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.aiResponseText,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Mic Button
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return GestureDetector(
                    onTap: widget.onToggleListening,
                    child: Container(
                      width:
                          80 *
                          (widget.isListening ? _pulseAnimation.value : 1.0),
                      height:
                          80 *
                          (widget.isListening ? _pulseAnimation.value : 1.0),
                      decoration: BoxDecoration(
                        color: widget.isListening
                            ? const Color(0xFF7A9BFF)
                            : const Color(0xFF14161C),
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (widget.isListening)
                            BoxShadow(
                              color: const Color(
                                0xFF7A9BFF,
                              ).withValues(alpha: 0.4),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                        ],
                      ),
                      child: Icon(
                        Icons.mic,
                        color: widget.isListening
                            ? const Color(0xFF090A0C)
                            : Colors.white,
                        size: 32,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
