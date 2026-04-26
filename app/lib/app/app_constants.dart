// ============================================================
// GigCredit — App Constants
// ============================================================

class AppConstants {
  AppConstants._();

  // App Identity
  static const String appName = 'GigCredit';
  static const String tagline = 'Privacy-first. Explainable. Built for the real world.';

  // Credit System
  static const int freeReportsAllowed = 3;
  static const int creditsPerReport = 10;
  static const int pricePerTenCredits = 79; // ₹79
  static const int maxLoansPerUser = 5;
  static const int creditPurchaseStep = 10;

  // OTP
  static const String demoOtp = '000000';
  static const int otpResendSeconds = 30;
  static const int otpLength = 6;

  // Score Range
  static const int scoreMin = 300;
  static const int scoreMax = 900;
  static const int fallbackScore = 682;
  static const String fallbackGrade = 'B';
  static const String fallbackRiskBand = 'Medium';

  // Grade Thresholds
  static const int gradeS = 800;
  static const int gradeA = 720;
  static const int gradeB = 640;
  static const int gradeC = 560;
  static const int gradeD = 480;

  // Animation Durations (ms)
  static const int animFast = 200;
  static const int animStandard = 300;
  static const int animSlow = 600;
  static const int animDramatic = 3000;
  static const int scoreMessageDuration = 2500;

  // OCR Confidence Threshold
  static const double ocrConfidenceThreshold = 0.70;

  // Scoring Confidence Threshold
  static const double pillarConfidenceMin = 0.30;
  static const double missingFeatureDefault = 0.40;

  // Pagination
  static const int defaultPageSize = 20;

  // Asset paths
  static const String configDir = 'assets/config/';
  static const String imagesDir = 'assets/images/';

  // Hive Box Names
  static const String hiveBoxSession = 'session_box';
  static const String hiveBoxProfile = 'profile_box';
  static const String hiveBoxSettings = 'settings_box';

  // Supported Languages
  static const List<String> supportedLanguages = ['en', 'ta', 'hi'];
  static const Map<String, String> languageLabels = {
    'en': 'English',
    'ta': 'தமிழ்',
    'hi': 'हिंदी',
  };
}
