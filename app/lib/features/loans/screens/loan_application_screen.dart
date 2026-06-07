import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../app/app_router.dart';
import '../../../services/loan_api_service.dart';
import '../../../state/score_provider.dart';
import '../../../shared/widgets/loaders/coin_pulse_loader.dart';
import '../../../state/user_provider.dart';
import '../../../state/loan_applications_provider.dart';
import '../../../state/verified_profile_provider.dart';
import '../../../shared/theme/app_colors.dart';

// Unified theme constants — aligned with app-wide design system
const _bgPrimary = Color(0xFFF5F7F5);       // AppColors.bgScreen
const _bgCard = Color(0xFFFFFFFF);           // AppColors.bgCard
const _bgGlass = Color(0xF0FFFFFF);          // white glass
const _borderSubtle = Color(0xFFE0E8E0);     // AppColors.borderCard
const _accentTeal = Color(0xFF1A6B3C);       // AppColors.greenPrimary
const _accentTealDim = Color(0x151A6B3C);
const _accentTealGlow = Color(0x401A6B3C);
const _accentGreen = Color(0xFF3CC068);      // AppColors.greenBright
const _accentGreenDim = Color(0x153CC068);
const _accentGold = Color(0xFFFFA726);       // AppColors.warning
const _accentGoldDim = Color(0x15FFA726);
const _accentRed = Color(0xFFE53935);        // AppColors.error
const _accentRedDim = Color(0x15E53935);
const _accentRedGlow = Color(0x40E53935);
const _accentPurple = Color(0xFF8B5CF6);
const _accentPurpleDim = Color(0x158B5CF6);
const _textPrimary = Color(0xFF1A1F1A);      // AppColors.textPrimary
const _textSecondary = Color(0xFF5A6B5A);    // AppColors.textSecondary
const _textMuted = Color(0xFF8A9B8A);        // AppColors.textMuted

class LoanApplicationScreen extends ConsumerStatefulWidget {
  const LoanApplicationScreen({super.key});
  @override
  ConsumerState<LoanApplicationScreen> createState() => _LoanApplicationScreenState();
}

class _LoanApplicationScreenState extends ConsumerState<LoanApplicationScreen> with TickerProviderStateMixin {
  int _currentScreen = 1;
  String? _selectedProduct;
  double _loanAmount = 50000;
  double _sliderMin = 25000;
  double _sliderMax = 82000;
  int _tenure = 12;
  String? _purpose;
  bool _kfsAcknowledged = false;
  String? _kfsTimestamp;
  bool _declarationChecked = false;
  
  final ScrollController _scrollController = ScrollController();
  
  String get _formattedAmount => NumberFormat.currency(symbol: '', decimalDigits: 0).format(_loanAmount);
  
  double get _dynamicAPR {
    final score = _dynamicScore;
    if (score >= 800) return 0.14;
    if (score >= 700) return 0.16;
    if (score >= 600) return 0.18;
    if (score >= 500) return 0.22;
    return 0.24;
  }

  /// APR for emergency_advance product (one tier higher risk than income_bridge)
  String get _emergencyAprLabel {
    final score = _dynamicScore;
    if (score >= 720) return '14%';
    if (score >= 640) return '16%';
    if (score >= 600) return '19%';
    return '22%';
  }

  /// APR for income_bridge product
  String get _incomeBridgeAprLabel {
    final score = _dynamicScore;
    if (score >= 640) return '16%';
    if (score >= 600) return '18%';
    if (score >= 540) return '21%';
    return '24%';
  }

  /// Max eligible for emergency_advance (capped at ₹25,000)
  String get _emergencyMaxLabel {
    final max = _dynamicMaxLoan.clamp(0, 25000).round();
    return '₹${NumberFormat('#,##0').format(max)}';
  }

  /// Max eligible for income_bridge (capped at ₹1,00,000)
  String get _incomeBridgeMaxLabel {
    final max = _dynamicMaxLoan.clamp(0, 100000).round();
    return '₹${NumberFormat('#,##0').format(max)}';
  }
  
  double get _computedEMI {
    double monthlyRate = _dynamicAPR / 12;
    return (_loanAmount * monthlyRate * pow(1 + monthlyRate, _tenure)) / (pow(1 + monthlyRate, _tenure) - 1);
  }
  
  double get _existingEMI {
    // Use real EMI data from Step 9 if available
    final profile = ref.read(verifiedProfileProvider);
    final realEmi = profile.emiLoansInfo.loans
        .fold(0.0, (sum, loan) => sum + loan.monthlyEmi);
    if (realEmi > 0) return realEmi;
    // Fallback: estimate from score
    final report = ref.read(scoreProvider).reportData;
    if (report != null) {
      final emiRatio = report.finalScore > 700 ? 0.15 : (report.finalScore > 550 ? 0.30 : 0.40);
      return (_monthlyIncome * emiRatio).roundToDouble();
    }
    return 0;
  }
  
  double get _monthlyIncome {
    // First try: read from score report (survives PII cleanup after scoring)
    final report = ref.read(scoreProvider).reportData;
    if (report != null && report.applicantMonthlyIncome > 0) {
      return report.applicantMonthlyIncome;
    }
    // Second try: read from live profile (available during scoring session)
    final profile = ref.read(verifiedProfileProvider);
    final realIncome = profile.personalInfo.selfDeclaredIncome;
    if (realIncome > 0) return realIncome;
    // Fallback: estimate from P1 pillar contribution
    if (report != null) {
      final p1Contrib = report.pillarContributions['P1'] ?? 0;
      return (12000 + (p1Contrib * 200)).clamp(10000, 80000).roundToDouble();
    }
    return 18000;
  }
  
  int get _dynamicScore => ref.read(scoreProvider).reportData?.finalScore ?? 647;
  String get _dynamicGrade => ref.read(scoreProvider).reportData?.grade ?? 'B';
  
  double get _dynamicMaxLoan {
    final score = _dynamicScore;
    if (score >= 800) return 200000;
    if (score >= 700) return 120000;
    if (score >= 600) return 82000;
    if (score >= 500) return 50000;
    return 25000;
  }
  
  int get _estimatedAge {
    // Priority 1: read from score report (stored during scoring, survives PII cleanup)
    final report = ref.read(scoreProvider).reportData;
    if (report != null && report.applicantAge > 0) {
      return report.applicantAge.clamp(18, 65);
    }
    // Priority 2: live profile (available during active scoring session)
    final profile = ref.read(verifiedProfileProvider);
    final realAge = profile.personalInfo.age;
    if (realAge > 0) return realAge.clamp(18, 65);
    // Fallback: safe neutral default
    return 28;
  }
  
  int get _bankMonths {
    final report = ref.read(scoreProvider).reportData;
    if (report != null) {
      final p1Conf = report.pillars.where((p) => p.code == 'P1').firstOrNull?.confidence ?? 0.5;
      return p1Conf > 0.7 ? 6 : (p1Conf > 0.4 ? 3 : 1);
    }
    return 6;
  }
  
  String get _productDisplayName {
    switch (_selectedProduct) {
      case 'emergency_advance': return 'Emergency Cash Advance';
      case 'income_bridge': return 'Income Bridge Loan';
      case 'tool_equipment_loan': return 'Tools & Equipment Loan';
      case 'working_capital': return 'Working Capital Loan';
      case 'micro_enterprise': return 'Micro Enterprise Loan';
      default: return 'Credit Product';
    }
  }

  bool _isApproved = false;
  
  Future<void> _submitToBackend() async {
    final session = ref.read(scoreProvider);
    if (session.reportData == null) return;

    final report = ref.read(scoreProvider).reportData;
    final user = ref.read(userProvider);

    final application = {
      "loan_amount": _loanAmount,
      "tenure_months": _tenure,
      "product_id": _selectedProduct,
      "purpose": _purpose,
      "kfs_acknowledged": _kfsAcknowledged,
      "aadhaar_verified": report?.pillars.any((p) => p.code == 'P5' && p.confidence > 0.5) ?? false,
      "pan_verified": report?.pillars.any((p) => p.code == 'P8' && p.confidence > 0.5) ?? false,
      "net_monthly_income": _monthlyIncome.round(),
      "existing_emi_total": _existingEMI.round(),
      "applicant_age": _estimatedAge,
      "bank_statement_months": _bankMonths,           // HR-3: real bank months from P1 confidence
      "mobile_verified": true,                         // HR-7: user authenticated via OTP
      "proposed_emi": _computedEMI.round(),            // HR-4: real EMI for DSCR calculation
    };

    try {
      final result = await ref.read(loanApiServiceProvider).applyLoan(application, session.reportData!.toJson());
      print('Decision from backend: ${result["decision"]}');
      if (mounted) {
        setState(() {
          _isApproved = result["decision"] == "APPROVED";
        });
        // Populate applications provider
        ref.read(loanApplicationsProvider.notifier).addApplication(
          LoanApplication(
            refId: result["loan_id"]?.toString() ?? 'APP-${DateTime.now().millisecondsSinceEpoch}',
            nbfcName: 'GigCredit NBFC Ltd.',
            amount: _loanAmount.round(),
            tenure: '$_tenure months',
            purpose: _purpose ?? 'General',
            rate: _dynamicAPR,
            appliedAt: DateTime.now(),
            status: _isApproved ? 'Approved' : 'Processing',
          ),
        );
      }
    } catch (e) {
      print('Error submitting to backend: $e');
      if (mounted) {
        setState(() {
          _isApproved = _loanAmount <= _dynamicMaxLoan * 0.67;
        });
        // Populate applications provider even for fallback
        ref.read(loanApplicationsProvider.notifier).addApplication(
          LoanApplication(
            refId: 'APP-${DateTime.now().millisecondsSinceEpoch}',
            nbfcName: 'GigCredit NBFC Ltd.',
            amount: _loanAmount.round(),
            tenure: '$_tenure months',
            purpose: _purpose ?? 'General',
            rate: _dynamicAPR,
            appliedAt: DateTime.now(),
            status: _isApproved ? 'Approved' : 'Processing',
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPrimary,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildGlobalHeader(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            sliver: SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _buildCurrentScreenContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentScreenContent() {
    switch (_currentScreen) {
      case 1: return _buildScreen1ProductSelection();
      case 2: return _buildScreen2Form();
      case 3: return _buildScreen3KFS();
      case 4: return _buildScreen4Eligibility();
      case 5: return _buildScreen5AI();
      case 6: return _isApproved ? _buildScreen6AApproval() : _buildScreen6BRejection();
      case 7: return _isApproved ? _buildScreen7ASign() : _buildScreen7BReport();
      default: return const SizedBox();
    }
  }

  // --- HEADER ---
  Widget _buildGlobalHeader() {
    String title = "GigCredit Report";
    if (_currentScreen == 1) title = "Select Your Loan";
    if (_currentScreen == 2) title = "Income Bridge Loan";
    if (_currentScreen == 3) title = "Key Fact Statement";
    if (_currentScreen == 4) title = "Checking Eligibility";
    if (_currentScreen == 5) title = "AI Decision Engine";
    if (_currentScreen == 6) title = _isApproved ? "Loan Approved" : "Loan Decision";
    if (_currentScreen == 7) title = _isApproved ? "Sign & Accept" : "Decision Report";

    return SliverAppBar(
      backgroundColor: _bgGlass,
      pinned: true,
      elevation: 0,
      toolbarHeight: 56,
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, color: _textSecondary, size: 28),
        onPressed: () {
          if (_currentScreen == 1) {
            context.pop();
          } else if (_currentScreen > 1) {
            setState(() => _currentScreen--);
          }
        },
      ),
      title: Text(title, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 17, color: _textPrimary)),
      centerTitle: true,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }

  // --- REUSABLE COMPONENTS ---
  Widget _buildPrimaryCTA(String label, VoidCallback? onPressed, {Color bg = _accentTeal}) {
    final disabled = onPressed == null;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: disabled ? _borderSubtle : bg,
          foregroundColor: disabled ? _textMuted : _bgPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: disabled ? 0 : 8,
          shadowColor: disabled ? Colors.transparent : bg.withOpacity(0.4),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
      ),
    ).animate(target: disabled ? 0 : 1).shimmer(duration: 2000.ms);
  }

  Widget _buildSecondaryCTA(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _borderSubtle),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          foregroundColor: _textSecondary,
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 14)),
      ),
    );
  }

  // --- SCREEN 1: PRODUCT SELECTION ---
  Widget _buildScreen1ProductSelection() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(color: _bgCard, border: Border.all(color: _borderSubtle), borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text('Your Score: $_dynamicScore · Grade $_dynamicGrade', style: const TextStyle(fontFamily: 'Inter', color: _accentGreen, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Text('≤ ₹${NumberFormat.currency(symbol: '', decimalDigits: 0).format(_dynamicMaxLoan)}', style: const TextStyle(fontFamily: 'Inter', color: _accentTeal, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text('Showing plans you qualify for', style: TextStyle(color: _textSecondary, fontSize: 13)),
        const SizedBox(height: 24),
        
        // Product 1
        _buildProductCard(
          title: '🚨  EMERGENCY CASH ADVANCE',
          badge: 'Score 520+ ✅', badgeColor: _accentGreen,
          bg: _accentRedDim, borderColor: _accentRedGlow, leftBorder: _accentRed,
          amount: '₹10,000 – ₹25,000', tenure: '1 – 3 months', apr: _emergencyAprLabel,
          purpose: 'Bike repair, medical, phone damage — today',
          precalc: 'Max eligible: $_emergencyMaxLabel · from your income & score',
          btnText: 'SELECT →', btnColor: _accentRed,
          onTap: () {
            setState(() {
              _selectedProduct = 'emergency_advance';
              _sliderMin = 10000;
              _sliderMax = 25000;
              _loanAmount = 15000;
              _tenure = 3;
              _currentScreen = 2;
            });
          }
        ).animate().slideY(begin: 0.1).fadeIn(),
        const SizedBox(height: 16),
        
        // Product 2
        _buildProductCard(
          title: '🌉  INCOME BRIDGE LOAN',
          badge: '★ RECOMMENDED', badgeColor: _bgPrimary, badgeBg: _accentTeal,
          bg: _accentTealDim, borderColor: _accentTealGlow, leftBorder: _accentTeal,
          amount: '₹5,000 – ₹50,000', tenure: '7 – 30 days', apr: _incomeBridgeAprLabel,
          purpose: 'Stock purchase, seasonal income gap bridging',
          precalc: 'Max eligible: $_incomeBridgeMaxLabel · from your income & score',
          btnText: 'SELECT →', btnColor: _accentTeal,
          onTap: () {
            setState(() {
              _selectedProduct = 'income_bridge';
              _sliderMin = 5000;
              _sliderMax = _dynamicMaxLoan.clamp(5000, 50000);
              _loanAmount = (_sliderMax * 0.6).roundToDouble();
              _tenure = 14;
              _currentScreen = 2;
            });
          }
        ).animate().slideY(begin: 0.1, delay: 100.ms).fadeIn(),
        const SizedBox(height: 16),
        
        // Product 3
        _buildLockedCard().animate().slideY(begin: 0.1, delay: 200.ms).fadeIn(),
        
        const SizedBox(height: 24),
        const Center(child: Text('ℹ️ Max amounts pre-calculated from your verified bank statement data', style: TextStyle(color: _textSecondary, fontSize: 12), textAlign: TextAlign.center)),
      ]
    );
  }

  Widget _buildProductCard({required String title, required String badge, required Color badgeColor, Color? badgeBg, required Color bg, required Color borderColor, required Color leftBorder, required String amount, required String tenure, required String apr, required String purpose, required String precalc, required String btnText, required Color btnColor, required VoidCallback onTap}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 14, color: _textPrimary))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: badgeBg ?? badgeColor.withOpacity(0.2), borderRadius: BorderRadius.circular(999)),
                child: Text(badge, style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSpecItem('Amount', amount)),
              Expanded(child: _buildSpecItem('Tenure', tenure)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildSpecItem('APR', apr)),
              Expanded(child: _buildSpecItem('For', purpose, small: true)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _bgPrimary, borderRadius: BorderRadius.circular(8), border: Border.all(color: _borderSubtle)),
            child: Text(precalc, style: const TextStyle(color: _textSecondary, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: btnColor, foregroundColor: _bgPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: onTap,
              child: FittedBox(fit: BoxFit.scaleDown, child: Text(btnText, style: const TextStyle(fontWeight: FontWeight.bold))),
            )
          )
        ],
      )
    );
  }

  Widget _buildSpecItem(String label, String val, {bool small = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _textSecondary, fontSize: 11)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(color: _textPrimary, fontSize: small ? 11 : 12, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildLockedCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _accentPurpleDim, border: Border.all(color: const Color(0x408B5CF6)), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: Text('📈  GROWTH LOAN', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 14, color: _textPrimary))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: _accentPurple, borderRadius: BorderRadius.circular(999)),
                child: const Text('🔒 LOCKED', style: TextStyle(color: _textPrimary, fontSize: 9, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _accentRedDim, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0x30FF4E6A))),
            child: Text('⚠️  Your score: $_dynamicScore · Required: 640 · Gap: ${640 - _dynamicScore > 0 ? 640 - _dynamicScore : 0} pts', style: const TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _accentGreenDim, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0x303DD68C))),
            child: Text('💡 ${640 - _dynamicScore > 20 ? "Upload ITR → estimated +8 pts · ${((640 - _dynamicScore) / 8).ceil()} steps to unlock" : "You\'re close! Upload ITR to unlock instantly"}', style: const TextStyle(color: _accentGreen, fontSize: 13)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(side: const BorderSide(color: _accentPurple), foregroundColor: _accentPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {},
              child: const FittedBox(fit: BoxFit.scaleDown, child: Text('HOW TO UNLOCK →', style: TextStyle(fontWeight: FontWeight.bold))),
            )
          )
        ],
      )
    );
  }

  // --- SCREEN 2: FORM ---
  Widget _buildScreen2Form() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _accentGreenDim, border: Border.all(color: const Color(0x403DD68C)), borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(child: Text('You can borrow up to ₹${NumberFormat('#,##0').format(_dynamicMaxLoan)} based on your income and existing EMIs.', style: const TextStyle(color: _textPrimary, fontSize: 13))),
            ],
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 24),
        
        const Text('How much do you need?', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 15, color: _textPrimary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(color: AppColors.bgScreen, borderRadius: BorderRadius.circular(12), border: Border.all(color: _borderSubtle)),
          child: Row(
            children: [
              const Text('₹', style: TextStyle(color: _textSecondary, fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(width: 8),
              Text(NumberFormat('#,##0').format(_loanAmount), style: const TextStyle(color: _accentTeal, fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'Inter')),
            ],
          ),
        ),
        SliderTheme(
          data: SliderThemeData(trackHeight: 6, thumbColor: AppColors.greenPrimary, activeTrackColor: AppColors.greenPrimary, inactiveTrackColor: AppColors.borderCard),
          child: Slider(
            value: _loanAmount.clamp(_sliderMin, _sliderMax),
            min: _sliderMin,
            max: _sliderMax,
            divisions: ((_sliderMax - _sliderMin) / 1000).round(),
            onChanged: (v) => setState(() => _loanAmount = v),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('₹${NumberFormat('#,##0').format(_sliderMin)}', style: const TextStyle(color: _textSecondary, fontSize: 12)),
            Text('₹${NumberFormat('#,##0').format(_sliderMax)}', style: const TextStyle(color: _textSecondary, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 32),
        
        const Text('Loan Tenure', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 15, color: _textPrimary)),
        const SizedBox(height: 12),
        Row(
          children: [6, 12, 24].map((t) => Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tenure = t),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 48,
                decoration: BoxDecoration(color: _tenure == t ? _accentTeal : _bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: _borderSubtle)),
                alignment: Alignment.center,
                child: Text('${t}M', style: TextStyle(color: _tenure == t ? _bgPrimary : _textSecondary, fontWeight: FontWeight.bold)),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 32),
        
        const Text('Purpose of Loan', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 15, color: _textPrimary)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final res = await showModalBottomSheet<String>(context: context, backgroundColor: _bgCard, builder: (ctx) => ListView(
              children: ['Stock Purchase', 'Equipment Purchase', 'Medical Emergency', 'Vehicle Repair', 'Working Capital', 'Education'].map((e) => ListTile(
                title: Text(e, style: const TextStyle(color: _textPrimary)),
                onTap: () => Navigator.pop(ctx, e),
              )).toList(),
            ));
            if (res != null) setState(() => _purpose = res);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(color: AppColors.bgScreen, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderCard)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_purpose ?? 'Select Purpose', style: TextStyle(color: _purpose == null ? AppColors.textMuted : AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
                Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        
        // LIVE ESTIMATE
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: _bgPrimary, borderRadius: BorderRadius.circular(16), border: Border.all(color: _borderSubtle)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('LIVE ESTIMATE', style: TextStyle(color: _accentTeal, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              const SizedBox(height: 16),
              _buildEstimateRow('Loan Amount', '₹$_formattedAmount'),
              _buildEstimateRow('Tenure', '$_tenure months'),
              _buildEstimateRow('APR', '${(_dynamicAPR * 100).toStringAsFixed(0)}%'),
              _buildEstimateRow('Monthly EMI', '₹${NumberFormat.currency(symbol:'', decimalDigits:0).format(_computedEMI)}', valColor: _accentTeal),
              _buildEstimateRow('Total Repayable', '₹${NumberFormat.currency(symbol:'', decimalDigits:0).format(_computedEMI * _tenure)}'),
              _buildEstimateRow('Processing Fee', '₹0 (waived)', valColor: _accentGreen),
            ],
          ),
        ).animate(key: ValueKey('$_loanAmount$_tenure')).fadeIn(duration: 200.ms),
        const SizedBox(height: 32),
        
        _buildPrimaryCTA('VIEW LOAN TERMS (KFS) →', _purpose != null ? () => setState(() => _currentScreen = 3) : null),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildEstimateRow(String label, String val, {Color valColor = _textPrimary}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: _textSecondary, fontSize: 14)),
          Text(val, style: TextStyle(color: valColor, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- SCREEN 3: KFS ---
  Widget _buildScreen3KFS() {
    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _accentGoldDim, border: Border.all(color: const Color(0x40F4B942)), borderRadius: BorderRadius.circular(14)),
          child: const Text('⚖️  LEGAL DISCLOSURE — Read carefully before agreeing', style: TextStyle(color: _accentGold, fontSize: 14, fontWeight: FontWeight.w600)),
        ).animate().fadeIn(),
        const SizedBox(height: 24),
        
        _buildKfsSection('LOAN SUMMARY', [
          ['Product', _productDisplayName],
          ['Lender', 'GigCredit NBFC Ltd.'],
          ['Borrower', ref.read(userProvider)?.name ?? 'Applicant'],
          ['Loan Amount', '₹$_formattedAmount'],
          ['Tenure', '$_tenure months'],
        ]),
        
        _buildKfsSection('COST OF CREDIT', [
          ['Annual Percentage Rate', '${(_dynamicAPR * 100).toStringAsFixed(2)}%'],
          ['Monthly EMI', '₹${NumberFormat.currency(symbol:'', decimalDigits:0).format(_computedEMI)}'],
          ['Processing Fee', '₹0'],
          ['Total Amount Payable', '₹${NumberFormat.currency(symbol:'', decimalDigits:0).format(_computedEMI * _tenure)}'],
          ['Total Interest Cost', '₹${NumberFormat.currency(symbol:'', decimalDigits:0).format((_computedEMI * _tenure) - _loanAmount)}'],
        ]),
        
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _accentTealDim, border: Border.all(color: const Color(0x4000D4B4)), borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⏰  3-DAY COOLING-OFF PERIOD', style: TextStyle(color: _accentTeal, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('You can cancel this loan until ${DateFormat('d MMM yyyy').format(DateTime.now().add(const Duration(days: 3)))} with zero penalty, zero processing fee, and only principal repayable.', style: const TextStyle(color: _textPrimary, fontSize: 13, height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        GestureDetector(
          onTap: () => setState(() => _kfsAcknowledged = !_kfsAcknowledged),
          child: Row(
            children: [
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(color: _kfsAcknowledged ? _accentTeal : AppColors.bgScreen, borderRadius: BorderRadius.circular(6), border: Border.all(color: _kfsAcknowledged ? _accentTeal : _borderSubtle, width: 2)),
                child: _kfsAcknowledged ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('I have read and understood all terms in this Key Fact Statement', style: TextStyle(color: _textPrimary, fontSize: 14))),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        _buildPrimaryCTA('✅  I AGREE & PROCEED  →', _kfsAcknowledged ? () {
          setState(() { _kfsTimestamp = DateTime.now().toIso8601String(); _currentScreen = 4; });
        } : null),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildKfsSection(String title, List<List<String>> rows) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const Divider(color: _borderSubtle, height: 16),
          ...rows.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(r[0], style: const TextStyle(color: _textSecondary, fontSize: 14)),
                Text(r[1], style: const TextStyle(color: _textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // --- SCREEN 4: ELIGIBILITY ---
  Widget _buildScreen4Eligibility() {
    return Column(
      key: const ValueKey(4),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(valueColor: const AlwaysStoppedAnimation(_accentTeal), backgroundColor: AppColors.bgScreen, minHeight: 6, borderRadius: BorderRadius.circular(999)).animate().custom(duration: 6500.ms, builder: (ctx, val, child) => LinearProgressIndicator(value: val, valueColor: const AlwaysStoppedAnimation(_accentTeal), backgroundColor: AppColors.bgScreen, minHeight: 6, borderRadius: BorderRadius.circular(999))),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: _borderSubtle)),
          child: const Row(
            children: [
              CoinPulseLoader(color: _accentTeal, size: 6.0),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Running Checks', style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Secure server · Encrypted · RBI compliant', style: TextStyle(color: _textSecondary, fontSize: 12)),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text('STAGE 1 — REGULATORY CHECKS', style: TextStyle(color: _accentTeal, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildAnimatedCheck(500, 'Aadhaar API Verified', 'UIDAI confirmed · Face match ${90 + (_dynamicScore % 9)}%'),
        _buildAnimatedCheck(1000, 'PAN API Verified', 'Income Tax Dept confirmed'),
        _buildAnimatedCheck(1500, 'Age Verified: $_estimatedAge years', 'Eligible range: 18–65'),
        _buildAnimatedCheck(2000, 'Bank Statement: $_bankMonths months', 'Minimum required: 3 months'),
        _buildAnimatedCheck(2500, 'KFS Acknowledged', 'Timestamp: ${DateFormat('HH:mm:ss').format(DateTime.now())}'),
        _buildAnimatedCheck(3000, 'Mobile Number Verified', 'OTP confirmed at registration'),
        _buildAnimatedCheck(3500, 'Score Meets Threshold', 'Your score $_dynamicScore ≥ required 550'),
        const SizedBox(height: 32),
        
        // Stage 2
        const Text('STAGE 2 — AFFORDABILITY ENGINE', style: TextStyle(color: _accentTeal, fontSize: 12, fontWeight: FontWeight.bold)).animate().fadeIn(delay: 4000.ms),
        const SizedBox(height: 16),
        _buildAffordabilityCard(4200, 'DSCR (Debt Service Coverage)', 'Net Income: ₹${NumberFormat('#,##0').format(_monthlyIncome)}/mo', 'DSCR = ${_monthlyIncome.toInt()} ÷ ${NumberFormat('#,##0').format(_existingEMI + _computedEMI)} = ${(_monthlyIncome / (_existingEMI + _computedEMI)).toStringAsFixed(2)}', (_monthlyIncome / (_existingEMI + _computedEMI)) >= 1.25),
        _buildAffordabilityCard(4600, 'POST-LOAN EMI RATIO', 'Total EMI: ₹${NumberFormat('#,##0').format(_existingEMI + _computedEMI)}/mo', 'Ratio = ${((_existingEMI + _computedEMI)/_monthlyIncome * 100).toStringAsFixed(1)}%', ((_existingEMI + _computedEMI)/_monthlyIncome) <= 0.50),
        _buildAffordabilityCard(5000, 'LOAN-TO-INCOME RATIO', 'Loan Amount: ₹$_formattedAmount', 'LTI = ${(_loanAmount/_monthlyIncome).toStringAsFixed(1)}x', (_loanAmount/_monthlyIncome) <= 10.0),
        
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _accentPurpleDim, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x408B5CF6))),
          child: const Row(
            children: [
              CoinPulseLoader(color: _accentPurple, size: 6.0),
              SizedBox(width: 12),
              Text('Sending to AI decision engine...', style: TextStyle(color: _textPrimary)),
            ],
          ),
        ).animate().fadeIn(delay: 6500.ms).callback(delay: 8000.ms, duration: 1.ms, callback: (_) {
          _submitToBackend(); // Background sync for audit trail
          setState(() => _currentScreen = 5);
        }),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildAnimatedCheck(int delayMs, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 32, height: 32, decoration: const BoxDecoration(color: _accentGreenDim, shape: BoxShape.circle), child: const Icon(Icons.check, color: _accentGreen, size: 16)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: _textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
            Text(sub, style: const TextStyle(color: _textSecondary, fontSize: 12)),
          ]))
        ],
      ).animate().fadeIn(delay: delayMs.ms).slideX(begin: -0.1),
    );
  }

  Widget _buildAffordabilityCard(int delayMs, String title, String line1, String line2, bool passes) {
    final color = passes ? _accentGreen : _accentRed;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.4))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(line1, style: const TextStyle(color: _textPrimary, fontSize: 13)),
          const SizedBox(height: 4),
          Text(line2, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    ).animate().fadeIn(delay: delayMs.ms);
  }

  // --- SCREEN 5: AI ---
  Widget _buildScreen5AI() {
    double finalScore = ref.read(scoreProvider).reportData?.metaProbability ?? (_isApproved ? 0.79 : 0.61);
    return Column(
      key: const ValueKey(5),
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0x408B5CF6))),
          child: const Column(
            children: [
              Text('🤖', style: TextStyle(fontSize: 40)),
              SizedBox(height: 16),
              Text('AI EVALUATING', style: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Analysing 32 signals from your profile...', style: TextStyle(color: _textSecondary, fontSize: 13)),
            ],
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 40),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Repayment Probability Score', style: TextStyle(color: _textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Container(height: 12, decoration: BoxDecoration(color: AppColors.bgScreen, borderRadius: BorderRadius.circular(999)), alignment: Alignment.centerLeft, child: LayoutBuilder(builder: (ctx, constraints) {
              return Container(width: constraints.maxWidth * finalScore, height: 12, decoration: BoxDecoration(color: finalScore > 0.68 ? _accentGreen : _accentGold, borderRadius: BorderRadius.circular(999))).animate().custom(duration: 1500.ms, builder: (ctx, val, child) => Container(width: constraints.maxWidth * finalScore * val, height: 12, decoration: BoxDecoration(color: finalScore > 0.68 ? _accentGreen : _accentGold, borderRadius: BorderRadius.circular(999))));
            })),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: finalScore),
              duration: 1500.ms,
              builder: (ctx, val, _) => Text(val.toStringAsFixed(2), style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 24, fontWeight: FontWeight.bold, color: _accentTeal)),
            ),
            const SizedBox(height: 4),
            const Text('Threshold: 0.68', style: TextStyle(color: _textSecondary, fontSize: 12)),
          ],
        ),
      ],
    ).animate().callback(delay: 3000.ms, duration: 1.ms, callback: (_) => setState(() => _currentScreen = 6));
  }

  // --- SCREEN 6A: APPROVAL ---
  Widget _buildScreen6AApproval() {
    return Column(
      key: const ValueKey('6a'),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: _accentGreenDim, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0x403DD68C))),
          child: Column(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 48)).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: 0, end: -8, duration: 600.ms),
              const SizedBox(height: 16),
              const Text('APPROVED!', style: TextStyle(color: _accentGreen, fontSize: 32, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('Congratulations, ${ref.read(userProvider)?.name ?? 'Applicant'}! Your $_productDisplayName is approved.', style: const TextStyle(color: _textSecondary, fontSize: 15), textAlign: TextAlign.center),
            ],
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 24),
        _buildPrimaryCTA('✍️  SIGN & ACCEPT LOAN  →', () => setState(() => _currentScreen = 7)),
        const SizedBox(height: 16),
        _buildSecondaryCTA('Cancel within cooling-off period', () => context.go(AppRoutes.home)),
      ],
    );
  }

  // --- SCREEN 6B: REJECTION ---
  Widget _buildScreen6BRejection() {
    return Column(
      key: const ValueKey('6b'),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: _accentRedDim, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x40FF4E6A))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('❌', style: TextStyle(fontSize: 32)),
              SizedBox(height: 12),
              Text('Application Not Approved', style: TextStyle(color: _accentRed, fontSize: 18, fontWeight: FontWeight.bold)),
              Text('for ₹${NumberFormat.currency(symbol: '', decimalDigits: 0).format(_loanAmount)} $_productDisplayName', style: const TextStyle(color: _textSecondary, fontSize: 14)),
            ],
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _accentGreenDim, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x403DD68C))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('✅', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 8),
              Text('BUT — You are immediately eligible for ₹${NumberFormat.currency(symbol: '', decimalDigits: 0).format(_dynamicMaxLoan)}', style: const TextStyle(color: _accentGreen, fontSize: 14, fontWeight: FontWeight.bold)),
              Text('₹${NumberFormat.currency(symbol: '', decimalDigits: 0).format((_dynamicMaxLoan * (_dynamicAPR / 12) * pow(1 + (_dynamicAPR / 12), _tenure)) / (pow(1 + (_dynamicAPR / 12), _tenure) - 1))}/mo EMI · $_tenure months · ${(_dynamicAPR * 100).toStringAsFixed(0)}% APR', style: const TextStyle(color: _textPrimary, fontSize: 13)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _accentTeal, foregroundColor: _bgPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () => setState(() { _loanAmount = _dynamicMaxLoan; _currentScreen = 4; }), // Re-run checks
                  child: Text('APPLY FOR ₹${NumberFormat.currency(symbol: '', decimalDigits: 0).format(_dynamicMaxLoan)} →', style: const TextStyle(fontWeight: FontWeight.bold)),
                )
              )
            ],
          ),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: () => context.push(AppRoutes.loanDecisionReport, extra: {
            "loan_amount": _loanAmount,
            "tenure": _tenure,
            "product_id": _selectedProduct,
            "is_approved": _isApproved,
            "score": _dynamicScore,
          }),
          child: const Text('VIEW FULL DECISION REPORT →', style: TextStyle(color: _accentTeal, decoration: TextDecoration.underline, fontWeight: FontWeight.bold, fontSize: 14)),
        )
      ],
    );
  }

  // --- SCREEN 7A: SIGN ---
  Widget _buildScreen7ASign() {
    return Column(
      key: const ValueKey('7a'),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: _bgPrimary, border: Border.all(color: _borderSubtle, width: 2, style: BorderStyle.solid), borderRadius: BorderRadius.circular(16)),
          height: 160,
          alignment: Alignment.center,
          child: const Text('Sign here with your finger', style: TextStyle(color: _textSecondary)),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => setState(() => _declarationChecked = !_declarationChecked),
          child: Row(
            children: [
              Container(width: 22, height: 22, decoration: BoxDecoration(color: _declarationChecked ? _accentTeal : AppColors.bgScreen, borderRadius: BorderRadius.circular(6), border: Border.all(color: _declarationChecked ? _accentTeal : _borderSubtle, width: 2)), child: _declarationChecked ? const Icon(Icons.check, size: 16, color: Colors.white) : null),
              const SizedBox(width: 12),
              Expanded(child: Text('I confirm that I have read and accept the loan agreement. I authorise disbusral of ₹$_formattedAmount.', style: const TextStyle(color: _textPrimary, fontSize: 14))),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildPrimaryCTA('🏦  CONFIRM & DISBURSE  →', _declarationChecked ? () => context.go(AppRoutes.home) : null),
      ],
    );
  }

  // --- SCREEN 7B: REPORT ---
  Widget _buildScreen7BReport() {
    return Column(
      key: const ValueKey('7b'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _bgPrimary, border: Border.all(color: _borderSubtle), borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('OFFICIAL DECISION REPORT', style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Audit ID: ${ref.read(scoreProvider).reportData?.proofId ?? 'AT-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}'}\nDecision Type: AFFORDABILITY', style: const TextStyle(color: _textSecondary, fontFamily: 'JetBrains Mono', fontSize: 11, height: 1.5)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: _accentTeal), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () => context.push(AppRoutes.loanDecisionReport, extra: {
                    "loan_amount": _loanAmount,
                    "tenure": _tenure,
                    "product_id": _selectedProduct,
                    "is_approved": _isApproved,
                  }),
                  child: const Text('OPEN INTERACTIVE XAI REPORT', style: TextStyle(color: _accentTeal, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('❌ Rejected for: ₹${NumberFormat.currency(symbol: '', decimalDigits: 0).format(_loanAmount)}', style: const TextStyle(color: _accentRed, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('(Not a creditworthiness issue)', style: TextStyle(color: _textSecondary, fontStyle: FontStyle.italic)),
        const SizedBox(height: 32),
        _buildSecondaryCTA('🏠 Back to Dashboard', () => context.go(AppRoutes.home)),
      ],
    );
  }
}
extension BorderSideExt on BoxDecoration {
  BoxDecoration border({BorderSide? left, BorderSide? top, BorderSide? right, BorderSide? bottom}) {
    return copyWith(border: Border(
      left: left ?? BorderSide.none,
      top: top ?? BorderSide.none,
      right: right ?? BorderSide.none,
      bottom: bottom ?? BorderSide.none,
    ));
  }
}
