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

  void _generateMockData() {
    _bankNameCtrl.text = 'HDFC Bank';
    _holderNameCtrl.text = 'Praveen';
    _branchCtrl.text = 'Main Branch';
    _accCtrl.text = '098765432123';
    _ifscCtrl.text = 'HDFC0001234';
    setState(() {});
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify IFSC and Account Number first.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // Final processing simulation
      await Future.delayed(const Duration(seconds: 2));

      ref.read(verifiedProfileProvider.notifier).updateStep3(const BankInfo(isVerified: true));
      ref.read(stepStatusProvider.notifier).setStatus(3, StepStatus.verified);
      
      if (mounted) {
        setState(() => _isLoading = false);
        context.push(AppRoutes.scoreStep(4));
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyIfsc() async {
    final text = _ifscCtrl.text.trim().toUpperCase();
    if (text.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('IFSC must be 11 characters'), backgroundColor: Colors.red),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('IFSC Verified!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isIfscVerifying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _verifyAccount() async {
    final acc = _accCtrl.text.trim();
    final ifsc = _ifscCtrl.text.trim().toUpperCase();
    
    if (acc.isEmpty || !_ifscVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify IFSC and enter Account Number first'), backgroundColor: Colors.red),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account Verified!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAccVerifying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API Error: $e'), backgroundColor: Colors.red),
        );
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
            onDoubleTap: _generateMockData,
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

            DocumentUploadCard(
              title: 'Bank Statement (Primary Bank) *',
              subtitle: 'Upload PDF format for auto-extraction',
              docType: 'bank_statement',
              ocrService: ocrService,
              onExtracted: (data) {
                final rawText = data['raw_text']?.toString().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '') ?? '';
                final expectedAcc = _accCtrl.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
                
                if (expectedAcc.isNotEmpty && !rawText.contains(expectedAcc)) {
                  setState(() => _pdfUploaded = false);
                  throw Exception('Verification Failed: Bank Statement does not match the entered Account Number!');
                }
                
                setState(() => _pdfUploaded = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bank Statement Verified successfully!'), backgroundColor: Colors.green),
                );
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // AppColors.card fallback
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isVerified
              ? const Color(0xFF4CAF50).withValues(alpha: 0.5) // AppColors.verified
              : const Color(0xFF2C2C2E), // AppColors.surfaceVariant
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1.5),
                  decoration: InputDecoration(
                    labelText: label,
                    hintText: hint,
                    counterText: '',
                    border: const OutlineInputBorder(),
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
                              backgroundColor: const Color(0xFF2196F3), // AppColors.primary
                            ),
                            child: isVerifying
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
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
