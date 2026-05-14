import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../state/score_provider.dart';
import '../../../state/loan_provider.dart';
import '../../../models/score_report_model.dart';
import '../../../services/scoring_service.dart';
import '../../../state/user_provider.dart';
import '../../../app/app_router.dart';
import '../../../state/loan_applications_provider.dart';
import '../../../models/loan_offer_model.dart';
import '../../../services/loan_api_service.dart';

class ReportHistoryScreen extends ConsumerStatefulWidget {
  const ReportHistoryScreen({super.key});

  @override
  ConsumerState<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
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
    final user = ref.read(userProvider);
    if (user?.id.isNotEmpty == true) {
      try {
        final data = await ScoringService().getScoreHistory(user!.id);
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

  Future<void> _viewReport(Map<String, dynamic> reportJson) async {
    try {
      // Remove MongoDB-specific fields that break deserialization
      final cleanJson = Map<String, dynamic>.from(reportJson);
      cleanJson.remove('_id');
      cleanJson.remove('user_id');
      cleanJson.remove('stored_at');

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
            tenureMonths: (p['tenures'] as List?)?.isNotEmpty == true ? (p['tenures'] as List).first as int : 6,
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
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B25),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Score History',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00D4B4), size: 22),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchHistory();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF00D4B4)),
                  SizedBox(height: 16),
                  Text('Loading your reports from server...',
                      style: TextStyle(color: Color(0xFF8B95A8), fontSize: 13)),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 64, color: Color(0xFF8B95A8)),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, style: const TextStyle(color: Color(0xFF8B95A8), fontSize: 14)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() { _isLoading = true; _errorMessage = null; });
                          _fetchHistory();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D4B4)),
                        child: const Text('Retry', style: TextStyle(color: Color(0xFF0D0F14))),
                      ),
                    ],
                  ),
                )
              : _history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.history_rounded, size: 80, color: Color(0xFF4A5568)),
                          const SizedBox(height: 16),
                          const Text('No Reports Yet',
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text(
                            'Complete the verification to\ngenerate your first credit report.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF8B95A8), fontSize: 14),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => context.go(AppRoutes.score),
                            icon: const Icon(Icons.add_rounded, color: Color(0xFF0D0F14)),
                            label: const Text('Generate First Score',
                                style: TextStyle(color: Color(0xFF0D0F14), fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00D4B4),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchHistory,
                      color: const Color(0xFF00D4B4),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _history.length + 1, // +1 for header
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00D4B4).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('${_history.length} Report${_history.length > 1 ? 's' : ''}',
                                        style: const TextStyle(
                                            color: Color(0xFF00D4B4),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  const Spacer(),
                                  const Text('Tap any report to view full details',
                                      style: TextStyle(color: Color(0xFF8B95A8), fontSize: 11)),
                                ],
                              ),
                            ).animate().fadeIn();
                          }

                          final item = _history[index - 1];
                          final score = item['finalScore'] as int? ?? 0;
                          final grade = item['grade'] as String? ?? 'B';
                          final riskBand = item['riskBand'] as String? ?? 'Medium';
                          final proofId = item['proofId'] as String? ?? 'N/A';
                          final workType = item['workType'] as String? ?? 'unknown';
                          final llm = item['llmExplanation'] as String?;
                          final dateStr = item['generatedAt'] as String? ?? item['stored_at'] as String?;
                          DateTime date = DateTime.now();
                          if (dateStr != null) {
                            try { date = DateTime.parse(dateStr); } catch (_) {}
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
                          ).animate(delay: Duration(milliseconds: index * 80)).fadeIn().slideY(begin: 0.05);
                        },
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
  });

  @override
  Widget build(BuildContext context) {
    final gradeColor = (grade == 'S' || grade == 'A')
        ? const Color(0xFF3DD68C)
        : grade == 'B'
            ? const Color(0xFFF4B942)
            : const Color(0xFFFF4E6A);

    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFF161B25),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: const Color(0xFF00D4B4).withValues(alpha: 0.1),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLatest ? const Color(0xFF00D4B4).withValues(alpha: 0.4) : const Color(0xFF252D3D),
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
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              if (isLatest)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00D4B4),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text('LATEST',
                                      style: TextStyle(
                                          color: Color(0xFF0D0F14),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Risk: $riskBand  ·  $workType',
                              style: const TextStyle(color: Color(0xFF8B95A8), fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(formattedDate,
                              style: const TextStyle(color: Color(0xFF4A5568), fontSize: 11)),
                        ],
                      ),
                    ),
                    // Chevron
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF8B95A8), size: 24),
                  ],
                ),

                const SizedBox(height: 12),
                // Bottom info strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0F14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF252D3D)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.fingerprint_rounded, color: Color(0xFF8B95A8), size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('Proof: $proofId',
                            style: const TextStyle(
                                color: Color(0xFF8B95A8),
                                fontSize: 10,
                                fontFamily: 'monospace'),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (hasLlm) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3DD68C).withValues(alpha: 0.15),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
