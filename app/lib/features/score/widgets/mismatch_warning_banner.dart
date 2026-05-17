import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../scoring/validation/cross_step_validator.dart';

/// COMP_30 UI: Mismatch Warning Banner
/// 
/// Renders red/yellow warning cards when cross-step validation
/// detects inconsistencies between documents.
///
/// Usage: Place after document uploads in step screens, or
/// in the review screen (Step 9) before scoring.
class MismatchWarningBanner extends StatelessWidget {
  final List<ValidationIssue> issues;

  const MismatchWarningBanner({super.key, required this.issues});

  @override
  Widget build(BuildContext context) {
    final displayable = CrossStepValidator.getDisplayableIssues(issues);
    if (displayable.isEmpty) return const SizedBox.shrink();

    return Column(
      children: displayable.map((issue) {
        final isError = issue.severity == IssueSeverity.error;
        final bgColor = isError
            ? const Color(0x33F44336)  // red translucent
            : const Color(0x33FFC107); // amber translucent
        final borderColor = isError ? AppColors.error : AppColors.warning;
        final icon = isError ? Icons.error_rounded : Icons.warning_amber_rounded;
        final iconColor = isError ? AppColors.error : AppColors.warning;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor.withOpacity(0.6), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue.title,
                        style: TextStyle(
                          color: iconColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        issue.description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      if (issue.field1.isNotEmpty && issue.field2.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _ComparisonRow(
                          label1: 'Document 1',
                          value1: issue.field1,
                          label2: 'Document 2',
                          value2: issue.field2,
                          isError: isError,
                        ),
                      ],
                      if (issue.similarity != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Match: ${(issue.similarity! * 100).toStringAsFixed(0)}% (need ≥85%)',
                          style: TextStyle(
                            color: iconColor.withOpacity(0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (isError) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'BLOCKS SCORING — Fix before proceeding',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
      }).toList(),
    );
  }
}

/// Side-by-side comparison showing the two mismatched values
class _ComparisonRow extends StatelessWidget {
  final String label1, value1, label2, value2;
  final bool isError;

  const _ComparisonRow({
    required this.label1,
    required this.value1,
    required this.label2,
    required this.value2,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.warning;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label1, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  value1,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.compare_arrows, size: 16, color: color),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label2, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  value2,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
