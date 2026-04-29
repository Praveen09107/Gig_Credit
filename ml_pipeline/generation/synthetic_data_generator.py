import os
import json
import numpy as np
import pandas as pd
import sys

# Ensure ml_pipeline is in path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from config import (
    DATA_DIR, ASSETS_DIR, FEATURE_NAMES, CROSS_FEATURE_NAMES, 
    P5_WEIGHTS, P7_WEIGHTS, P8_WEIGHTS, PILLAR_FEATURE_RANGES, NORMALISED_INDICES
)

def generate_base_features(work_type, n):
    features = np.zeros((n, 95))
    
    for i in range(n):
        # P1 Income (f0-f12)
        if work_type == 'platform_worker':
            features[i, 0] = np.random.beta(3.0, 2.5)
            features[i, 1] = np.random.beta(4.0, 2.0)
            features[i, 2] = np.random.normal(0.50, 0.12)
            features[i, 3] = np.random.beta(5.0, 1.5)
            features[i, 4] = np.random.beta(4.0, 1.5)
            features[i, 5] = np.random.beta(3.5, 2.0)
        elif work_type == 'street_vendor':
            features[i, 0] = np.random.beta(2.0, 3.0)
            features[i, 1] = np.random.beta(2.5, 3.0)
            features[i, 2] = np.random.normal(0.40, 0.15)
            features[i, 3] = np.random.beta(3.0, 2.5)
            features[i, 4] = np.random.beta(1.5, 4.0)
        elif work_type == 'freelancer':
            features[i, 0] = np.random.beta(2.5, 2.0)
            features[i, 1] = np.random.beta(1.8, 2.5)
            features[i, 2] = np.random.normal(0.55, 0.18)
            features[i, 4] = np.random.beta(2.0, 3.0)
        elif work_type == 'skilled_tradesperson':
            features[i, 0] = np.random.beta(2.8, 2.5)
            features[i, 1] = np.random.beta(3.0, 2.5)
            features[i, 2] = np.random.normal(0.45, 0.14)
            
        # P2 Payment
        payment_quality = np.random.beta(3.0, 1.5)
        features[i, 13] = payment_quality * np.random.beta(4, 1.5)
        features[i, 14] = payment_quality * np.random.beta(3, 2)
        features[i, 15] = max(0, min(1, 1 - np.random.exponential(0.15)))
        features[i, 16] = 0.40 if work_type == 'street_vendor' else np.random.beta(3, 1.5)
        features[i, 22] = 1.0 if np.random.random() < 0.15 else 0.0
        
        # P3 Debt
        features[i, 28] = 1 - np.random.beta(1.5, 4)
        features[i, 29] = 1 - np.random.poisson(1.2) / 5.0
        features[i, 30] = np.random.beta(3, 2)
        
        # P4 Savings
        income_level = features[i, 0]
        features[i, 37] = np.random.beta(2, 4) * (0.5 + income_level * 0.5)
        features[i, 38] = np.random.beta(2, 3)
        features[i, 39] = np.random.beta(1.5, 4)
        features[i, 43] = 1.0 if (work_type == 'freelancer' and np.random.random() < 0.25) else 0.0
        
        # P5 Work & Identity
        features[i, 49] = 1.0 if np.random.random() < 0.90 else 0.0
        features[i, 50] = 1.0 if np.random.random() < 0.85 else 0.0
        features[i, 51] = 1.0 if np.random.random() < 0.70 else 0.0
        features[i, 53] = 1.0 if np.random.random() < 0.35 else 0.0
        features[i, 54] = np.random.beta(4, 1.5) if work_type == 'platform_worker' else 0.50
        
        # P6 Resilience
        has_any_insurance = np.random.random() < 0.45
        features[i, 67] = 1.0 if (has_any_insurance and np.random.random() < 0.70) else 0.0
        features[i, 68] = 1.0 if (has_any_insurance and np.random.random() < 0.40) else 0.0
        features[i, 70] = 1.0 if (work_type in ['platform_worker','street_vendor'] and np.random.random() < 0.30) else 0.0
        features[i, 76] = np.random.beta(2, 5) if has_any_insurance else 0.0
        
        # P7 Social
        features[i, 78] = np.random.beta(1.5, 3)
        features[i, 79] = 1.0 if np.random.random() < 0.20 else 0.0
        features[i, 86] = np.random.beta(2, 2)
        
        # P8 Tax
        has_itr = np.random.random() < 0.30
        features[i, 88] = 1.0 if has_itr else 0.0
        features[i, 89] = np.random.beta(1.5, 4) if has_itr else 0.0
        features[i, 90] = 1.0 if (has_itr and np.random.random() < 0.40) else 0.0
        features[i, 91] = 1.0 if (features[i, 50] > 0.5 and np.random.random() < 0.60) else 0.0
        
    return features

def compute_work_type_medians(df):
    medians = {}
    for wt in df['work_type'].unique():
        sub_df = df[df['work_type'] == wt]
        medians[wt] = {
            'income_cv': sub_df['f1'].median(),
            'income_growth_norm': sub_df['f2'].median(),
            'gig_share_norm': sub_df['f4'].median(),
            'payment_gap_freq': sub_df['f28'].median(),
            'balance_variability': sub_df['f47'].median()
        }
    # Prevent division by zero
    for wt in medians:
        for k in medians[wt]:
            medians[wt][k] = max(medians[wt][k], 0.01)
    return medians

def scorecard_P5(df):
    s, e = PILLAR_FEATURE_RANGES['P5']
    return df.iloc[:, s:e].dot(P5_WEIGHTS)

def scorecard_P7(df):
    s, e = PILLAR_FEATURE_RANGES['P7']
    return df.iloc[:, s:e].dot(P7_WEIGHTS)

def scorecard_P8(df):
    s, e = PILLAR_FEATURE_RANGES['P8']
    return df.iloc[:, s:e].dot(P8_WEIGHTS)

def generate_synthetic_data():
    print("Generating synthetic profiles...")
    counts = {
        'platform_worker': 4500,
        'street_vendor': 4500,
        'skilled_tradesperson': 3000,
        'freelancer': 3000
    }
    
    dfs = []
    for wt, count in counts.items():
        base_features = generate_base_features(wt, count)
        df_wt = pd.DataFrame(base_features, columns=[f'f{i}' for i in range(95)])
        df_wt['work_type'] = wt
        dfs.append(df_wt)
        
    df = pd.concat(dfs, ignore_index=True)
    
    # Fill remaining columns with some reasonable defaults since spec only defines a subset
    for i in range(95):
        if (df[f'f{i}'] == 0).all():
            df[f'f{i}'] = np.random.beta(2, 2, size=len(df))
    df.iloc[:, :95] = df.iloc[:, :95].clip(0, 1)
    
    # Stage 1: Normalisation
    print("Computing work type medians...")
    medians = compute_work_type_medians(df)
    for idx, row in df.iterrows():
        wt = row['work_type']
        df.at[idx, 'f1'] = row['f1'] / medians[wt]['income_cv']
        df.at[idx, 'f2'] = row['f2'] / medians[wt]['income_growth_norm']
        df.at[idx, 'f4'] = row['f4'] / medians[wt]['gig_share_norm']
        df.at[idx, 'f28'] = row['f28'] / medians[wt]['payment_gap_freq']
        df.at[idx, 'f47'] = row['f47'] / medians[wt]['balance_variability']
    
    df.iloc[:, :95] = df.iloc[:, :95].clip(0, 1)
    
    # Export medians
    os.makedirs(ASSETS_DIR, exist_ok=True)
    with open(os.path.join(ASSETS_DIR, 'work_type_medians.json'), 'w') as f:
        json.dump(medians, f, indent=2)
        
    # Stage 2: Cross-Pillar Features
    print("Generating cross-pillar features...")
    df['f95'] = df['f28'] * (1 - df['f1'])
    df['f96'] = (1 - df['f1']) * df['f29']
    df['f97'] = (df['f0'] - df['f28']).clip(0, 1)
    df['f98'] = df['f2'] * (1 - df['f31'])
    
    df['f99'] = (df['f13'] - df['f37']).clip(0, 1)
    df['f100'] = df['f39'] * df['f13']
    df['f101'] = df['f23'] * df['f43']
    
    df['f102'] = df['f67']*0.35 + df['f39']*0.40 + (1-df['f28'])*0.25
    df['f103'] = (df['f102'] - df['f28']).clip(0, 1)
    df['f104'] = (df['f67'] + df['f68']) * df['f1']
    
    df['f105'] = np.minimum(df['f3'], df['f13'])
    df['f106'] = df['f2'] * df['f15']
    df['f107'] = df['f5'] * df['f23']
    df['f108'] = df['f10'] * df['f13']
    
    df['f109'] = (df['f79'] + df['f69']) * df['f1']
    df['f110'] = df['f88'] * df['f5']
    df['f111'] = df[['f78','f79','f80','f81','f82','f83','f84','f85','f86','f87']].mean(axis=1) * df['f0']
    
    df['f112'] = np.random.beta(2, 2, size=len(df))
    df['f113'] = np.random.beta(3, 2, size=len(df))
    df['f114'] = np.random.beta(2, 3, size=len(df))
    
    cross_cols = [f'f{i}' for i in range(95, 115)]
    df[cross_cols] = df[cross_cols].clip(0, 1)
    
    # Target score generation
    # 5. Generate Target Scores (Proxy for creditworthiness)
    df['target_P1'] = df.iloc[:, PILLAR_FEATURE_RANGES['P1'][0]:PILLAR_FEATURE_RANGES['P1'][1]].mean(axis=1)
    df['target_P2'] = df.iloc[:, PILLAR_FEATURE_RANGES['P2'][0]:PILLAR_FEATURE_RANGES['P2'][1]].mean(axis=1)
    df['target_P3'] = df.iloc[:, PILLAR_FEATURE_RANGES['P3'][0]:PILLAR_FEATURE_RANGES['P3'][1]].mean(axis=1)
    df['target_P4'] = df.iloc[:, PILLAR_FEATURE_RANGES['P4'][0]:PILLAR_FEATURE_RANGES['P4'][1]].mean(axis=1)
    df['target_P5'] = df.iloc[:, PILLAR_FEATURE_RANGES['P5'][0]:PILLAR_FEATURE_RANGES['P5'][1]].mean(axis=1)
    df['target_P6'] = df.iloc[:, PILLAR_FEATURE_RANGES['P6'][0]:PILLAR_FEATURE_RANGES['P6'][1]].mean(axis=1)
    df['target_P7'] = df.iloc[:, PILLAR_FEATURE_RANGES['P7'][0]:PILLAR_FEATURE_RANGES['P7'][1]].mean(axis=1)
    df['target_P8'] = df.iloc[:, PILLAR_FEATURE_RANGES['P8'][0]:PILLAR_FEATURE_RANGES['P8'][1]].mean(axis=1)
    
    df['target'] = (0.22 * df['target_P1'] + 0.18 * df['target_P2'] + 0.15 * df['target_P3'] + 0.12 * df['target_P4'] + 
                    0.10 * df['target_P5'] + 0.10 * df['target_P6'] + 0.08 * df['target_P7'] + 0.05 * df['target_P8'] +
                    np.random.normal(0, 0.03, size=len(df))).clip(0, 1)
                    
    # Rename columns to actual feature names
    rename_map = {f'f{i}': FEATURE_NAMES[i] for i in range(95)}
    rename_map.update({f'f{95+i}': CROSS_FEATURE_NAMES[i] for i in range(20)})
    df.rename(columns=rename_map, inplace=True)
    
    # Quality Checks
    print("Running quality checks...")
    feature_cols = FEATURE_NAMES + CROSS_FEATURE_NAMES
    assert (df[feature_cols] >= 0).all().all(), "Some features are negative!"
    assert df.isna().sum().sum() == 0, "Found NaNs!"
    assert len(df) == 15000, "Wrong number of rows!"
    print(f"Target Mean: {df['target'].mean():.3f}, Target Std: {df['target'].std():.3f}")
    
    # Export
    os.makedirs(DATA_DIR, exist_ok=True)
    out_path = os.path.join(DATA_DIR, 'synthetic_profiles.csv')
    df.to_csv(out_path, index=False)
    print(f"Successfully exported 15K synthetic profiles to {out_path}")

if __name__ == "__main__":
    np.random.seed(42)
    generate_synthetic_data()
