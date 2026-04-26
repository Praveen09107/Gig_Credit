# ================================================================================
# GIGCREDIT — COMPONENT: SHAP EXPLAINABILITY ENGINE
# Document 21 | planning_new
# ================================================================================

## 1. SHAP LOOKUP ARCHITECTURE

SHAP values are pre-computed during offline ML training and bundled as a JSON asset.
At runtime, the app performs a simple bin-based lookup — NO heavy computation.

### Input: 95-element feature vector
### Output: Top 3 positive + Top 3 negative factors with human labels

---

## 2. SHAP LOOKUP JSON FORMAT

```json
{
  "income_to_anchor_ratio": {
    "bins": [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0],
    "shap_values": [-0.12, -0.08, -0.04, 0.0, 0.02, 0.05, 0.10, 0.15, 0.18, 0.22],
    "pillar": "income_stability",
    "label": "Income relative to regional average"
  },
  "emi_to_income_ratio": {
    "bins": [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0],
    "shap_values": [0.20, 0.15, 0.10, 0.05, 0.0, -0.05, -0.10, -0.15, -0.18, -0.22],
    "pillar": "debt_management",
    "label": "EMI payments relative to income"
  }
}
```

---

## 3. LOOKUP ALGORITHM (Dart)

```dart
int _findBin(double value, List<double> bins) {
  for (int i = 0; i < bins.length - 1; i++) {
    if (value >= bins[i] && value < bins[i + 1]) return i;
  }
  return bins.length - 2; // last bin if value == 1.0
}
```

---

## 4. FEATURE LABEL MAPPING

Every feature has a human-readable label for display:

| Feature Name                 | Label (Positive Context)                    | Label (Negative Context)                    |
|-----------------------------|---------------------------------------------|---------------------------------------------|
| income_to_anchor_ratio      | Income above regional average               | Income below regional average               |
| income_stability_cv         | Consistent monthly income                   | Irregular monthly income                    |
| electricity_on_time_ratio   | Electricity bills paid on time              | Late electricity bill payments              |
| emi_to_income_ratio         | Low EMI burden                              | High EMI burden relative to income          |
| health_insurance_active     | Active health insurance coverage            | No health insurance coverage                |
| avg_balance_normalized      | Healthy bank balance maintained             | Low bank balance                            |
| savings_rate                | Good savings rate                           | Low monthly savings rate                    |
| eshram_registered           | Registered with e-Shram                     | Not registered with e-Shram                 |
| itr_filed                   | Income tax returns filed                    | No income tax returns filed                 |
| face_match_score            | Strong identity verification                | Weak identity verification                  |
| ... (all 95 features)       |                                             |                                             |

---

## 5. SHAP OUTPUT STRUCTURE

```dart
class ShapResult {
  final List<ShapFactor> positiveFactors; // top 3 by positive impact
  final List<ShapFactor> negativeFactors; // top 3 by negative impact
}

class ShapFactor {
  final String featureName;    // "income_stability_cv"
  final String label;          // "Consistent monthly income"
  final String pillar;         // "Income Stability"
  final double impact;         // +15 or -18
  final String icon;           // "📈" or "📉"
}
```

---

## 6. SHAP IS EXPLANATION ONLY

> **CRITICAL**: SHAP values do NOT affect the credit score in any way.
> The score is computed solely by the pillar models + meta-learner.
> SHAP is for USER EDUCATION only — helping them understand their score.
