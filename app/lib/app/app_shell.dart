import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../shared/theme/app_colors.dart';
import '../shared/theme/app_typography.dart';
import '../state/nav_provider.dart';
import 'app_router.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const List<_NavItem> _items = [
    _NavItem(label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home_rounded, route: AppRoutes.home),
    _NavItem(label: 'Score', icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded, route: AppRoutes.score),
    _NavItem(label: 'Loans', icon: Icons.account_balance_outlined, activeIcon: Icons.account_balance_rounded, route: AppRoutes.loans),
    _NavItem(label: 'Track', icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, route: AppRoutes.applications),
    _NavItem(label: 'Profile', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, route: AppRoutes.profile),
  ];

  int _activeIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/app/score')) return 1;
    if (location.startsWith('/app/loans')) return 2;
    if (location.startsWith('/app/applications')) return 3;
    if (location.startsWith('/app/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeIndex = _activeIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: _GigCreditBottomNav(
        activeIndex: activeIndex,
        items: _items,
        onTap: (index) {
          ref.read(navProvider.notifier).setTab(index);
          context.go(_items[index].route);
        },
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
        color: AppColors.card,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: isActive
                  ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
                  : EdgeInsets.zero,
              decoration: isActive
                  ? BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    )
                  : null,
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                color: isActive ? AppColors.accent : AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppTypography.labelSmall.copyWith(
                color: isActive ? AppColors.accent : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
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
