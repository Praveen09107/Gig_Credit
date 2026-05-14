import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Running Dots Loader (Level 1B)
/// Used for navigation/page move buttons. Trail of dots that moves forward.
/// ─────────────────────────────────────────────────────────────────────────────
class RunningDotsLoader extends StatelessWidget {
  const RunningDotsLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFFA8F0C6),
      const Color(0xFF3CC068),
      const Color(0xFF2D8653),
      const Color(0xFF1A6B3C),
    ];

    return SizedBox(
      height: 6,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(4, (index) {
          return Padding(
            padding: EdgeInsets.only(right: index < 3 ? 4.0 : 0),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colors[index],
                shape: BoxShape.circle,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .fadeIn(
                  duration: 180.ms,
                  delay: (index * 100).ms,
                )
                .slideX(
                  begin: -1.0,
                  end: 0,
                  duration: 180.ms,
                  delay: (index * 100).ms,
                )
                // Wait for all to appear
                .then(delay: ((4 - index) * 100 + 300).ms)
                // Fade all out together
                .fadeOut(duration: 200.ms),
          );
        }),
      ),
    );
  }
}
