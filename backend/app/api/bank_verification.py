import re
from typing import Annotated
from datetime import datetime

from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException

from app.auth.hmac_validator import verify_hmac_headers
from app.db.connection import get_db
from app.schemas.verification_schemas import (
    AccountVerifyRequest,
    AccountVerifyResponse,
    IfscVerifyRequest,
    IfscVerifyResponse,
    LoanCheckRequest,
    LoanCheckResponse,
)
from app.utils.error_handlers import AppException

router = APIRouter()


@router.post("/ifsc/verify", response_model=IfscVerifyResponse)
async def verify_ifsc(
    request: IfscVerifyRequest,
    _: Annotated[None, Depends(verify_hmac_headers)],
):
    if not re.match(r"^[A-Z]{4}0[A-Z0-9]{6}$", request.ifsc):
        raise AppException(400, "invalid_format", "IFSC format invalid")
    db = get_db()
    record = await db.ifsc_db.find_one({"ifsc": request.ifsc}) if db is not None else None
    if not record:
        raise AppException(404, "not_found", "IFSC not found")
    return {
        "status": "valid",
        "bank_name": record["bank_name"],
        "branch_name": record["branch_name"],
        "city": record["city"],
        "state": record["state"],
    }


@router.post("/account/verify", response_model=AccountVerifyResponse)
async def verify_account(
    request: AccountVerifyRequest,
    _: Annotated[None, Depends(verify_hmac_headers)],
):
    if not re.match(r"^\d{9,18}$", request.account_number):
        raise AppException(400, "invalid_format", "Account number must be 9-18 digits")
    if not re.match(r"^[A-Z]{4}0[A-Z0-9]{6}$", request.ifsc):
        raise AppException(400, "invalid_format", "IFSC format invalid")

    db = get_db()
    record = await db.bank_accounts_db.find_one(
        {"account_number": request.account_number, "ifsc": request.ifsc}
    ) if db is not None else None
    if not record:
        raise AppException(404, "not_found", "Account record not found")
    return {
        "status": "valid",
        "account_holder": record["account_holder"],
        "account_type": record.get("account_type", "Savings"),
        "account_active": bool(record.get("account_active", True)),
    }


@router.post("/loan/check", response_model=LoanCheckResponse)
async def check_loans(
    request: LoanCheckRequest,
    _: Annotated[None, Depends(verify_hmac_headers)],
):
    if not re.match(r"^\d{9,18}$", request.account_number):
        raise AppException(400, "invalid_format", "Account number must be 9-18 digits")
    db = get_db()
    record = await db.loan_accounts_db.find_one({"account_number": request.account_number}) if db is not None else None
    if not record:
        return {"has_active_loans": False, "loan_count": 0, "loans": []}
    loans = record.get("loans", [])
    return {
        "has_active_loans": bool(record.get("has_active_loans", bool(loans))),
        "loan_count": len(loans),
        "loans": loans,
    }

@router.post("/statement/upload")
async def upload_bank_statement(
    file: UploadFile = File(...),
    user_id: str = Form(...),
    db=Depends(get_db)
):
    if file.content_type != "application/pdf":
        raise HTTPException(400, "Only PDF files accepted")

    contents = await file.read()
    if len(contents) > 10 * 1024 * 1024:  # 10MB limit
        raise HTTPException(400, "File too large — max 10MB")

    # Store temporarily for processing pipeline
    doc = {
        "user_id": user_id,
        "filename": file.filename,
        "content_type": file.content_type,
        "size_bytes": len(contents),
        "uploaded_at": datetime.utcnow().isoformat(),
        "status": "uploaded",
        "parsed": False
    }
    result = await db["bank_statements"].insert_one(doc)

    return {
        "status": "uploaded",
        "statement_id": str(result.inserted_id),
        "message": "Bank statement received. Processing on device.",
        "size_bytes": len(contents)
    }
