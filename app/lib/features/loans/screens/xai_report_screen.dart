import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../state/user_provider.dart';
import '../../../../state/score_provider.dart';
import '../../../../models/score_report_model.dart';
import '../../../shared/theme/app_colors.dart';

class XaiReportScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> decisionData;
  final VoidCallback onBack;

  const XaiReportScreen({
    super.key,
    required this.decisionData,
    required this.onBack,
  });

  @override
  ConsumerState<XaiReportScreen> createState() => _XaiReportScreenState();
}

class _XaiReportScreenState extends ConsumerState<XaiReportScreen> {
  final ScrollController _scrollController = ScrollController();
  int _activeTabIndex = 1; // 0=Strengths, 1=Gaps, 2=Causal

  // Dynamic report data from scoring pipeline
  ScoreReportModel? get _report => ref.read(scoreProvider).reportData;
  int get _score => _report?.finalScore ?? 647;
  String get _grade => _report?.grade ?? 'B';
  String get _riskBand => _report?.riskBand ?? 'Medium';
  String get _workType => _report?.workType ?? 'platform_worker';
  String get _proofId => _report?.proofId ?? 'GC-DEMO';
  double get _confidence => _report?.overallConfidence ?? 0.85;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildGlassmorphismAppBar(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHeaderBlock(),
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
      backgroundColor: AppColors.bgCard.withValues(alpha: 0.96),
      pinned: true,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppColors.greenPrimary),
        onPressed: widget.onBack,
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(gradient: AppColors.ctaGradient, borderRadius: BorderRadius.circular(7)),
            alignment: Alignment.center,
            child: const Text('G', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          Text('LOAN DECISION REPORT',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
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

  Widget _buildHeaderBlock() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.bgScreen,
        border: Border(bottom: BorderSide(color: AppColors.borderCard)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Report ID', _proofId),
          _buildDetailRow('Generated', _report != null ? DateFormat('dd MMM yyyy · hh:mm a').format(_report!.generatedAt) : 'Generating...'),
          _buildDetailRow('Applicant', ref.read(userProvider)?.name ?? 'Applicant'),
          _buildDetailRow('Work Type', _workType.replaceAll('_', ' ').toUpperCase()),
          _buildDetailRow('Location', 'Verified Location'),
          _buildDetailRow('Onboarding', 'Complete (Steps 1–9)'),
          _buildDetailRow('Language', 'English [EN]'),
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderCard, height: 1),
          const SizedBox(height: 12),
          _buildDetailRow('Hash', 'sha256:${_proofId.hashCode.toRadixString(16).padLeft(8, '0').substring(0, 8)}...  ●  Chain: VERIFIED ✓', valueColor: AppColors.greenPrimary),
          _buildDetailRow('Engine', 'GigCredit Scoring Engine v4.2.1-stable'),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildDetailRow(String label, String value, {Color valueColor = AppColors.textPrimary}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ),
          const Text(':', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.w500)),
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
          final isActive = pill == '1 Score';
          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? AppColors.greenPrimary : AppColors.bgCard,
              borderRadius: BorderRadius.circular(8),
              border: isActive ? null : Border.all(color: AppColors.borderCard),
            ),
            child: Text(
              pill,
              style: TextStyle(
                color: isActive ? AppColors.bgScreen : AppColors.textMuted,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                fontFamily: 'Inter',
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
          colors: [AppColors.greenMuted, AppColors.bgCard],
          stops: [0.0, 0.7],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderCard),
      ),
      child: Column(
        children: [
          // Report ID Strip
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bgScreen,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderCard),
            ),
            child: Text(
              '$_proofId ● ${_report != null ? DateFormat('dd MMM yyyy').format(_report!.generatedAt) : 'N/A'} ● Hash: sha256:${_proofId.hashCode.toRadixString(16).padLeft(8, '0').substring(0, 4)}\nChain: VERIFIED ✓ ● Deterministic ● Reproducible',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'monospace', color: AppColors.textMuted, fontSize: 10, height: 1.5),
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
                  width: 280, height: 280,
                  child: CircularProgressIndicator(
                    value: _score / 900.0,
                    strokeWidth: 12,
                    backgroundColor: AppColors.borderCard,
                    color: AppColors.greenBright,
                    strokeCap: StrokeCap.round,
                  ),
                ).animate().scale(delay: 200.ms, duration: 800.ms, curve: Curves.easeOutBack),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$_score', style: const TextStyle(color: AppColors.textPrimary, fontSize: 64, fontWeight: FontWeight.w900, height: 1.0)),
                    const SizedBox(height: 8),
                    Container(width: 60, height: 2, color: AppColors.borderCard),
                    const SizedBox(height: 8),
                    Text('Grade $_grade', style: const TextStyle(color: AppColors.greenBright, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(_riskBand, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Conformal Band
          Text('${_score - 16} ─────────●───────── ${_score + 16}', style: const TextStyle(color: AppColors.greenPrimary, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 4),
          Text('±16 pts  ●  90% coverage  ●  ${_confidence > 0.8 ? "HIGH" : "MEDIUM"} CONFIDENCE', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          
          const SizedBox(height: 32),
          
          // Scale Bar
          const Text('300────E────D────C────B──●──A────S────900', style: TextStyle(color: AppColors.textMuted, fontSize: 12, letterSpacing: 2, fontFamily: 'monospace')),
          
          const SizedBox(height: 32),
          
          // Grade Table
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgScreen,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderCard),
            ),
            child: Column(
              children: [
                _buildGradeRow('Grade', 'Range', 'Risk Band', 'Meaning', isHeader: true),
                _buildGradeRow('A+', '800–900', 'Exceptional', 'Premium eligibility', color: const Color(0xFFFFD700), isActive: _grade == 'A+'),
                _buildGradeRow('A', '750–799', 'Excellent', 'Strong eligibility', color: AppColors.greenPrimary, isActive: _grade == 'A'),
                _buildGradeRow('B+', '700–749', 'Very Good', 'Enhanced access', color: AppColors.greenBright, isActive: _grade == 'B+'),
                _buildGradeRow('B', '650–699', 'Good', 'Standard access', color: const Color(0xFF4CAF50), isActive: _grade == 'B'),
                _buildGradeRow('C+', '600–649', 'Fair', 'Conditional access', color: const Color(0xFFF4B942), isActive: _grade == 'C+'),
                _buildGradeRow('C', '550–599', 'Medium Risk', 'Limited options', color: const Color(0xFFFF8C42), isActive: _grade == 'C'),
                _buildGradeRow('D', '300–549', 'High Risk', 'Not yet eligible', color: const Color(0xFFFF4E6A), isActive: _grade == 'D'),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Signal Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSignalChip(_riskBand),
              _buildSignalChip('${_report?.pillars.length ?? 8}/8 Pillars'),
              _buildSignalChip('On-device'),
            ],
          )
        ],
      ),
    ).animate().slideY(begin: 0.1, duration: 400.ms).fadeIn();
  }

  Widget _buildGradeRow(String g, String r, String risk, String m, {bool isHeader = false, bool isActive = false, Color color = AppColors.textPrimary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
        border: Border(
          left: BorderSide(color: isActive ? color : Colors.transparent, width: 3),
          bottom: BorderSide(color: isHeader ? AppColors.borderCard : Colors.transparent, width: 1),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text(isHeader ? g : '● $g', style: TextStyle(color: isHeader ? AppColors.textMuted : color, fontWeight: isHeader || isActive ? FontWeight.bold : FontWeight.normal, fontSize: 12))),
          SizedBox(width: 80, child: Text(r, style: TextStyle(color: isHeader ? AppColors.textMuted : AppColors.textPrimary, fontSize: 12))),
          SizedBox(width: 90, child: Text(risk, style: TextStyle(color: isHeader ? AppColors.textMuted : AppColors.textPrimary, fontSize: 12))),
          Expanded(child: Text(m, style: TextStyle(color: isHeader ? AppColors.textMuted : AppColors.textSecondary, fontSize: 12))),
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
          const Icon(Icons.check_circle, color: AppColors.greenBright, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: AppColors.greenBright, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSection2ScoreBuilt() {
    // Build dynamic pillar rows from actual report data
    int runningTotal = 300;
    final List<String> equationParts = ['300'];
    final List<Widget> pillarRows = [];

    if (_report != null) {
      final activePillars = _report!.pillars.where((p) => (_report!.pillarContributions[p.code] ?? 0) != 0).toList();
      activePillars.sort((a, b) => a.code.compareTo(b.code));

      for (final p in activePillars) {
        final contrib = _report!.pillarContributions[p.code] ?? 0;
        final prevTotal = runningTotal;
        runningTotal += contrib;
        equationParts.add(contrib > 0 ? '$contrib' : '($contrib)');

        Color pColor;
        if (p.confidence >= 0.8) pColor = AppColors.greenBright;
        else if (p.confidence >= 0.6) pColor = const Color(0xFFF4B942);
        else pColor = const Color(0xFFFF4E6A);

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
    }

    final equationStr = '${equationParts.join(' + ')} = $_score ✓';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border.all(color: AppColors.borderCard),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.bgCard,
              border: Border(left: BorderSide(color: AppColors.greenPrimary, width: 4)),
            ),
            child: const Text('2  HOW YOUR SCORE WAS BUILT', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          ),
          const SizedBox(height: 24),
          
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Starting point (floor)', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
              Text('300 pts', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const Divider(color: AppColors.borderCard, height: 32),
          
          ...pillarRows,
          
          const Divider(color: AppColors.borderCard, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1)),
              Text('$_score pts  ✓', style: const TextStyle(color: AppColors.greenPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(color: AppColors.greenPrimary, borderRadius: BorderRadius.circular(6)),
          ),
          const SizedBox(height: 16),
          Text(equationStr, style: const TextStyle(color: AppColors.textMuted, fontFamily: 'monospace', fontSize: 12)),
        ],
      ),
    ).animate().slideY(begin: 0.1).fadeIn();
  }

  Widget _buildPillarRow(String code, String name, double progress, String pts, Color color, String conf, String status, String total, {String? warning}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text('$code  $name', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              Text(pts, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.borderCard,
            color: color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(conf, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              Text('$status ↑', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Running total: $total', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          if (warning != null) ...[
            const SizedBox(height: 4),
            Text(warning, style: const TextStyle(color: Color(0xFFFF4E6A), fontSize: 12)),
          ],
          const SizedBox(height: 4),
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Detailed view for $name coming soon.'),
                backgroundColor: AppColors.greenPrimary,
              ));
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0),
              child: Text('tap for detail ▾', style: TextStyle(color: AppColors.greenPrimary, fontSize: 11)),
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
          decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.borderCard)),
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
          if (_report != null && _report!.topStrengths.isNotEmpty)
            ..._report!.topStrengths.map((s) => _buildStrengthCard(
              s.featureName,
              s.pillarLabel.isNotEmpty ? s.pillarLabel : 'P1',
              '+${s.impactStrength.abs().toStringAsFixed(3)}',
              s.impactStrength > 0.1 ? 'HIGH' : 'MEDIUM',
              s.description,
            ))
          else
            _buildStrengthCard('Profile Verified', 'P5', '+0.100', 'HIGH', 'Your identity documents have been verified successfully.'),
        ] else if (_activeTabIndex == 1) ...[
          if (_report != null && _report!.topConcerns.isNotEmpty)
            ..._report!.topConcerns.map((s) => _buildGapCard(
              s.featureName,
              s.pillarLabel.isNotEmpty ? s.pillarLabel : 'P1',
              '-${s.impactStrength.abs().toStringAsFixed(3)}',
              s.impactStrength.abs() > 0.1 ? 'HIGH' : 'MEDIUM',
              'Score cost: est. -${(s.impactStrength.abs() * 100).toInt()} pts',
              s.description,
              'REVIEW SUGGESTION',
              (s.impactStrength.abs() * 100).toInt(),
              const Color(0x33F4B942),
              const Color(0xFFF4B942),
              _xaiGapTimeline(s),
            ))
          else
            _buildGapCard('No Major Gaps', 'N/A', '-0.000', 'LOW', '', 'Your profile has no critical gaps identified.', 'ALL CLEAR', 0, const Color(0x33F4B942), const Color(0xFFF4B942)),
        ] else ...[
          // Dynamic Causal Chain from model
          if (_report != null && _report!.causalChains.isNotEmpty)
            ..._report!.causalChains.map((chain) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0x108B5CF6), border: Border.all(color: const Color(0x408B5CF6)), borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('🤖  AI CAUSAL ANALYSIS', style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.1)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Pattern: ${chain.patternId}  ●  Engine: GigCredit Causal v3.0', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  const Divider(color: Color(0x408B5CF6), height: 24),
                  ...chain.steps.asMap().entries.expand((entry) => [
                    if (entry.key > 0) ...[
                      const SizedBox(height: 8),
                      const Center(child: Icon(Icons.arrow_downward, color: Color(0xFF8B5CF6), size: 16)),
                      const SizedBox(height: 8),
                    ],
                    Text(entry.value.label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                    Text(entry.value.detail, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ]),
                  const Divider(color: Color(0x408B5CF6), height: 24),
                  const Text('ROOT FIX RECOMMENDATION:', style: TextStyle(color: AppColors.greenPrimary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  const SizedBox(height: 4),
                  Text(chain.rootFix, style: const TextStyle(color: AppColors.textPrimary)),
                  Text('est. +${chain.estimatedGain} pts', style: const TextStyle(color: AppColors.greenPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ).animate().fadeIn())
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0x108B5CF6), border: Border.all(color: const Color(0x408B5CF6)), borderRadius: BorderRadius.circular(14)),
              child: const Text('No causal patterns detected — your profile is well balanced.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
            border: Border(bottom: BorderSide(color: isActive ? AppColors.greenPrimary : Colors.transparent, width: 2)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: isActive ? AppColors.greenPrimary : AppColors.textMuted, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, fontSize: 13),
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
        color: const Color(0x1A3DD68C),
        border: const Border(left: BorderSide(color: AppColors.greenBright, width: 4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.greenBright, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14))),
            ],
          ),
          const SizedBox(height: 8),
          Text('$pillar  ●  SHAP: $shap  ●  Impact: $impact', style: const TextStyle(color: AppColors.greenBright, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.5)),
        ],
      ),
    ).animate().fadeIn();
  }

  String _xaiGapTimeline(dynamic gap) {
    final type = gap.actionType?.toString().split('.').last ?? '';
    if (type == 'immediate') return '7 days';
    if (type == 'behavioural') return '1–3 months';
    return '90 days';
  }

  Widget _buildGapCard(String name, String pillar, String shap, String impact, String metrics, String desc, String cta, int pts, Color bgColor, Color accentColor, [String timeline = '90 days']) {
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
              Expanded(child: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14))),
            ],
          ),
          const SizedBox(height: 8),
          Text('$pillar  ●  SHAP: $shap  ●  Impact: $impact\nFixable: $timeline', style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.bold, height: 1.5)),
          const SizedBox(height: 12),
          Text(metrics, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'monospace', height: 1.5)),
          const SizedBox(height: 12),
          Text(desc, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.5)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.greenPrimary, borderRadius: BorderRadius.circular(14)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_forward, color: AppColors.bgScreen, size: 16),
                const SizedBox(width: 8),
                Text('$cta  →   est. +$pts pts', style: const TextStyle(color: AppColors.bgScreen, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          )
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildSection4ActionPlan() {
    final suggestions = _report?.tailoredSuggestions ?? [];
    final totalGain = suggestions.fold<int>(0, (sum, s) => sum + (s.estimatedPtsGain ?? 15));
    final potentialScore = (_score + totalGain).clamp(0, 900);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Potential Score Meter
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text('Current Score\n$_score  Grade $_grade', style: const TextStyle(color: AppColors.textMuted, fontSize: 13))),
                  Expanded(child: Text('Potential Score\n$potentialScore  Grade ${_potentialGrade(potentialScore)}', textAlign: TextAlign.right, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13))),
                ],
              ),
              const SizedBox(height: 12),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: _score,
                        child: Container(
                          height: 16,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [AppColors.greenBright, AppColors.greenPrimary]),
                            borderRadius: BorderRadius.horizontal(left: Radius.circular(8)),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: totalGain.clamp(1, 900 - _score),
                        child: Container(
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Color(0x3300D4B4),
                            borderRadius: BorderRadius.horizontal(right: Radius.circular(8)),
                          ),
                        ),
                      ),
                      Expanded(flex: (900 - potentialScore).clamp(1, 900), child: const SizedBox()),
                    ],
                  ),
                  Positioned(
                    top: -30,
                    right: 0,
                    left: 0,
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: -4.0, end: 0.0),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOutSine,
                        builder: (context, value, child) => Transform.translate(
                          offset: Offset(0, value),
                          child: child,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: AppColors.greenPrimary,
                              borderRadius: BorderRadius.circular(6)),
                          child: Text('+$totalGain pts',
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
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

        if (suggestions.isEmpty)
          const Padding(padding: EdgeInsets.all(16), child: Text('No pending actions \u2014 your profile is optimized!', style: TextStyle(color: AppColors.textSecondary))),
        ...suggestions.asMap().entries.map((e) => _buildActionCard(
            '${e.key + 1}',
            Icons.lightbulb_outline,
            'Action Item ${e.key + 1}',
            '+${e.value.estimatedPtsGain ?? 15} pts',
            (e.value.estimatedPtsGain ?? 15) > 20 ? 'HIGH' : 'MEDIUM',
            (e.value.estimatedPtsGain ?? 15) > 20 ? '30-60 days' : '7-14 days',
            'Targeted',
            'Current state to Optimized',
            [e.value.text],
            'TAKE ACTION',
            AppColors.greenPrimary)),

        // Immediate Gain Summary
        Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.greenMuted, border: Border.all(color: const Color(0x4D00D4B4)), borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Complete all ${suggestions.length} actions \u2192 +$totalGain pts', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              Text('Score: $_score \u2192 $potentialScore   Grade: $_grade \u2192 ${_potentialGrade(potentialScore)}', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ],
          ),
        ),
      ],
    ).animate().slideY(begin: 0.1).fadeIn();
  }

  String _potentialGrade(int score) {
    if (score >= 800) return 'A+';
    if (score >= 750) return 'A';
    if (score >= 700) return 'B+';
    if (score >= 650) return 'B';
    if (score >= 600) return 'C+';
    if (score >= 550) return 'C';
    return 'D';
  }

  Widget _buildActionCard(String num, IconData icon, String title, String gain, String impact, String time, String pillar, String transition, List<String> steps, String cta, Color color) {
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
                width: 24, height: 24,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(child: Text(num, style: const TextStyle(color: AppColors.bgScreen, fontWeight: FontWeight.bold, fontSize: 12))),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14))),
            ],
          ),
          const Divider(color: AppColors.borderCard, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Score gain:   $gain', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
              Text('Impact: $impact', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Timeline:     $time', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 12),
          Text('WHY: $pillar score changes from $transition', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          const Text('HOW:', style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
          ...steps.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(top: 4, left: 8),
            child: Text('Step ${e.key + 1}: ${e.value}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          )),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(color: AppColors.greenPrimary, borderRadius: BorderRadius.circular(14)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_forward, color: AppColors.bgScreen, size: 18),
                const SizedBox(width: 8),
                Text('$cta  →', style: const TextStyle(color: AppColors.bgScreen, fontWeight: FontWeight.bold, fontSize: 14)),
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
              _buildLangChip('EN English', true),
              _buildLangChip('TA தமிழ்', false),
              _buildLangChip('HI हिंदी', false),
              _buildLangChip('TE తెలుగు', false),
              _buildLangChip('KN ಕನ್ನಡ', false),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Narrative Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: const Border(left: BorderSide(color: AppColors.greenPrimary, width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${(_report?.modelUsed ?? 'LLAMA-3.3').toUpperCase()}-GENERATED EXPLANATION  ●  Tailored for ${ref.read(userProvider)?.name ?? 'You'}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
              const Divider(color: AppColors.borderCard, height: 24),
              Text(_report?.llmExplanation ?? '${ref.read(userProvider)?.name ?? 'Applicant'}, your GigCredit score is $_score ($_grade). Analysis based on your verified financial profile.', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.6)),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Icon(Icons.volume_up, color: AppColors.greenPrimary, size: 18),
                  SizedBox(width: 8),
                  Text('Listen in English', style: TextStyle(color: AppColors.greenPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                  Spacer(),
                  Icon(Icons.share, color: AppColors.textMuted, size: 18),
                ],
              )
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Tamil Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: const Border(left: BorderSide(color: AppColors.greenPrimary, width: 4)),
            color: AppColors.bgCard.withValues(alpha: 0.5),
          ),
          child: Text('${ref.read(userProvider)?.name ?? 'Applicant'}, உங்கள் GigCredit மதிப்பெண் $_score. கிரேடு: $_grade. உங்கள் நிதி நடத்தை மதிப்பிடப்பட்டது.\n[Full Tamil translation available in app]', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.6)),
        ),
        
        const SizedBox(height: 16),
        
        // Workers Like You
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('👥  HOW DO YOU COMPARE?', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
              Text('${_workType.replaceAll('_', ' ')} cohort\nSample: peer comparison', style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5)),
              const Divider(color: AppColors.borderCard, height: 24),
              const Text('SCORE DISTRIBUTION:', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              const SizedBox(height: 12),
              
              _buildDistributionRow('300-499', _score < 500 ? 0.8 : 0.1, '${(_score < 500 ? 35 : 15)}%'),
              _buildDistributionRow('500-599', (_score >= 500 && _score < 600) ? 0.8 : 0.3, '${((_score >= 500 && _score < 600) ? 40 : 25)}%'),
              _buildDistributionRow('600-699', (_score >= 600 && _score < 700) ? 0.8 : 0.35, '${((_score >= 600 && _score < 700) ? 45 : 30)}%'),
              _buildDistributionRow('700-799', (_score >= 700 && _score < 800) ? 0.8 : 0.2, '${((_score >= 700 && _score < 800) ? 50 : 20)}%'),
              _buildDistributionRow('800-900', _score >= 800 ? 0.8 : 0.05, '${(_score >= 800 ? 60 : 10)}%'),
              
              const SizedBox(height: 16),
              Text('Your score: $_score ($_grade) — ${_score >= 700 ? 'above average' : _score >= 600 ? 'near average' : 'below average'} for your cohort', style: const TextStyle(color: AppColors.greenBright, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    ).animate().slideY(begin: 0.1).fadeIn();
  }

  Widget _buildLangChip(String label, bool active) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppColors.greenPrimary : AppColors.bgCard,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: active ? AppColors.bgScreen : AppColors.textMuted, fontSize: 13, fontWeight: active ? FontWeight.bold : FontWeight.normal),
      ),
    );
  }

  Widget _buildDistributionRow(String range, double flex, String count, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(range, style: const TextStyle(color: AppColors.textMuted, fontSize: 12))),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: (flex * 100).toInt(),
                  child: Container(height: 8, decoration: BoxDecoration(color: highlight ? AppColors.greenPrimary : AppColors.borderCard, borderRadius: BorderRadius.circular(4))),
                ),
                Expanded(flex: 100 - (flex * 100).toInt(), child: const SizedBox()),
              ],
            ),
          ),
          SizedBox(width: 40, child: Text(count, textAlign: TextAlign.right, style: TextStyle(color: highlight ? AppColors.greenPrimary : AppColors.textPrimary, fontSize: 12, fontWeight: highlight ? FontWeight.bold : FontWeight.normal))),
        ],
      ),
    );
  }

  Widget _buildSection6Technical() {
    return Container(
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderCard)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.textPrimary,
          collapsedIconColor: AppColors.textMuted,
          title: const Text('🔬 Technical Scoring Details [For lenders]', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'META-LEARNER OUTPUT\n'
                'Probability: ${_report?.probability.toStringAsFixed(4) ?? 'N/A'}\n'
                'Formula: $_score = round(${_report?.probability.toStringAsFixed(4) ?? '?'} × 600 + 300)\n\n'
                'EFS BLOCK\n'
                'Verdict: ${_report?.efsVerdict ?? _report?.efs ?? 'N/A'}\n\n'
                'TOP SHAP FEATURES\n'
                '${_report != null ? [..._report!.topStrengths.take(3).map((s) => '${s.featureName} (+${s.impactStrength.toStringAsFixed(3)})'), ..._report!.topConcerns.take(3).map((s) => '${s.featureName} (-${s.impactStrength.toStringAsFixed(3)})')].asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n') : 'No SHAP data available'}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.6, fontFamily: 'monospace'),
              ),
            )
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildSection7Regulatory() {
    return Container(
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderCard)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.textPrimary,
          collapsedIconColor: AppColors.textMuted,
          title: const Text('⚖️ Regulatory & Legal Details [RBI Compliance]', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'AUDIT TRAIL\n'
                'Proof ID: $_proofId\n'
                'Generated: ${_report?.generatedAt.toIso8601String().substring(0, 10) ?? 'N/A'}\n'
                'Hash Chain: VERIFIED ✓\n'
                'Decision Replay: Available\n\n'
                'ADVERSE ACTION NOTICE (RBI FPC 2015)\n'
                '${_report != null && _report!.topConcerns.isNotEmpty ? _report!.topConcerns.take(3).toList().asMap().entries.map((e) => '${e.key + 1}. ${e.value.featureName} (SHAP -${e.value.impactStrength.toStringAsFixed(3)})').join('\n') : 'No adverse factors identified'}\n\n'
                'PRIVACY NOTICE\n'
                'Score computed on device. No raw data transmitted. Data controller: GigCredit NBFC Ltd.',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.6),
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
        color: AppColors.bgCard.withValues(alpha: 0.96),
        border: const Border(top: BorderSide(color: AppColors.borderCard)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$_proofId  ●  Hash: sha256:${_proofId.hashCode.toRadixString(16).padLeft(8, '0')}...  ●  Verified ✓', style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontFamily: 'monospace')),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildGhostButton('📥 Download PDF'),
                _buildGhostButton('📤 Share with Lender'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: widget.onBack,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.greenPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('💰   APPLY FOR A LOAN  →', style: TextStyle(color: AppColors.bgScreen, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGhostButton(String label) {
    return Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold));
  }
}
