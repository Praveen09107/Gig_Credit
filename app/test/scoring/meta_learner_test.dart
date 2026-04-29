import 'package:flutter_test/flutter_test.dart';
import 'package:gigcredit/scoring/engine/meta_learner.dart';

void main() {
  group('MetaLearner', () {
    test('predict() calculates correct sigmoid dot product', () {
      final calibratedScores = {'P1': 0.5, 'P2': 0.5, 'P3': 0.5, 'P4': 0.5, 'P5': 0.5, 'P6': 0.5, 'P7': 0.5, 'P8': 0.5};
      final confidences = {'P1': 1.0, 'P2': 1.0, 'P3': 1.0, 'P4': 1.0, 'P5': 1.0, 'P6': 1.0, 'P7': 1.0, 'P8': 1.0};
      final features = List.filled(115, 0.5);
      
      final metaJson = {
        'coefficients': List.filled(20, 1.0), // 20 ones
        'intercept': -10.0,
        'top4_cross_pillar_indices': [95, 96, 97, 98]
      };

      // Vector is 8 scores (0.5), 8 confidences (1.0), 4 features (0.5)
      // Dot product: (8 * 0.5) + (8 * 1.0) + (4 * 0.5) = 4 + 8 + 2 = 14
      // z = 14 + intercept(-10) = 4
      // sigmoid(4) = 1 / (1 + exp(-4)) ≈ 0.98201

      final prob = MetaLearner.predict(calibratedScores, confidences, features, metaJson);
      expect(prob, closeTo(0.9820, 0.0001));
    });

    test('predict() throws if coefficients length is not 20', () {
      final metaJson = {
        'coefficients': List.filled(19, 1.0), // Invalid length
        'intercept': 0.0,
        'top4_cross_pillar_indices': [95, 96, 97, 98]
      };

      expect(
        () => MetaLearner.predict({}, {}, List.filled(115, 0.0), metaJson),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
