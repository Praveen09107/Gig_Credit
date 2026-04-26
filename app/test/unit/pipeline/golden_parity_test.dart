import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import 'package:gigcredit/scoring/engine/scoring_engine.dart';
import 'package:gigcredit/scoring/engine/meta_learner.dart';
import 'package:gigcredit/scoring/models/scoring_constants.dart';

/// GOLDEN PARITY TEST
/// Validates that our Dart scoring pipeline produces the SAME results
/// as Dev A's Python ML pipeline using the golden_inference.json file.
///
/// Tolerance: pillar scores within 1e-4, final score within ±3 points.
void main() {
  late List<dynamic> goldenCases;

  setUpAll(() {
    final goldenPath = '${Directory.current.parent.path}/ml_pipeline/output/golden/golden_inference.json';
    final file = File(goldenPath);
    if (!file.existsSync()) {
      // Try relative path from app/
      final altPath = '${Directory.current.path}/../ml_pipeline/output/golden/golden_inference.json';
      final altFile = File(altPath);
      if (!altFile.existsSync()) {
        fail('golden_inference.json not found at $goldenPath or $altPath');
      }
      goldenCases = jsonDecode(altFile.readAsStringSync()) as List;
    } else {
      goldenCases = jsonDecode(file.readAsStringSync()) as List;
    }
  });

  group('Golden Parity Test — Python vs Dart', () {
    test('golden_inference.json loaded with 5 test cases', () {
      expect(goldenCases.length, 5);
    });

    test('Case 1: platform_worker — pillar scores match', () {
      _runPillarParityTest(goldenCases[0]);
    });

    test('Case 2: vendor — pillar scores match', () {
      _runPillarParityTest(goldenCases[1]);
    });

    test('Case 3: tradesperson — pillar scores match', () {
      _runPillarParityTest(goldenCases[2]);
    });

    test('Case 4: freelancer — pillar scores match', () {
      _runPillarParityTest(goldenCases[3]);
    });

    test('Case 5: platform_worker — pillar scores match', () {
      _runPillarParityTest(goldenCases[4]);
    });

    test('Case 1: platform_worker — meta-learner score matches', () {
      _runMetaParityTest(goldenCases[0]);
    });

    test('Case 2: vendor — meta-learner score matches', () {
      _runMetaParityTest(goldenCases[1]);
    });

    test('Case 3: tradesperson — meta-learner score matches', () {
      _runMetaParityTest(goldenCases[2]);
    });

    test('Case 4: freelancer — meta-learner score matches', () {
      _runMetaParityTest(goldenCases[3]);
    });

    test('Case 5: platform_worker — meta-learner score matches', () {
      _runMetaParityTest(goldenCases[4]);
    });

    test('All 5 cases: final score within ±3 of Python', () {
      for (int i = 0; i < goldenCases.length; i++) {
        final testCase = goldenCases[i];
        final expectedScore = testCase['final_score'] as int;
        final features = List<double>.from(testCase['features'] as List);
        final workType = testCase['work_type'] as String;

        // Score pillars with real models
        final engine = ScoringEngine();
        final pillarScores = engine.scorePillars(features);

        // Meta-learner
        final dartScore = MetaLearner.predict(pillarScores, workType);

        expect(
          (dartScore - expectedScore).abs(),
          lessThanOrEqualTo(3),
          reason: 'Case ${i + 1} ($workType): Dart=$dartScore vs Python=$expectedScore',
        );
      }
    });

    test('Grade mapping matches scoring_constants.dart', () {
      expect(scoreToGrade(800), 'A+');
      expect(scoreToGrade(750), 'A');
      expect(scoreToGrade(700), 'B+');
      expect(scoreToGrade(650), 'B');
      expect(scoreToGrade(600), 'C+');
      expect(scoreToGrade(550), 'C');
      expect(scoreToGrade(400), 'D');
    });

    test('Risk mapping matches scoring_constants.dart', () {
      expect(scoreToRiskLevel(750), 'Low');
      expect(scoreToRiskLevel(650), 'Medium');
      expect(scoreToRiskLevel(500), 'High');
    });
  });
}

/// Validate that each Dart pillar score matches the Python golden value.
void _runPillarParityTest(Map<String, dynamic> testCase) {
  final features = List<double>.from(testCase['features'] as List);
  final expectedPillars = testCase['pillar_scores'] as Map<String, dynamic>;
  final caseId = testCase['case_id'];

  final engine = ScoringEngine();
  final dartPillars = engine.scorePillars(features);

  for (final pillar in expectedPillars.keys) {
    final expected = (expectedPillars[pillar] as num).toDouble();
    final actual = dartPillars[pillar]!;
    expect(
      (actual - expected).abs(),
      lessThan(1e-4),
      reason: 'Case $caseId pillar $pillar: Dart=$actual vs Python=$expected',
    );
  }
}

/// Validate that the meta-learner final score matches.
void _runMetaParityTest(Map<String, dynamic> testCase) {
  final features = List<double>.from(testCase['features'] as List);
  final expectedScore = testCase['final_score'] as int;
  final workType = testCase['work_type'] as String;

  final engine = ScoringEngine();
  final pillarScores = engine.scorePillars(features);
  final dartScore = MetaLearner.predict(pillarScores, workType);

  expect(
    (dartScore - expectedScore).abs(),
    lessThanOrEqualTo(3),
    reason: 'Case ${testCase['case_id']} ($workType): Dart=$dartScore vs Python=$expectedScore',
  );
}
