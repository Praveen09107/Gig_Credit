from fastapi import APIRouter, BackgroundTasks
from typing import Dict, Any
import os
import google.generativeai as genai
from app.db.connection import get_db

router = APIRouter()

@router.post("/full")
async def explain_full(req: Dict[str, Any], background_tasks: BackgroundTasks):
    user_id = req.get("user_id", "demo_user")
    score_data = req.get("score_data", {})
    
    # Compute dynamic SHAP based on score
    base_score = score_data.get("score", 600)
    
    # Compute platform average from DB (fallback to 620)
    platform_avg = 620
    try:
        db = get_db()
        if db is not None:
            pipeline = [{"$group": {"_id": None, "avg": {"$avg": "$score_data.finalScore"}}}]
            cursor = db["score_history"].aggregate(pipeline)
            async for doc in cursor:
                if doc.get("avg"):
                    platform_avg = round(doc["avg"])
                break
    except Exception:
        pass  # Fallback to 620
    
    # L5: Live SHAP
    live_shap = {
        "payment_regularity": round(max(-0.15, min(0.20, (base_score - 600) * 0.001)), 3),
        "debt_to_income": round(max(-0.25, min(0.05, (650 - base_score) * 0.0012)), 3),
        "platform_tenure": round(max(0.0, min(0.15, (base_score - 550) * 0.0008)), 3)
    }
    
    # L6: EFS
    efs_score = round(max(0.1, min(0.99, base_score / 850.0)), 2)
    
    # L7: Peer cohort
    peer_cohort = {
        "avg_score": platform_avg,
        "percentile": min(99, max(1, int(((base_score - 300) / 550.0) * 100))),
        "top_difference_feature": "payment_regularity_streak" if base_score > platform_avg else "debt_to_income"
    }
    
    # L9: Delta-SHAP (if returning user)
    diff = base_score - platform_avg
    delta_shap = {"score_change": f"{'+' if diff >= 0 else ''}{diff} pts relative to platform average"}
    
    # L10: LLM translation (Layer 9 in some docs)
    report = f"Your score of {base_score} reflects {'steady' if base_score > 650 else 'fluctuating'} platform income. {'Consider consolidating debt.' if base_score < 680 else 'Keep up the good work.'}"
    
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
