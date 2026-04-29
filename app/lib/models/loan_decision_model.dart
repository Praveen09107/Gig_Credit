enum LoanDecisionStatus { approved, conditionallyApproved, rejected, needsManualReview }

class CounterfactualPath {
  final String description;
  final int requiredScore;
  final double maxAmount;

  const CounterfactualPath({
    required this.description,
    required this.requiredScore,
    required this.maxAmount,
  });

  factory CounterfactualPath.fromJson(Map<String, dynamic> json) {
    return CounterfactualPath(
      description: json['description'] as String,
      requiredScore: json['requiredScore'] as int,
      maxAmount: (json['maxAmount'] as num).toDouble(),
    );
  }
}

class AlternativeOffer {
  final String productId;
  final String productName;
  final double maxAmount;

  const AlternativeOffer({
    required this.productId,
    required this.productName,
    required this.maxAmount,
  });

  factory AlternativeOffer.fromJson(Map<String, dynamic> json) {
    return AlternativeOffer(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      maxAmount: (json['maxAmount'] as num).toDouble(),
    );
  }
}

class AanResult {
  final String primaryReason;
  final List<String> secondaryReasons;

  const AanResult({
    required this.primaryReason,
    required this.secondaryReasons,
  });

  factory AanResult.fromJson(Map<String, dynamic> json) {
    return AanResult(
      primaryReason: json['primaryReason'] as String,
      secondaryReasons: List<String>.from(json['secondaryReasons'] as List),
    );
  }
}

class LoanDecisionModel {
  final String applicationId;
  final LoanDecisionStatus status;
  final double approvedAmount;
  final double interestRate;
  final int tenureDays;
  final AanResult? aan;
  final List<CounterfactualPath> dicePaths;
  final AlternativeOffer? alternativeOffer;

  const LoanDecisionModel({
    required this.applicationId,
    required this.status,
    required this.approvedAmount,
    required this.interestRate,
    required this.tenureDays,
    this.aan,
    this.dicePaths = const [],
    this.alternativeOffer,
  });

  factory LoanDecisionModel.fromJson(Map<String, dynamic> json) {
    LoanDecisionStatus statusEnum;
    switch (json['status']) {
      case 'approved':
        statusEnum = LoanDecisionStatus.approved;
        break;
      case 'conditionally_approved':
        statusEnum = LoanDecisionStatus.conditionallyApproved;
        break;
      case 'needs_manual_review':
        statusEnum = LoanDecisionStatus.needsManualReview;
        break;
      default:
        statusEnum = LoanDecisionStatus.rejected;
        break;
    }

    return LoanDecisionModel(
      applicationId: json['applicationId'] as String,
      status: statusEnum,
      approvedAmount: (json['approvedAmount'] as num?)?.toDouble() ?? 0.0,
      interestRate: (json['interestRate'] as num?)?.toDouble() ?? 0.0,
      tenureDays: json['tenureDays'] as int? ?? 0,
      aan: json['aan'] != null ? AanResult.fromJson(json['aan']) : null,
      dicePaths: (json['dicePaths'] as List?)?.map((e) => CounterfactualPath.fromJson(e)).toList() ?? [],
      alternativeOffer: json['alternativeOffer'] != null ? AlternativeOffer.fromJson(json['alternativeOffer']) : null,
    );
  }
}
