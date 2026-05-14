from typing import Annotated

from fastapi import APIRouter, Depends

from app.auth.hmac_validator import verify_hmac_headers
from app.db.connection import get_db
from app.utils.error_handlers import AppException
from pydantic import BaseModel


class UtilityVerifyRequest(BaseModel):
    consumer_number: str
    provider: str


class GstVerifyRequest(BaseModel):
    gst: str


class RationCardVerifyRequest(BaseModel):
    card_number: str


class AbhaVerifyRequest(BaseModel):
    aybha_id: str


router = APIRouter()


@router.post("/verify")
async def verify_utility(
    request: UtilityVerifyRequest,
    _: Annotated[None, Depends(verify_hmac_headers)],
):
    db = get_db()
    record = (
        await db.utility_db.find_one(
            {"consumer_number": request.consumer_number, "provider": request.provider}
        )
        if db is not None
        else None
    )
    if not record:
        # Return a "not_found" but still allow the step to proceed
        # (utility verification is supplementary, not blocking)
        raise AppException(404, "not_found", "Utility record not found in database")
    return {
        "status": "verified",
        "consumer_name": record.get("consumer_name", ""),
        "provider": record.get("provider", request.provider),
        "last_payment_date": record.get("last_payment_date", ""),
        "amount_due": record.get("amount_due", 0),
        "payment_status": record.get("payment_status", "paid"),
    }


@router.post("/gst/verify")
async def verify_gst(
    request: GstVerifyRequest,
    _: Annotated[None, Depends(verify_hmac_headers)],
):
    import re
    if not re.match(r"^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][0-9A-Z]Z[0-9A-Z]$", request.gst):
        raise AppException(400, "invalid_format", "GSTIN format invalid (expected 15-char)")
    db = get_db()
    record = (
        await db.gst_db.find_one({"gst": request.gst})
        if db is not None
        else None
    )
    if not record:
        raise AppException(404, "not_found", "GST record not found")
    return {
        "status": "active",
        "legal_name": record.get("legal_name", ""),
        "trade_name": record.get("trade_name", ""),
        "registration_date": record.get("registration_date", ""),
        "gst_type": record.get("gst_type", "Regular"),
    }


@router.post("/ration/verify")
async def verify_ration_card(
    request: RationCardVerifyRequest,
    _: Annotated[None, Depends(verify_hmac_headers)],
):
    db = get_db()
    record = (
        await db.ration_db.find_one({"card_number": request.card_number})
        if db is not None
        else None
    )
    if not record:
        raise AppException(404, "not_found", "Ration card not found")
    return {
        "status": "active",
        "card_holder": record.get("card_holder", ""),
        "card_type": record.get("card_type", "BPL"),
        "family_members": record.get("family_members", 0),
        "state": record.get("state", ""),
    }


@router.post("/abha/verify")
async def verify_abha(
    request: AbhaVerifyRequest,
    _: Annotated[None, Depends(verify_hmac_headers)],
):
    db = get_db()
    record = (
        await db.abha_db.find_one({"abha_id": request.aybha_id})
        if db is not None
        else None
    )
    if not record:
        raise AppException(404, "not_found", "ABHA record not found")
    return {
        "status": "verified",
        "name": record.get("name", ""),
        "health_id": record.get("health_id", ""),
    }
