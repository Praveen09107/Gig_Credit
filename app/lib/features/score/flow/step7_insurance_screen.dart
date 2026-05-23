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
import '../../../../models/verified_profile/insurance_info.dart';
import '../../../../app/app_router.dart';
import '../../../../demo/demo_profile_manager.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';
import '../../../../shared/widgets/feedback/step_popups.dart';
import '../../../../scoring/validation/bank_transaction_matcher.dart';
import '../../../../scoring/validation/step3_validator.dart';
import '../../../../shared/widgets/feedback/verification_phase_overlay.dart';
import '../../../../scoring/validation/fuzzy_matcher.dart';

class Step7InsuranceScreen extends ConsumerStatefulWidget {
  const Step7InsuranceScreen({super.key});

  @override
  ConsumerState<Step7InsuranceScreen> createState() => _Step7InsuranceScreenState();
}

class _Step7InsuranceScreenState extends ConsumerState<Step7InsuranceScreen> with VerificationPhaseMixin {
  bool _isLoading = false;

  bool _hasHealth = false;
  bool _hasVehicle = false;
  bool _hasLife = false;

  final _healthPolicyCtrl = TextEditingController();
  final _healthHolderCtrl = TextEditingController();
  bool _healthUploaded = false;

  final _vehiclePolicyCtrl = TextEditingController();
  final _vehicleHolderCtrl = TextEditingController();
  bool _vehicleUploaded = false;

  final _lifePolicyCtrl = TextEditingController();
  final _lifeHolderCtrl = TextEditingController();
  bool _lifeUploaded = false;

  @override
  void dispose() {
    _healthPolicyCtrl.dispose(); _healthHolderCtrl.dispose();
    _vehiclePolicyCtrl.dispose(); _vehicleHolderCtrl.dispose();
    _lifePolicyCtrl.dispose(); _lifeHolderCtrl.dispose();
    super.dispose();
  }

  /// Demo autofill — populates insurance info from demo profile
  void _fillFromDemoProfile() {
    final ins = DemoProfileManager().profile.insuranceInfo;
    setState(() {
      if (ins.hasHealthInsurance) {
        _hasHealth = true;
        _healthPolicyCtrl.text = 'HLT-892347';
        _healthHolderCtrl.text = DemoProfileManager().profile.personalInfo.fullName;
        _healthUploaded = true;
      }
      if (ins.hasLifeInsurance) {
        _hasLife = true;
        _lifePolicyCtrl.text = 'LIC-902341';
        _lifeHolderCtrl.text = DemoProfileManager().profile.personalInfo.fullName;
        _lifeUploaded = true;
      }
      if (ins.hasVehicleInsurance) {
        _hasVehicle = true;
        _vehiclePolicyCtrl.text = 'VEH-456712';
        _vehicleHolderCtrl.text = DemoProfileManager().profile.personalInfo.fullName;
        _vehicleUploaded = true;
      }
    });
  }

  Future<void> _submit() async {
    final statusMap = ref.read(stepStatusProvider);
    if (statusMap[7] == StepStatus.verified) {
       context.push(AppRoutes.scoreStep(8));
       return;
    }

    final confirmed = await StepConfirmPopup.show(context, stepNumber: 7);
    if (!confirmed || !mounted) return;

    setState(() => _isLoading = true);
    showVerificationPhase();

    try {
      // ═══════════════════════════════════════════════════════════════
      // REAL CROSS-VERIFICATION: Insurance vs bank premiums
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
      final insuranceTxns = matcher.findByCategory(TxnCategory.insurance);

      // Identity cross-check: policy holder names vs Step 1 name
      final step1Name = profile.personalInfo.fullName;
      final holderNames = [_healthHolderCtrl.text, _vehicleHolderCtrl.text, _lifeHolderCtrl.text];
      for (final name in holderNames) {
        if (name.trim().isEmpty || step1Name.isEmpty) continue;
        final match = FuzzyMatcher.matchNames(step1Name, name.trim());
        if (match.severity == MatchSeverity.hardFail) {
          print('[Step7 Identity] HARD FAIL: "$step1Name" vs policy holder "${name.trim()}" (${(match.score * 100).toStringAsFixed(1)}%)');
        } else if (match.severity == MatchSeverity.softFlag) {
          print('[Step7 Identity] SOFT FLAG: "$step1Name" vs policy holder "${name.trim()}" (${(match.score * 100).toStringAsFixed(1)}%)');
        }
      }

      // Vehicle ownership consistency (Step 1 -> Step 7)
      if (profile.personalInfo.vehicleOwnership && !_hasVehicle) {
        print('[Step7] SOFT FLAG: Vehicle owner (Step 1) but no vehicle insurance declared');
        if (mounted) AppToast.warning(context, 'Vehicle owner but no vehicle insurance declared');
      }

      print('\n════════════════════════════════════════════');
      print('STEP 7 INSURANCE CROSS-VERIFICATION');
      print('Insurance debits found in bank: ${insuranceTxns.length}');
      print('Health: $_hasHealth, Vehicle: $_hasVehicle, Life: $_hasLife');
      print('════════════════════════════════════════════\n');

      // ═══════════════════════════════════════════════════════════════
      // GAP 6 FIX: Backend API calls for insurance verification
      // Non-blocking — failures are soft-flagged, flow continues
      // ═══════════════════════════════════════════════════════════════
      final api = ref.read(apiServiceProvider);
      if (_hasHealth && _healthPolicyCtrl.text.trim().isNotEmpty) {
        try {
          final result = await api.verifyInsurance(_healthPolicyCtrl.text.trim(), 'health');
          print('[Step7 API] Health insurance: ${result['status'] ?? 'ok'}');
        } catch (e) {
          print('[Step7 API] Health insurance failed (non-blocking): $e');
        }
      }
      if (_hasVehicle && _vehiclePolicyCtrl.text.trim().isNotEmpty) {
        try {
          final result = await api.verifyInsurance(_vehiclePolicyCtrl.text.trim(), 'vehicle');
          print('[Step7 API] Vehicle insurance: ${result['status'] ?? 'ok'}');
        } catch (e) {
          print('[Step7 API] Vehicle insurance failed (non-blocking): $e');
        }
      }
      if (_hasLife && _lifePolicyCtrl.text.trim().isNotEmpty) {
        try {
          final result = await api.verifyInsurance(_lifePolicyCtrl.text.trim(), 'life');
          print('[Step7 API] Life insurance: ${result['status'] ?? 'ok'}');
        } catch (e) {
          print('[Step7 API] Life insurance failed (non-blocking): $e');
        }
      }

      dismissVerificationPhase();

      ref.read(verifiedProfileProvider.notifier).updateStep7(InsuranceInfo(
        isVerified: true,
        hasHealthInsurance: _hasHealth,
        hasVehicleInsurance: _hasVehicle,
        hasLifeInsurance: _hasLife,
      ));
      ref.read(stepStatusProvider.notifier).setStatus(7, StepStatus.verified);
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.success(context, 'Insurance verified ✓ (${insuranceTxns.length} premium payments found)');
        context.push(AppRoutes.scoreStep(8));
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _skip() {
    ref.read(stepStatusProvider.notifier).setStatus(7, StepStatus.verified);
    context.push(AppRoutes.scoreStep(8));
  }

  @override
  Widget build(BuildContext context) {
    final statusMap = ref.watch(stepStatusProvider);
    final ocrService = ref.watch(ocrServiceProvider);
    final isVerified = statusMap[7] == StepStatus.verified;

    return ScrollableStepLayout(
      currentStep: 7,
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
                child: const Text('Insurance', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              if (isVerified) const VerificationBadge(),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Active insurance lowers your risk profile.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 20),

          // ── Health Insurance ──
          _buildInsuranceModule(
            title: '🏥 Health Insurance',
            hint: 'Health / Mediclaim policy — optional',
            selected: _hasHealth,
            onToggle: (v) => setState(() => _hasHealth = v),
            children: [
              AppTextField(label: 'Health Policy Number *', controller: _healthPolicyCtrl),
              const SizedBox(height: 12),
              AppTextField(label: 'Policy Holder Name *', controller: _healthHolderCtrl),
              const SizedBox(height: 12),
              DocumentUploadCard(title: 'Health Policy Document *', subtitle: 'Policy schedule / e-policy PDF', docType: 'insurance_health', ocrService: ocrService, onExtracted: (_) => setState(() => _healthUploaded = true)),
            ],
          ),

          // ── Vehicle Insurance (Dynamic based on Step 1) ──
          if (ref.watch(verifiedProfileProvider).personalInfo.vehicleOwnership)
            _buildInsuranceModule(
              title: '🚗 Vehicle Insurance',
              hint: 'Required if you own a vehicle (Step 1)',
              selected: _hasVehicle,
              onToggle: (v) => setState(() => _hasVehicle = v),
              children: [
                AppTextField(label: 'Vehicle Policy Number *', controller: _vehiclePolicyCtrl),
                const SizedBox(height: 12),
                AppTextField(label: 'Policy Holder Name *', controller: _vehicleHolderCtrl),
                const SizedBox(height: 12),
                DocumentUploadCard(title: 'Vehicle Insurance Document *', subtitle: 'Motor insurance certificate', docType: 'insurance_vehicle', ocrService: ocrService, onExtracted: (_) => setState(() => _vehicleUploaded = true)),
              ],
            ),

          // ── Life Insurance ──
          _buildInsuranceModule(
            title: '🛡️ Life Insurance',
            hint: 'LIC / Term policy — optional',
            selected: _hasLife,
            onToggle: (v) => setState(() => _hasLife = v),
            children: [
              AppTextField(label: 'Life Policy Number *', controller: _lifePolicyCtrl),
              const SizedBox(height: 12),
              AppTextField(label: 'Policy Holder Name *', controller: _lifeHolderCtrl),
              const SizedBox(height: 12),
              DocumentUploadCard(title: 'Life Policy Document *', subtitle: 'Policy bond / premium certificate PDF', docType: 'insurance_life', ocrService: ocrService, onExtracted: (_) => setState(() => _lifeUploaded = true)),
            ],
          ),

          const SizedBox(height: 16),
          if (!isVerified)
            SecondaryButton(label: 'Skip this step', onPressed: _skip),
        ],
      ),
      bottomBar: PrimaryButton(
        label: isVerified ? 'Continue to Next Step' : 'Confirm Policies',
        isLoading: _isLoading,
        isDisabled: false,
        onPressed: _submit,
      ),
    );
  }

  Widget _buildInsuranceModule({
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
