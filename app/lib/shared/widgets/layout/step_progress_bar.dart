import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StepProgressBar extends StatelessWidget {
  final int currentStep; // 1 to 9
  final ValueChanged<int>? onStepTapped;
  final Map<int, bool> stepCompletionMap; // Map step to isComplete bool

  const StepProgressBar({
    super.key,
    required this.currentStep,
    this.onStepTapped,
    this.stepCompletionMap = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final dotSize = 16.0;
          final lineSpacing = (totalWidth - (9 * dotSize)) / 8;

          return SizedBox(
            height: dotSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Background lines
                Positioned.fill(
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(8, (index) {
                        final stepIndex = index + 1;
                        final isLineActive = currentStep > stepIndex || (stepCompletionMap[stepIndex] == true);
                        
                        return Container(
                          height: 2,
                          width: lineSpacing,
                          color: isLineActive ? AppColors.accent : AppColors.border,
                        );
                      }),
                    ),
                  ),
                ),
                // Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(9, (index) {
                    final stepIndex = index + 1;
                    final isActive = currentStep == stepIndex;
                    final isCompleted = stepCompletionMap[stepIndex] == true || currentStep > stepIndex;
                    
                    return GestureDetector(
                      onTap: (isCompleted || isActive) && onStepTapped != null 
                        ? () => onStepTapped!(stepIndex) 
                        : null,
                      child: _StepDot(
                        isActive: isActive,
                        isCompleted: isCompleted,
                        size: dotSize,
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool isActive;
  final bool isCompleted;
  final double size;

  const _StepDot({
    required this.isActive,
    required this.isCompleted,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    if (isActive) {
      color = AppColors.highlight;
    } else if (isCompleted) {
      color = AppColors.accent;
    } else {
      color = AppColors.border;
    }

    Widget dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: isActive 
          ? Border.all(color: AppColors.surface, width: 2) 
          : null,
      ),
    );

    if (isActive) {
      dot = dot.animate(onPlay: (controller) => controller.repeat())
               .shimmer(duration: 1500.ms, color: Colors.white.withValues(alpha: 0.5))
               .scaleXY(begin: 1.0, end: 1.1, duration: 800.ms, curve: Curves.easeInOut)
               .then()
               .scaleXY(begin: 1.1, end: 1.0, duration: 800.ms, curve: Curves.easeInOut);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
      ),
      child: dot,
    );
  }
}
