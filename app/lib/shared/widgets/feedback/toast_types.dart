import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// TOAST TYPE DEFINITIONS — matches spec exactly
/// ─────────────────────────────────────────────────────────────────────────────
enum ToastType { success, error, warning, info, processing }

class ToastStyle {
  final Color colour;
  final Color borderColour;
  final Color iconBg;
  final String emoji;
  final Duration autoDismiss;

  const ToastStyle({
    required this.colour,
    required this.borderColour,
    required this.iconBg,
    required this.emoji,
    required this.autoDismiss,
  });
}

const Map<ToastType, ToastStyle> toastStyles = {
  ToastType.success: ToastStyle(
    colour: Color(0xFF1A6B3C),
    borderColour: Color(0x331A6B3C),
    iconBg: Color(0xFFD4EDDA),
    emoji: '✅',
    autoDismiss: Duration(milliseconds: 3000),
  ),
  ToastType.error: ToastStyle(
    colour: Color(0xFFD32F2F),
    borderColour: Color(0x33D32F2F),
    iconBg: Color(0xFFFFEBEE),
    emoji: '❌',
    autoDismiss: Duration(milliseconds: 3500),
  ),
  ToastType.warning: ToastStyle(
    colour: Color(0xFFE65100),
    borderColour: Color(0x33E65100),
    iconBg: Color(0xFFFFF3E0),
    emoji: '⚠️',
    autoDismiss: Duration(milliseconds: 3500),
  ),
  ToastType.info: ToastStyle(
    colour: Color(0xFF0277BD),
    borderColour: Color(0x330277BD),
    iconBg: Color(0xFFBBDEFB),
    emoji: 'ℹ️',
    autoDismiss: Duration(milliseconds: 3000),
  ),
  ToastType.processing: ToastStyle(
    colour: Color(0xFF6A1B9A),
    borderColour: Color(0x336A1B9A),
    iconBg: Color(0xFFE1BEE7),
    emoji: '⏳',
    autoDismiss: Duration.zero, // stays until replaced
  ),
};

/// ─────────────────────────────────────────────────────────────────────────────
/// TOAST ID CONSTANTS — used app-wide, never duplicate strings
/// ─────────────────────────────────────────────────────────────────────────────
class ToastId {
  // Auth
  static const otpSent = 'OTP_SENT';
  static const otpResent = 'OTP_RESENT';
  static const accountCreated = 'ACCOUNT_CREATED';
  static const signinSuccess = 'SIGNIN_SUCCESS';
  static const otpIncorrect = 'OTP_INCORRECT';
  static const otpExpired = 'OTP_EXPIRED';
  static const accountExists = 'ACCOUNT_EXISTS';
  static const accountNotFound = 'ACCOUNT_NOT_FOUND';
  static const otpSendFailed = 'OTP_SEND_FAILED';
  static const tooManyAttempts = 'TOO_MANY_ATTEMPTS';

  // Steps
  static const stepVerifying = 'STEP_VERIFYING';
  static const docUploading = 'DOC_UPLOADING';
  static const docProcessing = 'DOC_PROCESSING';
  static const step1Complete = 'STEP1_COMPLETE';
  static const step2Complete = 'STEP2_COMPLETE';
  static const step3Complete = 'STEP3_COMPLETE';
  static const step4Complete = 'STEP4_COMPLETE';
  static const stepInputInvalid = 'STEP_INPUT_INVALID';
  static const docVerified = 'DOC_VERIFIED';
  static const docUnreadable = 'DOC_UNREADABLE';
  static const docWrongType = 'DOC_WRONG_TYPE';

  // AI/Processing
  static const aiScoreRunning = 'AI_SCORE_RUNNING';
  static const aiScoreDone = 'AI_SCORE_DONE';
  static const aiScoreFailed = 'AI_SCORE_FAILED';
  static const ocrRunning = 'OCR_RUNNING';
  static const ocrSuccess = 'OCR_SUCCESS';
  static const bankParseSuccess = 'BANK_PARSE_SUCCESS';
  static const bankParseFailed = 'BANK_PARSE_FAILED';

  // Loan
  static const eligibilityPass = 'ELIGIBILITY_PASS';
  static const eligibilityFail = 'ELIGIBILITY_FAIL';
  static const loanApproved = 'LOAN_APPROVED';
  static const kfsAcknowledged = 'KFS_ACKNOWLEDGED';
  static const affordabilityFail = 'AFFORDABILITY_FAIL';

  // Session
  static const logoutSuccess = 'LOGOUT_SUCCESS';
  static const sessionExpired = 'SESSION_EXPIRED';
  static const profileUpdated = 'PROFILE_UPDATED';

  // Network
  static const noInternet = 'NO_INTERNET';
  static const serverError = 'SERVER_ERROR';
  static const requestTimeout = 'REQUEST_TIMEOUT';

  // PDF
  static const pdfSaved = 'PDF_SAVED';
  static const pdfFailed = 'PDF_FAILED';
}

/// Pre-defined toast data for quick lookup
class ToastData {
  final String id;
  final ToastType type;
  final String emoji;
  final String title;
  final String? subtitle;

  const ToastData({
    required this.id,
    required this.type,
    required this.emoji,
    required this.title,
    this.subtitle,
  });
}

/// Master toast registry — every toast in the app
const Map<String, ToastData> toastRegistry = {
  // ── AUTH ───────────────────────────────────────────────────────────────
  ToastId.otpSent: ToastData(id: ToastId.otpSent, type: ToastType.success, emoji: '📱', title: 'OTP Sent', subtitle: 'Check your SMS — valid for 5 minutes'),
  ToastId.otpResent: ToastData(id: ToastId.otpResent, type: ToastType.success, emoji: '🔁', title: 'New OTP Sent', subtitle: 'Previous code is now invalid'),
  ToastId.accountCreated: ToastData(id: ToastId.accountCreated, type: ToastType.success, emoji: '🎉', title: 'Account Created', subtitle: 'Welcome to GigCredit!'),
  ToastId.signinSuccess: ToastData(id: ToastId.signinSuccess, type: ToastType.success, emoji: '✅', title: 'Signed In', subtitle: 'Welcome back!'),
  ToastId.otpIncorrect: ToastData(id: ToastId.otpIncorrect, type: ToastType.error, emoji: '❌', title: 'Incorrect OTP', subtitle: "The code doesn't match. Try again"),
  ToastId.otpExpired: ToastData(id: ToastId.otpExpired, type: ToastType.error, emoji: '⏱️', title: 'OTP Expired', subtitle: 'Request a new one and try again'),
  ToastId.accountExists: ToastData(id: ToastId.accountExists, type: ToastType.error, emoji: '👤', title: 'Account Already Exists', subtitle: 'This number is registered — sign in instead'),
  ToastId.accountNotFound: ToastData(id: ToastId.accountNotFound, type: ToastType.error, emoji: '🔍', title: 'No Account Found', subtitle: 'Sign up first to create your account'),
  ToastId.otpSendFailed: ToastData(id: ToastId.otpSendFailed, type: ToastType.error, emoji: '📵', title: "Couldn't Send OTP", subtitle: 'Check your number and try again'),
  ToastId.tooManyAttempts: ToastData(id: ToastId.tooManyAttempts, type: ToastType.warning, emoji: '⚠️', title: 'Too Many Attempts', subtitle: 'Wait 10 minutes before trying again'),

  // ── STEPS ──────────────────────────────────────────────────────────────
  ToastId.stepVerifying: ToastData(id: ToastId.stepVerifying, type: ToastType.processing, emoji: '⏳', title: 'Verifying Your Details', subtitle: 'This takes just a second...'),
  ToastId.docUploading: ToastData(id: ToastId.docUploading, type: ToastType.processing, emoji: '⏳', title: 'Uploading Document', subtitle: "Please don't close the app"),
  ToastId.docProcessing: ToastData(id: ToastId.docProcessing, type: ToastType.processing, emoji: '⏳', title: 'Reading Your Document', subtitle: 'Our AI is extracting the details'),
  ToastId.step1Complete: ToastData(id: ToastId.step1Complete, type: ToastType.success, emoji: '✅', title: 'Personal Details Saved', subtitle: 'Moving to income details'),
  ToastId.step2Complete: ToastData(id: ToastId.step2Complete, type: ToastType.success, emoji: '✅', title: 'Income Details Saved', subtitle: 'Moving to document uploads'),
  ToastId.step3Complete: ToastData(id: ToastId.step3Complete, type: ToastType.success, emoji: '✅', title: 'Documents Verified', subtitle: 'Moving to credit history'),
  ToastId.step4Complete: ToastData(id: ToastId.step4Complete, type: ToastType.success, emoji: '🎯', title: 'All Details Submitted', subtitle: 'Checking your eligibility now'),
  ToastId.stepInputInvalid: ToastData(id: ToastId.stepInputInvalid, type: ToastType.error, emoji: '❌', title: 'Some Details Need Fixing', subtitle: 'Check the highlighted fields and try again'),
  ToastId.docVerified: ToastData(id: ToastId.docVerified, type: ToastType.success, emoji: '✅', title: 'Document Verified', subtitle: 'Details extracted successfully'),
  ToastId.docUnreadable: ToastData(id: ToastId.docUnreadable, type: ToastType.error, emoji: '📷', title: "Couldn't Read Document", subtitle: 'Try a clearer photo in good lighting'),
  ToastId.docWrongType: ToastData(id: ToastId.docWrongType, type: ToastType.error, emoji: '📄', title: 'Wrong Document', subtitle: 'Please upload the correct document type'),

  // ── AI / PROCESSING ────────────────────────────────────────────────────
  ToastId.aiScoreRunning: ToastData(id: ToastId.aiScoreRunning, type: ToastType.processing, emoji: '🧠', title: 'Calculating Your Score', subtitle: 'Analysing your financial signals'),
  ToastId.aiScoreDone: ToastData(id: ToastId.aiScoreDone, type: ToastType.success, emoji: '🏆', title: 'Score Ready', subtitle: 'Your GigCredit report is updated'),
  ToastId.aiScoreFailed: ToastData(id: ToastId.aiScoreFailed, type: ToastType.error, emoji: '🤖', title: 'Scoring Unavailable', subtitle: 'Try again — your data is saved'),
  ToastId.ocrRunning: ToastData(id: ToastId.ocrRunning, type: ToastType.processing, emoji: '📋', title: 'Reading Document', subtitle: 'Extracting text with AI...'),
  ToastId.ocrSuccess: ToastData(id: ToastId.ocrSuccess, type: ToastType.success, emoji: '📋', title: 'Document Read', subtitle: 'All fields extracted successfully'),
  ToastId.bankParseSuccess: ToastData(id: ToastId.bankParseSuccess, type: ToastType.success, emoji: '🏦', title: 'Statement Analysed', subtitle: 'Income patterns extracted'),
  ToastId.bankParseFailed: ToastData(id: ToastId.bankParseFailed, type: ToastType.error, emoji: '🏦', title: "Couldn't Read Statement", subtitle: 'Upload a clearer PDF from your bank app'),

  // ── LOAN ───────────────────────────────────────────────────────────────
  ToastId.eligibilityPass: ToastData(id: ToastId.eligibilityPass, type: ToastType.success, emoji: '🎯', title: 'Eligibility Confirmed', subtitle: 'Sending to our decision engine'),
  ToastId.eligibilityFail: ToastData(id: ToastId.eligibilityFail, type: ToastType.error, emoji: '❌', title: 'Not Eligible Right Now', subtitle: 'See the report below to understand why'),
  ToastId.loanApproved: ToastData(id: ToastId.loanApproved, type: ToastType.success, emoji: '🎉', title: 'Loan Approved!', subtitle: 'Tap below to sign and receive funds'),
  ToastId.kfsAcknowledged: ToastData(id: ToastId.kfsAcknowledged, type: ToastType.success, emoji: '✅', title: 'Terms Confirmed', subtitle: "You've accepted the Key Fact Statement"),
  ToastId.affordabilityFail: ToastData(id: ToastId.affordabilityFail, type: ToastType.warning, emoji: '⚠️', title: 'Loan Amount Adjusted', subtitle: "We've suggested a smaller amount that fits"),

  // ── SESSION ────────────────────────────────────────────────────────────
  ToastId.logoutSuccess: ToastData(id: ToastId.logoutSuccess, type: ToastType.info, emoji: '👋', title: 'Logged Out', subtitle: 'See you next time!'),
  ToastId.sessionExpired: ToastData(id: ToastId.sessionExpired, type: ToastType.warning, emoji: '🔒', title: 'Session Expired', subtitle: 'Please sign in again to continue'),
  ToastId.profileUpdated: ToastData(id: ToastId.profileUpdated, type: ToastType.success, emoji: '✅', title: 'Profile Updated', subtitle: 'Your changes have been saved'),

  // ── NETWORK ────────────────────────────────────────────────────────────
  ToastId.noInternet: ToastData(id: ToastId.noInternet, type: ToastType.info, emoji: '📶', title: 'No Internet', subtitle: 'Check your connection and retry'),
  ToastId.serverError: ToastData(id: ToastId.serverError, type: ToastType.info, emoji: '🌐', title: 'Something Went Wrong', subtitle: 'Please try again in a moment'),
  ToastId.requestTimeout: ToastData(id: ToastId.requestTimeout, type: ToastType.warning, emoji: '⏳', title: 'Request Timed Out', subtitle: 'Slow connection detected — try again'),

  // ── PDF ─────────────────────────────────────────────────────────────────
  ToastId.pdfSaved: ToastData(id: ToastId.pdfSaved, type: ToastType.success, emoji: '📥', title: 'PDF Saved', subtitle: 'Your report is in your downloads folder'),
  ToastId.pdfFailed: ToastData(id: ToastId.pdfFailed, type: ToastType.error, emoji: '📄', title: "Couldn't Save PDF", subtitle: 'Try again or take a screenshot'),
};
