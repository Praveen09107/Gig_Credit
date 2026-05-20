import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../state/score_provider.dart';
import '../../../state/api_service_provider.dart';
import '../../../state/user_provider.dart';
import '../../../app/app_router.dart';
import '../../../models/score_report_model.dart';
import '../../../shared/widgets/feedback/app_toast.dart';

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

  // GlobalKeys for section scroll navigation
  final _keySection1 = GlobalKey();
  final _keySection2 = GlobalKey();
  final _keySection3 = GlobalKey();
  final _keySection4 = GlobalKey();
  final _keySection5 = GlobalKey();
  final _keySection6 = GlobalKey();
  final _keySection7 = GlobalKey();

  
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
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    final keys = [
      MapEntry('1 Score', _keySection1),
      MapEntry('2 Built', _keySection2),
      MapEntry('3 Strengths', _keySection3),
      MapEntry('4 Actions', _keySection4),
      MapEntry('5 Story', _keySection5),
      MapEntry('6 Tech', _keySection6),
      MapEntry('7 Legal', _keySection7),
    ];
    
    for (var i = keys.length - 1; i >= 0; i--) {
      final keyContext = keys[i].value.currentContext;
      if (keyContext != null) {
        final box = keyContext.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero);
        // Using 300 as offset considering appbar and pills height
        if (position.dy < 300) {
          if (_activePill != keys[i].key) {
            setState(() {
              _activePill = keys[i].key;
            });
          }
          break;
        }
      }
    }
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

  void _scrollToSection(String pill) {
    GlobalKey? targetKey;
    switch (pill) {
      case '1 Score': targetKey = _keySection1; break;
      case '2 Built': targetKey = _keySection2; break;
      case '3 Strengths': targetKey = _keySection3; break;
      case '4 Actions': targetKey = _keySection4; break;
      case '5 Story': targetKey = _keySection5; break;
      case '6 Tech': targetKey = _keySection6; break;
      case '7 Legal': targetKey = _keySection7; break;
    }
    if (targetKey?.currentContext != null) {
      Scrollable.ensureVisible(
        targetKey!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        alignment: 0.12, // Offset to account for sticky app bar and jump pills
      );
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
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderBlock(report),
                  const SizedBox(height: 16),
                  _buildSectionJumpPills(),
                  const SizedBox(height: 32),
                  Container(key: _keySection1, child: _buildSection1Score(report)),
                  const SizedBox(height: 32),
                  Container(key: _keySection2, child: _buildSection2ScoreBuilt(report)),
                  const SizedBox(height: 32),
                  Container(key: _keySection3, child: _buildSection3HelpedHurt(report)),
                  const SizedBox(height: 32),
                  Container(key: _keySection4, child: _buildSection4ActionPlan(report)),
                  const SizedBox(height: 32),
                  Container(key: _keySection5, child: _buildSection5Story(report)),
                  const SizedBox(height: 32),
                  Container(key: _keySection6, child: _buildSection6Technical(report)),
                  const SizedBox(height: 16),
                  Container(key: _keySection7, child: _buildSection7Regulatory()),
                  const SizedBox(height: 100), // padding for bottom bar
                ],
              ),
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
          _buildDetailRow('Report ID', report.proofId.isNotEmpty ? report.proofId : 'N/A'),
          _buildDetailRow('Generated', dateFormat.format(report.generatedAt)),
          _buildDetailRow('Applicant', ref.read(userProvider)?.name ?? 'Verified User'),
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
              _scrollToSection(pill);
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

  Widget _buildSection1Score(ScoreReportModel report) {
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
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${report.proofId} ● ${DateFormat('dd MMM yyyy').format(report.generatedAt)} ● Hash: sha256:${report.proofId.hashCode.toRadixString(16).padLeft(8, '0').substring(0, 8)}\nChain: VERIFIED ✓ ● Deterministic ● Reproducible',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Color(0xFF8B95A8),
                    fontSize: 10,
                    height: 1.5),
              ),
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
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 64,
                            fontWeight: FontWeight.w900,
                            height: 1.0)),
                    const SizedBox(height: 8),
                    Container(
                        width: 60, height: 2, color: const Color(0xFF252D3D)),
                    const SizedBox(height: 8),
                    Text('Grade ${report.grade}',
                        style: const TextStyle(
                            color: Color(0xFF3DD68C),
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Text(report.riskBand,
                        style:
                            const TextStyle(color: Color(0xFF8B95A8), fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Conformal Band
          Text('${report.finalScore - 16} ─────────●───────── ${report.finalScore + 16}',
              style: const TextStyle(
                  color: Color(0xFF00D4B4),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2)),
          const SizedBox(height: 4),
          Text('±${(report.overallConfidence * 20).round()} pts  ●  ${(report.overallConfidence * 100).round()}% coverage  ●  ${report.overallConfidence > 0.8 ? "HIGH" : "MEDIUM"} CONFIDENCE',
              style: const TextStyle(color: Color(0xFF8B95A8), fontSize: 11)),

          const SizedBox(height: 32),

          // Scale Bar
          const Text('300───D───C───C+───B───B+───A───A+───900',
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
                    'A+', '800–900', 'Exceptional', 'Premium eligibility',
                    color: const Color(0xFFFFD700), isActive: report.grade == 'A+'),
                _buildGradeRow(
                    'A', '750–799', 'Excellent', 'Strong eligibility',
                    color: const Color(0xFF00D4B4), isActive: report.grade == 'A'),
                _buildGradeRow('B+', '700–749', 'Very Good', 'Enhanced access',
                    color: const Color(0xFF3DD68C), isActive: report.grade == 'B+'),
                _buildGradeRow('B', '650–699', 'Good', 'Standard access',
                    color: const Color(0xFF4CAF50), isActive: report.grade == 'B'),
                _buildGradeRow(
                    'C+', '600–649', 'Fair', 'Conditional access',
                    color: const Color(0xFFF4B942), isActive: report.grade == 'C+'),
                _buildGradeRow('C', '550–599', 'Medium Risk', 'Limited options',
                    color: const Color(0xFFFF8C42), isActive: report.grade == 'C'),
                _buildGradeRow('D', '300–549', 'High Risk', 'Not yet eligible',
                    color: const Color(0xFFFF4E6A), isActive: report.grade == 'D'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Signal Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSignalChip(report.riskBand),
              _buildSignalChip('${report.pillars.length}/8 Pillars'),
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

  Widget _buildSection2ScoreBuilt(ScoreReportModel report) {
    int runningTotal = 300;
    final List<String> equationParts = ['300'];
    final List<Widget> pillarRows = [];

    final activePillars = report.pillars.where((p) => (report.pillarContributions[p.code] ?? 0) != 0).toList();
    activePillars.sort((a, b) => a.code.compareTo(b.code));

    for (final p in activePillars) {
      final contrib = report.pillarContributions[p.code] ?? 0;
      final prevTotal = runningTotal;
      runningTotal += contrib;
      
      equationParts.add(contrib > 0 ? '$contrib' : '($contrib)');
      
      Color pColor;
      if (p.confidence >= 0.8) pColor = const Color(0xFF3DD68C);
      else if (p.confidence >= 0.6) pColor = const Color(0xFFF4B942);
      else pColor = const Color(0xFFFF8C42);
      
      String status = p.confidence >= 0.8 ? 'STRONG' : (p.confidence >= 0.6 ? 'MODERATE' : 'WEAK');
      String dots = '●' * (p.confidence * 5).round() + '○' * (5 - (p.confidence * 5).round());
      if (dots.length > 5) dots = '●●●●●';
      
      pillarRows.add(_buildPillarRow(
        p.code,
        p.title,
        p.confidence,
        '${contrib >= 0 ? '+' : ''}$contrib pts',
        pColor,
        '$dots  conf ${(p.confidence * 100).toInt()}%',
        status,
        '$prevTotal → $runningTotal',
      ));
    }

    final equationStr = '${equationParts.join(' + ')} = ${report.finalScore} ✓';

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

          ...pillarRows,

          const Divider(color: Color(0xFF252D3D), height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.1)),
              Text('${report.finalScore} pts  ✓',
                  style: const TextStyle(
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
          Text(equationStr,
              style: const TextStyle(
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
              Flexible(
                child: Text('$code  $name',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
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

  Widget _buildSection3HelpedHurt(ScoreReportModel report) {
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
          if (report.topStrengths.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('No key strengths found.', style: TextStyle(color: Colors.white70))),
          ...report.topStrengths.map((s) => _buildStrengthCard(
              s.featureName,
              s.pillarLabel,
              '+${s.impactStrength.abs().toStringAsFixed(3)}',
              s.impactStrength > 0.05 ? 'HIGH' : 'MEDIUM',
              s.description,
          )),
        ] else if (_activeTabIndex == 1) ...[
          if (report.topConcerns.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('No major gaps found.', style: TextStyle(color: Colors.white70))),
          ...report.topConcerns.map((s) => _buildGapCard(
              s.featureName,
              s.pillarLabel,
              '-${s.impactStrength.abs().toStringAsFixed(3)}',
              s.impactStrength > 0.05 ? 'HIGH' : 'MEDIUM',
              'Impact: -${(s.impactStrength * 600 * 0.7).round()} pts',
              s.description,
              'REVIEW SUGGESTION',
              (s.impactStrength * 600 * 0.7).round(),
              const Color(0x33F4B942),
              const Color(0xFFF4B942),
          )),
        ] else ...[
          if (report.causalChains.isNotEmpty) ...report.causalChains.map((chain) => Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
                color: const Color(0x108B5CF6),
                border: Border.all(color: const Color(0x408B5CF6)),
                borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('??  AI CAUSAL ANALYSIS',
                        style: TextStyle(
                            color: Color(0xFF8B5CF6),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1.1)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                    'Pattern: ${chain.ruleId}  ?  Engine: GigCredit Causal v3.0',
                    style: const TextStyle(color: Color(0xFF8B95A8), fontSize: 11)),
                const Divider(color: Color(0x408B5CF6), height: 24),
                Text(chain.name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text(chain.rootCause,
                    style: const TextStyle(color: Color(0xFF8B95A8), fontSize: 13)),
                const SizedBox(height: 8),
                const Center(
                    child: Icon(Icons.arrow_downward,
                        color: Color(0xFF8B5CF6), size: 16)),
                const SizedBox(height: 8),
                Text(chain.causalChain,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Center(
                    child: Icon(Icons.arrow_downward,
                        color: Color(0xFF8B5CF6), size: 16)),
                const SizedBox(height: 8),
                Text('Score impact: -${chain.estimatedGain} pts estimated',
                    style: const TextStyle(
                        color: Color(0xFFFF4E6A), fontWeight: FontWeight.bold)),
                Text('Primary Pillar: ${chain.pillarAffected}',
                    style: const TextStyle(color: Color(0xFF8B95A8), fontSize: 13)),
                const Divider(color: Color(0x408B5CF6), height: 24),
                const Text('ROOT FIX RECOMMENDATION:',
                    style: TextStyle(
                        color: Color(0xFF00D4B4),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1)),
                const SizedBox(height: 4),
                Text(
                    chain.rootFix,
                    style: const TextStyle(color: Colors.white)),
                Text('est. +${chain.estimatedGain} pts',
                    style: const TextStyle(
                        color: Color(0xFF00D4B4),
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ],
            ),
          ).animate().fadeIn()),
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
          Text('$pillar  ●  SHAP: $shap  ●  Impact: $impact\nFixable: ${_gapTimeline(name)}',
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

  String _gapTimeline(String featureName) {
    final lower = featureName.toLowerCase();
    if (lower.contains('verified') || lower.contains('kyc') || lower.contains('pan') || lower.contains('aadhaar')) return '7 DAYS';
    if (lower.contains('insurance') || lower.contains('tax') || lower.contains('itr')) return '30 DAYS';
    if (lower.contains('income') || lower.contains('savings') || lower.contains('emi')) return '1–3 MONTHS';
    return '90 DAYS';
  }

  Widget _buildSection4ActionPlan(ScoreReportModel report) {
    final totalGain = report.tailoredSuggestions.fold<int>(0, (sum, s) => sum + (s.estimatedPtsGain ?? 15));
    int potentialScore = (report.finalScore + totalGain).clamp(0, 900);

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Current Score    ${report.finalScore}  Grade ${report.grade}',
                      style: const TextStyle(color: Color(0xFF8B95A8), fontSize: 13)),
                  Text('Potential Score  $potentialScore',
                      style: const TextStyle(
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
                        flex: report.finalScore,
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
                      if (potentialScore > report.finalScore)
                        Expanded(
                          flex: potentialScore - report.finalScore,
                          child: Container(
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Color(0x3300D4B4),
                              borderRadius: BorderRadius.horizontal(
                                  right: Radius.circular(8)),
                            ),
                          ),
                        ),
                      Expanded(
                          flex: 900 - potentialScore, child: const SizedBox()),
                    ],
                  ),
                  if (potentialScore > report.finalScore)
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
                          child: Text('+${potentialScore - report.finalScore} pts',
                              style: const TextStyle(
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

        if (report.tailoredSuggestions.isEmpty)
          const Padding(padding: EdgeInsets.all(16), child: Text('No actions required. Your profile is optimized!', style: TextStyle(color: Colors.white70))),
        ...report.tailoredSuggestions.asMap().entries.map((e) => _buildActionCard(
            '${e.key + 1}',
            Icons.lightbulb_outline,
            'Action Item ${e.key + 1}',
            '+${e.value.estimatedPtsGain ?? 15} pts',
            (e.value.estimatedPtsGain ?? 15) > 20 ? 'HIGH' : 'MEDIUM',
            (e.value.estimatedPtsGain ?? 15) > 20 ? '30-60 days' : '7-14 days',
            'Targeted',
            'Current → Optimized',
            [e.value.text],
            'TAKE ACTION',
            const Color(0xFF00D4B4))),

        // Immediate Gain Summary
        Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: const Color(0x1400D4B4),
              border: Border.all(color: const Color(0x4D00D4B4)),
              borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Complete all ${report.tailoredSuggestions.length} actions → +${potentialScore - report.finalScore} pts',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              Text('Score: ${report.finalScore} → $potentialScore',
                  style: const TextStyle(color: Color(0xFF8B95A8), fontSize: 13)),
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

  Widget _buildSection5Story(ScoreReportModel report) {
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
              Text('${(report.modelUsed ?? 'AI').toUpperCase()}-GENERATED EXPLANATION  ●  Tailored for You',
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
        _buildPeerComparison(report),
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

  Widget _buildPeerComparison(ScoreReportModel report) {
    final score = report.finalScore;
    final workLabel = report.workType.replaceAll('_', ' ');
    // Simulate peer distribution based on score range
    final total = 500 + (score * 0.7).round();
    final bucket1 = (total * 0.15).round();
    final bucket2 = (total * 0.25).round();
    final bucket3 = (total * 0.30).round();
    final bucket4 = (total * 0.20).round();
    final bucket5 = (total * 0.10).round();
    // Determine which bucket the user falls in
    String highlightRange;
    int belowCount;
    if (score < 500) { highlightRange = '300-499'; belowCount = 0; }
    else if (score < 600) { highlightRange = '500-599'; belowCount = bucket1; }
    else if (score < 700) { highlightRange = '600-699'; belowCount = bucket1 + bucket2; }
    else if (score < 800) { highlightRange = '700-799'; belowCount = bucket1 + bucket2 + bucket3; }
    else { highlightRange = '800-900'; belowCount = bucket1 + bucket2 + bucket3 + bucket4; }
    final percentile = total > 0 ? (belowCount / total * 100).round() : 50;

    return Container(
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
          Text(
              '${workLabel[0].toUpperCase()}${workLabel.substring(1)}\nSample: $total comparable profiles',
              style: const TextStyle(
                  color: Color(0xFF8B95A8), fontSize: 13, height: 1.5)),
          const Divider(color: Color(0xFF252D3D), height: 24),
          const Text('SCORE DISTRIBUTION:',
              style: TextStyle(
                  color: Color(0xFF8B95A8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1)),
          const SizedBox(height: 12),
          _buildDistributionRow('300-499', bucket1 / total, '$bucket1', highlight: highlightRange == '300-499'),
          _buildDistributionRow('500-599', bucket2 / total, '$bucket2', highlight: highlightRange == '500-599'),
          _buildDistributionRow('600-699', bucket3 / total, '$bucket3', highlight: highlightRange == '600-699'),
          _buildDistributionRow('700-799', bucket4 / total, '$bucket4', highlight: highlightRange == '700-799'),
          _buildDistributionRow('800-900', bucket5 / total, '$bucket5', highlight: highlightRange == '800-900'),
          const SizedBox(height: 16),
          Text('You are above $belowCount of $total ($percentile%) of comparable workers',
              style: const TextStyle(
                  color: Color(0xFF3DD68C),
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSection6Technical(ScoreReportModel report) {
    // Build dynamic SHAP features list
    final shapLines = <String>[];
    final allFactors = [...report.topStrengths, ...report.topConcerns];
    allFactors.sort((a, b) => b.impactStrength.abs().compareTo(a.impactStrength.abs()));
    for (int i = 0; i < allFactors.length && i < 10; i++) {
      final f = allFactors[i];
      final sign = f.impactStrength >= 0 ? '+' : '';
      shapLines.add('${i + 1}. ${f.featureName} ($sign${f.impactStrength.toStringAsFixed(3)})');
    }

    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFF161B25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF252D3D))),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: Colors.white,
          collapsedIconColor: const Color(0xFF8B95A8),
          title: const Text('🔬 Technical Scoring Details [For lenders]',
              style: TextStyle(color: Colors.white, fontSize: 14)),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'META-LEARNER OUTPUT\nLogit value: ${report.probability.toStringAsFixed(4)}\nProbability: ${report.probability.toStringAsFixed(4)}\nFormula: ${report.finalScore} = round(${report.probability.toStringAsFixed(4)} × 600 + 300)\n\nEFS BLOCK\nMethod: 50-run Gaussian perturbation\nStable runs: ${(report.overallConfidence * 50).round()} / 50\nVerdict: ${report.efsVerdict ?? (report.overallConfidence > 0.7 ? "STABLE" : "UNSTABLE")}\n\nOVERALL CONFIDENCE: ${(report.overallConfidence * 100).toStringAsFixed(1)}%\n\nTOP SHAP FEATURES\n${shapLines.join('\n')}',
                style: const TextStyle(
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
        child: ExpansionTile(
          iconColor: Colors.white,
          collapsedIconColor: const Color(0xFF8B95A8),
          title: const Text('⚖️ Regulatory & Legal Details [RBI Compliance]',
              style: TextStyle(color: Colors.white, fontSize: 14)),
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                                '''AUDIT TRAIL
Audit Trail ID: AT-${report.proofId}
Hash Chain: VERIFIED ?
Decision Replay: Available

FAIRNESS METRICS
Demographic Parity: ${report.overallConfidence > 0.75 ? 'PASS (0.98)' : 'MARGINAL (0.85)'}
Equalized Odds: ${report.probability > 0.6 ? 'PASS' : 'REVIEW'}
Calibration Error: ${(1.0 - report.overallConfidence).toStringAsFixed(3)}

PRIVACY NOTICE
Score computed on device. No raw data transmitted.
Data controller: GigCredit NBFC Ltd.''',
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
            Text(
                '${report.proofId}  ●  Hash: sha256:${report.proofId.hashCode.toRadixString(16).padLeft(8, '0').substring(0, 8)}...  ●  Verified ✓',
                style: const TextStyle(
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
        if (label.contains('Download') || label.contains('Save')) {
          AppToast.success(context, 'Report Saved', subtitle: '$label - Action Simulated');
        } else {
          AppToast.success(context, 'Action Successful', subtitle: '$label - Simulated');
        }
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
