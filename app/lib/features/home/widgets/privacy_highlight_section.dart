import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../../../shared/widgets/cards/app_card.dart';

class PrivacyHighlightSection extends StatelessWidget {
  const PrivacyHighlightSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy First',
          style: AppTypography.titleLarge,
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildRow(Icons.lock_outline_rounded, 'On-Device Processing', 'Data stays on your device.'),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(height: 1, color: AppColors.border),
              ),
              _buildRow(Icons.file_copy_outlined, 'No PDFs Stored', 'Statements are extracted and deleted instantly.'),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(height: 1, color: AppColors.border),
              ),
              _buildRow(Icons.security_rounded, 'Encryption', 'Bank-grade security applied on every step.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.accent, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.labelLarge),
              Text(subtitle, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
