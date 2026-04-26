import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../shared/widgets/buttons/secondary_button.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../app/app_router.dart';
import '../../../state/score_provider.dart';
import '../../../state/loan_applications_provider.dart';

class LoanApplicationScreen extends ConsumerStatefulWidget {
  const LoanApplicationScreen({super.key});

  @override
  ConsumerState<LoanApplicationScreen> createState() => _LoanApplicationScreenState();
}

class _LoanApplicationScreenState extends ConsumerState<LoanApplicationScreen> {
  int _currentStep = 0; // 0=Form, 1=Matching Anim, 2=NBFC Results, 3=Success
  int _selectedNbfc = -1;

  double _loanAmount = 50000;
  String _tenure = '6 Mo';
  String _purpose = 'Working Capital';
  bool _isProcessingMandate = false;

  final List<String> _tenures = ['3 Mo', '6 Mo', '12 Mo', '24+ Mo'];
  final List<String> _purposes = ['Working Capital', 'Vehicle Repair', 'Medical Emergency', 'Equipment Purchase'];

  List<Map<String, dynamic>> _getNbfcOptions(int score) {
    // Show 3-5 options regardless of score as per prompt rules.
    return [
      {'name': 'KreditBee', 'approval': 92, 'rate': 14.5, 'tenure': 'Flexible', 'positives': ['Fast approval', 'No collateral'], 'negatives': ['Higher rate', 'Processing fee'], 'logo': Icons.electric_bolt, 'isBest': true},
      {'name': 'MoneyTap', 'approval': 88, 'rate': 13.0, 'tenure': '3-24 months', 'positives': ['Line of credit', 'Pay-as-you-use'], 'negatives': ['Processing fee', 'Auto-debit required'], 'logo': Icons.touch_app, 'isBest': false},
      {'name': 'CASHe', 'approval': 85, 'rate': 15.0, 'tenure': '6-18 months', 'positives': ['Higher limits', 'Flexible'], 'negatives': ['Longer processing'], 'logo': Icons.account_balance, 'isBest': false},
      {'name': 'Navi Finance', 'approval': 72, 'rate': 11.0, 'tenure': '6-36 months', 'positives': ['Highest limit', 'Lowest rate'], 'negatives': ['Strict KYC'], 'logo': Icons.navigation, 'isBest': false},
    ];
  }

  void _discoverLenders() {
    setState(() => _currentStep = 1);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _currentStep = 2);
    });
  }

  void _triggerApplyFlow(int index) {
    setState(() => _selectedNbfc = index);
    _showSmartConsentSheet();
  }

  void _showSmartConsentSheet() {
    final nbfc = _getNbfcOptions(750)[_selectedNbfc];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.security, color: AppColors.accent, size: 28),
                const SizedBox(width: 12),
                const Text('Data Consent & Privacy', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'To proceed with your application to ${nbfc['name']}, GigCredit requires your authorization to securely share your Verified Certificate and KYC data.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.cardElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.surfaceVariant)),
              child: const Row(
                children: [
                  Icon(Icons.verified_user, color: AppColors.verified, size: 20),
                  SizedBox(width: 12),
                  Expanded(child: Text('RBI Account Aggregator Framework Compliant. Your data is fully encrypted.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: SecondaryButton(label: 'Cancel', onPressed: () => Navigator.pop(context))),
                const SizedBox(width: 16),
                Expanded(child: PrimaryButton(label: 'I Authorize', onPressed: () {
                  Navigator.pop(context);
                  _showEMandateSheet();
                })),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showEMandateSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(Icons.autorenew, color: Colors.blueAccent, size: 28),
                    const SizedBox(width: 12),
                    const Text('Setup Auto-Pay (e-NACH)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'NBFC partners require an active auto-debit mandate to guarantee your low 14.5% interest rate. Please authorize auto-pay on your primary account.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.cardElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3))),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.account_balance, color: Colors.indigo, size: 20)),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('HDFC Bank', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            Text('A/C ending in 4592', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle, color: AppColors.verified),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: _isProcessingMandate ? 'Authenticating via UPI...' : 'Authorize via UPI',
                  isLoading: _isProcessingMandate,
                  onPressed: () {
                    setSheetState(() => _isProcessingMandate = true);
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) {
                        Navigator.pop(context);
                        // Write to tracking provider
                        final nbfc = _getNbfcOptions(750)[_selectedNbfc];
                        ref.read(loanApplicationsProvider.notifier).addApplication(
                          LoanApplication(
                            refId: 'APP-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                            nbfcName: nbfc['name'] as String,
                            amount: _loanAmount.toInt(),
                            tenure: _tenure,
                            purpose: _purpose,
                            rate: nbfc['rate'] as double,
                            appliedAt: DateTime.now(),
                            status: 'Processing',
                          ),
                        );
                        setState(() {
                          _isProcessingMandate = false;
                          _currentStep = 3;
                        });
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('GigCredit Loan Apply'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0 && _currentStep < 3
            ? IconButton(
                icon: const Icon(Icons.arrow_back), 
                onPressed: () {
                  if (_currentStep == 1) return;
                  if (_currentStep == 2) setState(() => _currentStep = 0);
                }
              )
            : IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _buildStep(),
      ),
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0: return _buildDiscoveryForm();
      case 1: return _buildMatchingAnimation();
      case 2: return _buildNbfcResults();
      case 3: return _buildSuccessScreen();
      default: return const SizedBox();
    }
  }

  Widget _buildDiscoveryForm() {
    final report = ref.watch(scoreProvider).reportData;
    final score = report?.finalScore ?? 750;
    final risk = report?.riskBand ?? 'Low Risk';
    
    return SingleChildScrollView(
      key: const ValueKey('step0'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Certificate Hero Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accent.withValues(alpha: 0.8), AppColors.accent.withValues(alpha: 0.3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
              boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: -5)],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.verified, color: Colors.white, size: 28),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                      child: const Text('CERTIFICATE GC-1234', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Praveen Kumar', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Score: $score', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 12),
                    Text('•', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                    const SizedBox(width: 12),
                    Text(risk, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1),

          const SizedBox(height: 32),
          const Text('Loan Requirements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 24),

          // 2. Frictionless Form
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Loan Amount', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  Text('₹${_loanAmount.toInt()}', style: const TextStyle(color: AppColors.accent, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderThemeData(activeTrackColor: AppColors.accent, inactiveTrackColor: AppColors.surfaceVariant, thumbColor: Colors.white),
                child: Slider(
                  value: _loanAmount,
                  min: 5000,
                  max: 200000,
                  divisions: 39,
                  onChanged: (val) => setState(() => _loanAmount = val),
                ),
              ),
              
              const SizedBox(height: 24),
              const Text('Repayment Tenure', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 12),
              Row(
                children: _tenures.map((t) => Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tenure = t),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _tenure == t ? AppColors.accent : AppColors.cardElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _tenure == t ? AppColors.accent : AppColors.surfaceVariant),
                      ),
                      child: Center(child: Text(t, style: TextStyle(color: _tenure == t ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13))),
                    ),
                  ),
                )).toList(),
              ),

              const SizedBox(height: 24),
              const Text('Loan Purpose', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: AppColors.cardElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.surfaceVariant)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _purpose,
                    dropdownColor: AppColors.cardElevated,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.accent),
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    items: _purposes.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (v) => setState(() => _purpose = v ?? _purpose),
                  ),
                ),
              ),

              const SizedBox(height: 40),
              PrimaryButton(label: 'Discover Lenders', icon: const Icon(Icons.search, color: Colors.white, size: 20), onPressed: _discoverLenders)
                .animate().fadeIn(delay: 400.ms).scale(),
            ],
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildMatchingAnimation() {
    return Center(
      key: const ValueKey('step1'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accent.withValues(alpha: 0.1), border: Border.all(color: AppColors.accent.withValues(alpha: 0.3), width: 2)),
            child: const Center(child: SizedBox(width: 60, height: 60, child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 4))),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 1.seconds),
          const SizedBox(height: 32),
          const Text('Searching NBFC Network...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))
            .animate().fadeIn(duration: 500.ms)
            .swap(builder: (_, __) => const Text('Applying Risk Profile...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)), delay: 1000.ms),
        ],
      ),
    );
  }

  Widget _buildNbfcResults() {
    final report = ref.watch(scoreProvider).reportData;
    final options = _getNbfcOptions(report?.finalScore ?? 750);
    
    return SingleChildScrollView(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Matching Lenders', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)).animate().fadeIn(),
          const SizedBox(height: 4),
          Text('${options.length} NBFCs found for your ₹${_loanAmount.toInt()} request.', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 24),
          
          ...List.generate(options.length, (i) {
            final n = options[i];
            final isBest = n['isBest'] as bool;
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isBest ? AppColors.accent : AppColors.surfaceVariant, width: isBest ? 2 : 1),
                boxShadow: isBest ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.15), blurRadius: 20, spreadRadius: 2)] : [],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (isBest) Positioned(
                    top: -12, right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.5), blurRadius: 8)]),
                      child: const Row(children: [Icon(Icons.star, color: Colors.white, size: 12), SizedBox(width: 4), Text('Best Match', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(n['logo'] as IconData, color: AppColors.accent, size: 24)),
                            const SizedBox(width: 12),
                            Expanded(child: Text(n['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white))),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _buildNbfcMetric('Approval', '${n['approval']}%', Colors.green),
                            _buildNbfcMetric('Rate', '${n['rate']}%', AppColors.accent),
                            _buildNbfcMetric('Tenure', n['tenure'] as String, AppColors.textSecondary),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.cardElevated, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildBulletList('✅ Positives', n['positives'] as List, Colors.green)),
                              Expanded(child: _buildBulletList('❌ Negatives', n['negatives'] as List, Colors.orange)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _triggerApplyFlow(i),
                            style: ElevatedButton.styleFrom(backgroundColor: isBest ? AppColors.accent : AppColors.surfaceVariant, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: const Text('Apply Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (200 + i * 150).ms).slideY(begin: 0.1);
          }),
        ],
      ),
    );
  }

  Widget _buildNbfcMetric(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: valueColor, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBulletList(String title, List items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ...items.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(margin: const EdgeInsets.only(top: 5, right: 6), width: 4, height: 4, decoration: BoxDecoration(color: color.withValues(alpha: 0.6), shape: BoxShape.circle)),
              Expanded(child: Text(p, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11))),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildSuccessScreen() {
    final nbfc = _getNbfcOptions(750)[_selectedNbfc];
    final refNo = 'APP-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    
    return Center(
      key: const ValueKey('step3'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.green, Color(0xFF00C853)]), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 5)]),
              child: const Icon(Icons.check, color: Colors.white, size: 50),
            ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
            const SizedBox(height: 28),
            const Text('Loan Applied!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            Text('Your verified GigCredit profile has been successfully submitted to ${nbfc['name']}.', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5), textAlign: TextAlign.center).animate().fadeIn(delay: 300.ms),
            
            const SizedBox(height: 32),
            
            // Gamification Badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.amber.withValues(alpha: 0.2), AppColors.surface]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium, color: Colors.amber, size: 36),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Milestone Unlocked: Credit Initiator!', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 4),
                        Text('Repay this loan on time to boost your score by up to 45 points.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

            const SizedBox(height: 24),
            
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _confirmRow('Application Ref', refNo, isHighlight: true),
                  const Divider(height: 24, color: AppColors.surfaceVariant),
                  _confirmRow('Lender', nbfc['name'] as String),
                  _confirmRow('Requested Amount', '₹${_loanAmount.toInt()}'),
                  _confirmRow('Tenure', _tenure),
                  _confirmRow('Interest Rate', '${nbfc['rate']}% p.a.'),
                ],
              ),
            ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1),
            
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.accent.withValues(alpha: 0.3))),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: AppColors.accent, size: 24),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Next steps: ${nbfc['name']} will process your mandate and disburse funds within 24 hours.', style: const TextStyle(fontSize: 12, color: AppColors.accent, height: 1.5))),
                ],
              ),
            ).animate().fadeIn(delay: 900.ms),
            
            const SizedBox(height: 40),
            PrimaryButton(label: 'Return to Dashboard', onPressed: () => context.go(AppRoutes.home)).animate().fadeIn(delay: 1100.ms),
          ],
        ),
      ),
    );
  }

  Widget _confirmRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Flexible(
            child: Text(
              value, 
              style: TextStyle(fontSize: isHighlight ? 15 : 13, fontWeight: FontWeight.bold, color: isHighlight ? AppColors.accent : Colors.white), 
              textAlign: TextAlign.right
            )
          ),
        ],
      ),
    );
  }
}
