# V3.0 Dev B — Data Models Spec (CORRECTED)

## All new/modified Dart data models for v3.0

---

## B1: MODIFY `models/score_report_model.dart`

```dart
class ScoreReportModel {
  // Core score
  final int finalScore;
  final String grade;
  final String riskBand;
  final String proofId;
  final DateTime generatedAt;
  final double overallConfidence;
  final double probability;
  final String workType;
  final double computeTimeMs;
  
  // 8 pillars
  final List<ScorePillarModel> pillars;
  
  // L1: Pillar contribution decomposition
  final Map<String, int> pillarContributions;
  
  // L2: SHAP factors
  final List<ShapFactorModel> topStrengths;
  final List<ShapFactorModel> topConcerns;
  
  // L3: Actionable items (3-tier tagged)
  final List<ActionableItem> actionableItems;
  
  // L4: Score trajectory (3 paths)
  final TrajectoryResult trajectory;
  
  // L8: Causal chains (on-device)
  final List<CausalChain> causalChains;
  
  // Conformal intervals
  final Map<String, ConformalInterval> conformalIntervals;
  
  // Suggestions (from actionable items)
  final List<String> tailoredSuggestions;
  
  // Server-enriched (nullable — filled when connected)
  String? llmExplanation;             // L10
  PeerCohortResult? peerCohort;       // L7
  EfsResult? efs;                     // L6
  DeltaShapResult? deltaShap;         // L9
}
```

---

## B2: MODIFY `models/score_pillar_model.dart`

```dart
class ScorePillarModel {
  final String code;            // "P1" ... "P8"
  final String title;           // "Income Stability"
  final String subtitle;        // "Earnings & growth"
  final int score;              // mapped to pillar max (e.g., 117/150)
  final int maxScore;           // pillar max (150, 125, 85, 90, 70, 70, 55, 55)
  final double rawScore;        // uncalibrated [0,1]
  final double calibratedScore; // after isotonic [0,1]
  final double? conformalLow;   // lower bound in pillar points
  final double? conformalHigh;  // upper bound in pillar points
  final double confidence;      // conformal confidence (0.5/0.75/1.0)
  final double weight;          // pillar weight (0.07-0.22)
  final double attention;       // from attention proxy
}
```

---

## B3: MODIFY `models/shap_factor_model.dart`

```dart
class ShapFactorModel {
  final String featureName;     // "health_insurance_active"
  final String displayName;     // "Health Insurance"
  final String pillar;          // "P6"
  final String pillarLabel;     // "Financial Resilience"
  final double impact;          // SHAP value (+ or -)
  final double featureValue;    // actual value [0,1]
  final double meanAbsShap;     // global importance
  final String? actionType;     // "immediate" / "behavioural" / "non_actionable"
  final String? actionText;     // "Upload health insurance document"
}
```

---

## B4: NEW `models/actionable_item.dart`

```dart
class ActionableItem {
  final String featureName;
  final String displayName;
  final String pillar;
  final String actionText;
  final String difficulty;       // "easy" | "medium" | "hard"
  final String horizon;          // "1-7 days" | "1-3 months"
  final int expectedGainPts;
  final double currentValue;
  final String actionType;       // "immediate" | "behavioural"
  final String fixCategory;      // "documentation" | "habit_change"
}
```

---

## B5: NEW `models/trajectory_result.dart`

```dart
class TrajectoryResult {
  final List<TrajectoryPath> paths;
}

class TrajectoryPath {
  final String label;             // "7-day quick wins"
  final List<ActionableItem> actions;
  final int projectedScore;
  final String projectedGrade;
  final String horizon;
}
```

---

## B6: NEW `models/causal_chain.dart`

```dart
class CausalChain {
  final String id;                // "high_emi_low_income"
  final String rootCause;         // "income_seasonality"
  final String chain;             // "Seasonal income drop → ..."
  final String userMessage;       // User-facing explanation
  final String fix;               // Suggested fix
}
```

---

## B7: NEW `models/conformal_interval.dart`

```dart
class ConformalInterval {
  final double low;
  final double high;
  final double halfWidth;
}
```

---

## B8: NEW `models/loan_decision_model.dart`

```dart
class LoanDecisionModel {
  final String decisionId;
  final String decision;           // "approved" | "rejected"
  final String? rejectionBucket;   // "hard_rule" | "affordability" | "ml_scored"
  final int? approvedAmount;
  final double? interestRate;      // risk-based
  final int? emi;
  final int? tenureMonths;
  final HardRulesResult hardRules;
  final AffordabilityResult affordability;
  final MlDecisionResult? mlDecision;
  final AanResult? aan;
  final List<CounterfactualPath> counterfactualPaths;
  final AlternativeOffer? alternativeOffer;
  final DateTime decidedAt;
}

class HardRulesResult {
  final bool pass;
  final List<String> failedRules;
}

class AffordabilityResult {
  final bool pass;
  final double dscr;
  final double postLoanEmiRatio;
  final double loanToIncome;
  final int proposedEmi;
}

class MlDecisionResult {
  final bool pass;
  final double probability;
  final double threshold;
}

class AanResult {
  final String primaryReason;
  final List<String> secondaryReasons;
  final List<String> fixableFactors;
  final List<String> regulatoryFactors;
  final String coolingOffReminder;
  final String grievanceContact;
}

class CounterfactualPath {
  final String type;     // "debt_reduction" | "documentation" | "amount_adjustment"
  final String change;
  final String effect;
  final String outcome;
}

class AlternativeOffer {
  final String productId;
  final String productName;
  final int maxAmount;
  final double interestRate;
}
```

---

## B9: NEW `models/kfs_model.dart`

```dart
class KfsModel {
  final String kfsId;
  final String productName;
  final String lender;
  final int principal;
  final double interestRateAnnual;
  final int tenureMonths;
  final int emi;
  final int totalInterest;
  final int totalRepayable;
  final int processingFee;
  final double processingFeePct;
  final int netDisbursement;
  final double annualPercentageRate;
  final Map<String, dynamic> penalties;
  final int coolingOffPeriodDays;
  final String grievanceOfficer;
  final DateTime generatedAt;
}
```

---

## B10: NEW `models/loan_product_model.dart`

```dart
class LoanProductModel {
  final String id;                // "emergency_micro"
  final String name;              // "Emergency Micro Loan"
  final List<int> amountRange;    // [5000, 25000]
  final int minScore;
  final List<int> tenureRange;    // [1, 3]
  final String useCase;
  final bool eligible;
  final double? interestRate;     // risk-based
  final int? maxEligibleAmount;   // pre-computed
  final double? discountFactor;
  final int? scoreGap;            // how many pts needed if ineligible
}
```

---

## B11: NEW Server-Enrichment Models (nullable)

```dart
class PeerCohortResult {
  final int cohortSize;
  final int highScorers;
  final List<CohortDifference> keyDifferences;
}

class EfsResult {
  final double score;
  final String label;
  final String? note;
}

class DeltaShapResult {
  final int previousScore;
  final int currentScore;
  final int scoreChange;
  final List<DeltaFactor> improved;
  final List<DeltaFactor> declined;
  final bool fullyExplained;
}

class DeltaFactor {
  final String displayName;
  final double delta;
  final String direction;
  final int scoreImpactPts;
}
```
