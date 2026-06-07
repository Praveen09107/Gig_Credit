import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/layout/scrollable_step_layout.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/status/verification_badge.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';
import '../../../../shared/widgets/feedback/step_popups.dart';
import '../../../../state/step_status_provider.dart';
import '../../../../state/verified_profile_provider.dart';
import '../../../../state/score_provider.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../models/verified_profile/personal_info.dart';
import '../../../../app/app_router.dart';
import '../../../../demo/demo_profile_manager.dart';
import '../../../../scoring/validation/step1_validator.dart';
import '../../../../services/gig_logger.dart';

/// COMP_24 Step 1 — Basic Profile (12 mandatory + 1 optional)
class Step1PersonalScreen extends ConsumerStatefulWidget {
  const Step1PersonalScreen({super.key});

  @override
  ConsumerState<Step1PersonalScreen> createState() =>
      _Step1PersonalScreenState();
}

class _Step1PersonalScreenState extends ConsumerState<Step1PersonalScreen> {
  final _formKey = GlobalKey<FormState>();

  // 12 Mandatory field controllers
  final _nameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _currentAddrCtrl = TextEditingController();
  final _permAddrCtrl = TextEditingController();
  final _incomeCtrl = TextEditingController();
  String _selectedState = 'Tamil Nadu';
  String _selectedWorkType = 'platform_worker';
  int _yearsInProfession = 2;
  int _dependents = 1;
  bool _vehicleOwnership = true;
  bool _sameAddress = false;

  // 1 Optional
  final _secondaryIncomeCtrl = TextEditingController();

  bool _isLoading = false;

  bool get _isFormValid {
    if (_nameCtrl.text.trim().length < 2) return false;
    if (_dobCtrl.text.isEmpty) return false;
    if (_mobileCtrl.text.length != 10) return false;
    if (_currentAddrCtrl.text.trim().length < 10) return false;
    if (!_sameAddress && _permAddrCtrl.text.trim().length < 10) return false;
    if (_incomeCtrl.text.isEmpty) return false;
    return true;
  }

  @override
  void initState() {
    super.initState();
    // Add listeners to trigger rebuilds for button validation
    void rebuild() => setState(() {});
    _nameCtrl.addListener(rebuild);
    _dobCtrl.addListener(rebuild);
    _mobileCtrl.addListener(rebuild);
    _currentAddrCtrl.addListener(rebuild);
    _permAddrCtrl.addListener(rebuild);
    _incomeCtrl.addListener(rebuild);
  }

  static const List<String> _indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Andaman & Nicobar',
    'Chandigarh',
    'Dadra & Nagar Haveli',
    'Delhi',
    'Jammu & Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry',
  ];

  static const Map<String, String> _workTypes = {
    'platform_worker': 'Platform Worker (Delivery/Ride)',
    'vendor': 'Street Vendor',
    'tradesperson': 'Tradesperson (Electrician/Plumber)',
    'freelancer': 'Freelancer (Tech/Design/Writing)',
    'salaried': 'Salaried Employee',
    'self_employed': 'Self Employed / Business',
    'gig_worker': 'Gig Worker',
    'unemployed': 'Currently Unemployed',
    'student': 'Student',
  };

  /// Praveen Kumar P — real data autofill (double-tap Full Name field for demo)
  /// Source: PaddleOCR extracted from actual Aadhaar card + bank statement.
  void _fillFromDemoProfile() {
    _nameCtrl.text = 'Praveen Kumar P';
    _dobCtrl.text = '09/01/2007';
    _mobileCtrl.text = '9500009092';
    _currentAddrCtrl.text =
        '205F, Srirangam New Town, Wimco Nagar, Sakthipuram, '
        'Kattivakkam, Ennore Thermal Station, Tiruvallur, Tamil Nadu - 600057';
    _incomeCtrl.text = '25000';
    _secondaryIncomeCtrl.text = '';
    setState(() {
      _selectedState = 'Tamil Nadu';
      _selectedWorkType = 'platform_worker';
      _yearsInProfession = 2;
      _dependents = 1;
      _vehicleOwnership = true;
      _sameAddress = true;
    });
    // No toast — silent autofill for demo
  }

  void _showIncompletePopup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete this step before moving ahead',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: const Text(
            'Some required inputs are missing. Please choose how you want to proceed.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go(AppRoutes.home);
            },
            child: const Text('Save and Exit'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text('Fix Now and Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final statusMap = ref.read(stepStatusProvider);
    if (statusMap[1] == StepStatus.verified) {
      context.push(AppRoutes.scoreStep(2));
      return;
    }

    if (!_isFormValid) {
      _showIncompletePopup();
      return;
    }

    final income = double.tryParse(_incomeCtrl.text.replaceAll(',', '')) ?? 0;
    final secondaryIncome = _secondaryIncomeCtrl.text.isNotEmpty
        ? double.tryParse(_secondaryIncomeCtrl.text.replaceAll(',', ''))
        : null;

    // ═══════════════════════════════════════════════════════════════
    // REAL VALIDATION — Step1Validator (per spec)
    // ═══════════════════════════════════════════════════════════════
    GigLogger.stepBanner(1, 'BASIC PROFILE — DATA INGESTION');

    GigLogger.sectionHeader('RAW INPUTS CAPTURED FROM UI');
    GigLogger.data('Full Name', _nameCtrl.text.trim());
    GigLogger.data('Date of Birth', _dobCtrl.text.trim());
    GigLogger.data('Mobile Number', _mobileCtrl.text.trim());
    GigLogger.data(
        'Work Type', '$_selectedWorkType (${_workTypes[_selectedWorkType]})');
    GigLogger.data('Monthly Income', '₹${_incomeCtrl.text}');
    GigLogger.data(
        'Secondary Income',
        _secondaryIncomeCtrl.text.isNotEmpty
            ? '₹${_secondaryIncomeCtrl.text}'
            : 'None');
    GigLogger.data('State', _selectedState);
    GigLogger.data('Years in Profession', _yearsInProfession.toString());
    GigLogger.data('Dependents', _dependents.toString());
    GigLogger.data('Vehicle Owned', _vehicleOwnership ? 'Yes' : 'No');
    GigLogger.data('Same Address', _sameAddress ? 'Yes (auto-copied)' : 'No');
    GigLogger.data(
        'Current Address',
        _currentAddrCtrl.text.trim().substring(
                0,
                _currentAddrCtrl.text.length > 50
                    ? 50
                    : _currentAddrCtrl.text.length) +
            '...');

    final validation = Step1Validator.validate(
      fullName: _nameCtrl.text.trim(),
      dateOfBirth: _dobCtrl.text.trim(),
      mobileNumber: _mobileCtrl.text.trim(),
      currentAddress: _currentAddrCtrl.text.trim(),
      permanentAddress: _sameAddress
          ? _currentAddrCtrl.text.trim()
          : _permAddrCtrl.text.trim(),
      stateOfResidence: _selectedState,
      workType: _selectedWorkType,
      selfDeclaredIncome: income,
      yearsInProfession: _yearsInProfession,
      dependents: _dependents,
      vehicleOwnership: _vehicleOwnership,
      secondaryIncome: secondaryIncome,
      sameAddress: _sameAddress,
    );

    // ── Detailed validation log ──────────────────────────────────────────────
    GigLogger.sectionHeader('RUNNING STEP 1 VALIDATOR');
    GigLogger.check('Name length ≥ 2 chars', _nameCtrl.text.trim().length >= 2,
        detail: 'len=${_nameCtrl.text.trim().length}');
    GigLogger.check('Date of Birth provided', _dobCtrl.text.isNotEmpty);
    GigLogger.check('Mobile is 10 digits', _mobileCtrl.text.trim().length == 10,
        detail: _mobileCtrl.text.trim());
    GigLogger.check(
        'Address ≥ 10 chars', _currentAddrCtrl.text.trim().length >= 10,
        detail: 'len=${_currentAddrCtrl.text.trim().length}');
    GigLogger.check('Income > 0', income > 0,
        detail: '₹${income.toStringAsFixed(0)}');
    GigLogger.check('Work type selected', _selectedWorkType.isNotEmpty,
        detail: _selectedWorkType);
    if (validation.age != null) {
      GigLogger.check('Age ≥ 18 (computed)', (validation.age ?? 0) >= 18,
          detail: '${validation.age} years');
    }
    GigLogger.divider();
    GigLogger.data('Hard Fails', '${validation.hardFails.length}');
    GigLogger.data('Soft Flags', '${validation.softFlags.length}');
    for (final issue in validation.issues) {
      if (issue.severity.name == 'hard') {
        GigLogger.fail(
            '[${issue.severity.name.toUpperCase()}] ${issue.code}: ${issue.message}');
      } else {
        GigLogger.warn(
            '[${issue.severity.name.toUpperCase()}] ${issue.code}: ${issue.message}');
      }
    }
    if (validation.passed) {
      GigLogger.ok('STEP 1 VALIDATION → PASSED ✓');
    } else {
      GigLogger.fail('STEP 1 VALIDATION → FAILED — submission blocked');
    }

    // HARD FAIL — block submission with details
    if (!validation.passed) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Validation Failed',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'The following issues must be fixed before proceeding:',
                  style: TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              ...validation.hardFails.map((issue) => Padding(
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
    if (validation.softFlags.isNotEmpty && mounted) {
      for (final flag in validation.softFlags) {
        AppToast.warning(context, flag.message);
      }
    }

    // Show confirmation popup before proceeding
    final confirmed = await StepConfirmPopup.show(context, stepNumber: 1);
    if (!confirmed || !mounted) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    ref.read(verifiedProfileProvider.notifier).updateStep1(PersonalInfo(
          isVerified: true,
          fullName: _nameCtrl.text.trim(),
          dateOfBirth: _dobCtrl.text.trim(),
          mobileNumber: _mobileCtrl.text.trim(),
          currentAddress: _currentAddrCtrl.text.trim(),
          permanentAddress: _sameAddress
              ? _currentAddrCtrl.text.trim()
              : _permAddrCtrl.text.trim(),
          stateOfResidence: _selectedState,
          workType: _selectedWorkType,
          selfDeclaredIncome: income,
          yearsInProfession: _yearsInProfession,
          dependents: _dependents,
          vehicleOwnership: _vehicleOwnership,
          secondaryIncome: secondaryIncome,
        ));
    ref.read(stepStatusProvider.notifier).setStatus(1, StepStatus.verified);
    ref
        .read(stepStatusProvider.notifier)
        .resetStepsAfter(1); // GAP 3: Reset downstream steps on re-submit

    GigLogger.sectionHeader('GLOBAL STATE UPDATE — verifiedProfileProvider');
    GigLogger.stateUpdate('verifiedProfileProvider', 'personalInfo.fullName',
        _nameCtrl.text.trim());
    GigLogger.stateUpdate('verifiedProfileProvider', 'personalInfo.dateOfBirth',
        _dobCtrl.text.trim());
    GigLogger.stateUpdate(
        'verifiedProfileProvider', 'personalInfo.workType', _selectedWorkType);
    GigLogger.stateUpdate('verifiedProfileProvider',
        'personalInfo.selfDeclaredIncome', '₹$income');
    GigLogger.stateUpdate(
        'verifiedProfileProvider', 'personalInfo.isVerified', 'true');
    GigLogger.stateUpdate(
        'stepStatusProvider', 'step[1]', 'StepStatus.verified');
    GigLogger.warn(
        'Steps 2-9 downstream state RESET (re-submission guard active)');
    GigLogger.ok('Step 1 complete — advancing to Step 2 (KYC)');

    if (mounted) {
      setState(() => _isLoading = false);
      AppToast.success(context, 'Personal details verified ✓');
      context.push(AppRoutes.scoreStep(2));
    }
  }

  Future<bool> _onWillPop() async {
    // Step 1 back = abandon session
    final abandon = await AbandonSessionPopup.show(context);
    if (abandon && mounted) {
      ref.read(stepStatusProvider.notifier).reset();
      ref.read(verifiedProfileProvider.notifier).reset();
      ref.read(scoreProvider.notifier).reset();
      AppToast.warning(context, 'Session cancelled. All data cleared.');
      context.go(AppRoutes.home);
    }
    return false; // We handle navigation ourselves
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(() {});
    _dobCtrl.removeListener(() {});
    _mobileCtrl.removeListener(() {});
    _currentAddrCtrl.removeListener(() {});
    _permAddrCtrl.removeListener(() {});
    _incomeCtrl.removeListener(() {});

    _nameCtrl.dispose();
    _dobCtrl.dispose();
    _mobileCtrl.dispose();
    _currentAddrCtrl.dispose();
    _permAddrCtrl.dispose();
    _incomeCtrl.dispose();
    _secondaryIncomeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusMap = ref.watch(stepStatusProvider);
    final isVerified = statusMap[1] == StepStatus.verified;

    return ScrollableStepLayout(
      currentStep: 1,
      stepCompletionMap: statusMap
          .map((key, value) => MapEntry(key, value == StepStatus.verified)),
      onStepTapped: (step) => context.push(AppRoutes.scoreStep(step)),
      onAbandon: () {
        // Reset all session data when user abandons from Step 1
        ref.read(stepStatusProvider.notifier).reset();
        ref.read(verifiedProfileProvider.notifier).reset();
        ref.read(scoreProvider.notifier).reset();
        AppToast.warning(context, 'Session cancelled. All data cleared.');
      },
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Personal Info',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                if (isVerified) const VerificationBadge(),
              ],
            ),
            const SizedBox(height: 4),
            Text('12 mandatory fields • 1 optional',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 20),

            // ── 1. Full Name ──
            GestureDetector(
              onDoubleTap: _fillFromDemoProfile,
              child: AppTextField(
                label: 'Full Name (as on Aadhaar)',
                controller: _nameCtrl,
                validator: (v) {
                  if (v == null || v.trim().length < 2)
                    return 'Name must be 2-50 characters';
                  if (v.trim().length > 50) return 'Name too long';
                  if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(v.trim()))
                    return 'Letters and spaces only';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 14),

            // ── 2. Date of Birth ──
            AppTextField(
              label: 'Date of Birth (DD/MM/YYYY)',
              controller: _dobCtrl,
              keyboardType: TextInputType.datetime,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                final parts = v.split('/');
                if (parts.length != 3) return 'Use DD/MM/YYYY format';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // ── 3. Mobile Number ──
            AppTextField(
              label: 'Mobile Number',
              controller: _mobileCtrl,
              keyboardType: TextInputType.phone,
              prefixText: '+91 ',
              validator: (v) {
                if (v == null || v.length != 10) return 'Must be 10 digits';
                if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v))
                  return 'Must start with 6-9';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // ── 4. Current Address ──
            AppTextField(
              label: 'Current Address',
              controller: _currentAddrCtrl,
              maxLines: 2,
              validator: (v) {
                if (v == null || v.trim().length < 10)
                  return 'Min 10 characters';
                if (v.trim().length > 200) return 'Max 200 characters';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // ── 5. Permanent Address ──
            Row(
              children: [
                Checkbox(
                  value: _sameAddress,
                  onChanged: (v) => setState(() => _sameAddress = v ?? false),
                  activeColor: AppColors.accent,
                ),
                const Text('Same as current address',
                    style: TextStyle(fontSize: 13)),
              ],
            ),
            if (!_sameAddress) ...[
              AppTextField(
                label: 'Permanent Address',
                controller: _permAddrCtrl,
                maxLines: 2,
                validator: (v) {
                  if (_sameAddress) return null;
                  if (v == null || v.trim().length < 10)
                    return 'Min 10 characters';
                  return null;
                },
              ),
              const SizedBox(height: 14),
            ],

            // ── 6. State of Residence ──
            _buildLabel('State of Residence'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedState,
              items: _indianStates
                  .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s, style: const TextStyle(fontSize: 14))))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedState = v);
              },
              decoration: _dropdownDecoration(),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            // ── 7. Work Type ──
            _buildLabel('Primary Work Type'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedWorkType,
              items: _workTypes.entries
                  .map((e) => DropdownMenuItem(
                      value: e.key,
                      child:
                          Text(e.value, style: const TextStyle(fontSize: 14))))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedWorkType = v);
              },
              decoration: _dropdownDecoration(),
            ),
            const SizedBox(height: 14),

            // ── 8. Self-Declared Income ──
            AppTextField(
              label: 'Monthly Income (₹)',
              controller: _incomeCtrl,
              keyboardType: TextInputType.number,
              prefixText: '₹ ',
              validator: (v) {
                final val = double.tryParse(v?.replaceAll(',', '') ?? '') ?? 0;
                if (val < 1000) return 'Minimum ₹1,000';
                if (val > 500000) return 'Maximum ₹5,00,000';
                return null;
              },
            ),
            const SizedBox(height: 18),

            // ── 9. Years in Profession (Stepper) ──
            _buildLabel('Years in Profession'),
            const SizedBox(height: 8),
            _buildStepper(
              value: _yearsInProfession,
              min: 0,
              max: 40,
              onChanged: (v) => setState(() => _yearsInProfession = v),
              suffix: 'years',
            ),
            const SizedBox(height: 18),

            // ── 10. Dependents (Stepper) ──
            _buildLabel('Number of Dependents'),
            const SizedBox(height: 8),
            _buildStepper(
              value: _dependents,
              min: 0,
              max: 10,
              onChanged: (v) => setState(() => _dependents = v),
              suffix: 'people',
            ),
            const SizedBox(height: 18),

            // ── 11. Vehicle Ownership (Toggle) ──
            _buildToggleRow(
              label: 'Do you own a vehicle?',
              value: _vehicleOwnership,
              onChanged: (v) => setState(() => _vehicleOwnership = v),
            ),
            const SizedBox(height: 20),

            // ── Divider: Optional Fields ──
            Row(
              children: [
                const Expanded(child: Divider(color: AppColors.surfaceVariant)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Optional',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
                ),
                const Expanded(child: Divider(color: AppColors.surfaceVariant)),
              ],
            ),
            const SizedBox(height: 14),

            // ── 12 (optional). Secondary Income ──
            AppTextField(
              label: 'Secondary Income (₹/month)',
              controller: _secondaryIncomeCtrl,
              keyboardType: TextInputType.number,
              prefixText: '₹ ',
            ),
          ],
        ),
      ),
      bottomBar: PrimaryButton(
        label: isVerified ? 'Continue to Next Step' : 'Save & Continue',
        isLoading: _isLoading,
        isDisabled: !_isFormValid && !isVerified,
        onPressed: _submit,
      ),
    );
  }

  // ── Helpers ──

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.textPrimary),
      );

  Widget _buildStepper({
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
    required String suffix,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderCard),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline,
                color: AppColors.textSecondary),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          Expanded(
            child: Center(
              child: Text(
                '$value $suffix',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: AppColors.greenPrimary),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(
      {required String label,
      required bool value,
      required ValueChanged<bool> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderCard),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
          Switch.adaptive(
            value: value,
            onChanged: (v) => onChanged(v),
            activeColor: AppColors.greenPrimary,
          ),
        ],
      ),
    );
  }

  InputDecoration _dropdownDecoration() => InputDecoration(
        filled: true,
        fillColor: AppColors.bgCard,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.borderCard)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.borderCard)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.greenPrimary, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}
