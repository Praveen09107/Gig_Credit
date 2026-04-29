import os
import sys
import json
import joblib
import numpy as np
import pandas as pd
from sklearn.isotonic import IsotonicRegression

# Ensure ml_pipeline is in path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from config import (
    DATA_DIR, MODELS_DIR, ASSETS_DIR, ML_PILLARS, WORK_TYPES,
    CONFORMAL_ALPHA
)
from training.train_pillars_v3 import get_pillar_features

def expected_calibration_error(y_true, y_prob, n_bins=10):
    bins = np.linspace(0., 1., n_bins + 1)
    binids = np.digitize(y_prob, bins) - 1
    
    ece = 0.0
    for i in range(n_bins):
        bin_idx = binids == i
        if np.sum(bin_idx) > 0:
            bin_true = np.mean(y_true[bin_idx])
            bin_prob = np.mean(y_prob[bin_idx])
            ece += np.abs(bin_true - bin_prob) * np.sum(bin_idx)
            
    return ece / len(y_prob)

def main():
    print("Loading calibration data...")
    cal_path = os.path.join(DATA_DIR, 'calibration_profiles.csv')
    df = pd.read_csv(cal_path)
    
    knots = {}
    intervals = {}
    
    for pillar in ML_PILLARS:
        # Load model
        model_files = [f for f in os.listdir(MODELS_DIR) if f.startswith(pillar.lower() + "_")]
        if not model_files:
            print(f"Model for {pillar} not found.")
            continue
        model_path = os.path.join(MODELS_DIR, model_files[0])
        model = joblib.load(model_path)
        
        # Predict
        X_cal = get_pillar_features(df, pillar)
        y_cal = df[f'target_{pillar}'].values
        preds = model.predict(X_cal)
        
        # 1. Isotonic Calibration
        ir = IsotonicRegression(out_of_bounds='clip')
        ir.fit(preds, y_cal)
        calibrated_preds = ir.transform(preds)
        
        ece = expected_calibration_error(y_cal, calibrated_preds)
        print(f"{pillar} Calibrated ECE: {ece:.4f}")
        
        # Save knots
        # Extract X and Y of the step function from IsotonicRegression
        knots[pillar] = {
            "x": ir.X_thresholds_.tolist() if hasattr(ir, 'X_thresholds_') else ir.f_.x.tolist(),
            "y": ir.y_thresholds_.tolist() if hasattr(ir, 'y_thresholds_') else ir.f_.y.tolist()
        }
        
        # 2. Conformal Prediction (Split Conformal)
        # Compute absolute residuals on calibrated predictions
        residuals = np.abs(y_cal - calibrated_preds)
        
        intervals[pillar] = {}
        for wt in WORK_TYPES:
            wt_mask = df['work_type'] == wt
            if np.sum(wt_mask) < 10:
                print(f"Warning: Not enough samples for {pillar} - {wt}")
                intervals[pillar][wt] = 0.15 # Fallback
                continue
                
            wt_residuals = residuals[wt_mask]
            
            # 1 - alpha quantile
            n = len(wt_residuals)
            q_level = min(1.0, (n + 1) * (1 - CONFORMAL_ALPHA) / n)
            q_hat = np.quantile(wt_residuals, q_level)
            
            intervals[pillar][wt] = float(q_hat)
            
            # Coverage sanity check
            coverage = np.mean(wt_residuals <= q_hat)
            print(f"  {pillar} - {wt}: interval ±{q_hat:.3f}, coverage: {coverage:.1%}")

    # Export
    os.makedirs(ASSETS_DIR, exist_ok=True)
    with open(os.path.join(ASSETS_DIR, 'calibration_knots.json'), 'w') as f:
        json.dump(knots, f, indent=2)
        
    with open(os.path.join(ASSETS_DIR, 'conformal_intervals.json'), 'w') as f:
        json.dump(intervals, f, indent=2)
        
    print("Calibration and conformal prediction complete.")

if __name__ == "__main__":
    main()
