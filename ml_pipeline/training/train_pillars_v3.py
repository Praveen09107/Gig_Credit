import os
import sys
import json
import joblib
import numpy as np
import pandas as pd
from lightgbm import LGBMRegressor
from xgboost import XGBRegressor
from sklearn.ensemble import ExtraTreesRegressor
from sklearn.metrics import r2_score, mean_squared_error

# Ensure ml_pipeline is in path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from config import (
    DATA_DIR, MODELS_DIR, FEATURE_NAMES, CROSS_FEATURE_NAMES,
    PILLAR_FEATURE_RANGES, PILLAR_CROSS_INDICES,
    TRAIN_RATIO, VAL_RATIO, SEED, MODEL_TYPES,
    XGB_PARAMS_P2, XGB_PARAMS_P3
)

def load_data():
    csv_path = os.path.join(DATA_DIR, 'synthetic_profiles.csv')
    print(f"Loading data from {csv_path}")
    df = pd.read_csv(csv_path)
    
    # Shuffle
    df = df.sample(frac=1, random_state=SEED).reset_index(drop=True)
    
    n_total = len(df)
    n_train = int(n_total * TRAIN_RATIO)
    n_val = int(n_total * VAL_RATIO)
    
    train_df = df.iloc[:n_train]
    val_df = df.iloc[n_train:n_train + n_val]
    cal_df = df.iloc[n_train + n_val:]
    
    print(f"Data split: Train={len(train_df)}, Val={len(val_df)}, Cal={len(cal_df)}")
    
    # We will save calibration data for Task A5
    cal_path = os.path.join(DATA_DIR, 'calibration_profiles.csv')
    cal_df.to_csv(cal_path, index=False)
    
    return train_df, val_df, cal_df

def get_pillar_features(df, pillar):
    """Extract base + cross features for a pillar."""
    base_start, base_end = PILLAR_FEATURE_RANGES[pillar]
    base_cols = FEATURE_NAMES[base_start:base_end]
    
    cross_indices = PILLAR_CROSS_INDICES.get(pillar, [])
    cross_cols = [CROSS_FEATURE_NAMES[idx - 95] for idx in cross_indices]
    
    return df[base_cols + cross_cols].values

def train_pillar_model(pillar, train_df, val_df):
    model_type = MODEL_TYPES[pillar]
    print(f"\n--- Training {pillar} ({model_type}) ---")
    
    X_train = get_pillar_features(train_df, pillar)
    y_train = train_df[f'target_{pillar}'].values
    
    X_val = get_pillar_features(val_df, pillar)
    y_val = val_df[f'target_{pillar}'].values
    
    if model_type == 'lgbm':
        model = LGBMRegressor(
            n_estimators=300 if pillar == 'P1' else 250,
            max_depth=5,
            learning_rate=0.05,
            num_leaves=31,
            random_state=SEED,
            n_jobs=-1
        )
    elif model_type == 'xgb':
        model = XGBRegressor(**XGB_PARAMS_P2)
    elif model_type == 'xgb_shallow':
        model = XGBRegressor(**XGB_PARAMS_P3)
    elif model_type == 'extratrees':
        model = ExtraTreesRegressor(
            n_estimators=200,
            max_depth=8,
            min_samples_leaf=10,
            random_state=SEED,
            n_jobs=-1
        )
    else:
        raise ValueError(f"Unknown model type: {model_type}")
    
    # Fit the model
    if model_type in ['lgbm']:
        model.fit(
            X_train, y_train,
            eval_set=[(X_val, y_val)]
        )
    elif model_type in ['xgb', 'xgb_shallow']:
        model.fit(
            X_train, y_train,
            eval_set=[(X_val, y_val)],
            verbose=False
        )
    else:
        model.fit(X_train, y_train)
    
    # Evaluate
    val_preds = model.predict(X_val)
    r2 = r2_score(y_val, val_preds)
    rmse = np.sqrt(mean_squared_error(y_val, val_preds))
    print(f"{pillar} Validation R²: {r2:.4f}, RMSE: {rmse:.4f}")
    
    # Save model
    out_name = f"{pillar.lower()}_{'lgbm' if model_type == 'lgbm' else 'xgb' if 'xgb' in model_type else 'et'}.pkl"
    out_path = os.path.join(MODELS_DIR, out_name)
    joblib.dump(model, out_path)
    print(f"Saved to {out_path}")
    
    return model

def main():
    os.makedirs(MODELS_DIR, exist_ok=True)
    train_df, val_df, cal_df = load_data()
    
    pillars_to_train = ['P1', 'P2', 'P3', 'P4', 'P6']
    
    for p in pillars_to_train:
        train_pillar_model(p, train_df, val_df)
        
if __name__ == '__main__':
    main()
