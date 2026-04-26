import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../app/app_router.dart';
import '../../../state/loan_applications_provider.dart';

class ApplicationsScreen extends ConsumerWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applications = ref.watch(loanApplicationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Application Tracker')),
      body: applications.isEmpty
          ? _buildEmptyState(context)
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text('Track Your Loans', style: AppTypography.displaySmall)
                    .animate().fadeIn().slideX(begin: -0.1, end: 0),
                const SizedBox(height: 8),
                Text(
                  'Monitor the status of your micro-loan applications applied via GigCredit.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
                const SizedBox(height: 32),
                ...applications.asMap().entries.map((entry) {
                  final i = entry.key;
                  final app = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _ApplicationCard(
                      bankName: app.nbfcName,
                      loanType: '${app.purpose} Loan',
                      amount: '₹${app.amount}',
                      date: _formatDate(app.appliedAt),
                      status: app.status,
                      refId: app.refId,
                      icon: Icons.account_balance_rounded,
                      delayMs: 200 + i * 100,
                      onTap: () {},
                    ),
                  );
                }),
              ],
            ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceVariant),
              ),
              child: const Icon(Icons.assignment_outlined, size: 48, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            const Text('No Applications Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text(
              'After you apply for a loan via your GigCredit Report, your applications will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.score),
              icon: const Icon(Icons.credit_score),
              label: const Text('Generate Credit Report'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final String bankName;
  final String loanType;
  final String amount;
  final String date;
  final String status;
  final String refId;
  final IconData icon;
  final int delayMs;
  final VoidCallback onTap;

  const _ApplicationCard({
    required this.bankName,
    required this.loanType,
    required this.amount,
    required this.date,
    required this.status,
    required this.refId,
    required this.icon,
    required this.delayMs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isProcessing = status == 'Processing';

    Color statusColor = AppColors.verified;
    if (isProcessing) statusColor = AppColors.warning;

    IconData statusIcon = Icons.check_circle_rounded;
    if (isProcessing) statusIcon = Icons.hourglass_top_rounded;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.accent, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bankName, style: AppTypography.titleLarge),
                      const SizedBox(height: 4),
                      Text(loanType, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 4),
                      Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amount Applied', style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
                    const SizedBox(height: 4),
                    Text(amount, style: AppTypography.titleMedium.copyWith(color: AppColors.accent, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Applied On', style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
                    const SizedBox(height: 4),
                    Text(date, style: AppTypography.titleMedium),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Ref: $refId', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11, fontFamily: 'monospace')),
            if (isProcessing) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.warning),
                backgroundColor: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true)).fade(begin: 0.4, end: 1.0, duration: 800.ms),
            ]
          ],
        ),
      ),
    ).animate().slideY(begin: 0.2, end: 0).fadeIn(delay: Duration(milliseconds: delayMs));
  }
}
