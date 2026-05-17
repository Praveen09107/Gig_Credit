class CausalTrigger {
  final int featureIndex;
  final String operator;
  final double threshold;

  const CausalTrigger({
    required this.featureIndex,
    required this.operator,
    required this.threshold,
  });

  factory CausalTrigger.fromJson(Map<String, dynamic> json) {
    return CausalTrigger(
      featureIndex: json['feature_index'] as int,
      operator: json['operator'] as String,
      threshold: (json['threshold'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'feature_index': featureIndex,
    'operator': operator,
    'threshold': threshold,
  };
}

class CausalRule {
  final String ruleId;
  final String name;
  final List<CausalTrigger> triggers;
  final String triggerLogic;
  final String rootCause;
  final String causalChain;
  final String applicantMessage;
  final bool actionable;
  final String actionText;
  final String pillarAffected;
  final List<String> workTypes;

  const CausalRule({
    required this.ruleId,
    required this.name,
    required this.triggers,
    required this.triggerLogic,
    required this.rootCause,
    required this.causalChain,
    required this.applicantMessage,
    required this.actionable,
    required this.actionText,
    required this.pillarAffected,
    required this.workTypes,
  });

  factory CausalRule.fromJson(Map<String, dynamic> json) {
    return CausalRule(
      ruleId: json['rule_id'] as String? ?? 'mock_rule_id',
      name: json['name'] as String? ?? json['rule'] as String? ?? 'Mock Rule',
      triggers: json.containsKey('triggers')
          ? (json['triggers'] as List)
              .map((t) => CausalTrigger.fromJson(t as Map<String, dynamic>))
              .toList()
          : [],
      triggerLogic: json['trigger_logic'] as String? ?? 'AND',
      rootCause: json['root_cause'] as String? ?? 'Unknown Root Cause',
      causalChain: json['causal_chain'] as String? ?? json['suggestion'] as String? ?? 'No chain provided',
      applicantMessage: json['applicant_message'] as String? ?? 'No message provided',
      actionable: json['actionable'] as bool? ?? false,
      actionText: json['action_text'] as String? ?? json['suggestion'] as String? ?? '',
      pillarAffected: json['pillar_affected'] as String? ?? 'Unknown',
      workTypes: List<String>.from(json['work_types'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'rule_id': ruleId,
    'name': name,
    'triggers': triggers.map((t) => t.toJson()).toList(),
    'trigger_logic': triggerLogic,
    'root_cause': rootCause,
    'causal_chain': causalChain,
    'applicant_message': applicantMessage,
    'actionable': actionable,
    'action_text': actionText,
    'pillar_affected': pillarAffected,
    'work_types': workTypes,
  };

  // Convenience getters for XAI display
  String get patternId => ruleId;

  /// Parse causalChain text into displayable steps
  List<CausalStep> get steps {
    final parts = causalChain.split(' → ');
    if (parts.length <= 1) {
      // Single-block chain: split on '.' for multi-sentence
      return [
        CausalStep(label: rootCause, detail: causalChain),
      ];
    }
    return parts.map((p) => CausalStep(label: p.trim(), detail: '')).toList();
  }

  String get rootFix => actionText.isNotEmpty ? actionText : applicantMessage;

  int get estimatedGain {
    // Estimate from number of triggers × 12 pts
    return triggers.length * 12;
  }
}

class CausalStep {
  final String label;
  final String detail;
  const CausalStep({required this.label, required this.detail});
}
