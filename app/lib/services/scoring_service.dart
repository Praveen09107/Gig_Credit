import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/score_report_model.dart';
import '../models/verified_profile/verified_profile.dart';
import '../scoring/score_pipeline.dart';
import '../core/config/app_config.dart';
import 'temp_storage_manager.dart';
import 'gig_logger.dart';

class ScoringService {
  final String baseUrl = AppConfig.baseUrl;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-API-Key': AppConfig.apiKey,
      };

  Future<void> storeScore(ScoreReportModel report, String userId) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/score/store'),
          headers: _headers,
          body: jsonEncode({'user_id': userId, 'score_data': report.toJson()}),
        )
        .timeout(const Duration(seconds: 120));

    if (response.statusCode != 200 && response.statusCode != 201) {
      print('Failed to store score securely on backend.');
    }
  }

  Future<List<Map<String, dynamic>>> getScoreHistory(String userId) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/score/history/$userId'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(json['history'] ?? []);
    }
    return [];
  }

  Future<void> deleteScoreReport(String userId, String proofId) async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl/score/history/$userId/$proofId'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 15));

    // 200 = deleted successfully
    if (response.statusCode != 200) {
      throw Exception('Delete failed: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getExplanation(String proofId) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/explain/full'),
          headers: _headers,
          body: jsonEncode({'proof_id': proofId}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch explanation from server.');
  }

  /// Determines whether the profile has real user-entered data.
  /// Only requires Step 1 data (name + income) — bank data is optional enrichment.
  /// This ensures real features are always used when a real user fills Step 1.
  bool _hasRealInputs(VerifiedProfile profile) {
    final hasName = profile.personalInfo.fullName.trim().length >= 2;
    final hasIncome = profile.personalInfo.selfDeclaredIncome > 0;
    final hasDob = profile.personalInfo.dateOfBirth.isNotEmpty;
    return hasName && hasIncome && hasDob;
  }

  Future<ScoreReportModel> generateScoreLocally(VerifiedProfile profile) async {
    GigLogger.stepBanner(0, 'SCORE GENERATION — FULL PIPELINE');

    GigLogger.sectionHeader('LOADING CALIBRATION ASSETS FROM BUNDLE');
    // Load all required JSON constants from assets
    final calibrationKnots = jsonDecode(
        await rootBundle.loadString('assets/constants/calibration_knots.json'));
    GigLogger.ok('calibration_knots.json loaded');
    final conformalIntervals = jsonDecode(await rootBundle
        .loadString('assets/constants/conformal_intervals.json'));
    GigLogger.ok('conformal_intervals.json loaded');
    final metaJson = jsonDecode(await rootBundle
        .loadString('assets/constants/meta_lr_coefficients.json'));
    GigLogger.ok('meta_lr_coefficients.json loaded');
    final weightsJson = jsonDecode(
        await rootBundle.loadString('assets/constants/pillar_weights.json'));
    GigLogger.ok('pillar_weights.json loaded');
    final shapLookupJson = jsonDecode(
        await rootBundle.loadString('assets/constants/shap_lookup_v3.json'));
    GigLogger.ok('shap_lookup_v3.json loaded');
    final displayNamesJson = jsonDecode(await rootBundle
        .loadString('assets/constants/feature_display_names.json'));
    GigLogger.ok('feature_display_names.json loaded');
    final actionabilityJson = jsonDecode(await rootBundle
        .loadString('assets/constants/actionability_tags.json'));
    GigLogger.ok('actionability_tags.json loaded');
    final causalChainsJsonList = jsonDecode(
        await rootBundle.loadString('assets/constants/causal_chains.json'));
    GigLogger.ok('causal_chains.json loaded');

    // ── Feature source decision ──────────────────────────────────────────────
    // REAL inputs (user filled Steps 1-3): use FeatureEngineer.extract(profile)
    // DEMO profiles (50+ golden_100 users): inject pre-computed dummy features
    // ──────────────────────────────────────────────────────────────
    GigLogger.sectionHeader('FEATURE SOURCE DECISION');
    Map<String, dynamic>? dummyFeatures;
    String workType;

    if (_hasRealInputs(profile)) {
      // Real user data — let FeatureEngineer extract features from the profile
      dummyFeatures = null;
      workType = profile.personalInfo.workType.isNotEmpty
          ? profile.personalInfo.workType
          : 'platform_worker';
      GigLogger.ok(
          'REAL USER INPUTS detected — using FeatureEngineer.extract(profile)');
      GigLogger.data('User', profile.personalInfo.fullName);
      GigLogger.data('WorkType', workType);
      GigLogger.data('Income',
          '₹${profile.personalInfo.selfDeclaredIncome.toStringAsFixed(0)}');
      GigLogger.data(
          'Bank Acc',
          profile.bankInfo.accountNumber.isNotEmpty
              ? '****${profile.bankInfo.accountNumber.substring(profile.bankInfo.accountNumber.length > 4 ? profile.bankInfo.accountNumber.length - 4 : 0)}'
              : 'Not provided');
      GigLogger.data('Aadhaar', profile.kycInfo.isVerified ? 'Verified' : 'Not verified');
    } else {
      // Demo profile — use golden_100 pre-computed features for stability
      final golden100 = jsonDecode(
              await rootBundle.loadString('assets/constants/golden_100.json'))
          as List;
      final randomProfile = golden100[Random().nextInt(golden100.length)];
      dummyFeatures = randomProfile['features'] as Map<String, dynamic>;
      workType = randomProfile['work_type'] as String;
      GigLogger.warn(
          'DEMO profile detected — injecting golden_100 pre-computed features');
      GigLogger.data('WorkType', workType);
    }

    GigLogger.sectionHeader('EXECUTING SCORE PIPELINE');
    GigLogger.processing('ScorePipeline.execute() starting...');
    GigLogger.info(
        '  Inputs: profile + workType=$workType + dummyFeatures=${dummyFeatures == null ? "null (REAL)" : "pre-computed (DEMO)"}');
    GigLogger.info(
        '  Modules: FeatureEngineer → PillarScorer → Calibration → SHAP → Report');

    final report = ScorePipeline.execute(
      profile: profile,
      workType: workType,
      dummyFeatures: dummyFeatures, // null = use real features
      calibrationKnotsJson: calibrationKnots,
      conformalIntervalsJson: conformalIntervals,
      metaJson: metaJson,
      weightsJson: weightsJson,
      shapLookupJson: shapLookupJson,
      displayNamesJson: displayNamesJson,
      actionabilityJson: actionabilityJson,
      causalChainsJsonList: causalChainsJsonList,
    );

    GigLogger.sectionHeader('SCORE PIPELINE COMPLETE');
    GigLogger.score(report.finalScore, report.riskBand);
    GigLogger.data('Grade', report.grade);
    GigLogger.data('Confidence', '${(report.overallConfidence * 100).toStringAsFixed(1)}%');
    GigLogger.data('Proof ID', report.proofId);
    GigLogger.data('Generated At', report.generatedAt.toIso8601String());

    GigLogger.sectionHeader('PILLAR SCORES BREAKDOWN');
    if (report.pillarContributions.isNotEmpty) {
      for (final entry in report.pillarContributions.entries) {
        GigLogger.pillarScore(entry.key, entry.value.toDouble(), (entry.value * 10).round().clamp(0, 100));
      }
    } else {
      GigLogger.info('  (No pillar breakdown available)');
    }

    GigLogger.sectionHeader('TOP SHAP FACTORS (Explainability)');
    if (report.topStrengths.isNotEmpty) {
      for (final f in report.topStrengths.take(3)) {
        GigLogger.shapScore(f.featureName, f.impactStrength, true, f.description);
      }
    }
    if (report.topConcerns.isNotEmpty) {
      for (final f in report.topConcerns.take(3)) {
        GigLogger.shapScore(f.featureName, f.impactStrength, false, f.description);
      }
    }

    GigLogger.llmSection('REPORT NARRATIVE',
        'Report content generated from causal chains + SHAP tags');
    GigLogger.data('Explanation length', '${report.llmExplanation?.length ?? 0} chars');
    GigLogger.data('Suggestions', '${report.tailoredSuggestions.length} items');

    // MANDATORY: Clean up all temp files after scoring is complete.
    // No raw documents should remain on device after score generation.
    final deleted = await TempStorageManager().cleanupAll();
    GigLogger.cleanup(deleted);
    GigLogger.ok(
        'Score generation complete ✔ All sensitive data purged from device.');

    return report;
  }
}
