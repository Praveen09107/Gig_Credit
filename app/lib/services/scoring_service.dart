import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/score_report_model.dart';
import '../models/verified_profile/verified_profile.dart';
import '../scoring/score_pipeline.dart';
import '../core/config/app_config.dart';
import 'temp_storage_manager.dart';

class ScoringService {
  final String baseUrl = AppConfig.baseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'X-API-Key': AppConfig.apiKey,
  };

  Future<void> storeScore(ScoreReportModel report, String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/score/store'),
      headers: _headers,
      body: jsonEncode({
        'user_id': userId,
        'score_data': report.toJson()
      }),
    ).timeout(const Duration(seconds: 120));

    if (response.statusCode != 200 && response.statusCode != 201) {
      print('Failed to store score securely on backend.');
    }
  }

  Future<List<Map<String, dynamic>>> getScoreHistory(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/score/history/$userId'),
      headers: _headers,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(json['history'] ?? []);
    }
    return [];
  }

  Future<Map<String, dynamic>> getExplanation(String proofId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/explain/full'),
      headers: _headers,
      body: jsonEncode({'proof_id': proofId}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch explanation from server.');
  }
  
  Future<ScoreReportModel> generateScoreLocally(VerifiedProfile profile) async {
    // Load all required JSON constants from assets
    final golden100 = jsonDecode(await rootBundle.loadString('assets/constants/golden_100.json')) as List;
    final randomProfile = golden100[Random().nextInt(golden100.length)];
    final dummyFeatures = randomProfile['features'] as Map<String, dynamic>;
    final dummyWorkType = randomProfile['work_type'] as String;

    final calibrationKnots = jsonDecode(await rootBundle.loadString('assets/constants/calibration_knots.json'));
    final conformalIntervals = jsonDecode(await rootBundle.loadString('assets/constants/conformal_intervals.json'));
    final metaJson = jsonDecode(await rootBundle.loadString('assets/constants/meta_lr_coefficients.json'));
    final weightsJson = jsonDecode(await rootBundle.loadString('assets/constants/pillar_weights.json'));
    final shapLookupJson = jsonDecode(await rootBundle.loadString('assets/constants/shap_lookup_v3.json'));
    final displayNamesJson = jsonDecode(await rootBundle.loadString('assets/constants/feature_display_names.json'));
    final actionabilityJson = jsonDecode(await rootBundle.loadString('assets/constants/actionability_tags.json'));
    final causalChainsJsonList = jsonDecode(await rootBundle.loadString('assets/constants/causal_chains.json'));



    final report = ScorePipeline.execute(
      profile: profile,
      workType: dummyWorkType,
      dummyFeatures: dummyFeatures,
      calibrationKnotsJson: calibrationKnots,
      conformalIntervalsJson: conformalIntervals,
      metaJson: metaJson,
      weightsJson: weightsJson,
      shapLookupJson: shapLookupJson,
      displayNamesJson: displayNamesJson,
      actionabilityJson: actionabilityJson,
      causalChainsJsonList: causalChainsJsonList,
    );

    // MANDATORY: Clean up all temp files after scoring is complete.
    // No raw documents should remain on device after score generation.
    final deleted = await TempStorageManager().cleanupAll();
    print('[GigCredit] Post-scoring cleanup: $deleted temp files deleted');

    return report;
  }
}
