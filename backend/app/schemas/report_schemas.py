from typing import Dict, List

from pydantic import BaseModel


class FactorItem(BaseModel):
    feature_label: str
    pillar: str
    impact: float


class ReportGenerateRequest(BaseModel):
    credit_score: int
    grade: str
    risk_level: str
    work_type: str
    language: str
    pillar_scores: Dict[str, float]
    positive_factors: List[FactorItem]
    negative_factors: List[FactorItem]
    confidence_level: str


class ReportGenerateResponse(BaseModel):
    status: str
    language: str
    explanation: str
    suggestions: List[str]
    model_used: str | None = None
    generated_at: str | None = None