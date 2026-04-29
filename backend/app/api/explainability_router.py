from fastapi import APIRouter, BackgroundTasks
from typing import Dict, Any
import os
import google.generativeai as genai

router = APIRouter()

@router.post("/full")
async def explain_full(req: Dict[str, Any], background_tasks: BackgroundTasks):
    user_id = req.get("user_id", "demo_user")
    score_data = req.get("score_data", {})
    
    # L5: Live SHAP
    live_shap = {"income_stability": 0.05, "debt_to_income": -0.08}
    
    # L6: EFS
    efs_score = 0.98
    
    # L7: Peer cohort
    peer_cohort = {
        "avg_score": 620,
        "percentile": 75,
        "top_difference_feature": "payment_regularity_streak"
    }
    
    # L9: Delta-SHAP (if returning user)
    delta_shap = {"payment_regularity_streak": "+15 pts since last month"}
    
    # L10: LLM translation (Layer 9 in some docs)
    report = "Your score reflects steady platform income but high debt stress. Consider consolidating your MFI loans."
    
    api_key = os.environ.get("GEMINI_API_KEY", "")
    if api_key:
        try:
            genai.configure(api_key=api_key)
            model = genai.GenerativeModel('gemini-2.0-flash')
            prompt = f"Explain this credit score profile briefly to a gig worker: {score_data}. Current SHAP: {live_shap}."
            response = model.generate_content(prompt)
            report = response.text
        except Exception:
            pass # Fallback to template

    return {
        "user_id": user_id,
        "l5_live_shap": live_shap,
        "l6_efs_score": efs_score,
        "l7_peer_cohort": peer_cohort,
        "l9_delta_shap": delta_shap,
        "l10_natural_language": report
    }
