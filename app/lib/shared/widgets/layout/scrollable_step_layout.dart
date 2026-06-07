import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'step_progress_bar.dart';
import '../feedback/step_popups.dart';
import '../../../app/app_router.dart';

/// Step metadata for hero band display
class _StepMeta {
  final String name;
  final String description;
  final String emoji;
  const _StepMeta(this.name, this.description, this.emoji);
}

/// GigCredit Step Layout — wraps all 9 scoring step screens
/// Green hero band → step progress bar → scrollable content → sticky bottom CTA
class ScrollableStepLayout extends StatelessWidget {
  final int currentStep;
  final Widget content;
  final Widget bottomBar;
  final Map<int, bool>? stepCompletionMap;
  final ValueChanged<int>? onStepTapped;
  final VoidCallback? onAbandon;

  const ScrollableStepLayout({
    super.key,
    required this.currentStep,
    required this.content,
    required this.bottomBar,
    this.stepCompletionMap,
    this.onStepTapped,
    this.onAbandon,
  });

  static const _steps = {
    1: _StepMeta('Personal Info', 'Tell us who you are', '👤'),
    2: _StepMeta('KYC & Identity', 'Verify your identity', '🪪'),
    3: _StepMeta('Bank Details', 'Your primary bank account', '🏦'),
    4: _StepMeta('Utility Bills', 'Electricity, water & more', '💡'),
    5: _StepMeta('Work & Platform', 'Your gig work history', '📱'),
    6: _StepMeta('Govt. Schemes', 'Schemes you are enrolled in', '🏛️'),
    7: _StepMeta('Insurance', 'Your insurance coverage', '🛡️'),
    8: _StepMeta('Tax & ITR', 'Your tax filing history', '📋'),
    9: _StepMeta('Loans & EMIs', 'Existing loan obligations', '💳'),
  };

  @override
  Widget build(BuildContext context) {
    final meta = _steps[currentStep] ?? const _StepMeta('Step', 'Fill in the details', '📝');
    final completedCount = (stepCompletionMap ?? {}).values.where((v) => v).length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (currentStep == 1) {
          final abandon = await AbandonSessionPopup.show(context);
          if (abandon && context.mounted) {
            onAbandon?.call();
            context.go(AppRoutes.home);
          }
        } else {
          final goBack = await StepBackPopup.show(context, stepNumber: currentStep);
          if (goBack && context.mounted) {
            // Use pop() to go back — preserves the previous step's widget state
            // (entered fields, verified status, uploaded docs all remain intact)
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(AppRoutes.scoreStep(currentStep - 1));
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgScreen,
        body: Column(
          children: [
            // ── Hero Band (replaces plain AppBar) ──────────────────
            _StepHeroBand(
              currentStep: currentStep,
              totalSteps: 9,
              meta: meta,
              completedCount: completedCount,
              stepCompletionMap: stepCompletionMap ?? {},
              onStepTapped: onStepTapped,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            // ── Scrollable Content ─────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: content,
              ),
            ),
            // ── Sticky Bottom Bar ──────────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                border: const Border(top: BorderSide(color: AppColors.borderCard)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -4)),
                ],
              ),
              child: bottomBar,
            ),
          ],
        ),
      ),
    );
  }
}

/// The green hero band shown at the top of every step screen
class _StepHeroBand extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final _StepMeta meta;
  final int completedCount;
  final Map<int, bool> stepCompletionMap;
  final ValueChanged<int>? onStepTapped;
  final VoidCallback onBack;

  const _StepHeroBand({
    required this.currentStep,
    required this.totalSteps,
    required this.meta,
    required this.completedCount,
    required this.stepCompletionMap,
    required this.onStepTapped,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: back + title + counter ───────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: onBack,
                  ),
                  Expanded(
                    child: Text(
                      'Step $currentStep · ${meta.name}',
                      style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
                    ),
                    child: Text(
                      '$currentStep of $totalSteps',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            // ── Step description + emoji ───────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
                    ),
                    alignment: Alignment.center,
                    child: Text(meta.emoji, style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(meta.description,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text('$completedCount of $totalSteps steps completed',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.70), fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── Step Progress Bar ──────────────────────────────────
            Container(
              color: Colors.white.withValues(alpha: 0.08),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: StepProgressBar(
                currentStep: currentStep,
                stepCompletionMap: stepCompletionMap,
                onStepTapped: onStepTapped,
                lightMode: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
