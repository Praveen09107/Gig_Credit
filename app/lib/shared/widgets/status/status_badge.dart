import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../../core/enums/app_enums.dart';

class StatusBadge extends StatelessWidget {
  final ApplicationStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case ApplicationStatus.approved:
      case ApplicationStatus.disbursed:
        bgColor = AppColors.successLight;
        textColor = AppColors.success;
        label = status == ApplicationStatus.approved ? 'Approved' : 'Disbursed';
        break;
      case ApplicationStatus.rejected:
        bgColor = AppColors.errorLight;
        textColor = AppColors.error;
        label = 'Rejected';
        break;
      case ApplicationStatus.underReview:
      case ApplicationStatus.decisionPending:
        bgColor = AppColors.warningLight;
        textColor = AppColors.warning;
        label = 'In Review';
        break;
      case ApplicationStatus.submitted:
      case ApplicationStatus.consentVerified:
        bgColor = AppColors.accent.withValues(alpha: 0.2);
        textColor = AppColors.accentLight;
        label = 'Processing';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
