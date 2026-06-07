import 'package:flutter/material.dart';

/// Reusable inline validation banner for Steps 4-9.
/// Shows blocking errors with "OK, Fix It" dismiss button.
/// Same visual style as MismatchWarningBanner but simpler (no comparison chips).
class StepValidationBanner extends StatefulWidget {
  final List<String> errors;       // blocking errors (red)
  final List<String> warnings;     // soft flags (orange)
  final VoidCallback? onDismiss;

  const StepValidationBanner({
    super.key,
    this.errors = const [],
    this.warnings = const [],
    this.onDismiss,
  });

  bool get hasBlockingErrors => errors.isNotEmpty;

  @override
  State<StepValidationBanner> createState() => _StepValidationBannerState();
}

class _StepValidationBannerState extends State<StepValidationBanner> {
  final Set<String> _dismissed = {};

  @override
  void didUpdateWidget(StepValidationBanner old) {
    super.didUpdateWidget(old);
    // Clear dismissed set when errors change (new validation run)
    if (old.errors != widget.errors || old.warnings != widget.warnings) {
      _dismissed.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final allIssues = [
      ...widget.errors.map((e) => _Issue(e, true)),
      ...widget.warnings.map((w) => _Issue(w, false)),
    ].where((i) => !_dismissed.contains(i.message)).toList();

    if (allIssues.isEmpty) return const SizedBox.shrink();

    return Column(
      children: allIssues.map((issue) {
        final color = issue.isError ? Colors.red : Colors.orange;
        final bgColor = issue.isError ? const Color(0x22F44336) : const Color(0x22FF9800);
        final icon = issue.isError ? Icons.error_rounded : Icons.warning_amber_rounded;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      issue.isError ? 'Validation Failed' : 'Warning',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(issue.message,
                  style: const TextStyle(color: Color(0xFF555555), fontSize: 12, height: 1.4)),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _dismissed.add(issue.message));
                    widget.onDismiss?.call();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      issue.isError ? 'OK, Fix It' : 'Got It',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _Issue {
  final String message;
  final bool isError;
  const _Issue(this.message, this.isError);
}
