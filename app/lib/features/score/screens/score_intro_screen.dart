import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../shared/widgets/buttons/secondary_button.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../app/app_router.dart';
import '../../../state/score_provider.dart';
import '../../../state/credit_provider.dart';
import '../widgets/buy_credits_prompt.dart';

/// GigCredit Score Intro Screen
/// Hero + 3 benefit cards + CTA to start scoring
class ScoreIntroScreen extends ConsumerWidget {
  const ScoreIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreState = ref.watch(scoreProvider);
    final hasScore = scoreState.reportData != null;

    if (hasScore) {
      return _ActiveScoreView(
        onViewReport: () => context.push(AppRoutes.scoreReport),
        onNewReport: () {
          ref.read(scoreProvider.notifier).reset();
          context.push(AppRoutes.scoreStep(1));
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgScreen,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.bgCard,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.greenPrimary),
              onPressed: () => context.go(AppRoutes.home),
            ),
            title: Text(
              'Credit Score',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Hero ───────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
                  decoration: const BoxDecoration(gradient: AppColors.heroGradient),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.speed_rounded,
                            size: 48, color: Colors.white),
                      ).animate()
                          .scale(duration: 500.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: 16),
                      Text(
                        'Generate Your\nGigCredit Score',
                        style: AppTypography.heroHeading.copyWith(fontSize: 28),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 120.ms),
                      const SizedBox(height: 10),
                      Text(
                        'A 9-step private verification to unlock micro-loans tailored for the gig economy.',
                        style: AppTypography.heroBody,
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 200.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Benefits ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('WHY GIGCREDIT?',
                          style: AppTypography.sectionLabel),
                      const SizedBox(height: 14),
                      const _BenefitCard(
                        icon: Icons.shield_outlined,
                        iconColor: AppColors.greenPrimary,
                        title: '100% Private',
                        subtitle:
                            'Data never leaves your device. No cloud storage.',
                        delay: 280,
                      ),
                      const _BenefitCard(
                        icon: Icons.account_balance_wallet_outlined,
                        iconColor: AppColors.pillar2,
                        title: 'Unlock Loan Offers',
                        subtitle:
                            'Qualify for micro-loans from top lending partners.',
                        delay: 360,
                      ),
                      const _BenefitCard(
                        icon: Icons.flash_on_rounded,
                        iconColor: AppColors.warning,
                        title: 'Instant Generation',
                        subtitle:
                            'Takes under 5 minutes to verify and calculate.',
                        delay: 440,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // ── CTAs ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      PrimaryButton(
                        label: 'CHECK CREDIT SCORE',
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          final creditState = ref.read(creditProvider);
                          if (creditState.totalAvailable > 0) {
                            context.push(AppRoutes.scoreStep(1));
                          } else {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (context) =>
                                  const BuyCreditsPrompt(),
                            );
                          }
                        },
                        suffixIcon: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18),
                      ).animate().fadeIn(delay: 520.ms).slideY(begin: 0.05),
                      const SizedBox(height: 14),
                      SecondaryButton(
                        label: 'How it works',
                        icon: const Icon(Icons.play_circle_outline_rounded,
                            size: 18, color: AppColors.textSecondary),
                        onPressed: () {
                          context.push(AppRoutes.scoreHowItWorks);
                        },
                      ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.04),
                    ],
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final int delay;

  const _BenefitCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTypography.titleSmall
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: AppTypography.bodySmall.copyWith(height: 1.4)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    ).animate()
        .fadeIn(delay: Duration(milliseconds: delay))
        .slideY(begin: 0.06, duration: 400.ms, curve: Curves.easeOutCubic);
  }
}

class _ActiveScoreView extends StatelessWidget {
  final VoidCallback onViewReport;
  final VoidCallback onNewReport;
  const _ActiveScoreView({required this.onViewReport, required this.onNewReport});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgScreen,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.greenPrimary),
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: Text('Credit Score',
            style: AppTypography.titleMedium
                .copyWith(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: AppColors.ctaGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.greenBright.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.verified_rounded,
                    size: 44, color: Colors.white),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 24),
              Text('Score Active',
                  style: AppTypography.displaySmall
                      .copyWith(fontWeight: FontWeight.w900))
                  .animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 10),
              Text(
                'Your credit profile has been generated.\nView your detailed report below.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(height: 1.5),
              ).animate().fadeIn(delay: 250.ms),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'VIEW REPORT',
                  onPressed: onViewReport,
                  suffixIcon: const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 18),
                ),
              ).animate().fadeIn(delay: 380.ms).slideY(begin: 0.06),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: SecondaryButton(
                  label: 'GENERATE NEW REPORT',
                  onPressed: onNewReport,
                ),
              ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.06),
            ],
          ),
        ),
      ),
    );
  }
}
