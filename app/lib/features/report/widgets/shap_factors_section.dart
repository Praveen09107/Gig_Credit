import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../models/shap_factor_model.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';

class ShapFactorsSection extends StatelessWidget {
  final List<ShapFactorModel> strengths;
  final List<ShapFactorModel> concerns;
  const ShapFactorsSection({super.key, required this.strengths, required this.concerns});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What Drives Your Score', style: AppTypography.titleLarge),
        const SizedBox(height: 16),
        Text('Top Strengths', style: AppTypography.labelLarge.copyWith(color: AppColors.gradeA)),
        const SizedBox(height: 8),
        ...strengths.asMap().entries.map((e) => _FactorCard(
          factor: e.value,
          isPositive: true,
          index: e.key,
        )),
        const SizedBox(height: 16),
        Text('Areas to Improve', style: AppTypography.labelLarge.copyWith(color: AppColors.gradeC)),
        const SizedBox(height: 8),
        ...concerns.asMap().entries.map((e) => _FactorCard(
          factor: e.value,
          isPositive: false,
          index: e.key,
        )),
      ],
    );
  }
}

class _FactorCard extends StatelessWidget {
  final ShapFactorModel factor;
  final bool isPositive;
  final int index;
  const _FactorCard({required this.factor, required this.isPositive, required this.index});

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? AppColors.gradeA : AppColors.gradeC;
    final icon = isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(factor.featureName, style: AppTypography.labelLarge),
                const SizedBox(height: 2),
                Text(
                  factor.description,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 100))
        .fadeIn(duration: 400.ms)
        .slideX(begin: isPositive ? -0.1 : 0.1, end: 0);
  }
}
