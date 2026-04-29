import re
from typing import Annotated

from fastapi import APIRouter, Depends

from app.auth.hmac_validator import verify_hmac_headers
from app.db.connection import get_db
from app.schemas.verification_schemas import (
    AadhaarVerifyRequest,
    AadhaarVerifyResponse,
    EshramVerifyRequest,
    EshramVerifyResponse,
    ItrVerifyRequest,
    ItrVerifyResponse,
    PanVerifyRequest,
    PanVerifyResponse,
    PmsymVerifyRequest,
    PmsymVerifyResponse,
    VehicleRcVerifyRequest,
    VehicleRcVerifyResponse,
)
from app.utils.error_handlers import AppException

router = APIRouter()


@router.post("/aadhaar/verify", response_model=AadhaarVerifyResponse)
async def verify_aadhaar(
    request: AadhaarVerifyRequest,
    _: Annotated[None, Depends(verify_hmac_headers)],
):
    if not re.match(r"^[2-9]\d{11}$", request.aadhaar):
        raise AppException(400, "invalid_format", "Aadhaar must be 12 digits")
    db = get_db()
    record = await db.aadhaar_db.find_one({"aadhaar": request.aadhaar}) if db is not None else None
    if not record:
        raise AppException(404, "not_found", "Aadhaar record not found")
    
    # Generate OTP for Aadhaar and print to terminal
    import random
    otp = str(random.randint(100000, 999999))
    print("\n" + "="*50)
    print(f"✅ AADHAAR OTP for {request.aadhaar} : {otp}")
    print("="*50 + "\n")
    
    return {"status": "valid", "name": record["name"], "dob": record["dob"], "state": record["state"], "otp": otp}


@router.post("/pan/verify", response_model=PanVerifyResponse)
async def verify_pan(
    request: PanVerifyRequest,
    _: Annotated[None, Depends(verify_hmac_headers)],
):
    if not re.match(r"^[A-Z]{5}\d{4}[A-Z]$", request.pan):
        raise AppException(400, "invalid_format", "PAN format invalid")
    db = get_db()
    record = await db.pan_db.find_one({"pan": request.pan}) if db is not None else None
    if not record:
        raise AppException(404, "not_found", "PAN record not found")
    
    # Generate OTP for PAN and print to terminal
    import random
    otp = str(random.randint(100000, 999999))
    print("\n" + "="*50)
    print(f"✅ PAN OTP for {request.pan} : {otp}")
    print("="*50 + "\n")

    return {
        "status": "valid",
        "name": record["name"],
        "dob": record["dob"],
        "pan_active": record.get("pan_active", True),
        "itr_filed": record.get("itr_filed", False),
        "itr_years": record.get("itr_years", []),
        "otp": otp
    }


@router.post("/vehicle/rc/verify", response_model=VehicleRcVerifyResponse)
async def verify_vehicle_rc(
    request: VehicleRcVerifyRequest,
    _: Annotated[None, Depends(verify_hmac_headers)],
):
    if not re.match(r"^[A-Z]{2}\d{2}[A-Z]{1,3}\d{1,4}$", request.vehicle_number):
        raise AppException(400, "invalid_format", "Vehicle number format invalid")
    db = get_db()
    record = await db.vehicle_rc_db.find_one({"vehicle_number": request.vehicle_number}) if db is not None else None
    if not record:
        raise AppException(404, "not_found", "RC record not found")
    return {
        "status": "valid",
        "owner_name": record["owner_name"],
        "vehicle_class": record["vehicle_class"],
        "chassis_number": record["chassis_number"],
        "engine_number": record["engine_number"],
        "registration_date": record["registration_date"],
        "rc_expiry": record["rc_expiry"],
        "fitness_expiry": record["fitness_expiry"],
    }


@router.post("/eshram/verify", response_model=EshramVerifyResponse)
async def verify_eshram(
    request: EshramVerifyRequest,
    _: Annotated[None, Depends(verify_hmac_headers)],
):
    if not re.match(r"^UAN[A-Z0-9]{12}$", request.uan):
        raise AppException(400, "invalid_format", "UAN format invalid")
    db = get_db()
    record = await db.eshram_db.find_one({"uan": request.uan}) if db is not None else None
    if not record:
        raise AppException(404, "not_found", "eShram record not found")
    return {
        "status": "registered",
        "name": record["name"],
        "worker_category": record["worker_category"],
        "registration_date": record["registration_date"],
    }


@router.post("/pmsym/verify", response_model=PmsymVerifyResponse)
async def verify_pmsym(
    request: PmsymVerifyRequest,
    _: Annotated[None, Depends(verify_hmac_headers)],
):
    if not re.match(r"^UAN[A-Z0-9]{12}$", request.uan):
        raise AppException(400, "invalid_format", "UAN format invalid")
    db = get_db()
    record = await db.pmsym_db.find_one({"uan": request.uan}) if db is not None else None
    if not record:
        raise AppException(404, "not_found", "PMSYM record not found")
    return {
        "status": "active",
        "months_contributed": int(record.get("months_contributed", 0)),
        "last_contribution_date": record.get("last_contribution_date", ""),
    }


@router.post("/income-tax/itr/verify", response_model=ItrVerifyResponse)
async def verify_itr(
    request: ItrVerifyRequest,
    _: Annotated[None, Depends(verify_hmac_headers)],
):
    if not re.match(r"^[A-Z]{5}\d{4}[A-Z]$", request.pan):
        raise AppException(400, "invalid_format", "PAN format invalid")
    db = get_db()
    record = (
        await db.itr_db.find_one({"pan": request.pan, "assessment_year": request.assessment_year})
        if db is not None
        else None
    )
    if not record:
        raise AppException(404, "not_found", "ITR record not found")
    return {
        "status": "filed",
        "assessment_year": record["assessment_year"],
        "itr_form": record["itr_form"],
        "gross_income": int(record["gross_income"]),
        "tax_paid": int(record.get("tax_paid", 0)),
        "filing_date": record["filing_date"],
    }
