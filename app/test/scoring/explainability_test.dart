import 'package:flutter_test/flutter_test.dart';
import 'package:gigcredit/models/shap_factor_model.dart';
import 'package:gigcredit/scoring/explainability/layer1_pillar_decomp.dart';
import 'package:gigcredit/scoring/explainability/layer2_shap_lookup.dart';
import 'package:gigcredit/scoring/explainability/layer3_actionable.dart';
import 'package:gigcredit/scoring/explainability/layer8_causal_rules.dart';
import 'package:gigcredit/models/actionable_item.dart';

void main() {
  group('Layer 1: Pillar Decomp', () {
    test('computeContributions() normalises points to exactly sum to (finalScore - 300)', () {
      final adjustedScores = {
        'P1': 0.8, 'P2': 0.6, 'P3': 0.7, 'P4': 0.5,
        'P5': 0.9, 'P6': 0.4, 'P7': 0.8, 'P8': 0.9
      };
      final weightsJson = {
        'P1': 0.2, 'P2': 0.2, 'P3': 0.1, 'P4': 0.1,
        'P5': 0.1, 'P6': 0.1, 'P7': 0.1, 'P8': 0.1
      };
      final metaJson = {
        'coefficients': List.filled(20, 1.0)
      };

      final finalScore = 650; // points to distribute = 350
      final contribs = Layer1PillarDecomp.computeContributions(finalScore, adjustedScores, weightsJson, metaJson);

      int sum = contribs.values.reduce((a, b) => a + b);
      expect(sum, 350);
    });
  });

  group('Layer 3: Actionable Tagging', () {
    test('generateActionableItems() filters non_actionable and sorts properly', () {
      final concerns = [
        ShapFactorModel(featureName: 'f1', description: '', direction: 'negative', impactStrength: 0.05, pillarLabel: 'P1', actionType: ActionabilityTier.immediate),
        ShapFactorModel(featureName: 'f2', description: '', direction: 'negative', impactStrength: 0.10, pillarLabel: 'P2', actionType: ActionabilityTier.nonActionable),
        ShapFactorModel(featureName: 'f3', description: '', direction: 'negative', impactStrength: 0.08, pillarLabel: 'P3', actionType: ActionabilityTier.behavioural),
        ShapFactorModel(featureName: 'f4', description: '', direction: 'negative', impactStrength: 0.02, pillarLabel: 'P4', actionType: ActionabilityTier.immediate),
      ];

      final actionabilityJson = {
        'f1': {'actionable': 'immediate', 'expected_gain_pts': 10, 'pillar': 'P1', 'action_text': 'Do f1'},
        'f2': {'actionable': 'non_actionable', 'expected_gain_pts': 50, 'pillar': 'P2', 'action_text': 'Do f2'},
        'f3': {'actionable': 'behavioural', 'expected_gain_pts': 20, 'pillar': 'P3', 'action_text': 'Do f3'},
        'f4': {'actionable': 'immediate', 'expected_gain_pts': 15, 'pillar': 'P4', 'action_text': 'Do f4'},
      };

      final actions = Layer3Actionable.generateActionableItems(concerns, actionabilityJson);

      // Should filter out f2 completely.
      expect(actions.length, 3);
      expect(actions.any((a) => a.featureName == 'f2'), false);

      // Sort order should be: immediate > behavioural. Within immediate: gain desc.
      // 1. f4 (immediate, 15)
      // 2. f1 (immediate, 10)
      // 3. f3 (behavioural, 20)
      expect(actions[0].featureName, 'f4');
      expect(actions[1].featureName, 'f1');
      expect(actions[2].featureName, 'f3');
    });
  });

  group('Layer 8: Causal Rules', () {
    test('evaluateRule() exactly implements the <= >= < > JSON logic', () {
      final features = List.filled(115, 0.5);
      features[1] = 0.8; // income_cv is high
      features[28] = 0.6; // emi_ratio is high

      final causalChainsJson = [
        {
          'rule_id': 'high_emi_low_income',
          'name': 'High EMI',
          'root_cause': 'Volatility',
          'causal_chain': 'X -> Y',
          'applicant_message': 'Warning',
          'action_text': 'Fix this',
          'work_types': ['all'],
          'trigger_logic': 'AND',
          'triggers': [
            {'feature_index': 1, 'operator': '>=', 'threshold': 0.75},
            {'feature_index': 28, 'operator': '>', 'threshold': 0.50}
          ]
        },
        {
          'rule_id': 'should_fail',
          'name': 'Should fail',
          'root_cause': 'Test',
          'causal_chain': 'X -> Y',
          'applicant_message': 'Warning',
          'action_text': 'Fix this',
          'work_types': ['all'],
          'trigger_logic': 'AND',
          'triggers': [
            {'feature_index': 1, 'operator': '<', 'threshold': 0.75},
          ]
        }
      ];

      final matches = Layer8CausalRules.evaluate(features, 'platform_worker', causalChainsJson);

      expect(matches.length, 1);
      expect(matches[0].ruleId, 'high_emi_low_income');
    });
  });
}
