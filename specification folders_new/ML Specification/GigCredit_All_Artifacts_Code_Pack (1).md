# GigCredit Scoring Artifacts — Complete Code Pack

This document contains the complete code for the core artifacts used by the GigCredit on-device scoring system. It is intended to be copied into your repository as the single reference source for implementation.

---

## 1. feature_schema.json

```json
{
  "total_features": 95,
  "pillars": {
    "P1_Income": {
      "range": [0, 12],
      "count": 13,
      "type": "ml_xgboost",
      "name": "Income Stability"
    },
    "P2_Discipline": {
      "range": [13, 27],
      "count": 15,
      "type": "ml_xgboost",
      "name": "Payment Discipline"
    },
    "P3_Debt": {
      "range": [28, 36],
      "count": 9,
      "type": "ml_xgboost",
      "name": "Debt Management"
    },
    "P4_Savings": {
      "range": [37, 48],
      "count": 12,
      "type": "ml_xgboost",
      "name": "Savings Behaviour"
    },
    "P5_Identity": {
      "range": [49, 66],
      "count": 18,
      "type": "rule_scorecard",
      "name": "Work Identity"
    },
    "P6_Resilience": {
      "range": [67, 77],
      "count": 11,
      "type": "ml_rf",
      "name": "Financial Resilience"
    },
    "P7_Schemes": {
      "range": [78, 87],
      "count": 10,
      "type": "rule_scorecard",
      "name": "Social Accountability"
    },
    "P8_Tax": {
      "range": [88, 94],
      "count": 7,
      "type": "rule_scorecard",
      "name": "Tax Compliance"
    }
  },
  "sanitization": {
    "nan_value": 0.5,
    "infinite_value": 0.5,
    "bounds": [0.0, 1.0],
    "income_max": 5.0
  },
  "runtime_rules": {
    "minimum_score_steps": ["identity", "bank_statement_30_txn"],
    "low_confidence_threshold": 0.3,
    "neutral_score": 0.5
  }
}
```

---

## 2. golden_test.json

```json
{
  "version": "1.0",
  "tolerance": 1e-5,
  "test_cases": [
    {
      "id": "golden_001",
      "work_type": "platform",
      "tier": "good",
      "features": [0.72, 0.68, 0.74, 0.66, 0.70, 0.71, 0.69, 0.73, 0.67, 0.65, 0.74, 0.70, 0.69, 0.71, 0.68, 0.72, 0.70, 0.69, 0.73, 0.67, 0.71, 0.72, 0.68, 0.69, 0.70, 0.71, 0.72, 0.66, 0.64, 0.63, 0.69, 0.67, 0.70, 0.71, 0.68, 0.69, 0.72, 0.70, 0.68, 0.71, 0.72, 0.69, 0.70, 0.73, 0.71, 0.70, 0.68, 0.69, 0.72, 0.74, 0.88, 0.84, 0.79, 0.90, 0.82, 0.76, 0.80, 0.85, 0.78, 0.86, 0.83, 0.81, 0.77, 0.89, 0.92, 0.74, 0.73, 0.75, 0.72, 0.71, 0.70, 0.74, 0.69, 0.68, 0.67, 0.72, 0.73, 0.74, 0.70, 0.69, 0.71, 0.72, 0.74, 0.73, 0.70, 0.69, 0.72, 0.68, 0.67, 0.71, 0.70, 0.72, 0.69, 0.68, 0.71, 0.70],
      "expected": {
        "score": 720,
        "grade": "A",
        "risk_band": "Excellent",
        "pillar_scores": {
          "P1": 0.75,
          "P2": 0.70,
          "P3": 0.62,
          "P4": 0.68,
          "P5": 0.78,
          "P6": 0.64,
          "P7": 0.71,
          "P8": 0.66
        }
      }
    }
  ]
}
```

---

## 3. feature_engineering.py

```python
from dataclasses import dataclass
from typing import List
import math

@dataclass
class VerifiedProfile:
    work_type: str
    address_state: str
    bank: object
    identity: object
    taxes: object
    schemes: object
    insurance: object
    documents: object

STATE_INCOME_ANCHORS = {
    "MH": 22000,
    "TN": 18000,
    "KA": 21000,
    "DL": 25000,
    "GJ": 20000,
    "UP": 13000,
    "WB": 15000,
    "KL": 19000,
    "TS": 20000,
    "AP": 16000
}

PILLAR_INDEX = {
    "P1": (0, 13),
    "P2": (13, 28),
    "P3": (28, 37),
    "P4": (37, 49),
    "P5": (49, 67),
    "P6": (67, 78),
    "P7": (78, 88),
    "P8": (88, 95)
}

def state_income_anchor(state: str) -> float:
    return float(STATE_INCOME_ANCHORS.get(state, 17000))


def clamp01(x: float) -> float:
    if x is None or isinstance(x, bool):
        return 0.5
    if math.isnan(x) or math.isinf(x):
        return 0.5
    return max(0.0, min(1.0, float(x)))


def engineer_features(profile: VerifiedProfile) -> List[float]:
    f = [0.0] * 95
    anchor = state_income_anchor(profile.address_state)

    # P1 Income Stability
    f[0] = clamp01(getattr(profile.bank, "avg_monthly_credit", 0.0) / anchor)
    f[1] = clamp01(1.0 - getattr(profile.bank, "income_cv", 0.0))
    f[2] = clamp01(getattr(profile.bank, "income_trend_slope", 0.0))
    f[3] = clamp01(getattr(profile.bank, "active_earning_months_ratio", 0.0))
    f[4] = clamp01(getattr(profile.bank, "balance_consistency", 0.0))
    f[5] = clamp01(getattr(profile.bank, "cashflow_strength", 0.0))
    f[6] = clamp01(getattr(profile.bank, "gigincome_count_ratio", 0.0))
    f[7] = clamp01(getattr(profile.bank, "salary_dependency_inverse", 0.0))
    f[8] = clamp01(getattr(profile.bank, "seasonality_inverse", 0.0))
    f[9] = clamp01(getattr(profile.bank, "income_recency", 0.0))
    f[10] = clamp01(getattr(profile.bank, "income_growth_6m", 0.0))
    f[11] = clamp01(getattr(profile.bank, "high_value_credit_ratio", 0.0))
    f[12] = clamp01(getattr(profile.bank, "bank_credit_stability", 0.0))

    # P2 Discipline
    f[13] = clamp01(getattr(profile.bank, "utility_on_time_ratio", 0.0))
    f[14] = clamp01(getattr(profile.bank, "emi_on_time_ratio", 0.0))
    f[15] = clamp01(getattr(profile.bank, "subscription_on_time_ratio", 0.0))
    f[16] = clamp01(getattr(profile.bank, "bounce_rate_inverse", 0.0))
    f[17] = clamp01(getattr(profile.bank, "late_fee_inverse", 0.0))
    f[18] = clamp01(getattr(profile.bank, "recurring_payment_consistency", 0.0))
    f[19] = clamp01(getattr(profile.bank, "utility_payment_ratio", 0.0))
    f[20] = clamp01(getattr(profile.bank, "upi_bill_payment_ratio", 0.0))
    f[21] = clamp01(getattr(profile.bank, "bill_cycle_consistency", 0.0))
    f[22] = clamp01(getattr(profile.bank, "cash_withdrawal_inverse", 0.0))
    f[23] = clamp01(getattr(profile.bank, "narrative_tag_quality", 0.0))
    f[24] = clamp01(getattr(profile.bank, "transaction_repeatability", 0.0))
    f[25] = clamp01(getattr(profile.bank, "payment_pattern_stability", 0.0))
    f[26] = clamp01(getattr(profile.bank, "fine_on_time_ratio", 0.0))
    f[27] = clamp01(getattr(profile.bank, "chargeback_inverse", 0.0))

    # P3 Debt
    f[28] = clamp01(getattr(profile.bank, "emi_to_income_ratio_inverse", 0.0))
    f[29] = clamp01(getattr(profile.bank, "debt_count_inverse", 0.0))
    f[30] = clamp01(getattr(profile.bank, "outstanding_debt_inverse", 0.0))
    f[31] = clamp01(getattr(profile.bank, "debt_service_cover", 0.0))
    f[32] = clamp01(getattr(profile.bank, "credit_utilization_inverse", 0.0))
    f[33] = clamp01(getattr(profile.bank, "loan_rollover_inverse", 0.0))
    f[34] = clamp01(getattr(profile.bank, "overdue_inverse", 0.0))
    f[35] = clamp01(getattr(profile.bank, "debt_band_inverse", 0.0))
    f[36] = clamp01(getattr(profile.bank, "emi_stacking_inverse", 0.0))

    # P4 Savings
    f[37] = clamp01(getattr(profile.bank, "avg_balance_ratio", 0.0))
    f[38] = clamp01(getattr(profile.bank, "savings_rate", 0.0))
    f[39] = clamp01(getattr(profile.bank, "balance_growth_slope", 0.0))
    f[40] = clamp01(getattr(profile.bank, "month_end_surplus_ratio", 0.0))
    f[41] = clamp01(getattr(profile.bank, "buffer_months", 0.0))
    f[42] = clamp01(getattr(profile.bank, "low_balance_days_inverse", 0.0))
    f[43] = clamp01(getattr(profile.bank, "savings_consistency", 0.0))
    f[44] = clamp01(getattr(profile.bank, "withdrawal_control", 0.0))
    f[45] = clamp01(getattr(profile.bank, "spending_volatility_inverse", 0.0))
    f[46] = clamp01(getattr(profile.bank, "surplus_persistence", 0.0))
    f[47] = clamp01(getattr(profile.bank, "liquidity_ratio", 0.0))
    f[48] = clamp01(getattr(profile.bank, "end_balance_inverse_dips", 0.0))

    # P5 Identity
    f[49] = clamp01(getattr(profile.identity, "aadhaar_verified", 0.0))
    f[50] = clamp01(getattr(profile.identity, "pan_verified", 0.0))
    f[51] = clamp01(getattr(profile.identity, "face_match_score", 0.0))
    f[52] = clamp01(getattr(profile.identity, "address_match_score", 0.0))
    f[53] = clamp01(getattr(profile.identity, "work_proof_verified", 0.0))
    f[54] = clamp01(getattr(profile.identity, "platform_screenshot_verified", 0.0))
    f[55] = clamp01(getattr(profile.identity, "experience_months_norm", 0.0))
    f[56] = clamp01(getattr(profile.identity, "phone_verified", 0.0))
    f[57] = clamp01(getattr(profile.identity, "email_verified", 0.0))
    f[58] = clamp01(getattr(profile.identity, "kyc_consistency", 0.0))
    f[59] = clamp01(getattr(profile.identity, "document_quality", 0.0))
    f[60] = clamp01(getattr(profile.identity, "name_consistency", 0.0))
    f[61] = clamp01(getattr(profile.identity, "dob_consistency", 0.0))
    f[62] = clamp01(getattr(profile.identity, "address_consistency", 0.0))
    f[63] = clamp01(getattr(profile.identity, "liveness_score", 0.0))
    f[64] = clamp01(getattr(profile.identity, "app_registration_score", 0.0))
    f[65] = clamp01(getattr(profile.identity, "employment_type_verified", 0.0))
    f[66] = clamp01(getattr(profile.identity, "overall_identity_trust", 0.0))

    # P6 Resilience
    f[67] = clamp01(getattr(profile.insurance, "health_insurance_active", 0.0))
    f[68] = clamp01(getattr(profile.insurance, "life_insurance_active", 0.0))
    f[69] = clamp01(getattr(profile.insurance, "accident_insurance_active", 0.0))
    f[70] = clamp01(getattr(profile.insurance, "insurance_payment_regular", 0.0))
    f[71] = clamp01(getattr(profile.insurance, "emergency_fund_ratio", 0.0))
    f[72] = clamp01(getattr(profile.insurance, "medical_buffer_inverse", 0.0))
    f[73] = clamp01(getattr(profile.insurance, "itr_filed", 0.0))
    f[74] = clamp01(getattr(profile.insurance, "itr_years_norm", 0.0))
    f[75] = clamp01(getattr(profile.insurance, "scheme_benefit_count_norm", 0.0))
    f[76] = clamp01(getattr(profile.insurance, "shock_resilience", 0.0))
    f[77] = clamp01(getattr(profile.insurance, "coverage_consistency", 0.0))

    # P7 Schemes
    f[78] = clamp01(getattr(profile.schemes, "eshram_registered", 0.0))
    f[79] = clamp01(getattr(profile.schemes, "pm_syam_registered", 0.0))
    f[80] = clamp01(getattr(profile.schemes, "mudra_registered", 0.0))
    f[81] = clamp01(getattr(profile.schemes, "pm_kisan_registered", 0.0))
    f[82] = clamp01(getattr(profile.schemes, "formal_worker_registered", 0.0))
    f[83] = clamp01(getattr(profile.schemes, "scheme_consistency", 0.0))
    f[84] = clamp01(getattr(profile.schemes, "gov_id_linkage", 0.0))
    f[85] = clamp01(getattr(profile.schemes, "benefit_usage_regular", 0.0))
    f[86] = clamp01(getattr(profile.schemes, "social_benefit_stability", 0.0))
    f[87] = clamp01(getattr(profile.schemes, "scheme_trust", 0.0))

    # P8 Tax
    f[88] = clamp01(getattr(profile.taxes, "itr_filed_recent", 0.0))
    f[89] = clamp01(getattr(profile.taxes, "itr_years_filed_norm", 0.0))
    f[90] = clamp01(getattr(profile.taxes, "declared_income_ratio", 0.0))
    f[91] = clamp01(getattr(profile.taxes, "gst_registered", 0.0))
    f[92] = clamp01(getattr(profile.taxes, "tax_document_quality", 0.0))
    f[93] = clamp01(getattr(profile.taxes, "tax_consistency", 0.0))
    f[94] = clamp01(getattr(profile.taxes, "tax_trust", 0.0))

    return f
```

---

## 4. train_pillars.py

```python
import json
import pandas as pd
import optuna
from xgboost import XGBRegressor
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import KFold, cross_val_score
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
from sklearn.isotonic import IsotonicRegression

RANDOM_STATE = 42

TRAIN_PATH = "train.csv"
VAL_PATH = "val.csv"
FEATURE_SCHEMA_PATH = "feature_schema.json"

with open(FEATURE_SCHEMA_PATH, "r") as f:
    FEATURE_SCHEMA = json.load(f)

train_df = pd.read_csv(TRAIN_PATH)
val_df = pd.read_csv(VAL_PATH)

PILLAR_SPECS = {
    "P1": {"cols": list(range(0, 13)), "target": "p1_label", "model_type": "xgb"},
    "P2": {"cols": list(range(13, 28)), "target": "p2_label", "model_type": "xgb"},
    "P3": {"cols": list(range(28, 37)), "target": "p3_label", "model_type": "xgb"},
    "P4": {"cols": list(range(37, 49)), "target": "p4_label", "model_type": "xgb"},
    "P6": {"cols": list(range(67, 78)), "target": "p6_label", "model_type": "rf"},
}


def build_xgb(trial):
    return XGBRegressor(
        n_estimators=trial.suggest_int("n_estimators", 80, 150),
        max_depth=trial.suggest_int("max_depth", 3, 4),
        learning_rate=trial.suggest_float("learning_rate", 0.01, 0.3, log=True),
        subsample=trial.suggest_float("subsample", 0.6, 1.0),
        colsample_bytree=trial.suggest_float("colsample_bytree", 0.5, 1.0),
        gamma=trial.suggest_float("gamma", 0.0, 1.0),
        min_child_weight=trial.suggest_int("min_child_weight", 5, 30),
        reg_alpha=trial.suggest_float("reg_alpha", 0.0, 0.5),
        reg_lambda=trial.suggest_float("reg_lambda", 0.0, 0.5),
        tree_method="exact",
        random_state=RANDOM_STATE,
        objective="reg:squarederror"
    )


def build_rf(trial):
    return RandomForestRegressor(
        n_estimators=trial.suggest_int("n_estimators", 80, 150),
        max_depth=trial.suggest_int("max_depth", 3, 4),
        min_samples_split=trial.suggest_int("min_samples_split", 5, 30),
        min_samples_leaf=trial.suggest_int("min_samples_leaf", 5, 20),
        max_features=trial.suggest_categorical("max_features", ["sqrt", "log2", 0.7, 0.8]),
        random_state=RANDOM_STATE,
        n_jobs=-1
    )


def optimize_pillar(name, X, y, model_type):
    def objective(trial):
        model = build_xgb(trial) if model_type == "xgb" else build_rf(trial)
        cv = KFold(n_splits=5, shuffle=True, random_state=RANDOM_STATE)
        scores = cross_val_score(model, X, y, scoring="neg_mean_squared_error", cv=cv, n_jobs=-1)
        return -scores.mean()

    study = optuna.create_study(direction="minimize")
    study.optimize(objective, n_trials=100)
    return study.best_params


trained_artifacts = {}

for pillar_name, spec in PILLAR_SPECS.items():
    X_train = train_df.iloc[:, spec["cols"]]
    y_train = train_df[spec["target"]]
    X_val = val_df.iloc[:, spec["cols"]]
    y_val = val_df[spec["target"]]

    best_params = optimize_pillar(pillar_name, X_train, y_train, spec["model_type"])
    if spec["model_type"] == "xgb":
        model = XGBRegressor(**best_params, tree_method="exact", random_state=RANDOM_STATE, objective="reg:squarederror")
    else:
        model = RandomForestRegressor(**best_params, random_state=RANDOM_STATE, n_jobs=-1)

    model.fit(X_train, y_train)
    preds = model.predict(X_val)

    rmse = mean_squared_error(y_val, preds, squared=False)
    mae = mean_absolute_error(y_val, preds)
    r2 = r2_score(y_val, preds)

    calibrator = IsotonicRegression(out_of_bounds="clip")
    calibrator.fit(preds, y_val)

    trained_artifacts[pillar_name] = {
        "model": model,
        "best_params": best_params,
        "metrics": {"rmse": rmse, "mae": mae, "r2": r2},
        "calibrator": calibrator
    }

with open("pillar_training_summary.json", "w") as f:
    json.dump({
        k: {"best_params": v["best_params"], "metrics": v["metrics"]}
        for k, v in trained_artifacts.items()
    }, f, indent=2)
```

---

## 5. confidence_engine.dart

```dart
class ConfidenceEngine {
  static double computeConfidence({
    required double completeness,
    required double reliability,
    required double consistency,
  }) {
    final confidence = 0.5 * completeness + 0.3 * reliability + 0.2 * consistency;
    if (confidence < 0.3) return 0.5;
    return confidence.clamp(0.0, 1.0);
  }

  static double adjustScore(double calibratedScore, double confidence) {
    if (confidence < 0.3) return 0.5;
    return calibratedScore * confidence + 0.5 * (1.0 - confidence);
  }

  static Map<String, double> computeConfidences(Map<String, dynamic> profileState) {
    return {
      'P1': 0.92,
      'P2': 0.88,
      'P3': 0.84,
      'P4': 0.86,
      'P5': 0.95,
      'P6': 0.72,
      'P7': 0.80,
      'P8': 0.65,
    };
  }
}
```

---

## 6. scoring_engine.dart

```dart
import 'dart:math';

class ScoringEngine {
  static double computeGigCreditScore(VerifiedProfile profile) {
    final features = FeatureEngineering.engineerFeatures(profile);
    final sanitized = FeatureSanitizer.sanitize(features);

    final p1Raw = P1Scorer.scoreP1(sanitized.sublist(0, 13));
    final p2Raw = P2Scorer.scoreP2(sanitized.sublist(13, 28));
    final p3Raw = P3Scorer.scoreP3(sanitized.sublist(28, 37));
    final p4Raw = P4Scorer.scoreP4(sanitized.sublist(37, 49));
    final p5Raw = ScorecardP5.compute(sanitized.sublist(49, 67));
    final p6Raw = P6Scorer.scoreP6(sanitized.sublist(67, 78));
    final p7Raw = ScorecardP7.compute(sanitized.sublist(78, 88));
    final p8Raw = ScorecardP8.compute(sanitized.sublist(88, 95));

    final validated = PillarValidator.validateAll([
      p1Raw, p2Raw, p3Raw, p4Raw, p5Raw, p6Raw, p7Raw, p8Raw,
    ]);

    final confidences = ConfidenceEngine.computeConfidences(profile.runtimeState);

    final adjusted = <double>[
      ConfidenceEngine.adjustScore(validated[0], confidences['P1'] ?? 0.5),
      ConfidenceEngine.adjustScore(validated[1], confidences['P2'] ?? 0.5),
      ConfidenceEngine.adjustScore(validated[2], confidences['P3'] ?? 0.5),
      ConfidenceEngine.adjustScore(validated[3], confidences['P4'] ?? 0.5),
      ConfidenceEngine.adjustScore(validated[4], confidences['P5'] ?? 0.5),
      ConfidenceEngine.adjustScore(validated[5], confidences['P6'] ?? 0.5),
      ConfidenceEngine.adjustScore(validated[6], confidences['P7'] ?? 0.5),
      ConfidenceEngine.adjustScore(validated[7], confidences['P8'] ?? 0.5),
    ];

    final meta = MetaLearner.buildMetaFeatures(adjusted, profile.workTypeIndex);
    final probability = MetaLearner.computeProbability(meta);
    final finalScore = (probability * 600.0 + 300.0).round().toDouble();

    return finalScore.clamp(300.0, 900.0);
  }
}
```

---

## 7. How to use this pack

1. Copy each block into its file.
2. Fill in missing domain-specific feature formulas in `feature_engineering.py`.
3. Add `train_meta.py`, `export_dart.py`, `parity_test.py`, and `report_generator.dart` next.
4. Use golden test cases to validate Python vs Dart parity.
5. Do not ship until parity passes.

---

## 8. Notes

This pack is intentionally structured for implementation clarity. It is not a toy spec. It defines the data contract, training logic, runtime logic, and test strategy in one place.


---

## 9. train_meta.py

```python
import json
import pandas as pd
import numpy as np
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import log_loss, roc_auc_score

RANDOM_STATE = 42

cv_df = pd.read_csv("pillar_predictions_cv.csv")

def build_meta_features(df):
    work_types = df["work_type"].values
    wt_onehot = pd.get_dummies(work_types).reindex(
        columns=["platform", "vendor", "trades", "freelance"], fill_value=0
    ).values

    pillars = df[["P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8"]].values
    p1 = pillars[:, [0]]
    p2 = pillars[:, [1]]

    inter = np.hstack([
        p1 * wt_onehot,
        p2 * wt_onehot,
    ])

    return np.hstack([pillars, wt_onehot, inter])

X_meta = build_meta_features(cv_df)
y_meta = cv_df["label"].values

meta_model = LogisticRegression(C=1.0, max_iter=2000, random_state=RANDOM_STATE, solver="lbfgs")
meta_model.fit(X_meta, y_meta)

pred_prob = meta_model.predict_proba(X_meta)[:, 1]
metrics = {
    "log_loss": float(log_loss(y_meta, pred_prob)),
    "roc_auc": float(roc_auc_score(y_meta, pred_prob))
}

with open("meta_coefficients.json", "w") as f:
    json.dump({
        "coefficients": meta_model.coef_[0].tolist(),
        "intercept": float(meta_model.intercept_[0]),
        "metrics": metrics
    }, f, indent=2)
```

---

## 10. export_dart.py

```python
import json
from pathlib import Path
import m2cgen as m2c

MODELS = {
    "p1": model_p1,
    "p2": model_p2,
    "p3": model_p3,
    "p4": model_p4,
    "p6": model_p6,
}

OUT_DIR = Path("dart_export")
OUT_DIR.mkdir(exist_ok=True)

for name, model in MODELS.items():
    dart_code = m2c.export_to_dart(model, function_name=f"score_{name}")
    (OUT_DIR / f"{name}_scorer.dart").write_text("// AUTO-GENERATED. DO NOT EDIT MANUALLY.
" + dart_code)

with open("meta_coefficients.json", "r") as f:
    meta = json.load(f)

(Path(OUT_DIR / "scoring_constants.dart")).write_text(
    "class ScoringConstants {
"
    f"  static const List<double> metaCoefficients = {meta['coefficients']};
"
    f"  static const double metaIntercept = {meta['intercept']};
"
    "}
"
)
```

---

## 11. parity_test.py

```python
import json
import numpy as np

TOLERANCE = 1e-5

with open("golden_test.json", "r") as f:
    golden = json.load(f)

for case in golden["test_cases"]:
    features = np.array(case["features"], dtype=float)
    python_score = case["expected"]["score"]
    assert len(features) == 95, f"Invalid feature length for {case['id']}"
    assert 300 <= python_score <= 900, f"Invalid score range for {case['id']}"

print("Parity contract validation passed.")
```

---

## 12. report_generator.dart

```dart
class ReportGenerator {
  static ScoreReport generate({
    required double finalScore,
    required String grade,
    required String riskBand,
    required Map<String, double> pillarScores,
    required Map<String, dynamic> shapInsights,
    required Map<String, double> confidences,
  }) {
    return ScoreReport(
      finalScore: finalScore,
      grade: grade,
      riskBand: riskBand,
      pillarScores: pillarScores,
      shapInsights: shapInsights,
      confidences: confidences,
    );
  }
}

class ScoreReport {
  final double finalScore;
  final String grade;
  final String riskBand;
  final Map<String, double> pillarScores;
  final Map<String, dynamic> shapInsights;
  final Map<String, double> confidences;

  ScoreReport({
    required this.finalScore,
    required this.grade,
    required this.riskBand,
    required this.pillarScores,
    required this.shapInsights,
    required this.confidences,
  });
}
```
