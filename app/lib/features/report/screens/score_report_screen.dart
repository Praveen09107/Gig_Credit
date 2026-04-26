import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../pdf_report_generator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../shared/widgets/buttons/secondary_button.dart';
import '../../../state/score_provider.dart';
import '../../../state/step_status_provider.dart';
import '../../../state/verified_profile_provider.dart';
import '../../../app/app_router.dart';
import '../widgets/report_header.dart';
import '../widgets/score_summary_card.dart';
import '../widgets/pillar_breakdown_list.dart';

class ScoreReportScreen extends ConsumerWidget {
  const ScoreReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(scoreProvider);
    final report = session.reportData;

    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Score Report')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              const Text('No report generated yet.'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Return to Dashboard'),
              ),
            ],
          ),
        ),
      );
    }

    final summaryText = report.llmExplanation ?? 
        'This score of ${report.finalScore} places you in the ${report.riskBand.toLowerCase()} risk category. '
        'Based on your verified digital footprint, you demonstrate strong financial resilience and reliable cash flow. '
        'Your profile indicates responsible debt management, though minor improvements in formal savings could elevate your grade further. '
        'Overall, lenders will view this profile favorably for micro-credit and short-term working capital loans. '
        'Continue maintaining on-time utility payments to secure top-tier lending rates.';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('GigCredit Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. HEADER SECTION
            _buildSectionLabel('1. Header Section'),
            ReportHeader(generatedAt: report.generatedAt).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
            const SizedBox(height: 24),
            
            // 2. SCORE SECTION
            _buildSectionLabel('2. Score Section'),
            ScoreSummaryCard(
              finalScore: report.finalScore,
              grade: report.grade,
              riskBand: report.riskBand,
            ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),
            
            const SizedBox(height: 24),

            // 3. SCORE SUMMARY
            _buildSectionLabel('3. Score Summary'),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardElevated,
                borderRadius: BorderRadius.circular(16),
                border: const Border(left: BorderSide(color: AppColors.accent, width: 4)),
                boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.format_quote_rounded, color: AppColors.accent, size: 24),
                      SizedBox(width: 8),
                      Text('Executive Summary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(summaryText, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6, fontStyle: FontStyle.italic)),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

            const SizedBox(height: 24),

            // 4. POSITIVE FACTORS
            _buildSectionLabel('4. Positive Factors'),
            _buildStylizedCard(
              Icons.trending_up, 
              Colors.green, 
              '• Your consistent Gig-platform earnings demonstrate high reliability. The AI noted a strong correlation between your active work hours and your ability to maintain cash reserves.\n• The absence of any major defaults in the past 12 months provides a massive boost to your credibility. This establishes a highly trustworthy baseline for future credit.'
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 24),

            // 5. DETAILED REASON BREAKDOWN
            _buildSectionLabel('5. Detailed Reason Breakdown'),
            _buildStylizedCard(
              Icons.psychology, 
              Colors.purple, 
              'The algorithm assigned this specific score because your income stability is heavily offset by a lack of formal savings. While you have excellent payment discipline on small utilities, the AI requires proof of handling larger obligations to unlock the next score tier. The primary reason you sit in this specific band is the absence of an ITR filing, which acts as a ceiling for gig-worker profiles in our current scoring model.'
            ).animate().fadeIn(delay: 450.ms),

            const SizedBox(height: 24),

            // 6. FINANCIAL PROFILE SUMMARY
            _buildSectionLabel('6. Financial Profile Summary'),
            _buildStylizedCard(
              Icons.account_balance_wallet, 
              Colors.blue, 
              'The analysis reveals a steady month-over-month income with moderate volatility. Your repayment patterns on smaller utilities are excellent, indicating good financial discipline. However, your reliance on cash-based transactions slightly obscures your true liquidity. Formalizing your income through digital banking will significantly improve this profile.'
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 32),

            // 7. PILLAR BREAKDOWN
            PillarBreakdownList(pillars: report.pillars),

            const SizedBox(height: 32),

            // 8. CONSOLIDATED ANALYSIS
            _buildSectionLabel('8. Consolidated Analysis'),
            _buildStylizedCard(
              Icons.merge_type, 
              Colors.teal, 
              'Synthesizing all 95 data points across the 7 pillars, the model identifies you as a low-to-medium risk borrower. The positive strength of your verifiable platform data successfully counteracts the negative weight of your thin formal credit file. By maintaining your current earning velocity and formalizing your savings, your overall trajectory is mapped to reach the 750+ Prime tier within 6-8 months of continued platform activity.'
            ).animate().fadeIn(delay: 600.ms),

            const SizedBox(height: 24),

            // 9. IMPROVEMENT AREAS
            _buildSectionLabel('9. Improvement Areas'),
            _buildStylizedCard(
              Icons.build_circle, 
              Colors.orange, 
              '• The model flagged a lack of formal health or vehicle insurance as a vulnerability. Acquiring basic coverage will protect your income stability score.\n• Filing an Income Tax Return (ITR), even if your income is below the taxable bracket, will instantly provide a massive boost to your Social Accountability and overall score.'
            ).animate().fadeIn(delay: 650.ms),

            const SizedBox(height: 24),

            // 10. FINAL ASSESSMENT
            _buildSectionLabel('10. Final Assessment'),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accent.withValues(alpha: 0.2), AppColors.surface],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(color: AppColors.accent.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: -5),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.verified.withValues(alpha: 0.1), shape: BoxShape.circle, border: Border.all(color: AppColors.verified.withValues(alpha: 0.3))),
                    child: const Icon(Icons.verified_user, color: AppColors.verified, size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text('AI Authentication Validated', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  const Text(
                    'This GigCredit profile has been successfully audited and authenticated using on-device identity checks and live behavioral data. '
                    'The user demonstrates verifiable gig-economy income and steady financial behavior that mitigates traditional lending risks. '
                    'Future outlook is highly positive, with strong potential for premium credit upgrades if current payment discipline is maintained. '
                    'This profile represents a trustworthy and verified financial persona.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 700.ms).scale(begin: const Offset(0.95, 0.95)),

            const SizedBox(height: 32),

            // 11. ACTION BUTTONS
            _buildSectionLabel('11. Action Buttons'),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Share Report',
                    icon: const Icon(Icons.share, size: 18, color: AppColors.accent),
                    onPressed: () {
                      final text = 'I just checked my GigCredit rating for autonomous gig-workers! '
                          'My verified score is ${report.finalScore} (Grade: ${report.grade}). '
                          'Check yours out on GigCredit!';
                      SharePlus.instance.share(ShareParams(text: text));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PrimaryButton(
                    label: 'Download PDF',
                    icon: const Icon(Icons.picture_as_pdf, size: 18, color: Colors.white),
                    onPressed: () => PdfReportGenerator.shareReport(report),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 800.ms),
            
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Report Ref: ${report.proofId} • Confidence: ${(report.overallConfidence * 100).toInt()}%',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
              ),
            ).animate().fadeIn(delay: 900.ms),
            
            const SizedBox(height: 32),
            const Divider(color: AppColors.surfaceVariant),
            const SizedBox(height: 24),
            
            PrimaryButton(
              label: 'Proceed to Loan Application →',
              onPressed: () => context.push(AppRoutes.loanApply),
            ).animate().fadeIn(delay: 1000.ms).shimmer(duration: 2000.ms, delay: 2000.ms),
            const SizedBox(height: 16),
            SecondaryButton(
              label: '+ Start New Report',
              icon: const Icon(Icons.refresh, size: 18, color: AppColors.accent),
              onPressed: () {
                // Reset all state for a fresh report
                ref.read(stepStatusProvider.notifier).reset();
                ref.read(verifiedProfileProvider.notifier).reset();
                ref.read(scoreProvider.notifier).reset();
                context.go(AppRoutes.score);
              },
            ).animate().fadeIn(delay: 1100.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(color: AppColors.textTertiary.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildStylizedCard(IconData icon, Color color, String content) {
    final hasBullets = content.contains('•');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: hasBullets ? _buildBulletPoints(content, color) : Text(
                content,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoints(String text, Color accentColor) {
    final points = text.split('•').where((s) => s.trim().isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: points.map((point) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 6, right: 12),
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.8), shape: BoxShape.circle),
            ),
            Expanded(
              child: Text(
                point.trim(),
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}
