import '../../../shared/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DeliveryBikeLoader extends StatelessWidget {
  final String label;

  const DeliveryBikeLoader({
    super.key,
    this.label = 'Processing...',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 160,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Road lines moving left (giving illusion of forward speed)
              Positioned(
                bottom: 20,
                child: SizedBox(
                  width: 140,
                  height: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (index) {
                      return Container(
                        width: 16,
                        height: 2,
                        color: AppColors.greenMuted,
                      ).animate(onPlay: (controller) => controller.repeat())
                       .slideX(begin: 1.0, end: -1.0, duration: 400.ms, curve: Curves.linear);
                    }),
                  ),
                ),
              ),

              // The bike
              Positioned(
                bottom: 22,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.greenMuted,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.two_wheeler_rounded,
                    color: AppColors.greenPrimary,
                    size: 28,
                  ),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                 // Bouncing effect
                 .moveY(begin: 0, end: -4, duration: 250.ms, curve: Curves.easeOut)
                 .then()
                 .moveY(begin: -4, end: 0, duration: 250.ms, curve: Curves.easeIn),
              ),
              
              // Wind streaks
              Positioned(
                bottom: 40,
                right: 30,
                child: Container(
                  width: 24,
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.greenMint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ).animate(onPlay: (controller) => controller.repeat())
                 .slideX(begin: 2.0, end: -4.0, duration: 600.ms)
                 .fade(begin: 1.0, end: 0.0),
              ),
              Positioned(
                bottom: 55,
                right: 20,
                child: Container(
                  width: 16,
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.greenMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ).animate(onPlay: (controller) => controller.repeat())
                 .slideX(begin: 2.0, end: -5.0, duration: 500.ms, delay: 200.ms)
                 .fade(begin: 1.0, end: 0.0),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
