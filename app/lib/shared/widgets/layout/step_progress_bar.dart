import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// GigCredit Step Progress Bar — 9 dots with connecting lines
/// Green active/completed dots, grey future dots, shimmer on current step
class StepProgressBar extends StatelessWidget {
  final int currentStep; // 1 to 9
  final ValueChanged<int>? onStepTapped;
  final Map<int, bool> stepCompletionMap;
  /// When true, renders on a dark/green background (white dots/lines)
  final bool lightMode;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    this.onStepTapped,
    this.stepCompletionMap = const {},
    this.lightMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          const dotSize = 18.0;
          final lineSpacing = (totalWidth - (9 * dotSize)) / 8;

          return SizedBox(
            height: dotSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Background lines — positioned between dots, not overlapping them
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 9.0), // half of dotSize=18
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(8, (index) {
                        final stepIndex = index + 1;
                        final isLineActive = currentStep > stepIndex ||
                            (stepCompletionMap[stepIndex] == true);

                        return Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: isLineActive
                                  ? (lightMode ? Colors.white : AppColors.greenBright)
                                  : (lightMode ? Colors.white.withValues(alpha: 0.30) : AppColors.borderCard),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
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
                    final isCompleted =
                        stepCompletionMap[stepIndex] == true ||
                            currentStep > stepIndex;

                    return GestureDetector(
                      onTap:
                          (isCompleted || isActive) && onStepTapped != null
                              ? () => onStepTapped!(stepIndex)
                              : null,
                      child: _StepDot(
                        stepNumber: stepIndex,
                        isActive: isActive,
                        isCompleted: isCompleted,
                        size: dotSize,
                        lightMode: lightMode,
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
  final int stepNumber;
  final bool isActive;
  final bool isCompleted;
  final double size;
  final bool lightMode;

  const _StepDot({
    required this.stepNumber,
    required this.isActive,
    required this.isCompleted,
    required this.size,
    this.lightMode = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    Color borderColor;

    if (isActive) {
      bgColor = lightMode ? Colors.white : AppColors.greenPrimary;
      textColor = lightMode ? AppColors.greenPrimary : Colors.white;
      borderColor = lightMode ? Colors.white : AppColors.greenMint;
    } else if (isCompleted) {
      bgColor = lightMode ? Colors.white.withValues(alpha: 0.85) : AppColors.greenBright;
      textColor = lightMode ? AppColors.greenPrimary : Colors.white;
      borderColor = lightMode ? Colors.white : AppColors.greenBright;
    } else {
      bgColor = lightMode ? Colors.white.withValues(alpha: 0.15) : AppColors.bgScreen;
      textColor = lightMode ? Colors.white.withValues(alpha: 0.60) : AppColors.textMuted;
      borderColor = lightMode ? Colors.white.withValues(alpha: 0.30) : AppColors.borderCard;
    }

    Widget dot = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: isActive ? 2 : 1.5),
        boxShadow: isActive
            ? [BoxShadow(
                color: lightMode
                    ? Colors.white.withValues(alpha: 0.40)
                    : AppColors.greenBright.withValues(alpha: 0.40),
                blurRadius: 8,
              )]
            : null,
      ),
      child: Center(
        child: isCompleted && !isActive
            ? Icon(Icons.check_rounded, size: 11, color: textColor)
            : Text(
                '$stepNumber',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: textColor),
              ),
      ),
    );

    if (isActive) {
      dot = dot
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1.0, end: 1.12, duration: 800.ms, curve: Curves.easeInOut);
    }

    return dot;
  }
}
