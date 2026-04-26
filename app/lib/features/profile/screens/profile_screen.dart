import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../state/user_provider.dart';
import '../../../shared/widgets/cards/app_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.accent.withValues(alpha: 0.2),
              child: Text(
                user?.name?.substring(0, 1) ?? 'U',
                style: AppTypography.displaySmall.copyWith(color: AppColors.accent),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              user?.name ?? 'Gig Worker',
              style: AppTypography.titleLarge,
            ),
          ),
          Center(
            child: Text(
              '+91 ${user?.mobile ?? "9876543210"}',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 48),
          Text('Preferences', style: AppTypography.titleMedium),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: AppColors.accentLight),
                  title: Text('Language', style: AppTypography.bodyLarge),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('English', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
                      const Icon(Icons.chevron_right, color: AppColors.border),
                    ],
                  ),
                ),
                Divider(color: AppColors.border, height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined, color: AppColors.accentLight),
                  title: Text('Notifications', style: AppTypography.bodyLarge),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.border),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('Help & Support', style: AppTypography.titleMedium),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.accentLight),
                  title: Text('Privacy Policy', style: AppTypography.bodyLarge),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.border),
                ),
                Divider(color: AppColors.border, height: 1),
                ListTile(
                  leading: const Icon(Icons.support_agent_rounded, color: AppColors.accentLight),
                  title: Text('Contact Support', style: AppTypography.bodyLarge),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.border),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
