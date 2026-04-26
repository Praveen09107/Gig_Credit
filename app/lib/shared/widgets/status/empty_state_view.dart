import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import '../buttons/primary_button.dart';

class EmptyStateView extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget imageOrIcon;
  final String? buttonLabel;
  final VoidCallback? onButtonTap;

  const EmptyStateView({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageOrIcon,
    this.buttonLabel,
    this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 160,
            width: 160,
            child: imageOrIcon,
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: AppTypography.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (buttonLabel != null && onButtonTap != null) ...[
            const SizedBox(height: 32),
            PrimaryButton(
              label: buttonLabel!,
              onPressed: onButtonTap,
            ),
          ],
        ],
      ),
    );
  }
}
