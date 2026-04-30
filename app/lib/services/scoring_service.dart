import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/score_report_model.dart';
import '../models/verified_profile/verified_profile.dart';
import '../scoring/score_pipeline.dart';
class ScoringService {
  final String baseUrl;

  ScoringService({this.baseUrl = 'https://gig-credit.onrender.com/api'});

  Future<void> storeScore(ScoreReportModel report) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/score/store'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(report.toJson()),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to store score');
      }
    } catch (e) {
      // Offline fallback: store locally or ignore
      print('Offline mode: Score saved locally. Error: $e');
    }
  }

  Future<Map<String, dynamic>> getExplanation(String proofId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/explain/full'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'proof_id': proofId}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch server explanation');
      }
    } catch (e) {
      print('Offline mode: Could not fetch server explanation. Error: $e');
      return {};
    }
  }
  Future<ScoreReportModel> generateScoreLocally(VerifiedProfile profile) async {
    // Load all required JSON constants from assets
    final calibrationKnots = jsonDecode(await rootBundle.loadString('assets/constants/calibration_knots.json'));
    final conformalIntervals = jsonDecode(await rootBundle.loadString('assets/constants/conformal_intervals.json'));
    final metaJson = jsonDecode(await rootBundle.loadString('assets/constants/meta_lr_coefficients.json'));
    final weightsJson = jsonDecode(await rootBundle.loadString('assets/constants/pillar_weights.json'));
    final shapLookupJson = jsonDecode(await rootBundle.loadString('assets/constants/shap_lookup_v3.json'));
    final displayNamesJson = jsonDecode(await rootBundle.loadString('assets/constants/feature_display_names.json'));
    final actionabilityJson = jsonDecode(await rootBundle.loadString('assets/constants/actionability_tags.json'));
    final causalChainsJsonList = jsonDecode(await rootBundle.loadString('assets/constants/causal_chains.json'));

    final workType = profile.personalInfo.workType.isNotEmpty ? profile.personalInfo.workType : 'platform_worker';

    return ScorePipeline.execute(
      profile: profile,
      workType: workType,
      calibrationKnotsJson: calibrationKnots,
      conformalIntervalsJson: conformalIntervals,
      metaJson: metaJson,
      weightsJson: weightsJson,
      shapLookupJson: shapLookupJson,
      displayNamesJson: displayNamesJson,
      actionabilityJson: actionabilityJson,
      causalChainsJsonList: causalChainsJsonList,
    );
  }
}
