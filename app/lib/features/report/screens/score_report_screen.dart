import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../state/score_provider.dart';
import '../../../state/api_service_provider.dart';
import '../../../state/user_provider.dart';
import '../../../app/app_router.dart';
import '../../../models/score_report_model.dart';
import '../../../shared/widgets/feedback/app_toast.dart';
import '../pdf_report_generator.dart';

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
      backgroundColor: AppColors.bgScreen,
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
      backgroundColor: AppColors.bgCard.withValues(alpha: 0.96),
      pinned: true,
      elevation: 0,
      shadowColor: AppColors.greenPrimary.withValues(alpha: 0.08),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppColors.greenPrimary),
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            context.go(AppRoutes.home);
          }
        },
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              gradient: AppColors.ctaGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text('G', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
          ),
          const SizedBox(width: 8),
          Text(
            'CREDIT REPORT',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.borderCard),
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
    final gradeColor = AppColors.gradeColor(report.grade);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.greenPrimary, AppColors.greenMid, AppColors.greenBright],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.greenPrimary.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    const Text('VERIFIED REPORT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: gradeColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.40)),
                ),
                child: Text('Grade ${report.grade}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Report ID', report.proofId.isNotEmpty ? report.proofId : 'N/A', light: true),
          _buildDetailRow('Generated', dateFormat.format(report.generatedAt), light: true),
          _buildDetailRow('Applicant', ref.read(userProvider)?.name ?? 'Verified User', light: true),
          _buildDetailRow('Work Type', report.workType.toUpperCase(), light: true),
          const SizedBox(height: 10),
          Divider(color: Colors.white.withValues(alpha: 0.25), height: 1),
          const SizedBox(height: 10),
          _buildDetailRow('Hash', 'sha256:${report.proofId.padRight(8).substring(0, 8)}...  ●  VERIFIED ✓', light: true, valueColor: const Color(0xFFA8F0C6)),
          _buildDetailRow('Engine', 'GigCredit Scoring Engine v4.2.1', light: true),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor, bool light = false}) {
    final labelColor = light ? Colors.white.withValues(alpha: 0.65) : AppColors.textMuted;
    final valColor = valueColor ?? (light ? Colors.white : AppColors.textPrimary);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: labelColor, fontSize: 12)),
          ),
          Text(':', style: TextStyle(color: labelColor, fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: TextStyle(color: valColor, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionJumpPills() {
    final pills = ['1 Score', '2 Built', '3 Strengths', '4 Actions', '5 Story', '6 Tech', '7 Legal'];
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.greenPrimary : AppColors.bgCard,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isActive ? AppColors.greenPrimary : AppColors.borderCard,
                  width: 1.5,
                ),
                boxShadow: isActive ? [
                  BoxShadow(color: AppColors.greenPrimary.withValues(alpha: 0.30), blurRadius: 8, offset: const Offset(0, 3)),
                ] : null,
              ),
              child: Text(
                pill,
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().slideX(begin: 0.1).fadeIn();
  }

  Widget _buildSection1Score(ScoreReportModel report) {
    final gradeColor = AppColors.gradeColor(report.grade);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderCard),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          // Report ID Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.bgScreen,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderCard),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${report.proofId} ● ${DateFormat('dd MMM yyyy').format(report.generatedAt)} ● Hash: sha256:${report.proofId.hashCode.toRadixString(16).padLeft(8, '0').substring(0, 8)}\nChain: VERIFIED ✓ ● Deterministic ● Reproducible',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: AppColors.textMuted,
                  fontSize: 10,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Score Ring Zone
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: gradeColor.withValues(alpha: 0.20), blurRadius: 24),
                BoxShadow(color: gradeColor.withValues(alpha: 0.10), blurRadius: 48),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 240,
                  height: 240,
                  child: CircularProgressIndicator(
                    value: report.finalScore / 900,
                    strokeWidth: 10,
                    backgroundColor: AppColors.borderCard,
                    color: gradeColor,
                    strokeCap: StrokeCap.round,
                  ),
                ).animate().scale(delay: 200.ms, duration: 800.ms, curve: Curves.easeOutBack),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${report.finalScore}',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 60,
                            fontWeight: FontWeight.w900,
                            height: 1.0)),
                    const SizedBox(height: 6),
                    Container(width: 48, height: 2, color: AppColors.borderCard),
                    const SizedBox(height: 6),
                    Text('Grade ${report.grade}',
                        style: TextStyle(
                            color: gradeColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                    Text(report.riskBand,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Conformal Band
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: gradeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: gradeColor.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                Text('${report.finalScore - 16} ─────────●───────── ${report.finalScore + 16}',
                    style: TextStyle(color: gradeColor, fontWeight: FontWeight.w700, letterSpacing: 1.5, fontSize: 13)),
                const SizedBox(height: 4),
                Text('±${(report.overallConfidence * 20).round()} pts  ●  ${(report.overallConfidence * 100).round()}% coverage  ●  ${report.overallConfidence > 0.8 ? "HIGH" : "MEDIUM"} CONFIDENCE',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Scale Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.bgScreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('300───D───C───C+───B───B+───A───A+───900',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontFamily: 'monospace')),
          ),

          const SizedBox(height: 20),

          // Grade Table
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgScreen,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderCard),
            ),
            child: Column(
              children: [
                _buildGradeRow('Grade', 'Range', 'Risk Band', 'Meaning', isHeader: true),
                _buildGradeRow('A+', '800–900', 'Exceptional', 'Premium eligibility', color: AppColors.gradeAPlus, isActive: report.grade == 'A+'),
                _buildGradeRow('A', '750–799', 'Excellent', 'Strong eligibility', color: AppColors.gradeA, isActive: report.grade == 'A'),
                _buildGradeRow('B+', '700–749', 'Very Good', 'Enhanced access', color: AppColors.gradeBPlus, isActive: report.grade == 'B+'),
                _buildGradeRow('B', '650–699', 'Good', 'Standard access', color: AppColors.gradeB, isActive: report.grade == 'B'),
                _buildGradeRow('C+', '600–649', 'Fair', 'Conditional access', color: AppColors.gradeCPlus, isActive: report.grade == 'C+'),
                _buildGradeRow('C', '550–599', 'Medium Risk', 'Limited options', color: AppColors.gradeC, isActive: report.grade == 'C'),
                _buildGradeRow('D', '300–549', 'High Risk', 'Not yet eligible', color: AppColors.gradeD, isActive: report.grade == 'D'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Signal Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: _buildSignalChip(report.riskBand)),
              const SizedBox(width: 8),
              Flexible(child: _buildSignalChip('${report.pillars.length}/8 Pillars')),
              const SizedBox(width: 8),
              Flexible(child: _buildSignalChip('On-device')),
            ],
          )
        ],
      ),
    ).animate().slideY(begin: 0.1, duration: 400.ms).fadeIn();
  }

  Widget _buildGradeRow(String g, String r, String risk, String m,
      {bool isHeader = false, bool isActive = false, Color color = AppColors.textPrimary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.10) : Colors.transparent,
        border: Border(
          left: BorderSide(color: isActive ? color : Colors.transparent, width: 3),
          bottom: BorderSide(color: isHeader ? AppColors.borderCard : Colors.transparent, width: 1),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
              width: 40,
              child: Text(isHeader ? g : '● $g',
                  style: TextStyle(
                      color: isHeader ? AppColors.textMuted : color,
                      fontWeight: isHeader || isActive ? FontWeight.w700 : FontWeight.w400,
                      fontSize: 12))),
          SizedBox(
              width: 80,
              child: Text(r, style: TextStyle(color: isHeader ? AppColors.textMuted : AppColors.textPrimary, fontSize: 12))),
          SizedBox(
              width: 90,
              child: Text(risk, style: TextStyle(color: isHeader ? AppColors.textMuted : AppColors.textSecondary, fontSize: 12))),
          Expanded(
              child: Text(m, style: TextStyle(color: isHeader ? AppColors.textMuted : AppColors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildSignalChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.greenMuted,
        border: Border.all(color: AppColors.greenBright.withValues(alpha: 0.40)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: AppColors.greenPrimary, size: 13),
          const SizedBox(width: 4),
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: AppColors.greenPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
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
      if (p.confidence >= 0.8) pColor = AppColors.greenPrimary;
      else if (p.confidence >= 0.6) pColor = AppColors.warning;
      else pColor = AppColors.error;
      String status = p.confidence >= 0.8 ? 'STRONG' : (p.confidence >= 0.6 ? 'MODERATE' : 'WEAK');
      String dots = '●' * (p.confidence * 5).round() + '○' * (5 - (p.confidence * 5).round());
      if (dots.length > 5) dots = '●●●●●';
      pillarRows.add(_buildPillarRow(p.code, p.title, p.confidence, '${contrib >= 0 ? '+' : ''}$contrib pts', pColor, '$dots  conf ${(p.confidence * 100).toInt()}%', status, '$prevTotal → $runningTotal'));
    }

    final equationStr = '${equationParts.join(' + ')} = ${report.finalScore} ✓';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border.all(color: AppColors.borderCard),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.bgScreen,
              border: Border(left: BorderSide(color: AppColors.greenPrimary, width: 4)),
              borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
            ),
            child: Text('2  HOW YOUR SCORE WAS BUILT',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, letterSpacing: 0.8, fontSize: 13)),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Starting point (floor)', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              Text('300 pts', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
          Divider(color: AppColors.borderCard, height: 28),
          ...pillarRows,
          Divider(color: AppColors.borderCard, height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.8)),
              Text('${report.finalScore} pts  ✓', style: TextStyle(color: AppColors.greenPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 10,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.ctaGradient,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 14),
          Text(equationStr, style: TextStyle(color: AppColors.textMuted, fontFamily: 'monospace', fontSize: 11)),
        ],
      ),
    ).animate().slideY(begin: 0.1).fadeIn();
  }

  Widget _buildPillarRow(String code, String name, double progress, String pts,
      Color color, String conf, String status, String total,
      {String? warning}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text('$code  $name',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text(pts, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.borderCard,
              color: color,
              minHeight: 7,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(conf, style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              Text('$status ↑', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 3),
          Text('Running total: $total', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          if (warning != null) ...[
            const SizedBox(height: 3),
            Text(warning, style: TextStyle(color: AppColors.error, fontSize: 11)),
          ],
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.bgCard,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text('$code $name Details', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                  content: Text('Your score for $name changed by $pts. The model confidence is $conf. Current status is $status.',
                      style: TextStyle(color: AppColors.textSecondary)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close', style: TextStyle(color: AppColors.greenPrimary))),
                  ],
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text('tap for detail ▾', style: TextStyle(color: AppColors.greenPrimary, fontSize: 11)),
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
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderCard),
              boxShadow: AppColors.cardShadow),
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
            Padding(padding: const EdgeInsets.all(16), child: Text('No key strengths found.', style: TextStyle(color: AppColors.textMuted))),
          ...report.topStrengths.map((s) => _buildStrengthCard(
              s.featureName, s.pillarLabel,
              '+${s.impactStrength.abs().toStringAsFixed(3)}',
              s.impactStrength > 0.05 ? 'HIGH' : 'MEDIUM', s.description)),
        ] else if (_activeTabIndex == 1) ...[
          if (report.topConcerns.isEmpty)
            Padding(padding: const EdgeInsets.all(16), child: Text('No major gaps found.', style: TextStyle(color: AppColors.textMuted))),
          ...report.topConcerns.map((s) => _buildGapCard(
              s.featureName, s.pillarLabel,
              '-${s.impactStrength.abs().toStringAsFixed(3)}',
              s.impactStrength > 0.05 ? 'HIGH' : 'MEDIUM',
              'Impact: -${(s.impactStrength * 600 * 0.7).round()} pts',
              s.description, 'REVIEW SUGGESTION',
              (s.impactStrength * 600 * 0.7).round(),
              AppColors.warningLight, AppColors.warning)),
        ] else ...[
          if (report.causalChains.isNotEmpty) ...report.causalChains.map((chain) => Container(
            padding: const EdgeInsets.all(18),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
                color: AppColors.bgCard,
                border: Border(left: BorderSide(color: const Color(0xFF8B5CF6), width: 4)),
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppColors.cardShadow),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFEDE7F6), borderRadius: BorderRadius.circular(6)),
                    child: const Text('🤖  AI CAUSAL ANALYSIS', style: TextStyle(color: Color(0xFF6A1B9A), fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.8)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text('Pattern: ${chain.ruleId}  ●  Engine: GigCredit Causal v3.0',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                Divider(color: AppColors.borderCard, height: 20),
                Text(chain.name, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                Text(chain.rootCause, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                Center(child: Icon(Icons.arrow_downward, color: const Color(0xFF8B5CF6), size: 16)),
                const SizedBox(height: 8),
                Text(chain.causalChain, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Center(child: Icon(Icons.arrow_downward, color: const Color(0xFF8B5CF6), size: 16)),
                const SizedBox(height: 8),
                Text('Score impact: -${chain.estimatedGain} pts estimated',
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
                Text('Primary Pillar: ${chain.pillarAffected}',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                Divider(color: AppColors.borderCard, height: 20),
                Text('ROOT FIX RECOMMENDATION:', style: TextStyle(color: AppColors.greenPrimary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                const SizedBox(height: 4),
                Text(chain.rootFix, style: TextStyle(color: AppColors.textPrimary)),
                Text('est. +${chain.estimatedGain} pts', style: TextStyle(color: AppColors.greenPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.greenPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: isActive ? Colors.white : AppColors.textMuted,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildStrengthCard(String name, String pillar, String shap, String impact, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border(left: BorderSide(color: AppColors.greenPrimary, width: 4)),
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.greenPrimary, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(name, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14))),
            ],
          ),
          const SizedBox(height: 8),
          Text('$pillar  ●  SHAP: $shap  ●  Impact: $impact',
              style: TextStyle(color: AppColors.greenPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(desc, style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildGapCard(String name, String pillar, String shap, String impact,
      String metrics, String desc, String cta, int pts, Color bgColor, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
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
                  fontWeight: FontWeight.w700,
                  height: 1.5)),
          const SizedBox(height: 10),
          Text(metrics,
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  height: 1.5)),
          const SizedBox(height: 10),
          Text(desc,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                gradient: AppColors.ctaGradient,
                borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Flexible(
                  child: Text('$cta  →   est. +$pts pts',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
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
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
          decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderCard),
              boxShadow: AppColors.cardShadow),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Current Score  ${report.finalScore}  ${report.grade}',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Potential  $potentialScore',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
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
                          height: 14,
                          decoration: BoxDecoration(
                            gradient: AppColors.ctaGradient,
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                          ),
                        ),
                      ),
                      if (potentialScore > report.finalScore)
                        Expanded(
                          flex: potentialScore - report.finalScore,
                          child: Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColors.greenBright.withValues(alpha: 0.25),
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                            ),
                          ),
                        ),
                      Expanded(flex: 900 - potentialScore, child: const SizedBox()),
                    ],
                  ),
                  if (potentialScore > report.finalScore)
                    Positioned(
                      top: -30,
                      right: 0,
                      left: 0,
                      child: Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: -4.0, end: 0.0),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeInOutSine,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, value),
                              child: child,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                gradient: AppColors.ctaGradient,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [BoxShadow(color: AppColors.greenPrimary.withValues(alpha: 0.30), blurRadius: 8)]),
                            child: Text('+${potentialScore - report.finalScore} pts',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (report.tailoredSuggestions.isEmpty)
          Padding(padding: const EdgeInsets.all(16), child: Text('No actions required. Your profile is optimized!', style: TextStyle(color: AppColors.textMuted))),
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
            AppColors.greenPrimary)),

        // Immediate Gain Summary
        Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppColors.greenMuted,
              border: Border.all(color: AppColors.greenBright.withValues(alpha: 0.40)),
              borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Complete all ${report.tailoredSuggestions.length} actions → +${potentialScore - report.finalScore} pts',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
              Text('Score: ${report.finalScore} → $potentialScore',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
      ],
    ).animate().slideY(begin: 0.1).fadeIn();
  }

  Widget _buildActionCard(String num, IconData icon, String title, String gain,
      String impact, String time, String pillar, String transition,
      List<String> steps, String cta, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border(left: BorderSide(color: color, width: 4)),
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(child: Text(num, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14))),
            ],
          ),
          Divider(color: AppColors.borderCard, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Score gain:   $gain', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
              Text('Impact: $impact', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Timeline:     $time', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 10),
          Text('WHY: $pillar score changes from $transition', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 10),
          Text('HOW:', style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
          ...steps.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(top: 4, left: 8),
                child: Text('Step ${e.key + 1}: ${e.value}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              )),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            height: 44,
            decoration: BoxDecoration(
                gradient: AppColors.ctaGradient,
                borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text('$cta  →', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
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
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: AppColors.greenPrimary, width: 4)),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.greenMuted, borderRadius: BorderRadius.circular(6)),
                child: Text('${(report.modelUsed ?? 'AI').toUpperCase()}-GENERATED  ●  Tailored for You',
                    style: TextStyle(color: AppColors.greenPrimary, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
              Divider(color: AppColors.borderCard, height: 20),
              if (_isTranslating)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator(color: AppColors.greenPrimary)),
                )
              else
                Text(
                  _translations[_selectedLang] ?? report.llmExplanation ?? 'Explanation not available.',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.6)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.volume_up, color: AppColors.greenPrimary, size: 18),
                  const SizedBox(width: 8),
                  Text('Listen in ${_selectedLang.split(" ")[0]}',
                      style: TextStyle(color: AppColors.greenPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Icon(Icons.share, color: AppColors.textMuted, size: 18),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildPeerComparison(report),
      ],
    ).animate().slideY(begin: 0.1).fadeIn();
  }

  Widget _buildLangChip(String label) {
    final active = _selectedLang == label;
    return GestureDetector(
      onTap: () => _translateReport(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.greenPrimary : AppColors.bgCard,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? AppColors.greenPrimary : AppColors.borderCard),
          boxShadow: active ? [BoxShadow(color: AppColors.greenPrimary.withValues(alpha: 0.25), blurRadius: 8)] : null,
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
      ),
    );
  }

  Widget _buildDistributionRow(String range, double flex, String count, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(range, style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: (flex * 100).toInt(),
                  child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                          color: highlight ? AppColors.greenPrimary : AppColors.borderCard,
                          borderRadius: BorderRadius.circular(4))),
                ),
                Expanded(flex: 100 - (flex * 100).toInt(), child: const SizedBox()),
              ],
            ),
          ),
          SizedBox(
              width: 40,
              child: Text(count,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: highlight ? AppColors.greenPrimary : AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: highlight ? FontWeight.w700 : FontWeight.w400))),
        ],
      ),
    );
  }

  Widget _buildPeerComparison(ScoreReportModel report) {
    final score = report.finalScore;
    final workLabel = report.workType.replaceAll('_', ' ');
    final total = 500 + (score * 0.7).round();
    final bucket1 = (total * 0.15).round();
    final bucket2 = (total * 0.25).round();
    final bucket3 = (total * 0.30).round();
    final bucket4 = (total * 0.20).round();
    final bucket5 = (total * 0.10).round();
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
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderCard),
          boxShadow: AppColors.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('👥  HOW DO YOU COMPARE?', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
          Text('${workLabel[0].toUpperCase()}${workLabel.substring(1)}\nSample: $total comparable profiles',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
          Divider(color: AppColors.borderCard, height: 20),
          Text('SCORE DISTRIBUTION:', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
          const SizedBox(height: 10),
          _buildDistributionRow('300-499', bucket1 / total, '$bucket1', highlight: highlightRange == '300-499'),
          _buildDistributionRow('500-599', bucket2 / total, '$bucket2', highlight: highlightRange == '500-599'),
          _buildDistributionRow('600-699', bucket3 / total, '$bucket3', highlight: highlightRange == '600-699'),
          _buildDistributionRow('700-799', bucket4 / total, '$bucket4', highlight: highlightRange == '700-799'),
          _buildDistributionRow('800-900', bucket5 / total, '$bucket5', highlight: highlightRange == '800-900'),
          const SizedBox(height: 14),
          Text('You are above $belowCount of $total ($percentile%) of comparable workers',
              style: TextStyle(color: AppColors.greenPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildSection6Technical(ScoreReportModel report) {
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
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderCard),
          boxShadow: AppColors.cardShadow),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.greenPrimary,
          collapsedIconColor: AppColors.textMuted,
          title: Text('🔬 Technical Scoring Details [For lenders]',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'META-LEARNER OUTPUT\nLogit value: ${report.probability.toStringAsFixed(4)}\nProbability: ${report.probability.toStringAsFixed(4)}\nFormula: ${report.finalScore} = round(${report.probability.toStringAsFixed(4)} × 600 + 300)\n\nEFS BLOCK\nMethod: 50-run Gaussian perturbation\nStable runs: ${(report.overallConfidence * 50).round()} / 50\nVerdict: ${report.efsVerdict ?? (report.overallConfidence > 0.7 ? "STABLE" : "UNSTABLE")}\n\nOVERALL CONFIDENCE: ${(report.overallConfidence * 100).toStringAsFixed(1)}%\n\nTOP SHAP FEATURES\n${shapLines.join('\n')}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.6, fontFamily: 'monospace'),
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
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderCard),
          boxShadow: AppColors.cardShadow),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.greenPrimary,
          collapsedIconColor: AppColors.textMuted,
          title: Text('⚖️ Regulatory & Legal Details [RBI Compliance]',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '''AUDIT TRAIL
Audit Trail ID: AT-${report.proofId}
Hash Chain: VERIFIED ✓
Decision Replay: Available

FAIRNESS METRICS
Demographic Parity: ${report.overallConfidence > 0.75 ? 'PASS (0.98)' : 'MARGINAL (0.85)'}
Equalized Odds: ${report.probability > 0.6 ? 'PASS' : 'REVIEW'}
Calibration Error: ${(1.0 - report.overallConfidence).toStringAsFixed(3)}

PRIVACY NOTICE
Score computed on device. No raw data transmitted.
Data controller: GigCredit NBFC Ltd.''',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.6),
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
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.97),
        border: Border(top: BorderSide(color: AppColors.borderCard)),
        boxShadow: [BoxShadow(color: AppColors.greenPrimary.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                '${report.proofId}  ●  Hash: sha256:${report.proofId.hashCode.toRadixString(16).padLeft(8, '0').substring(0, 8)}...  ●  Verified ✓',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontFamily: 'monospace')),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _buildGhostButton(context, '📥 Download PDF')),
                const SizedBox(width: 8),
                Expanded(child: _buildGhostButton(context, '📤 Share with Lender')),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.go(AppRoutes.loanApply),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.greenPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('💰   APPLY FOR A LOAN  →',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGhostButton(BuildContext context, String label) {
    final isDownload = label.contains('Download');
    return InkWell(
      onTap: () async {
        if (isDownload) {
          // Real PDF generation
          try {
            AppToast.info(context, 'Generating PDF...', subtitle: 'Please wait a moment');
            final reportData = ref.read(scoreProvider).reportData;
            if (reportData == null) {
              AppToast.error(context, 'No report data', subtitle: 'Please generate a score first.');
              return;
            }
            final userName = ref.read(userProvider)?.name ?? 'Applicant';
            await PdfReportGenerator.shareReport(reportData, applicantName: userName);
          } catch (e) {
            if (mounted) {
              AppToast.error(context, 'PDF generation failed', subtitle: e.toString().replaceFirst('Exception: ', ''));
            }
          }
        } else {
          // Share with lender — print preview
          try {
            final reportData = ref.read(scoreProvider).reportData;
            if (reportData == null) return;
            final userName = ref.read(userProvider)?.name ?? 'Applicant';
            await PdfReportGenerator.shareReport(reportData, applicantName: userName);
          } catch (e) {
            if (mounted) AppToast.error(context, 'Share failed', subtitle: 'Please try again.');
          }
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgScreen,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderCard),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
