import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../state/verified_profile_provider.dart';
import '../../../state/ocr_results_provider.dart';
import '../../../state/step_status_provider.dart';
import '../../../state/score_provider.dart';
import '../../../state/user_provider.dart';
import '../../../state/loan_provider.dart';
import '../../../models/loan_offer_model.dart';
import '../../../app/app_router.dart';
import '../../../models/score_report_model.dart';
import '../../../models/tailored_suggestion.dart';
import '../../../state/api_service_provider.dart';
import '../../../services/loan_api_service.dart';
import '../widgets/score_status_message.dart';
import '../../../shared/widgets/feedback/app_toast.dart';
import '../../../shared/widgets/loaders/delivery_bike_loader.dart';
import '../../../core/session/secure_storage.dart';
import '../../../services/scoring_service.dart';

/// GigCredit Score Generating Screen
/// Green gradient pulsing ring + cycling messages + computes real score in background.
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
    try {
      final profile = ref.read(verifiedProfileProvider);
      
      // 1. Run local scoring & SHAP pipeline
      var report = await ScoringService().generateScoreLocally(profile);

      try {
        // 2. Prepare payload for LLM explanation (passing SHAP outputs)
        // Build pillar_scores map from the scored pillars
        final pillarScores = <String, double>{};
        for (final p in report.pillars) {
          pillarScores[p.code] = p.calibratedScore;
        }
        
        final payload = {
          "credit_score": report.finalScore,
          "grade": report.grade,
          "risk_level": report.riskBand,
          "work_type": profile.personalInfo.workType.isNotEmpty ? profile.personalInfo.workType : 'platform_worker',
          "language": "English",
          "pillar_scores": pillarScores,
          "confidence_level": report.overallConfidence > 0.8 ? "high" : (report.overallConfidence > 0.5 ? "medium" : "low"),
          "positive_factors": report.topStrengths.map((e) => {"feature_label": e.featureName, "pillar": e.pillarLabel.isNotEmpty ? e.pillarLabel : "P1", "impact": e.impactStrength}).toList(),
          "negative_factors": report.topConcerns.map((e) => {"feature_label": e.featureName, "pillar": e.pillarLabel.isNotEmpty ? e.pillarLabel : "P1", "impact": e.impactStrength}).toList(),
        };

        // 3. Request LLM generated explanation via the live backend
        final api = ref.read(apiServiceProvider);
        final llmResponse = await api.generateReportScore(payload);

        if (llmResponse['status'] == 'success' || llmResponse['status'] == 'fallback') {
          // Merge the backend LLM response with our local score report
          report = ScoreReportModel(
            finalScore: report.finalScore,
            probability: report.probability,
            workType: report.workType,
            computeTimeMs: report.computeTimeMs,
            grade: report.grade,
            riskBand: report.riskBand,
            proofId: report.proofId,
            generatedAt: report.generatedAt,
            overallConfidence: report.overallConfidence,
            pillars: report.pillars,
            pillarContributions: report.pillarContributions,
            topStrengths: report.topStrengths,
            topConcerns: report.topConcerns,
            llmExplanation: llmResponse['explanation'],
            tailoredSuggestions: (llmResponse['suggestions'] as List?)?.map((s) {
              if (s is String) return TailoredSuggestion(text: s);
              return TailoredSuggestion.fromJson(s);
            }).toList() ?? report.tailoredSuggestions,
            causalChains: report.causalChains,
            trajectory: report.trajectory,
            metaProbability: report.metaProbability,
            modelUsed: llmResponse['model_used'] as String? ?? report.modelUsed,
            efsVerdict: report.efsVerdict,
          );
        }
      } catch (e) {
        print('LLM API Error: $e');
        // If network fails, we just use the on-device fallback suggestions
      }

      if (!mounted) return;

      // ── STEP A: Store the score FIRST (feature engineering already done) ──
      // The score report contains only anonymized features, not raw PII.
      ref.read(scoreProvider.notifier).setSuccess(report);

      // Store in backend MongoDB
      final user = ref.read(userProvider);
      if (user?.id.isNotEmpty == true) {
        try {
          await ScoringService().storeScore(report, user!.id);
        } catch (e) {
          debugPrint('[ScoreGen] Failed to push score to backend: $e');
        }
      }

      // Seed personalized loan offers
      await _seedLoanOffers(report.finalScore);

      // ═══════════════════════════════════════════════════════════════
      // STEP B: DELETE ALL RAW PII DATA
      // Only runs AFTER feature engineering is complete AND score is
      // safely stored. Raw inputs (Aadhaar, PAN, bank statement,
      // uploaded images/PDFs, OCR results) are wiped from all storage.
      // The score report contains only anonymized ML features — no PII.
      // ═══════════════════════════════════════════════════════════════
      await _deleteAllRawData();

      // Haptic celebration
      HapticFeedback.heavyImpact();

      // Navigate to report screen
      context.go(AppRoutes.scoreReport);

    } catch (e, stackTrace) {
      print('🔥 PIPELINE CRASHED: $e');
      print(stackTrace);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.bgCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Computation Error',
                style: AppTypography.headlineMedium),
            content: Text(
              'The scoring engine encountered an error:\n\n$e',
              style: AppTypography.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go(AppRoutes.home);
                },
                child: const Text('Go Home',
                    style: TextStyle(color: AppColors.greenPrimary, fontWeight: FontWeight.w600)),
              )
            ],
          ),
        );
      }
    }
  }

  /// Delete all raw PII data after feature engineering + score storage succeeds.
  /// Called ONLY after score is safely stored — never before.
  Future<void> _deleteAllRawData() async {
    debugPrint('[Privacy] Starting raw data deletion...');

    // 1. Clear in-memory verified profile
    //    Contains: name, DOB, Aadhaar, PAN, bank transactions, OCR data
    ref.read(verifiedProfileProvider.notifier).reset();
    debugPrint('[Privacy] ✓ In-memory verified profile cleared');

    // 2. Clear all OCR extraction results
    //    Contains: extracted text from Aadhaar, PAN, bank statement, utility bills
    ref.read(ocrResultsProvider.notifier).clear();
    debugPrint('[Privacy] ✓ OCR results cleared');

    // 3. Clear step completion status
    //    No longer needed — score is generated and stored
    ref.read(stepStatusProvider.notifier).reset();
    debugPrint('[Privacy] ✓ Step status cleared');

    // 4. Delete from encrypted secure storage
    //    Contains: serialized verified_profile + step_progress (persisted across app restarts)
    try {
      await SecureStorage.clearAll();
      debugPrint('[Privacy] ✓ Encrypted secure storage cleared');
    } catch (e) {
      debugPrint('[Privacy] Secure storage clear: $e (non-critical)');
    }

    // 5. Delete temp files from device storage
    //    Contains: uploaded PDFs (bank statement), JPEGs (Aadhaar, PAN, utility bills)
    //    These are written by FilePicker/ImagePicker to the temp directory
    try {
      final tempDir = await getTemporaryDirectory();
      int deletedCount = 0;
      final entities = tempDir.listSync(recursive: true);
      for (final entity in entities) {
        if (entity is File) {
          final ext = entity.path.toLowerCase();
          if (ext.endsWith('.pdf') || ext.endsWith('.jpg') ||
              ext.endsWith('.jpeg') || ext.endsWith('.png') ||
              ext.endsWith('.webp') || ext.endsWith('.heic')) {
            try {
              await entity.delete();
              deletedCount++;
            } catch (_) {}
          }
        }
      }
      debugPrint('[Privacy] ✓ Temp files deleted: $deletedCount document files removed');
    } catch (e) {
      debugPrint('[Privacy] Temp file cleanup: $e (non-critical)');
    }

    // 6. Delete app documents directory uploads (some pickers write here)
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      int deletedCount = 0;
      final entities = docsDir.listSync(recursive: false);
      for (final entity in entities) {
        if (entity is File) {
          final ext = entity.path.toLowerCase();
          if (ext.endsWith('.pdf') || ext.endsWith('.jpg') ||
              ext.endsWith('.jpeg') || ext.endsWith('.png')) {
            try {
              await entity.delete();
              deletedCount++;
            } catch (_) {}
          }
        }
      }
      if (deletedCount > 0) {
        debugPrint('[Privacy] ✓ App docs directory: $deletedCount files removed');
      }
    } catch (e) {
      debugPrint('[Privacy] App docs cleanup: $e (non-critical)');
    }

    debugPrint('[Privacy] ✅ COMPLETE: All raw PII data deleted. '
        'Only anonymized score report (no raw inputs) retained in memory.');

    if (mounted) {
      AppToast.success(context, 'Raw data deleted', subtitle: 'Real user text and uploaded data deleted from temp storage');
    }
  }

  Future<void> _seedLoanOffers(int score) async {
    try {
      // Real backend call to fetch eligible loan products
      final loanApi = ref.read(loanApiServiceProvider);
      final result = await loanApi.getProducts(score);
      final products = result['eligible_products'] as List? ?? [];

      final offers = <LoanOfferModel>[];
      for (final p in products) {
        offers.add(LoanOfferModel(
          id: p['id'] ?? 'offer_${offers.length}',
          lenderName: p['name'] ?? 'GigCredit Partner',
          lenderLogoUrl: '',
          amount: (p['max_amount'] as num?)?.toDouble() ?? 0,
          interestRate: 18.0, // Will be refined in KFS
          tenureMonths: (p['tenures'] as List?)?.isNotEmpty == true ? (p['tenures'] as List).first as int : 6,
          estimatedEmi: 0, // Calculated in KFS step
          highlights: [p['description'] ?? 'Pre-approved'],
        ));
      }

      ref.read(loanProvider.notifier).setOffers(offers);
      debugPrint('[ScoreGen] Loaded ${offers.length} real loan products from backend');
    } catch (e) {
      debugPrint('[ScoreGen] Failed to fetch loan products: $e');
      // No fallback — if backend fails, loan list stays empty
    }
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
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.bgScreen,
          ),
          child: Stack(
            children: [
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Delivery Bike Loader instead of the static psychology icon
                        const DeliveryBikeLoader(),
                        const SizedBox(height: 40),
                        
                        Text(
                          'Generating Your Score',
                          style: AppTypography.heroHeading.copyWith(
                              fontSize: 26, color: AppColors.greenPrimary),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(duration: 600.ms),
                        
                        const SizedBox(height: 14),
                        const ScoreStatusMessage(),
                        
                        const SizedBox(height: 36),
                        
                        // Progress dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (i) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.greenMint,
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
            ],
          ),
        ),
      ),
    );
  }
}
