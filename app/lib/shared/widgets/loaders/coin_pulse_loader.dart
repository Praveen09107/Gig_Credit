import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Coin Pulse Loader (Level 1A)
/// Used inside CTA buttons. Replaces generic circular progress indicator.
/// Looks like 3 coins bouncing sequentially.
/// ─────────────────────────────────────────────────────────────────────────────
class CoinPulseLoader extends StatelessWidget {
  final Color color;
  final double size;

  const CoinPulseLoader({
    super.key,
    this.color = Colors.white,
    this.size = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size + 8, // padding for bounce
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCoin(0),
          const SizedBox(width: 5),
          _buildCoin(120),
          const SizedBox(width: 5),
          _buildCoin(240),
        ],
      ),
    );
  }

  Widget _buildCoin(int delayMs) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .moveY(
          begin: 0,
          end: -8,
          duration: 400.ms,
          curve: Curves.easeInOutSine,
          delay: delayMs.ms,
        )
        .then()
        .moveY(
          begin: -8,
          end: 0,
          duration: 400.ms,
          curve: Curves.easeInOutSine,
        )
        .then(delay: (400 - delayMs).ms); // padding to sync loops
  }
}
