import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/loaders/skeleton_shimmer.dart';
import '../../../state/loan_provider.dart';
import '../../../core/enums/app_enums.dart';

/// GigCredit Loan Offers Screen
/// Green hero banner → loan offer cards with lender info, amount, interest
class LoansScreen extends ConsumerWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loanState = ref.watch(loanProvider);
    final hasOffers = loanState.offers.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bgScreen,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.bgCard,
            elevation: 0,
            title: Text(
              'Credit Offers',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
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
                  Text(
                    '💰  Personalised Offers',
                    style: AppTypography.eyebrow.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    hasOffers
                        ? '${loanState.offers.length} Loan Offers\nUnlocked for You'
                        : 'No Offers Yet',
                    style: AppTypography.heroHeading.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasOffers
                        ? 'Pre-approved based on your GigCredit score. Tap any offer to view details.'
                        : 'Complete your credit scoring to unlock personalised loan offers.',
                    style: AppTypography.heroBody,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
          ),

          // Offer cards
          if (loanState.status == LoanEligibilityStatus.loading)
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 32),
              sliver: SliverToBoxAdapter(
                child: SkeletonShimmer(isList: true),
              ),
            )
          else if (!hasOffers)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.greenMuted,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance_outlined,
                          size: 32, color: AppColors.greenPrimary),
                    ),
                    const SizedBox(height: 16),
                    Text('No offers available',
                        style: AppTypography.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      'Complete your score to see loan offers',
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, idx) {
                    final offer = loanState.offers[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: AppCard(
                        onTap: () =>
                            context.push('/app/loans/detail/${offer.id}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: AppColors.greenMuted,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                          Icons.account_balance_rounded,
                                          size: 18,
                                          color: AppColors.greenPrimary),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(offer.lenderName,
                                        style: AppTypography.titleSmall
                                            .copyWith(
                                                fontWeight: FontWeight.w700)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.greenMuted,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                        color: AppColors.greenBright
                                            .withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    'PRE-APPROVED',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.greenPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Stats
                            Row(
                              children: [
                                Expanded(
                                  child: _DetailColumn(
                                    label: 'Amount',
                                    value: '₹${offer.amount}',
                                    valueColor: AppColors.greenPrimary,
                                  ),
                                ),
                                Container(
                                    width: 1,
                                    height: 32,
                                    color: AppColors.borderCard),
                                Expanded(
                                  child: _DetailColumn(
                                    label: 'Interest',
                                    value: '${offer.interestRate}% p.a',
                                  ),
                                ),
                                Container(
                                    width: 1,
                                    height: 32,
                                    color: AppColors.borderCard),
                                Expanded(
                                  child: _DetailColumn(
                                    label: 'EMI',
                                    value: '₹${offer.estimatedEmi}/mo',
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // Highlights
                            if (offer.highlights.isNotEmpty)
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: offer.highlights
                                    .map((h) => Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.bgScreen,
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            h,
                                            style: AppTypography.labelSmall
                                                .copyWith(
                                              color: AppColors.textSecondary,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                          ],
                        ),
                      ),
                    ).animate()
                        .fadeIn(delay: Duration(milliseconds: 200 + idx * 80))
                        .slideY(
                            begin: 0.06,
                            duration: 400.ms,
                            curve: Curves.easeOutCubic);
                  },
                  childCount: loanState.offers.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailColumn({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: AppTypography.labelSmall
                .copyWith(color: AppColors.textMuted, fontSize: 10)),
        const SizedBox(height: 3),
        Text(value,
            style: AppTypography.labelLarge.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
            )),
      ],
    );
  }
}
