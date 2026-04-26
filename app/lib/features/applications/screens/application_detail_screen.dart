import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/buttons/secondary_button.dart';

class ApplicationDetailScreen extends StatelessWidget {
  final String applicationId;
  const ApplicationDetailScreen({super.key, required this.applicationId});

  @override
  Widget build(BuildContext context) {
    final isProcessing = applicationId == 'app_1';
    
    return Scaffold(
      appBar: AppBar(title: const Text('Application Status')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              isProcessing ? Icons.hourglass_top : Icons.check_circle,
              size: 80,
              color: isProcessing ? AppColors.warning : AppColors.gradeA,
            ),
            const SizedBox(height: 16),
            Text(
              isProcessing ? 'Application in Review' : 'Loan Approved',
              style: AppTypography.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              isProcessing 
                  ? 'The lender is processing your 1-click application.'
                  : 'Your loan was successfully approved and disbursed.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 48),
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _DetailRow(label: 'Application ID', value: applicationId.toUpperCase()),
                  const Divider(height: 32, color: AppColors.divider),
                  const _DetailRow(label: 'Lender', value: 'HDFC Bank'),
                  const SizedBox(height: 16),
                  const _DetailRow(label: 'Loan Amount', value: '₹50,000'),
                  const SizedBox(height: 16),
                  const _DetailRow(label: 'Interest Rate', value: '14% p.a'),
                  const SizedBox(height: 16),
                  const _DetailRow(label: 'Tenure', value: '12 Months'),
                ],
              ),
            ),
            const SizedBox(height: 48),
            SecondaryButton(
              label: 'Download Agreement Terms',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
