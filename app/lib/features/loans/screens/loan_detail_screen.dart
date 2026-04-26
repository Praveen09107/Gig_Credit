import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../state/loan_provider.dart';

class LoanDetailScreen extends ConsumerStatefulWidget {
  final String offerId;
  const LoanDetailScreen({super.key, required this.offerId});

  @override
  ConsumerState<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends ConsumerState<LoanDetailScreen> {
  bool _isDisbursing = false;

  void _applyForLoan() async {
    setState(() => _isDisbursing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isDisbursing = false);
    
    // Simulate approval and return
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Application Submitted successfully!')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final loanState = ref.watch(loanProvider);
    final offer = loanState.offers.firstWhere((o) => o.id == widget.offerId, orElse: () => loanState.offers.first);

    return Scaffold(
      appBar: AppBar(title: Text(offer.lenderName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Exclusive Pre-Approved Offer', style: AppTypography.labelMedium.copyWith(color: AppColors.gradeA)),
            const SizedBox(height: 8),
            Text('₹${offer.amount}', style: AppTypography.displayLarge.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _InfoTile(label: 'Interest Rate', value: '${offer.interestRate}% p.a')),
                Expanded(child: _InfoTile(label: 'Tenure', value: '${offer.tenureMonths} Months')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _InfoTile(label: 'Processing Fee', value: '2%')),
                Expanded(child: _InfoTile(label: 'Loan Type', value: 'PERSONAL LOAN')),
              ],
            ),
            const SizedBox(height: 48),
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bolt, color: AppColors.warning),
                      SizedBox(width: 8),
                      Text('1-Click Disbursal', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Because you have verified your Gig Income and KYC through GigCredit, no additional paperwork is required.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: PrimaryButton(
            label: 'Apply Instantly',
            isLoading: _isDisbursing,
            onPressed: _applyForLoan,
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }
}
