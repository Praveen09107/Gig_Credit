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
import '../../../../models/verified_profile/tax_info.dart';
import '../../../../app/app_router.dart';
import '../../../../demo/demo_profile_manager.dart';

class Step8TaxScreen extends ConsumerStatefulWidget {
  const Step8TaxScreen({super.key});

  @override
  ConsumerState<Step8TaxScreen> createState() => _Step8TaxScreenState();
}

class _Step8TaxScreenState extends ConsumerState<Step8TaxScreen> {
  bool _isLoading = false;
  bool _hasItr = false;
  bool _hasGst = false;

  // ITR fields
  final _itrPanCtrl = TextEditingController();
  final _itrNameCtrl = TextEditingController();
  final _itrIncomeCtrl = TextEditingController();
  String _assessmentYear = '2024-25';
  bool _itrUploaded = false;
  bool _form26asUploaded = false;

  // GST fields
  final _gstinCtrl = TextEditingController();
  final _gstLegalNameCtrl = TextEditingController();
  final _gstTurnoverCtrl = TextEditingController();
  bool _gstUploaded = false;

  @override
  void dispose() {
    _itrPanCtrl.dispose(); _itrNameCtrl.dispose(); _itrIncomeCtrl.dispose();
    _gstinCtrl.dispose(); _gstLegalNameCtrl.dispose(); _gstTurnoverCtrl.dispose();
    super.dispose();
  }

  /// Demo autofill — populates tax info from demo profile
  void _fillFromDemoProfile() {
    final tax = DemoProfileManager().profile.taxInfo;
    setState(() {
      if (tax.itrFiled) {
        _hasItr = true;
        _itrPanCtrl.text = 'ABCDE1234F';
        _itrNameCtrl.text = DemoProfileManager().profile.personalInfo.fullName;
        _itrIncomeCtrl.text = tax.declaredAnnualIncome.toStringAsFixed(0);
        _assessmentYear = '${tax.assessmentYear}-${(tax.assessmentYear + 1).toString().substring(2)}';
        _itrUploaded = true;
      }
      if (tax.gstRegistered) {
        _hasGst = true;
        _gstinCtrl.text = '33ABCDE1234F1Z5';
        _gstLegalNameCtrl.text = DemoProfileManager().profile.personalInfo.fullName;
        _gstTurnoverCtrl.text = (tax.declaredAnnualIncome * 1.5).toStringAsFixed(0);
        _gstUploaded = true;
      }
    });
  }

  Future<void> _submit() async {
    final statusMap = ref.read(stepStatusProvider);
    if (statusMap[8] == StepStatus.verified) {
       context.push(AppRoutes.scoreStep(9));
       return;
    }

    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);

      // Real backend ITR verification
      if (_hasItr && _itrPanCtrl.text.trim().isNotEmpty) {
        try {
          final itrResult = await api.verifyItr(_itrPanCtrl.text.trim(), _assessmentYear);
          debugPrint('[Step8] ITR verified: AY ${itrResult['assessment_year']} — income ₹${itrResult['gross_income']}');
        } catch (e) {
          debugPrint('[Step8] ITR verification failed: $e');
        }
      }

      // Real backend GST verification
      if (_hasGst && _gstinCtrl.text.trim().isNotEmpty) {
        try {
          final gstResult = await api.verifyGst(_gstinCtrl.text.trim());
          debugPrint('[Step8] GST verified: ${gstResult['status']}');
        } catch (e) {
          debugPrint('[Step8] GST verification failed: $e');
        }
      }
      
      final declaredIncome = double.tryParse(_itrIncomeCtrl.text) ?? 0.0;
      final yearInt = int.tryParse(_assessmentYear.split('-')[0]) ?? 2024;
      
      ref.read(verifiedProfileProvider.notifier).updateStep8(TaxInfo(
        isVerified: true,
        itrFiled: _hasItr,
        assessmentYear: yearInt,
        declaredAnnualIncome: declaredIncome,
        gstRegistered: _hasGst,
        taxPaid: 0.0,
      ));
      ref.read(stepStatusProvider.notifier).setStatus(8, StepStatus.verified);
      if (mounted) {
        setState(() => _isLoading = false);
        context.push(AppRoutes.scoreStep(9));
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _skip() {
    ref.read(stepStatusProvider.notifier).setStatus(8, StepStatus.verified);
    context.push(AppRoutes.scoreStep(9));
  }

  @override
  Widget build(BuildContext context) {
    final statusMap = ref.watch(stepStatusProvider);
    final ocrService = ref.watch(ocrServiceProvider);
    final isVerified = statusMap[8] == StepStatus.verified;

    return ScrollableStepLayout(
      currentStep: 8,
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
                child: const Text('Tax Records', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              if (isVerified) const VerificationBadge(),
            ],
          ),
          const SizedBox(height: 4),
          Text('ITR and GST are optional but significantly boost your score.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 20),

          // ── ITR Module ──
          _buildTaxModule(
            title: '📄 Income Tax Return (ITR)',
            hint: 'Declared annual income via ITR-V',
            selected: _hasItr,
            onToggle: (v) => setState(() => _hasItr = v),
            children: [
              AppTextField(label: 'PAN Number (as per ITR) *', controller: _itrPanCtrl, textCapitalization: TextCapitalization.characters, maxLength: 10),
              const SizedBox(height: 12),
              AppTextField(label: 'Name as per ITR *', controller: _itrNameCtrl),
              const SizedBox(height: 12),
              // Assessment Year dropdown
              DropdownButtonFormField<String>(
                value: _assessmentYear,
                decoration: InputDecoration(
                  labelText: 'Assessment Year *',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
                items: ['2022-23', '2023-24', '2024-25', '2025-26']
                    .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                    .toList(),
                onChanged: (v) => setState(() => _assessmentYear = v ?? _assessmentYear),
              ),
              const SizedBox(height: 12),
              AppTextField(label: 'Annual Income (₹) *', controller: _itrIncomeCtrl, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              DocumentUploadCard(title: 'ITR Acknowledgement *', subtitle: 'ITR-V or e-Acknowledgement PDF', docType: 'tax_itr', ocrService: ocrService, onExtracted: (_) => setState(() => _itrUploaded = true)),
              const SizedBox(height: 12),
              DocumentUploadCard(title: 'Form 26AS (Optional)', subtitle: 'Tax credit statement linked to PAN', docType: 'tax_26as', isRequired: false, ocrService: ocrService, onExtracted: (_) => setState(() => _form26asUploaded = true)),
            ],
          ),

          // ── GST Module ──
          _buildTaxModule(
            title: '🧾 GST Records',
            hint: 'GSTIN + GSTR-3B returns / Registration Certificate',
            selected: _hasGst,
            onToggle: (v) => setState(() => _hasGst = v),
            children: [
              AppTextField(label: 'GSTIN (15-char) *', controller: _gstinCtrl, textCapitalization: TextCapitalization.characters, maxLength: 15),
              const SizedBox(height: 12),
              AppTextField(label: 'Legal Name as per GST *', controller: _gstLegalNameCtrl),
              const SizedBox(height: 12),
              AppTextField(label: 'Annual Turnover (₹) *', controller: _gstTurnoverCtrl, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              DocumentUploadCard(title: 'GST Document *', subtitle: 'GSTR-3B / GST Registration Certificate PDF', docType: 'tax_gst', ocrService: ocrService, onExtracted: (_) => setState(() => _gstUploaded = true)),
            ],
          ),

          const SizedBox(height: 16),
          if (!isVerified)
            SecondaryButton(label: 'Skip this step', onPressed: _skip),
        ],
      ),
      bottomBar: PrimaryButton(
        label: isVerified ? 'Continue to Next Step' : 'Confirm Tax Info',
        isLoading: _isLoading,
        isDisabled: false,
        onPressed: _submit,
      ),
    );
  }

  Widget _buildTaxModule({
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
