import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Scan Line Loader (Level 1C)
/// Used for upload / scan buttons. Shows a document with a moving scan line.
/// ─────────────────────────────────────────────────────────────────────────────
class ScanLineLoader extends StatelessWidget {
  final Color borderColor;
  final Color scanColor;

  const ScanLineLoader({
    super.key,
    this.borderColor = Colors.white,
    this.scanColor = const Color(0xFFA8F0C6),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Stack(
        children: [
          // Moving scan line
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                color: scanColor,
                boxShadow: [
                  BoxShadow(
                    color: scanColor.withValues(alpha: 0.8),
                    blurRadius: 4,
                  ),
                ],
              ),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .moveY(
                  begin: 0,
                  end: 15.5, // 20 - 1.5 (height) - 3 (borders)
                  duration: 600.ms,
                  curve: Curves.easeInOutSine,
                ),
          ),
        ],
      ),
    );
  }
}
