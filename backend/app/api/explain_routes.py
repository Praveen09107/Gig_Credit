from fastapi import APIRouter, Depends, HTTPException
from app.db.connection import get_db

router = APIRouter()

@router.post("/explain/full")
async def get_full_explanation(body: dict, db=Depends(get_db)):
    report_id = body.get("report_id")
    user_id = body.get("user_id")

    if not report_id and not user_id:
        raise HTTPException(422, "report_id or user_id required")

    # Try fetching from stored score history
    query = {}
    if report_id:
        query["report_id"] = report_id
    elif user_id:
        query["user_id"] = user_id

    record = await db["score_history"].find_one(
        query,
        sort=[("stored_at", -1)],  # most recent
        projection={"_id": 0}
    )

    if not record:
        raise HTTPException(404, "Score report not found")

    # Return full SHAP table + EFS + pillar contributions
    return {
        "report_id": record.get("report_id"),
        "final_score": record.get("finalScore"),
        "grade": record.get("grade"),
        "shap_values": record.get("shapValues", []),
        "efs_score": record.get("efsScore"),
        "efs_verdict": record.get("efsVerdict"),
        "pillar_contributions": record.get("pillarContributions", []),
        "causal_chains": record.get("causalChains", []),
        "conformal_interval": record.get("conformalInterval"),
        "meta_probability": record.get("metaProbability"),
        "model_used": record.get("modelUsed", "llama-3.3-70b-versatile"),
        "audit_id": record.get("auditId")
    }
