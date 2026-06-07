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
import '../../../../state/api_service_provider.dart';
import '../../../../state/ocr_results_provider.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../models/verified_profile/utility_info.dart';
import '../../../../app/app_router.dart';
import '../../../../demo/demo_profile_manager.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';
import '../../../../shared/widgets/feedback/step_popups.dart';
import '../../../../scoring/validation/bank_transaction_matcher.dart';
import '../../../../scoring/validation/step3_validator.dart';
import '../../../../scoring/validation/fuzzy_matcher.dart';
import '../../../../shared/widgets/feedback/verification_phase_overlay.dart';

import '../../../../shared/widgets/feedback/step_validation_banner.dart';
import '../../../../services/gig_logger.dart';

class Step4UtilityScreen extends ConsumerStatefulWidget {
  const Step4UtilityScreen({super.key});

  @override
  ConsumerState<Step4UtilityScreen> createState() => _Step4UtilityScreenState();
}

class _Step4UtilityScreenState extends ConsumerState<Step4UtilityScreen> with VerificationPhaseMixin {
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
  // Counters for allowing up to 6 consecutive bills
  int _elecUploadCount = 1;
  int _waterUploadCount = 1;
  int _gasUploadCount = 1;
  int _mobileUploadCount = 1;
  int _internetUploadCount = 1;
  int _rentUploadCount = 1;

  // Inline validation errors
  List<String> _validationErrors = [];
  List<String> _validationWarnings = [];

  void _runInlineValidation() {
    final errors = <String>[];
    final warnings = <String>[];
    final profile = ref.read(verifiedProfileProvider);
    final step1Mobile = profile.personalInfo.mobileNumber;
    final step1Name = profile.personalInfo.fullName;

    // Mobile bill must match Step 1 mobile
    if (_hasMobile && _mobileMobileCtrl.text.trim().isNotEmpty) {
      final billMobile = _mobileMobileCtrl.text.trim();
      if (step1Mobile.isNotEmpty && billMobile != step1Mobile) {
        errors.add('Mobile bill number ($billMobile) does not match your registered mobile ($step1Mobile).');
      }
    }

    // Bill names must match Step 1 name (soft flag)
    if (step1Name.isNotEmpty) {
      for (final ctrl in [_elecNameCtrl, _waterNameCtrl, _gasNameCtrl, _mobileNameCtrl, _internetNameCtrl]) {
        final billName = ctrl.text.trim();
        if (billName.isEmpty) continue;
        final upper1 = step1Name.toUpperCase();
        final upper2 = billName.toUpperCase();
        if (!upper1.contains(upper2.split(' ').first) && !upper2.contains(step1Name.split(' ').first.toUpperCase())) {
          warnings.add('Bill name "$billName" may not match your profile name "$step1Name". Please verify.');
          break; // one warning is enough
        }
      }
    }

    setState(() {
      _validationErrors = errors;
      _validationWarnings = warnings;
    });
  }

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

  /// Demo autofill — populates utility bill toggles and amounts from demo profile
  void _fillFromDemoProfile() {
    final bills = DemoProfileManager().profile.utilityInfo.bills;
    for (final bill in bills) {
      switch (bill.billType) {
        case 'electricity': _hasElectricity = true; _elecAmountCtrl.text = bill.amount.toStringAsFixed(0); _elecUploaded = true; _elecUploadCount = 6; break;
        case 'water': _hasWater = true; _waterAmountCtrl.text = bill.amount.toStringAsFixed(0); _waterUploaded = true; _waterUploadCount = 6; break;
        case 'gas': _hasGas = true; _gasAmountCtrl.text = bill.amount.toStringAsFixed(0); _gasUploaded = true; _gasUploadCount = 6; break;
        case 'mobile': _hasMobile = true; _mobileAmountCtrl.text = bill.amount.toStringAsFixed(0); _mobileUploaded = true; _mobileUploadCount = 6; break;
        case 'internet': case 'wifi': _hasInternet = true; _internetAmountCtrl.text = bill.amount.toStringAsFixed(0); _internetUploaded = true; _internetUploadCount = 6; break;
        case 'rent': _hasRent = true; _rentAmountCtrl.text = bill.amount.toStringAsFixed(0); _rentUploaded = true; _rentUploadCount = 6; break;
      }
    }
    setState(() {});
  }

  /// Step 4 is optional — user can proceed without any bills.
  /// But if a bill is toggled, its required fields must be filled.
  bool get _hasAnyBillToggled =>
      _hasElectricity || _hasWater || _hasGas ||
      _hasMobile || _hasInternet || _hasRent;

  /// Returns true if all toggled bills have their required fields filled.
  bool get _toggledBillsValid {
    if (_hasElectricity &&
        (_elecConsumerCtrl.text.isEmpty || _elecNameCtrl.text.isEmpty || _elecAmountCtrl.text.isEmpty)) return false;
    if (_hasWater &&
        (_waterConsumerCtrl.text.isEmpty || _waterNameCtrl.text.isEmpty || _waterAmountCtrl.text.isEmpty)) return false;
    if (_hasGas &&
        (_gasConsumerCtrl.text.isEmpty || _gasNameCtrl.text.isEmpty || _gasAmountCtrl.text.isEmpty)) return false;
    if (_hasMobile &&
        (_mobileMobileCtrl.text.isEmpty || _mobileNameCtrl.text.isEmpty || _mobileAmountCtrl.text.isEmpty)) return false;
    if (_hasInternet &&
        (_internetAccountCtrl.text.isEmpty || _internetNameCtrl.text.isEmpty || _internetAmountCtrl.text.isEmpty)) return false;
    if (_hasRent &&
        (_rentTenantCtrl.text.isEmpty || _rentAmountCtrl.text.isEmpty)) return false;
    return true;
  }
  Future<void> _submit() async {
    final statusMap = ref.read(stepStatusProvider);
    if (statusMap[4] == StepStatus.verified) {
       context.push(AppRoutes.scoreStep(5));
       return;
    }

    // ═══════════════════════════════════════════════════════════════
    // GAP 5 FIX: Validate that toggled bills have at least 1 upload
    // and warn if fewer than 6 bills uploaded (consecutive months spec)
    // ═══════════════════════════════════════════════════════════════
    if (_hasElectricity && !_elecUploaded) {
      AppToast.error(context, 'Electricity Bill Required', subtitle: 'Please upload at least 1 electricity bill document.');
      return;
    }
    if (_hasWater && !_waterUploaded) {
      AppToast.error(context, 'WiFi Bill Required', subtitle: 'Please upload at least 1 WiFi/broadband bill document.');
      return;
    }
    if (_hasGas && !_gasUploaded) {
      AppToast.error(context, 'Gas Bill Required', subtitle: 'Please upload at least 1 gas/LPG bill document.');
      return;
    }
    if (_hasMobile && !_mobileUploaded) {
      AppToast.error(context, 'Mobile Bill Required', subtitle: 'Please upload at least 1 mobile bill document.');
      return;
    }
    if (_hasInternet && !_internetUploaded) {
      AppToast.error(context, 'Internet Bill Required', subtitle: 'Please upload at least 1 internet bill document.');
      return;
    }
    if (_hasRent && !_rentUploaded) {
      AppToast.error(context, 'Rent Document Required', subtitle: 'Please upload at least 1 rent receipt/agreement.');
      return;
    }

    // Warn if fewer than 6 bills uploaded (spec requires 6 consecutive months)
    final insufficientBills = <String>[];
    if (_hasElectricity && _elecUploadCount < 6) insufficientBills.add('Electricity (${_elecUploadCount - 1}/6)');
    if (_hasWater && _waterUploadCount < 6) insufficientBills.add('WiFi (${_waterUploadCount - 1}/6)');
    if (_hasGas && _gasUploadCount < 6) insufficientBills.add('Gas (${_gasUploadCount - 1}/6)');
    if (_hasMobile && _mobileUploadCount < 6) insufficientBills.add('Mobile (${_mobileUploadCount - 1}/6)');
    if (_hasInternet && _internetUploadCount < 6) insufficientBills.add('Internet (${_internetUploadCount - 1}/6)');
    if (_hasRent && _rentUploadCount < 6) insufficientBills.add('Rent (${_rentUploadCount - 1}/6)');

    if (insufficientBills.isNotEmpty) {
      // Soft warning — spec says 6 consecutive months but we don't hard-block
      // since OCR can't verify dates. Show warning and let user proceed.
      AppToast.warning(context, 'Fewer than 6 months uploaded: ${insufficientBills.join(', ')}. Upload 6 consecutive months for best score.');
    }

    // Show confirmation popup before proceeding
    final confirmed = await StepConfirmPopup.show(context, stepNumber: 4);
    if (!confirmed || !mounted) return;

    setState(() => _isLoading = true);
    showVerificationPhase();

    try {
      final profile = ref.read(verifiedProfileProvider);
      // ═══════════════════════════════════════════════════════════════
      // SPEC: Mobile bill number MUST match Step-1 registered mobile
      // This is a HARD FAIL per spec Section 5.3 — identity lock
      // ═══════════════════════════════════════════════════════════════
      if (_hasMobile && _mobileMobileCtrl.text.trim().isNotEmpty) {
        final billMobile = _mobileMobileCtrl.text.trim();
        final step1Mobile = profile.personalInfo.mobileNumber;
        if (step1Mobile.isNotEmpty && billMobile != step1Mobile) {
          if (mounted) {
            AppToast.error(context, 'Mobile number on bill does not match your registered mobile number.',
                subtitle: 'Bill: $billMobile vs Registered: $step1Mobile');
            setState(() => _isLoading = false);
          }
          return;
        }
      }

      // ═══════════════════════════════════════════════════════════════
      // Build bill entries from form data
      // ═══════════════════════════════════════════════════════════════
      List<Map<String, dynamic>> billsForVerification = [];
      List<UtilityBillEntry> extractedBills = [];

      void collectBill(bool hasBill, String type, TextEditingController amtCtrl) {
        if (hasBill) {
          final amt = double.tryParse(amtCtrl.text.replaceAll(',', '')) ?? 0.0;
          if (amt > 0) {
            billsForVerification.add({'type': type, 'amount': amt});
          }
        }
      }

      collectBill(_hasElectricity, 'electricity', _elecAmountCtrl);
      collectBill(_hasWater, 'water', _waterAmountCtrl);
      collectBill(_hasGas, 'gas', _gasAmountCtrl);
      collectBill(_hasMobile, 'mobile', _mobileAmountCtrl);
      collectBill(_hasInternet, 'internet', _internetAmountCtrl);
      collectBill(_hasRent, 'rent', _rentAmountCtrl);

      // ═══════════════════════════════════════════════════════════════
      // REAL CROSS-VERIFICATION against bank CSV (per spec)
      // ═══════════════════════════════════════════════════════════════
      final ocrResults = ref.read(ocrResultsProvider);
      final bankOcr = ocrResults['bank_statement'];

      // Get categorized transactions from Step 3
      List<CategorizedTransaction> categorized = [];
      if (bankOcr != null && bankOcr['categorized_transactions'] != null) {
        final rawList = bankOcr['categorized_transactions'] as List;
        for (final item in rawList) {
          if (item is Map<String, dynamic>) {
            final cat = TxnCategory.values.firstWhere(
              (c) => c.name == (item['category'] as String? ?? ''),
              orElse: () => TxnCategory.other,
            );
            categorized.add(CategorizedTransaction(
              date: item['date'] as String? ?? '',
              amount: (item['amount'] as num?)?.toDouble() ?? 0.0,
              type: item['type'] as String? ?? 'debit',
              description: item['description'] as String? ?? '',
              category: cat,
              merchantRaw: item['merchant_raw'] as String?,
              refId: item['ref_id'] as String?,
            ));
          }
        }
      }
      // Fallback: use raw bank transactions if categorized not available
      if (categorized.isEmpty && profile.bankInfo.transactions.isNotEmpty) {
        categorized = TransactionCategorizer.categorize(
          profile.bankInfo.transactions.map((t) => t.toJson()).toList(),
        );
      }

      final matcher = BankTransactionMatcher(categorized);
      final verifyResult = matcher.verifyUtilityBills(billsForVerification);

      // Log results
      print('\n════════════════════════════════════════════');
      print('STEP 4 UTILITY CROSS-VERIFICATION RESULT');
      print('Total bills: ${verifyResult.totalItems}');
      print('Matched: ${verifyResult.matchedItems}');
      print('Soft flags: ${verifyResult.softFlagItems}');
      print('Not found: ${verifyResult.failedItems}');
      print('Match ratio: ${(verifyResult.matchRatio * 100).toStringAsFixed(1)}%');
      for (final item in verifyResult.items) {
        print('  [${item.status}] ${item.label}: ₹${item.declaredAmount} → ${item.matchResult.matchType} (${(item.matchResult.confidence * 100).toStringAsFixed(0)}% confidence)');
      }
      for (final w in verifyResult.warnings) {
        print('  ⚠ $w');
      }
      print('════════════════════════════════════════════\n');

      // ═══════════════════════════════════════════════════════════════
      // IDENTITY CROSS-CHECK: bill names vs Step 1/2 name
      // ═══════════════════════════════════════════════════════════════
      final step1Name = profile.personalInfo.fullName;
      final namesForCheck = [
        _elecNameCtrl.text.trim(),
        _waterNameCtrl.text.trim(),
        _gasNameCtrl.text.trim(),
        _mobileNameCtrl.text.trim(),
        _internetNameCtrl.text.trim(),
        _rentTenantCtrl.text.trim(),
      ];

      for (final billName in namesForCheck) {
        if (billName.isEmpty || step1Name.isEmpty) continue;
        final match = FuzzyMatcher.matchNames(step1Name, billName);
        if (match.severity == MatchSeverity.hardFail) {
          GigLogger.crossValidation('Step1.name', step1Name, 'Bill.name', billName.trim(), false);
        } else if (match.severity == MatchSeverity.softFlag) {
          GigLogger.warn('SOFT: Step1 "$step1Name" vs bill "$billName" (${(match.score * 100).toStringAsFixed(1)}%)');
        }
      }

      // Show warnings for unmatched bills
      if (verifyResult.warnings.isNotEmpty && mounted) {
        for (final w in verifyResult.warnings) {
          AppToast.warning(context, w);
        }
      }

      // Build verified bill entries with match status
      for (final item in verifyResult.items) {
        extractedBills.add(UtilityBillEntry(
          billType: item.label,
          amount: item.declaredAmount,
          verified: item.status == 'matched',
          transactionRef: item.matchResult.matchedTransaction?.refId,
        ));
      }

      // Also add bills that weren't in verification (e.g., zero-amount)
      if (extractedBills.isEmpty) {
        // Fallback: add all toggled bills as unverified
        void addFallback(bool has, String type, TextEditingController ctrl) {
          if (has) {
            extractedBills.add(UtilityBillEntry(
              billType: type,
              amount: double.tryParse(ctrl.text.replaceAll(',', '')) ?? 0.0,
              verified: false,
            ));
          }
        }
        addFallback(_hasElectricity, 'electricity', _elecAmountCtrl);
        addFallback(_hasWater, 'water', _waterAmountCtrl);
        addFallback(_hasGas, 'gas', _gasAmountCtrl);
        addFallback(_hasMobile, 'mobile', _mobileAmountCtrl);
        addFallback(_hasInternet, 'internet', _internetAmountCtrl);
        addFallback(_hasRent, 'rent', _rentAmountCtrl);
      }

      // ═══════════════════════════════════════════════════════════════
      // GAP 6 FIX: Backend API calls for utility verification
      // Non-blocking — failures are soft-flagged, flow continues
      // ═══════════════════════════════════════════════════════════════
      final api = ref.read(apiServiceProvider);
      if (_hasElectricity && _elecConsumerCtrl.text.trim().isNotEmpty) {
        try {
          final result = await api.verifyEb(_elecConsumerCtrl.text.trim());
          GigLogger.ok('EB verify: ${result['status'] ?? 'ok'}');
        } catch (e) {
          GigLogger.warn('EB verify failed (non-blocking): $e');
        }
      }
      if (_hasGas && _gasConsumerCtrl.text.trim().isNotEmpty) {
        try {
          // Assume provider is typed in name field for now
          final result = await api.verifyLpg(_gasConsumerCtrl.text.trim(), _gasNameCtrl.text.trim());
          GigLogger.ok('LPG verify: ${result['status'] ?? 'ok'}');
        } catch (e) {
          GigLogger.warn('LPG verify failed (non-blocking): $e');
        }
      }

      dismissVerificationPhase();

      ref.read(verifiedProfileProvider.notifier).updateStep4(UtilityInfo(
        isVerified: true,
        bills: extractedBills,
      ));
      ref.read(stepStatusProvider.notifier).setStatus(4, StepStatus.verified);

      GigLogger.stepBanner(4, 'UTILITY BILLS (OPTIONAL) — COMPLETE');
      GigLogger.stateUpdate('verifiedProfileProvider', 'utilityInfo.bills',     '${extractedBills.length} bills');
      GigLogger.stateUpdate('verifiedProfileProvider', 'utilityInfo.isVerified','true');
      GigLogger.stateUpdate('stepStatusProvider',      'step[4]',               'StepStatus.verified');
      GigLogger.ok('Step 4 Utility complete');

      if (mounted) {
        setState(() => _isLoading = false);
        final matchPct = (verifyResult.matchRatio * 100).toStringAsFixed(0);
        AppToast.success(context, 'Utility verified ✓ ($matchPct% bank-matched)');
        context.push(AppRoutes.scoreStep(5));
      }
    } catch (e) {
      debugPrint('[Step4] Error: $e');
      if (mounted) setState(() => _isLoading = false);
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
              GestureDetector(
                onDoubleTap: _fillFromDemoProfile,
                child: const Text('Utility Bills', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              if (isVerified) const VerificationBadge(),
            ],
          ),
          const SizedBox(height: 4),
          const Text('All modules optional. Toggle any bills you have.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
              ListenableBuilder(
                listenable: Listenable.merge([_elecConsumerCtrl, _elecNameCtrl, _elecAmountCtrl]),
                builder: (context, _) {
                  final isReady = _elecConsumerCtrl.text.isNotEmpty && _elecNameCtrl.text.isNotEmpty && _elecAmountCtrl.text.isNotEmpty;
                  return Opacity(
                    opacity: isReady ? 1.0 : 0.5,
                    child: IgnorePointer(
                      ignoring: !isReady,
                      child: Column(
                        children: [
                          if (!isReady)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Text('Fill all details above to enable document upload', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ...List.generate(_elecUploadCount, (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DocumentUploadCard(
                              title: 'Electricity Bill ${index + 1} *', 
                              subtitle: 'Consecutive last 6 months bills from current date', 
                              docType: 'utility_electricity', 
                              ocrService: ocrService, 
                              onExtracted: (_) {
                                if (_elecUploadCount < 6) setState(() { _elecUploadCount++; _elecUploaded = true; });
                              }
                            ),
                          )),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          // ── WiFi ──
          _buildBillModule(
            title: '📶 WiFi / Broadband Bill',
            hint: 'Address and payment regularity proof',
            selected: _hasWater,
            onToggle: (v) => setState(() => _hasWater = v),
            children: [
              AppTextField(label: 'Account / Customer No *', controller: _waterConsumerCtrl),
              const SizedBox(height: 12),
              AppTextField(label: 'Name as per Bill *', controller: _waterNameCtrl),
              const SizedBox(height: 12),
              AppTextField(label: 'Amount Paid (₹) *', controller: _waterAmountCtrl, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: Listenable.merge([_waterConsumerCtrl, _waterNameCtrl, _waterAmountCtrl]),
                builder: (context, _) {
                  final isReady = _waterConsumerCtrl.text.isNotEmpty && _waterNameCtrl.text.isNotEmpty && _waterAmountCtrl.text.isNotEmpty;
                  return Opacity(
                    opacity: isReady ? 1.0 : 0.5,
                    child: IgnorePointer(
                      ignoring: !isReady,
                      child: Column(
                        children: [
                          if (!isReady)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Text('Fill all details above to enable document upload', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ...List.generate(_waterUploadCount, (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DocumentUploadCard(
                              title: 'WiFi Bill ${index + 1} *', 
                              subtitle: 'Consecutive last 6 months bills from current date', 
                              docType: 'utility_wifi', 
                              ocrService: ocrService, 
                              onExtracted: (_) {
                                if (_waterUploadCount < 6) setState(() { _waterUploadCount++; _waterUploaded = true; });
                              }
                            ),
                          )),
                        ],
                      ),
                    ),
                  );
                },
              ),
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
              ListenableBuilder(
                listenable: Listenable.merge([_gasConsumerCtrl, _gasNameCtrl, _gasAmountCtrl]),
                builder: (context, _) {
                  final isReady = _gasConsumerCtrl.text.isNotEmpty && _gasNameCtrl.text.isNotEmpty && _gasAmountCtrl.text.isNotEmpty;
                  return Opacity(
                    opacity: isReady ? 1.0 : 0.5,
                    child: IgnorePointer(
                      ignoring: !isReady,
                      child: Column(
                        children: [
                          if (!isReady)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Text('Fill all details above to enable document upload', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ...List.generate(_gasUploadCount, (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DocumentUploadCard(
                              title: 'Gas Bill ${index + 1} *', 
                              subtitle: 'Consecutive last 6 months bills from current date', 
                              docType: 'utility_gas', 
                              ocrService: ocrService, 
                              onExtracted: (_) {
                                if (_gasUploadCount < 6) setState(() { _gasUploadCount++; _gasUploaded = true; });
                              }
                            ),
                          )),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          // ── Mobile ──
          _buildBillModule(
            title: '📱 Mobile / Phone Bill',
            hint: 'Postpaid bill proves payment discipline',
            selected: _hasMobile,
            onToggle: (v) => setState(() => _hasMobile = v),
            children: [
              AppTextField(label: 'Mobile Number *', controller: _mobileMobileCtrl, keyboardType: TextInputType.phone,
                onChanged: (_) => _runInlineValidation()),
              const SizedBox(height: 12),
              AppTextField(label: 'Account / Customer Number *', controller: _mobileAccountCtrl),
              const SizedBox(height: 12),
              AppTextField(label: 'Name as per Bill *', controller: _mobileNameCtrl),
              const SizedBox(height: 12),
              AppTextField(label: 'Amount Paid (₹) *', controller: _mobileAmountCtrl, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: Listenable.merge([_mobileMobileCtrl, _mobileAccountCtrl, _mobileNameCtrl, _mobileAmountCtrl]),
                builder: (context, _) {
                  final isReady = _mobileMobileCtrl.text.isNotEmpty && _mobileAccountCtrl.text.isNotEmpty && _mobileNameCtrl.text.isNotEmpty && _mobileAmountCtrl.text.isNotEmpty;
                  return Opacity(
                    opacity: isReady ? 1.0 : 0.5,
                    child: IgnorePointer(
                      ignoring: !isReady,
                      child: Column(
                        children: [
                          if (!isReady)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Text('Fill all details above to enable document upload', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ...List.generate(_mobileUploadCount, (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DocumentUploadCard(
                              title: 'Mobile Bill ${index + 1} *', 
                              subtitle: 'Consecutive last 6 months bills from current date', 
                              docType: 'utility_mobile', 
                              ocrService: ocrService, 
                              onExtracted: (_) {
                                if (_mobileUploadCount < 6) setState(() { _mobileUploadCount++; _mobileUploaded = true; });
                              }
                            ),
                          )),
                        ],
                      ),
                    ),
                  );
                },
              ),
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
              ListenableBuilder(
                listenable: Listenable.merge([_internetAccountCtrl, _internetNameCtrl, _internetAmountCtrl]),
                builder: (context, _) {
                  final isReady = _internetAccountCtrl.text.isNotEmpty && _internetNameCtrl.text.isNotEmpty && _internetAmountCtrl.text.isNotEmpty;
                  return Opacity(
                    opacity: isReady ? 1.0 : 0.5,
                    child: IgnorePointer(
                      ignoring: !isReady,
                      child: Column(
                        children: [
                          if (!isReady)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Text('Fill all details above to enable document upload', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ...List.generate(_internetUploadCount, (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DocumentUploadCard(
                              title: 'Internet Bill ${index + 1} *', 
                              subtitle: 'Consecutive last 6 months bills from current date', 
                              docType: 'utility_internet', 
                              ocrService: ocrService, 
                              onExtracted: (_) {
                                if (_internetUploadCount < 6) setState(() { _internetUploadCount++; _internetUploaded = true; });
                              }
                            ),
                          )),
                        ],
                      ),
                    ),
                  );
                },
              ),
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
              ListenableBuilder(
                listenable: Listenable.merge([_rentTenantCtrl, _rentLandlordCtrl, _rentAddressCtrl, _rentAmountCtrl]),
                builder: (context, _) {
                  final isReady = _rentTenantCtrl.text.isNotEmpty && _rentLandlordCtrl.text.isNotEmpty && _rentAddressCtrl.text.isNotEmpty && _rentAmountCtrl.text.isNotEmpty;
                  return Opacity(
                    opacity: isReady ? 1.0 : 0.5,
                    child: IgnorePointer(
                      ignoring: !isReady,
                      child: Column(
                        children: [
                          if (!isReady)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Text('Fill all details above to enable document upload', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ...List.generate(_rentUploadCount, (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DocumentUploadCard(
                              title: 'Rent Document ${index + 1} *', 
                              subtitle: 'Consecutive last 6 months bills from current date', 
                              docType: 'utility_rent', 
                              ocrService: ocrService, 
                              onExtracted: (_) {
                                if (_rentUploadCount < 6) setState(() { _rentUploadCount++; _rentUploaded = true; });
                              }
                            ),
                          )),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      bottomBar: PrimaryButton(
        label: isVerified ? 'Continue to Next Step' : 'Save & Continue',
        isLoading: _isLoading,
        isDisabled: (!isVerified && !_toggledBillsValid) || _validationErrors.isNotEmpty,
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
            subtitle: Text(hint, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            value: selected,
            onChanged: onToggle,
            activeThumbColor: AppColors.accent,
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
