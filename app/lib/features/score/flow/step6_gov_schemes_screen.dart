import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/layout/scrollable_step_layout.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/inputs/document_upload_card.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/buttons/secondary_button.dart';
import '../../../../shared/widgets/status/verification_badge.dart';
import '../../../../state/step_status_provider.dart';
import '../../../../state/verified_profile_provider.dart';
import '../../../../state/ocr_service_provider.dart';
import '../../../../state/api_service_provider.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../models/verified_profile/gov_schemes_info.dart';
import '../../../../app/app_router.dart';
import '../../../../demo/demo_profile_manager.dart';

class Step6GovSchemesScreen extends ConsumerStatefulWidget {
  const Step6GovSchemesScreen({super.key});

  @override
  ConsumerState<Step6GovSchemesScreen> createState() => _Step6GovSchemesScreenState();
}

class _Step6GovSchemesScreenState extends ConsumerState<Step6GovSchemesScreen> {
  bool _isLoading = false;

  // Scheme toggles
  bool _hasSvanidhi = false;
  bool _hasEshram = false;
  bool _hasPmsym = false;
  bool _hasPmjjby = false;
  bool _hasMudra = false;
  bool _hasPpf = false;
  bool _hasUdyam = false;

  // Scheme IDs
  final _svanidhiIdCtrl = TextEditingController();
  final _eshramUanCtrl = TextEditingController();
  final _pmsymAccCtrl = TextEditingController();
  final _pmjjbyUrnCtrl = TextEditingController();
  final _mudraAccCtrl = TextEditingController();
  final _ppfAccCtrl = TextEditingController();
  final _udyamRegCtrl = TextEditingController();

  // Upload status
  bool _svanidhiUploaded = false;
  bool _eshramUploaded = false;
  bool _pmsymUploaded = false;
  bool _pmjjbyUploaded = false;
  bool _mudraUploaded = false;
  bool _ppfUploaded = false;
  bool _udyamUploaded = false;

  @override
  void dispose() {
    _svanidhiIdCtrl.dispose();
    _eshramUanCtrl.dispose();
    _pmsymAccCtrl.dispose();
    _pmjjbyUrnCtrl.dispose();
    _mudraAccCtrl.dispose();
    _ppfAccCtrl.dispose();
    _udyamRegCtrl.dispose();
    super.dispose();
  }

  /// Demo autofill — populates gov schemes from demo profile
  void _fillFromDemoProfile() {
    final s = DemoProfileManager().profile.govSchemesInfo;
    setState(() {
      if (s.hasEshram) {
        _hasEshram = true;
        _eshramUanCtrl.text = '123456789012';
        _eshramUploaded = true;
      }
      if (s.hasPmScheme) {
        _hasSvanidhi = true;
        _svanidhiIdCtrl.text = 'SVN12345678';
        _svanidhiUploaded = true;
      }
    });
  }

  Future<void> _submit() async {
    final statusMap = ref.read(stepStatusProvider);
    if (statusMap[6] == StepStatus.verified) {
       context.push(AppRoutes.scoreStep(7));
       return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      ref.read(verifiedProfileProvider.notifier).updateStep6(GovSchemesInfo(
        isVerified: true,
        hasEshram: _hasEshram,
        hasPmScheme: _hasSvanidhi || _hasPmsym || _hasPmjjby || _hasMudra,
        // _hasUdyam or _hasPpf could be mapped if fields existed, ignoring for now
      ));
      ref.read(stepStatusProvider.notifier).setStatus(6, StepStatus.verified);
      
      if (mounted) {
        setState(() => _isLoading = false);
        context.push(AppRoutes.scoreStep(7));
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _skip() {
    ref.read(stepStatusProvider.notifier).setStatus(6, StepStatus.verified);
    context.push(AppRoutes.scoreStep(7));
  }

  @override
  Widget build(BuildContext context) {
    final statusMap = ref.watch(stepStatusProvider);
    final ocrService = ref.watch(ocrServiceProvider);
    final isVerified = statusMap[6] == StepStatus.verified;

    return ScrollableStepLayout(
      currentStep: 6,
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
                child: const Text('Gov Schemes', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              if (isVerified) const VerificationBadge(),
            ],
          ),
          const SizedBox(height: 4),
          Text('All optional. Toggle schemes you are enrolled in.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 20),

          _buildSchemeModule(title: '🛒 PM SVANidhi', hint: 'Street Vendor Scheme', selected: _hasSvanidhi, onToggle: (v) => setState(() => _hasSvanidhi = v), children: [
            AppTextField(label: 'SVANidhi Application ID *', controller: _svanidhiIdCtrl),
            const SizedBox(height: 12),
            DocumentUploadCard(title: 'SVANidhi Proof *', subtitle: 'Approval / sanction letter', docType: 'gov_svanidhi', ocrService: ocrService, onExtracted: (_) => setState(() => _svanidhiUploaded = true)),
          ]),

          _buildSchemeModule(title: '👷 eShram Registration', hint: 'Unorganised Workers UAN', selected: _hasEshram, onToggle: (v) => setState(() => _hasEshram = v), children: [
            AppTextField(label: 'UAN (12-digit) *', controller: _eshramUanCtrl, keyboardType: TextInputType.number, maxLength: 12),
            const SizedBox(height: 12),
            DocumentUploadCard(title: 'eShram Card Upload *', subtitle: 'Photo of eShram card', docType: 'gov_eshram', ocrService: ocrService, onExtracted: (_) => setState(() => _eshramUploaded = true)),
          ]),

          _buildSchemeModule(title: '🏦 PM-SYM Pension', hint: 'Shram Yogi Maandhan Pension', selected: _hasPmsym, onToggle: (v) => setState(() => _hasPmsym = v), children: [
            AppTextField(label: 'Pension Account Number *', controller: _pmsymAccCtrl),
            const SizedBox(height: 12),
            DocumentUploadCard(title: 'PM-SYM Proof *', subtitle: 'Pension card / acknowledgement', docType: 'gov_pmsym', ocrService: ocrService, onExtracted: (_) => setState(() => _pmsymUploaded = true)),
          ]),

          _buildSchemeModule(title: '🛡️ PMJJBY Life Insurance', hint: 'Pradhan Mantri Jeevan Jyoti Bima', selected: _hasPmjjby, onToggle: (v) => setState(() => _hasPmjjby = v), children: [
            AppTextField(label: 'Unique Reference Number (URN) *', controller: _pmjjbyUrnCtrl),
            const SizedBox(height: 12),
            DocumentUploadCard(title: 'PMJJBY Certificate *', subtitle: 'Certificate of Insurance (COI)', docType: 'gov_pmjjby', ocrService: ocrService, onExtracted: (_) => setState(() => _pmjjbyUploaded = true)),
          ]),

          _buildSchemeModule(title: '💰 PMMY / Mudra Loan', hint: 'Pradhan Mantri Mudra Yojana', selected: _hasMudra, onToggle: (v) => setState(() => _hasMudra = v), children: [
            AppTextField(label: 'Mudra Loan Account Number *', controller: _mudraAccCtrl),
            const SizedBox(height: 12),
            DocumentUploadCard(title: 'Mudra Loan Proof *', subtitle: 'Sanction letter / account statement', docType: 'gov_mudra', ocrService: ocrService, onExtracted: (_) => setState(() => _mudraUploaded = true)),
          ]),

          _buildSchemeModule(title: '📗 PPF Account', hint: 'Public Provident Fund', selected: _hasPpf, onToggle: (v) => setState(() => _hasPpf = v), children: [
            AppTextField(label: 'PPF Account Number *', controller: _ppfAccCtrl),
            const SizedBox(height: 12),
            DocumentUploadCard(title: 'PPF Passbook *', subtitle: 'Passbook identity page / statement', docType: 'gov_ppf', ocrService: ocrService, onExtracted: (_) => setState(() => _ppfUploaded = true)),
          ]),

          _buildSchemeModule(title: '🏭 Udyam / MSME', hint: 'MSME Registration', selected: _hasUdyam, onToggle: (v) => setState(() => _hasUdyam = v), children: [
            AppTextField(label: 'Udyam Registration Number *', controller: _udyamRegCtrl),
            const SizedBox(height: 12),
            DocumentUploadCard(title: 'Udyam Certificate *', subtitle: 'Registration certificate PDF/photo', docType: 'gov_udyam', ocrService: ocrService, onExtracted: (_) => setState(() => _udyamUploaded = true)),
          ]),

          const SizedBox(height: 16),
          if (!isVerified)
            SecondaryButton(label: 'Skip this step', onPressed: _skip),
        ],
      ),
      bottomBar: PrimaryButton(
        label: isVerified ? 'Continue to Next Step' : 'Confirm & Proceed',
        isLoading: _isLoading,
        isDisabled: false,
        onPressed: _submit,
      ),
    );
  }

  Widget _buildSchemeModule({
    required String title,
    required String hint,
    required bool selected,
    required ValueChanged<bool> onToggle,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: selected ? AppColors.accent.withValues(alpha: 0.4) : AppColors.surfaceVariant),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(hint, style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            value: selected,
            onChanged: onToggle,
            activeColor: AppColors.accent,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
          if (selected)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Divider(height: 1),
                const SizedBox(height: 16),
                ...children,
              ]),
            ),
        ],
      ),
    );
  }
}
