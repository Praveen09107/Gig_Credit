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
import '../../../../core/enums/app_enums.dart';
import '../../../../models/verified_profile/work_info.dart';
import '../../../../app/app_router.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';
import '../../../../shared/widgets/feedback/step_popups.dart';
import '../../../../shared/widgets/feedback/verification_phase_overlay.dart';
import '../../../../services/gig_logger.dart';

import '../../../../shared/widgets/feedback/step_validation_banner.dart';

class Step5WorkScreen extends ConsumerStatefulWidget {
  const Step5WorkScreen({super.key});

  @override
  ConsumerState<Step5WorkScreen> createState() => _Step5WorkScreenState();
}

class _Step5WorkScreenState extends ConsumerState<Step5WorkScreen> with VerificationPhaseMixin {
  bool _isLoading = false;

  // Type A: Platform Worker
  final _platformIdCtrl = TextEditingController();
  bool _rcUploaded = false;
  bool _dlFrontUploaded = false;
  bool _dlBackUploaded = false;
  bool _vehicleInsUploaded = false;
  int _earningScreenshots = 0;
  bool _upiUploaded = false;

  // Type B: Vendor
  final _svanidhiIdCtrl = TextEditingController();
  bool _svanidhiUploaded = false;
  bool _tradeLicenceUploaded = false;

  // Type C: Tradesperson
  final _skillCertIdCtrl = TextEditingController();
  bool _skillCertUploaded = false;
  bool _workOrderUploaded = false;

  // Type D: Freelancer
  bool _freelanceProfileUploaded = false;
  int _freelanceInvoices = 0;

  // Inline validation
  List<String> _validationErrors = [];
  List<String> _validationWarnings = [];

  void _runInlineValidation() {
    final errors = <String>[];
    final workType = _workType;
    // Vehicle registration format check for platform workers
    if ((workType == 'platform_worker' || workType == 'gig_worker') &&
        _platformIdCtrl.text.trim().isNotEmpty) {
      final rc = _platformIdCtrl.text.trim().toUpperCase();
      if (!RegExp(r'^[A-Z]{2}\d{2}[A-Z]{1,3}\d{1,4}$').hasMatch(rc)) {
        errors.add('Vehicle registration number format is invalid (e.g. TN09AB1234).');
      }
    }
    setState(() { _validationErrors = errors; _validationWarnings = []; });
  }

  String get _workType {
    final profile = ref.read(verifiedProfileProvider);
    return profile.personalInfo.workType;
  }

  /// Demo autofill — marks work proof uploads as complete from demo profile
  void _fillFromDemoProfile() {
    _platformIdCtrl.text = 'TN09AB1234';
    _svanidhiIdCtrl.text = 'SVN12345678';
    _skillCertIdCtrl.text = 'NSDC-2023-457892';
    setState(() {
      _rcUploaded = true;
      _dlFrontUploaded = true;
      _dlBackUploaded = true;
      _vehicleInsUploaded = true;
      _earningScreenshots = 3;
      _upiUploaded = true;
      _svanidhiUploaded = true;
      _tradeLicenceUploaded = true;
      _skillCertUploaded = true;
      _workOrderUploaded = true;
      _freelanceProfileUploaded = true;
      _freelanceInvoices = 3;
    });
  }

  Future<void> _submit() async {
    final statusMap = ref.read(stepStatusProvider);
    if (statusMap[5] == StepStatus.verified) {
      context.push(AppRoutes.scoreStep(6));
      return;
    }

    setState(() => _isLoading = true);

    // Show confirmation popup before proceeding
    final confirmed = await StepConfirmPopup.show(context, stepNumber: 5);
    if (!confirmed || !mounted) {
      setState(() => _isLoading = false);
      return;
    }

    showVerificationPhase();
    try {
      final api = ref.read(apiServiceProvider);
      final workType = _workType;

      // Real backend verification for platform workers with vehicle
      if ((workType == 'platform_worker' || workType == 'gig_worker') && _platformIdCtrl.text.trim().isNotEmpty) {
        try {
          final vehicleResult = await api.verifyVehicle(_platformIdCtrl.text.trim());
          debugPrint('[Step5] Vehicle RC verified: ${vehicleResult['owner_name']}');
        } catch (e) {
          debugPrint('[Step5] Vehicle verification skipped: $e');
          // Non-blocking — vehicle verification is supplementary
        }
      }

      // Backend API call for Gig History (already have vehicle check above)
      if ((workType == 'platform_worker' || workType == 'gig_worker') && _platformIdCtrl.text.trim().isNotEmpty) {
        try {
          final gigResult = await api.getGigHistory(_platformIdCtrl.text.trim());
          debugPrint('[Step5 API] Gig history: ${gigResult['status'] ?? 'ok'}');
        } catch (e) {
          debugPrint('[Step5 API] Gig history skipped: $e');
        }
      }

      GigLogger.stepBanner(5, 'WORK PROOF (OPTIONAL) — VERIFICATION');
      GigLogger.sectionHeader('RAW INPUTS');
      GigLogger.data('Work Type',      _workType);
      GigLogger.data('Platform ID',    _platformIdCtrl.text.trim().isNotEmpty ? _platformIdCtrl.text.trim() : 'N/A');
      GigLogger.data('RC Uploaded',    _rcUploaded.toString());
      GigLogger.data('DL Uploaded',    _dlFrontUploaded.toString());
      GigLogger.data('Earning Shots',  '$_earningScreenshots');
      GigLogger.data('UPI Screenshot', _upiUploaded.toString());

      dismissVerificationPhase();

      ref.read(verifiedProfileProvider.notifier).updateStep5(WorkInfo(
        isVerified: true,
        platformId: _platformIdCtrl.text.trim(),
        rcUploaded: _rcUploaded,
        dlFrontUploaded: _dlFrontUploaded,
        dlBackUploaded: _dlBackUploaded,
        vehicleInsuranceUploaded: _vehicleInsUploaded,
        earningScreenshots: _earningScreenshots,
        upiScreenshotUploaded: _upiUploaded,
        svanidhiUploaded: _svanidhiUploaded,
        tradeLicenceUploaded: _tradeLicenceUploaded,
        // The other fields aren't in WorkInfo strictly, but UI allows progress
      ));
      ref.read(stepStatusProvider.notifier).setStatus(5, StepStatus.verified);

      GigLogger.sectionHeader('GLOBAL STATE UPDATE');
      GigLogger.stateUpdate('verifiedProfileProvider', 'workInfo.platformId',    _platformIdCtrl.text.trim());
      GigLogger.stateUpdate('verifiedProfileProvider', 'workInfo.isVerified',    'true');
      GigLogger.stateUpdate('stepStatusProvider',      'step[5]',                'StepStatus.verified');
      GigLogger.ok('Step 5 Work Proof complete');

      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.success(context, 'Work proof verified ✓');
        context.push(AppRoutes.scoreStep(6));
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _platformIdCtrl.dispose();
    _svanidhiIdCtrl.dispose();
    _skillCertIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusMap = ref.watch(stepStatusProvider);
    final ocrService = ref.watch(ocrServiceProvider);
    final isVerified = statusMap[5] == StepStatus.verified;
    final workType = _workType;

    return ScrollableStepLayout(
      currentStep: 5,
      stepCompletionMap: statusMap.map((key, value) => MapEntry(key, value == StepStatus.verified)),
      onStepTapped: (step) => context.push(AppRoutes.scoreStep(step)),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onDoubleTap: _fillFromDemoProfile,
                child: const Text('Work Proof', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              if (isVerified) const VerificationBadge(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _getSubtitle(workType),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // ── Inline validation banner ──
          if (_validationErrors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: StepValidationBanner(
                errors: _validationErrors,
                onDismiss: () => setState(() => _validationErrors = []),
              ),
            ),

          if (workType == 'platform_worker' || workType == 'gig_worker') 
            _buildPlatformWorker(ocrService)
          else if (workType == 'vendor') 
            _buildVendor(ocrService)
          else if (workType == 'tradesperson') 
            _buildTradesperson(ocrService)
          else if (workType == 'freelancer' || workType == 'self_employed') 
            _buildFreelancer(ocrService)
          else 
            _buildGenericWork(ocrService),
        ],
      ),
      bottomBar: PrimaryButton(
        label: isVerified ? 'Continue to Next Step' : 'Save & Continue',
        isLoading: _isLoading,
        isDisabled: false, // Step 5 onwards always enabled per user request
        onPressed: _submit,
      ),
    );
  }

  String _getSubtitle(String type) {
    switch (type) {
      case 'platform_worker': return 'Upload your vehicle documents and earnings screenshots from your platform app.';
      case 'vendor': return 'Upload your SVANidhi scheme documents and trade licence.';
      case 'tradesperson': return 'Upload your NSDC skill certificate and a recent work order.';
      case 'freelancer': return 'Upload a screenshot of your platform profile and client invoices.';
      default: return 'Upload your work proof documents';
    }
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.accent),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildPlatformWorker(ocrService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Vehicle Documents', Icons.directions_car),
        const SizedBox(height: 10),
        AppTextField(
          label: 'Vehicle Registration Number *',
          controller: _platformIdCtrl,
          onChanged: (_) { setState(() {}); _runInlineValidation(); },
        ),
        const SizedBox(height: 12),
        DocumentUploadCard(
          title: 'RC Book (Front) *',
          subtitle: 'Vehicle registration certificate photo',
          docType: 'work_rc',
          ocrService: ocrService,
          onExtracted: (data) => setState(() => _rcUploaded = true),
        ),
        const SizedBox(height: 12),
        DocumentUploadCard(
          title: 'Driving Licence (Front) *',
          subtitle: 'Clear photo showing DL number',
          docType: 'work_dl_front',
          ocrService: ocrService,
          onExtracted: (data) => setState(() => _dlFrontUploaded = true),
        ),
        const SizedBox(height: 12),
        DocumentUploadCard(
          title: 'Driving Licence (Back) *',
          subtitle: 'Photo showing vehicle class',
          docType: 'work_dl_back',
          ocrService: ocrService,
          onExtracted: (data) => setState(() => _dlBackUploaded = true),
        ),
        const SizedBox(height: 12),
        DocumentUploadCard(
          title: 'Vehicle Insurance Certificate *',
          subtitle: 'Valid insurance policy document',
          docType: 'insurance_vehicle',
          ocrService: ocrService,
          onExtracted: (data) => setState(() => _vehicleInsUploaded = true),
        ),
        const SizedBox(height: 24),
        _sectionHeader('Platform Earnings', Icons.currency_rupee),
        const SizedBox(height: 10),
        ...List.generate((_earningScreenshots < 3 ? _earningScreenshots + 1 : 3), (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DocumentUploadCard(
            title: 'Earnings Screenshot ${i + 1} *',
            subtitle: 'Platform earnings for month ${i + 1}',
            docType: 'work_earnings_${i + 1}',
            ocrService: ocrService,
            onExtracted: (data) => setState(() => _earningScreenshots = (_earningScreenshots + 1).clamp(0, 3)),
          ),
        )),
      ],
    );
  }

  Widget _buildVendor(ocrService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('SVANidhi Scheme', Icons.storefront),
        const SizedBox(height: 10),
        AppTextField(
          label: 'PM SVANidhi Application ID *',
          controller: _svanidhiIdCtrl,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        DocumentUploadCard(
          title: 'SVANidhi Approval Letter *',
          subtitle: 'Upload approval letter',
          docType: 'work_svanidhi',
          ocrService: ocrService,
          onExtracted: (data) => setState(() => _svanidhiUploaded = true),
        ),
        const SizedBox(height: 24),
        _sectionHeader('Business Licence', Icons.assignment),
        const SizedBox(height: 10),
        DocumentUploadCard(
          title: 'Municipal Trade Licence *',
          subtitle: 'Local trade/shop licence',
          docType: 'work_trade_licence',
          ocrService: ocrService,
          onExtracted: (data) => setState(() => _tradeLicenceUploaded = true),
        ),
      ],
    );
  }

  Widget _buildTradesperson(ocrService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Skill Certification', Icons.handyman),
        const SizedBox(height: 10),
        AppTextField(
          label: 'Skill Certificate ID *',
          controller: _skillCertIdCtrl,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        DocumentUploadCard(
          title: 'NSDC / Skill Certificate *',
          subtitle: 'Image or PDF',
          docType: 'work_skill_cert',
          ocrService: ocrService,
          onExtracted: (data) => setState(() => _skillCertUploaded = true),
        ),
        const SizedBox(height: 24),
        _sectionHeader('Work Proof', Icons.assignment_turned_in),
        const SizedBox(height: 10),
        DocumentUploadCard(
          title: 'Work Order Letter *',
          subtitle: 'Recent work order proof',
          docType: 'work_order',
          ocrService: ocrService,
          onExtracted: (data) => setState(() => _workOrderUploaded = true),
        ),
      ],
    );
  }

  Widget _buildFreelancer(ocrService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Platform Profile', Icons.laptop_mac),
        const SizedBox(height: 10),
        DocumentUploadCard(
          title: 'Freelance Platform Profile Screenshot *',
          subtitle: 'Screenshot showing your name, rating, earnings',
          docType: 'work_freelance_profile',
          ocrService: ocrService,
          onExtracted: (data) => setState(() => _freelanceProfileUploaded = true),
        ),
        const SizedBox(height: 24),
        _sectionHeader('Client Invoices', Icons.receipt),
        const SizedBox(height: 10),
        ...List.generate((_freelanceInvoices < 5 ? _freelanceInvoices + 1 : 5), (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DocumentUploadCard(
            title: 'Client Invoice ${i + 1} ${i == 0 ? '*' : '(Optional)'}',
            subtitle: 'Upload client invoice (JPG/PNG/PDF)',
            docType: 'work_freelance_invoice_${i + 1}',
            ocrService: ocrService,
            onExtracted: (data) => setState(() => _freelanceInvoices = (_freelanceInvoices + 1).clamp(0, 5)),
          ),
        )),
      ],
    );
  }

  Widget _buildGenericWork(ocrService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Proof of Work / Income', Icons.work),
        const SizedBox(height: 10),
        DocumentUploadCard(
          title: 'Work ID / Badge / Pay Slip *',
          subtitle: 'Upload proof of your employment or income',
          docType: 'work_generic',
          ocrService: ocrService,
          onExtracted: (data) => setState(() => _rcUploaded = true), // Reuse a boolean flag to track upload
        ),
      ],
    );
  }
}
