import os
import sys
import json
import joblib
import m2cgen as m2c

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from config import MODELS_DIR, EXPORT_DIR, ML_PILLARS, MODEL_TYPES

def export_model(pillar):
    model_path = [os.path.join(MODELS_DIR, f) for f in os.listdir(MODELS_DIR) if f.startswith(pillar.lower() + "_")][0]
    model = joblib.load(model_path)
    
    print(f"Exporting {pillar} to Dart via m2cgen...")
    class_name = f"{pillar}Scorer"
    
    code = m2c.export_to_dart(model)
    code = code.replace("class Model", f"class {class_name}")
    
    out_path = os.path.join(EXPORT_DIR, f"{pillar.lower()}_scorer.dart")
    with open(out_path, "w") as f:
        f.write(code)
    print(f"Saved {out_path}")

def export_meta_learner():
    print("Exporting Meta Learner to Dart...")
    assets_dir = os.path.join(os.path.dirname(MODELS_DIR), 'assets')
    with open(os.path.join(assets_dir, 'meta_lr_coefficients.json'), 'r') as f:
        meta_lr = json.load(f)
        
    coefs = meta_lr['coefficients']
    intercept = meta_lr['intercept']
    
    coef_str = ", ".join([f"{c:.6f}" for c in coefs])
    
    dart_code = f"""import 'dart:math';

class MetaLearnerLR {{
  static const List<double> weights = [
    {coef_str}
  ];
  static const double intercept = {intercept:.6f};

  static double score(List<double> features) {{
    if (features.length != 20) {{
      throw ArgumentError('Meta Learner requires exactly 20 features');
    }}

    double total = intercept;
    for (int i = 0; i < 20; i++) {{
      total += features[i] * weights[i];
    }}

    // Sigmoid
    return 1.0 / (1.0 + exp(-total));
  }}
}}
"""
    out_path = os.path.join(EXPORT_DIR, "meta_learner_lr.dart")
    with open(out_path, "w") as f:
        f.write(dart_code)
    print(f"Saved {out_path}")

def main():
    os.makedirs(EXPORT_DIR, exist_ok=True)
    for p in ML_PILLARS:
        export_model(p)
    export_meta_learner()

if __name__ == "__main__":
    main()
