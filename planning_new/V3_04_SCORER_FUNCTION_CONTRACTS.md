# V3.0 Scorer Function Contracts (CORRECTED)

## On-Device Dart Scorer Signatures

Each scorer is the contract between Dev A (generates) and Dev B (imports and calls).

---

## ML Scorers (m2cgen auto-generated)

### P1 — Income Stability (LightGBM GBDT)
```dart
// File: app/lib/scoring/models/p1_scorer.dart
// AUTO-GENERATED from LightGBM model via m2cgen

/// Input: 17 doubles
///   [0-12]: P1 base features (avg_income, income_cv, growth_slope, ...)
///   [13-16]: Cross-pillar (income_debt_stress, debt_vulnerability, income_emi_coverage, income_trend_vs_debt)
/// Output: double in [0, 1] (raw P1 score)
double scoreP1(List<double> input) { ... }
```

### P2 — Payment Discipline (XGBoost GBDT)
```dart
// File: app/lib/scoring/models/p2_scorer.dart
// AUTO-GENERATED from XGBoost model via m2cgen

/// Input: 19 doubles
///   [0-14]: P2 base features (utility_ontime, emi_ontime, bounce_rate, ...)
///   [15-18]: Cross-pillar (consistent_earning_streak, income_payment_trend, platform_reliability, income_floor)
/// Output: double in [0, 1]
double scoreP2(List<double> input) { ... }
```

### P3 — Debt Management (XGBoost GBDT, depth=2)
```dart
// File: app/lib/scoring/models/p3_scorer.dart
// AUTO-GENERATED from XGBoost shallow model via m2cgen

/// Input: 13 doubles
///   [0-8]: P3 base features (emi_ratio, debt_count, dscr, ...)
///   [9-12]: Cross-pillar (income_debt_stress, debt_vulnerability, income_emi_coverage, income_trend_vs_debt)
/// Output: double in [0, 1]
double scoreP3(List<double> input) { ... }
```

### P4 — Savings Behaviour (LightGBM GBDT + interaction constraints)
```dart
// File: app/lib/scoring/models/p4_scorer.dart
// AUTO-GENERATED from LightGBM model via m2cgen

/// Input: 16 doubles
///   [0-11]: P4 base features (savings_balance, savings_rate, slope, ...)
///   [12-15]: Cross-pillar (payment_savings_alignment, buffer_payment, digital_savings, shock_resistance)
/// Output: double in [0, 1]
double scoreP4(List<double> input) { ... }
```

### P6 — Financial Resilience (ExtraTreesRegressor)
```dart
// File: app/lib/scoring/models/p6_scorer.dart
// AUTO-GENERATED from ExtraTrees model via m2cgen

/// Input: 14 doubles
///   [0-10]: P6 base features (health_ins, life_ins, accident_ins, ...)
///   [11-13]: Cross-pillar (shock_resistance, resilience_debt_mismatch, insurance_income_anchor)
/// Output: double in [0, 1]
double scoreP6(List<double> input) { ... }
```

---

## Rule-Based Scorecards (hand-written by Dev A)

### P5 — Work & Identity (Scorecard with KYC Gate)
```dart
// File: app/lib/scoring/models/scorecard_p5.dart
// HAND-WRITTEN — deterministic scorecard

/// Input: 18 doubles (indices 49-66)
/// KYC GATE: if input[0] (aadhaar) < 0.5 OR input[1] (pan) < 0.5 → return 0.0
/// Output: double in [0, 1]
double scoreP5(List<double> input) {
  if (input[0] < 0.5 || input[1] < 0.5) return 0.0;
  const w = [0.15,0.15,0.10,0.08,0.08,0.06,0.05,0.04,0.03,0.06,0.04,0.04,0.02,0.02,0.02,0.03,0.02,0.01];
  double s = 0.0;
  for (int i = 0; i < 18; i++) s += input[i] * w[i];
  return s.clamp(0.0, 1.0);
}
```

### P7 — Social Accountability (Scorecard)
```dart
// File: app/lib/scoring/models/scorecard_p7.dart
// HAND-WRITTEN — deterministic scorecard

/// Input: 10 doubles (indices 78-87)
/// Output: double in [0, 1]
double scoreP7(List<double> input) {
  const w = [0.15, 0.12, 0.10, 0.10, 0.08, 0.10, 0.08, 0.12, 0.10, 0.05];
  double s = 0.0;
  for (int i = 0; i < 10; i++) s += input[i] * w[i];
  return s.clamp(0.0, 1.0);
}
```

### P8 — Tax & Compliance (Scorecard)
```dart
// File: app/lib/scoring/models/scorecard_p8.dart
// HAND-WRITTEN — deterministic scorecard

/// Input: 7 doubles (indices 88-94)
/// Output: double in [0, 1]
double scoreP8(List<double> input) {
  const w = [0.25, 0.15, 0.20, 0.15, 0.10, 0.08, 0.07];
  double s = 0.0;
  for (int i = 0; i < 7; i++) s += input[i] * w[i];
  return s.clamp(0.0, 1.0);
}
```

---

## Meta-Learner (LR Dot-Product)

```dart
// File: app/lib/scoring/models/meta_learner_lr.dart

/// Input: 20 doubles
///   [0-7]: 8 calibrated pillar scores (P1-P8)
///   [8-15]: 8 conformal confidence values
///   [16-19]: 4 auto-selected cross-pillar features
/// coefficients: 20 doubles from meta_lr_coefficients.json
/// intercept: double from meta_lr_coefficients.json
/// Output: probability [0, 1] (sigmoid)
double predictMeta(List<double> input, List<double> coefficients, double intercept) {
  assert(input.length == 20);
  assert(coefficients.length == 20);
  double z = intercept;
  for (int i = 0; i < 20; i++) z += input[i] * coefficients[i];
  return 1.0 / (1.0 + math.exp(-z));
}
```

---

## Score Mapping Utilities

```dart
// File: app/lib/scoring/models/scoring_constants.dart

int probabilityToScore(double p) => (p * 600 + 300).round().clamp(300, 900);

String scoreToGrade(int s) {
  if (s >= 800) return 'A+';
  if (s >= 750) return 'A';
  if (s >= 700) return 'B+';
  if (s >= 650) return 'B';
  if (s >= 600) return 'C+';
  if (s >= 550) return 'C';
  return 'D';
}

String scoreToRiskLevel(int s) {
  if (s >= 700) return 'Low';
  if (s >= 550) return 'Medium';
  return 'High';
}
```

---

## Dev B Calling Convention

```dart
// In scoring_engine.dart — exact slice construction
'P1': p1.scoreP1([...f.sublist(0, 13), f[95], f[96], f[97], f[98]]),
'P2': p2.scoreP2([...f.sublist(13, 28), f[105], f[106], f[107], f[108]]),
'P3': p3.scoreP3([...f.sublist(28, 37), f[95], f[96], f[97], f[98]]),
'P4': p4.scoreP4([...f.sublist(37, 49), f[99], f[100], f[101], f[102]]),
'P5': p5.scoreP5(f.sublist(49, 67)),
'P6': p6.scoreP6([...f.sublist(67, 78), f[102], f[103], f[104]]),
'P7': p7.scoreP7(f.sublist(78, 88)),
'P8': p8.scoreP8(f.sublist(88, 95)),
```

> ⚠️ Cross-pillar features are APPENDED to the base feature slice. The order must match training.
