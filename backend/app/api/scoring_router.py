from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Dict, Any, List
from datetime import datetime, timezone
from app.db.connection import get_db

router = APIRouter()

class ScoreRequest(BaseModel):
    user_id: str
    score_data: Dict[str, Any]

@router.post("/store")
async def store_score(req: ScoreRequest):
    db = get_db()
    if db is None:
        raise HTTPException(status_code=500, detail="Database connection failed")
    
    # Add timestamp
    req.score_data["stored_at"] = datetime.now(timezone.utc).isoformat()
    req.score_data["user_id"] = req.user_id
    
    await db.score_history.insert_one(req.score_data)
    
    return {"status": "success", "message": "Score stored successfully."}

@router.get("/history/{user_id}")
async def get_score_history(user_id: str):
    db = get_db()
    if db is None:
        raise HTTPException(status_code=500, detail="Database connection failed")
        
    cursor = db.score_history.find({"user_id": user_id}).sort("stored_at", -1)
    history = await cursor.to_list(length=100)
    
    # Clean up ObjectIds
    for item in history:
        item["_id"] = str(item["_id"])
        
    return {"user_id": user_id, "history": history}


@router.delete("/history/{user_id}/{proof_id}")
async def delete_score_report(user_id: str, proof_id: str):
    db = get_db()
    if db is None:
        raise HTTPException(status_code=500, detail="Database connection failed")

    # Try primary match: exact user_id + proofId
    result = await db.score_history.delete_one(
        {"user_id": user_id, "proofId": proof_id}
    )

    # Fallback 1: proofId only — handles mismatched user_id formats (USR_ vs ObjectId vs mobile)
    if result.deleted_count == 0:
        result = await db.score_history.delete_one({"proofId": proof_id})

    # Fallback 2: try mobile-only user_id (strip USR_ prefix)
    if result.deleted_count == 0:
        mobile = user_id.replace("USR_", "").strip()
        if mobile != user_id:
            result = await db.score_history.delete_one(
                {"user_id": mobile, "proofId": proof_id}
            )

    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Report not found")

    return {"status": "success", "deleted": proof_id, "user_id": user_id}
