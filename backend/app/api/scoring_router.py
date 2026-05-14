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
