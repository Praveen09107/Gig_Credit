from fastapi import APIRouter, Depends, HTTPException
from app.db.connection import get_db

router = APIRouter()

@router.post("/explain/full")
async def get_full_explanation(body: dict, db=Depends(get_db)):
    # Frontend sends proof_id or report_id, and user_id
    report_id = body.get("proof_id") or body.get("report_id")
    user_id = body.get("user_id")

    if not report_id and not user_id:
        raise HTTPException(422, "proof_id/report_id or user_id required")

    # Build query — stored documents use proofId inside score_data
    query = {}
    if report_id:
        query["score_data.proofId"] = report_id
    elif user_id:
        query["user_id"] = user_id

    record = await db["score_history"].find_one(
        query,
        sort=[("stored_at", -1)],  # most recent
        projection={"_id": 0}
    )

    if not record:
        raise HTTPException(404, "Score report not found")

    # Data is nested inside score_data
    score_data = record.get("score_data", record)

    # Return full SHAP table + EFS + pillar contributions
    return {
        "report_id": score_data.get("proofId"),
        "final_score": score_data.get("finalScore"),
        "grade": score_data.get("grade"),
        "shap_values": score_data.get("topStrengths", []) + score_data.get("topConcerns", []),
        "efs_score": score_data.get("overallConfidence"),
        "efs_verdict": score_data.get("efsVerdict"),
        "pillar_contributions": score_data.get("pillarContributions", {}),
        "causal_chains": score_data.get("causalChains", []),
        "conformal_interval": score_data.get("overallConfidence"),
        "meta_probability": score_data.get("metaProbability"),
        "model_used": score_data.get("modelUsed", "llama-3.3-70b-versatile"),
        "audit_id": f"AT-{score_data.get('proofId', 'N/A')}"
    }
