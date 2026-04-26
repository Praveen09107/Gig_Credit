from datetime import datetime, timezone
from typing import Annotated

from fastapi import APIRouter, Depends

from app.auth.hmac_validator import verify_hmac_headers
from app.schemas.report_schemas import ReportGenerateRequest
from app.services.llm_service import generate_report_text

router = APIRouter()


@router.post("/report/generate")
async def report_generate(
    request: ReportGenerateRequest,
    _: Annotated[None, Depends(verify_hmac_headers)],
):
    llm_result = await generate_report_text(request)
    return {
        "status": llm_result["status"],
        "language": llm_result["language"],
        "explanation": llm_result["explanation"],
        "suggestions": llm_result["suggestions"],
        "model_used": llm_result.get("model_used"),
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }