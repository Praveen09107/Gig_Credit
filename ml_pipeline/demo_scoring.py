import os
import sys
import json
import joblib
import pandas as pd
import numpy as np
from scipy.special import expit

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from config import (
    DATA_DIR, MODELS_DIR, ASSETS_DIR, ML_PILLARS, RULE_PILLARS,
    CROSS_FEATURE_NAMES, SCORE_MIN, SCORE_MAX, GRADE_BANDS
)
from training.train_pillars_v3 import get_pillar_features
from training.meta_learner_v3 import confidence_from_interval
from generation.synthetic_data_generator import scorecard_P5, scorecard_P7, scorecard_P8

def get_grade(score):
    for mn, mx, gr, desc, risk in GRADE_BANDS:
        if mn <= score <= mx:
            return gr, risk
    return "D", "High"

def run_demo():
    print("="*60)
    print("[RUNNING] GIGCREDIT V3.0 - LIVE SCORING ENGINE DEMO")
    print("="*60)
    
    with open(os.path.join(ASSETS_DIR, 'calibration_knots.json'), 'r') as f:
        knots = json.load(f)
    with open(os.path.join(ASSETS_DIR, 'conformal_intervals.json'), 'r') as f:
        intervals = json.load(f)
    with open(os.path.join(ASSETS_DIR, 'meta_lr_coefficients.json'), 'r') as f:
        meta_lr = json.load(f)
        
    df = pd.read_csv(os.path.join(DATA_DIR, 'synthetic_profiles.csv'))
    sample = df.sample(n=1, random_state=88) 
    wt = sample['work_type'].iloc[0]
    
    print(f"\n[*] APPLICANT PROFILE: {wt.upper().replace('_', ' ')}")
    print("-" * 60)
    
    ordered_pillars = ['P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7', 'P8']
    calibrated_scores = {}
    confidences = {}
    
    print("[*] STAGE 1: 8-PILLAR PROCESSING")
    for p in ordered_pillars:
        if p in ML_PILLARS:
            model_path = [os.path.join(MODELS_DIR, m) for m in os.listdir(MODELS_DIR) if m.startswith(p.lower() + "_")][0]
            model = joblib.load(model_path)
            X = get_pillar_features(sample, p)
            raw = float(model.predict(X)[0])
            
            x_k = np.array(knots[p]['x'])
            y_k = np.array(knots[p]['y'])
            cal = float(np.interp(raw, x_k, y_k))
            
            interval = intervals[p].get(wt, 0.15)
            conf = confidence_from_interval(interval)
            print(f"  [{p}] ML Score: {raw:.3f} -> Calibrated: {cal:.3f} | Confidence: {conf:.2f}")
        else:
            if p == 'P5': raw = float(scorecard_P5(sample).iloc[0])
            elif p == 'P7': raw = float(scorecard_P7(sample).iloc[0])
            elif p == 'P8': raw = float(scorecard_P8(sample).iloc[0])
            
            cal = raw
            conf = 1.0 
            print(f"  [{p}] Rule Score: {raw:.3f} -> Calibrated: {cal:.3f} | Confidence: {conf:.2f}")
            
        calibrated_scores[p] = cal
        confidences[p] = conf
        
    print("\n[*] STAGE 2: META-LEARNER FUSION (LOGISTIC REGRESSION)")
    preds_arr = [calibrated_scores[p] for p in ordered_pillars]
    confs_arr = [confidences[p] for p in ordered_pillars]
    
    top4 = meta_lr['top4_cross_pillar_indices']
    cross_arr = [float(sample[CROSS_FEATURE_NAMES[i - 95]].iloc[0]) for i in top4]
    
    meta_inputs = preds_arr + confs_arr + cross_arr
    
    total = meta_lr['intercept']
    for i, val in enumerate(meta_inputs):
        total += val * meta_lr['coefficients'][i]
        
    probability = float(expit(total))
    print(f"  Aggregated Log-Odds: {total:.4f}")
    print(f"  Final Probability:   {probability:.4f}")
    
    print("\n[*] STAGE 3: FINAL SCORING")
    final_score = int(round(SCORE_MIN + probability * (SCORE_MAX - SCORE_MIN)))
    grade, risk = get_grade(final_score)
    
    print(f"  =========================================")
    print(f"  [>] FINAL CREDIT SCORE : {final_score} / {SCORE_MAX}")
    print(f"  [>] ASSIGNED GRADE     : {grade} ({risk} Risk)")
    print(f"  =========================================\n")

if __name__ == '__main__':
    run_demo()
