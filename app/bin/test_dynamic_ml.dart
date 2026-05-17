import 'dart:io';
import 'dart:convert';
import 'dart:math';
import '../lib/scoring/score_pipeline.dart';
import '../lib/models/verified_profile/verified_profile.dart';

void main() {
  print("=" * 60);
  print(" 🤖 GIGCREDIT ML PIPELINE REAL EXECUTION TEST 🤖 ");
  print("=" * 60);

  // Load JSONs using standard File IO (since we are outside Flutter context)
  final String assetsDir = 'assets/constants';
  
  final golden100 = jsonDecode(File('$assetsDir/golden_100.json').readAsStringSync()) as List;
  final calibrationKnots = jsonDecode(File('$assetsDir/calibration_knots.json').readAsStringSync());
  final conformalIntervals = jsonDecode(File('$assetsDir/conformal_intervals.json').readAsStringSync());
  final metaJson = jsonDecode(File('$assetsDir/meta_lr_coefficients.json').readAsStringSync());
  final weightsJson = jsonDecode(File('$assetsDir/pillar_weights.json').readAsStringSync());
  final shapLookupJson = jsonDecode(File('$assetsDir/shap_lookup_v3.json').readAsStringSync());
  final displayNamesJson = jsonDecode(File('$assetsDir/feature_display_names.json').readAsStringSync());
  final actionabilityJson = jsonDecode(File('$assetsDir/actionability_tags.json').readAsStringSync());
  final causalChainsJsonList = jsonDecode(File('$assetsDir/causal_chains.json').readAsStringSync());

  // Test Profile 0 (Should have good score)
  final profileData0 = golden100[0];
  final dummyFeatures0 = profileData0['features'] as Map<String, dynamic>;
  final dummyWorkType0 = profileData0['work_type'] as String;

  // Test Profile 1 (Should have lower score)
  final profileData1 = golden100[1];
  final dummyFeatures1 = profileData1['features'] as Map<String, dynamic>;
  final dummyWorkType1 = profileData1['work_type'] as String;

  // Create a dummy VerifiedProfile (required by pipeline signature but unused when dummyFeatures provided)
  final dummyProfile = VerifiedProfile();

  print("\n[+] Loaded all Neural Weights, Knots, SHAP lookups, and ML config files successfully.");
  print("[+] Executing exact ScorePipeline.execute() in Dart (NO HARDCODING)...\n");

  final report0 = ScorePipeline.execute(
    profile: dummyProfile,
    workType: dummyWorkType0,
    dummyFeatures: dummyFeatures0,
    calibrationKnotsJson: calibrationKnots,
    conformalIntervalsJson: conformalIntervals,
    metaJson: metaJson,
    weightsJson: weightsJson,
    shapLookupJson: shapLookupJson,
    displayNamesJson: displayNamesJson,
    actionabilityJson: actionabilityJson,
    causalChainsJsonList: causalChainsJsonList,
  );

  final report1 = ScorePipeline.execute(
    profile: dummyProfile,
    workType: dummyWorkType1,
    dummyFeatures: dummyFeatures1,
    calibrationKnotsJson: calibrationKnots,
    conformalIntervalsJson: conformalIntervals,
    metaJson: metaJson,
    weightsJson: weightsJson,
    shapLookupJson: shapLookupJson,
    displayNamesJson: displayNamesJson,
    actionabilityJson: actionabilityJson,
    causalChainsJsonList: causalChainsJsonList,
  );

  _printReport("PROFILE 1 (test_000 data)", report0);
  _printReport("PROFILE 2 (test_001 data)", report1);
}

void _printReport(String title, dynamic report) {
  print("--- $title ---");
  print("    -> ACTUAL COMPUTED SCORE:        ${report.finalScore}");
  print("    -> ACTUAL COMPUTED GRADE:        ${report.grade}");
  print("    -> ACTUAL RISK BAND:             ${report.riskBand}");
  print("    -> P1 (Income) Contribution:     +${report.pillarContributions['P1']?.round() ?? 0} pts");
  print("    -> P2 (Finance) Contribution:    +${report.pillarContributions['P2']?.round() ?? 0} pts");
  print("");
  print("    [XAI / SHAP EXTRACTION - STRENGTHS]");
  for (var s in report.topStrengths) {
    print("      + ${s.featureName} (${s.impactStrength > 0 ? '+' : ''}${s.impactStrength.round()} pts)");
  }
  print("    [XAI / SHAP EXTRACTION - GAPS]");
  for (var s in report.topConcerns) {
    print("      - ${s.featureName} (${s.impactStrength > 0 ? '+' : ''}${s.impactStrength.round()} pts)");
  }
  
  if (report.causalChains.isNotEmpty) {
    print("");
    print("    [CAUSAL CHAIN GENERATED]");
    print("      Rule triggered: ${report.causalChains.first.ruleId}");
    print("      Root Cause:     ${report.causalChains.first.rootCause}");
  }
  print("\n");
}
