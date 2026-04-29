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

// New XAI Widgets
import '../widgets/report_header.dart';
import '../widgets/score_gauge_widget.dart';
import '../widgets/pillar_waterfall_chart.dart';
import '../widgets/pillar_radar_chart.dart';
import '../widgets/shap_strength_card.dart';
import '../widgets/shap_concern_card.dart';
import '../widgets/pillar_detail_card.dart';
import '../widgets/causal_insight_card.dart';
import '../widgets/action_improvement_card.dart';
import '../widgets/trajectory_widget.dart';
import '../../../models/actionable_item.dart';

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

    // Filter SHAP factors
    final positiveShap = report.positiveFactors.take(3).toList();
    final negativeShap = report.negativeFactors
        .where((f) => f.actionType == 'immediate' || f.actionType == 'behavioural')
        .take(3)
        .toList();

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
            ReportHeader(generatedAt: report.generatedAt).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
            const SizedBox(height: 24),
            
            // 2. SCORE GAUGE
            ScoreGaugeWidget(
              finalScore: report.finalScore,
              grade: report.grade,
              riskBand: report.riskBand,
            ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),
            const SizedBox(height: 24),

            // 3. SCORE SUMMARY (LLM Output)
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
            const SizedBox(height: 32),

            // 4. WATERFALL CHART (L1)
            PillarWaterfallChart(
              contributions: report.pillarContributions ?? {},
              finalScore: report.finalScore,
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
            const SizedBox(height: 32),

            // 5. RADAR CHART
            PillarRadarChart(pillars: report.pillars).animate().fadeIn(delay: 450.ms).scale(),
            const SizedBox(height: 32),

            // 6. POSITIVE SHAP FACTORS (L2)
            if (positiveShap.isNotEmpty) ...[
              _buildSectionTitle('Top Strengths', Icons.trending_up, Colors.green),
              const SizedBox(height: 12),
              ...positiveShap.map((f) => ShapStrengthCard(factor: f).animate().fadeIn(delay: 500.ms)),
              const SizedBox(height: 24),
            ],

            // 7. NEGATIVE SHAP FACTORS (L2/L3)
            if (negativeShap.isNotEmpty) ...[
              _buildSectionTitle('Areas for Improvement', Icons.warning_amber_rounded, Colors.orange),
              const SizedBox(height: 12),
              ...negativeShap.map((f) => ShapConcernCard(factor: f).animate().fadeIn(delay: 550.ms)),
              const SizedBox(height: 24),
            ],

            // 8. CAUSAL INSIGHTS (L8)
            if (report.causalChains != null && report.causalChains!.isNotEmpty) ...[
              _buildSectionTitle('Causal Insights', Icons.link, Colors.blue),
              const SizedBox(height: 12),
              ...report.causalChains!.map((c) => CausalInsightCard(chain: c).animate().fadeIn(delay: 600.ms)),
              const SizedBox(height: 24),
            ],

            // 9. ACTIONABLE IMPROVEMENTS (L3)
            if (report.actionableItems != null && report.actionableItems!.isNotEmpty) ...[
              _buildSectionTitle('Actionable Path to Prime', Icons.build_circle, Colors.amber),
              const SizedBox(height: 12),
              ...report.actionableItems!.map((item) {
                // Ensure valid enum parsing or fallback
                final tier = item.tier; 
                if (tier == ActionabilityTier.nonActionable) return const SizedBox.shrink();
                return ActionImprovementCard(item: item).animate().fadeIn(delay: 650.ms);
              }),
              const SizedBox(height: 24),
            ],

            // 10. TRAJECTORY (L4)
            if (report.trajectory != null) ...[
              TrajectoryWidget(trajectory: report.trajectory!).animate().fadeIn(delay: 700.ms),
              const SizedBox(height: 32),
            ],

            // 11. PILLAR DETAILS EXPANDABLE
            _buildSectionTitle('Detailed Pillar Breakdown', Icons.bar_chart, AppColors.accent),
            const SizedBox(height: 12),
            ...report.pillars.map((p) => PillarDetailCard(pillar: p).animate().fadeIn(delay: 750.ms)),
            const SizedBox(height: 32),

            // 12. ACTION BUTTONS
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Share',
                    icon: const Icon(Icons.share, size: 18, color: AppColors.accent),
                    onPressed: () {
                      final text = 'I just checked my GigCredit rating! My verified score is ${report.finalScore} (Grade: ${report.grade}).';
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
                'Report Ref: ${report.proofId} • Compute Time: ${report.computeTimeMs}ms',
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

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
