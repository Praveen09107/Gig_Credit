import os
import sys
import json
import joblib
import numpy as np
import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.feature_selection import mutual_info_classif
from sklearn.metrics import roc_auc_score, accuracy_score
from sklearn.model_selection import train_test_split

# Ensure ml_pipeline is in path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from config import (
    DATA_DIR, MODELS_DIR, ASSETS_DIR, ML_PILLARS, SEED
)
from training.train_pillars_v3 import get_pillar_features
from generation.synthetic_data_generator import scorecard_P5, scorecard_P7, scorecard_P8

def confidence_from_interval(interval):
    if interval <= 0.12:
        return 1.0
    elif interval <= 0.20:
        return 0.75
    return 0.50

def get_calibrated_preds_and_conf(df, knots, intervals):
    n = len(df)
    preds = np.zeros((n, 8))
    confs = np.zeros((n, 8))
    
    # ML Pillars (P1, P2, P3, P4, P6) -> indices 0, 1, 2, 3, 5
    ml_indices = [0, 1, 2, 3, 5]
    for i, p in zip(ml_indices, ML_PILLARS):
        model_path = [os.path.join(MODELS_DIR, f) for f in os.listdir(MODELS_DIR) if f.startswith(p.lower() + "_")][0]
        model = joblib.load(model_path)
        X = get_pillar_features(df, p)
        raw_pred = model.predict(X)
        
        x_knots = np.array(knots[p]['x'])
        y_knots = np.array(knots[p]['y'])
        cal_pred = np.interp(raw_pred, x_knots, y_knots)
        preds[:, i] = cal_pred
        
        for j, wt in enumerate(df['work_type']):
            interval = intervals[p].get(wt, 0.15)
            confs[j, i] = confidence_from_interval(interval)
            
    # Rule Pillars (P5, P7, P8) -> indices 4, 6, 7
    preds[:, 4] = scorecard_P5(df)
    confs[:, 4] = 1.0
    preds[:, 6] = scorecard_P7(df)
    confs[:, 6] = 1.0
    preds[:, 7] = scorecard_P8(df)
    confs[:, 7] = 1.0
    
    return preds, confs

def main():
    print("Loading data for meta-learner...")
    train_df = pd.read_csv(os.path.join(DATA_DIR, 'synthetic_profiles.csv'))
    
    with open(os.path.join(ASSETS_DIR, 'calibration_knots.json'), 'r') as f:
        knots = json.load(f)
    with open(os.path.join(ASSETS_DIR, 'conformal_intervals.json'), 'r') as f:
        intervals = json.load(f)
        
    print("Generating calibrated predictions...")
    preds, confs = get_calibrated_preds_and_conf(train_df, knots, intervals)
    
    # Select top 4 cross-pillar features
    from config import CROSS_FEATURE_NAMES
    cross_features = train_df[CROSS_FEATURE_NAMES].values
    
    y_prob = train_df['target'].values
    # Binarize for classification and mutual information
    y_bin = (y_prob > np.median(y_prob)).astype(int)
    
    mi = mutual_info_classif(cross_features, y_bin, random_state=SEED)
    top4_local = np.argsort(mi)[-4:][::-1]
    top4_global = [int(idx + 95) for idx in top4_local]
    print(f"Selected top 4 cross-pillar features: {top4_global}")
    
    selected_cross = cross_features[:, top4_local]
    
    X_meta = np.column_stack([preds, confs, selected_cross])
    
    # Use deterministic threshold for clear signal separation
    # Top 50% = 1 (Good), Bottom 50% = 0 (Default)
    y_true = (y_prob >= np.median(y_prob)).astype(int)
    
    X_tr, X_val, y_tr, y_val = train_test_split(X_meta, y_true, test_size=0.2, random_state=SEED)
    
    print("Training Logistic Regression meta-learner...")
    lr = LogisticRegression(C=1.0, max_iter=1000, random_state=SEED)
    lr.fit(X_tr, y_tr)
    
    y_pred_prob = lr.predict_proba(X_val)[:, 1]
    y_pred_bin = lr.predict(X_val)
    
    auc = roc_auc_score(y_val, y_pred_prob)
    acc = accuracy_score(y_val, y_pred_bin)
    print(f"Meta-Learner Validation AUC: {auc:.4f}, Accuracy: {acc:.4f}")
    
    # Export coefficients
    coefs = lr.coef_[0].tolist()
    intercept = float(lr.intercept_[0])
    
    export_data = {
        "coefficients": coefs,
        "intercept": intercept,
        "top4_cross_pillar_indices": top4_global,
        "metrics": {
            "auc": auc,
            "accuracy": acc
        }
    }
    
    os.makedirs(ASSETS_DIR, exist_ok=True)
    with open(os.path.join(ASSETS_DIR, 'meta_lr_coefficients.json'), 'w') as f:
        json.dump(export_data, f, indent=2)
        
    print("Exported meta_lr_coefficients.json successfully.")

if __name__ == "__main__":
    main()
