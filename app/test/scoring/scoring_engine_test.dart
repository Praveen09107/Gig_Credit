import 'package:flutter_test/flutter_test.dart';
import 'package:gigcredit/scoring/engine/scoring_engine.dart';

void main() {
  group('ScoringEngine', () {
    test('isotonicInterpolate() correctly handles bounds and piecewise linear logic', () {
      final xKnots = [0.1, 0.5, 0.9];
      final yKnots = [0.2, 0.6, 0.8];

      // Lower bound (clips to leftmost y)
      expect(ScoringEngine.isotonicInterpolate(0.05, xKnots, yKnots), 0.2);

      // Upper bound (clips to rightmost y)
      expect(ScoringEngine.isotonicInterpolate(0.95, xKnots, yKnots), 0.8);

      // Exact knot
      expect(ScoringEngine.isotonicInterpolate(0.5, xKnots, yKnots), 0.6);

      // Linear interpolation between 0.1 and 0.5 (midpoint 0.3 should be 0.4)
      expect(ScoringEngine.isotonicInterpolate(0.3, xKnots, yKnots), closeTo(0.4, 0.0001));

      // Linear interpolation between 0.5 and 0.9 (midpoint 0.7 should be 0.7)
      expect(ScoringEngine.isotonicInterpolate(0.7, xKnots, yKnots), closeTo(0.7, 0.0001));
    });

    test('scorePillars() enforces P5 KYC Gate', () {
      List<double> features = List.filled(115, 0.8);
      
      // Force failure on Aadhaar (f[49])
      features[49] = 0.4;
      features[50] = 0.8;
      
      var scores = ScoringEngine.scorePillars(features);
      expect(scores['P5'], 0.0);

      // Force failure on PAN (f[50])
      features[49] = 0.8;
      features[50] = 0.4;
      
      scores = ScoringEngine.scorePillars(features);
      expect(scores['P5'], 0.0);

      // Both valid
      features[49] = 0.8;
      features[50] = 0.8;
      scores = ScoringEngine.scorePillars(features);
      expect(scores['P5'], greaterThan(0.0));
    });

    test('calibrateScores() applies isotonic calibration only to ML pillars', () {
      final rawScores = {
        'P1': 0.3, 'P2': 0.7, 'P3': 0.5, 'P4': 0.8,
        'P5': 0.6, 'P6': 0.4, 'P7': 0.9, 'P8': 0.2
      };

      final calibrationKnots = {
        'P1': {'x_knots': [0.0, 1.0], 'y_knots': [0.1, 0.9]},
      };

      final calibrated = ScoringEngine.calibrateScores(rawScores, calibrationKnots);

      // P1 calibrated using [0.1, 0.9] -> 0.3 should map to 0.1 + 0.3*(0.8) = 0.34
      expect(calibrated['P1'], closeTo(0.34, 0.0001));

      // P5, P7, P8 remain untouched
      expect(calibrated['P5'], 0.6);
      expect(calibrated['P7'], 0.9);
      expect(calibrated['P8'], 0.2);
    });
  });
}
