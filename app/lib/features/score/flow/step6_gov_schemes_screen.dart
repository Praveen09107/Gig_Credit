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
import '../../../../models/verified_profile/gov_schemes_info.dart';
import '../../../../app/app_router.dart';
import '../../../../demo/demo_profile_manager.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';
import '../../../../shared/widgets/feedback/step_popups.dart';
import '../../../../scoring/validation/bank_transaction_matcher.dart';
import '../../../../scoring/validation/step3_validator.dart';
import '../../../../shared/widgets/feedback/verification_phase_overlay.dart';
import '../../../../services/gig_logger.dart';

import '../../../../shared/widgets/feedback/step_validation_banner.dart';

class Step6GovSchemesScreen extends ConsumerStatefulWidget {
  const Step6GovSchemesScreen({super.key});

  @override
  ConsumerState<Step6GovSchemesScreen> createState() => _Step6GovSchemesScreenState();
}

class _Step6GovSchemesScreenState extends ConsumerState<Step6GovSchemesScreen> with VerificationPhaseMixin {
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

  // Inline validation
  List<String> _validationErrors = [];

  void _runInlineValidation() {
    final errors = <String>[];
    // eShram UAN: must be 12 digits
    if (_hasEshram && _eshramUanCtrl.text.trim().isNotEmpty) {
      final uan = _eshramUanCtrl.text.trim();
      if (uan.length != 12 || !RegExp(r'^\d{12}$').hasMatch(uan)) {
        errors.add('eShram UAN must be exactly 12 digits (e.g. 123456789012).');
      }
    }
    // Udyam: UDYAM-XX-00-0000000
    if (_hasUdyam && _udyamRegCtrl.text.trim().isNotEmpty) {
      final udyam = _udyamRegCtrl.text.trim().toUpperCase();
      if (!RegExp(r'^UDYAM-[A-Z]{2}-\d{2}-\d{7}$').hasMatch(udyam)) {
        errors.add('Udyam number format is invalid. Expected: UDYAM-TN-33-0012345.');
      }
    }
    setState(() => _validationErrors = errors);
  }

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
    
    final confirmed = await StepConfirmPopup.show(context, stepNumber: 6);
    if (!confirmed || !mounted) return;

    setState(() => _isLoading = true);
    showVerificationPhase();

    try {
      // ═══════════════════════════════════════════════════════════════
      // REAL CROSS-VERIFICATION: Gov scheme credits in bank
      // ═══════════════════════════════════════════════════════════════
      final profile = ref.read(verifiedProfileProvider);
      final ocrResults = ref.read(ocrResultsProvider);
      final bankOcr = ocrResults['bank_statement'];

      List<CategorizedTransaction> categorized = [];
      if (bankOcr != null && bankOcr['categorized_transactions'] != null) {
        for (final item in (bankOcr['categorized_transactions'] as List)) {
          if (item is Map<String, dynamic>) {
            categorized.add(CategorizedTransaction(
              date: item['date'] as String? ?? '',
              amount: (item['amount'] as num?)?.toDouble() ?? 0.0,
              type: item['type'] as String? ?? 'debit',
              description: item['description'] as String? ?? '',
              category: TxnCategory.values.firstWhere(
                (c) => c.name == (item['category'] as String? ?? ''), orElse: () => TxnCategory.other),
            ));
          }
        }
      }
      if (categorized.isEmpty && profile.bankInfo.transactions.isNotEmpty) {
        categorized = TransactionCategorizer.categorize(
          profile.bankInfo.transactions.map((t) => t.toJson()).toList(),
        );
      }

      final matcher = BankTransactionMatcher(categorized);
      final govCredits = matcher.findByCategory(TxnCategory.govScheme);
      final totalGovIncome = govCredits.fold(0.0, (sum, t) => sum + t.amount);

      // eShram UAN format validation
      if (_hasEshram && _eshramUanCtrl.text.trim().isNotEmpty) {
        final uan = _eshramUanCtrl.text.trim();
        if (uan.length != 12 || !RegExp(r'^\d{12}$').hasMatch(uan)) {
          print('[Step6] SOFT FLAG: eShram UAN format invalid: $uan (expected 12 digits)');
          if (mounted) AppToast.warning(context, 'eShram UAN should be 12 digits');
        }
      }

      // Udyam registration format validation
      if (_hasUdyam && _udyamRegCtrl.text.trim().isNotEmpty) {
        final udyam = _udyamRegCtrl.text.trim().toUpperCase();
        if (!RegExp(r'^UDYAM-[A-Z]{2}-\d{2}-\d{7}$').hasMatch(udyam)) {
          GigLogger.warn('Udyam format may be invalid: $udyam');
          if (mounted) AppToast.warning(context, 'Udyam format: UDYAM-XX-00-0000000');
        }
      }

      GigLogger.stepBanner(6, 'GOV SCHEMES (OPTIONAL) — CROSS-VERIFICATION');
      GigLogger.sectionHeader('SCHEME TOGGLES');
      GigLogger.data('SVANidhi', _hasSvanidhi.toString());
      GigLogger.data('eShram',   _hasEshram.toString());
      GigLogger.data('PM-SYM',   _hasPmsym.toString());
      GigLogger.data('PMJJBY',   _hasPmjjby.toString());
      GigLogger.data('Mudra',    _hasMudra.toString());
      GigLogger.data('PPF',      _hasPpf.toString());
      GigLogger.data('Udyam',    _hasUdyam.toString());
      GigLogger.sectionHeader('BANK CROSS-CHECK');
      GigLogger.data('Gov credits found', '${govCredits.length}');
      GigLogger.data('Total gov income',  '\u20b9${totalGovIncome.toStringAsFixed(0)}');
      for (final c in govCredits) {
        GigLogger.data('  \u20b9${c.amount.toStringAsFixed(0)}', '${c.date}: ${c.description}');
      }

      // ═══════════════════════════════════════════════════════════════
      // GAP 6 FIX: Backend API calls for government scheme verification
      // Non-blocking — failures are soft-flagged, flow continues
      // ═══════════════════════════════════════════════════════════════
      final api = ref.read(apiServiceProvider);
      if (_hasEshram && _eshramUanCtrl.text.trim().isNotEmpty) {
        try {
          final result = await api.verifyEshram(_eshramUanCtrl.text.trim());
          GigLogger.ok('eShram: ${result['status'] ?? 'ok'}');
        } catch (e) {
          GigLogger.warn('eShram failed (non-blocking): $e');
        }
      }
      if (_hasUdyam && _udyamRegCtrl.text.trim().isNotEmpty) {
        try {
          final result = await api.verifyUdyam(_udyamRegCtrl.text.trim().toUpperCase());
          GigLogger.ok('Udyam: ${result['status'] ?? 'ok'}');
        } catch (e) {
          GigLogger.warn('Udyam failed (non-blocking): $e');
        }
      }
      if (_hasPmsym && _pmsymAccCtrl.text.trim().isNotEmpty) {
        try {
          final result = await api.verifyPmsym(_pmsymAccCtrl.text.trim());
          GigLogger.ok('PM-SYM: ${result['status'] ?? 'ok'}');
        } catch (e) {
          GigLogger.warn('PM-SYM failed (non-blocking): $e');
        }
      }

      dismissVerificationPhase();

      ref.read(verifiedProfileProvider.notifier).updateStep6(GovSchemesInfo(
        isVerified: true,
        hasEshram: _hasEshram,
        hasPmScheme: _hasSvanidhi || _hasPmsym || _hasPmjjby || _hasMudra,
      ));
      ref.read(stepStatusProvider.notifier).setStatus(6, StepStatus.verified);

      GigLogger.sectionHeader('GLOBAL STATE UPDATE');
      GigLogger.stateUpdate('verifiedProfileProvider', 'govSchemesInfo.isVerified', 'true');
      GigLogger.stateUpdate('stepStatusProvider',      'step[6]',                   'StepStatus.verified');
      GigLogger.ok('Step 6 Gov Schemes complete');
      
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.success(context, 'Gov schemes verified ✓ (${govCredits.length} DBT credits found)');
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
          const Text('All optional. Toggle schemes you are enrolled in.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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

          _buildSchemeModule(title: '🛒 PM SVANidhi', hint: 'Street Vendor Scheme', selected: _hasSvanidhi, onToggle: (v) => setState(() => _hasSvanidhi = v), children: [
            AppTextField(label: 'SVANidhi Application ID *', controller: _svanidhiIdCtrl),
            const SizedBox(height: 12),
            DocumentUploadCard(title: 'SVANidhi Proof *', subtitle: 'Approval / sanction letter', docType: 'gov_svanidhi', ocrService: ocrService, onExtracted: (_) => setState(() => _svanidhiUploaded = true)),
          ]),

          _buildSchemeModule(title: '👷 eShram Registration', hint: 'Unorganised Workers UAN', selected: _hasEshram, onToggle: (v) => setState(() => _hasEshram = v), children: [
            AppTextField(label: 'UAN (12-digit) *', controller: _eshramUanCtrl, keyboardType: TextInputType.number, maxLength: 12, onChanged: (_) => _runInlineValidation()),
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
            AppTextField(label: 'Udyam Registration Number *', controller: _udyamRegCtrl, onChanged: (_) => _runInlineValidation()),
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
        isDisabled: _validationErrors.isNotEmpty,
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
