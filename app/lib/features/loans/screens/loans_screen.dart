import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../state/loan_provider.dart';
import '../../../core/enums/app_enums.dart';

class LoansScreen extends ConsumerWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loanState = ref.watch(loanProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Credit Offers')),
      body: loanState.status == LoanEligibilityStatus.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: loanState.offers.length,
              itemBuilder: (ctx, idx) {
                final offer = loanState.offers[idx];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AppCard(
                    onTap: () => context.push('/app/loans/detail/${offer.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(offer.lenderName, style: AppTypography.titleMedium),
                              const _OfferTypeBadge(type: 'Personal'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _DetailColumn(
                                  label: 'Amount',
                                  value: '₹${offer.amount}',
                                ),
                              ),
                              Expanded(
                                child: _DetailColumn(
                                  label: 'Interest',
                                  value: '${offer.interestRate}% p.a',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Pre-approved based on your GigCredit score',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.gradeA),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _OfferTypeBadge extends StatelessWidget {
  final String type;
  const _OfferTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent),
      ),
      child: Text(
        type.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(color: AppColors.accentLight),
      ),
    );
  }
}

class _DetailColumn extends StatelessWidget {
  final String label;
  final String value;
  const _DetailColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.titleLarge),
      ],
    );
  }
}
