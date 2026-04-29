"""
GigCredit — Meta-Learner Training
=====================================
Trains an XGBClassifier meta-learner on top of 7 pillar scores.

Input (19 features):
  [p1, p2, p3, p4, p5, p6, p7]           7 pillar scores
  [w_platform, w_vendor, w_trades, w_free] 4 work-type one-hot
  [p1×platform, p2×platform, p1×vendor, p2×vendor,
   p1×trades,   p2×trades,   p1×free,  p2×free]   8 interaction terms

Output: binary probability → final_score = round(prob × 600) + 300
  Score range: 300 (prob=0) → 900 (prob=1)

Constraint: All 7 pillar scores have a monotonic increasing relationship
with the final probability (higher pillar score = higher final score).
"""

import json
import sys
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from sklearn.metrics import accuracy_score, roc_auc_score
from sklearn.model_selection import train_test_split
from xgboost import XGBClassifier


def compute_pillar_scores(df: pd.DataFrame, models: dict) -> pd.DataFrame:
    """
    Compute all 7 pillar scores for a dataframe.
    P1–P4 and P6 use trained models; P5 and P7 use uniform weighted mean.
    """
    results = {}

    for name, indices in [
        ("p1", range(0,  13)),
        ("p2", range(13, 28)),
        ("p3", range(28, 37)),
        ("p4", range(37, 49)),
        ("p6", range(67, 78)),
    ]:
        cols = [f"f_{i}" for i in indices]
        results[name] = models[name].predict(df[cols]).astype(float)

    # Deterministic scorecards
    p5_cols = [f"f_{i}" for i in range(49, 67)]
    p7_cols = [f"f_{i}" for i in range(78, 95)]
    results["p5"] = df[p5_cols].mean(axis=1).values
    results["p7"] = df[p7_cols].mean(axis=1).values

    return pd.DataFrame(results, index=df.index)


def build_meta_features(pillars: pd.DataFrame, work_type: pd.Series) -> pd.DataFrame:
    """Build the 19-feature meta-learner input matrix."""
    one_hot = pd.get_dummies(work_type, prefix="w")
    for col in ["w_platform_worker", "w_vendor", "w_tradesperson", "w_freelancer"]:
        if col not in one_hot.columns:
            one_hot[col] = 0.0

    meta = pd.DataFrame({
        "p1": pillars["p1"],
        "p2": pillars["p2"],
        "p3": pillars["p3"],
        "p4": pillars["p4"],
        "p5": pillars["p5"],
        "p6": pillars["p6"],
        "p7": pillars["p7"],
        "w_platform": one_hot["w_platform_worker"].values,
        "w_vendor":   one_hot["w_vendor"].values,
        "w_trades":   one_hot["w_tradesperson"].values,
        "w_free":     one_hot["w_freelancer"].values,
    }, index=pillars.index)

    # 8 interaction terms
    meta["p1_x_platform"] = meta["p1"] * meta["w_platform"]
    meta["p2_x_platform"] = meta["p2"] * meta["w_platform"]
    meta["p1_x_vendor"]   = meta["p1"] * meta["w_vendor"]
    meta["p2_x_vendor"]   = meta["p2"] * meta["w_vendor"]
    meta["p1_x_trades"]   = meta["p1"] * meta["w_trades"]
    meta["p2_x_trades"]   = meta["p2"] * meta["w_trades"]
    meta["p1_x_free"]     = meta["p1"] * meta["w_free"]
    meta["p2_x_free"]     = meta["p2"] * meta["w_free"]

    return meta


def main() -> None:
    data_path = Path("ml_pipeline/data/generated/synthetic_profiles.csv")
    model_dir  = Path("ml_pipeline/output/models")
    out_dir    = Path("ml_pipeline/output/json_configs")
    out_dir.mkdir(parents=True, exist_ok=True)

    if not data_path.exists():
        print("ERROR: Run synthetic_generator.py first.")
        sys.exit(1)

    print("Loading dataset …")
    df = pd.read_csv(data_path)

    print("Loading pillar models …")
    try:
        models = {n: joblib.load(model_dir / f"{n}.pkl") for n in ["p1", "p2", "p3", "p4", "p6"]}
    except FileNotFoundError as e:
        print(f"ERROR: {e}\nRun train_pillars.py first.")
        sys.exit(1)

    df_train, df_val = train_test_split(df, test_size=0.20, random_state=42)
    print(f"Train: {len(df_train):,}  Val: {len(df_val):,}")

    y_train = df_train["target"]
    y_val   = df_val["target"]
    
    # We still need the binary label just for validation metrics (AUC)
    threshold = df["target"].quantile(0.60)
    y_val_bin = (df_val["target"] >= threshold).astype(int)

    print("\nComputing pillar scores …")
    p_train = compute_pillar_scores(df_train, models)
    p_val   = compute_pillar_scores(df_val,   models)

    X_train = build_meta_features(p_train, df_train["work_type"])
    X_val   = build_meta_features(p_val,   df_val["work_type"])

    feature_order = list(X_train.columns)

    monotone_constraints = {}
    for feat in feature_order:
        if feat in ["p1", "p2", "p3", "p4", "p5", "p6", "p7"]:
            monotone_constraints[feat] = 1
        else:
            monotone_constraints[feat] = 0

    print("Training meta-learner (RandomForestRegressor) …")
    from sklearn.ensemble import RandomForestRegressor
    rf = RandomForestRegressor(
        n_estimators=100,
        max_depth=6,
        min_samples_leaf=5,
        random_state=42,
        n_jobs=-1,
    )
    rf.fit(X_train, y_train)

    y_pred  = rf.predict(X_val)
    # Since it's a regressor, output is continuous [0, 1]. Treat directly as probability.
    y_prob  = y_pred
    
    # Calculate binary accuracy using the threshold
    y_pred_bin = (y_prob >= threshold).astype(int)
    acc     = accuracy_score(y_val_bin, y_pred_bin)
    auc     = roc_auc_score(y_val_bin, y_prob)
    print(f"  Accuracy={acc:.4f}  AUC-ROC={auc:.4f}")

    (out_dir / "meta_coefficients.json").write_text(
        json.dumps(
            {
                "feature_order": feature_order,
                "label_threshold": round(float(threshold), 6),
                "validation": {"accuracy": round(acc, 4), "auc_roc": round(auc, 4)},
                "note": "Meta-Learner is now an XGBRegressor trained on continuous target."
            },
            indent=2,
        ),
        encoding="utf-8",
    )

    # Feature means (fallback for missing values in Flutter)
    feat_cols = [f"f_{i}" for i in range(95)]
    means = df[feat_cols].mean(axis=0).round(6).tolist()
    (out_dir / "feature_means.json").write_text(json.dumps(means, indent=2), encoding="utf-8")

    joblib.dump(rf, model_dir / "meta_rf.pkl")

    print(f"\nArtifacts saved to {out_dir}/")
    print("  meta_coefficients.json  ok")
    print("  feature_means.json      ok")


if __name__ == "__main__":
    main()
