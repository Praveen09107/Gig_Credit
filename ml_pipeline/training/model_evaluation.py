import os
import sys
import joblib
import numpy as np
import pandas as pd
from sklearn.metrics import roc_auc_score, accuracy_score, brier_score_loss
from scipy.stats import ks_2samp

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from config import DATA_DIR, MODELS_DIR, LOAN_FEATURES

def calculate_ks(y_true, y_prob):
    goods = y_prob[y_true == 1]
    bads = y_prob[y_true == 0]
    if len(goods) == 0 or len(bads) == 0:
        return 0.0
    ks, p_value = ks_2samp(goods, bads)
    return ks

def evaluate_loan_model():
    print("\n" + "="*50)
    print("LOAN DECISION MODEL VIGOUR TESTING")
    print("="*50)
    
    df = pd.read_csv(os.path.join(DATA_DIR, 'loan', 'loan_scenarios.csv'))
    model_path = os.path.join(MODELS_DIR, 'loan_lgbm.pkl')
    
    if not os.path.exists(model_path):
        print("Loan model not found.")
        return
        
    model = joblib.load(model_path)
    
    X = df[LOAN_FEATURES].values
    y = df['approved'].values
    y_prob = model.predict_proba(X)[:, 1]
    y_pred = model.predict(X)
    
    auc = roc_auc_score(y, y_prob)
    acc = accuracy_score(y, y_pred)
    brier = brier_score_loss(y, y_prob)
    ks = calculate_ks(y, y_prob)
    
    print(f"Overall Metrics:")
    print(f"  AUC:           {auc:.4f}  (>0.75 Good, >0.85 Excellent)")
    print(f"  Accuracy:      {acc:.4f}")
    print(f"  Brier Score:   {brier:.4f}  (Closer to 0 is better calibration)")
    print(f"  KS Statistic:  {ks:.4f}  (>0.30 Good separation)")
    
    print("\nDecile Analysis (Model Lift):")
    df['prob'] = y_prob
    df['decile'] = pd.qcut(df['prob'], 10, labels=False, duplicates='drop')
    
    decile_stats = df.groupby('decile').agg(
        total_count=('approved', 'count'),
        approved_count=('approved', 'sum'),
        avg_prob=('prob', 'mean')
    ).sort_index(ascending=False)
    
    total_approved = decile_stats['approved_count'].sum()
    decile_stats['capture_rate'] = decile_stats['approved_count'] / total_approved
    decile_stats['cumulative_capture'] = decile_stats['capture_rate'].cumsum()
    
    for i, row in decile_stats.iterrows():
        print(f"  Top {10-(i):2d}0%: Avg Prob {row['avg_prob']:.2f} | Captured Approvals {row['cumulative_capture']:.1%}")
        
    print("\nSubpopulation Fairness (AUC by Work Type):")
    for wt in df['work_type'].unique():
        wt_mask = df['work_type'] == wt
        y_wt = y[wt_mask]
        if len(set(y_wt)) > 1:
            auc_wt = roc_auc_score(y_wt, y_prob[wt_mask])
            print(f"  {wt.ljust(22)}: AUC {auc_wt:.4f}")

def main():
    evaluate_loan_model()

if __name__ == '__main__':
    main()
