from typing import Annotated

from fastapi import APIRouter, Depends

from app.auth.hmac_validator import verify_hmac_headers
from app.db.connection import get_db
from app.schemas.verification_schemas import InsurancePolicyVerifyRequest, InsuranceVerifyResponse
from app.utils.error_handlers import AppException

router = APIRouter()


@router.post("/policy/verify", response_model=InsuranceVerifyResponse)
async def verify_insurance_policy(
    request: InsurancePolicyVerifyRequest,
    _: Annotated[None, Depends(verify_hmac_headers)],
):
    db = get_db()
    record = (
        await db.insurance_db.find_one(
            {"policy_number": request.policy_number, "policy_type": request.policy_type}
        )
        if db is not None
        else None
    )
    if not record:
        raise AppException(404, "not_found", "Insurance policy not found")
    return {
        "status": "active",
        "policy_holder": record["policy_holder"],
        "insurer": record["insurer"],
        "sum_insured": record.get("sum_insured"),
        "premium_annual": record.get("premium_annual"),
        "policy_start": record.get("policy_start"),
        "policy_expiry": record["policy_expiry"],
        "vehicle_number": record.get("vehicle_number"),
    }
