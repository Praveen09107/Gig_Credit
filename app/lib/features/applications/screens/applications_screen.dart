import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../app/app_router.dart';
import '../../../state/loan_applications_provider.dart';

/// GigCredit Application Tracker Screen
/// Green hero → application cards with status badges
class ApplicationsScreen extends ConsumerWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applications = ref.watch(loanApplicationsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgScreen,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.bgCard,
            elevation: 0,
            title: Text('Track Applications',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
            centerTitle: true,
          ),

          // Hero band
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              decoration: const BoxDecoration(gradient: AppColors.heroGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📋  Application Tracker',
                      style: AppTypography.eyebrow.copyWith(fontSize: 13)),
                  const SizedBox(height: 10),
                  Text(
                    applications.isNotEmpty
                        ? '${applications.length} Active\nApplications'
                        : 'No Applications\nSubmitted Yet',
                    style: AppTypography.heroHeading.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Monitor the status of your micro-loan applications applied via GigCredit.',
                    style: AppTypography.heroBody,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
          ),

          // Content
          if (applications.isEmpty)
            SliverFillRemaining(child: _buildEmptyState(context))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final app = applications[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ApplicationCard(
                        bankName: app.nbfcName,
                        loanType: '${app.purpose} Loan',
                        amount: '₹${app.amount}',
                        date: _formatDate(app.appliedAt),
                        status: app.status,
                        refId: app.refId,
                        icon: Icons.account_balance_rounded,
                        delayMs: 200 + i * 80,
                        onTap: () => _showApplicationDetail(context, app),
                      ),
                    );
                  },
                  childCount: applications.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
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
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.greenMuted,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.assignment_outlined,
                  size: 32, color: AppColors.greenPrimary),
            ),
            const SizedBox(height: 20),
            Text('No Applications Yet',
                style: AppTypography.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Apply for a loan via your GigCredit Report.\nYour applications will appear here.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.score),
              icon: const Icon(Icons.credit_score, size: 18),
              label: const Text('Generate Credit Report'),
            ),
          ],
        ),
      ),
    );
  }

  void _showApplicationDetail(BuildContext context, LoanApplication app) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: AppColors.borderCard, borderRadius: BorderRadius.circular(999)),
                ),
              ),
              Text('Application Details', style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              _detailRow('Lender', app.nbfcName),
              _detailRow('Amount', '₹${app.amount}'),
              _detailRow('Tenure', app.tenure),
              _detailRow('Purpose', app.purpose),
              _detailRow('Interest Rate', '${app.rate}% p.a'),
              _detailRow('Status', app.status),
              _detailRow('Reference ID', app.refId),
              _detailRow('Applied On', _formatDate(app.appliedAt)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.greenPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
          Text(value, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final String bankName, loanType, amount, date, status, refId;
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

    Color statusColor = AppColors.success;
    if (isProcessing) statusColor = AppColors.warning;

    IconData statusIcon = Icons.check_circle_rounded;
    if (isProcessing) statusIcon = Icons.hourglass_top_rounded;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.greenMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.greenPrimary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bankName,
                        style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(loanType,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 12),
                    const SizedBox(width: 4),
                    Text(status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: AppColors.borderCard),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Amount',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 10)),
                  const SizedBox(height: 3),
                  Text(amount,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.greenPrimary,
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Applied',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 10)),
                  const SizedBox(height: 3),
                  Text(date, style: AppTypography.labelLarge),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Ref: $refId',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontFamily: 'monospace',
              )),
          if (isProcessing) ...[
            const SizedBox(height: 14),
            LinearProgressIndicator(
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.warning),
              backgroundColor: AppColors.borderCard,
              borderRadius: BorderRadius.circular(4),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
                .fade(begin: 0.4, end: 1.0, duration: 800.ms),
          ]
        ],
      ),
    ).animate()
        .slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOutCubic)
        .fadeIn(delay: Duration(milliseconds: delayMs));
  }
}
