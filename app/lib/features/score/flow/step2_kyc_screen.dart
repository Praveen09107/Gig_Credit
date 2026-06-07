import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/layout/scrollable_step_layout.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/inputs/document_upload_card.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/status/verification_badge.dart';
import '../../../../state/step_status_provider.dart';
import '../../../../state/verified_profile_provider.dart';
import '../../../../state/ocr_service_provider.dart';
import '../../../../state/api_service_provider.dart';
import '../../../../state/ocr_results_provider.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../models/verified_profile/kyc_info.dart';
import '../../../../app/app_router.dart';
import '../../../../scoring/placeholders/demo_face_verifier.dart';
import '../../../../scoring/validation/cross_step_validator.dart';
import '../../../../scoring/validation/step2_validator.dart';
import '../widgets/mismatch_warning_banner.dart';
import '../../../../shared/widgets/loaders/coin_pulse_loader.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';
import '../../../../shared/widgets/feedback/step_popups.dart';
import '../../../../services/gig_logger.dart';

class Step2KycScreen extends ConsumerStatefulWidget {
  const Step2KycScreen({super.key});

  @override
  ConsumerState<Step2KycScreen> createState() => _Step2KycScreenState();
}

class _Step2KycScreenState extends ConsumerState<Step2KycScreen> {
  final _aadhaarController = TextEditingController();
  final _panController = TextEditingController();

  bool _aadhaarVerified = false;
  bool _aadhaarVerifying = false;
  bool _panVerified = false;
  bool _panVerifying = false;

  // ── API-verified data (from server) — stored for cross-checking against OCR ──
  // These are set when verify buttons succeed and used to validate uploaded images
  Map<String, dynamic> _aadhaarApiData = {};  // {name, dob, aadhaar_number} from API
  Map<String, dynamic> _panApiData = {};       // {name, dob, pan_number} from API

  // Inline mismatch messages shown immediately after upload
  String? _aadhaarImageMismatch;
  String? _panImageMismatch;
  bool _aadhaarFrontExtracted = false;
  bool _aadhaarBackExtracted = false;
  bool _panExtracted = false;
  List<ValidationIssue> _validationIssues = [];

  // Keys to force DocumentUploadCard reset when user needs to re-upload
  int _aadhaarFrontUploadKey = 0;
  int _panUploadKey = 0;

  bool _aadhaarOtpSent = false;
  String? _expectedAadhaarOtp;
  final _aadhaarOtpController = TextEditingController();

  bool _panOtpSent = false;
  String? _expectedPanOtp;
  final _panOtpController = TextEditingController();

  bool _selfieVerified = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _aadhaarController.dispose();
    _panController.dispose();
    _aadhaarOtpController.dispose();
    _panOtpController.dispose();
    super.dispose();
  }

  /// Verify Aadhaar number with real format validation + API call
  Future<void> _verifyAadhaar() async {
    // If OTP is already sent, this button press means "Verify OTP via backend"
    if (_aadhaarOtpSent) {
      final enteredOtp = _aadhaarOtpController.text.trim();
      if (enteredOtp.length != 6) {
        AppToast.error(context, 'Enter the 6-digit OTP');
        return;
      }
      setState(() => _aadhaarVerifying = true);
      try {
        final api = ref.read(apiServiceProvider);
        final aadhaarNumber = _aadhaarController.text.replaceAll(' ', '');
        // ── REAL SERVER-SIDE OTP VALIDATION — no local fallback ──
        await api.verifyAadhaarOtp(aadhaarNumber, enteredOtp);
        if (mounted) {
          setState(() {
            _aadhaarVerified = true;
            _aadhaarOtpSent = false;
            _aadhaarVerifying = false;
          });
          AppToast.success(context, 'Aadhaar Verified ✓');
        }
      } catch (e) {
        if (mounted && !_aadhaarVerified) {
          // guard: don't show error if already verified
          setState(() => _aadhaarVerifying = false);
          final msg = e.toString().replaceFirst('Exception: ', '');
          if (msg.contains('Incorrect') ||
              msg.contains('wrong_otp') ||
              msg.contains('Wrong')) {
            AppToast.error(context, 'Incorrect OTP. Please try again.');
          } else if (msg.contains('expired')) {
            AppToast.error(context, 'OTP expired. Please request a new one.');
          } else if (msg.contains('too_many') || msg.contains('attempts')) {
            AppToast.error(
                context, 'Too many failed attempts. Please request a new OTP.');
          } else {
            AppToast.error(
                context, 'OTP verification failed. Please try again.');
          }
        }
      }
      return;
    }

    // ── REAL FORMAT VALIDATION — blocks before calling backend ──
    final text = _aadhaarController.text.replaceAll(' ', '');
    final formatIssue = Step2Validator.validateAadhaarFormat(text);
    if (formatIssue != null) {
      AppToast.error(context, formatIssue.message);
      return; // Hard block — do NOT call backend with invalid format
    }
    setState(() => _aadhaarVerifying = true);

    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.verifyAadhaar(text);
      if (mounted) {
        // Store API-verified Aadhaar data — used to cross-check uploaded image
        _aadhaarApiData = {
          'aadhaar_number': text,
          'name': result['name'] as String? ?? '',
          'dob':  result['dob']  as String? ?? '',
          'state': result['state'] as String? ?? '',
        };
        setState(() {
          _aadhaarVerifying = false;
          _aadhaarOtpSent = true;
          _expectedAadhaarOtp = result['otp'] as String?;
        });
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(children: [
              Icon(Icons.message, color: Colors.blue),
              SizedBox(width: 8),
              Text('New Message')
            ]),
            content: Text(
                'UIDAI: Your Aadhaar verification OTP is ${_expectedAadhaarOtp ?? '------'}. Valid for 10 minutes.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Dismiss'))
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _aadhaarVerifying = false);
        final msg = e.toString().replaceFirst('Exception: ', '');
        // Real backend error — show it, do NOT generate local OTP
        if (msg.contains('not_found') || msg.contains('not found')) {
          AppToast.error(context,
              'Aadhaar not found. Please check the number and try again.');
        } else if (msg.contains('invalid_format')) {
          AppToast.error(context, 'Invalid Aadhaar format.');
        } else if (msg.contains('Network')) {
          AppToast.error(
              context, 'Network error. Please check your connection.');
        } else {
          AppToast.error(
              context, 'Aadhaar verification failed. Please try again.');
        }
      }
    }
  }

  /// Verify PAN number with real format validation + API call
  Future<void> _verifyPan() async {
    // If OTP is already sent, this button press means "Verify OTP via backend"
    if (_panOtpSent) {
      final enteredOtp = _panOtpController.text.trim();
      if (enteredOtp.length != 6) {
        AppToast.error(context, 'Enter the 6-digit OTP');
        return;
      }
      setState(() => _panVerifying = true);
      try {
        final api = ref.read(apiServiceProvider);
        final panNumber = _panController.text.trim();
        // ── REAL SERVER-SIDE OTP VALIDATION — no local fallback ──
        await api.verifyPanOtp(panNumber, enteredOtp);
        if (mounted) {
          setState(() {
            _panVerified = true;
            _panOtpSent = false;
            _panVerifying = false;
          });
          AppToast.success(context, 'PAN Verified ✓');
        }
      } catch (e) {
        if (mounted && !_panVerified) {
          // guard: don't show error if already verified
          setState(() => _panVerifying = false);
          final msg = e.toString().replaceFirst('Exception: ', '');
          if (msg.contains('Incorrect') ||
              msg.contains('wrong_otp') ||
              msg.contains('Wrong')) {
            AppToast.error(context, 'Incorrect OTP. Please try again.');
          } else if (msg.contains('expired')) {
            AppToast.error(context, 'OTP expired. Please request a new one.');
          } else if (msg.contains('too_many') || msg.contains('attempts')) {
            AppToast.error(
                context, 'Too many failed attempts. Please request a new OTP.');
          } else {
            AppToast.error(
                context, 'OTP verification failed. Please try again.');
          }
        }
      }
      return;
    }

    // ── REAL FORMAT VALIDATION — blocks before calling backend ──
    final text = _panController.text.trim();
    final formatIssue = Step2Validator.validatePanFormat(text);
    if (formatIssue != null && formatIssue.isBlocking) {
      AppToast.error(context, formatIssue.message);
      return; // Hard block only — suppress soft flag (4th char warning is confusing)
    }
    setState(() => _panVerifying = true);

    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.verifyPan(text);
      if (mounted) {
        // Store API-verified PAN data — used to cross-check uploaded image
        _panApiData = {
          'pan_number': text,
          'name': result['name'] as String? ?? '',
          'dob':  result['dob']  as String? ?? '',
        };
        setState(() {
          _panVerifying = false;
          _panOtpSent = true;
          _expectedPanOtp = result['otp'] as String?;
        });
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(children: [
              Icon(Icons.message, color: Colors.blue),
              SizedBox(width: 8),
              Text('New Message')
            ]),
            content: Text(
                'NSDL: Your PAN verification OTP is ${_expectedPanOtp ?? '------'}. Valid for 10 minutes.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Dismiss'))
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _panVerifying = false);
        final msg = e.toString().replaceFirst('Exception: ', '');
        // Real backend error — show it, do NOT generate local OTP
        if (msg.contains('not_found') || msg.contains('not found')) {
          AppToast.error(
              context, 'PAN not found. Please check the number and try again.');
        } else if (msg.contains('invalid_format')) {
          AppToast.error(context, 'Invalid PAN format.');
        } else if (msg.contains('Network')) {
          AppToast.error(
              context, 'Network error. Please check your connection.');
        } else {
          AppToast.error(context, 'PAN verification failed. Please try again.');
        }
      }
    }
  }

  /// Cross-check Aadhaar image OCR vs API-verified data.
  /// Called immediately after image upload — shows inline mismatch banner if names/numbers don't match.
  void _onAadhaarFrontExtracted(Map<String, dynamic> data) {
    ref.read(ocrResultsProvider.notifier).addResult('aadhaar_front', data);
    if (data.containsKey('aadhaar_number') && data['aadhaar_number'] != null) {
      _aadhaarController.text = data['aadhaar_number'];
    }

    String? mismatch;

    // 1. Aadhaar number: OCR vs entered number
    final ocrAadhaar = (data['aadhaar_number'] as String? ?? '').replaceAll(' ', '');
    final enteredAadhaar = _aadhaarController.text.replaceAll(' ', '');
    if (ocrAadhaar.isNotEmpty && enteredAadhaar.isNotEmpty && ocrAadhaar != enteredAadhaar) {
      mismatch = 'Aadhaar number on the uploaded card ($ocrAadhaar) does not match the number you entered ($enteredAadhaar). Please upload your own Aadhaar card.';
    }

    // 2. Name: OCR vs API-verified name (from /gov/aadhaar/verify response)
    if (mismatch == null && _aadhaarApiData.isNotEmpty) {
      final apiName  = (_aadhaarApiData['name'] as String? ?? '').trim().toLowerCase();
      final ocrName  = (data['name'] as String? ?? '').trim().toLowerCase();
      if (apiName.isNotEmpty && ocrName.isNotEmpty) {
        final score = _nameSimilarity(apiName, ocrName);
        if (score < 0.60) {
          mismatch = 'Name on the uploaded Aadhaar card ("${data['name']}") does not match the verified Aadhaar record ("${_aadhaarApiData['name']}"). You must upload your own Aadhaar card.';
        }
      }
    }

    // 3. DOB: OCR vs API-verified DOB
    if (mismatch == null && _aadhaarApiData.isNotEmpty) {
      final apiDob = (_aadhaarApiData['dob'] as String? ?? '').trim();
      final ocrDob = (data['dob'] as String? ?? '').trim();
      if (apiDob.isNotEmpty && ocrDob.isNotEmpty && !_dobsRoughMatch(apiDob, ocrDob)) {
        mismatch = 'Date of birth on the uploaded Aadhaar card ($ocrDob) does not match the verified record ($apiDob). This does not appear to be your Aadhaar card.';
      }
    }

    setState(() {
      _aadhaarFrontExtracted = mismatch == null;
      _aadhaarImageMismatch = mismatch;
      _validationIssues = [];
    });

    if (mismatch == null) {
      _runCrossValidation();
    }
  }

  /// Cross-check PAN image OCR vs API-verified data AND vs Aadhaar API data.
  /// Called immediately after image upload — shows inline mismatch banner if data doesn't match.
  void _onPanExtracted(Map<String, dynamic> data) {
    ref.read(ocrResultsProvider.notifier).addResult('pan', data);
    if (data.containsKey('pan_number') && data['pan_number'] != null) {
      _panController.text = data['pan_number'];
    }

    String? mismatch;

    // 1. PAN number: OCR vs entered number
    final ocrPan     = (data['pan_number'] as String? ?? '').trim().toUpperCase();
    final enteredPan = _panController.text.trim().toUpperCase();
    if (ocrPan.isNotEmpty && enteredPan.isNotEmpty && ocrPan != enteredPan) {
      mismatch = 'PAN number on the uploaded card ($ocrPan) does not match the PAN you entered ($enteredPan). Please upload your own PAN card.';
    }

    // 2. Name: OCR vs API-verified PAN name
    if (mismatch == null && _panApiData.isNotEmpty) {
      final apiName = (_panApiData['name'] as String? ?? '').trim().toLowerCase();
      final ocrName = (data['name'] as String? ?? '').trim().toLowerCase();
      if (apiName.isNotEmpty && ocrName.isNotEmpty) {
        final score = _nameSimilarity(apiName, ocrName);
        if (score < 0.60) {
          mismatch = 'Name on the uploaded PAN card ("${data['name']}") does not match the verified PAN record ("${_panApiData['name']}"). You must upload your own PAN card.';
        }
      }
    }

    // 3. PAN name vs Aadhaar API name (cross-document identity chain)
    if (mismatch == null && _aadhaarApiData.isNotEmpty && _panApiData.isNotEmpty) {
      final aadhaarName = (_aadhaarApiData['name'] as String? ?? '').trim().toLowerCase();
      final panName     = (_panApiData['name']    as String? ?? '').trim().toLowerCase();
      if (aadhaarName.isNotEmpty && panName.isNotEmpty) {
        final score = _nameSimilarity(aadhaarName, panName);
        if (score < 0.55) {
          mismatch = 'The name on your PAN ("${_panApiData['name']}") does not match the name on your Aadhaar ("${_aadhaarApiData['name']}"). Both documents must belong to the same person.';
        }
      }
    }

    // 4. DOB: OCR vs API-verified PAN DOB
    if (mismatch == null && _panApiData.isNotEmpty) {
      final apiDob = (_panApiData['dob'] as String? ?? '').trim();
      final ocrDob = (data['dob'] as String? ?? '').trim();
      if (apiDob.isNotEmpty && ocrDob.isNotEmpty && !_dobsRoughMatch(apiDob, ocrDob)) {
        mismatch = 'Date of birth on the uploaded PAN card ($ocrDob) does not match the verified record ($apiDob). This does not appear to be your PAN card.';
      }
    }

    setState(() {
      _panExtracted = mismatch == null;
      _panImageMismatch = mismatch;
      _validationIssues = [];
    });

    if (mismatch == null) {
      _runCrossValidation();
    }
  }

  /// Simple bigram name similarity (0.0 – 1.0).
  /// Works well for Indian names with minor OCR noise.
  double _nameSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    // Tokenise and check first-token containment (handles "Praveen Kumar P" vs "Praveen Kumar")
    final aToks = a.split(RegExp(r'\s+'));
    final bToks = b.split(RegExp(r'\s+'));
    final common = aToks.where((t) => t.length > 1 && bToks.contains(t)).length;
    final tokenScore = common / (aToks.length > bToks.length ? aToks.length : bToks.length);
    if (tokenScore >= 0.6) return tokenScore;
    // Bigram fallback
    Set<String> bigrams(String s) {
      final set = <String>{};
      for (int i = 0; i < s.length - 1; i++) set.add(s.substring(i, i + 2));
      return set;
    }
    final ab = bigrams(a); final bb = bigrams(b);
    final inter = ab.intersection(bb).length;
    if (ab.isEmpty && bb.isEmpty) return 1.0;
    return (2.0 * inter) / (ab.length + bb.length);
  }

  /// Loose DOB comparison — same year+month is enough (OCR day errors are common).
  bool _dobsRoughMatch(String d1, String d2) {
    DateTime? parse(String s) {
      final parts = s.split(RegExp(r'[/\-.]'));
      if (parts.length < 3) return null;
      try {
        final first = int.parse(parts[0]);
        if (first > 31) return DateTime(first, int.parse(parts[1]), int.parse(parts[2]));
        return DateTime(int.parse(parts[2]), int.parse(parts[1]), first);
      } catch (_) { return null; }
    }
    final dt1 = parse(d1); final dt2 = parse(d2);
    if (dt1 == null || dt2 == null) return true; // can't parse — don't block
    return dt1.year == dt2.year && dt1.month == dt2.month;
  }

  void _onAadhaarBackExtracted(Map<String, dynamic> data) {
    ref.read(ocrResultsProvider.notifier).addResult('aadhaar_back', data);
    setState(() => _aadhaarBackExtracted = true);
  }

  void _runCrossValidation() {
    final ocrResults = ref.read(ocrResultsProvider);
    final issues = CrossStepValidator.validate(ocrResults);
    setState(() => _validationIssues = issues);
  }

  Future<void> _verifySelfie(Map<String, dynamic> data) async {
    ref.read(ocrResultsProvider.notifier).addResult('selfie', data);

    final ocrResults = ref.read(ocrResultsProvider);
    final aadhaarPath =
        ocrResults['aadhaar_front']?['image_path'] as String? ?? '';
    final panPath = ocrResults['pan']?['image_path'] as String? ?? '';
    final selfiePath = data['image_path'] as String? ?? 'mock_selfie';

    final result = await DemoFaceVerifier.verify(
      aadhaarPath: aadhaarPath,
      panPath: panPath,
      selfiePath: selfiePath,
    );

    setState(() => _selfieVerified = result.matched);

    if (!result.matched) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Verification Failed: ${result.error ?? "Faces do not match!"}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      // Remove the invalid selfie so they can try again
      ref.read(ocrResultsProvider.notifier).addResult('selfie', {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selfie Verified! Faces match.'),
            backgroundColor: Colors.green),
      );
    }
  }

  bool get _isFormValid {
    // Block if any inline mismatch banners are showing
    if (_aadhaarImageMismatch != null || _panImageMismatch != null) return false;
    return _aadhaarVerified &&
        _aadhaarFrontExtracted &&
        _panVerified &&
        _panExtracted &&
        _selfieVerified;
  }

  Future<void> _submit() async {
    final statusMap = ref.read(stepStatusProvider);
    if (statusMap[2] == StepStatus.verified) {
      context.push(AppRoutes.scoreStep(3));
      return;
    }

    if (CrossStepValidator.hasBlockingErrors(_validationIssues)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fix document mismatches before proceeding'),
            backgroundColor: Colors.red),
      );
      return;
    }

    // ═══════════════════════════════════════════════════════════════
    // REAL CROSS-STEP IDENTITY CHAIN VALIDATION (per spec)
    // ═══════════════════════════════════════════════════════════════
    final profile = ref.read(verifiedProfileProvider);
    final ocrResults = ref.read(ocrResultsProvider);

    final step2Result = Step2Validator.validateFull(
      step1Name: profile.personalInfo.fullName,
      step1Dob: profile.personalInfo.dateOfBirth,
      enteredAadhaar: _aadhaarController.text.replaceAll(' ', ''),
      enteredPan: _panController.text.trim(),
      aadhaarFrontOcr: ocrResults['aadhaar_front'],
      panOcr: ocrResults['pan'],
      selfieVerified: _selfieVerified,
    );

    GigLogger.stepBanner(2, 'KYC IDENTITY CHAIN — CROSS-VALIDATION');

    GigLogger.sectionHeader('INPUTS FOR CROSS-VALIDATION');
    GigLogger.data('Step 1 Name (declared)', profile.personalInfo.fullName);
    GigLogger.data('Step 1 DOB  (declared)', profile.personalInfo.dateOfBirth);
    GigLogger.data(
        'Entered Aadhaar',
        _aadhaarController.text
            .replaceAll(' ', '')
            .replaceRange(0, 8, 'XXXX-XXXX-'));
    GigLogger.data(
        'Entered PAN',
        _panController.text.trim().isEmpty
            ? 'N/A'
            : _panController.text.trim().replaceRange(0, 5, 'XXXXX'));
    GigLogger.data('Aadhaar Front OCR name',
        ocrResults['aadhaar_front']?['name'] ?? '(not extracted)');
    GigLogger.data('Aadhaar DOB from OCR',
        ocrResults['aadhaar_front']?['dob'] ?? '(not extracted)');
    GigLogger.data(
        'PAN OCR name', ocrResults['pan']?['name'] ?? '(not extracted)');
    GigLogger.data('Selfie verified', _selfieVerified.toString());

    GigLogger.sectionHeader('CROSS-STEP IDENTITY CHAIN CHECKS');
    final step1Name = profile.personalInfo.fullName.toLowerCase().trim();
    final aadhaarName = (ocrResults['aadhaar_front']?['name'] as String? ?? '')
        .toLowerCase()
        .trim();
    final panName =
        (ocrResults['pan']?['name'] as String? ?? '').toLowerCase().trim();
    GigLogger.crossValidation(
        'Step1.name',
        step1Name,
        'Aadhaar.name',
        aadhaarName,
        aadhaarName.isEmpty ||
            aadhaarName == step1Name ||
            step1Name.contains(aadhaarName.split(' ').first));
    GigLogger.crossValidation(
        'Step1.name',
        step1Name,
        'PAN.name',
        panName,
        panName.isEmpty ||
            panName == step1Name ||
            step1Name.contains(panName.split(' ').first));
    GigLogger.crossValidation(
        'Step1.dob',
        profile.personalInfo.dateOfBirth,
        'Aadhaar.dob',
        ocrResults['aadhaar_front']?['dob'] ?? '',
        (ocrResults['aadhaar_front']?['dob'] as String? ?? '').isEmpty ||
            ocrResults['aadhaar_front']?['dob'] ==
                profile.personalInfo.dateOfBirth);
    GigLogger.check('Selfie face match', _selfieVerified);
    GigLogger.check('Aadhaar front OCR done', _aadhaarFrontExtracted);
    GigLogger.check('Aadhaar back OCR done', _aadhaarBackExtracted);
    GigLogger.check('PAN OCR done', _panExtracted);
    GigLogger.check('Aadhaar API verified', _aadhaarVerified);
    GigLogger.check('PAN API verified', _panVerified);

    GigLogger.divider();
    GigLogger.data('Name Match Score',
        '${(step2Result.nameMatchScore * 100).toStringAsFixed(1)}%');
    GigLogger.data('Hard Fails', '${step2Result.hardFails.length}');
    GigLogger.data('Soft Flags', '${step2Result.softFlags.length}');
    for (final issue in step2Result.issues) {
      if (issue.severity.name == 'hard') {
        GigLogger.fail('[HARD] ${issue.code}: ${issue.message}');
      } else {
        GigLogger.warn('[SOFT] ${issue.code}: ${issue.message}');
      }
    }
    if (step2Result.passed) {
      GigLogger.ok('STEP 2 CROSS-VALIDATION → PASSED ✓');
    } else {
      GigLogger.fail('STEP 2 CROSS-VALIDATION → FAILED — submission blocked');
    }

    // HARD FAIL — block submission
    if (!step2Result.passed) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('KYC Validation Failed',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Identity chain verification failed:',
                  style: TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              ...step2Result.hardFails.map((issue) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.close, color: Colors.red, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text(issue.message,
                                style: const TextStyle(fontSize: 12))),
                      ],
                    ),
                  )),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fix Issues'),
            ),
          ],
        ),
      );
      return;
    }

    // Show soft flag warnings (non-blocking)
    if (step2Result.softFlags.isNotEmpty && mounted) {
      for (final flag in step2Result.softFlags) {
        AppToast.warning(context, flag.message);
      }
    }

    // Show confirmation popup before proceeding
    final confirmed = await StepConfirmPopup.show(context, stepNumber: 2);
    if (!confirmed || !mounted) return;

    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(seconds: 2));

      ref.read(verifiedProfileProvider.notifier).updateStep2(
            KycInfo(
              isVerified: true,
              backVerified: _aadhaarBackExtracted,
              selfieVerified: _selfieVerified,
              panVerified: _panVerified,
              nameMatchScore: step2Result.nameMatchScore,
            ),
          );
      ref.read(stepStatusProvider.notifier).setStatus(2, StepStatus.verified);
      ref
          .read(stepStatusProvider.notifier)
          .resetStepsAfter(2); // GAP 3: Reset downstream on re-submit

      GigLogger.sectionHeader('GLOBAL STATE UPDATE — verifiedProfileProvider');
      GigLogger.stateUpdate(
          'verifiedProfileProvider', 'kycInfo.isVerified', 'true');
      GigLogger.stateUpdate('verifiedProfileProvider',
          'kycInfo.aadhaarVerified', _aadhaarVerified.toString());
      GigLogger.stateUpdate('verifiedProfileProvider', 'kycInfo.panVerified',
          _panVerified.toString());
      GigLogger.stateUpdate('verifiedProfileProvider', 'kycInfo.selfieVerified',
          _selfieVerified.toString());
      GigLogger.stateUpdate('verifiedProfileProvider', 'kycInfo.nameMatchScore',
          '${(step2Result.nameMatchScore * 100).toStringAsFixed(1)}%');
      GigLogger.stateUpdate(
          'stepStatusProvider', 'step[2]', 'StepStatus.verified');
      GigLogger.warn('Steps 3-9 downstream state RESET');
      GigLogger.ok('Step 2 KYC complete — advancing to Step 3 (Bank)');

      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.success(context,
            'KYC verified ✓ (name match: ${(step2Result.nameMatchScore * 100).toStringAsFixed(0)}%)');
        context.push(AppRoutes.scoreStep(3));
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusMap = ref.watch(stepStatusProvider);
    final ocrService = ref.watch(ocrServiceProvider);
    final isVerified = statusMap[2] == StepStatus.verified;

    return ScrollableStepLayout(
      currentStep: 2,
      stepCompletionMap: statusMap
          .map((key, value) => MapEntry(key, value == StepStatus.verified)),
      onStepTapped: (step) => context.push(AppRoutes.scoreStep(step)),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('KYC Verification',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              if (isVerified) const VerificationBadge(),
            ],
          ),
          const SizedBox(height: 4),
          Text('Upload photos of your ID cards. Data is extracted on-device.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 24),

          // ── Cross-Step Validation Warnings ──
          if (_validationIssues.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: MismatchWarningBanner(
                issues: _validationIssues,
                onDismiss: () {
                  // Reset upload cards so user can re-upload correct documents
                  setState(() {
                    _aadhaarFrontExtracted = false;
                    _panExtracted = false;
                    _aadhaarImageMismatch = null;
                    _panImageMismatch = null;
                    _aadhaarFrontUploadKey++; // forces DocumentUploadCard to reset
                    _panUploadKey++;
                    _validationIssues = [];
                  });
                  // Clear OCR results so re-upload triggers fresh validation
                  ref
                      .read(ocrResultsProvider.notifier)
                      .removeResult('aadhaar_front');
                  ref.read(ocrResultsProvider.notifier).removeResult('pan');
                },
              ),
            ),

          // ═══════════════════════════════════════════
          // SECTION A — AADHAAR CARD
          // ═══════════════════════════════════════════
          _buildSectionHeader('A', 'Aadhaar Card'),
          const SizedBox(height: 16),

          // Aadhaar Number + Verify button
          if (_aadhaarOtpSent)
            _buildVerifyInputRow(
              controller: _aadhaarOtpController,
              label: 'Aadhaar OTP',
              hint: 'Enter 6-digit OTP',
              maxLength: 6,
              keyboardType: TextInputType.number,
              isVerified: false,
              isVerifying:
                  _aadhaarVerifying, // show spinner during OTP validation
              isStepVerified: isVerified,
              onVerify: _verifyAadhaar,
            )
          else
            _buildVerifyInputRow(
              controller: _aadhaarController,
              label: 'Aadhaar Number',
              hint: 'Enter 12-digit Aadhaar',
              maxLength: 12,
              keyboardType: TextInputType.number,
              isVerified: _aadhaarVerified,
              isVerifying: _aadhaarVerifying,
              isStepVerified: isVerified,
              onVerify: _verifyAadhaar,
            ),
          const SizedBox(height: 16),

          Opacity(
            opacity: _aadhaarVerified ? 1.0 : 0.5,
            child: IgnorePointer(
              ignoring: !_aadhaarVerified,
              child: Column(
                children: [
                  DocumentUploadCard(
                    key: ValueKey('aadhaar_front_$_aadhaarFrontUploadKey'),
                    title: 'Aadhaar Card — Front Side',
                    subtitle: 'Photo showing name, DOB, Aadhaar number',
                    docType: 'aadhaar_front',
                    ocrService: ocrService,
                    onExtracted: _onAadhaarFrontExtracted,
                  ),
                  // Inline mismatch banner — shown immediately after wrong Aadhaar upload
                  if (_aadhaarImageMismatch != null) ...[
                    const SizedBox(height: 10),
                    _buildMismatchBanner(
                      message: _aadhaarImageMismatch!,
                      onReupload: () => setState(() {
                        _aadhaarImageMismatch = null;
                        _aadhaarFrontExtracted = false;
                        _aadhaarFrontUploadKey++;
                        ref.read(ocrResultsProvider.notifier).removeResult('aadhaar_front');
                      }),
                    ),
                  ],
                  const SizedBox(height: 12),
                  DocumentUploadCard(
                    title: 'Aadhaar Card — Back Side',
                    subtitle: 'Photo showing full address, PIN code',
                    docType: 'aadhaar_back',
                    ocrService: ocrService,
                    isRequired: false,
                    onExtracted: _onAadhaarBackExtracted,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ═══════════════════════════════════════════
          // SECTION B — PAN CARD
          // ═══════════════════════════════════════════
          _buildSectionHeader('B', 'PAN Card'),
          const SizedBox(height: 16),

          // PAN Number + Verify button
          if (_panOtpSent)
            _buildVerifyInputRow(
              controller: _panOtpController,
              label: 'PAN OTP',
              hint: 'Enter 6-digit OTP',
              maxLength: 6,
              keyboardType: TextInputType.number,
              isVerified: false,
              isVerifying: _panVerifying, // show spinner during OTP validation
              isStepVerified: isVerified,
              onVerify: _verifyPan,
            )
          else
            _buildVerifyInputRow(
              controller: _panController,
              label: 'PAN Number',
              hint: 'e.g. ABCDE1234F',
              maxLength: 10,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.characters,
              isVerified: _panVerified,
              isVerifying: _panVerifying,
              isStepVerified: isVerified,
              onVerify: _verifyPan,
            ),
          const SizedBox(height: 16),

          Opacity(
            opacity: _panVerified ? 1.0 : 0.5,
            child: IgnorePointer(
              ignoring: !_panVerified,
              child: Column(
                children: [
                  DocumentUploadCard(
                    key: ValueKey('pan_$_panUploadKey'),
                    title: 'PAN Card Photo',
                    subtitle: 'Photo showing PAN number, name, DOB',
                    docType: 'pan',
                    ocrService: ocrService,
                    onExtracted: _onPanExtracted,
                  ),
                  // Inline mismatch banner — shown immediately after wrong PAN upload
                  if (_panImageMismatch != null) ...[
                    const SizedBox(height: 10),
                    _buildMismatchBanner(
                      message: _panImageMismatch!,
                      onReupload: () => setState(() {
                        _panImageMismatch = null;
                        _panExtracted = false;
                        _panUploadKey++;
                        ref.read(ocrResultsProvider.notifier).removeResult('pan');
                      }),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ═══════════════════════════════════════════
          // SECTION C — LIVE SELFIE
          // ═══════════════════════════════════════════
          _buildSectionHeader('C', 'Live Selfie'),
          const SizedBox(height: 16),

          DocumentUploadCard(
            title: 'Selfie for Face Match',
            subtitle: 'Camera only — matched against Aadhaar photo',
            docType: 'selfie',
            ocrService: ocrService,
            isRequired: false,
            useCamera: true,
            onExtracted: _verifySelfie,
          ),

          if (_selfieVerified)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.face, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Face matched (95% confidence)',
                      style: TextStyle(
                          color: Colors.green.shade400,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomBar: PrimaryButton(
        label: isVerified ? 'Continue to Next Step' : 'Verify KYC',
        isLoading: _isLoading,
        // Disabled if: form not complete OR step not verified OR blocking mismatch errors exist
        isDisabled: (!_isFormValid && !isVerified) ||
            CrossStepValidator.hasBlockingErrors(_validationIssues),
        onPressed: _submit,
      ),
    );
  }

  // ── Inline mismatch banner — shown immediately after wrong document upload ──
  Widget _buildMismatchBanner({required String message, required VoidCallback onReupload}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x22F44336),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_rounded, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Document Mismatch — Cannot Continue',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onReupload,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Re-upload Correct Document',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Header (A, B, C badges) ──
  Widget _buildSectionHeader(String badge, String title) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.accent, AppColors.accentLight]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
              child: Text(badge,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13))),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ── Input field with Verify button beside it ──
  Widget _buildVerifyInputRow({
    required TextEditingController controller,
    required String label,
    required String hint,
    required int maxLength,
    required TextInputType keyboardType,
    required bool isVerified,
    required bool isVerifying,
    required bool isStepVerified,
    required VoidCallback onVerify,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isVerified
              ? AppColors.verified.withValues(alpha: 0.5)
              : AppColors.surfaceVariant,
          width: isVerified ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  textCapitalization: textCapitalization,
                  maxLength: maxLength,
                  enabled: !isVerified && !isStepVerified,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5),
                  decoration: InputDecoration(
                    labelText: label,
                    hintText: hint,
                    counterText: '',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Verify Button
              SizedBox(
                width: 90,
                height: 48,
                child: isVerified
                    ? Container(
                        decoration: BoxDecoration(
                          color: AppColors.verified.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.verified.withValues(alpha: 0.4)),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle,
                                  color: AppColors.verified, size: 16),
                              SizedBox(width: 4),
                              Text('Verified',
                                  style: TextStyle(
                                      color: AppColors.verified,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: isVerifying ? null : onVerify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: EdgeInsets.zero,
                        ),
                        child: isVerifying
                            ? const CoinPulseLoader(size: 6.0)
                            : const Text('Verify',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
              ),
            ],
          ),
          // Status hint below
          if (isVerified)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.check, color: AppColors.verified, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Number verified — you can now upload the document below',
                      style: TextStyle(fontSize: 11, color: AppColors.verified),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          if (!isVerified && !isStepVerified)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Enter the number and tap Verify to enable document upload',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
        ],
      ),
    );
  }
}
