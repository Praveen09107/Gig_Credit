import '../../models/shap_factor_model.dart';
import '../../models/actionable_item.dart';
import '../../models/trajectory_result.dart';
import '../../models/causal_chain.dart';

import 'layer1_pillar_decomp.dart';
import 'layer2_shap_lookup.dart';
import 'layer3_actionable.dart';
import 'layer4_trajectory.dart';
import 'layer8_causal_rules.dart';

class ExplanationBundle {
  final Map<String, int> pillarContributions;
  final List<ShapFactorModel> topStrengths;
  final List<ShapFactorModel> topConcerns;
  final List<ActionableItem> actions;
  final TrajectoryResult trajectory;
  final List<CausalRule> causalChains;
  final int computeTimeMs;

  ExplanationBundle({
    required this.pillarContributions,
    required this.topStrengths,
    required this.topConcerns,
    required this.actions,
    required this.trajectory,
    required this.causalChains,
    required this.computeTimeMs,
  });

  /// Master function that runs all On-Device XAI layers
  static ExplanationBundle compute({
    required int finalScore,
    required Map<String, double> adjustedScores,
    required List<double> features,
    required String workType,
    required Map<String, dynamic> weightsJson,
    required Map<String, dynamic> metaJson,
    required Map<String, dynamic> shapLookupJson,
    required Map<String, dynamic> displayNamesJson,
    required Map<String, dynamic> actionabilityJson,
    required List<dynamic> causalChainsJsonList,
  }) {
    final stopwatch = Stopwatch()..start();

    // L1: Pillar Decomp
    var pillarContributions = Layer1PillarDecomp.computeContributions(
      finalScore,
      adjustedScores,
      weightsJson,
      metaJson,
    );

    // L2: SHAP Lookup
    var shapResults = Layer2ShapLookup.computeShap(
      features,
      workType,
      shapLookupJson,
      displayNamesJson,
      actionabilityJson,
    );
    List<ShapFactorModel> strengths = shapResults['topStrengths'];
    List<ShapFactorModel> concerns = shapResults['topConcerns'];

    // L3: Actionable Tagging
    List<ActionableItem> actions = Layer3Actionable.generateActionableItems(
      concerns,
      actionabilityJson,
    );

    // L4: Trajectory
    TrajectoryResult trajectory = Layer4Trajectory.simulate(finalScore, actions);

    // L8: Causal Chains
    List<CausalRule> causalChains = Layer8CausalRules.evaluate(
      features,
      workType,
      causalChainsJsonList,
    );

    stopwatch.stop();

    return ExplanationBundle(
      pillarContributions: pillarContributions,
      topStrengths: strengths,
      topConcerns: concerns,
      actions: actions,
      trajectory: trajectory,
      causalChains: causalChains,
      computeTimeMs: stopwatch.elapsedMilliseconds,
    );
  }
}
