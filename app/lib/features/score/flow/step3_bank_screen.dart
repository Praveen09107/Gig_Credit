import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/layout/scrollable_step_layout.dart';
import '../../../../shared/widgets/inputs/document_upload_card.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/status/verification_badge.dart';
import '../../../../state/step_status_provider.dart';
import '../../../../state/verified_profile_provider.dart';
import '../../../../state/ocr_service_provider.dart';
import '../../../../state/api_service_provider.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../models/verified_profile/bank_info.dart';
import '../../../../app/app_router.dart';
import '../../../../demo/demo_profile_manager.dart';
import '../../../../shared/widgets/loaders/coin_pulse_loader.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';
import '../../../../shared/widgets/feedback/step_popups.dart';

class Step3BankScreen extends ConsumerStatefulWidget {
  const Step3BankScreen({super.key});

  @override
  ConsumerState<Step3BankScreen> createState() => _Step3BankScreenState();
}

class _Step3BankScreenState extends ConsumerState<Step3BankScreen> {
  final _bankNameCtrl = TextEditingController();
  final _holderNameCtrl = TextEditingController();
  final _branchCtrl = TextEditingController();
  final _accCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _micrCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();

  bool _pdfUploaded = false;
  
  bool _hasSecondaryBank = false;
  final _secBankNameCtrl = TextEditingController();
  final _secHolderNameCtrl = TextEditingController();
  final _secBranchCtrl = TextEditingController();
  final _secAccCtrl = TextEditingController();
  final _secIfscCtrl = TextEditingController();
  final _secMicrCtrl = TextEditingController();
  
  bool _secPdfUploaded = false;
  
  bool _isLoading = false;

  List<double> _monthlyCredits = [];
  List<double> _monthlyDebits = [];
  List<dynamic> _transactions = [];

  bool _ifscVerified = false;
  bool _isIfscVerifying = false;
  bool _accVerified = false;
  bool _isAccVerifying = false;

  bool get _isFormValid {
    final primaryOk = _bankNameCtrl.text.isNotEmpty &&
        _holderNameCtrl.text.isNotEmpty &&
        _branchCtrl.text.isNotEmpty &&
        _accCtrl.text.isNotEmpty &&
        _ifscCtrl.text.isNotEmpty &&
        _pdfUploaded;
    if (!primaryOk) return false;
    if (_hasSecondaryBank) {
      return _secBankNameCtrl.text.isNotEmpty &&
          _secHolderNameCtrl.text.isNotEmpty &&
          _secAccCtrl.text.isNotEmpty &&
          _secIfscCtrl.text.isNotEmpty &&
          _secPdfUploaded;
    }
    return true;
  }

  @override
  void dispose() {
    _bankNameCtrl.dispose();
    _holderNameCtrl.dispose();
    _branchCtrl.dispose();
    _accCtrl.dispose();
    _ifscCtrl.dispose();
    _micrCtrl.dispose();
    _upiCtrl.dispose();
    _secBankNameCtrl.dispose();
    _secHolderNameCtrl.dispose();
    _secBranchCtrl.dispose();
    _secAccCtrl.dispose();
    _secIfscCtrl.dispose();
    _secMicrCtrl.dispose();
    super.dispose();
  }

  /// Demo autofill — populates bank fields from the same demo profile
  void _fillFromDemoProfile() {
    final b = DemoProfileManager().profile.bankInfo;
    _bankNameCtrl.text = b.bankName.isNotEmpty ? b.bankName : 'Axis Bank';
    _holderNameCtrl.text = b.accountHolderName;
    _ifscCtrl.text = b.ifscCode.isNotEmpty ? b.ifscCode : 'UTIB0000345';
    _accCtrl.text = b.accountNumber;
    _monthlyCredits = List<double>.from(b.monthlyCredits);
    _monthlyDebits = List<double>.from(b.monthlyDebits);
    setState(() {
      _pdfUploaded = true;
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
    if (statusMap[3] == StepStatus.verified) {
       context.push(AppRoutes.scoreStep(4));
       return;
    }
    
    if (!_ifscVerified || !_accVerified) {
      AppToast.error(context, 'Verification Required', subtitle: 'Please verify IFSC and Account Number first.');
      return;
    }

    setState(() => _isLoading = true);

    // Show confirmation popup before proceeding
    final confirmed = await StepConfirmPopup.show(context, stepNumber: 3);
    if (!confirmed || !mounted) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      // Final processing simulation
      await Future.delayed(const Duration(seconds: 2));

      ref.read(verifiedProfileProvider.notifier).updateStep3(BankInfo(
        isVerified: true,
        accountNumber: _accCtrl.text,
        ifscCode: _ifscCtrl.text,
        bankName: _bankNameCtrl.text,
        accountHolderName: _holderNameCtrl.text,
        monthlyCredits: _monthlyCredits,
        monthlyDebits: _monthlyDebits,
        transactions: _transactions.map((e) => BankTransaction.fromJson(e)).toList(),
      ));
      ref.read(stepStatusProvider.notifier).setStatus(3, StepStatus.verified);
      
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.success(context, 'Bank details verified ✓');
        context.push(AppRoutes.scoreStep(4));
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyIfsc() async {
    final text = _ifscCtrl.text.trim().toUpperCase();
    if (text.length != 11) {
      AppToast.error(context, 'Invalid IFSC', subtitle: 'Must be exactly 11 characters.');
      return;
    }
    
    setState(() => _isIfscVerifying = true);
    
    // Simulate realistic network/processing delay for hackathon demo
    await Future.delayed(const Duration(seconds: 2));
    
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.verifyIfsc(text);
      if (mounted) {
        setState(() {
          _ifscVerified = true;
          _isIfscVerifying = false;
          // Auto-fill bank details from API
          _bankNameCtrl.text = result['bank_name'] ?? '';
          _branchCtrl.text = result['branch_name'] ?? '';
        });
        AppToast.success(context, 'IFSC Verified!', subtitle: 'Bank details auto-filled.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ifscVerified = true;
          _isIfscVerifying = false;
          _bankNameCtrl.text = 'Demo Bank';
          _branchCtrl.text = 'Hackathon Branch';
        });
        AppToast.warning(context, 'Demo Mode', subtitle: 'Mock IFSC Verified for Demo');
      }
    }
  }

  Future<void> _verifyAccount() async {
    final acc = _accCtrl.text.trim();
    final ifsc = _ifscCtrl.text.trim().toUpperCase();
    
    if (acc.isEmpty || !_ifscVerified) {
      AppToast.error(context, 'Missing Details', subtitle: 'Please verify IFSC and enter Account Number first.');
      return;
    }

    setState(() => _isAccVerifying = true);
    
    // Simulate realistic core-banking system delay for hackathon demo
    await Future.delayed(const Duration(milliseconds: 2500));
    
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.verifyAccount(acc, ifsc);
      if (mounted) {
        setState(() {
          _accVerified = true;
          _isAccVerifying = false;
          // Auto-fill holder name from API
          _holderNameCtrl.text = result['account_holder'] ?? '';
        });
        AppToast.success(context, 'Account Verified!', subtitle: 'Account holder auto-filled.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _accVerified = true;
          _isAccVerifying = false;
          _holderNameCtrl.text = 'Demo User';
        });
        AppToast.warning(context, 'Demo Mode', subtitle: 'Mock Account Verified for Demo');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusMap = ref.watch(stepStatusProvider);
    final ocrService = ref.watch(ocrServiceProvider);
    final isVerified = statusMap[3] == StepStatus.verified;

    return ScrollableStepLayout(
      currentStep: 3,
      stepCompletionMap: statusMap.map((key, value) => MapEntry(key, value == StepStatus.verified)),
      onStepTapped: (step) => context.push(AppRoutes.scoreStep(step)),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Bank Information', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              if (isVerified) const VerificationBadge(),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Provide your primary account where you receive gig payouts.'),
          const SizedBox(height: 24),

          GestureDetector(
            onDoubleTap: _fillFromDemoProfile,
            child: AppTextField(
              label: 'Bank Name *',
              controller: _bankNameCtrl,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Account Holder Name *',
            controller: _holderNameCtrl,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Branch Name *',
            controller: _branchCtrl,
            onChanged: (_) => setState(() {}),
          ),
          _buildVerifyInputRow(
            controller: _ifscCtrl,
            label: 'IFSC Code *',
            hint: 'e.g. HDFC0001234',
            maxLength: 11,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            isVerified: _ifscVerified,
            isVerifying: _isIfscVerifying,
            isStepVerified: isVerified,
            onVerify: _verifyIfsc,
          ),
          const SizedBox(height: 16),
          _buildVerifyInputRow(
            controller: _accCtrl,
            label: 'Account Number *',
            hint: 'Enter your bank account number',
            maxLength: 18,
            keyboardType: TextInputType.number,
            isVerified: _accVerified,
            isVerifying: _isAccVerifying,
            isStepVerified: isVerified,
            onVerify: _verifyAccount,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'MICR Code (Optional)',
            controller: _micrCtrl,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'UPI Details (Optional)',
            controller: _upiCtrl,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),

          // ── Upload section: locked until IFSC + Account verified ──────────
          if (!_ifscVerified || !_accVerified)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2C2C2E)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, color: Color(0xFF888888), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bank Statement Upload',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF888888))),
                        const SizedBox(height: 4),
                        Text(
                          !_ifscVerified
                              ? 'Verify IFSC code first to unlock upload'
                              : 'Verify Account Number to unlock upload',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF555555)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            DocumentUploadCard(
              title: 'Bank Statement (Primary Bank) *',
              subtitle: 'PDF only — statement must match your verified account',
              docType: 'bank_statement',
              ocrService: ocrService,
              onExtracted: (data) {
                setState(() {
                  _pdfUploaded = true;
                  if (data['monthly_credits'] != null) {
                    _monthlyCredits = (data['monthly_credits'] as List).map((e) => (e as num).toDouble()).toList();
                  }
                  if (data['monthly_debits'] != null) {
                    _monthlyDebits = (data['monthly_debits'] as List).map((e) => (e as num).toDouble()).toList();
                  }
                  if (data['transactions'] != null) {
                    _transactions = data['transactions'] as List;
                  }
                                });
                AppToast.success(context, 'Statement Verified', subtitle: 'Bank Statement processed successfully!');
              },
            ),
          
          const SizedBox(height: 32),
          SwitchListTile(
            title: const Text('Add Secondary Bank', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Include another bank account for a stronger profile.'),
            value: _hasSecondaryBank,
            onChanged: (val) {
              setState(() {
                _hasSecondaryBank = val;
              });
            },
          ),
          
          if (_hasSecondaryBank) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text('Secondary Bank Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Bank Name *',
              controller: _secBankNameCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Account Holder Name *',
              controller: _secHolderNameCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Branch Name *',
              controller: _secBranchCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Account Number *',
              controller: _secAccCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'IFSC Code *',
              controller: _secIfscCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'MICR Code (Optional)',
              controller: _secMicrCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            DocumentUploadCard(
              title: 'Bank Statement (Secondary Bank) *',
              subtitle: 'Upload PDF format for auto-extraction',
              docType: 'sec_bank_statement',
              ocrService: ocrService,
              onExtracted: (data) => setState(() => _secPdfUploaded = true),
            ),
          ],
        ],
      ),
      bottomBar: PrimaryButton(
        label: isVerified ? 'Continue to Next Step' : 'Verify Account',
        isLoading: _isLoading,
        isDisabled: !_isFormValid && !isVerified,
        onPressed: _submit,
      ),
    );
  }
  // ── Input field with Verify button beside it ──
  Widget _buildVerifyInputRow({
    required TextEditingController controller,
    required String label,
    required String hint,
    required int maxLength,
    required TextInputType keyboardType,
    required bool isVerified,
    required bool isVerifying,
    required bool isStepVerified,
    required VoidCallback onVerify,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FAF7), // Light green-tinted white — same as AppTextField
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isVerified
              ? const Color(0xFF4CAF50).withValues(alpha: 0.5)
              : const Color(0xFFD0E8D9), // Light green border — matches other fields
          width: isVerified ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  textCapitalization: textCapitalization,
                  maxLength: maxLength,
                  enabled: !isVerified && !isStepVerified,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: Color(0xFF1A2E23)),
                  decoration: InputDecoration(
                    labelText: label,
                    hintText: hint,
                    labelStyle: const TextStyle(color: Color(0xFF4A6E57)),
                    hintStyle: const TextStyle(color: Color(0xFF8BA99A)),
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD0E8D9)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD0E8D9)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Verify Button
              SizedBox(
                width: 90,
                height: 48,
                child: isVerified
                    ? Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.4)),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 16),
                              SizedBox(width: 4),
                              Text('Verified', style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      )
                    : isStepVerified
                        ? const SizedBox.shrink()
                        : ElevatedButton(
                            onPressed: (controller.text.isNotEmpty && !isVerifying) ? onVerify : null,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              backgroundColor: const Color(0xFF2E7D32), // Green — matches app theme
                            ),
                            child: isVerifying
                                ? const CoinPulseLoader(size: 6.0)
                                : const Text('Verify', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
