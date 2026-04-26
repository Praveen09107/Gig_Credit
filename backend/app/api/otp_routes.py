import re
from typing import Annotated

from fastapi import APIRouter, Depends

from app.auth.hmac_validator import verify_hmac_headers
from app.db.connection import get_db
from app.schemas.auth_schemas import (
    OtpSendRequest,
    OtpSendResponse,
    OtpVerifyRequest,
    OtpVerifyResponse,
)
from app.utils.error_handlers import AppException

router = APIRouter()


@router.post("/otp/send", response_model=OtpSendResponse)
async def otp_send(request: OtpSendRequest, _: Annotated[None, Depends(verify_hmac_headers)]):
    if not re.match(r"^[6-9]\d{9}$", request.mobile):
        raise AppException(400, "invalid_format", "Mobile must be a valid 10-digit Indian number")

    db = get_db()
    if db is not None:
        await db.otp_db.update_one(
            {"mobile": request.mobile},
            {"$set": {"otp": "000000", "verified": False}},
            upsert=True,
        )
    return {"status": "sent", "expires_in_seconds": 300, "otp": "000000"}


@router.post("/otp/verify", response_model=OtpVerifyResponse)
async def otp_verify(request: OtpVerifyRequest, _: Annotated[None, Depends(verify_hmac_headers)]):
    if not re.match(r"^[6-9]\d{9}$", request.mobile):
        raise AppException(400, "invalid_format", "Mobile must be a valid 10-digit Indian number")
    if request.otp != "000000":
        raise AppException(400, "invalid_otp", "OTP is incorrect")

    db = get_db()
    if db is not None:
        await db.otp_db.update_one({"mobile": request.mobile}, {"$set": {"verified": True}}, upsert=True)
    return {"status": "verified", "mobile_verified": True}
