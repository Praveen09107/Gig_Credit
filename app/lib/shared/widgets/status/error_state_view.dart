import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../buttons/secondary_button.dart';

class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String title;

  const ErrorStateView({
    super.key,
    required this.message,
    required this.onRetry,
    this.title = 'Oops! Something went wrong',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.errorLight.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: AppColors.error,
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: AppTypography.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SecondaryButton(
            label: 'Try Again',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.accent),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
