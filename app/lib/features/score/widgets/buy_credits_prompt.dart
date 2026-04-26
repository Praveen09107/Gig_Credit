import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/buttons/secondary_button.dart';
import '../../../../app/app_router.dart';

class BuyCreditsPrompt extends StatelessWidget {
  const BuyCreditsPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.stars_rounded, size: 64, color: AppColors.warning),
            const SizedBox(height: 16),
            Text(
              'Out of Free Reports',
              style: AppTypography.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "You've used all your free reports. Buy credits to generate a new credit score and report.",
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Buy Credits',
              onPressed: () {
                context.pop(); // Close sheet
                context.push(AppRoutes.buyCredits); // Assumes we have a route or we can navigate via Profile
              },
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
