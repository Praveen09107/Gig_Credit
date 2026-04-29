import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../state/verified_profile_provider.dart';
import '../../../state/score_provider.dart';
import '../../../state/loan_provider.dart';
import '../../../models/loan_offer_model.dart';
import '../../../scoring/score_pipeline.dart';
import '../../../app/app_router.dart';
import '../../../models/score_report_model.dart';
import '../../../state/api_service_provider.dart';
import '../widgets/score_status_message.dart';

/// P6-11: Score Generating Screen
/// Pulsing gradient ring + cycling messages + computes real score in background.
/// WillPopScope blocks back navigation.
class ScoreGeneratingScreen extends ConsumerStatefulWidget {
  const ScoreGeneratingScreen({super.key});

  @override
  ConsumerState<ScoreGeneratingScreen> createState() => _ScoreGeneratingScreenState();
}

class _ScoreGeneratingScreenState extends ConsumerState<ScoreGeneratingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    // Run scoring pipeline after a brief render delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runPipeline();
    });
  }

  Future<void> _runPipeline() async {
    // Minimum screen display time for UX: 6×2.5s = 15s messages OR pipeline completes
    final profile = ref.read(verifiedProfileProvider);
    
    // Allow UI to breathe before heavy computation
    await Future.delayed(const Duration(seconds: 2));

    // 1. Run local scoring & SHAP pipeline
    var report = ScorePipeline.run(profile);

    // Wait for realistic AI processing feel
    await Future.delayed(const Duration(seconds: 4));

    try {
      // 2. Prepare payload for LLM explanation (passing SHAP outputs)
      final payload = {
        "credit_score": report.finalScore,
        "grade": report.grade,
        "risk_level": report.riskBand,
        "work_type": profile.personalInfo.workType.isNotEmpty ? profile.personalInfo.workType : 'platform_worker',
        "language": "English",
        "positive_factors": report.topStrengths.map((e) => {"feature_label": e.featureName, "impact": e.impactStrength}).toList(),
        "negative_factors": report.topConcerns.map((e) => {"feature_label": e.featureName, "impact": e.impactStrength}).toList(),
      };

      // 3. Request LLM generated explanation via the live backend
      final api = ref.read(apiServiceProvider);
      final llmResponse = await api.generateReportScore(payload);

      if (llmResponse['status'] == 'success' || llmResponse['status'] == 'fallback') {
        // Merge the backend LLM response with our local score report
        report = ScoreReportModel(
          finalScore: report.finalScore,
          grade: report.grade,
          riskBand: report.riskBand,
          proofId: report.proofId,
          generatedAt: report.generatedAt,
          overallConfidence: report.overallConfidence,
          pillars: report.pillars,
          topStrengths: report.topStrengths,
          topConcerns: report.topConcerns,
          llmExplanation: llmResponse['explanation'],
          tailoredSuggestions: List<String>.from(llmResponse['suggestions'] ?? []),
        );
      }
    } catch (e) {
      print('LLM API Error: $e');
      // If network fails, we just use the on-device fallback suggestions
    }

    if (!mounted) return;

    // 4. Delete sensitive PII data post-evaluation for privacy
    ref.read(verifiedProfileProvider.notifier).reset();

    // Store result in provider
    ref.read(scoreProvider.notifier).setSuccess(report);

    // Seed personalized loan offers based on the generated score
    _seedLoanOffers(report.finalScore);

    // Haptic celebration
    HapticFeedback.heavyImpact();

    // Navigate to report screen
    context.go(AppRoutes.scoreReport);
  }

  void _seedLoanOffers(int score) {
    final offers = <LoanOfferModel>[];
    
    if (score >= 600) {
      offers.add(LoanOfferModel(
        id: 'offer_1',
        lenderName: 'HDFC Bank',
        lenderLogoUrl: '',
        amount: score >= 720 ? 75000 : 50000,
        interestRate: score >= 720 ? 12.5 : 16.0,
        tenureMonths: 12,
        estimatedEmi: score >= 720 ? 6656 : 4529,
        highlights: ['Pre-approved', 'Instant disbursal', 'No collateral'],
      ));
    }
    if (score >= 560) {
      offers.add(LoanOfferModel(
        id: 'offer_2',
        lenderName: 'TVS Credit',
        lenderLogoUrl: '',
        amount: 40000,
        interestRate: 18.0,
        tenureMonths: 6,
        estimatedEmi: 7023,
        highlights: ['Two-wheeler finance', 'Flexible tenure'],
      ));
    }
    if (score >= 480) {
      offers.add(LoanOfferModel(
        id: 'offer_3',
        lenderName: 'Bajaj Finserv',
        lenderLogoUrl: '',
        amount: 25000,
        interestRate: 20.0,
        tenureMonths: 3,
        estimatedEmi: 8710,
        highlights: ['Emergency cash', 'Quick approval'],
      ));
    }
    
    ref.read(loanProvider.notifier).setOffers(offers);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Block back navigation during generation
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pulsing gradient ring
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale = 0.9 + _pulseController.value * 0.15;
                      final opacity = 0.5 + _pulseController.value * 0.5;
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.accent.withValues(alpha: opacity * 0.3),
                                AppColors.accentLight.withValues(alpha: opacity * 0.1),
                                Colors.transparent,
                              ],
                            ),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: opacity),
                              width: 2,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.psychology_rounded,
                              size: 64,
                              color: AppColors.accentLight,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 48),
                  
                  Text(
                    'Generating Your Score',
                    style: AppTypography.displaySmall,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 800.ms),
                  
                  const SizedBox(height: 16),
                  const ScoreStatusMessage(),
                  
                  const SizedBox(height: 40),
                  
                  // Progress row with 3 dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ).animate(delay: Duration(milliseconds: i * 200))
                          .fade(begin: 0.2, end: 1.0, duration: 600.ms)
                          .then()
                          .fade(begin: 1.0, end: 0.2, duration: 600.ms);
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
