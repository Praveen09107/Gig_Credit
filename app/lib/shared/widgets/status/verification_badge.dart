import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class VerificationBadge extends StatelessWidget {
  final String label;

  const VerificationBadge({
    super.key,
    this.label = 'Verified',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.verifiedLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.verified.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.verified,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.verified,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack).fadeIn();
  }
}
