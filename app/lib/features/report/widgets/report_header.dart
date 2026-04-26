import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';

class ReportHeader extends StatelessWidget {
  final DateTime generatedAt;
  const ReportHeader({super.key, required this.generatedAt});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${generatedAt.day.toString().padLeft(2, '0')} '
        '${_month(generatedAt.month)} ${generatedAt.year}';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Credit Score Report', style: AppTypography.displaySmall),
              const SizedBox(height: 4),
              Text('Generated on $dateStr', style: AppTypography.bodySmall),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.gradeA.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gradeA.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified, color: AppColors.gradeA, size: 16),
              const SizedBox(width: 4),
              Text('Verified', style: AppTypography.labelSmall.copyWith(color: AppColors.gradeA)),
            ],
          ),
        ),
      ],
    );
  }

  String _month(int m) => const [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ][m];
}
