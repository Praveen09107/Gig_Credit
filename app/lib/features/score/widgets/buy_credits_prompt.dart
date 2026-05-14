import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/buttons/secondary_button.dart';
import '../../../../app/app_router.dart';

/// GigCredit Buy Credits Prompt — bottom sheet for out-of-credits scenario
class BuyCreditsPrompt extends StatelessWidget {
  const BuyCreditsPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 14),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderCard,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.25),
                  width: 2,
                ),
              ),
              child: const Icon(Icons.stars_rounded,
                  size: 36, color: AppColors.warning),
            ),
            const SizedBox(height: 20),
            Text(
              'Out of Free Reports',
              style: AppTypography.headlineLarge.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "You've used all your free reports.\nBuy credits to generate a new score.",
              style: AppTypography.bodyMedium.copyWith(height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'BUY CREDITS',
              onPressed: () {
                context.pop();
                context.push(AppRoutes.buyCredits);
              },
              suffixIcon: const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Maybe Later',
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}
