import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';

/// GigCredit Score Summary Card — Animated counter + grade/risk badges
class ScoreSummaryCard extends StatefulWidget {
  final int finalScore;
  final String grade;
  final String riskBand;
  const ScoreSummaryCard({
    super.key,
    required this.finalScore,
    required this.grade,
    required this.riskBand,
  });

  @override
  State<ScoreSummaryCard> createState() => _ScoreSummaryCardState();
}

class _ScoreSummaryCardState extends State<ScoreSummaryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _counterAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();
    _counterAnim = Tween<double>(begin: 300, end: widget.finalScore.toDouble())
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _gradeColor => AppColors.gradeColor(widget.grade);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gradeColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: _gradeColor.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Animated counter
          AnimatedBuilder(
            animation: _counterAnim,
            builder: (_, __) => Text(
              _counterAnim.value.toInt().toString(),
              style: AppTypography.displayLarge.copyWith(
                fontSize: 64,
                color: _gradeColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Chip(label: 'Grade ${widget.grade}', color: _gradeColor),
              const SizedBox(width: 12),
              _Chip(label: widget.riskBand, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Score range: 300 – 900',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          // Score bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (widget.finalScore - 300) / 600,
              minHeight: 8,
              backgroundColor: AppColors.borderCard,
              valueColor: AlwaysStoppedAnimation<Color>(_gradeColor),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0);
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: AppTypography.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          )),
    );
  }
}
