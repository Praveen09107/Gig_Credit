import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/layout/scrollable_step_layout.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/status/verification_badge.dart';
import '../../../../state/step_status_provider.dart';
import '../../../../state/verified_profile_provider.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../models/verified_profile/personal_info.dart';
import '../../../../app/app_router.dart';

/// COMP_24 Step 1 — Basic Profile (12 mandatory + 1 optional)
class Step1PersonalScreen extends ConsumerStatefulWidget {
  const Step1PersonalScreen({super.key});

  @override
  ConsumerState<Step1PersonalScreen> createState() => _Step1PersonalScreenState();
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
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand',
    'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur',
    'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab',
    'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura',
    'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
    'Andaman & Nicobar', 'Chandigarh', 'Dadra & Nagar Haveli',
    'Delhi', 'Jammu & Kashmir', 'Ladakh', 'Lakshadweep', 'Puducherry',
  ];

  static const Map<String, String> _workTypes = {
    'platform_worker': 'Platform Worker (Delivery/Ride)',
    'vendor': 'Street Vendor',
    'tradesperson': 'Tradesperson (Electrician/Plumber)',
    'freelancer': 'Freelancer (Tech/Design/Writing)',
  };

  void _generateMockData() {
    _nameCtrl.text = 'Ravi Kumar';
    _dobCtrl.text = '15/06/1995';
    _mobileCtrl.text = '9876543210';
    _currentAddrCtrl.text = '23, 4th Cross Street, Anna Nagar, Chennai';
    _permAddrCtrl.text = '23, 4th Cross Street, Anna Nagar, Chennai';
    _incomeCtrl.text = '25000';
    _secondaryIncomeCtrl.text = '5000';
    setState(() {
      _selectedState = 'Tamil Nadu';
      _selectedWorkType = 'platform_worker';
      _yearsInProfession = 4;
      _dependents = 2;
      _vehicleOwnership = true;
      _sameAddress = true;
    });
  }

  void _showIncompletePopup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete this step before moving ahead', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: const Text('Some required inputs are missing. Please choose how you want to proceed.'),
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

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    final income = double.tryParse(_incomeCtrl.text.replaceAll(',', '')) ?? 0;
    final secondaryIncome = _secondaryIncomeCtrl.text.isNotEmpty
        ? double.tryParse(_secondaryIncomeCtrl.text.replaceAll(',', ''))
        : null;

    ref.read(verifiedProfileProvider.notifier).updateStep1(PersonalInfo(
      isVerified: true,
      fullName: _nameCtrl.text.trim(),
      dateOfBirth: _dobCtrl.text.trim(),
      mobileNumber: _mobileCtrl.text.trim(),
      currentAddress: _currentAddrCtrl.text.trim(),
      permanentAddress: _sameAddress ? _currentAddrCtrl.text.trim() : _permAddrCtrl.text.trim(),
      stateOfResidence: _selectedState,
      workType: _selectedWorkType,
      selfDeclaredIncome: income,
      yearsInProfession: _yearsInProfession,
      dependents: _dependents,
      vehicleOwnership: _vehicleOwnership,
      secondaryIncome: secondaryIncome,
    ));
    ref.read(stepStatusProvider.notifier).setStatus(1, StepStatus.verified);

    if (mounted) {
      setState(() => _isLoading = false);
      context.push(AppRoutes.scoreStep(2));
    }
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
      stepCompletionMap: statusMap.map((key, value) => MapEntry(key, value == StepStatus.verified)),
      onStepTapped: (step) => context.push(AppRoutes.scoreStep(step)),
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Personal Info', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                if (isVerified) const VerificationBadge(),
              ],
            ),
            const SizedBox(height: 4),
            Text('12 mandatory fields • 1 optional', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 20),

            // ── 1. Full Name ──
            GestureDetector(
              onDoubleTap: _generateMockData,
              child: AppTextField(
                label: 'Full Name (as on Aadhaar)',
                controller: _nameCtrl,
                validator: (v) {
                  if (v == null || v.trim().length < 2) return 'Name must be 2-50 characters';
                  if (v.trim().length > 50) return 'Name too long';
                  if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(v.trim())) return 'Letters and spaces only';
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
                if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v)) return 'Must start with 6-9';
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
                if (v == null || v.trim().length < 10) return 'Min 10 characters';
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
                const Text('Same as current address', style: TextStyle(fontSize: 13)),
              ],
            ),
            if (!_sameAddress) ...[
              AppTextField(
                label: 'Permanent Address',
                controller: _permAddrCtrl,
                maxLines: 2,
                validator: (v) {
                  if (_sameAddress) return null;
                  if (v == null || v.trim().length < 10) return 'Min 10 characters';
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
              items: _indianStates.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: (v) { if (v != null) setState(() => _selectedState = v); },
              decoration: _dropdownDecoration(),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            // ── 7. Work Type ──
            _buildLabel('Primary Work Type'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedWorkType,
              items: _workTypes.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: (v) { if (v != null) setState(() => _selectedWorkType = v); },
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
              min: 0, max: 40,
              onChanged: (v) => setState(() => _yearsInProfession = v),
              suffix: 'years',
            ),
            const SizedBox(height: 18),

            // ── 10. Dependents (Stepper) ──
            _buildLabel('Number of Dependents'),
            const SizedBox(height: 8),
            _buildStepper(
              value: _dependents,
              min: 0, max: 10,
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
                  child: Text('Optional', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
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
    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: AppColors.textSecondary),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          Expanded(
            child: Center(
              child: Text(
                '$value $suffix',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.accent),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({required String label, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
          Switch.adaptive(
            value: value,
            onChanged: (v) => onChanged(v),
            activeColor: AppColors.accent,
          ),
        ],
      ),
    );
  }

  InputDecoration _dropdownDecoration() => InputDecoration(
    filled: true,
    fillColor: AppColors.card,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.surfaceVariant)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.surfaceVariant)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}
