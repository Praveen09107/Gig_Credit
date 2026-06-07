import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../state/score_provider.dart';
import '../../../state/loan_provider.dart';
import '../../../models/score_report_model.dart';
import '../../../services/scoring_service.dart';
import '../../../state/user_provider.dart';
import '../../../state/auth_provider.dart';
import '../../../app/app_router.dart';
import '../../../models/loan_offer_model.dart';
import '../../../services/loan_api_service.dart';
import '../../report/pdf_report_generator.dart';
import '../../../shared/widgets/feedback/app_toast.dart';

class ReportHistoryScreen extends ConsumerStatefulWidget {
  const ReportHistoryScreen({super.key});

  @override
  ConsumerState<ReportHistoryScreen> createState() =>
      _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends ConsumerState<ReportHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _history = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final authState = ref.read(authProvider);
    final userId = authState.userId ?? ref.read(userProvider)?.id;

    if (userId != null && userId.isNotEmpty) {
      try {
        final data = await ScoringService().getScoreHistory(userId);
        if (mounted) {
          setState(() {
            _history = data;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Could not fetch history. Check your connection.';
          });
        }
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteReport(String proofId) async {
    final authState = ref.read(authProvider);
    final userId = authState.userId ?? ref.read(userProvider)?.id;
    if (userId == null) return;

    try {
      await ScoringService().deleteScoreReport(userId, proofId);
      setState(() {
        _history.removeWhere((item) => item['proofId'] == proofId);
      });
      if (mounted) AppToast.success(context, 'Report deleted');
    } catch (e) {
      if (mounted) AppToast.error(context, 'Delete failed', subtitle: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _confirmAndDelete(String proofId, String dateStr) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 22),
          const SizedBox(width: 8),
          const Text('Delete Report', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ]),
        content: Text(
          'This will permanently delete the report from $dateStr.\n\nThis action cannot be undone.',
          style: const TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm == true) await _deleteReport(proofId);
  }

  Future<void> _viewReport(Map<String, dynamic> reportJson) async {
    try {
      // Remove MongoDB-specific fields that break deserialization
      final cleanJson = Map<String, dynamic>.from(reportJson);
      cleanJson.remove('_id');
      cleanJson.remove('user_id');
      cleanJson.remove('stored_at');

      // Recompute grade from score — stored grade may be wrong (test data)
      final rawScore = cleanJson['finalScore'] as int? ?? 0;
      cleanJson['finalScore'] = rawScore.clamp(300, 900);

      final report = ScoreReportModel.fromJson(cleanJson);

      // Load into score provider so ScoreReportScreen can read it
      ref.read(scoreProvider.notifier).setSuccess(report);

      // Fetch matching loan offers for this past score so the loan screen is accurate
      try {
        final loanApi = ref.read(loanApiServiceProvider);
        final result = await loanApi.getProducts(report.finalScore);
        final products = result['eligible_products'] as List? ?? [];

        final offers = <LoanOfferModel>[];
        for (final p in products) {
          offers.add(LoanOfferModel(
            id: p['id'] ?? 'offer_${offers.length}',
            lenderName: p['name'] ?? 'GigCredit Partner',
            lenderLogoUrl: '',
            amount: (p['max_amount'] as num?)?.toDouble() ?? 0,
            interestRate: 18.0,
            tenureMonths: (p['tenures'] as List?)?.isNotEmpty == true
                ? (p['tenures'] as List).first as int
                : 6,
            estimatedEmi: 0,
            highlights: [p['description'] ?? 'Pre-approved'],
          ));
        }
        ref.read(loanProvider.notifier).setOffers(offers);
      } catch (e) {
        debugPrint('[History] Failed to seed historical loans: $e');
      }

      if (mounted) {
        // Navigate to the full report screen
        context.push(AppRoutes.scoreReport);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to load this report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoutes.home);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5FFF8), // Mint theme background
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 140,
              backgroundColor: const Color(0xFF00522F),
              elevation: 4,
              shadowColor: Colors.black45,
              iconTheme: const IconThemeData(color: Colors.white),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => context.go(AppRoutes.home),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: Colors.white, size: 22),
                  onPressed: () {
                    setState(() => _isLoading = true);
                    _fetchHistory();
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding:
                    const EdgeInsets.only(left: 20, bottom: 16, right: 20),
                title: const Text('Score History',
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 20)),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00522F), Color(0xFF008A43)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Icon(Icons.history_rounded,
                            size: 120, color: Colors.white.withOpacity(0.1)),
                      )
                    ],
                  ),
                ),
              ),
            ),
            if (_isLoading)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                          color: AppColors.greenPrimary),
                      const SizedBox(height: 16),
                      const Text('Loading your reports from server...',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 13)),
                    ],
                  ),
                ),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off_rounded,
                          size: 64, color: AppColors.textMuted),
                      const SizedBox(height: 16),
                      Text(_errorMessage!,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 14)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _errorMessage = null;
                          });
                          _fetchHistory();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.greenPrimary),
                        child: const Text('Retry',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              )
            else if (_history.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history_rounded,
                          size: 80, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      const Text('No Reports Yet',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      const Text(
                          'Complete the verification to\ngenerate your first credit report.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 15,
                              height: 1.5)),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () => context.go(AppRoutes.score),
                        icon:
                            const Icon(Icons.add_rounded, color: Colors.white),
                        label: const Text('Generate Score',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.greenPrimary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.greenPrimary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                    '${_history.length} Report${_history.length > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                        color: AppColors.greenPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ),
                              const Spacer(),
                              const Text('Tap any report to view full details',
                                  style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11)),
                            ],
                          ),
                        ).animate().fadeIn();
                      }

                      final item = _history[index - 1];
                      final rawScore = item['finalScore'] as int? ?? 0;
                      final score = rawScore.clamp(300, 900);
                      final grade = ScoreReportModel.computeGrade(score);
                      final riskBand = item['riskBand'] as String? ?? 'Medium';
                      final proofId = item['proofId'] as String? ?? 'N/A';
                      final workType = item['workType'] as String? ?? 'unknown';
                      final llm = item['llmExplanation'] as String?;
                      final dateStr = item['generatedAt'] as String? ??
                          item['stored_at'] as String?;
                      DateTime date = DateTime.now();
                      if (dateStr != null) {
                        try {
                          date = DateTime.parse(dateStr);
                        } catch (_) {}
                      }
                      final isLatest = index == 1;

                      return _HistoryReportCard(
                        score: score,
                        grade: grade,
                        riskBand: riskBand,
                        proofId: proofId,
                        workType: workType,
                        hasLlm: llm != null && llm.isNotEmpty,
                        date: date,
                        isLatest: isLatest,
                        onTap: () => _viewReport(item),
                        onDownload: () async {
                          try {
                            AppToast.info(context, 'Generating PDF...', subtitle: 'Please wait');
                            final cleanJson = Map<String, dynamic>.from(item);
                            cleanJson.remove('_id');
                            cleanJson.remove('stored_at');
                            final report = ScoreReportModel.fromJson(cleanJson);
                            final userName = ref.read(userProvider)?.name ?? 'Applicant';
                            await PdfReportGenerator.shareReport(report, applicantName: userName);
                          } catch (e) {
                            if (context.mounted) {
                              AppToast.error(context, 'PDF failed', subtitle: e.toString().replaceFirst('Exception: ', ''));
                            }
                          }
                        },
                        onDelete: () => _confirmAndDelete(
                          proofId,
                          DateFormat('dd MMM yyyy').format(date),
                        ),
                      )
                          .animate(delay: Duration(milliseconds: index * 80))
                          .fadeIn()
                          .slideY(begin: 0.05);
                    },
                    childCount: _history.length + 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryReportCard extends StatelessWidget {
  final int score;
  final String grade;
  final String riskBand;
  final String proofId;
  final String workType;
  final bool hasLlm;
  final DateTime date;
  final bool isLatest;
  final VoidCallback onTap;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;

  const _HistoryReportCard({
    required this.score,
    required this.grade,
    required this.riskBand,
    required this.proofId,
    required this.workType,
    required this.hasLlm,
    required this.date,
    required this.isLatest,
    required this.onTap,
    this.onDownload,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final gradeColor = (grade == 'A+' || grade == 'A' || grade == 'S')
        ? const Color(0xFF3DD68C)
        : (grade == 'B+' || grade == 'B')
            ? const Color(0xFFF4B942)
            : const Color(0xFFFF4E6A);

    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.greenPrimary.withValues(alpha: 0.1),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLatest
                    ? AppColors.greenPrimary.withValues(alpha: 0.4)
                    : AppColors.borderCard,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Score circle + Grade + Badges
                Row(
                  children: [
                    // Score circle
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: gradeColor.withValues(alpha: 0.15),
                        border: Border.all(color: gradeColor, width: 2.5),
                      ),
                      child: Center(
                        child: Text(
                          '$score',
                          style: TextStyle(
                            color: gradeColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Grade + Risk + Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Grade $grade',
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              if (isLatest)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.greenPrimary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text('LATEST',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Risk: $riskBand  ·  $workType',
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(formattedDate,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                    // Chevron
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textMuted, size: 24),
                  ],
                ),

                const SizedBox(height: 12),
                // Bottom info strip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.bgScreen,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderCard),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.fingerprint_rounded,
                          color: AppColors.textMuted, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('Proof: $proofId',
                            style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                                fontFamily: 'monospace'),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (hasLlm) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF3DD68C).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('LLM ✓',
                              style: TextStyle(
                                  color: Color(0xFF3DD68C),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                ),
                // Download PDF button
                if (onDownload != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onDownload,
                      icon: const Icon(Icons.download_rounded, size: 14),
                      label: const Text('Download PDF Report',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.greenPrimary,
                        side: BorderSide(color: AppColors.greenPrimary.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
                // Delete button
                if (onDelete != null) ...[
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: Icon(Icons.delete_outline_rounded, size: 14, color: Colors.red.shade400),
                      label: Text('Delete Report',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.red.shade400)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade200),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
