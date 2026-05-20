import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../state/loan_provider.dart';
import '../../../state/score_provider.dart';
import '../../../state/loan_applications_provider.dart';
import '../../../services/loan_api_service.dart';

/// GigCredit Loan Detail Screen
/// Green hero header → offer details → 1-click disbursal
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

    final loanState = ref.read(loanProvider);
    final offer = loanState.offers.firstWhere(
      (o) => o.id == widget.offerId,
      orElse: () => loanState.offers.first,
    );
    final scoreReport = ref.read(scoreProvider).reportData;

    try {
      // Compute proposed EMI for DSCR check
      final monthlyRate = offer.interestRate / 12 / 100;
      final tenure = offer.tenureMonths;
      final proposedEmi = monthlyRate > 0
          ? (offer.amount * monthlyRate * pow(1 + monthlyRate, tenure)) / (pow(1 + monthlyRate, tenure) - 1)
          : offer.amount / tenure;

      // Derive income from P1 pillar contribution
      final p1Contrib = scoreReport?.pillarContributions['P1'] ?? 0;
      final monthlyIncome = (12000 + (p1Contrib * 200)).clamp(10000, 80000).toDouble();

      final application = {
        'loan_amount': offer.amount,
        'tenure_months': offer.tenureMonths,
        'product_id': offer.id,
        'purpose': 'Pre-approved offer',
        'kfs_acknowledged': true,
        'aadhaar_verified': scoreReport?.pillars.any((p) => p.code == 'P5' && p.confidence > 0.5) ?? true,
        'pan_verified': scoreReport?.pillars.any((p) => p.code == 'P8' && p.confidence > 0.5) ?? true,
        'net_monthly_income': monthlyIncome.round(),
        'existing_emi_total': ((scoreReport != null && scoreReport.finalScore > 700) ? monthlyIncome * 0.15 : monthlyIncome * 0.30).round(),
        'applicant_age': 28,
        'bank_statement_months': (scoreReport?.pillars.where((p) => p.code == 'P1').firstOrNull?.confidence ?? 0.5) > 0.7 ? 6 : 3,
        'mobile_verified': true,
        'proposed_emi': proposedEmi.round(),
      };
      final result = await ref.read(loanApiServiceProvider).applyLoan(
        application,
        scoreReport?.toJson() ?? {},
      );

      // Populate applications provider
      ref.read(loanApplicationsProvider.notifier).addApplication(
        LoanApplication(
          refId: result['loan_id']?.toString() ?? 'APP-${DateTime.now().millisecondsSinceEpoch}',
          nbfcName: offer.lenderName,
          amount: offer.amount.round(),
          tenure: '${offer.tenureMonths} months',
          purpose: 'Pre-approved',
          rate: offer.interestRate,
          appliedAt: DateTime.now(),
          status: result['decision'] == 'APPROVED' ? 'Approved' : 'Processing',
        ),
      );

      if (!mounted) return;
      setState(() => _isDisbursing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['decision'] == 'APPROVED'
                ? 'Loan approved! Disbursal in progress.'
                : 'Application submitted — under review.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
          ),
          backgroundColor: AppColors.bgCard,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDisbursing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submission failed: $e',
              style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loanState = ref.watch(loanProvider);
    final offer = loanState.offers.firstWhere(
      (o) => o.id == widget.offerId,
      orElse: () => loanState.offers.first,
    );

    return Scaffold(
      backgroundColor: AppColors.bgScreen,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.bgCard,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.greenPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(offer.lenderName,
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
            centerTitle: true,
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // Hero
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  decoration: const BoxDecoration(gradient: AppColors.heroGradient),
                  child: Column(
                    children: [
                      Text('Pre-Approved Offer',
                          style: AppTypography.eyebrow.copyWith(fontSize: 12))
                          .animate().fadeIn(delay: 80.ms),
                      const SizedBox(height: 10),
                      Text('₹${offer.amount}',
                          style: AppTypography.heroHeading.copyWith(
                            fontSize: 36,
                            letterSpacing: -1,
                          )).animate().fadeIn(delay: 150.ms),
                      const SizedBox(height: 6),
                      Text('${offer.interestRate}% p.a  •  ${offer.tenureMonths} Months',
                          style: AppTypography.heroBody.copyWith(fontSize: 14))
                          .animate().fadeIn(delay: 220.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Details
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AppCard(
                    child: Column(
                      children: [
                        _DetailRow(label: 'Loan Amount', value: '₹${offer.amount}'),
                        const Divider(color: AppColors.borderCard, height: 24),
                        _DetailRow(label: 'Interest Rate', value: '${offer.interestRate}% p.a'),
                        const Divider(color: AppColors.borderCard, height: 24),
                        _DetailRow(label: 'Tenure', value: '${offer.tenureMonths} Months'),
                        const Divider(color: AppColors.borderCard, height: 24),
                        _DetailRow(label: 'Est. EMI', value: '₹${offer.estimatedEmi}/mo'),
                        const Divider(color: AppColors.borderCard, height: 24),
                        _DetailRow(label: 'Processing Fee', value: '${(offer.interestRate > 18 ? 2.5 : 2.0).toStringAsFixed(1)}%'),
                        const Divider(color: AppColors.borderCard, height: 24),
                        _DetailRow(label: 'Loan Type', value: offer.highlights.isNotEmpty ? offer.highlights.first : 'Pre-approved'),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),

                const SizedBox(height: 20),

                // Disbursal card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AppCard(
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.warningLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.bolt, color: AppColors.warning, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('1-Click Disbursal',
                                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(
                                'No additional paperwork required. KYC verified via GigCredit.',
                                style: AppTypography.bodySmall.copyWith(height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.04),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            border: const Border(top: BorderSide(color: AppColors.borderCard)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: PrimaryButton(
            label: 'APPLY INSTANTLY',
            isLoading: _isDisbursing,
            onPressed: _applyForLoan,
            suffixIcon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textMuted,
              fontSize: 13,
            )),
        Text(value,
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            )),
      ],
    );
  }
}
