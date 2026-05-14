import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Growing Seedling Loader (Level 2A)
/// Used for score / report loading states inside cards.
/// ─────────────────────────────────────────────────────────────────────────────
class SeedlingLoader extends StatefulWidget {
  final String label;

  const SeedlingLoader({
    super.key,
    this.label = 'Building your profile...',
  });

  @override
  State<SeedlingLoader> createState() => _SeedlingLoaderState();
}

class _SeedlingLoaderState extends State<SeedlingLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _swayController;

  @override
  void initState() {
    super.initState();
    _swayController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // 2s each way
    );
    // Start swaying only after plant grows
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) _swayController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _swayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Ground bar
              Positioned(
                bottom: 20,
                child: Container(
                  width: 80,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4EDDA),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),

              // The plant (sways as a group after growing)
              Positioned(
                bottom: 24, // On top of ground bar
                child: AnimatedBuilder(
                  animation: _swayController,
                  builder: (context, child) {
                    final sway = (_swayController.value - 0.5) * 2; // -1 to 1
                    final angle = sway * 0.052; // roughly 3 degrees
                    return Transform(
                      transform: Matrix4.rotationZ(angle),
                      alignment: Alignment.bottomCenter,
                      child: child,
                    );
                  },
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    clipBehavior: Clip.none,
                    children: [
                      // Stem
                      Container(
                        width: 3,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A6B3C),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3CC068).withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ).animate()
                          .scaleY(
                            begin: 0,
                            end: 1,
                            duration: 800.ms,
                            curve: const Cubic(0.34, 1.56, 0.64, 1),
                            alignment: Alignment.bottomCenter,
                          ),

                      // Left leaf
                      Positioned(
                        bottom: 12,
                        left: -16,
                        child: Transform.rotate(
                          angle: -0.7, // roughly -40 degrees
                          alignment: Alignment.centerRight,
                          child: Container(
                            width: 18,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF3CC068),
                              borderRadius: BorderRadius.all(Radius.elliptical(18, 10)),
                            ),
                          ).animate(delay: 700.ms)
                              .scale(
                                begin: Offset.zero,
                                end: const Offset(1, 1),
                                duration: 400.ms,
                                curve: Curves.easeOut,
                                alignment: Alignment.centerRight,
                              ),
                        ),
                      ),

                      // Right leaf
                      Positioned(
                        bottom: 22,
                        right: -16,
                        child: Transform.rotate(
                          angle: 0.7, // roughly 40 degrees
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 18,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2D8653),
                              borderRadius: BorderRadius.all(Radius.elliptical(18, 10)),
                            ),
                          ).animate(delay: 900.ms)
                              .scale(
                                begin: Offset.zero,
                                end: const Offset(1, 1),
                                duration: 400.ms,
                                curve: Curves.easeOut,
                                alignment: Alignment.centerLeft,
                              ),
                        ),
                      ),

                      // Top tiny leaves
                      Positioned(
                        bottom: 46,
                        child: Row(
                          children: [
                            Transform.rotate(
                              angle: -0.5,
                              child: Container(
                                width: 10,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF3CC068),
                                  borderRadius: BorderRadius.all(Radius.elliptical(10, 6)),
                                ),
                              ),
                            ),
                            Transform.rotate(
                              angle: 0.5,
                              child: Container(
                                width: 10,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2D8653),
                                  borderRadius: BorderRadius.all(Radius.elliptical(10, 6)),
                                ),
                              ),
                            ),
                          ],
                        ).animate(delay: 1100.ms)
                            .scale(
                              begin: Offset.zero,
                              end: const Offset(1, 1),
                              duration: 300.ms,
                              alignment: Alignment.bottomCenter,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Label
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Color(0xFF4A6B57),
              ),
            ),
            const SizedBox(width: 4),
            _buildBlinkingDot(0),
            _buildBlinkingDot(300),
            _buildBlinkingDot(600),
          ],
        ),
      ],
    );
  }

  Widget _buildBlinkingDot(int delayMs) {
    return const Text(
      '.',
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        color: Color(0xFF4A6B57),
        fontWeight: FontWeight.bold,
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
        .fadeIn(duration: 400.ms, delay: delayMs.ms)
        .fadeOut(duration: 400.ms);
  }
}
