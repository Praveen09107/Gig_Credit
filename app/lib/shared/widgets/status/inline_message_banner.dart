import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

enum BannerType { error, success, info }

class InlineMessageBanner extends StatelessWidget {
  final String message;
  final BannerType type;

  const InlineMessageBanner({
    super.key,
    required this.message,
    this.type = BannerType.error,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (type) {
      case BannerType.error:
        bgColor = AppColors.errorLight.withValues(alpha: 0.5);
        textColor = AppColors.error;
        icon = Icons.error_outline_rounded;
        break;
      case BannerType.success:
        bgColor = AppColors.verifiedLight.withValues(alpha: 0.5);
        textColor = AppColors.verified;
        icon = Icons.check_circle_outline_rounded;
        break;
      case BannerType.info:
        bgColor = AppColors.accent.withValues(alpha: 0.2);
        textColor = AppColors.accentLight;
        icon = Icons.info_outline_rounded;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyMedium.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}
