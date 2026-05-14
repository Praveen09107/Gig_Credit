import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'step_progress_bar.dart';

/// GigCredit Step Layout — wraps all 9 scoring step screens
/// Green header → step progress bar → scrollable content → sticky bottom CTA
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
      backgroundColor: AppColors.bgScreen,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.greenPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Step $currentStep of 9',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
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
          // Green accent gradient line below step bar
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.greenPrimary.withValues(alpha: 0.0),
                  AppColors.greenPrimary,
                  AppColors.greenBright,
                  AppColors.greenPrimary,
                  AppColors.greenPrimary.withValues(alpha: 0.0),
                ],
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
          // Sticky bottom bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16).copyWith(
              bottom: 16 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              border: const Border(
                top: BorderSide(color: AppColors.borderCard),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
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
