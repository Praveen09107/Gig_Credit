// ============================================================
// GigCredit — All App Enums (single source of truth)
// ============================================================

enum AuthStatus { unauthenticated, loading, authenticated, error }

enum StepStatus { notStarted, inProgress, ocrComplete, pendingVerification, verified, rejected }

enum ScoreGenerationStatus { idle, generating, success, error }

enum UploadCardState { empty, processing, extracted, fallback, uploadError }

enum LoanEligibilityStatus { noScore, eligible, noOffers, loading }

enum ApplicationStatus {
  submitted,
  consentVerified,
  underReview,
  decisionPending,
  approved,
  rejected,
  disbursed,
}

enum ScoreAccessReason {
  freeReportAvailable,
  eligibleWithCredits,
  insufficientCredits,
}

enum WorkType {
  platformWorker,
  driver,
  streetVendor,
  freelancer,
  other,
}

enum InsuranceType { health, vehicle, life }

enum ConnectivityStatus { online, offline }

enum GradeType { S, A, B, C, D, E }

extension GradeTypeExtension on GradeType {
  static GradeType fromScore(int score) {
    if (score >= 800) return GradeType.S;
    if (score >= 720) return GradeType.A;
    if (score >= 640) return GradeType.B;
    if (score >= 560) return GradeType.C;
    if (score >= 480) return GradeType.D;
    return GradeType.E;
  }

  String get label {
    switch (this) {
      case GradeType.S: return 'Exceptional';
      case GradeType.A: return 'Excellent';
      case GradeType.B: return 'Good';
      case GradeType.C: return 'Fair';
      case GradeType.D: return 'Needs Improvement';
      case GradeType.E: return 'Poor';
    }
  }
}
