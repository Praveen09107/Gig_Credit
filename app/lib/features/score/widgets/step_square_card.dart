import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';

/// GigCredit Step Square Card — for the "How It Works" grid
class StepSquareCard extends StatelessWidget {
  final int stepNumber;
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const StepSquareCard({
    super.key,
    required this.stepNumber,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: AppColors.greenMuted.withValues(alpha: 0.3),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          border: Border.all(color: AppColors.borderCard),
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.greenMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.greenPrimary, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              'Step $stepNumber',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: AppTypography.labelLarge.copyWith(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
