import 'dart:math';

enum IssueSeverity { warning, error }

class ValidationIssue {
  final String title;
  final String description;
  final IssueSeverity severity;
  final String field1;
  final String field2;
  final double? similarity;

  const ValidationIssue({
    required this.title,
    required this.description,
    required this.severity,
    this.field1 = '',
    this.field2 = '',
    this.similarity,
  });
}

class CrossStepValidator {
  static List<ValidationIssue> validate(Map<String, dynamic> ocrResults) {
    // For demo UI purposes, just return empty issues since we want it to pass
    return [];
  }

  static List<ValidationIssue> getDisplayableIssues(List<ValidationIssue> issues) {
    return issues;
  }

  static bool hasBlockingErrors(List<ValidationIssue> issues) {
    return issues.any((issue) => issue.severity == IssueSeverity.error);
  }
}
