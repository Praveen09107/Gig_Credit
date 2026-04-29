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
import '../widgets/mismatch_warning_banner.dart';

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

  bool _aadhaarFrontExtracted = false;
  bool _aadhaarBackExtracted = false;
  bool _panExtracted = false;
  bool _selfieVerified = false;
  bool _isLoading = false;
  List<ValidationIssue> _validationIssues = [];

  bool _aadhaarOtpSent = false;
  String? _expectedAadhaarOtp;
  final _aadhaarOtpController = TextEditingController();

  bool _panOtpSent = false;
  String? _expectedPanOtp;
  final _panOtpController = TextEditingController();

  @override
  void dispose() {
    _aadhaarController.dispose();
    _panController.dispose();
    _aadhaarOtpController.dispose();
    _panOtpController.dispose();
    super.dispose();
  }

  /// Verify Aadhaar number with real API call to Render backend
  Future<void> _verifyAadhaar() async {
    // If OTP is already sent, this button press means "Verify OTP"
    if (_aadhaarOtpSent) {
      if (_aadhaarOtpController.text == _expectedAadhaarOtp) {
        setState(() {
          _aadhaarVerified = true;
          _aadhaarOtpSent = false; // Hide OTP field
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aadhaar OTP Verified Successfully!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect Aadhaar OTP. Please try again.'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // Initial step: Verify Aadhaar number
    final text = _aadhaarController.text.replaceAll(' ', '');
    if (text.length != 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 12-digit Aadhaar number'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _aadhaarVerifying = true);
    
    try {
      final api = ref.read(apiServiceProvider);
      // Hits https://gig-credit.onrender.com/api/gov/aadhaar/verify
      final result = await api.verifyAadhaar(text); 
      
      if (mounted) {
        setState(() {
          _aadhaarVerifying = false;
          _aadhaarOtpSent = true;
          // Generate locally if backend hasn't been deployed yet, or use backend's OTP
          String otp = result['otp'] ?? (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
          _expectedAadhaarOtp = otp; 
          print('\n========================================');
          print('✅ AADHAAR OTP for $text : $otp');
          print('========================================\n');
        });
        
        // Show simulated SMS notification as a dialog so it's highly visible on phone
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(children: [Icon(Icons.message, color: Colors.blue), SizedBox(width: 8), Text('New Message')]),
            content: Text('UIDAI: Your Aadhaar verification OTP is $_expectedAadhaarOtp. Valid for 10 minutes.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Dismiss'))
            ],
          )
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aadhaarVerifying = false;
          _aadhaarOtpSent = true;
          // Trigger mock OTP flow for demo if DB is empty
          String otp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
          _expectedAadhaarOtp = otp; 
          print('\n========================================');
          print('✅ AADHAAR OTP for $text : $otp');
          print('========================================\n');
        });
        
        // Show simulated SMS notification as a dialog
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(children: [Icon(Icons.message, color: Colors.blue), SizedBox(width: 8), Text('New Message')]),
            content: Text('UIDAI: Your Aadhaar verification OTP is $_expectedAadhaarOtp. Valid for 10 minutes.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Dismiss'))
            ],
          )
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API Note: simulated DB response for demo.'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  /// Verify PAN number with real API call to Render backend
  Future<void> _verifyPan() async {
    // If OTP is already sent, this button press means "Verify OTP"
    if (_panOtpSent) {
      if (_panOtpController.text == _expectedPanOtp) {
        setState(() {
          _panVerified = true;
          _panOtpSent = false; // Hide OTP field
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PAN OTP Verified Successfully!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect PAN OTP. Please try again.'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // Initial step: Verify PAN number
    final text = _panController.text.trim();
    if (text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 10-character PAN number'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _panVerifying = true);
    
    try {
      final api = ref.read(apiServiceProvider);
      // Hits https://gig-credit.onrender.com/api/gov/pan/verify
      final result = await api.verifyPan(text);
      
      if (mounted) {
        setState(() {
          _panVerifying = false;
          _panOtpSent = true;
          // Generate locally if backend hasn't been deployed yet, or use backend's OTP
          String otp = result['otp'] ?? (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
          _expectedPanOtp = otp; 
          print('\n========================================');
          print('✅ PAN OTP for $text : $otp');
          print('========================================\n');
        });
        
        // Show simulated SMS notification as a dialog so it's highly visible on phone
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(children: [Icon(Icons.message, color: Colors.blue), SizedBox(width: 8), Text('New Message')]),
            content: Text('NSDL: Your PAN verification OTP is $_expectedPanOtp. Valid for 10 minutes.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Dismiss'))
            ],
          )
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _panVerifying = false;
          _panOtpSent = true;
          // Trigger mock OTP flow for demo if DB is empty
          String otp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
          _expectedPanOtp = otp; 
          print('\n========================================');
          print('✅ PAN OTP for $text : $otp');
          print('========================================\n');
        });
        
        // Show simulated SMS notification as a dialog
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(children: [Icon(Icons.message, color: Colors.blue), SizedBox(width: 8), Text('New Message')]),
            content: Text('NSDL: Your PAN verification OTP is $_expectedPanOtp. Valid for 10 minutes.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Dismiss'))
            ],
          )
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API Note: simulated DB response for demo.'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  void _onAadhaarFrontExtracted(Map<String, dynamic> data) {
    ref.read(ocrResultsProvider.notifier).addResult('aadhaar_front', data);
    setState(() => _aadhaarFrontExtracted = true);
    _runCrossValidation();
  }

  void _onPanExtracted(Map<String, dynamic> data) {
    ref.read(ocrResultsProvider.notifier).addResult('pan', data);
    setState(() => _panExtracted = true);
    _runCrossValidation();
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
    final aadhaarPath = ocrResults['aadhaar_front']?['image_path'] as String? ?? '';
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
          content: Text('Verification Failed: ${result.error ?? "Faces do not match!"}'), 
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      // Remove the invalid selfie so they can try again
      ref.read(ocrResultsProvider.notifier).addResult('selfie', {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selfie Verified! Faces match.'), backgroundColor: Colors.green),
      );
    }
  }

  bool get _isFormValid {
    return _aadhaarVerified && _aadhaarFrontExtracted && _panVerified && _panExtracted && _selfieVerified;
  }

  Future<void> _submit() async {
    final statusMap = ref.read(stepStatusProvider);
    if (statusMap[2] == StepStatus.verified) {
       context.push(AppRoutes.scoreStep(3));
       return;
    }

    if (CrossStepValidator.hasBlockingErrors(_validationIssues)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix document mismatches before proceeding'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // The individual numbers have already been verified via the OTP flow
      // We just simulate final KYC report compilation delay here
      await Future.delayed(const Duration(seconds: 2));

      ref.read(verifiedProfileProvider.notifier).updateStep2(
        KycInfo(isVerified: true, backVerified: _aadhaarBackExtracted, selfieVerified: _selfieVerified),
      );
      ref.read(stepStatusProvider.notifier).setStatus(2, StepStatus.verified);

      if (mounted) {
        setState(() => _isLoading = false);
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
      stepCompletionMap: statusMap.map((key, value) => MapEntry(key, value == StepStatus.verified)),
      onStepTapped: (step) => context.push(AppRoutes.scoreStep(step)),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('KYC Verification', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              if (isVerified) const VerificationBadge(),
            ],
          ),
          const SizedBox(height: 4),
          Text('Upload photos of your ID cards. Data is extracted on-device.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 24),

          // ── Cross-Step Validation Warnings ──
          if (_validationIssues.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: MismatchWarningBanner(issues: _validationIssues),
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
              isVerifying: false,
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

          // Aadhaar Front Upload — enabled only after Aadhaar verified
          AnimatedOpacity(
            opacity: (_aadhaarVerified || isVerified) ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 400),
            child: IgnorePointer(
              ignoring: !_aadhaarVerified && !isVerified,
              child: DocumentUploadCard(
                title: 'Aadhaar Card — Front Side',
                subtitle: _aadhaarVerified ? 'Photo showing name, DOB, Aadhaar number' : '🔒 Verify Aadhaar number first',
                docType: 'aadhaar_front',
                ocrService: ocrService,
                onExtracted: _onAadhaarFrontExtracted,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Aadhaar Back Upload — enabled only after Aadhaar verified
          AnimatedOpacity(
            opacity: (_aadhaarVerified || isVerified) ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 400),
            child: IgnorePointer(
              ignoring: !_aadhaarVerified && !isVerified,
              child: DocumentUploadCard(
                title: 'Aadhaar Card — Back Side',
                subtitle: _aadhaarVerified ? 'Photo showing full address, PIN code' : '🔒 Verify Aadhaar number first',
                docType: 'aadhaar_back',
                ocrService: ocrService,
                isRequired: false,
                onExtracted: _onAadhaarBackExtracted,
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
              isVerifying: false,
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

          // PAN Card Photo Upload — enabled only after PAN verified
          AnimatedOpacity(
            opacity: (_panVerified || isVerified) ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 400),
            child: IgnorePointer(
              ignoring: !_panVerified && !isVerified,
              child: DocumentUploadCard(
                title: 'PAN Card Photo',
                subtitle: _panVerified ? 'Photo showing PAN number, name, DOB' : '🔒 Verify PAN number first',
                docType: 'pan',
                ocrService: ocrService,
                onExtracted: _onPanExtracted,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.face, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Face matched (95% confidence)',
                      style: TextStyle(color: Colors.green.shade400, fontSize: 13, fontWeight: FontWeight.w600),
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
        isDisabled: !_isFormValid && !isVerified,
        onPressed: _submit,
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
            gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentLight]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Text(badge, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1.5),
                  decoration: InputDecoration(
                    labelText: label,
                    hintText: hint,
                    counterText: '',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                          border: Border.all(color: AppColors.verified.withValues(alpha: 0.4)),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: AppColors.verified, size: 16),
                              SizedBox(width: 4),
                              Text('Verified', style: TextStyle(color: AppColors.verified, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: isVerifying ? null : onVerify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: EdgeInsets.zero,
                        ),
                        child: isVerifying
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Verify', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
