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
    
    setState(() => _isLoading = true);
    
    try {
      final api = ref.read(apiServiceProvider);
      await api.verifyAccount(_accCtrl.text, _ifscCtrl.text);
      await api.uploadBankStatement('base64_stub');

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
          const SizedBox(height: 16),
          AppTextField(
            label: 'Account Number *',
            controller: _accCtrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'IFSC Code *',
            controller: _ifscCtrl,
            onChanged: (_) => setState(() {}),
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
            onExtracted: (data) => setState(() => _pdfUploaded = true),
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
}
