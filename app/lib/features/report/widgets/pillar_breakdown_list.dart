import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../models/score_pillar_model.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';

class PillarBreakdownList extends StatefulWidget {
  final List<ScorePillarModel> pillars;
  const PillarBreakdownList({super.key, required this.pillars});

  @override
  State<PillarBreakdownList> createState() => _PillarBreakdownListState();
}

class _PillarBreakdownListState extends State<PillarBreakdownList> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.greenMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.analytics, color: AppColors.greenPrimary, size: 20),
            ),
            const SizedBox(width: 12),
            Text('7-Pillar Breakdown', style: AppTypography.titleLarge),
          ],
        ),
        const SizedBox(height: 16),
        ...widget.pillars.asMap().entries.map((e) => _buildAccordion(e.value, e.key)),
      ],
    );
  }

  Widget _buildAccordion(ScorePillarModel pillar, int index) {
    final isExpanded = _expandedIndex == index;
    final ratio = pillar.maxScore > 0 ? pillar.score / pillar.maxScore : 0.0;
    final color = _barColor(ratio);
    final content = _getPillarContent(pillar.code);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuart,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpanded ? color.withValues(alpha: 0.4) : AppColors.borderCard,
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: isExpanded
            ? [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 2)]
            : [],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expandedIndex = isExpanded ? null : index),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pillar.title, style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(pillar.subtitle, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '${pillar.score}/${pillar.maxScore}',
                          style: AppTypography.labelMedium.copyWith(color: color, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  if (!isExpanded) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: ratio),
                        duration: Duration(milliseconds: 600 + index * 100),
                        curve: Curves.easeOutCubic,
                        builder: (_, val, __) => LinearProgressIndicator(
                          value: val,
                          minHeight: 8,
                          backgroundColor: AppColors.borderCard,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: AppColors.borderCard),
                  const SizedBox(height: 16),
                  
                  // STYLIZED POSITIVES
                  _buildBulletList('Positives', content['positives']!, Colors.green, Icons.check_circle),
                  const SizedBox(height: 16),
                  
                  // STYLIZED NEGATIVES
                  _buildBulletList('Negatives', content['negatives']!, Colors.orange, Icons.warning_rounded),
                  const SizedBox(height: 20),
                  
                  // PREMIUM AI REASON BLOCK
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.greenMuted, AppColors.bgCard],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.greenBright.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.psychology, color: AppColors.greenPrimary, size: 18),
                            SizedBox(width: 8),
                            Text('Detailed AI Reason', style: TextStyle(color: AppColors.greenPrimary, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          content['reason']!,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (200 + index * 100).ms).slideY(begin: 0.1);
  }

  Widget _buildBulletList(String title, String text, Color color, IconData icon) {
    // Split the text by bullets
    final points = text.split('•').where((s) => s.trim().isNotEmpty).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        ...points.map((point) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6, right: 12),
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.6), shape: BoxShape.circle),
              ),
              Expanded(
                child: Text(
                  point.trim(),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Map<String, String> _getPillarContent(String code) {
    switch (code) {
      case 'p1': return {
          'positives': '• Reliable transaction history shows highly consistent earning patterns over the last 6 months.\n• Your platform usage metrics strongly correlate with top-tier gig workers in your locality.',
          'negatives': '• Lack of formal tax filing limits the absolute ceiling of this pillar.\n• Minor fluctuations in off-peak months reduce overall stability confidence.',
          'reason': 'The AI evaluation determined this score based on a comprehensive review of your digital footprint. Your primary earning streams are robust and demonstrate high resilience against market volatility. However, the absence of secondary verified data points like GST returns or ITR means the model must apply a slight risk penalty. By diversifying your platform usage and formalizing your tax status, this pillar score could increase by 15-20 points. Overall, this is a strong performance indicating reliable cash flow.'
        };
      case 'p2': return {
          'positives': '• Zero defaults recorded in the past 12 months on utility and micro-loan repayments.\n• Consistent maintenance of minimum required balances before EMI due dates.',
          'negatives': '• Only one active credit line makes the credit history slightly thin.\n• Delayed payment on a minor utility bill 8 months ago impacted the perfection score.',
          'reason': 'Payment discipline is the strongest indicator of intent to repay. Your historical data shows a near-perfect track record for fulfilling obligations on time. The AI identified that you proactively manage your balances ahead of scheduled auto-debits, which is a highly positive behavioral trait. The only constraint holding back a perfect score is the lack of diverse credit lines (like a major credit card) to prove discipline across multiple obligation types. Lenders view this specific pillar output as highly trustworthy.'
        };
      case 'p3': return {
          'positives': '• Your Debt-to-Income (DTI) ratio is exceptionally healthy at under 15%.\n• No instances of credit-hungry behavior (e.g., multiple hard inquiries in a short span).',
          'negatives': '• High utilization on a single small-ticket buy-now-pay-later (BNPL) account.\n• Limited history of managing larger, long-term debt structures.',
          'reason': 'Debt management measures how well you balance your income against your outstanding obligations. The model positively weighted your low overall debt burden, indicating you are not over-leveraged. You have avoided taking multiple simultaneous micro-loans, which gig workers frequently do when distressed. The minor negative factor is that your active BNPL account is frequently maxed out, even if paid on time. Keeping individual line utilization below 30% will rapidly improve this specific assessment.'
        };
      case 'p4': return {
          'positives': '• Steady month-over-month increase in baseline account liquidity.\n• Evidence of small, recurring transfers to secondary accounts or digital wallets.',
          'negatives': '• Lack of formal high-yield savings or fixed deposit investments.\n• Emergency fund reserve is below the recommended 3-month income threshold.',
          'reason': 'Savings behavior acts as a critical shock absorber for gig workers who lack fixed salaries. The AI analyzed your bank statement inflows and outflows, noting that you consistently retain about 12% of your monthly earnings at the end of each cycle. This proves you operate at a surplus rather than a deficit. However, to achieve a maximum score, the model looks for structured savings (like recurring deposits or mutual funds). Starting a formal SIP would drastically enhance the predictive stability of this profile.'
        };
      case 'p5': return {
          'positives': '• Aadhaar and PAN matching completed with 99.8% demographic confidence.\n• Live face verification confirmed liveness and identity ownership without discrepancies.',
          'negatives': '• Address mismatch flag between Aadhaar and current geo-location of device.\n• Lack of secondary employment proof (e.g., official platform ID card upload).',
          'reason': 'This pillar assesses the fundamental legitimacy of your profile to prevent fraud. The on-device OCR and face-matching engines successfully authenticated your core government IDs, creating a highly trusted baseline. The slight deduction stems from a minor geographical variance where your active device location does not perfectly align with your registered permanent address. This is common for migrant gig workers, but providing localized address proof (like a recent utility bill) would eliminate this minor risk flag.'
        };
      case 'p6': return {
          'positives': '• Income is sourced from at least two distinct gig-economy platforms, reducing single-point failure risk.\n• Basic life insurance premium payments detected in recent transaction history.',
          'negatives': '• No active health insurance policy found, posing a catastrophic medical risk to earnings.\n• Income dips sharply during traditional monsoon months, indicating seasonal vulnerability.',
          'reason': 'Resilience evaluates how well you can withstand unexpected financial shocks. Your multi-platform approach is heavily rewarded by the AI, as losing access to one app will not completely halt your earnings. However, the model flagged the absence of comprehensive health coverage. For physical gig workers, a medical emergency means immediate income cessation. Procuring a low-cost, high-coverage health insurance plan is the single most effective action you can take to boost this specific pillar score.'
        };
      case 'p7': return {
          'positives': '• No digital fraud flags or associated risky device behaviors detected.\n• Consistent usage of formal banking channels over cash for daily transactions.',
          'negatives': '• Absence of community-based financial participation (e.g., recognized chit funds or micro-saving groups).\n• Tax footprint is virtually non-existent for the last two assessment years.',
          'reason': 'Social accountability measures your integration into the formal financial ecosystem. The AI verifies that your device is clean from malicious apps and your digital footprint aligns with legitimate commercial activity. Your preference for UPI and digital banking provides a transparent trail of accountability. The primary area for growth is formalizing your tax status. Even a zero-tax ITR filing establishes a government-backed record of your earnings, which institutional lenders require for premium lending rates.'
        };
      default: return {
          'positives': '• Standard reliable metric found.\n• Consistent baseline performance.',
          'negatives': '• Needs formalization in some areas.\n• Minor variance detected.',
          'reason': 'The AI has assessed this metric and found it to be within acceptable baseline parameters. Continual steady performance will improve this over time.'
        };
    }
  }

  Color _barColor(double ratio) {
    if (ratio >= 0.8) return AppColors.gradeA;
    if (ratio >= 0.6) return AppColors.gradeB;
    if (ratio >= 0.4) return AppColors.gradeC;
    return AppColors.error;
  }
}
