import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gigcredit/models/verified_profile/verified_profile.dart';
import 'package:gigcredit/models/verified_profile/personal_info.dart';
import 'package:gigcredit/models/verified_profile/kyc_info.dart';
import 'package:gigcredit/scoring/score_pipeline.dart';
import 'package:gigcredit/models/score_report_model.dart';

/// End-to-End Production Pipeline Test
/// Validates that the entire ML execution chain (from raw profile to final XAI report)
/// functions without crashing and produces a structurally valid result.
void main() {
  group('E2E Production Pipeline Tests', () {
    late Map<String, dynamic> calibrationKnots;
    late Map<String, dynamic> conformalIntervals;
    late Map<String, dynamic> metaJson;
    late Map<String, dynamic> weightsJson;
    late Map<String, dynamic> shapLookupJson;
    late Map<String, dynamic> displayNamesJson;
    late Map<String, dynamic> actionabilityJson;
    late List<dynamic> causalChainsJsonList;

    setUpAll(() {
      // Load all production JSON constants
      calibrationKnots = jsonDecode(File('assets/constants/calibration_knots.json').readAsStringSync());
      conformalIntervals = jsonDecode(File('assets/constants/conformal_intervals.json').readAsStringSync());
      metaJson = jsonDecode(File('assets/constants/meta_lr_coefficients.json').readAsStringSync());
      weightsJson = jsonDecode(File('assets/constants/pillar_weights.json').readAsStringSync());
      shapLookupJson = jsonDecode(File('assets/constants/shap_lookup_v3.json').readAsStringSync());
      displayNamesJson = jsonDecode(File('assets/constants/feature_display_names.json').readAsStringSync());
      actionabilityJson = jsonDecode(File('assets/constants/actionability_tags.json').readAsStringSync());
      causalChainsJsonList = jsonDecode(File('assets/constants/causal_chains.json').readAsStringSync());
    });

    test('ScorePipeline.execute processes a VerifiedProfile end-to-end', () {
      // 1. Create a mock VerifiedProfile
      final profile = VerifiedProfile(
        personalInfo: const PersonalInfo(
          fullName: 'Test User',
          workType: 'platform_worker',
        ),
        kycInfo: const KycInfo(
          isVerified: true,
        ),
      );

      // 2. Execute the Pipeline
      ScoreReportModel report = ScorePipeline.execute(
        profile: profile,
        workType: 'platform_worker', // Use a valid workType
        calibrationKnotsJson: calibrationKnots,
        conformalIntervalsJson: conformalIntervals,
        metaJson: metaJson,
        weightsJson: weightsJson,
        shapLookupJson: shapLookupJson,
        displayNamesJson: displayNamesJson,
        actionabilityJson: actionabilityJson,
        causalChainsJsonList: causalChainsJsonList,
      );

      // 3. Verify the output structure
      expect(report, isNotNull);
      expect(report!.finalScore, inInclusiveRange(300, 900), reason: 'Score must be 300-900');
      expect(report.probability, inInclusiveRange(0.0, 1.0), reason: 'Probability must be 0-1');
      expect(report.pillars.length, equals(8), reason: 'Must output exactly 8 pillars');
      
      // Verify XAI features exist
      expect(report.topStrengths, isA<List>(), reason: 'Should return list of strengths');
      expect(report.tailoredSuggestions, isA<List>(), reason: 'Should return list of actions');
      
      print('✅ Full Pipeline End-to-End execution successful. Generated Score: \${report.finalScore}');
    });
  });
}
