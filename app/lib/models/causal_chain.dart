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
      ruleId: json['rule_id'] as String,
      name: json['name'] as String,
      triggers: (json['triggers'] as List)
          .map((t) => CausalTrigger.fromJson(t as Map<String, dynamic>))
          .toList(),
      triggerLogic: json['trigger_logic'] as String,
      rootCause: json['root_cause'] as String,
      causalChain: json['causal_chain'] as String,
      applicantMessage: json['applicant_message'] as String,
      actionable: json['actionable'] as bool? ?? false,
      actionText: json['action_text'] as String? ?? '',
      pillarAffected: json['pillar_affected'] as String? ?? '',
      workTypes: List<String>.from(json['work_types'] as List? ?? []),
    );
  }
}
