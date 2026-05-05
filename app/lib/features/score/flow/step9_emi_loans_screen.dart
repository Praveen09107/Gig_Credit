import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/layout/scrollable_step_layout.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../state/step_status_provider.dart';
import '../../../../state/verified_profile_provider.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../models/verified_profile/emi_loans_info.dart';
import '../../../../app/app_router.dart';
import '../../../../demo/demo_profile_manager.dart';

class Step9EmiLoansScreen extends ConsumerStatefulWidget {
  const Step9EmiLoansScreen({super.key});

  @override
  ConsumerState<Step9EmiLoansScreen> createState() => _Step9EmiLoansScreenState();
}

class _LoanEntry {
  final TextEditingController lenderCtrl;
  final TextEditingController emiCtrl;
  final TextEditingController prevDateCtrl;
  final TextEditingController latestDateCtrl;

  _LoanEntry()
      : lenderCtrl = TextEditingController(),
        emiCtrl = TextEditingController(),
        prevDateCtrl = TextEditingController(),
        latestDateCtrl = TextEditingController();

  void dispose() {
    lenderCtrl.dispose();
    emiCtrl.dispose();
    prevDateCtrl.dispose();
    latestDateCtrl.dispose();
  }
}

class _Step9EmiLoansScreenState extends ConsumerState<Step9EmiLoansScreen> {
  bool _hasActiveLoans = false;
  bool _isLoading = false;
  final List<_LoanEntry> _loanEntries = [_LoanEntry()];

  @override
  void dispose() {
    for (final e in _loanEntries) {
      e.dispose();
    }
    super.dispose();
  }

  /// Demo autofill — populates EMI info from demo profile
  void _fillFromDemoProfile() {
    final emiInfo = DemoProfileManager().profile.emiLoansInfo;
    if (emiInfo.loans.isNotEmpty) {
      setState(() {
        _hasActiveLoans = true;
        _loanEntries.clear();
        for (final loan in emiInfo.loans) {
          final entry = _LoanEntry();
          entry.lenderCtrl.text = loan.loanType; // using loanType as lender/type
          entry.emiCtrl.text = loan.monthlyEmi.toStringAsFixed(0);
          _loanEntries.add(entry);
        }
      });
    }
  }

  void _addLoan() {
    if (_loanEntries.length >= 5) return;
    setState(() => _loanEntries.add(_LoanEntry()));
  }

  void _removeLoan(int index) {
    if (_loanEntries.length <= 1) return;
    setState(() {
      _loanEntries[index].dispose();
      _loanEntries.removeAt(index);
    });
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2018),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ctrl.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      setState(() {});
    }
  }

  Future<void> _submit() async {
    final statusMap = ref.read(stepStatusProvider);
    if (statusMap[9] == StepStatus.verified) {
       context.push(AppRoutes.scoreGenerating);
       return;
    }

    setState(() => _isLoading = true);

    List<EmiEntry> extractedLoans = [];
    if (_hasActiveLoans) {
      for (final entry in _loanEntries) {
        final amount = double.tryParse(entry.emiCtrl.text) ?? 0.0;
        if (amount > 0) {
          extractedLoans.add(EmiEntry(
            loanType: entry.lenderCtrl.text,
            monthlyEmi: amount,
            regularPayment: true,
          ));
        }
      }
    }

    ref.read(verifiedProfileProvider.notifier).updateStep9(EmiLoansInfo(
      isVerified: true,
      loans: extractedLoans,
    ));
    ref.read(stepStatusProvider.notifier).setStatus(9, StepStatus.verified);

    if (mounted) {
      setState(() => _isLoading = false);
      context.push(AppRoutes.scoreGenerating);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusMap = ref.watch(stepStatusProvider);

    return ScrollableStepLayout(
      currentStep: 9,
      stepCompletionMap: statusMap.map((key, value) => MapEntry(key, value == StepStatus.verified)),
      onStepTapped: (step) => context.push(AppRoutes.scoreStep(step)),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onDoubleTap: _fillFromDemoProfile,
            child: const Text('EMI & Loans', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          Text('Declare active loan and EMI obligations.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 20),

          // Top-level toggle
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _hasActiveLoans ? AppColors.accent.withValues(alpha: 0.4) : AppColors.surfaceVariant),
            ),
            child: SwitchListTile(
              title: const Text('Do you have active EMIs or loans?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(_hasActiveLoans ? 'Fill in your loan details below' : 'Skip if you have no active loans',
                  style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
              value: _hasActiveLoans,
              onChanged: (v) => setState(() => _hasActiveLoans = v),
              activeColor: AppColors.accent,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            ),
          ),

          if (_hasActiveLoans) ...[
            const SizedBox(height: 20),
            ...List.generate(_loanEntries.length, (i) => _buildLoanCard(i)),
            if (_loanEntries.length < 5) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: _addLoan,
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: Text('Add Another Loan (${_loanEntries.length}/5)', style: const TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ],

          if (!_hasActiveLoans) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 24),
                  SizedBox(width: 12),
                  Expanded(child: Text('No active loans — this is a positive signal for your credit score!', style: TextStyle(fontSize: 13, color: Colors.green))),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomBar: PrimaryButton(
        label: 'Generate Score',
        isLoading: _isLoading,
        isDisabled: false,
        onPressed: _submit,
      ),
    );
  }

  Widget _buildLoanCard(int index) {
    final entry = _loanEntries[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentLight]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Loan ${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                if (_loanEntries.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: () => _removeLoan(index),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(label: 'Lender Name *', controller: entry.lenderCtrl, hint: 'SBI / HDFC / Bajaj / IIFL / Other'),
            const SizedBox(height: 12),
            AppTextField(label: 'Monthly EMI Amount (₹) *', controller: entry.emiCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _pickDate(entry.prevDateCtrl),
              child: AbsorbPointer(
                child: AppTextField(label: 'Previous Debit Date *', controller: entry.prevDateCtrl, hint: 'Tap to pick date', suffixIcon: const Icon(Icons.calendar_today, size: 18)),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _pickDate(entry.latestDateCtrl),
              child: AbsorbPointer(
                child: AppTextField(label: 'Latest Debit Date *', controller: entry.latestDateCtrl, hint: 'Tap to pick date', suffixIcon: const Icon(Icons.calendar_today, size: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
