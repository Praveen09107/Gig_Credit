import os
import sys
import numpy as np
import pandas as pd

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from config import DATA_DIR, LOAN_FEATURES, SEED

def generate_loan_data(n_samples=50000):
    np.random.seed(SEED)
    print(f"Generating {n_samples} loan scenarios...")
    
    # 18 features
    df = pd.DataFrame()
    
    # final_score (300 to 900)
    df['final_score'] = np.random.normal(600, 100, n_samples).clip(300, 900)
    
    # P1 to P8
    for p in ['P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7', 'P8']:
        df[p] = np.random.beta(5, 2, n_samples)
        
    df['dscr'] = np.random.lognormal(0.5, 0.4, n_samples).clip(0, 5) # Debt Service Coverage Ratio
    df['post_loan_emi_ratio'] = np.random.beta(2, 5, n_samples)
    df['loan_to_income'] = np.random.lognormal(1, 0.5, n_samples).clip(0, 10)
    df['payment_streak'] = np.random.poisson(10, n_samples).clip(0, 36)
    df['insurance_coverage'] = np.random.beta(1.5, 4, n_samples)
    df['savings_buffer_months'] = np.random.lognormal(0.5, 0.5, n_samples).clip(0, 12)
    df['income_growth_slope'] = np.random.normal(0.5, 0.2, n_samples).clip(0, 1)
    
    # Work type flags
    w_rand = np.random.random(n_samples)
    df['w_platform'] = (w_rand < 0.30).astype(int)
    df['w_vendor'] = ((w_rand >= 0.30) & (w_rand < 0.60)).astype(int)
    
    # Work type string for thresholds
    conditions = [
        df['w_platform'] == 1,
        df['w_vendor'] == 1,
        (w_rand >= 0.60) & (w_rand < 0.80)
    ]
    choices = ['platform_worker', 'street_vendor', 'skilled_tradesperson']
    df['work_type'] = np.select(conditions, choices, default='freelancer')
    
    # Products
    products = ['emergency_micro', 'income_bridge', 'growth']
    df['product'] = np.random.choice(products, n_samples)
    
    # Target label: synthetic rule
    # Higher score, higher dscr, lower emi_ratio -> better
    score_norm = (df['final_score'] - 300) / 600
    raw_prob = (score_norm * 0.4 + 
                (df['dscr'] > 1.25).astype(float) * 0.2 + 
                (1 - df['post_loan_emi_ratio']) * 0.2 + 
                df['payment_streak'] / 36 * 0.1 +
                df['P2'] * 0.1)
            
    # Product difficulty
    diff = {'emergency_micro': 0.1, 'income_bridge': 0.3, 'growth': 0.5}
    raw_prob -= df['product'].map(diff)
    
    from scipy.special import expit
    sharp_prob = expit((raw_prob - 0.5) * 50)
    
    df['approved'] = np.random.binomial(1, sharp_prob)
    
    os.makedirs(os.path.join(DATA_DIR, 'loan'), exist_ok=True)
    out_path = os.path.join(DATA_DIR, 'loan', 'loan_scenarios.csv')
    df.to_csv(out_path, index=False)
    print(f"Exported to {out_path}")

if __name__ == '__main__':
    generate_loan_data()
