import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'step_progress_bar.dart';

class ScrollableStepLayout extends StatelessWidget {
  final int currentStep;
  final Widget content;
  final Widget bottomBar;
  final Map<int, bool>? stepCompletionMap;
  final ValueChanged<int>? onStepTapped;

  const ScrollableStepLayout({
    super.key,
    required this.currentStep,
    required this.content,
    required this.bottomBar,
    this.stepCompletionMap,
    this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Scoring'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: StepProgressBar(
            currentStep: currentStep,
            stepCompletionMap: stepCompletionMap ?? {},
            onStepTapped: onStepTapped,
          ),
        ),
      ),
      body: Column(
        children: [
          // Subtle gradient divider below step bar
          Container(
            height: 2,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accent, AppColors.highlight, AppColors.accent],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: content,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16).copyWith(
              bottom: 16 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: bottomBar,
          ),
        ],
      ),
    );
  }
}
