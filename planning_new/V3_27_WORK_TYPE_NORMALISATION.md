# V3.0 Work-Type Normalisation (Stage 1)

## Purpose
Before any feature enters a model, 5 income/volatility features are rescaled by work-type-specific medians. The same raw value means different things for different gig types.

## Example
A Freelancer with income CV = 0.55 is normal (project-based income varies).
A Platform Worker (Swiggy) with CV = 0.55 is worrying (daily deposits should be stable).
Without normalisation, both get the same penalty. With it, each is judged against their benchmark.

## JSON Constants: `work_type_medians.json`

```json
{
  "platform_worker": {
    "income_cv": 0.28,
    "income_growth_norm": 0.35,
    "gig_share_norm": 0.85,
    "payment_gap_freq": 0.12,
    "balance_variability": 0.22
  },
  "street_vendor": {
    "income_cv": 0.44,
    "income_growth_norm": 0.28,
    "gig_share_norm": 0.70,
    "payment_gap_freq": 0.22,
    "balance_variability": 0.31
  },
  "skilled_tradesperson": {
    "income_cv": 0.39,
    "income_growth_norm": 0.30,
    "gig_share_norm": 0.60,
    "payment_gap_freq": 0.19,
    "balance_variability": 0.26
  },
  "freelancer": {
    "income_cv": 0.61,
    "income_growth_norm": 0.40,
    "gig_share_norm": 0.55,
    "payment_gap_freq": 0.31,
    "balance_variability": 0.38
  }
}
```

## 5 Features Normalised

| Feature Index | Feature Name | Normalised By |
|--------------|-------------|--------------|
| 1 | `income_stability_cv` (F-P1-02) | work_type median CV |
| 2 | `income_growth_slope` (F-P1-03) | work_type income growth norm |
| 4 | `income_platform_verified_ratio` (F-P1-05) | work_type gig share norm |
| 28 | `emi_to_income_ratio` (F-P3-03) | work_type payment gap norm |
| 47 | `savings_growth_slope` (F-P4-05) | work_type balance variability |

## Dev A: Generate Medians During Training
```python
# In synthetic_data_generator.py, after generating profiles:
for wt in WORK_TYPES:
    subset = df[df['work_type'] == wt]
    medians[wt] = {
        'income_cv': float(subset['income_stability_cv'].median()),
        'income_growth_norm': float(subset['income_growth_slope'].median()),
        # ... etc
    }
json.dump(medians, open('output/assets/work_type_medians.json', 'w'))
```

## Dev B: Dart Implementation (in feature_engineer.dart)
```dart
// STAGE 1: Work-type normalisation — runs BEFORE feature array assembly
void normaliseByWorkType(List<double> features, String workType, Map<String, dynamic> medians) {
  final wt = medians[workType] ?? medians['platform_worker']!;
  
  features[1]  = (features[1]  / (wt['income_cv'] as double)).clamp(0.0, 2.0) / 2.0;
  features[2]  = (features[2]  / (wt['income_growth_norm'] as double)).clamp(0.0, 2.0) / 2.0;
  features[4]  = (features[4]  / (wt['gig_share_norm'] as double)).clamp(0.0, 2.0) / 2.0;
  features[28] = (features[28] / (wt['payment_gap_freq'] as double)).clamp(0.0, 2.0) / 2.0;
  features[47] = (features[47] / (wt['balance_variability'] as double)).clamp(0.0, 2.0) / 2.0;
}
```

## Pipeline Position
```
VerifiedProfile
  → FeatureEngineer.extract() → 95 features
  → normaliseByWorkType()      → 5 features rescaled (STAGE 1)
  → computeCrossPillar()       → 20 features added (STAGE 2)
  → ScoringEngine.scorePillars() → 8 raw pillar scores
  → ... rest of pipeline
```
