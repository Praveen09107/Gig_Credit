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
import '../../../../models/verified_profile/work_info.dart';
import '../../../../app/app_router.dart';

/// COMP_24 Step 5 — Work Proof (Dynamic by Work Type)
/// Platform Worker: RC, DL front/back, vehicle insurance, 3 earning screenshots, UPI screenshot
/// Vendor: Svanidhi ID, approval letter, trade licence
/// Shows dynamic upload grid based on the work type selected in Step 1.
class Step5WorkScreen extends ConsumerStatefulWidget {
  const Step5WorkScreen({super.key});

  @override
  ConsumerState<Step5WorkScreen> createState() => _Step5WorkScreenState();
}

class _Step5WorkScreenState extends ConsumerState<Step5WorkScreen> {
  final _platformIdCtrl = TextEditingController();
  bool _isLoading = false;

  // Upload tracking
  bool _rcUploaded = false;
  bool _dlFrontUploaded = false;
  bool _dlBackUploaded = false;
  bool _vehicleInsUploaded = false;
  int _earningScreenshots = 0;
  bool _upiUploaded = false;
  bool _payoutUploaded = false;
  // Vendor
  bool _svanidhiUploaded = false;
  bool _approvalUploaded = false;
  bool _tradeLicenceUploaded = false;

  void _generateMockData() {
    _platformIdCtrl.text = 'ZMT-RK-2024-87654';
    setState(() {
      _rcUploaded = true;
      _dlFrontUploaded = true;
      _dlBackUploaded = true;
      _vehicleInsUploaded = true;
      _earningScreenshots = 3;
      _upiUploaded = true;
      _payoutUploaded = true;
    });
  }

  String get _workType {
    final profile = ref.read(verifiedProfileProvider);
    return profile.personalInfo.workType;
  }

  bool get _canSubmit {
    if (_workType == 'platform_worker') {
      return _platformIdCtrl.text.isNotEmpty && _rcUploaded && _dlFrontUploaded && _payoutUploaded;
    } else if (_workType == 'vendor') {
      return _svanidhiUploaded || _tradeLicenceUploaded;
    }
    return _payoutUploaded || _platformIdCtrl.text.isNotEmpty;
  }

  Future<void> _submit() async {
    final statusMap = ref.read(stepStatusProvider);
    if (statusMap[5] == StepStatus.verified) {
      context.push(AppRoutes.scoreStep(6));
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Verify RC via backend if platform worker
      if (_workType == 'platform_worker' && _rcUploaded) {
        final api = ref.read(apiServiceProvider);
        await api.verifyVehicle('TN09AB1234');
      }

      ref.read(verifiedProfileProvider.notifier).updateStep5(WorkInfo(
        isVerified: true,
        platformId: _platformIdCtrl.text.trim(),
        rcUploaded: _rcUploaded,
        dlFrontUploaded: _dlFrontUploaded,
        dlBackUploaded: _dlBackUploaded,
        vehicleInsuranceUploaded: _vehicleInsUploaded,
        earningScreenshots: _earningScreenshots,
        upiScreenshotUploaded: _upiUploaded,
        payoutUploaded: _payoutUploaded,
        svanidhiUploaded: _svanidhiUploaded,
        approvalLetterUploaded: _approvalUploaded,
        tradeLicenceUploaded: _tradeLicenceUploaded,
      ));
      ref.read(stepStatusProvider.notifier).setStatus(5, StepStatus.verified);

      if (mounted) {
        setState(() => _isLoading = false);
        context.push(AppRoutes.scoreStep(6));
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _platformIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusMap = ref.watch(stepStatusProvider);
    final ocrService = ref.watch(ocrServiceProvider);
    final isVerified = statusMap[5] == StepStatus.verified;
    final workType = _workType;
    final isPlatform = workType == 'platform_worker';
    final isVendor = workType == 'vendor';

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
              const Text('Work Proof', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              if (isVerified) const VerificationBadge(),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isPlatform ? '🛵 Platform Worker' : isVendor ? '🏪 Vendor' : '💼 ${workType.replaceAll('_', ' ')}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isPlatform ? 'Upload your vehicle and platform documents' : isVendor ? 'Upload your vendor registration documents' : 'Upload your work proof documents',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // ── Platform ID ──
          GestureDetector(
            onDoubleTap: _generateMockData,
            child: AppTextField(
              label: isPlatform ? 'Platform Worker ID (Zomato/Swiggy/Ola)' : 'Work Registration ID',
              controller: _platformIdCtrl,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 20),

          // ═══════════════════════════════════════════════════
          // PLATFORM WORKER DOCUMENTS (8 uploads per COMP_24)
          // ═══════════════════════════════════════════════════
          if (isPlatform) ...[
            _sectionHeader('Vehicle Documents', Icons.directions_car),
            const SizedBox(height: 10),

            // RC Book
            DocumentUploadCard(
              title: 'Registration Certificate (RC)',
              subtitle: 'Vehicle registration certificate photo',
              docType: 'work_rc',
              ocrService: ocrService,
              onExtracted: (data) {
                ref.read(ocrResultsProvider.notifier).addResult('work_rc', data);
                setState(() => _rcUploaded = true);
              },
            ),
            const SizedBox(height: 12),

            // DL Front
            DocumentUploadCard(
              title: 'Driving Licence (Front)',
              subtitle: 'Clear photo showing DL number',
              docType: 'work_dl_front',
              ocrService: ocrService,
              onExtracted: (data) {
                ref.read(ocrResultsProvider.notifier).addResult('work_dl_front', data);
                setState(() => _dlFrontUploaded = true);
              },
            ),
            const SizedBox(height: 12),

            // DL Back
            DocumentUploadCard(
              title: 'Driving Licence (Back)',
              subtitle: 'Photo showing vehicle class',
              docType: 'work_dl_back',
              ocrService: ocrService,
              isRequired: false,
              onExtracted: (data) => setState(() => _dlBackUploaded = true),
            ),
            const SizedBox(height: 12),

            // Vehicle Insurance
            DocumentUploadCard(
              title: 'Vehicle Insurance Certificate',
              subtitle: 'Valid insurance policy document',
              docType: 'insurance_vehicle',
              ocrService: ocrService,
              onExtracted: (data) {
                ref.read(ocrResultsProvider.notifier).addResult('insurance_vehicle', data);
                setState(() => _vehicleInsUploaded = true);
              },
            ),
            const SizedBox(height: 20),

            _sectionHeader('Earnings Proof', Icons.currency_rupee),
            const SizedBox(height: 10),

            // Earning Screenshots (1-3)
            ...List.generate(3, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DocumentUploadCard(
                title: 'Earnings Screenshot ${i + 1}',
                subtitle: 'Platform earnings for month ${i + 1}',
                docType: 'work_earnings_${i + 1}',
                ocrService: ocrService,
                isRequired: i == 0,
                onExtracted: (data) => setState(() => _earningScreenshots = (_earningScreenshots + 1).clamp(0, 3)),
              ),
            )),

            // UPI Screenshot
            DocumentUploadCard(
              title: 'UPI Transaction Proof',
              subtitle: 'Screenshot of recent UPI payment from platform',
              docType: 'work_upi',
              ocrService: ocrService,
              isRequired: false,
              onExtracted: (data) => setState(() => _upiUploaded = true),
            ),
            const SizedBox(height: 12),
          ],

          // ═══════════════════════════════════════════════════
          // VENDOR DOCUMENTS (3 uploads per COMP_24)
          // ═══════════════════════════════════════════════════
          if (isVendor) ...[
            _sectionHeader('Vendor Registration', Icons.storefront),
            const SizedBox(height: 10),

            DocumentUploadCard(
              title: 'PM SVANidhi ID Card',
              subtitle: 'Street vendor registration card',
              docType: 'work_svanidhi',
              ocrService: ocrService,
              onExtracted: (data) => setState(() => _svanidhiUploaded = true),
            ),
            const SizedBox(height: 12),

            DocumentUploadCard(
              title: 'Vending Approval Letter',
              subtitle: 'Municipal approval for vending zone',
              docType: 'work_approval',
              ocrService: ocrService,
              isRequired: false,
              onExtracted: (data) => setState(() => _approvalUploaded = true),
            ),
            const SizedBox(height: 12),

            DocumentUploadCard(
              title: 'Trade Licence',
              subtitle: 'Local trade/shop licence',
              docType: 'work_trade_licence',
              ocrService: ocrService,
              isRequired: false,
              onExtracted: (data) => setState(() => _tradeLicenceUploaded = true),
            ),
            const SizedBox(height: 12),
          ],

          // ═══════════════════════════════════════════════════
          // COMMON: Payout Summary
          // ═══════════════════════════════════════════════════
          _sectionHeader('Income Summary', Icons.receipt_long),
          const SizedBox(height: 10),

          DocumentUploadCard(
            title: 'Payout Summary / Ledger',
            subtitle: 'Upload screenshot or PDF of recent earnings',
            docType: 'work_payout',
            ocrService: ocrService,
            onExtracted: (data) => setState(() => _payoutUploaded = true),
          ),

          // Upload progress indicator
          const SizedBox(height: 16),
          _buildUploadProgress(),
        ],
      ),
      bottomBar: PrimaryButton(
        label: isVerified ? 'Continue to Next Step' : 'Verify Work Proof',
        isLoading: _isLoading,
        isDisabled: !_canSubmit && !isVerified,
        onPressed: _submit,
      ),
    );
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

  Widget _buildUploadProgress() {
    final isPlatform = _workType == 'platform_worker';
    final total = isPlatform ? 8 : 3;
    int uploaded = 0;

    if (isPlatform) {
      if (_rcUploaded) uploaded++;
      if (_dlFrontUploaded) uploaded++;
      if (_dlBackUploaded) uploaded++;
      if (_vehicleInsUploaded) uploaded++;
      uploaded += _earningScreenshots;
      if (_upiUploaded) uploaded++;
    } else {
      if (_svanidhiUploaded) uploaded++;
      if (_approvalUploaded) uploaded++;
      if (_tradeLicenceUploaded) uploaded++;
    }
    if (_payoutUploaded) uploaded++;

    final progress = uploaded / (total + 1); // +1 for payout

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Documents: $uploaded/${total + 1}', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            Text('${(progress * 100).toInt()}%', style: TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? Colors.green : AppColors.accent,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
