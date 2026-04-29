"""
GigCredit — Golden Inference Test Data Generator
==================================================
Generates 5 deterministic test cases for Dart parity validation.

Each case contains:
  - features[95]       : exact normalized input vector
  - pillar_scores      : {p1..p7} from real trained models
  - meta_input[19]     : features fed to XGBoost meta-learner
  - probability        : XGBClassifier.predict_proba()[1]
  - final_score        : round(prob * 600) + 300  → 300-900

Dev B runs these through the Dart scorers and must match within 1e-4.
"""

import json
import sys
from pathlib import Path

import joblib
import numpy as np


def _score_from_prob(p: float) -> int:
    return int(round(p * 600 + 300))


def build_meta_row(pillars: dict, work_type: str, meta_model: object) -> tuple[list, float, int]:
    """Build the 19-feature meta-learner input, run inference, and compute final score."""
    wt_map = {
        "platform_worker": (1, 0, 0, 0),
        "vendor":          (0, 1, 0, 0),
        "tradesperson":    (0, 0, 1, 0),
        "freelancer":      (0, 0, 0, 1),
    }
    w_pl, w_ve, w_tr, w_fr = wt_map[work_type]

    p1, p2, p3, p4, p5, p6, p7 = (
        pillars["p1"], pillars["p2"], pillars["p3"], pillars["p4"],
        pillars["p5"], pillars["p6"], pillars["p7"],
    )

    meta_input = [
        p1, p2, p3, p4, p5, p6, p7,
        w_pl, w_ve, w_tr, w_fr,
        p1 * w_pl, p2 * w_pl,
        p1 * w_ve, p2 * w_ve,
        p1 * w_tr, p2 * w_tr,
        p1 * w_fr, p2 * w_fr,
    ]

    # Inference via XGBoost model
    # predict returns a 1D array, we want the first element
    prob = float(meta_model.predict([meta_input])[0])
    score = _score_from_prob(prob)

    return meta_input, prob, score


def main() -> None:
    model_dir  = Path("ml_pipeline/output/models")
    out_dir    = Path("ml_pipeline/output/golden")
    out_dir.mkdir(parents=True, exist_ok=True)

    # Load models
    required = ["p1", "p2", "p3", "p4", "p6", "meta_rf"]
    try:
        models = {n: joblib.load(model_dir / f"{n}.pkl") for n in required}
    except FileNotFoundError as e:
        print(f"ERROR: {e}\nRun train_pillars.py and train_meta_learner.py first.")
        sys.exit(1)

    # 5 deterministic test profiles (seed=123 for reproducibility)
    rng = np.random.default_rng(123)
    WORK_TYPES = ["platform_worker", "vendor", "tradesperson", "freelancer", "platform_worker"]

    # Import generator to reuse feature generation logic
    sys.path.insert(0, str(Path("ml_pipeline/data/generator")))
    from synthetic_generator import generate_one_profile

    cases = []
    print("Generating 5 golden test cases …")

    for i, wt in enumerate(WORK_TYPES):
        profile = generate_one_profile(rng, wt)
        features = [float(profile[f"f_{j}"]) for j in range(95)]

        # Pillar scores via real models
        def predict(name: str, indices: range) -> float:
            cols = [profile[f"f_{j}"] for j in indices]
            return float(models[name].predict([cols])[0])

        p1 = predict("p1", range(0, 13))
        p2 = predict("p2", range(13, 28))
        p3 = predict("p3", range(28, 37))
        p4 = predict("p4", range(37, 49))
        p5 = float(np.mean([profile[f"f_{j}"] for j in range(49, 67)]))
        p6 = predict("p6", range(67, 78))
        p7 = float(np.mean([profile[f"f_{j}"] for j in range(78, 95)]))

        pillars = {
            "p1": round(p1, 6), "p2": round(p2, 6), "p3": round(p3, 6),
            "p4": round(p4, 6), "p5": round(p5, 6), "p6": round(p6, 6),
            "p7": round(p7, 6),
        }

        meta_input, prob, score = build_meta_row(pillars, wt, models["meta_rf"])

        case = {
            "case_id":      i + 1,
            "work_type":    wt,
            "features":     [round(f, 6) for f in features],
            "pillar_scores": pillars,
            "meta_input":   [round(v, 6) for v in meta_input],
            "probability":  round(prob, 6),
            "final_score":  score,
        }
        grade = (
            "A+" if score >= 800 else "A" if score >= 750 else
            "B+" if score >= 700 else "B" if score >= 650 else
            "C+" if score >= 600 else "C" if score >= 550 else "D"
        )
        case["grade"]      = grade
        case["risk_level"] = "Low" if score >= 700 else "Medium" if score >= 580 else "High"

        cases.append(case)
        print(f"  Case {i+1}: {wt:18s}  score={score}  grade={grade}  prob={prob:.4f}")

    out_path = out_dir / "golden_inference.json"
    out_path.write_text(json.dumps(cases, indent=2), encoding="utf-8")
    print(f"\ngolden_inference.json -> {out_path}")
    print("Dev B must match final_score within ±1 and probability within 1e-4")


if __name__ == "__main__":
    main()