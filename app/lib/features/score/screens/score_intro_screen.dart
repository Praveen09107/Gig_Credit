import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../shared/widgets/buttons/secondary_button.dart';
import '../../../app/app_router.dart';
import '../../../state/score_provider.dart';
import '../../../state/credit_provider.dart';
import '../widgets/score_benefit_card.dart';
import '../widgets/buy_credits_prompt.dart';

class ScoreIntroScreen extends ConsumerWidget {
  const ScoreIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreState = ref.watch(scoreProvider);
    final hasScore = scoreState.reportData != null;

    if (hasScore) {
      // If they click on "Score" tab and already have a score, they shouldn't see intro,
      // they should immediately see the report! For Phase 4 we just say "Locked/Active"
      // but let's actually just show a simple "You have a score" message for now.
      return Scaffold(
        appBar: AppBar(title: const Text('Credit Score')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified, size: 80, color: AppColors.gradeA),
              const SizedBox(height: 24),
              Text('Score Active', style: AppTypography.displaySmall),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'View Report',
                onPressed: () => context.push(AppRoutes.scoreReport),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unlock Credit'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Icon(
                Icons.speed_rounded,
                size: 100,
                color: AppColors.accentLight.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Generate Your\nGigCredit Score',
              style: AppTypography.displayMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'A 9-step private verification process to unlock access to micro-loans tailored for the gig economy.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            const ScoreBenefitCard(
              icon: Icons.shield_outlined,
              title: '100% Private',
              subtitle: 'Data never leaves your device. No cloud storage.',
            ),
            const SizedBox(height: 12),
            const ScoreBenefitCard(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Unlock Loan Offers',
              subtitle: 'Qualify for micro-loans from top lending partners.',
            ),
            const SizedBox(height: 12),
            const ScoreBenefitCard(
              icon: Icons.flash_on_rounded,
              title: 'Instant Generation',
              subtitle: 'Takes under 5 minutes to verify and calculate.',
            ),
            
            const SizedBox(height: 48),
            PrimaryButton(
              label: 'Check Credit Score',
              onPressed: () {
                final creditState = ref.read(creditProvider);
                if (creditState.totalAvailable > 0) {
                  context.push(AppRoutes.scoreStep(1));
                } else {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (context) => const BuyCreditsPrompt(),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            SecondaryButton(
              label: 'How it works',
              onPressed: () {
                context.push(AppRoutes.scoreHowItWorks);
              },
            ),
          ],
        ),
      ),
    );
  }
}
