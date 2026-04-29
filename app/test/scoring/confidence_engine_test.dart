import 'package:flutter_test/flutter_test.dart';
import 'package:gigcredit/scoring/engine/confidence_engine.dart';

void main() {
  group('ConfidenceEngine', () {
    test('computeConfidence() correctly maps interval widths to tiers', () {
      final conformalIntervals = {
        'platform_worker': {
          'P1': {'half_width': 0.05}, // width 0.10 -> <= 0.12 -> HIGH 1.0
          'P2': {'half_width': 0.08}, // width 0.16 -> <= 0.20 -> MEDIUM 0.75
          'P3': {'half_width': 0.12}, // width 0.24 -> > 0.20 -> LOW 0.50
        }
      };

      final confidences = ConfidenceEngine.computeConfidence('platform_worker', conformalIntervals);

      expect(confidences['P1'], 1.0);
      expect(confidences['P2'], 0.75);
      expect(confidences['P3'], 0.50);

      // Scorecard pillars always get 1.0
      expect(confidences['P5'], 1.0);
      expect(confidences['P7'], 1.0);
      expect(confidences['P8'], 1.0);
    });

    test('adjustScores() pulls scores toward 0.50 based on confidence', () {
      final scores = {'P1': 0.9, 'P2': 0.9, 'P3': 0.9};
      final confidences = {'P1': 1.0, 'P2': 0.75, 'P3': 0.50};

      final adjusted = ConfidenceEngine.adjustScores(scores, confidences);

      // 1.0 confidence -> no change
      expect(adjusted['P1'], 0.9);

      // 0.75 confidence -> 0.9 * 0.75 + 0.5 * 0.25 = 0.675 + 0.125 = 0.8
      expect(adjusted['P2'], closeTo(0.8, 0.0001));

      // 0.50 confidence -> 0.9 * 0.50 + 0.5 * 0.50 = 0.45 + 0.25 = 0.7
      expect(adjusted['P3'], closeTo(0.7, 0.0001));
    });
  });
}
