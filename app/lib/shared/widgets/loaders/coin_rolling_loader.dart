import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Coin Rolling Loader (Level 2C)
/// Used for loan eligibility / DSCR calculations. Shows a rolling rupee coin.
/// ─────────────────────────────────────────────────────────────────────────────
class CoinRollingLoader extends StatelessWidget {
  final String label;

  const CoinRollingLoader({
    super.key,
    this.label = 'Calculating your eligibility...',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 140,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Road
              Positioned(
                bottom: 20,
                child: SizedBox(
                  width: 120,
                  height: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (index) {
                      return Container(
                        width: 16,
                        height: 2,
                        color: const Color(0xFFE2EDE7),
                      );
                    }),
                  ),
                ),
              ),

              // Coin + Shadow grouping
              Positioned(
                bottom: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Coin
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A6B3C), Color(0xFF3CC068)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1A6B3C).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '₹',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                        // Roll across
                        .slideX(
                          begin: -2.0, // relative to its 32px width = -64px
                          end: 2.0, // +64px
                          duration: 1600.ms,
                          curve: Curves.easeInOut,
                        )
                        // Rotate
                        .rotate(
                          begin: -1.0, // -360 deg
                          end: 1.0, // +360 deg
                          duration: 1600.ms,
                          curve: Curves.linear, // constant rotation
                        )
                        // Bounce at ends
                        .then()
                        .moveY(
                          begin: 0,
                          end: -6,
                          duration: 150.ms,
                          curve: Curves.easeOut,
                        )
                        .then()
                        .moveY(
                          begin: -6,
                          end: 0,
                          duration: 150.ms,
                          curve: Curves.easeIn,
                        ),

                    // Shadow (moves with coin but stays on ground)
                    Container(
                      width: 24,
                      height: 4,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                        .slideX(
                          begin: -2.6,
                          end: 2.6,
                          duration: 1600.ms,
                          curve: Curves.easeInOut,
                        )
                        .then()
                        .scaleXY(
                          begin: 1.0,
                          end: 0.6,
                          duration: 150.ms,
                        )
                        .then()
                        .scaleXY(
                          begin: 0.6,
                          end: 1.0,
                          duration: 150.ms,
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: Color(0xFF4A6B57),
          ),
        ),
      ],
    );
  }
}
