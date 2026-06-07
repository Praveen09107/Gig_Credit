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
import '../../../../state/ocr_results_provider.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../models/verified_profile/tax_info.dart';
import '../../../../app/app_router.dart';
import '../../../../demo/demo_profile_manager.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';
import '../../../../shared/widgets/feedback/step_popups.dart';
import '../../../../scoring/validation/bank_transaction_matcher.dart';
import '../../../../scoring/validation/step3_validator.dart';
import '../../../../shared/widgets/feedback/verification_phase_overlay.dart';
import '../../../../services/gig_logger.dart';

import '../../../../shared/widgets/feedback/step_validation_banner.dart';

class Step8TaxScreen extends ConsumerStatefulWidget {
  const Step8TaxScreen({super.key});

  @override
  ConsumerState<Step8TaxScreen> createState() => _Step8TaxScreenState();
}

class _Step8TaxScreenState extends ConsumerState<Step8TaxScreen> with VerificationPhaseMixin {
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

  // Inline validation
  List<String> _validationErrors = [];
  List<String> _validationWarnings = [];

  void _runInlineValidation() {
    final errors = <String>[];
    final warnings = <String>[];
    final ocrResults = ref.read(ocrResultsProvider);

    // PAN cross-check: ITR PAN must match Step 2 KYC PAN
    if (_hasItr && _itrPanCtrl.text.trim().isNotEmpty) {
      final itrPan = _itrPanCtrl.text.trim().toUpperCase();
      final kycPan = (ocrResults['pan']?['pan_number'] as String? ??
                      ocrResults['pan']?['id_number'] as String?)?.trim().toUpperCase() ?? '';
      if (kycPan.isNotEmpty && itrPan != kycPan) {
        errors.add('ITR PAN ($itrPan) does not match your KYC PAN ($kycPan) from Step 2. Please use the same PAN.');
      }
    }

    // ITR income vs bank income cross-check (soft warning)
    if (_hasItr && _itrIncomeCtrl.text.trim().isNotEmpty) {
      final declaredAnnual = double.tryParse(_itrIncomeCtrl.text.replaceAll(',', '')) ?? 0.0;
      final bankMonthly = ref.read(verifiedProfileProvider).personalInfo.selfDeclaredIncome;
      if (declaredAnnual > 0 && bankMonthly > 0) {
        final itrMonthly = declaredAnnual / 12.0;
        final ratio = itrMonthly / bankMonthly;
        if (ratio < 0.5 || ratio > 2.0) {
          warnings.add('ITR annual income (₹${(declaredAnnual/1000).toStringAsFixed(0)}k) deviates significantly from your declared monthly income (₹${bankMonthly.toStringAsFixed(0)}/mo). Please verify.');
        }
      }
    }

    // GSTIN format check
    if (_hasGst && _gstinCtrl.text.trim().isNotEmpty) {
      final gstin = _gstinCtrl.text.trim().toUpperCase();
      if (!RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][0-9A-Z]Z[0-9A-Z]$').hasMatch(gstin)) {
        errors.add('GSTIN format is invalid. Expected format: 33ABCDE1234F1Z5 (15 characters).');
      }
    }

    setState(() {
      _validationErrors = errors;
      _validationWarnings = warnings;
    });
  }

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

    final confirmed = await StepConfirmPopup.show(context, stepNumber: 8);
    if (!confirmed || !mounted) return;

    setState(() => _isLoading = true);
    showVerificationPhase();

    try {
      final profile = ref.read(verifiedProfileProvider);
      final ocrResults = ref.read(ocrResultsProvider);

      // ═══════════════════════════════════════════════════════════════
      // PAN IDENTITY CHAIN: ITR PAN ↔ Step 2 KYC PAN
      // ═══════════════════════════════════════════════════════════════
      bool panMismatch = false;
      if (_hasItr && _itrPanCtrl.text.trim().isNotEmpty) {
        // PAN format validation
        // We will skip step 2 validator import, use a simple regex for pan format
        final panIssue = !RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(_itrPanCtrl.text.trim()) 
          ? true : false;
        if (panIssue) {
          if (mounted) AppToast.error(context, 'ITR PAN Invalid', subtitle: 'Invalid PAN format');
          setState(() => _isLoading = false);
          return;
        }

        // Cross-check against KYC PAN (Step 2 OCR)
        final kycPan = (ocrResults['pan']?['pan_number'] as String? ?? 
                        ocrResults['pan']?['id_number'] as String?)?.trim().toUpperCase() ?? '';
        final itrPan = _itrPanCtrl.text.trim().toUpperCase();
        if (kycPan.isNotEmpty && itrPan != kycPan) {
          panMismatch = true;
          print('[Step8] HARD FLAG: ITR PAN ($itrPan) != KYC PAN ($kycPan)');
          if (mounted) AppToast.error(context, 'PAN Mismatch', subtitle: 'ITR PAN does not match KYC PAN from Step 2');
        }
      }

      // ═══════════════════════════════════════════════════════════════
      // ITR INCOME vs BANK INCOME cross-verification
      // ═══════════════════════════════════════════════════════════════
      final declaredIncome = double.tryParse(_itrIncomeCtrl.text.replaceAll(',', '')) ?? 0.0;
      final bankAvgMonthly = profile.bankInfo.avgMonthlyIncome;

      Map<String, dynamic> incomeCheck = {};
      if (_hasItr && declaredIncome > 0) {
        final matcher = BankTransactionMatcher([]);
        incomeCheck = matcher.verifyItrIncome(
          itrAnnualIncome: declaredIncome,
          bankAvgMonthlyCredit: bankAvgMonthly,
        );
      }

      // GSTIN format validation
      if (_hasGst && _gstinCtrl.text.trim().isNotEmpty) {
        final gstin = _gstinCtrl.text.trim().toUpperCase();
        if (!RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][0-9A-Z]Z[0-9A-Z]$').hasMatch(gstin)) {
          print('[Step8] SOFT FLAG: GSTIN format invalid: $gstin');
          if (mounted) AppToast.warning(context, 'GSTIN format may be incorrect');
        }
      }

      GigLogger.stepBanner(8, 'TAX (OPTIONAL) — CROSS-VERIFICATION');
      GigLogger.data('ITR Filed',   _hasItr.toString());
      GigLogger.data('GST Reg',     _hasGst.toString());
      GigLogger.data('PAN Mismatch', panMismatch.toString());
      
      if (incomeCheck.isNotEmpty) {
        GigLogger.sectionHeader('INCOME CHECK (ITR vs BANK)');
        GigLogger.data('ITR monthly',  '\u20b9${(incomeCheck['itr_monthly'] as double).toStringAsFixed(0)}');
        GigLogger.data('Bank monthly', '\u20b9${(incomeCheck['bank_monthly'] as double).toStringAsFixed(0)}');
        GigLogger.data('Ratio',        '${((incomeCheck['ratio'] as double) * 100).toStringAsFixed(1)}%');
        GigLogger.data('Status',       incomeCheck['status'].toString());
        if (!(incomeCheck['within_range'] as bool)) {
          GigLogger.warn('ITR income deviates ${(incomeCheck['deviation_pct'] as double).toStringAsFixed(1)}% from bank average');
          if (mounted) AppToast.warning(context, 'ITR income deviates from bank average by ${(incomeCheck['deviation_pct'] as double).toStringAsFixed(0)}%');
        } else {
          GigLogger.ok('Income aligns with Bank records');
        }
      }

      // ═══════════════════════════════════════════════════════════════
      // GAP 6 FIX: Backend API calls for tax verification
      // Non-blocking — failures are soft-flagged, flow continues
      // ═══════════════════════════════════════════════════════════════
      final api = ref.read(apiServiceProvider);
      if (_hasGst && _gstinCtrl.text.trim().isNotEmpty) {
        try {
          final gstResult = await api.getGstFilingHistory(_gstinCtrl.text.trim().toUpperCase());
          GigLogger.ok('GST filing history: ${gstResult['status'] ?? 'ok'}');
        } catch (e) {
          GigLogger.warn('GST filing failed (non-blocking): $e');
        }
      }
      if (_hasItr && _itrPanCtrl.text.trim().isNotEmpty) {
        try {
          final itrResult = await api.verifyItr(_itrPanCtrl.text.trim().toUpperCase(), _assessmentYear);
          GigLogger.ok('ITR verify: ${itrResult['status'] ?? 'ok'}');
        } catch (e) {
          GigLogger.warn('ITR verify failed (non-blocking): $e');
        }
      }

      dismissVerificationPhase();

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

      GigLogger.sectionHeader('GLOBAL STATE UPDATE');
      GigLogger.stateUpdate('verifiedProfileProvider', 'taxInfo.isVerified', 'true');
      GigLogger.stateUpdate('stepStatusProvider',      'step[8]',            'StepStatus.verified');
      GigLogger.ok('Step 8 Tax complete');

      if (mounted) {
        setState(() => _isLoading = false);
        final incomeStatus = incomeCheck.isNotEmpty 
          ? (incomeCheck['within_range'] as bool ? 'income matched' : 'income deviated')
          : 'no ITR';
        AppToast.success(context, 'Tax verified ✓ ($incomeStatus)');
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
          const Text('ITR and GST are optional but significantly boost your score.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 20),

          // ── Inline validation banner ──
          if (_validationErrors.isNotEmpty || _validationWarnings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: StepValidationBanner(
                errors: _validationErrors,
                warnings: _validationWarnings,
                onDismiss: () => setState(() {
                  _validationErrors = [];
                  _validationWarnings = [];
                }),
              ),
            ),

          // ── ITR Module ──
          _buildTaxModule(
            title: '📄 Income Tax Return (ITR)',
            hint: 'Declared annual income via ITR-V',
            selected: _hasItr,
            onToggle: (v) => setState(() => _hasItr = v),
            children: [
              AppTextField(label: 'PAN Number (as per ITR) *', controller: _itrPanCtrl, textCapitalization: TextCapitalization.characters, maxLength: 10, onChanged: (_) => _runInlineValidation()),
              const SizedBox(height: 12),
              AppTextField(label: 'Name as per ITR *', controller: _itrNameCtrl),
              const SizedBox(height: 12),
              // Assessment Year dropdown
              DropdownButtonFormField<String>(
                initialValue: _assessmentYear,
                decoration: const InputDecoration(
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
              AppTextField(label: 'GSTIN (15-char) *', controller: _gstinCtrl, textCapitalization: TextCapitalization.characters, maxLength: 15, onChanged: (_) => _runInlineValidation()),
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
        isDisabled: _validationErrors.isNotEmpty,
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
            subtitle: Text(hint, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            value: selected,
            onChanged: onToggle,
            activeThumbColor: AppColors.accent,
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
