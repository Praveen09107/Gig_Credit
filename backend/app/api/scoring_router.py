from fastapi import APIRouter, BackgroundTasks
from pydantic import BaseModel
from typing import Dict, Any, List
import google.generativeai as genai
import os

router = APIRouter()

class ScoreRequest(BaseModel):
    user_id: str
    score_data: Dict[str, Any]

@router.post("/store")
async def store_score(req: ScoreRequest):
    return {"status": "success", "message": "Score stored successfully."}

@router.get("/history/{user_id}")
async def get_score_history(user_id: str):
    return {"user_id": user_id, "history": []}


