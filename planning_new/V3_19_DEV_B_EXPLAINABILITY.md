# V3.0 Dev B — On-Device Explainability (CORRECTED — 4 Layers)

## Old spec was WRONG — had L1 SHAP, L2 Attention, L6 Actions
## Correct: L1 Decomposition, L2 Enhanced SHAP, L3 Actionable Tagging, L4 Trajectory

---

## L1 — Pillar Contribution Decomposition (Always Available)

### File: `app/lib/scoring/explainability/layer1_pillar_decomp.dart`

**Pure arithmetic — no SHAP, no lookups, zero external files.**

```dart
class Layer1PillarDecomposition {
  /// Decompose final score into per-pillar point contributions
  /// Returns waterfall: {"P1": 142, "P2": 118, ..., "floor": 300}
  static Map<String, int> decompose({
    required Map<String, double> adjustedPillars,
    required Map<String, double> pillarWeights,
    required List<double> metaCoefficients,
    required int finalScore,
  }) {
    final scoreAboveFloor = finalScore - 300;
    
    // Raw contribution = adjusted_score × weight × meta_coefficient
    double totalContrib = 0.0;
    final rawContribs = <String, double>{};
    int pillarIdx = 0;
    for (final code in ['P1','P2','P3','P4','P5','P6','P7','P8']) {
      final contrib = (adjustedPillars[code] ?? 0.4) *
                      (pillarWeights[code] ?? 0.1) *
                      metaCoefficients[pillarIdx];
      rawContribs[code] = contrib;
      totalContrib += contrib;
      pillarIdx++;
    }
    
    // Normalise to score points
    final pointContribs = <String, int>{};
    for (final code in rawContribs.keys) {
      pointContribs[code] = (rawContribs[code]! / totalContrib * scoreAboveFloor).round();
    }
    pointContribs['floor'] = 300;
    
    return pointContribs;
  }
}
```

**User sees**: Stacked waterfall bar chart showing each pillar's point contribution.

---

## L2 — Enhanced SHAP Lookup (Always Available)

### File: `app/lib/scoring/explainability/layer2_shap_lookup.dart`

**Uses `shap_lookup_v3.json` — 20-bin, work-type-aware, 115 features.**

```dart
class Layer2ShapLookup {
  final Map<String, dynamic> _lookup;
  Layer2ShapLookup(this._lookup);
  
  ShapResult analyze(
    List<double> features,
    List<String> featureNames,
    String workType,
  ) {
    final impacts = <ShapImpact>[];
    
    for (int i = 0; i < featureNames.length; i++) {
      final entry = _lookup[featureNames[i]];
      if (entry == null) continue;
      
      // Get work-type-specific SHAP bins
      final shapByWt = entry['shap_by_work_type'] as Map<String, dynamic>;
      final shapValues = List<double>.from(
        shapByWt[workType] ?? shapByWt['platform_worker']!
      );
      
      // 20 bins: edges at 0.0, 0.05, ..., 1.0
      final binIdx = (features[i] * 20).floor().clamp(0, 19);
      final impact = shapValues[binIdx];
      
      impacts.add(ShapImpact(
        featureName: featureNames[i],
        displayName: (entry['display_name'] as String?) ?? featureNames[i],
        pillar: entry['pillar'] as String,
        pillarLabel: (entry['pillar_label'] as String?) ?? '',
        impact: impact,
        featureValue: features[i],
        meanAbsShap: (entry['mean_abs_shap'] as num).toDouble(),
      ));
    }
    
    impacts.sort((a, b) => b.impact.abs().compareTo(a.impact.abs()));
    
    // Pillar-level SHAP aggregation (sum feature SHAPs per pillar)
    final pillarShap = <String, double>{};
    for (final imp in impacts) {
      pillarShap[imp.pillar] = (pillarShap[imp.pillar] ?? 0.0) + imp.impact;
    }
    
    return ShapResult(
      positives: impacts.where((f) => f.impact > 0).take(5).toList(),
      negatives: impacts.where((f) => f.impact < 0).take(5).toList(),
      perPillarShap: pillarShap,
      allImpacts: impacts,
    );
  }
}
```

---

## L3 — Actionable / Non-Actionable Tagging (Always Available)

### File: `app/lib/scoring/explainability/layer3_actionable.dart`

**Uses `actionability_tags.json` — 3-tier tagging, 115 entries.**

```dart
class Layer3Actionable {
  final Map<String, dynamic> _tags;
  Layer3Actionable(this._tags);
  
  List<ActionableItem> getActions(
    List<double> features,
    List<String> featureNames,
    List<ShapImpact> negativeShaps,
  ) {
    final actions = <ActionableItem>[];
    
    for (final shap in negativeShaps) {
      final tag = _tags[shap.featureName];
      if (tag == null) continue;
      
      final actionType = tag['actionable'] as String;
      
      // 🔴 Non-actionable: NEVER show as improvement suggestion
      if (actionType == 'non_actionable') continue;
      
      // 🟢 Immediate or 🟡 Behavioural: show action card
      if (features[featureNames.indexOf(shap.featureName)] >= 0.7) continue; // already good
      
      actions.add(ActionableItem(
        featureName: shap.featureName,
        displayName: shap.displayName,
        pillar: tag['pillar'] ?? shap.pillar,
        actionText: tag['action_text'] ?? '',
        difficulty: tag['difficulty'] ?? 'medium',
        horizon: tag['horizon'] ?? '',
        expectedGainPts: (tag['expected_gain_pts'] as num?)?.toInt() ?? 0,
        currentValue: features[featureNames.indexOf(shap.featureName)],
        actionType: actionType, // "immediate" or "behavioural"
        fixCategory: tag['fix_category'] ?? '',
      ));
    }
    
    // Sort: 🟢 immediate first, then 🟡 behavioural, then by gain
    actions.sort((a, b) {
      final typeCmp = _actionTypeRank(a.actionType).compareTo(_actionTypeRank(b.actionType));
      if (typeCmp != 0) return typeCmp;
      return b.expectedGainPts.compareTo(a.expectedGainPts);
    });
    
    return actions.take(8).toList();
  }
  
  int _actionTypeRank(String type) => type == 'immediate' ? 0 : 1;
}
```

---

## L4 — Score Trajectory Simulation (Always Available)

### File: `app/lib/scoring/explainability/layer4_trajectory.dart`

**Projects 3 future score paths from actionable SHAP values.**

```dart
class Layer4Trajectory {
  static TrajectoryResult simulate({
    required int currentScore,
    required String currentGrade,
    required List<ActionableItem> actions,
    required Map<String, double> metaCoefficients,
  }) {
    // Path 1: Only 🟢 immediate actions (days)
    final immediatePts = actions
        .where((a) => a.actionType == 'immediate')
        .take(3)
        .fold(0, (sum, a) => sum + a.expectedGainPts);
    
    // Path 2: Immediate + top 2 behavioural (months)
    final behaviouralPts = actions
        .where((a) => a.actionType == 'behavioural')
        .take(2)
        .fold(0, (sum, a) => sum + a.expectedGainPts);
    
    // Path 3: All top 5 actions (6+ months)
    final allPts = actions.take(5).fold(0, (sum, a) => sum + a.expectedGainPts);
    
    return TrajectoryResult(
      paths: [
        TrajectoryPath(
          label: '7-day quick wins',
          actions: actions.where((a) => a.actionType == 'immediate').take(3).toList(),
          projectedScore: (currentScore + immediatePts).clamp(300, 900),
          projectedGrade: scoreToGrade(currentScore + immediatePts),
          horizon: '7 days',
        ),
        TrajectoryPath(
          label: '1-3 month improvement',
          actions: actions.take(5).toList(),
          projectedScore: (currentScore + immediatePts + behaviouralPts).clamp(300, 900),
          projectedGrade: scoreToGrade(currentScore + immediatePts + behaviouralPts),
          horizon: '1-3 months',
        ),
        TrajectoryPath(
          label: 'Full potential',
          actions: actions.take(8).toList(),
          projectedScore: (currentScore + allPts).clamp(300, 900),
          projectedGrade: scoreToGrade(currentScore + allPts),
          horizon: '6+ months',
        ),
      ],
    );
  }
}
```

---

## L8 On-Device — Causal Chain Rules (Always Available)

### File: `app/lib/scoring/explainability/layer8_causal_rules.dart`

**Uses `causal_chains.json` — 15 pre-defined patterns.**

```dart
class Layer8CausalRules {
  final List<dynamic> _rules;
  Layer8CausalRules(this._rules);
  
  List<CausalChain> check(List<double> features, String workType) {
    final matched = <CausalChain>[];
    
    for (final rule in _rules) {
      final conditions = rule['trigger_conditions'] as List;
      final applicable = rule['applicable_work_types'] as List;
      
      // Check work type applicability
      if (!applicable.contains('all') && !applicable.contains(workType)) continue;
      
      // Check all trigger conditions
      bool allMet = true;
      for (final cond in conditions) {
        final idx = cond['index'] as int;
        final op = cond['op'] as String;
        final val = (cond['value'] as num).toDouble();
        if (op == '<' && features[idx] >= val) { allMet = false; break; }
        if (op == '>' && features[idx] <= val) { allMet = false; break; }
      }
      
      if (allMet) {
        matched.add(CausalChain(
          id: rule['id'],
          rootCause: rule['root_cause'],
          chain: rule['chain'],
          userMessage: rule['user_message'],
          fix: rule['fix'],
        ));
      }
    }
    
    return matched.take(3).toList(); // Max 3 causal chains
  }
}
```

---

## Explanation Bundle — Combines L1 + L2 + L3 + L4 + L8(on-device)

### File: `app/lib/scoring/explainability/explanation_bundle.dart`

```dart
class ExplanationBundle {
  final Map<String, int> pillarContributions;     // L1
  final List<ShapImpact> topStrengths;            // L2 positive
  final List<ShapImpact> topConcerns;             // L2 negative
  final Map<String, double> perPillarShap;        // L2 aggregated
  final List<ActionableItem> actions;              // L3 tagged
  final TrajectoryResult trajectory;               // L4 projections
  final List<CausalChain> causalChains;           // L8 on-device rules
  final double computeTimeMs;

  static ExplanationBundle compute({
    required List<double> features,
    required List<String> featureNames,
    required String workType,
    required Map<String, double> adjustedPillars,
    required Map<String, double> pillarWeights,
    required List<double> metaCoefficients,
    required int finalScore,
    required String grade,
    required Map<String, dynamic> shapLookup,
    required Map<String, dynamic> actionTags,
    required List<dynamic> causalRules,
  }) {
    final sw = Stopwatch()..start();
    
    // L1: Pillar decomposition
    final contribs = Layer1PillarDecomposition.decompose(
      adjustedPillars: adjustedPillars,
      pillarWeights: pillarWeights,
      metaCoefficients: metaCoefficients,
      finalScore: finalScore,
    );
    
    // L2: Enhanced SHAP lookup
    final l2 = Layer2ShapLookup(shapLookup);
    final shapResult = l2.analyze(features, featureNames, workType);
    
    // L3: Actionable tagging (uses L2 negative SHAPs)
    final l3 = Layer3Actionable(actionTags);
    final actions = l3.getActions(features, featureNames, shapResult.negatives);
    
    // L4: Score trajectory
    final trajectory = Layer4Trajectory.simulate(
      currentScore: finalScore,
      currentGrade: grade,
      actions: actions,
      metaCoefficients: pillarWeights,
    );
    
    // L8: Causal chain rules (on-device)
    final l8 = Layer8CausalRules(causalRules);
    final causalChains = l8.check(features, workType);
    
    sw.stop();
    
    return ExplanationBundle(
      pillarContributions: contribs,
      topStrengths: shapResult.positives,
      topConcerns: shapResult.negatives,
      perPillarShap: shapResult.perPillarShap,
      actions: actions,
      trajectory: trajectory,
      causalChains: causalChains,
      computeTimeMs: sw.elapsedMicroseconds / 1000.0,
    );
  }
}
```

### Performance Target
- Total L1+L2+L3+L4+L8 < 8ms on device
