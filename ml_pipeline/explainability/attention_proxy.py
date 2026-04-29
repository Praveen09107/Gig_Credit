import os
import sys
import json
import joblib
import numpy as np

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from config import (
    MODELS_DIR, ASSETS_DIR, ML_PILLARS, MODEL_TYPES,
    PILLAR_FEATURE_RANGES, PILLAR_CROSS_INDICES, ALL_FEATURE_NAMES
)

def main():
    print("Extracting feature importances for proxy attention...")
    attention_dict = {}
    
    for pillar in ML_PILLARS:
        model_path = [os.path.join(MODELS_DIR, f) for f in os.listdir(MODELS_DIR) if f.startswith(pillar.lower() + "_")][0]
        model = joblib.load(model_path)
        
        base_start, base_end = PILLAR_FEATURE_RANGES[pillar]
        base_cols = ALL_FEATURE_NAMES[base_start:base_end]
        cross_indices = [idx - 95 for idx in PILLAR_CROSS_INDICES.get(pillar, [])]
        cross_cols = [ALL_FEATURE_NAMES[95 + idx] for idx in cross_indices]
        pillar_features = base_cols + cross_cols
        
        importances = model.feature_importances_
            
        importances = np.array(importances)
        # Normalize
        s = np.sum(importances)
        if s > 0:
            importances = importances / s
            
        attention_dict[pillar] = {
            f_name: float(imp) for f_name, imp in zip(pillar_features, importances)
        }

    os.makedirs(ASSETS_DIR, exist_ok=True)
    out_path = os.path.join(ASSETS_DIR, 'tabnet_attention.json')
    with open(out_path, 'w') as f:
        json.dump(attention_dict, f, indent=2)
    print(f"Exported proxy attention to {out_path}")

if __name__ == '__main__':
    main()
