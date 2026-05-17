import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../../../shared/widgets/cards/app_card.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../app/app_router.dart';
import '../../../../state/score_provider.dart';

class HeroScoreCard extends ConsumerWidget {
  const HeroScoreCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreState = ref.watch(scoreProvider);
    final hasScore = scoreState.reportData != null;

    return AppCard(
      hasGradientBorder: hasScore,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasScore ? Icons.verified : Icons.speed_rounded,
                color: AppColors.accentLight,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasScore ? 'Score Generated' : 'No Score Yet',
                  style: AppTypography.titleMedium,
                ),
              ),
              if (hasScore)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gradeA.withValues(alpha: 0.2), // Simple grade mapped later
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Grade ${scoreState.reportData!.grade}',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.gradeA),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hasScore
                ? 'Your credit profile is active. Check out your personalized loan offers.'
                : 'Complete your 9-step verification to generate your privacy-first credit score.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: hasScore ? 'View Score Details' : 'Start Verification',
            onPressed: () {
              if (hasScore) {
                context.push(AppRoutes.scoreReport);
              } else {
                showGeneralDialog(
                  context: context,
                  barrierDismissible: true,
                  barrierLabel: 'Dismiss',
                  transitionDuration: const Duration(milliseconds: 300),
                  pageBuilder: (context, animation, secondaryAnimation) => const SizedBox(),
                  transitionBuilder: (context, animation, secondaryAnimation, child) {
                    return ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack)),
                      child: FadeTransition(
                        opacity: animation,
                        child: AlertDialog(
                          backgroundColor: Colors.transparent,
                          contentPadding: EdgeInsets.zero,
                          elevation: 0,
                          content: Container(
                            width: double.maxFinite,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3), width: 2),
                              boxShadow: [
                                BoxShadow(color: AppColors.accent.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: -5),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(colors: [AppColors.accent, AppColors.accentLight]),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.rocket_launch, color: Colors.white, size: 36),
                                ),
                                const SizedBox(height: 20),
                                const Text('Ready to Start?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                                const SizedBox(height: 12),
                                const Text(
                                  'Complete your verification profile securely. All data is processed locally on your device.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                                ),
                                const SizedBox(height: 32),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          context.push('/app/guidance');
                                        },
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.help_outline, color: AppColors.accent, size: 18),
                                            SizedBox(width: 8),
                                            Text('Guidance', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          context.go(AppRoutes.score);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          backgroundColor: AppColors.accent,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          elevation: 8,
                                          shadowColor: AppColors.accent.withValues(alpha: 0.5),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text('Continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            SizedBox(width: 6),
                                            Icon(Icons.arrow_forward, size: 18),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
