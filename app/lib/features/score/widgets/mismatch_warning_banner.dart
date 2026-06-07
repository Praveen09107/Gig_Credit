import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../scoring/validation/cross_step_validator.dart';

/// Mismatch Warning Banner — shows identity chain errors with a dismiss button.
/// Each error card has "OK, Fix It" so the user knows what to do.
class MismatchWarningBanner extends StatefulWidget {
  final List<ValidationIssue> issues;
  final VoidCallback? onDismiss;

  const MismatchWarningBanner({
    super.key,
    required this.issues,
    this.onDismiss,
  });

  @override
  State<MismatchWarningBanner> createState() => _MismatchWarningBannerState();
}

class _MismatchWarningBannerState extends State<MismatchWarningBanner> {
  final Set<String> _dismissed = {};

  @override
  Widget build(BuildContext context) {
    final displayable = CrossStepValidator.getDisplayableIssues(widget.issues)
        .where((i) => !_dismissed.contains(i.code))
        .toList();

    if (displayable.isEmpty) return const SizedBox.shrink();

    return Column(
      children: displayable.map((issue) {
        final isError   = issue.severity == IssueSeverity.error;
        final bgColor   = isError ? const Color(0x33F44336) : const Color(0x33FFC107);
        final border    = isError ? AppColors.error : AppColors.warning;
        final icon      = isError ? Icons.error_rounded : Icons.warning_amber_rounded;
        final iconColor = isError ? AppColors.error : AppColors.warning;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border.withOpacity(0.6), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: iconColor, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(issue.title,
                              style: TextStyle(
                                  color: iconColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(issue.description,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),

                // Comparison chips
                if (issue.field1.isNotEmpty && issue.field2.isNotEmpty) ...[
                  const SizedBox(height: 10),
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
                        fontWeight: FontWeight.w500),
                  ),
                ],

                const SizedBox(height: 12),

                // Action row
                Row(
                  children: [
                    if (isError)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'BLOCKS SCORING',
                          style: TextStyle(
                              color: AppColors.error,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5),
                        ),
                      ),
                    const Spacer(),
                    // Dismiss button
                    GestureDetector(
                      onTap: () {
                        setState(() => _dismissed.add(issue.code));
                        widget.onDismiss?.call();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: isError ? AppColors.error : AppColors.warning,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isError ? 'OK, Fix It' : 'Got It',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
      }).toList(),
    );
  }
}

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
        Expanded(child: _chip(label1, value1, color)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.compare_arrows, size: 16, color: color),
        ),
        Expanded(child: _chip(label2, value2, color)),
      ],
    );
  }

  Widget _chip(String label, String value, Color color) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 9, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      );
}
