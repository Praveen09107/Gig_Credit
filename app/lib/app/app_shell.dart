import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../shared/theme/app_colors.dart';
import '../shared/theme/app_typography.dart';
import '../state/nav_provider.dart';
import '../state/step_status_provider.dart';
import '../state/verified_profile_provider.dart';
import '../state/score_provider.dart';
import '../shared/widgets/feedback/step_popups.dart';
import 'app_router.dart';

/// GigCredit App Shell — Bottom Navigation (4 tabs)
/// White bg, green active indicator, smooth tab transitions
class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const List<_NavItem> _items = [
    _NavItem(
        label: 'Home',
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        route: AppRoutes.home),
    _NavItem(
        label: 'Score',
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart_rounded,
        route: AppRoutes.score),
    _NavItem(
        label: 'History',
        icon: Icons.history_rounded,
        activeIcon: Icons.history_rounded,
        route: AppRoutes.reportHistory),
    _NavItem(
        label: 'Profile',
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        route: AppRoutes.profile),
  ];

  int _activeIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/app/score')) return 1;
    if (location.startsWith('/app/profile/reports')) return 2;
    if (location.startsWith('/app/profile')) return 3;
    return 0;
  }

  /// Returns true if the current route is inside the step flow (Steps 1-9 or generating)
  bool _isInStepFlow(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    return location.contains('/app/score/flow/') ||
        location.contains('/app/score/generating');
  }

  /// Show abandon confirmation when user tries to leave the step flow via footer
  Future<void> _handleTabTap(
      BuildContext context, WidgetRef ref, int index) async {
    HapticFeedback.selectionClick();

    if (_isInStepFlow(context)) {
      // Use the same premium popup style as the rest of the app
      final confirmed = await AbandonSessionPopup.show(context);
      if (confirmed != true) return; // User chose to stay

      // Clear all session data before navigating away
      ref.read(stepStatusProvider.notifier).reset();
      ref.read(verifiedProfileProvider.notifier).reset();
      ref.read(scoreProvider.notifier).reset();
    }

    ref.read(navProvider.notifier).setTab(index);
    context.go(_items[index].route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeIndex = _activeIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: _GigCreditBottomNav(
        activeIndex: activeIndex,
        items: _items,
        onTap: (index) => _handleTabTap(context, ref, index),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}

class _GigCreditBottomNav extends StatelessWidget {
  final int activeIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _GigCreditBottomNav({
    required this.activeIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: const Border(
          top: BorderSide(color: AppColors.borderCard, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = index == activeIndex;
              return Expanded(
                child: _NavTabItem(
                  item: item,
                  isActive: isActive,
                  onTap: () => onTap(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavTabItem extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTabItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: AppColors.greenMuted.withValues(alpha: 0.3),
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Active pill indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: isActive
                  ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
                  : EdgeInsets.zero,
              decoration: isActive
                  ? BoxDecoration(
                      color: AppColors.greenMuted,
                      borderRadius: BorderRadius.circular(20),
                    )
                  : null,
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                color: isActive
                    ? AppColors.greenPrimary
                    : AppColors.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: AppTypography.labelSmall.copyWith(
                color: isActive
                    ? AppColors.greenPrimary
                    : AppColors.textMuted,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                fontSize: 10,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}
