import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../state/score_provider.dart';

class ReportHistoryScreen extends ConsumerWidget {
  const ReportHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreState = ref.watch(scoreProvider);
    final report = scoreState.reportData;

    return Scaffold(
      appBar: AppBar(title: const Text('Report History')),
      body: report == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 80, color: AppColors.textTertiary),
                  const SizedBox(height: 16),
                  Text('No Reports Yet', style: AppTypography.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Complete the 9-step verification to\ngenerate your first credit report.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text('Latest Report', style: AppTypography.titleMedium),
                const SizedBox(height: 16),
                _ReportHistoryCard(
                  score: report.finalScore,
                  grade: report.grade,
                  proofId: report.proofId,
                  date: report.generatedAt,
                  isLatest: true,
                ),
                const SizedBox(height: 32),
                Text('Previous Reports', style: AppTypography.titleMedium),
                const SizedBox(height: 16),
                // Simulated previous reports for demo
                _ReportHistoryCard(
                  score: (report.finalScore * 0.92).round(),
                  grade: report.finalScore * 0.92 >= 720 ? 'A' : 'B',
                  proofId: 'GC-${report.generatedAt.millisecondsSinceEpoch - 2592000000}',
                  date: report.generatedAt.subtract(const Duration(days: 30)),
                  isLatest: false,
                ),
                const SizedBox(height: 12),
                _ReportHistoryCard(
                  score: (report.finalScore * 0.85).round(),
                  grade: report.finalScore * 0.85 >= 640 ? 'B' : 'C',
                  proofId: 'GC-${report.generatedAt.millisecondsSinceEpoch - 5184000000}',
                  date: report.generatedAt.subtract(const Duration(days: 60)),
                  isLatest: false,
                ),
              ],
            ),
    );
  }
}

class _ReportHistoryCard extends StatelessWidget {
  final int score;
  final String grade;
  final String proofId;
  final DateTime date;
  final bool isLatest;

  const _ReportHistoryCard({
    required this.score,
    required this.grade,
    required this.proofId,
    required this.date,
    required this.isLatest,
  });

  @override
  Widget build(BuildContext context) {
    final gradeColor = grade == 'S' || grade == 'A'
        ? AppColors.gradeA
        : grade == 'B'
            ? AppColors.gradeB
            : AppColors.warning;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: gradeColor.withValues(alpha: 0.15),
              border: Border.all(color: gradeColor, width: 2),
            ),
            child: Center(
              child: Text(
                '$score',
                style: AppTypography.titleMedium.copyWith(color: gradeColor),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Grade $grade', style: AppTypography.titleMedium),
                    if (isLatest) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('LATEST', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Proof: $proofId',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                ),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}
