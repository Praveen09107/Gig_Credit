import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../state/user_provider.dart';
import '../../../state/auth_provider.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/feedback/app_toast.dart';
import '../../../app/app_router.dart';

/// GigCredit Profile Screen
/// Green avatar hero → detail card → preferences → logout confirm sheet
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _numberMasked = true;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final mobile = user?.mobile ?? '9876543210';
    final name = user?.name ?? 'Gig Worker';

    return Scaffold(
      backgroundColor: AppColors.bgScreen,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.bgCard,
            elevation: 0,
            title: Text(
              'My Profile',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Avatar Hero ────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
                  decoration: const BoxDecoration(gradient: AppColors.heroGradient),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.45),
                            width: 3,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          name.substring(0, 1).toUpperCase(),
                          style: AppTypography.displayMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ).animate().scale(
                            begin: const Offset(0.8, 0.8),
                            duration: 400.ms,
                            curve: Curves.easeOutBack,
                          ),
                      const SizedBox(height: 14),
                      Text(
                        name,
                        style: AppTypography.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 4),
                      // Masked phone
                      GestureDetector(
                        onTap: () => setState(() => _numberMasked = !_numberMasked),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _numberMasked
                                  ? '+91 ${mobile.substring(0, 2)}****${mobile.substring(6)}'
                                  : '+91 $mobile',
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.80),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _numberMasked
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: Colors.white.withValues(alpha: 0.60),
                              size: 16,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 180.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Profile Details Card ───────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AppCard(
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Full Name',
                          value: name,
                        ),
                        const Divider(color: AppColors.borderCard, height: 24),
                        _DetailRow(
                          icon: Icons.phone_android_rounded,
                          label: 'Mobile',
                          value: '+91 $mobile',
                        ),
                        const Divider(color: AppColors.borderCard, height: 24),
                        _DetailRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'Member Since',
                          value: _memberSinceDate(ref),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.05),

                const SizedBox(height: 24),

                // ── Preferences ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PREFERENCES',
                        style: AppTypography.sectionLabel,
                      ),
                      const SizedBox(height: 12),
                      AppCard(
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          children: [
                            _SettingsTile(
                              icon: Icons.language_rounded,
                              label: 'Language',
                              trailing: 'English',
                              onTap: () {},
                            ),
                            const Divider(
                                color: AppColors.borderCard, height: 1),
                            _SettingsTile(
                              icon: Icons.notifications_none_rounded,
                              label: 'Notifications',
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.04),

                const SizedBox(height: 24),

                // ── Help ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HELP & SUPPORT',
                        style: AppTypography.sectionLabel,
                      ),
                      const SizedBox(height: 12),
                      AppCard(
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          children: [
                            _SettingsTile(
                              icon: Icons.privacy_tip_outlined,
                              label: 'Privacy Policy',
                              onTap: () {},
                            ),
                            const Divider(
                                color: AppColors.borderCard, height: 1),
                            _SettingsTile(
                              icon: Icons.support_agent_rounded,
                              label: 'Contact Support',
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.04),

                const SizedBox(height: 32),

                // ── Logout ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _LogoutButton(
                    onTap: () => _showLogoutSheet(context),
                  ),
                ).animate().fadeIn(delay: 550.ms),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xA60D1F15),
      builder: (_) => _LogoutConfirmSheet(
        onConfirm: () async {
          Navigator.pop(context);
          // Clear secure storage + in-memory state
          await ref.read(authControllerProvider.notifier).logout();
          if (!context.mounted) return;
          // Navigate to login — router redirect will also enforce this
          context.go(AppRoutes.login);
        },
      ),
    );
  }

  String _memberSinceDate(WidgetRef ref) {
    final authState = ref.read(authProvider);
    // Use auth creation timestamp if available, otherwise current date
    final createdAt = authState.createdAt;
    if (createdAt != null) {
      return DateFormat('MMM yyyy').format(createdAt);
    }
    // Fallback: use current month
    return DateFormat('MMM yyyy').format(DateTime.now());
  }
}

// ═══════════════════════════════════════════════════════════════════════════

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.greenMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.greenPrimary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  )),
              const SizedBox(height: 2),
              Text(value,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.greenPrimary, size: 22),
      title: Text(label,
          style: AppTypography.bodyLarge.copyWith(fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(trailing!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                )),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          color: AppColors.errorBg,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
            const SizedBox(width: 10),
            Text(
              'Log Out',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutConfirmSheet extends StatelessWidget {
  final VoidCallback onConfirm;
  const _LogoutConfirmSheet({required this.onConfirm});

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
          children: [
            // Drag handle
            const SizedBox(height: 14),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderCard,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 28),

            // Warning icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.errorLight,
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.20), width: 2),
              ),
              child: const Icon(Icons.logout_rounded,
                  color: AppColors.error, size: 32),
            ),

            const SizedBox(height: 20),

            Text(
              'Log Out?',
              style: AppTypography.headlineLarge.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your data is stored locally.\nYou can sign in again anytime.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(height: 1.6),
            ),

            const SizedBox(height: 28),

            // Confirm
            GestureDetector(
              onTap: onConfirm,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  'YES, LOG OUT',
                  style: AppTypography.button.copyWith(fontSize: 15),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Cancel
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderCard, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Cancel',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
