import os
import sys
import json
import joblib
import numpy as np
import pandas as pd
from scipy.special import expit

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from config import (
    DATA_DIR, MODELS_DIR, ASSETS_DIR, GOLDEN_DIR,
    ML_PILLARS, RULE_PILLARS, CROSS_FEATURE_NAMES, ALL_FEATURE_NAMES,
    SCORE_MIN, SCORE_MAX, GRADE_BANDS
)
from training.train_pillars_v3 import get_pillar_features
from training.meta_learner_v3 import confidence_from_interval
from generation.synthetic_data_generator import scorecard_P5, scorecard_P7, scorecard_P8

def get_grade(score):
    for mn, mx, gr, desc, risk in GRADE_BANDS:
        if mn <= score <= mx:
            return gr
    return "D"

def main():
    print("Generating golden test data...")
    df = pd.read_csv(os.path.join(DATA_DIR, 'synthetic_profiles.csv')).head(100)
    
    with open(os.path.join(ASSETS_DIR, 'calibration_knots.json'), 'r') as f:
        knots = json.load(f)
    with open(os.path.join(ASSETS_DIR, 'conformal_intervals.json'), 'r') as f:
        intervals = json.load(f)
    with open(os.path.join(ASSETS_DIR, 'meta_lr_coefficients.json'), 'r') as f:
        meta_lr = json.load(f)
        
    golden_results = []
    
    ordered_pillars = ['P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7', 'P8']
    
    for idx, row in df.iterrows():
        profile_df = pd.DataFrame([row])
        wt = row['work_type']
        
        raw_scores = {}
        for p in ML_PILLARS:
            model_path = [os.path.join(MODELS_DIR, m) for m in os.listdir(MODELS_DIR) if m.startswith(p.lower() + "_")][0]
            model = joblib.load(model_path)
            X = get_pillar_features(profile_df, p)
            raw_scores[p] = float(model.predict(X)[0])
            
        raw_scores['P5'] = float(scorecard_P5(profile_df).iloc[0])
        raw_scores['P7'] = float(scorecard_P7(profile_df).iloc[0])
        raw_scores['P8'] = float(scorecard_P8(profile_df).iloc[0])
        
        calibrated_scores = {}
        confidences = {}
        for p in ML_PILLARS:
            x_k = np.array(knots[p]['x'])
            y_k = np.array(knots[p]['y'])
            calibrated_scores[p] = float(np.interp(raw_scores[p], x_k, y_k))
            
            interval = intervals[p].get(wt, 0.15)
            confidences[p] = confidence_from_interval(interval)
            
        calibrated_scores['P5'] = raw_scores['P5']
        confidences['P5'] = 1.0
        calibrated_scores['P7'] = raw_scores['P7']
        confidences['P7'] = 1.0
        calibrated_scores['P8'] = raw_scores['P8']
        confidences['P8'] = 1.0
        
        preds_arr = [calibrated_scores[p] for p in ordered_pillars]
        confs_arr = [confidences[p] for p in ordered_pillars]
        
        top4 = meta_lr['top4_cross_pillar_indices']
        cross_arr = [float(row[CROSS_FEATURE_NAMES[i - 95]]) for i in top4]
        
        meta_inputs = preds_arr + confs_arr + cross_arr
        
        total = meta_lr['intercept']
        for i, val in enumerate(meta_inputs):
            total += val * meta_lr['coefficients'][i]
            
        probability = float(expit(total))
        final_score = int(round(SCORE_MIN + probability * (SCORE_MAX - SCORE_MIN)))
        grade = get_grade(final_score)
        
        # Just convert inputs to a dict for the golden test
        features_dict = {f: float(row[f]) for f in ALL_FEATURE_NAMES}
        
        golden_results.append({
            "profile_id": f"test_{idx:03d}",
            "work_type": wt,
            "features": features_dict,
            "expected_raw": raw_scores,
            "expected_calibrated": calibrated_scores,
            "expected_confidence": confidences,
            "expected_probability": probability,
            "expected_score": final_score,
            "expected_grade": grade
        })
        
    os.makedirs(GOLDEN_DIR, exist_ok=True)
    out_path = os.path.join(GOLDEN_DIR, 'golden_100.json')
    with open(out_path, 'w') as f:
        json.dump(golden_results, f, indent=2)
    print(f"Exported golden tests to {out_path}")

if __name__ == '__main__':
    main()
