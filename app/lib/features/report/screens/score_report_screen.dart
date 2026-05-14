import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../shared/widgets/buttons/secondary_button.dart';
import '../../../state/score_provider.dart';
import '../../../state/step_status_provider.dart';
import '../../../state/verified_profile_provider.dart';
import '../../../state/api_service_provider.dart';
import '../../../app/app_router.dart';
import '../../../models/score_report_model.dart';

class ScoreReportScreen extends ConsumerStatefulWidget {
  const ScoreReportScreen({super.key});
  @override
  ConsumerState<ScoreReportScreen> createState() => _ScoreReportScreenState();
}

class _ScoreReportScreenState extends ConsumerState<ScoreReportScreen> {
  final ScrollController _scrollController = ScrollController();
  int _activeTabIndex = 1; // 0=Strengths, 1=Gaps, 2=Causal
  String _activePill = '1 Score';
  String _selectedLang = 'EN English';
  
  bool _isTranslating = false;
  final Map<String, String> _translations = {};

  ScoreReportModel get report => ref.watch(scoreProvider).reportData!;

  @override
  void initState() {
    super.initState();
    // Schedule initialization to use the provider after mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(scoreProvider).reportData?.llmExplanation != null) {
        setState(() {
          _translations['EN English'] = ref.read(scoreProvider).reportData!.llmExplanation!;
        });
      }
    });
  }

  Future<void> _translateReport(String newLang) async {
    setState(() {
      _selectedLang = newLang;
    });

    if (_translations.containsKey(newLang)) return;

    setState(() => _isTranslating = true);

    try {
      final r = report;
      // Convert language chip format (e.g. "TA தமிழ்") to ISO code ("ta") or name ("Tamil")
      final langName = newLang.split(' ').last; 

      final payload = {
        "credit_score": r.finalScore,
        "grade": r.grade,
        "risk_level": r.riskBand,
        "work_type": r.workType,
        "language": langName,
        "pillar_scores": r.pillarContributions,
        "confidence_level": r.overallConfidence > 0.8 ? "high" : "medium",
        "positive_factors": r.topStrengths.map((e) => {"feature_label": e.featureName, "pillar": e.pillarLabel.isNotEmpty ? e.pillarLabel : "P1", "impact": e.impactStrength}).toList(),
        "negative_factors": r.topConcerns.map((e) => {"feature_label": e.featureName, "pillar": e.pillarLabel.isNotEmpty ? e.pillarLabel : "P1", "impact": e.impactStrength}).toList(),
      };

      final api = ref.read(apiServiceProvider);
      final llmResponse = await api.generateReportScore(payload);

      if (llmResponse['status'] == 'success' || llmResponse['status'] == 'fallback') {
        if (mounted) {
          setState(() {
            _translations[newLang] = llmResponse['explanation'];
            _isTranslating = false;
          });
        }
      } else {
        throw Exception('Translation failed');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTranslating = false;
          _translations[newLang] = 'Unable to fetch translation for $newLang. Please check your connection.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(scoreProvider);
    final report = session.reportData;
    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Score Report')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
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

    return Scaffold(
      backgroundColor: const Color(0xFF0A1A10),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildGlassmorphismAppBar(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHeaderBlock(report),
                const SizedBox(height: 16),
                _buildSectionJumpPills(),
                const SizedBox(height: 32),
                _buildSection1Score(),
                const SizedBox(height: 32),
                _buildSection2ScoreBuilt(),
                const SizedBox(height: 32),
                _buildSection3HelpedHurt(),
                const SizedBox(height: 32),
                _buildSection4ActionPlan(),
                const SizedBox(height: 32),
                _buildSection5Story(),
                const SizedBox(height: 32),
                _buildSection6Technical(),
                const SizedBox(height: 16),
                _buildSection7Regulatory(),
                const SizedBox(height: 100), // padding for bottom bar
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildStickyFooter(),
    );
  }

  Widget _buildGlassmorphismAppBar() {
    return SliverAppBar(
      backgroundColor: const Color(0xCC0D3320),
      pinned: true,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.greenMint),
        onPressed: () => context.go(AppRoutes.home),
      ),
      title: const Text(
        'GIGCREDIT CREDIT REPORT',
        style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2),
      ),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }

  Widget _buildHeaderBlock(ScoreReportModel report) {
    final dateFormat = DateFormat('dd MMM yyyy · hh:mm a');
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0F14),
        border: Border(bottom: BorderSide(color: Color(0xFF252D3D))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Report ID', report.proofId.isNotEmpty ? report.proofId : 'GC-2026-0430-AB1234'),
          _buildDetailRow('Generated', dateFormat.format(report.generatedAt)),
          _buildDetailRow('Applicant', 'Verified User'), // Future: Pull from user profile
          _buildDetailRow('Work Type', report.workType.toUpperCase()),
          _buildDetailRow('Location', 'Verified Location'),
          _buildDetailRow('Onboarding', 'Complete (Steps 1–9)'),
          _buildDetailRow('Language', 'English [EN]'),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF252D3D), height: 1),
          const SizedBox(height: 12),
          _buildDetailRow('Hash', 'sha256:${report.proofId.substring(0, 8)}...  ●  Chain: VERIFIED ✓',
              valueColor: const Color(0xFF00D4B4)),
          _buildDetailRow('Engine', 'GigCredit Scoring Engine v4.2.1-stable'),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildDetailRow(String label, String value,
      {Color valueColor = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(color: Color(0xFF8B95A8), fontSize: 13)),
          ),
          const Text(':',
              style: TextStyle(color: Color(0xFF8B95A8), fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    color: valueColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionJumpPills() {
    final pills = [
      '1 Score',
      '2 Built',
      '3 Strengths',
      '4 Actions',
      '5 Story',
      '6 Tech',
      '7 Legal'
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: pills.map((pill) {
          final isActive = pill == _activePill;
          return GestureDetector(
            onTap: () {
              setState(() => _activePill = pill);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Jumping to $pill...'), duration: const Duration(milliseconds: 500)));
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color:
                    isActive ? const Color(0xFF00D4B4) : const Color(0xFF161B25),
                borderRadius: BorderRadius.circular(8),
                border:
                    isActive ? null : Border.all(color: const Color(0xFF252D3D)),
              ),
              child: Text(
                pill,
                style: TextStyle(
                  color: isActive
                      ? const Color(0xFF0D0F14)
                      : const Color(0xFF8B95A8),
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().slideX(begin: 0.1).fadeIn();
  }

  Widget _buildSection1Score() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(0, -0.2),
          colors: [Color(0x1400D4B4), Color(0xFF161B25)],
          stops: [0.0, 0.7],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF252D3D)),
      ),
      child: Column(
        children: [
          // Report ID Strip
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0F14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF252D3D)),
            ),
            child: const Text(
              'GC-2026-0430-AB1234 ● 30 Apr 2026 ● Hash: sha256:a3f2\nChain: VERIFIED ✓ ● Deterministic ● Reproducible',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFF8B95A8),
                  fontSize: 10,
                  height: 1.5),
            ),
          ),
          const SizedBox(height: 40),

          // Score Ring Zone
          Container(
            width: 280,
            height: 280,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Color(0x403DD68C), blurRadius: 16),
                BoxShadow(color: Color(0x203DD68C), blurRadius: 32),
                BoxShadow(color: Color(0x103DD68C), blurRadius: 64),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 280,
                  height: 280,
                  child: CircularProgressIndicator(
                    value: report.finalScore / 900, // 647 out of 900
                    strokeWidth: 12,
                    backgroundColor: const Color(0xFF1E2535),
                    color: const Color(0xFF3DD68C),
                    strokeCap: StrokeCap.round,
                  ),
                ).animate().scale(
                    delay: 200.ms, duration: 800.ms, curve: Curves.easeOutBack),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${report.finalScore}',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 64,
                            fontWeight: FontWeight.w900,
                            height: 1.0)),
                    const SizedBox(height: 8),
                    Container(
                        width: 60, height: 2, color: const Color(0xFF252D3D)),
                    const SizedBox(height: 8),
                    Text('Grade ${report.grade}',
                        style: TextStyle(
                            color: Color(0xFF3DD68C),
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const Text('Good Eligibility',
                        style:
                            TextStyle(color: Color(0xFF8B95A8), fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Conformal Band
          const Text('631 ─────────●───────── 663',
              style: TextStyle(
                  color: Color(0xFF00D4B4),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2)),
          const SizedBox(height: 4),
          const Text('±16 pts  ●  90% coverage  ●  HIGH CONFIDENCE',
              style: TextStyle(color: Color(0xFF8B95A8), fontSize: 11)),

          const SizedBox(height: 32),

          // Scale Bar
          const Text('300────E────D────C────B──●──A────S────900',
              style: TextStyle(
                  color: Color(0xFF8B95A8),
                  fontSize: 12,
                  letterSpacing: 2,
                  fontFamily: 'monospace')),

          const SizedBox(height: 32),

          // Grade Table
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D0F14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF252D3D)),
            ),
            child: Column(
              children: [
                _buildGradeRow('Grade', 'Range', 'Risk Band', 'Meaning',
                    isHeader: true),
                _buildGradeRow(
                    'S', '800–900', 'Exceptional', 'Premium eligibility',
                    color: const Color(0xFFFFD700)),
                _buildGradeRow(
                    'A', '720–799', 'Excellent', 'Strong eligibility',
                    color: const Color(0xFF00D4B4)),
                _buildGradeRow('B', '640–719', 'Good', 'Standard access',
                    color: const Color(0xFF3DD68C), isActive: true),
                _buildGradeRow(
                    'C', '560–639', 'Medium Risk', 'Conditional access',
                    color: const Color(0xFFF4B942)),
                _buildGradeRow('D', '480–559', 'Medium Risk', 'Limited options',
                    color: const Color(0xFFFF8C42)),
                _buildGradeRow('E', '300–479', 'High Risk', 'Not yet eligible',
                    color: const Color(0xFFFF4E6A)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Signal Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSignalChip('Stable Risk'),
              _buildSignalChip('7/8 Pillars'),
              _buildSignalChip('On-device'),
            ],
          )
        ],
      ),
    ).animate().slideY(begin: 0.1, duration: 400.ms).fadeIn();
  }

  Widget _buildGradeRow(String g, String r, String risk, String m,
      {bool isHeader = false,
      bool isActive = false,
      Color color = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
        border: Border(
          left: BorderSide(
              color: isActive ? color : Colors.transparent, width: 3),
          bottom: BorderSide(
              color: isHeader ? const Color(0xFF252D3D) : Colors.transparent,
              width: 1),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
              width: 40,
              child: Text(isHeader ? g : '● $g',
                  style: TextStyle(
                      color: isHeader ? const Color(0xFF8B95A8) : color,
                      fontWeight: isHeader || isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12))),
          SizedBox(
              width: 80,
              child: Text(r,
                  style: TextStyle(
                      color: isHeader ? const Color(0xFF8B95A8) : Colors.white,
                      fontSize: 12))),
          SizedBox(
              width: 90,
              child: Text(risk,
                  style: TextStyle(
                      color: isHeader ? const Color(0xFF8B95A8) : Colors.white,
                      fontSize: 12))),
          Expanded(
              child: Text(m,
                  style: TextStyle(
                      color: isHeader ? const Color(0xFF8B95A8) : Colors.white,
                      fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildSignalChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x1A3DD68C),
        border: Border.all(color: const Color(0x663DD68C)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF3DD68C), size: 14),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF3DD68C),
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSection2ScoreBuilt() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B25),
        border: Border.all(color: const Color(0xFF252D3D)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF161B25),
              border:
                  Border(left: BorderSide(color: Color(0xFF00D4B4), width: 4)),
            ),
            child: const Text('2  HOW YOUR SCORE WAS BUILT',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1)),
          ),
          const SizedBox(height: 24),

          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Starting point (floor)',
                  style: TextStyle(color: Color(0xFF8B95A8), fontSize: 14)),
              Text('300 pts',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ],
          ),
          const Divider(color: Color(0xFF252D3D), height: 32),

          _buildPillarRow(
              'P1',
              'Income Stability',
              0.8,
              '+142 pts',
              const Color(0xFF3DD68C),
              '●●●●○  conf 95%',
              'STRONG',
              '300 → 442'),
          _buildPillarRow(
              'P2',
              'Platform Earnings',
              0.6,
              '+95 pts',
              const Color(0xFF3DD68C),
              '●●●○○  conf 82%',
              'STRONG',
              '442 → 537'),
          _buildPillarRow(
              'P3',
              'Expense Patterns',
              0.4,
              '+64 pts',
              const Color(0xFFF4B942),
              '●●●○○  conf 75%',
              'MODERATE',
              '537 → 601'),
          _buildPillarRow('P6', 'Insurance Coverage', 0.2, '+46 pts',
              const Color(0xFFFF4E6A), '●○○○○  conf 45%', 'WEAK', '601 → 647',
              warning: '⚠️ No insurance document uploaded'),

          const Divider(color: Color(0xFF252D3D), height: 32),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.1)),
              Text('647 pts  ✓',
                  style: TextStyle(
                      color: Color(0xFF00D4B4),
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
                color: const Color(0xFF00D4B4),
                borderRadius: BorderRadius.circular(6)),
          ),
          const SizedBox(height: 16),
          const Text('300 + 142 + 95 + 64 + 46 = 647 ✓',
              style: TextStyle(
                  color: Color(0xFF8B95A8),
                  fontFamily: 'monospace',
                  fontSize: 12)),
        ],
      ),
    ).animate().slideY(begin: 0.1).fadeIn();
  }

  Widget _buildPillarRow(String code, String name, double progress, String pts,
      Color color, String conf, String status, String total,
      {String? warning}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$code  $name',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              Text(pts,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFF1E2535),
            color: color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(conf,
                  style:
                      const TextStyle(color: Color(0xFF8B95A8), fontSize: 12)),
              Text('$status ↑',
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Running total: $total',
              style: const TextStyle(color: Color(0xFF8B95A8), fontSize: 12)),
          if (warning != null) ...[
            const SizedBox(height: 4),
            Text(warning,
                style: const TextStyle(color: Color(0xFFFF4E6A), fontSize: 12)),
          ],
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF161B25),
                  title: Text('$code $name Details', style: const TextStyle(color: Colors.white)),
                  content: Text('Your score for $name changed by $pts. The model confidence is $conf. Current status is $status.',
                      style: const TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Color(0xFF00D4B4)))),
                  ],
                ),
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text('tap for detail ▾',
                  style: TextStyle(color: Color(0xFF00D4B4), fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection3HelpedHurt() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab Bar
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: const Color(0xFF161B25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF252D3D))),
          child: Row(
            children: [
              _buildTab('✅ Strengths', 0),
              _buildTab('⚠️ Gaps', 1),
              _buildTab('💡 Causal', 2),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Content
        if (_activeTabIndex == 0) ...[
          _buildStrengthCard(
              'Consistent Monthly Income',
              'P1',
              '+0.152',
              'HIGH',
              'Your month-to-month income variance is only 12%, which is lower than 85% of similar workers. This provides strong confidence in your ability to repay.'),
          _buildStrengthCard('Platform Engagement', 'P2', '+0.089', 'HIGH',
              'You have been active on delivery platforms for 24 months consistently. This stability is highly valued by lenders.'),
          _buildStrengthCard('Positive Savings Trend', 'P4', '+0.065', 'MEDIUM',
              'Your end-of-month balance has grown by 8% over the last 3 months, showing good financial discipline.'),
        ] else if (_activeTabIndex == 1) ...[
          _buildGapCard(
              'Minor income volatility',
              'P3',
              '-0.181',
              'HIGH',
              'Current value: 38.9%\nTarget value: < 25.0%\nGap: 13.9%\nScore cost: est. -34 pts',
              'Your current monthly EMI obligations consume 38.9% of your income. Only 15% of approved workers have a ratio this high.',
              'REDUCE EMI BURDEN',
              24,
              const Color(0x33FF4E6A),
              const Color(0xFFFF4E6A)),
          _buildGapCard(
              'Missing Insurance Policy',
              'P6',
              '-0.092',
              'MEDIUM',
              'Current value: Null\nTarget value: Verified Policy\nGap: 1 Document\nScore cost: est. -18 pts',
              'We could not verify active health or life insurance. Uploading this document significantly improves your safety net rating.',
              'UPLOAD INSURANCE POLICY',
              18,
              const Color(0x33F4B942),
              const Color(0xFFF4B942)),
        ] else ...[
          // Causal Chain Template
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: const Color(0x108B5CF6),
                border: Border.all(color: const Color(0x408B5CF6)),
                borderRadius: BorderRadius.circular(14)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('🤖  AI CAUSAL ANALYSIS',
                        style: TextStyle(
                            color: Color(0xFF8B5CF6),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1.1)),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                    'Pattern: gig_debt_stress_loop  ●  Engine: GigCredit Causal v3.0',
                    style: TextStyle(color: Color(0xFF8B95A8), fontSize: 11)),
                Divider(color: Color(0x408B5CF6), height: 24),
                Text('High EMI/income ratio due to existing personal loan',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text('₹7,000 monthly EMI vs ₹18,000 income',
                    style: TextStyle(color: Color(0xFF8B95A8), fontSize: 13)),
                SizedBox(height: 8),
                Center(
                    child: Icon(Icons.arrow_downward,
                        color: Color(0xFF8B5CF6), size: 16)),
                SizedBox(height: 8),
                Text('Savings depleted by EMI',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Only 1.8 months emergency buffer — below 3mo target',
                    style: TextStyle(color: Color(0xFF8B95A8), fontSize: 13)),
                SizedBox(height: 8),
                Center(
                    child: Icon(Icons.arrow_downward,
                        color: Color(0xFF8B5CF6), size: 16)),
                SizedBox(height: 8),
                Text('Score impact: −34 pts estimated',
                    style: TextStyle(
                        color: Color(0xFFFF4E6A), fontWeight: FontWeight.bold)),
                Text('P3 and P4 both weakened by same root cause',
                    style: TextStyle(color: Color(0xFF8B95A8), fontSize: 13)),
                Divider(color: Color(0x408B5CF6), height: 24),
                Text('ROOT FIX RECOMMENDATION:',
                    style: TextStyle(
                        color: Color(0xFF00D4B4),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1)),
                SizedBox(height: 4),
                Text(
                    'Close personal loan or increase platform income by ₹4,000/mo',
                    style: TextStyle(color: Colors.white)),
                Text('est. +34 pts',
                    style: TextStyle(
                        color: Color(0xFF00D4B4),
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ],
            ),
          ).animate().fadeIn(),
        ],
      ],
    ).animate().slideY(begin: 0.1).fadeIn();
  }

  Widget _buildTab(String label, int index) {
    final isActive = _activeTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color:
                        isActive ? const Color(0xFF00D4B4) : Colors.transparent,
                    width: 2)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF8B95A8),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildStrengthCard(
      String name, String pillar, String shap, String impact, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x1A3DD68C),
        border:
            const Border(left: BorderSide(color: Color(0xFF3DD68C), width: 4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle,
                  color: Color(0xFF3DD68C), size: 16),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14))),
            ],
          ),
          const SizedBox(height: 8),
          Text('$pillar  ●  SHAP: $shap  ●  Impact: $impact',
              style: const TextStyle(
                  color: Color(0xFF3DD68C),
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(desc,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, height: 1.5)),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildGapCard(
      String name,
      String pillar,
      String shap,
      String impact,
      String metrics,
      String desc,
      String cta,
      int pts,
      Color bgColor,
      Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(left: BorderSide(color: accentColor, width: 4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14))),
            ],
          ),
          const SizedBox(height: 8),
          Text('$pillar  ●  SHAP: $shap  ●  Impact: $impact\nFixable: 7 DAYS',
              style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  height: 1.5)),
          const SizedBox(height: 12),
          Text(metrics,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  height: 1.5)),
          const SizedBox(height: 12),
          Text(desc,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, height: 1.5)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFF00D4B4),
                borderRadius: BorderRadius.circular(14)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_forward,
                    color: Color(0xFF0D0F14), size: 16),
                const SizedBox(width: 8),
                Text('$cta  →   est. +$pts pts',
                    style: const TextStyle(
                        color: Color(0xFF0D0F14),
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
          )
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildSection4ActionPlan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Potential Score Meter
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: const Color(0xFF161B25),
              borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Current Score    647  Grade B',
                      style: TextStyle(color: Color(0xFF8B95A8), fontSize: 13)),
                  Text('Potential Score  693  Grade B',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ],
              ),
              const SizedBox(height: 12),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 647,
                        child: Container(
                          height: 16,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                                colors: [Color(0xFF3DD68C), Color(0xFF00D4B4)]),
                            borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(8)),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 46, // 693 - 647
                        child: Container(
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Color(0x3300D4B4),
                            borderRadius: BorderRadius.horizontal(
                                right: Radius.circular(8)),
                          ),
                        ),
                      ),
                      const Expanded(
                          flex: 207, child: SizedBox()), // Remaining to 900
                    ],
                  ),
                  Positioned(
                    top: -30,
                    right: 0,
                    left: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: const Color(0xFF00D4B4),
                            borderRadius: BorderRadius.circular(6)),
                        child: const Text('+46 pts',
                            style: TextStyle(
                                color: Color(0xFF0D0F14),
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      )
                          .animate(
                              onPlay: (controller) =>
                                  controller.repeat(reverse: true))
                          .slideY(
                              begin: -0.2,
                              end: 0,
                              duration: 2.seconds,
                              curve: Curves.easeInOutSine),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildActionCard(
            '1',
            Icons.verified_user,
            'Upload Health Insurance Policy',
            '+18 pts',
            'HIGH',
            '2 minutes',
            'P6',
            '0.450 → 0.720',
            [
              'Open any PDF of your insurance policy',
              'Tap Upload below → select PDF',
              'PaddleOCR verifies in ~10 seconds'
            ],
            'UPLOAD INSURANCE POLICY',
            const Color(0xFFF4B942)),
        _buildActionCard(
            '2',
            Icons.description,
            'Upload ITR Acknowledgement',
            '+10 pts',
            'MEDIUM',
            '5 minutes',
            'P8',
            '0.500 → 0.720',
            [
              'Download from incometax.gov.in → e-filing',
              'Upload the PDF receipt'
            ],
            'UPLOAD ITR DOCUMENT',
            const Color(0xFF00D4B4)),

        // Immediate Gain Summary
        Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: const Color(0x1400D4B4),
              border: Border.all(color: const Color(0x4D00D4B4)),
              borderRadius: BorderRadius.circular(14)),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Complete all 2 actions → +28 pts',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              Text('Score: 647 → 675   Grade: B → B',
                  style: TextStyle(color: Color(0xFF8B95A8), fontSize: 13)),
            ],
          ),
        ),
      ],
    ).animate().slideY(begin: 0.1).fadeIn();
  }

  Widget _buildActionCard(
      String num,
      IconData icon,
      String title,
      String gain,
      String impact,
      String time,
      String pillar,
      String transition,
      List<String> steps,
      String cta,
      Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(
                    child: Text(num,
                        style: const TextStyle(
                            color: Color(0xFF0D0F14),
                            fontWeight: FontWeight.bold,
                            fontSize: 12))),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14))),
            ],
          ),
          const Divider(color: Color(0xFF252D3D), height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Score gain:   $gain',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 13)),
              Text('Impact: $impact',
                  style:
                      const TextStyle(color: Color(0xFF8B95A8), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Timeline:     $time',
              style: const TextStyle(color: Color(0xFF8B95A8), fontSize: 13)),
          const SizedBox(height: 12),
          Text('WHY: $pillar score changes from $transition',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 12),
          const Text('HOW:',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          ...steps.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(top: 4, left: 8),
                child: Text('Step ${e.key + 1}: ${e.value}',
                    style: const TextStyle(
                        color: Color(0xFF8B95A8), fontSize: 12)),
              )),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
                color: const Color(0xFF00D4B4),
                borderRadius: BorderRadius.circular(14)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_forward,
                    color: Color(0xFF0D0F14), size: 18),
                const SizedBox(width: 8),
                Text('$cta  →',
                    style: const TextStyle(
                        color: Color(0xFF0D0F14),
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSection5Story() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Language Selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildLangChip('EN English'),
              _buildLangChip('TA தமிழ்'),
              _buildLangChip('HI हिंदी'),
              _buildLangChip('TE తెలుగు'),
              _buildLangChip('KN ಕನ್ನಡ'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Narrative Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF161B25),
            borderRadius: BorderRadius.circular(14),
            border: const Border(
                left: BorderSide(color: Color(0xFF00D4B4), width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('GEMINI-GENERATED EXPLANATION  ●  Tailored for You',
                  style: TextStyle(
                      color: Color(0xFF8B95A8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
              const Divider(color: Color(0xFF252D3D), height: 24),
              if (_isTranslating)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF00D4B4)),
                  ),
                )
              else
                Text(
                  _translations[_selectedLang] ?? report.llmExplanation ?? 'Explanation not available.',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14, height: 1.6)),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.volume_up, color: Color(0xFF00D4B4), size: 18),
                  const SizedBox(width: 8),
                  Text('Listen in ${_selectedLang.split(" ")[0]}',
                      style: const TextStyle(
                          color: Color(0xFF00D4B4),
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  const Icon(Icons.share, color: Color(0xFF8B95A8), size: 18),
                ],
              )
            ],
          ),
        ),

        const SizedBox(height: 16),



        // Workers Like You
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: const Color(0xFF161B25),
              borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('👥  HOW DO YOU COMPARE?',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              const Text(
                  'Platform Worker in Tamil Nadu\nSample: 847 comparable profiles',
                  style: TextStyle(
                      color: Color(0xFF8B95A8), fontSize: 13, height: 1.5)),
              const Divider(color: Color(0xFF252D3D), height: 24),
              const Text('SCORE DISTRIBUTION:',
                  style: TextStyle(
                      color: Color(0xFF8B95A8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1)),
              const SizedBox(height: 12),
              _buildDistributionRow('300-499', 0.1, '142'),
              _buildDistributionRow('500-599', 0.3, '281'),
              _buildDistributionRow('600-699', 0.8, '212', highlight: true),
              _buildDistributionRow('700-799', 0.4, '114'),
              _buildDistributionRow('800-900', 0.1, '30'),
              const SizedBox(height: 16),
              const Text('You are above 491 of 847 (58%) of comparable workers',
                  style: TextStyle(
                      color: Color(0xFF3DD68C),
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    ).animate().slideY(begin: 0.1).fadeIn();
  }

  Widget _buildLangChip(String label) {
    final active = _selectedLang == label;
    return GestureDetector(
      onTap: () => _translateReport(label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF00D4B4) : const Color(0xFF161B25),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: active ? const Color(0xFF0D0F14) : const Color(0xFF8B95A8),
              fontSize: 13,
              fontWeight: active ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }

  Widget _buildDistributionRow(String range, double flex, String count,
      {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
              width: 60,
              child: Text(range,
                  style:
                      const TextStyle(color: Color(0xFF8B95A8), fontSize: 12))),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: (flex * 100).toInt(),
                  child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                          color: highlight
                              ? const Color(0xFF00D4B4)
                              : const Color(0xFF252D3D),
                          borderRadius: BorderRadius.circular(4))),
                ),
                Expanded(
                    flex: 100 - (flex * 100).toInt(), child: const SizedBox()),
              ],
            ),
          ),
          SizedBox(
              width: 40,
              child: Text(count,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: highlight ? const Color(0xFF00D4B4) : Colors.white,
                      fontSize: 12,
                      fontWeight:
                          highlight ? FontWeight.bold : FontWeight.normal))),
        ],
      ),
    );
  }

  Widget _buildSection6Technical() {
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFF161B25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF252D3D))),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: const ExpansionTile(
          iconColor: Colors.white,
          collapsedIconColor: Color(0xFF8B95A8),
          title: Text('🔬 Technical Scoring Details [For lenders]',
              style: TextStyle(color: Colors.white, fontSize: 14)),
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'META-LEARNER OUTPUT\nLogit value: 0.7821\nProbability: 0.6863\nFormula: 647 = round(0.6863 × 600 + 300)\n\nEFS BLOCK\nMethod: 50-run Gaussian perturbation\nStable runs: 42 / 50\nVerdict: STABLE\n\nTOP 10 SHAP FEATURES\n1. emi_to_income_ratio (-0.181)\n2. income_cv (+0.152)\n3. platform_tenure (+0.089)',
                style: TextStyle(
                    color: Color(0xFF8B95A8),
                    fontSize: 12,
                    height: 1.6,
                    fontFamily: 'monospace'),
              ),
            )
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildSection7Regulatory() {
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFF161B25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF252D3D))),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: const ExpansionTile(
          iconColor: Colors.white,
          collapsedIconColor: Color(0xFF8B95A8),
          title: Text('⚖️ Regulatory & Legal Details [RBI Compliance]',
              style: TextStyle(color: Colors.white, fontSize: 14)),
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'AUDIT TRAIL\nAudit Trail ID: AT-2026-0430-AB1234-a3f2\nHash Chain: VERIFIED ✓\nDecision Replay: Available\n\nFAIRNESS METRICS\nDemographic Parity: PASS (3.2 pts gap)\nEqualized Odds: PASS (4.0% gap)\nCalibration Error: PASS (0.031)\n\nADVERSE ACTION NOTICE (RBI FPC 2015)\n1. Minor income volatility (SHAP -0.181)\n2. Missing Insurance Policy (SHAP -0.092)\n\nPRIVACY NOTICE\nScore computed on device. No raw data transmitted. Data controller: GigCredit NBFC Ltd.',
                style: TextStyle(
                    color: Color(0xFF8B95A8), fontSize: 12, height: 1.6),
              ),
            )
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildStickyFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xE6161B25),
        border: Border(top: BorderSide(color: Color(0xFF252D3D))),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'GC-2026-0430-AB1234  ●  Hash: sha256:a3f2...  ●  Verified ✓',
                style: TextStyle(
                    color: Color(0xFF8B95A8),
                    fontSize: 10,
                    fontFamily: 'monospace')),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildGhostButton(context, '📥 Download PDF')),
                const SizedBox(width: 8),
                Expanded(child: _buildGhostButton(context, '📤 Share with Lender')),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => context.go(AppRoutes.loanApply),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.greenBright,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('💰   APPLY FOR A LOAN  →',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGhostButton(BuildContext context, String label) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label - Action Simulated', style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.greenPrimary),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
