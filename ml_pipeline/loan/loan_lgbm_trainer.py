import os
import sys
import json
import joblib
import pandas as pd
import numpy as np
from lightgbm import LGBMClassifier
from sklearn.metrics import roc_auc_score, accuracy_score

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from config import DATA_DIR, MODELS_DIR, ASSETS_DIR, LOAN_FEATURES, SEED

def main():
    print("Training Loan LightGBM Classifier...")
    df = pd.read_csv(os.path.join(DATA_DIR, 'loan', 'loan_scenarios.csv'))
    
    train_df = df.sample(frac=0.8, random_state=SEED)
    val_df = df.drop(train_df.index)
    
    X_tr = train_df[LOAN_FEATURES].values
    y_tr = train_df['approved'].values
    X_val = val_df[LOAN_FEATURES].values
    y_val = val_df['approved'].values
    
    model = LGBMClassifier(
        n_estimators=100, max_depth=5, learning_rate=0.05, 
        random_state=SEED, n_jobs=-1
    )
    
    model.fit(X_tr, y_tr, eval_set=[(X_val, y_val)])
    
    preds_prob = model.predict_proba(X_val)[:, 1]
    auc = roc_auc_score(y_val, preds_prob)
    acc = accuracy_score(y_val, model.predict(X_val))
    
    print(f"Loan Model Validation AUC: {auc:.4f}, Accuracy: {acc:.4f}")
    
    os.makedirs(MODELS_DIR, exist_ok=True)
    out_path = os.path.join(MODELS_DIR, 'loan_lgbm.pkl')
    joblib.dump(model, out_path)
    print(f"Saved to {out_path}")
    
    print("Calibrating thresholds...")
    thresholds = {}
    products = ['emergency_micro', 'income_bridge', 'growth']
    work_types = ['platform_worker', 'street_vendor', 'skilled_tradesperson', 'freelancer']
    
    for p in products:
        thresholds[p] = {}
        for wt in work_types:
            mask = (val_df['product'] == p) & (val_df['work_type'] == wt)
            if np.sum(mask) > 10:
                y_sub = y_val[mask]
                pred_sub = preds_prob[mask]
                app_preds = pred_sub[y_sub == 1]
                if len(app_preds) > 5:
                    th = np.percentile(app_preds, 10) 
                else:
                    th = 0.5
            else:
                th = 0.5
            thresholds[p][wt] = float(th)
            
    out_th = os.path.join(ASSETS_DIR, 'loan_thresholds.json')
    with open(out_th, 'w') as f:
        json.dump(thresholds, f, indent=2)
    print(f"Saved thresholds to {out_th}")

if __name__ == '__main__':
    main()
