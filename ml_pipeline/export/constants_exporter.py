import os
import sys
import json

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from config import (
    ASSETS_DIR, EXPORT_DIR, PILLAR_WEIGHTS, FEATURE_NAMES, CROSS_FEATURE_NAMES,
    ALL_FEATURE_NAMES, FEATURE_DISPLAY_NAMES, WORK_TYPES
)

def export_actionability_tags():
    tags = {}
    for f in ALL_FEATURE_NAMES:
        if 'ratio' in f or 'score' in f:
            tags[f] = {"actionable": "behavioural"}
        elif 'verified' in f or 'registered' in f or 'filed' in f:
            tags[f] = {"actionable": "immediate"}
        else:
            tags[f] = {"actionable": "non_actionable"}
    
    with open(os.path.join(ASSETS_DIR, 'actionability_tags.json'), 'w') as f:
        json.dump(tags, f, indent=2)
        
def export_feature_display_names():
    with open(os.path.join(ASSETS_DIR, 'feature_display_names.json'), 'w') as f:
        json.dump(FEATURE_DISPLAY_NAMES, f, indent=2)

def export_pillar_weights():
    with open(os.path.join(ASSETS_DIR, 'pillar_weights.json'), 'w') as f:
        json.dump(PILLAR_WEIGHTS, f, indent=2)

def export_causal_chains():
    chains = [{"rule": f"Rule {i}", "suggestion": f"Suggestion {i}"} for i in range(1, 16)]
    with open(os.path.join(ASSETS_DIR, 'causal_chains.json'), 'w') as f:
        json.dump(chains, f, indent=2)

def export_scoring_constants_dart():
    code = """class ScoringConstants {
  static const int minScore = 300;
  static const int maxScore = 900;
}
"""
    with open(os.path.join(EXPORT_DIR, 'scoring_constants.dart'), 'w') as f:
        f.write(code)

def main():
    os.makedirs(ASSETS_DIR, exist_ok=True)
    os.makedirs(EXPORT_DIR, exist_ok=True)
    export_actionability_tags()
    export_feature_display_names()
    export_pillar_weights()
    export_causal_chains()
    export_scoring_constants_dart()
    print("Exported JSON constants and dart constants.")

if __name__ == "__main__":
    main()
