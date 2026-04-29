import os
import sys
import json
import joblib
import numpy as np
import pandas as pd
import shap

# Ensure ml_pipeline is in path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from config import (
    DATA_DIR, MODELS_DIR, ASSETS_DIR, ML_PILLARS, RULE_PILLARS,
    WORK_TYPES, SEED, ALL_FEATURE_NAMES, P5_WEIGHTS, P7_WEIGHTS, P8_WEIGHTS,
    PILLAR_FEATURE_RANGES, PILLAR_CROSS_INDICES, MODEL_TYPES
)
from training.train_pillars_v3 import get_pillar_features

def main():
    print("Generating SHAP binned lookup...")
    df = pd.read_csv(os.path.join(DATA_DIR, 'synthetic_profiles.csv'))
    
    n_bins = 20
    shap_dict = {f: {wt: [] for wt in WORK_TYPES} for f in ALL_FEATURE_NAMES}
    
    # ML Pillars
    for pillar in ML_PILLARS:
        model_path = [os.path.join(MODELS_DIR, f) for f in os.listdir(MODELS_DIR) if f.startswith(pillar.lower() + "_")][0]
        model = joblib.load(model_path)
        
        base_start, base_end = PILLAR_FEATURE_RANGES[pillar]
        base_cols = ALL_FEATURE_NAMES[base_start:base_end]
        cross_indices = [idx - 95 for idx in PILLAR_CROSS_INDICES.get(pillar, [])]
        cross_cols = [ALL_FEATURE_NAMES[95 + idx] for idx in cross_indices]
        pillar_features = base_cols + cross_cols
        
        X = get_pillar_features(df, pillar)
        
        if MODEL_TYPES[pillar] == 'lgbm':
            contribs = model.predict(X, pred_contrib=True)
            shap_values = contribs[:, :-1]
        else:
            explainer = shap.TreeExplainer(model)
            shap_values = explainer.shap_values(X)
            
        for wt in WORK_TYPES:
            wt_mask = df['work_type'] == wt
            X_wt = X[wt_mask]
            sv_wt = shap_values[wt_mask]
            
            for j, f_name in enumerate(pillar_features):
                f_vals = X_wt[:, j]
                sv_f = sv_wt[:, j]
                
                bins = np.linspace(0, 1, n_bins + 1)
                bin_means = []
                for b_idx in range(n_bins):
                    mask = (f_vals >= bins[b_idx]) & (f_vals <= bins[b_idx+1])
                    if np.sum(mask) > 0:
                        bin_means.append(float(np.mean(sv_f[mask])))
                    else:
                        bin_means.append(0.0)
                shap_dict[f_name][wt] = bin_means

    # Rule Pillars synthetic SHAP
    rule_info = [
        ('P5', P5_WEIGHTS), ('P7', P7_WEIGHTS), ('P8', P8_WEIGHTS)
    ]
    for p, weights in rule_info:
        s, e = PILLAR_FEATURE_RANGES[p]
        p_cols = ALL_FEATURE_NAMES[s:e]
        for wt in WORK_TYPES:
            wt_mask = df['work_type'] == wt
            X_wt = df.loc[wt_mask, p_cols].values
            mean_X = np.mean(X_wt, axis=0)
            
            for j, f_name in enumerate(p_cols):
                f_vals = X_wt[:, j]
                w = weights[j]
                
                sv_f = (f_vals - mean_X[j]) * w
                
                bins = np.linspace(0, 1, n_bins + 1)
                bin_means = []
                for b_idx in range(n_bins):
                    mask = (f_vals >= bins[b_idx]) & (f_vals <= bins[b_idx+1])
                    if np.sum(mask) > 0:
                        bin_means.append(float(np.mean(sv_f[mask])))
                    else:
                        bin_means.append(0.0)
                shap_dict[f_name][wt] = bin_means

    os.makedirs(ASSETS_DIR, exist_ok=True)
    out_path = os.path.join(ASSETS_DIR, 'shap_lookup_v3.json')
    with open(out_path, 'w') as f:
        json.dump(shap_dict, f, indent=2)
    print(f"Exported SHAP lookup to {out_path}")

if __name__ == '__main__':
    main()
