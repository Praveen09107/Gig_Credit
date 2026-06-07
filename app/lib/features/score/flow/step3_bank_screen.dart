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
import '../../../../state/ocr_results_provider.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../models/verified_profile/bank_info.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../app/app_router.dart';
import '../../../../demo/demo_profile_manager.dart';
import '../../../../shared/widgets/loaders/coin_pulse_loader.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';
import '../../../../shared/widgets/feedback/step_popups.dart';
import '../../../../scoring/validation/step3_validator.dart';
import '../../../../services/gig_logger.dart';

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
  Map<String, dynamic>? _statementOcrData; // OCR data for cross-checks
  List<CategorizedTransaction> _categorizedTransactions = [];

  bool _ifscVerified = false;
  bool _isIfscVerifying = false;
  bool _accVerified = false;
  bool _isAccVerifying = false;

  // Inline mismatch message shown after bank statement upload
  String? _uploadMismatchError;
  // Key to force DocumentUploadCard reset on re-upload
  int _bankStatementUploadKey = 0;

  bool get _isFormValid {
    // All text fields + both verifications + PDF upload are required
    final primaryOk = _bankNameCtrl.text.isNotEmpty &&
        _holderNameCtrl.text.isNotEmpty &&
        _branchCtrl.text.isNotEmpty &&
        _accCtrl.text.isNotEmpty &&
        _ifscCtrl.text.isNotEmpty &&
        _ifscVerified &&
        _accVerified &&
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

  /// Praveen Kumar P — real bank data autofill (double-tap Bank Name field)
  /// Fills ALL fields. User can then tap Verify buttons to confirm IFSC and Account.
  void _fillFromDemoProfile() {
    _ifscCtrl.text    = 'UTIB0000345';
    _accCtrl.text     = '924010058793901';
    _bankNameCtrl.text    = 'Axis Bank';
    _holderNameCtrl.text  = 'Praveen Kumar P';
    _branchCtrl.text      = 'Ennore Branch';
    setState(() {});
    // No toast — silent autofill
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

    if (!_pdfUploaded) {
      AppToast.error(context, 'Bank Statement Required', subtitle: 'Please upload your bank statement PDF to continue.');
      return;
    }

    // ═══════════════════════════════════════════════════════════════
    // REAL VALIDATION — Step3Validator (per spec)
    // ═══════════════════════════════════════════════════════════════
    final profile = ref.read(verifiedProfileProvider);
    final ocrResults = ref.read(ocrResultsProvider);
    final aadhaarName = (ocrResults['aadhaar_front']?['name'] as String?) ?? '';

    final validation = Step3Validator.validateFull(
      bankName: _bankNameCtrl.text.trim(),
      holderName: _holderNameCtrl.text.trim(),
      ifsc: _ifscCtrl.text.trim(),
      account: _accCtrl.text.trim(),
      pdfUploaded: _pdfUploaded,
      transactionCount: _transactions.length,
      monthlyCredits: _monthlyCredits,
      aadhaarName: aadhaarName,
      step1Income: profile.personalInfo.selfDeclaredIncome,
      statementOcr: _statementOcrData,
    );

    // Categorize transactions for Steps 4-9
    _categorizedTransactions = TransactionCategorizer.categorize(
      _transactions.map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{}).toList(),
    );

    GigLogger.stepBanner(3, 'BANK ACCOUNT — VALIDATION & ANALYSIS');

    GigLogger.sectionHeader('RAW INPUTS FROM UI');
    GigLogger.data('Bank Name',         _bankNameCtrl.text.trim());
    GigLogger.data('Holder Name',       _holderNameCtrl.text.trim());
    GigLogger.data('Account Number',    '****${_accCtrl.text.trim().substring(_accCtrl.text.length > 4 ? _accCtrl.text.length - 4 : 0)}');
    GigLogger.data('IFSC Code',         _ifscCtrl.text.trim());
    GigLogger.data('PDF Uploaded',      _pdfUploaded.toString());
    GigLogger.data('Transactions Found', '${_transactions.length}');

    GigLogger.sectionHeader('BANK STATEMENT OCR EXTRACTION');
    if (_statementOcrData != null) {
      GigLogger.ocrField('OCR Account No',   _statementOcrData!['account_number']?.toString() ?? 'N/A');
      GigLogger.ocrField('OCR Bank Name',    _statementOcrData!['bank_name']?.toString() ?? 'N/A');
      GigLogger.ocrField('OCR Holder Name',  _statementOcrData!['holder_name']?.toString() ?? 'N/A');
      GigLogger.ocrField('OCR IFSC',         _statementOcrData!['ifsc']?.toString() ?? 'N/A');
    }
    GigLogger.data('Monthly Credits',   _monthlyCredits.map((c) => '\u20b9${c.toStringAsFixed(0)}').join(', '));
    GigLogger.data('Monthly Debits',    _monthlyDebits.map((d) => '\u20b9${d.toStringAsFixed(0)}').join(', '));

    GigLogger.sectionHeader('CROSS-VALIDATION');
    GigLogger.crossValidation('Step1.name', profile.personalInfo.fullName, 'Bank.holderName', _holderNameCtrl.text.trim(), _holderNameCtrl.text.trim().toLowerCase().contains(profile.personalInfo.fullName.split(' ').first.toLowerCase()));
    GigLogger.crossValidation('Step2.aadhaarName', aadhaarName, 'Bank.holderName', _holderNameCtrl.text.trim(), aadhaarName.isEmpty || _holderNameCtrl.text.trim().toLowerCase().contains(aadhaarName.split(' ').first.toLowerCase()));
    if (_monthlyCredits.isNotEmpty) {
      final avgCredit = _monthlyCredits.reduce((a,b) => a+b) / _monthlyCredits.length;
      GigLogger.crossValidation('Step1.income', '\u20b9${profile.personalInfo.selfDeclaredIncome.toStringAsFixed(0)}', 'Bank.avgCredits', '\u20b9${avgCredit.toStringAsFixed(0)}', (avgCredit / profile.personalInfo.selfDeclaredIncome).abs() < 2.0);
    }

    GigLogger.sectionHeader('RUNNING STEP 3 VALIDATOR');
    GigLogger.data('Hard Fails',   '${validation.hardFails.length}');
    GigLogger.data('Soft Flags',   '${validation.softFlags.length}');
    for (final issue in validation.issues) {
      if (issue.severity.name == 'hard') {
        GigLogger.fail('[HARD] ${issue.code}: ${issue.message}');
      } else {
        GigLogger.warn('[SOFT] ${issue.code}: ${issue.message}');
      }
    }

    GigLogger.sectionHeader('TRANSACTION CATEGORIZATION');
    GigLogger.data('Total Categorized',  '${_categorizedTransactions.length}');
    final catCounts = <String, int>{};
    for (final t in _categorizedTransactions) {
      catCounts[t.category.name] = (catCounts[t.category.name] ?? 0) + 1;
    }
    for (final entry in catCounts.entries) {
      GigLogger.data('  ${entry.key}', '${entry.value} txns');
    }
    if (validation.passed) {
      GigLogger.ok('STEP 3 VALIDATION \u2192 PASSED \u2713');
    } else {
      GigLogger.fail('STEP 3 VALIDATION \u2192 FAILED \u2014 submission blocked');
    }

    // HARD FAIL — block submission
    if (!validation.passed) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Bank Validation Failed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...validation.hardFails.map((issue) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.close, color: Colors.red, size: 16),
                    const SizedBox(width: 6),
                    Expanded(child: Text(issue.message, style: const TextStyle(fontSize: 12))),
                  ],
                ),
              )),
            ],
          ),
          actions: [
            ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fix Issues')),
          ],
        ),
      );
      return;
    }

    // Soft flags — log only, don't show toasts (they're confusing for users)
    if (validation.softFlags.isNotEmpty) {
      for (final flag in validation.softFlags) {
        GigLogger.warn('[SoftFlag] ${flag.code}: ${flag.message}');
      }
    }

    setState(() => _isLoading = true);

    // Show confirmation popup before proceeding
    final confirmed = await StepConfirmPopup.show(context, stepNumber: 3);
    if (!confirmed || !mounted) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      await Future.delayed(const Duration(seconds: 2));

      // Store categorized transactions in OCR results for Steps 4-9
      ref.read(ocrResultsProvider.notifier).addResult('bank_statement', {
        ..._statementOcrData ?? {},
        'categorized_transactions': _categorizedTransactions.map((t) => t.toJson()).toList(),
      });

      ref.read(verifiedProfileProvider.notifier).updateStep3(BankInfo(
        isVerified: true,
        accountNumber: _accCtrl.text,
        ifscCode: _ifscCtrl.text,
        bankName: _bankNameCtrl.text,
        accountHolderName: _holderNameCtrl.text,
        monthlyCredits: _monthlyCredits,
        monthlyDebits: _monthlyDebits,
        transactions: _transactions.map((e) => BankTransaction.fromJson(e is Map<String, dynamic> ? e : {})).toList(),
      ));
      ref.read(stepStatusProvider.notifier).setStatus(3, StepStatus.verified);
      ref.read(stepStatusProvider.notifier).resetStepsAfter(3); // GAP 3: Reset downstream on re-submit

      GigLogger.sectionHeader('GLOBAL STATE UPDATE — verifiedProfileProvider');
      GigLogger.stateUpdate('verifiedProfileProvider', 'bankInfo.accountNumber',    '****${_accCtrl.text.substring(_accCtrl.text.length > 4 ? _accCtrl.text.length - 4 : 0)}');
      GigLogger.stateUpdate('verifiedProfileProvider', 'bankInfo.bankName',         _bankNameCtrl.text);
      GigLogger.stateUpdate('verifiedProfileProvider', 'bankInfo.transactions',     '${_transactions.length} txns stored');
      GigLogger.stateUpdate('verifiedProfileProvider', 'bankInfo.isVerified',       'true');
      GigLogger.stateUpdate('stepStatusProvider',      'step[3]',                   'StepStatus.verified');
      GigLogger.info('NOTE: Steps 4-8 are OPTIONAL. User can jump directly to Step 9.');
      GigLogger.ok('Step 3 Bank complete — mandatory steps finished');
      
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.success(context, 'Bank verified ✓ (${_transactions.length} txns categorized)');
        context.push(AppRoutes.scoreStep(4));
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyIfsc() async {
    final text = _ifscCtrl.text.trim().toUpperCase();

    // ── REAL FORMAT VALIDATION (per spec) ──
    final formatIssue = Step3Validator.validateIfscFormat(text);
    if (formatIssue != null) {
      AppToast.error(context, formatIssue.message);
      print('[Step3 Validation] IFSC format FAILED: ${formatIssue.code}');
      return;
    }
    print('[Step3 Validation] IFSC format PASSED for $text');
    
    setState(() => _isIfscVerifying = true);
    
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.verifyIfsc(text);
      if (mounted) {
        setState(() {
          _ifscVerified = true;
          _isIfscVerifying = false;
          _bankNameCtrl.text = result['bank_name'] ?? '';
          _branchCtrl.text = result['branch_name'] ?? '';
        });
        AppToast.success(context, 'IFSC Verified!', subtitle: 'Bank details auto-filled.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isIfscVerifying = false);
        final msg = e.toString().replaceFirst('Exception: ', '');
        if (msg.contains('not_found') || msg.contains('not found')) {
          AppToast.error(context, 'IFSC not found. Please check and try again.');
        } else if (msg.contains('invalid_format')) {
          AppToast.error(context, 'Invalid IFSC format.');
        } else if (msg.contains('Network')) {
          AppToast.error(context, 'Network error. Please check your connection.');
        } else {
          AppToast.error(context, 'IFSC verification failed. Please try again.');
        }
      }
    }
  }

  Future<void> _verifyAccount() async {
    final acc = _accCtrl.text.trim();
    final ifsc = _ifscCtrl.text.trim().toUpperCase();
    
    // ── REAL FORMAT VALIDATION (per spec) ──
    final formatIssue = Step3Validator.validateAccountFormat(acc);
    if (formatIssue != null) {
      AppToast.error(context, formatIssue.message);
      print('[Step3 Validation] Account format FAILED: ${formatIssue.code}');
      return;
    }

    if (!_ifscVerified) {
      AppToast.error(context, 'Missing Details', subtitle: 'Please verify IFSC first.');
      return;
    }
    print('[Step3 Validation] Account format PASSED for $acc');

    setState(() => _isAccVerifying = true);
    
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.verifyAccount(acc, ifsc);
      if (mounted) {
        setState(() {
          _accVerified = true;
          _isAccVerifying = false;
          _holderNameCtrl.text = result['account_holder'] ?? '';
        });
        AppToast.success(context, 'Account Verified!', subtitle: 'Account holder auto-filled.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAccVerifying = false);
        final msg = e.toString().replaceFirst('Exception: ', '');
        if (msg.contains('not_found') || msg.contains('not found')) {
          AppToast.error(context, 'Account not found. Please check the account number and IFSC.');
        } else if (msg.contains('invalid_format')) {
          AppToast.error(context, 'Invalid account number format.');
        } else if (msg.contains('Network')) {
          AppToast.error(context, 'Network error. Please check your connection.');
        } else {
          AppToast.error(context, 'Account verification failed. Please try again.');
        }
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

          // Double-tap anywhere in this section to autofill all fields
          GestureDetector(
            onDoubleTap: _fillFromDemoProfile,
            child: Column(
              children: [
                AppTextField(
                  label: 'Bank Name *',
                  controller: _bankNameCtrl,
                  onChanged: (_) => setState(() {}),
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
              ],
            ),
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
              key: ValueKey('bank_stmt_$_bankStatementUploadKey'),
              title: 'Bank Statement (Primary Bank) *',
              subtitle: 'PDF only — statement must match your verified account',
              docType: 'bank_statement',
              ocrService: ocrService,
              onExtracted: (data) {
                setState(() {
                  _uploadMismatchError = null; // clear previous error first

                  // ── Account number cross-check against OCR ──────────────
                  final ocrAccount = (data['account_number'] as String? ?? '')
                      .replaceAll(RegExp(r'[^0-9]'), '');
                  final enteredAccount = _accCtrl.text.trim()
                      .replaceAll(RegExp(r'[^0-9]'), '');
                  if (ocrAccount.isNotEmpty && enteredAccount.isNotEmpty &&
                      ocrAccount != enteredAccount) {
                    _uploadMismatchError =
                        'Account mismatch: entered $enteredAccount but statement shows $ocrAccount. '
                        'Please upload the correct bank statement.';
                    _pdfUploaded = false; // mismatch — block continue button
                  }
                  // GAP 4 FIX: MERGE bank statement uploads instead of
                  // replacing. If user uploads a second statement, its
                  // transactions are appended and aggregates are combined.
                  // ═══════════════════════════════════════════════════════
                  if (data['monthly_credits'] != null) {
                    final newCredits = (data['monthly_credits'] as List).map((e) => (e as num).toDouble()).toList();
                    if (_monthlyCredits.isEmpty) {
                      _monthlyCredits = newCredits;
                    } else {
                      // Merge: extend with new months or sum overlapping
                      for (int i = 0; i < newCredits.length; i++) {
                        if (i < _monthlyCredits.length) {
                          _monthlyCredits[i] += newCredits[i];
                        } else {
                          _monthlyCredits.add(newCredits[i]);
                        }
                      }
                    }
                  }
                  if (data['monthly_debits'] != null) {
                    final newDebits = (data['monthly_debits'] as List).map((e) => (e as num).toDouble()).toList();
                    if (_monthlyDebits.isEmpty) {
                      _monthlyDebits = newDebits;
                    } else {
                      for (int i = 0; i < newDebits.length; i++) {
                        if (i < _monthlyDebits.length) {
                          _monthlyDebits[i] += newDebits[i];
                        } else {
                          _monthlyDebits.add(newDebits[i]);
                        }
                      }
                    }
                  }
                  if (data['transactions'] != null) {
                    final newTxns = data['transactions'] as List;
                    if (_transactions.isEmpty) {
                      _transactions = newTxns;
                    } else {
                      // Merge: append new transactions to existing list
                      _transactions = [..._transactions, ...newTxns];
                    }
                  }
                  // Merge OCR data — keep latest metadata, merge transactions
                  if (_statementOcrData == null) {
                    _statementOcrData = data;
                  } else {
                    _statementOcrData = {
                      ..._statementOcrData!,
                      ...data,
                      'transactions': _transactions,
                      'monthly_credits': _monthlyCredits,
                      'monthly_debits': _monthlyDebits,
                    };
                  }
                  ref.read(ocrResultsProvider.notifier).addResult('bank_statement', _statementOcrData!);
                  // Only mark as uploaded if no mismatch error
                  if (_uploadMismatchError == null) {
                    _pdfUploaded = true;
                  }
                });
                if (_uploadMismatchError == null) {
                  AppToast.success(context, 'Bank Statement Uploaded ✓',
                      subtitle: _transactions.isNotEmpty
                          ? '${_transactions.length} transactions extracted'
                          : 'Statement processed successfully');
                }
              },
            ),

          // ── Inline mismatch error after upload ──────────────────────────
          if (_uploadMismatchError != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0x22F44336),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.5), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error_rounded, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Bank Validation Failed',
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(_uploadMismatchError!,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4)),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _uploadMismatchError = null;
                        _pdfUploaded = false;
                        _transactions = [];
                        _monthlyCredits = [];
                        _monthlyDebits = [];
                        _statementOcrData = null;
                        _bankStatementUploadKey++; // forces DocumentUploadCard to reset
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('OK, Re-upload',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ),
                ],
              ),
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
        label: isVerified
            ? 'Continue to Next Step'
            : (_ifscVerified && _accVerified ? 'Continue' : 'Verify Account'),
        isLoading: _isLoading,
        isDisabled: (!isVerified && !_isFormValid) || _uploadMismatchError != null,
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
                  onChanged: (_) => setState(() {}), // re-evaluate button state on every keystroke
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
