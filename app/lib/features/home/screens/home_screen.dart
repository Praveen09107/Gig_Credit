import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../state/user_provider.dart';
import '../../../app/app_router.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/hero_score_card.dart';
import '../widgets/privacy_highlight_section.dart';
import '../widgets/hero_image_slider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GigCredit', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent)),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () => context.push(AppRoutes.about),
            child: const Text('About', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ).animate().fadeIn(delay: 200.ms),
          TextButton(
            onPressed: () => context.push(AppRoutes.schemes),
            child: const Text('Schemes to apply', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.accent)),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(dashboardControllerProvider.notifier).refreshAll(),
          color: AppColors.accent,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Header Greeting
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${user?.name?.split(' ').first ?? 'User'}',
                        style: AppTypography.displaySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ready to boost your financial profile?',
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.surfaceVariant,
                    child: Text(
                      user?.name?.substring(0, 1) ?? 'U',
                      style: AppTypography.titleLarge.copyWith(color: AppColors.accent),
                    ),
                  ),
                ],
              ).animate().slideX(begin: -0.1, end: 0).fadeIn(),
              
              const SizedBox(height: 32),
              
              // Real world testing image slider
              const HeroImageSlider(),
              
              const SizedBox(height: 32),

              // Hero Score Card (The "Get Started" core action)
              const HeroScoreCard().animate().slideY(begin: 0.1, end: 0).fadeIn(delay: 200.ms),
              
              const SizedBox(height: 32),
              
              Text('Quick Actions', style: AppTypography.titleLarge),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.track_changes_rounded,
                      label: 'Tracker',
                      onTap: () => context.go(AppRoutes.applications),
                    ).animate().scale(delay: 300.ms, duration: 400.ms),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.account_balance_rounded,
                      label: 'Micro Loans',
                      onTap: () => context.go(AppRoutes.loans),
                    ).animate().scale(delay: 400.ms, duration: 400.ms),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              const PrivacyHighlightSection().animate().fadeIn(delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 20),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.accent, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppTypography.labelLarge,
          ),
        ],
      ),
    );
  }
}
