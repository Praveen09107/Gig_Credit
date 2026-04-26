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
import '../../../../core/enums/app_enums.dart';
import '../../../../models/verified_profile/utility_info.dart';
import '../../../../app/app_router.dart';

class Step4UtilityScreen extends ConsumerStatefulWidget {
  const Step4UtilityScreen({super.key});

  @override
  ConsumerState<Step4UtilityScreen> createState() => _Step4UtilityScreenState();
}

class _Step4UtilityScreenState extends ConsumerState<Step4UtilityScreen> {
  bool _isLoading = false;

  // Module toggles
  bool _hasElectricity = false;
  bool _hasWater = false;
  bool _hasGas = false;
  bool _hasMobile = false;
  bool _hasInternet = false;
  bool _hasRent = false;

  // Electricity
  final _elecConsumerCtrl = TextEditingController();
  final _elecNameCtrl = TextEditingController();
  final _elecAmountCtrl = TextEditingController();
  bool _elecUploaded = false;

  // Water
  final _waterConsumerCtrl = TextEditingController();
  final _waterNameCtrl = TextEditingController();
  final _waterAmountCtrl = TextEditingController();
  bool _waterUploaded = false;

  // Gas
  final _gasConsumerCtrl = TextEditingController();
  final _gasNameCtrl = TextEditingController();
  final _gasAmountCtrl = TextEditingController();
  bool _gasUploaded = false;

  // Mobile
  final _mobileMobileCtrl = TextEditingController();
  final _mobileAccountCtrl = TextEditingController();
  final _mobileNameCtrl = TextEditingController();
  final _mobileAmountCtrl = TextEditingController();
  bool _mobileUploaded = false;

  // Internet
  final _internetAccountCtrl = TextEditingController();
  final _internetNameCtrl = TextEditingController();
  final _internetAmountCtrl = TextEditingController();
  bool _internetUploaded = false;

  // Rent
  final _rentTenantCtrl = TextEditingController();
  final _rentLandlordCtrl = TextEditingController();
  final _rentAddressCtrl = TextEditingController();
  final _rentAmountCtrl = TextEditingController();
  bool _rentUploaded = false;

  @override
  void dispose() {
    _elecConsumerCtrl.dispose(); _elecNameCtrl.dispose(); _elecAmountCtrl.dispose();
    _waterConsumerCtrl.dispose(); _waterNameCtrl.dispose(); _waterAmountCtrl.dispose();
    _gasConsumerCtrl.dispose(); _gasNameCtrl.dispose(); _gasAmountCtrl.dispose();
    _mobileMobileCtrl.dispose(); _mobileAccountCtrl.dispose(); _mobileNameCtrl.dispose(); _mobileAmountCtrl.dispose();
    _internetAccountCtrl.dispose(); _internetNameCtrl.dispose(); _internetAmountCtrl.dispose();
    _rentTenantCtrl.dispose(); _rentLandlordCtrl.dispose(); _rentAddressCtrl.dispose(); _rentAmountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final statusMap = ref.read(stepStatusProvider);
    if (statusMap[4] == StepStatus.verified) {
       context.push(AppRoutes.scoreStep(5));
       return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    ref.read(verifiedProfileProvider.notifier).updateStep4(const UtilityInfo(isVerified: true));
    ref.read(stepStatusProvider.notifier).setStatus(4, StepStatus.verified);

    if (mounted) {
      setState(() => _isLoading = false);
      context.push(AppRoutes.scoreStep(5));
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusMap = ref.watch(stepStatusProvider);
    final ocrService = ref.watch(ocrServiceProvider);
    final isVerified = statusMap[4] == StepStatus.verified;

    return ScrollableStepLayout(
      currentStep: 4,
      stepCompletionMap: statusMap.map((key, value) => MapEntry(key, value == StepStatus.verified)),
      onStepTapped: (step) => context.push(AppRoutes.scoreStep(step)),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Utility Bills', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              if (isVerified) const VerificationBadge(),
            ],
          ),
          const SizedBox(height: 4),
          Text('All modules optional. Toggle any bills you have.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 20),

          // ── Electricity ──
          _buildBillModule(
            title: '⚡ Electricity Bill',
            hint: 'Proves address continuity and regular payment',
            selected: _hasElectricity,
            onToggle: (v) => setState(() => _hasElectricity = v),
            children: [
              AppTextField(label: 'Consumer Number *', controller: _elecConsumerCtrl),
              const SizedBox(height: 12),
              AppTextField(label: 'Name as per Bill *', controller: _elecNameCtrl),
              const SizedBox(height: 12),
              AppTextField(label: 'Amount Paid (₹) *', controller: _elecAmountCtrl, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              DocumentUploadCard(title: 'Electricity Bill Upload *', subtitle: 'JPG/PNG/PDF', docType: 'utility_electricity', ocrService: ocrService, onExtracted: (_) => setState(() => _elecUploaded = true)),
            ],
          ),

          // ── Water ──
          _buildBillModule(
            title: '💧 Water Bill',
            hint: 'Address and payment regularity proof',
            selected: _hasWater,
            onToggle: (v) => setState(() => _hasWater = v),
            children: [
              AppTextField(label: 'Consumer / Account No *', controller: _waterConsumerCtrl),
              const SizedBox(height: 12),
              AppTextField(label: 'Name as per Bill *', controller: _waterNameCtrl),
              const SizedBox(height: 12),
              AppTextField(label: 'Amount Paid (₹) *', controller: _waterAmountCtrl, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              DocumentUploadCard(title: 'Water Bill Upload *', subtitle: 'JPG/PNG/PDF', docType: 'utility_water', ocrService: ocrService, onExtracted: (_) => setState(() => _waterUploaded = true)),
            ],
          ),

          // ── Gas ──
          _buildBillModule(
            title: '🔥 Gas / LPG Bill',
            hint: 'Regular household payment evidence',
            selected: _hasGas,
            onToggle: (v) => setState(() => _hasGas = v),
            children: [
              AppTextField(label: 'Consumer / BP Number *', controller: _gasConsumerCtrl),
              const SizedBox(height: 12),
              AppTextField(label: 'Name as per Bill *', controller: _gasNameCtrl),
              const SizedBox(height: 12),
              AppTextField(label: 'Amount Paid (₹) *', controller: _gasAmountCtrl, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              DocumentUploadCard(title: 'Gas Bill Upload *', subtitle: 'JPG/PNG/PDF', docType: 'utility_gas', ocrService: ocrService, onExtracted: (_) => setState(() => _gasUploaded = true)),
            ],
          ),

          // ── Mobile ──
          _buildBillModule(
            title: '📱 Mobile / Phone Bill',
            hint: 'Postpaid bill proves payment discipline',
            selected: _hasMobile,
            onToggle: (v) => setState(() => _hasMobile = v),
            children: [
              AppTextField(label: 'Mobile Number *', controller: _mobileMobileCtrl, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              AppTextField(label: 'Account / Customer Number *', controller: _mobileAccountCtrl),
              const SizedBox(height: 12),
              AppTextField(label: 'Name as per Bill *', controller: _mobileNameCtrl),
              const SizedBox(height: 12),
              AppTextField(label: 'Amount Paid (₹) *', controller: _mobileAmountCtrl, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              DocumentUploadCard(title: 'Mobile Bill Upload *', subtitle: 'JPG/PNG/PDF', docType: 'utility_mobile', ocrService: ocrService, onExtracted: (_) => setState(() => _mobileUploaded = true)),
            ],
          ),

          // ── Internet ──
          _buildBillModule(
            title: '🌐 Internet / Broadband Bill',
            hint: 'Broadband payment consistency',
            selected: _hasInternet,
            onToggle: (v) => setState(() => _hasInternet = v),
            children: [
              AppTextField(label: 'Account / Customer Number *', controller: _internetAccountCtrl),
              const SizedBox(height: 12),
              AppTextField(label: 'Name as per Bill *', controller: _internetNameCtrl),
              const SizedBox(height: 12),
              AppTextField(label: 'Amount Paid (₹) *', controller: _internetAmountCtrl, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              DocumentUploadCard(title: 'Internet Bill Upload *', subtitle: 'JPG/PNG/PDF', docType: 'utility_internet', ocrService: ocrService, onExtracted: (_) => setState(() => _internetUploaded = true)),
            ],
          ),

          // ── Rent ──
          _buildBillModule(
            title: '🏠 Rent Receipt / Agreement',
            hint: 'Rent proof — address and payment continuity',
            selected: _hasRent,
            onToggle: (v) => setState(() => _hasRent = v),
            children: [
              AppTextField(label: 'Tenant Name *', controller: _rentTenantCtrl),
              const SizedBox(height: 12),
              AppTextField(label: 'Landlord Name *', controller: _rentLandlordCtrl),
              const SizedBox(height: 12),
              AppTextField(label: 'Rental Address *', controller: _rentAddressCtrl, maxLines: 2),
              const SizedBox(height: 12),
              AppTextField(label: 'Monthly Rent (₹) *', controller: _rentAmountCtrl, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              DocumentUploadCard(title: 'Rent Document Upload *', subtitle: 'Receipt / Agreement JPG/PNG/PDF', docType: 'utility_rent', ocrService: ocrService, onExtracted: (_) => setState(() => _rentUploaded = true)),
            ],
          ),
        ],
      ),
      bottomBar: PrimaryButton(
        label: isVerified ? 'Continue to Next Step' : 'Save & Continue',
        isLoading: _isLoading,
        isDisabled: false,
        onPressed: _submit,
      ),
    );
  }

  Widget _buildBillModule({
    required String title,
    required String hint,
    required bool selected,
    required ValueChanged<bool> onToggle,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  ...children,
                ],
              ),
            ),
        ],
      ),
    );
  }
}
