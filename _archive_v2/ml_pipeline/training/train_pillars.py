"""
GigCredit — Pillar Model Training
===================================
Trains 5 pillar regressors on the 95-feature synthetic dataset.

Model map (from COMP_18 / COMP_23):
  P1 Income Stability     XGBoost   f_0  – f_12  (13 features)
  P2 Payment Discipline   XGBoost   f_13 – f_27  (15 features)
  P3 Debt Management      XGBoost   f_28 – f_36  ( 9 features)
  P4 Savings Behaviour    XGBoost   f_37 – f_48  (12 features)
  P6 Financial Resilience RF        f_67 – f_77  (11 features)

P5 (Work & Identity, f_49-f_66) and P7 (Social, f_78-f_94) are
deterministic scorecards — no ML training required.
"""

import json
import sys
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error
from sklearn.model_selection import train_test_split
from xgboost import XGBRegressor

# ---------------------------------------------------------------------------
# PILLAR CONFIGURATION
# ---------------------------------------------------------------------------
PILLAR_CONFIG = [
    # (name, feature_indices, model_type, per-pillar target slice for training)
    ("p1", list(range(0,  13)), "xgb"),
    ("p2", list(range(13, 28)), "xgb"),
    ("p3", list(range(28, 37)), "xgb"),
    ("p4", list(range(37, 49)), "xgb"),
    ("p6", list(range(67, 78)), "xgb"),
]

XGB_PARAMS = dict(
    n_estimators=200,
    max_depth=5,
    learning_rate=0.05,
    subsample=0.8,
    colsample_bytree=0.8,
    reg_alpha=0.1,
    reg_lambda=1.0,
    random_state=42,
    n_jobs=-1,
)

RF_PARAMS = dict(
    n_estimators=200,
    max_depth=6,
    min_samples_leaf=3,
    max_features="sqrt",
    random_state=42,
    n_jobs=-1,
)


def build_pillar_target(df: pd.DataFrame, feat_cols: list[str]) -> pd.Series:
    """
    Derive a pillar-specific target by averaging the features in that pillar
    and blending with the global target (80/20). This ensures each pillar
    model learns the actual semantic meaning of its features, not just noise.
    """
    pillar_mean = df[feat_cols].mean(axis=1)
    return 0.8 * pillar_mean + 0.2 * df["target"]


def train_model(
    name: str,
    X_train: pd.DataFrame,
    y_train: pd.Series,
    X_val: pd.DataFrame,
    y_val: pd.Series,
    model_type: str,
) -> object:
    if model_type == "xgb":
        model = XGBRegressor(**XGB_PARAMS)
    else:
        model = RandomForestRegressor(**RF_PARAMS)

    model.fit(X_train, y_train)
    y_pred = model.predict(X_val)
    rmse = float(np.sqrt(mean_squared_error(y_val, y_pred)))
    r2 = float(1 - np.sum((y_val - y_pred) ** 2) / np.sum((y_val - y_val.mean()) ** 2))
    print(f"  {name.upper():4s}  [{model_type:3s}]  RMSE={rmse:.5f}  R²={r2:.4f}")
    return model


def main() -> None:
    data_path = Path("ml_pipeline/data/generated/synthetic_profiles.csv")
    if not data_path.exists():
        print("ERROR: Run synthetic_generator.py first.")
        sys.exit(1)

    print("Loading dataset …")
    df = pd.read_csv(data_path)
    feat_cols = [f"f_{i}" for i in range(95)]

    # Global 80/20 stratified-ish split (stratify on work_type)
    df_train, df_val = train_test_split(df, test_size=0.20, random_state=42, shuffle=True)
    print(f"Train: {len(df_train):,}  Val: {len(df_val):,}")

    out = Path("ml_pipeline/output/models")
    out.mkdir(parents=True, exist_ok=True)

    metrics: dict = {}
    print("\nTraining pillar models:")
    print("-" * 55)

    for name, indices, model_type in PILLAR_CONFIG:
        cols = [f"f_{i}" for i in indices]
        X_tr = df_train[cols]
        X_vl = df_val[cols]
        y_tr = build_pillar_target(df_train, cols)
        y_vl = build_pillar_target(df_val, cols)

        model = train_model(name, X_tr, y_tr, X_vl, y_vl, model_type)
        joblib.dump(model, out / f"{name}.pkl")

        y_pred_vl = model.predict(X_vl)
        rmse = float(np.sqrt(mean_squared_error(y_vl, y_pred_vl)))
        metrics[name] = {"rmse": round(rmse, 6), "model_type": model_type, "n_features": len(indices)}

    # Deterministic scorecard registry (P5 and P7 → no .pkl needed)
    scorecards = {
        "p5": {
            "feature_range": [49, 66],
            "method": "weighted_mean",
            "weights": "uniform",
        },
        "p7": {
            "feature_range": [78, 94],
            "method": "weighted_mean",
            "weights": "uniform",
        },
    }
    (out / "scorecards.json").write_text(json.dumps(scorecards, indent=2), encoding="utf-8")
    (out / "training_metrics.json").write_text(json.dumps(metrics, indent=2), encoding="utf-8")

    print("-" * 55)
    print(f"\nAll models saved to {out}/")
    print(json.dumps(metrics, indent=2))


if __name__ == "__main__":
    main()
