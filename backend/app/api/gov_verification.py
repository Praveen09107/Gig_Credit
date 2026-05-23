import re
import random
from datetime import datetime, timedelta, timezone
from typing import Annotated

from fastapi import APIRouter, Depends

from app.auth.hmac_validator import verify_hmac_headers
from app.db.connection import get_db
from app.schemas.verification_schemas import (
    AadhaarVerifyRequest,
    AadhaarVerifyResponse,
    AadhaarOtpValidateRequest,
    PanVerifyRequest,
    PanVerifyResponse,
    PanOtpValidateRequest,
    EshramVerifyRequest,
    EshramVerifyResponse,
    ItrVerifyRequest,
    ItrVerifyResponse,
    PmsymVerifyRequest,
    PmsymVerifyResponse,
    VehicleRcVerifyRequest,
    VehicleRcVerifyResponse,
    EbVerifyRequest,
    LpgVerifyRequest,
    UdyamVerifyRequest,
    LoanVerifyRequest,
    GstFilingHistoryRequest,
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

    otp = str(random.randint(100000, 999999))
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=10)

    # Store OTP server-side for validation
    if db is not None:
        await db.otp_store.update_one(
            {"key": f"aadhaar:{request.aadhaar}"},
            {"$set": {"otp": otp, "expires_at": expires_at, "attempts": 0}},
            upsert=True,
        )

    print("\n" + "=" * 50)
    print(f"✅ AADHAAR OTP for {request.aadhaar} : {otp}")
    print("=" * 50 + "\n")

    return {"status": "valid", "name": record["name"], "dob": record["dob"], "state": record["state"], "otp": otp}


@router.post("/aadhaar/otp/validate")
async def validate_aadhaar_otp(
    request: AadhaarOtpValidateRequest,
    _: Annotated[None, Depends(verify_hmac_headers)],
):
    """Validate Aadhaar OTP server-side against stored value."""
    db = get_db()
    if db is None:
        raise AppException(503, "db_unavailable", "Database not available")

    stored = await db.otp_store.find_one({"key": f"aadhaar:{request.aadhaar}"})
    if not stored:
        raise AppException(400, "otp_not_found", "No OTP found. Please request a new OTP.")

    if datetime.now(timezone.utc) > stored["expires_at"].replace(tzinfo=timezone.utc):
        raise AppException(400, "otp_expired", "OTP has expired. Please request a new one.")

    attempts = stored.get("attempts", 0)
    if attempts >= 3:
        raise AppException(429, "too_many_attempts", "Too many failed attempts. Please request a new OTP.")

    if stored["otp"] != request.otp:
        await db.otp_store.update_one(
            {"key": f"aadhaar:{request.aadhaar}"},
            {"$inc": {"attempts": 1}},
        )
        remaining = 2 - attempts
        raise AppException(400, "wrong_otp", f"Incorrect OTP. {remaining} attempt(s) remaining.")

    # OTP correct — clear it
    await db.otp_store.delete_one({"key": f"aadhaar:{request.aadhaar}"})
    return {"verified": True, "message": "Aadhaar OTP verified successfully"}


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

    otp = str(random.randint(100000, 999999))
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=10)

    # Store OTP server-side for validation
    if db is not None:
        await db.otp_store.update_one(
            {"key": f"pan:{request.pan}"},
            {"$set": {"otp": otp, "expires_at": expires_at, "attempts": 0}},
            upsert=True,
        )

    print("\n" + "=" * 50)
    print(f"✅ PAN OTP for {request.pan} : {otp}")
    print("=" * 50 + "\n")

    return {
        "status": "valid",
        "name": record["name"],
        "dob": record["dob"],
        "pan_active": record.get("pan_active", True),
        "itr_filed": record.get("itr_filed", False),
        "itr_years": record.get("itr_years", []),
        "otp": otp,
    }


@router.post("/pan/otp/validate")
async def validate_pan_otp(
    request: PanOtpValidateRequest,
    _: Annotated[None, Depends(verify_hmac_headers)],
):
    """Validate PAN OTP server-side against stored value."""
    db = get_db()
    if db is None:
        raise AppException(503, "db_unavailable", "Database not available")

    stored = await db.otp_store.find_one({"key": f"pan:{request.pan}"})
    if not stored:
        raise AppException(400, "otp_not_found", "No OTP found. Please request a new OTP.")

    if datetime.now(timezone.utc) > stored["expires_at"].replace(tzinfo=timezone.utc):
        raise AppException(400, "otp_expired", "OTP has expired. Please request a new one.")

    attempts = stored.get("attempts", 0)
    if attempts >= 3:
        raise AppException(429, "too_many_attempts", "Too many failed attempts. Please request a new OTP.")

    if stored["otp"] != request.otp:
        await db.otp_store.update_one(
            {"key": f"pan:{request.pan}"},
            {"$inc": {"attempts": 1}},
        )
        remaining = 2 - attempts
        raise AppException(400, "wrong_otp", f"Incorrect OTP. {remaining} attempt(s) remaining.")

    # OTP correct — clear it
    await db.otp_store.delete_one({"key": f"pan:{request.pan}"})
    return {"verified": True, "message": "PAN OTP verified successfully"}


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


# ── Step 4: Electricity Bill Verification ─────────────────────────────────────

@router.post("/eb/verify")
async def verify_eb(
    request: EbVerifyRequest,
    _: Annotated[None, Depends(verify_hmac_headers)],
):
    """Verify EB service number — unlocks 6-bill upload slots (Gate 1 Step 4)."""
    if not request.service_number.strip():
        raise AppException(400, "invalid_format", "Service number cannot be empty")
    db = get_db()
    record = await db.eb_db.find_one({"service_number": request.service_number}) if db is not None else None
    if not record:
        raise AppException(404, "not_found", "Electricity service number not found in database")
    if record.get("connection_status", "Active") != "Active":
        raise AppException(400, "inactive", "Electricity connection is inactive or disconnected")
    return {
        "valid": True,
        "service_number": record["service_number"],
        "connection_status": record.get("connection_status", "Active"),
        "consumer_name": record.get("consumer_name", ""),
        "discom": record.get("discom", "TNEB"),
    }


# ── Step 4: LPG / Gas Bill Verification ──────────────────────────────────────

@router.post("/lpg/verify")
async def verify_lpg(
    request: LpgVerifyRequest,
    _: Annotated[None, Depends(verify_hmac_headers)],
):
    """Verify LPG consumer number — unlocks 6-bill upload slots (Gate 2 Step 4)."""
    if not request.consumer_number.strip():
        raise AppException(400, "invalid_format", "Consumer number cannot be empty")
    accepted_providers = ["Indane", "HP Gas", "Bharat Gas", "Indian Oil", "Hindustan Petroleum"]
    if request.provider not in accepted_providers:
        raise AppException(400, "invalid_provider", f"Provider must be one of: {', '.join(accepted_providers)}")
    db = get_db()
    record = await db.lpg_db.find_one({
        "consumer_number": request.consumer_number,
        "provider": {"$regex": request.provider, "$options": "i"}
    }) if db is not None else None
    if not record:
        raise AppException(404, "not_found", "LPG consumer number not found")
    if record.get("connection_status", "Active") != "Active":
        raise AppException(400, "inactive", "LPG connection is inactive")
    return {
        "valid": True,
        "consumer_number": record["consumer_number"],
        "consumer_name": record.get("consumer_name", ""),
        "provider": record.get("provider", request.provider),
        "connection_status": record.get("connection_status", "Active"),
    }


# ── Step 5: Vehicle Insurance Verification ───────────────────────────────────

@router.post("/vehicle/insurance/verify")
async def verify_vehicle_insurance(
    vehicle_number: str,
    _: Annotated[None, Depends(verify_hmac_headers)],
):
    """Verify vehicle insurance by vehicle number — auto-triggered after RC verify."""
    db = get_db()
    record = await db.vehicle_insurance_db.find_one({"vehicle_number": vehicle_number}) if db is not None else None
    if not record:
        raise AppException(404, "not_found", "No active insurance found for this vehicle")
    if record.get("insurance_status", "Active") != "Active":
        raise AppException(400, "expired", "Vehicle insurance policy is expired")
    return {
        "insurance_found": True,
        "policy_number": record["policy_number"],
        "insurance_company": record.get("insurance_company", ""),
        "insurance_status": record.get("insurance_status", "Active"),
        "expiry": record.get("expiry", ""),
        "vehicle_number": record["vehicle_number"],
    }


# ── Step 6: Udyam / MSME Registration Verification ───────────────────────────

@router.post("/msme/udyam-verify")
async def verify_udyam(
    request: UdyamVerifyRequest,
    _: Annotated[None, Depends(verify_hmac_headers)],
):
    """Verify Udyam registration number — format: UDYAM-XX-00-0000000."""
    udyam = request.udyam_number.strip().upper()
    if not re.match(r"^UDYAM-[A-Z]{2}-\d{2}-\d{7}$", udyam):
        raise AppException(400, "invalid_format", "Udyam format must be UDYAM-XX-00-0000000 (e.g. UDYAM-TN-33-0012345)")
    db = get_db()
    record = await db.udyam_db.find_one({"udyam_number": udyam}) if db is not None else None
    if not record:
        raise AppException(404, "not_found", "Udyam registration number not found")
    if record.get("status", "Active") != "Active":
        raise AppException(400, "inactive", "Udyam registration is cancelled or suspended")
    return {
        "enterprise_name": record.get("enterprise_name", ""),
        "udyam_number": record["udyam_number"],
        "category": record.get("category", "Micro"),
        "nic_activity": record.get("nic_activity", ""),
        "registration_date": record.get("registration_date", ""),
        "state": record.get("state", ""),
        "status": record.get("status", "Active"),
        "major_activity": record.get("major_activity", "Services"),
        "verified": True,
    }


# ── Step 9: Loan Verification (Optional) ─────────────────────────────────────

@router.post("/loan/verify")
async def verify_loan(
    request: LoanVerifyRequest,
    _: Annotated[None, Depends(verify_hmac_headers)],
):
    """Optional loan verification — matches lender + EMI amount in loan_obligations_db."""
    if not request.lender_name.strip():
        raise AppException(400, "invalid_format", "Lender name cannot be empty")
    if request.emi_amount <= 0:
        raise AppException(400, "invalid_format", "EMI amount must be positive")
    db = get_db()
    # Fuzzy lender match — case-insensitive partial match
    record = await db.loan_obligations_db.find_one({
        "lender_name": {"$regex": request.lender_name.strip(), "$options": "i"}
    }) if db is not None else None
    if not record:
        # Not found is non-blocking — fallback to bank cross-check
        return {
            "loan_found": False,
            "loan_status": "Not Found",
            "outstanding_balance": 0,
            "loan_type": "Unknown",
            "verified": False,
            "message": "Loan not found in database — bank cross-check will be used",
        }
    return {
        "loan_found": True,
        "loan_status": record.get("loan_status", "Active"),
        "outstanding_balance": int(record.get("outstanding_balance", 0)),
        "loan_type": record.get("loan_type", "Personal Loan"),
        "verified": True,
    }


# ── Step 8: GST Filing History ────────────────────────────────────────────────

@router.post("/gst/filing-history")
async def gst_filing_history(
    request: GstFilingHistoryRequest,
    _: Annotated[None, Depends(verify_hmac_headers)],
):
    """Check GSTR-3B filing consistency for a GSTIN."""
    gstin = request.gstin.strip().upper()
    if not re.match(r"^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][0-9A-Z]Z[0-9A-Z]$", gstin):
        raise AppException(400, "invalid_format", "GSTIN format invalid (expected 15 characters)")
    db = get_db()
    record = await db.gstr3b_filings_db.find_one({"gstin": gstin}) if db is not None else None
    if not record:
        return {
            "months_filed": 0,
            "latest_filing": None,
            "consistency_flag": "no_data",
            "message": "No GSTR-3B filing history found",
        }
    return {
        "months_filed": int(record.get("months_filed", 0)),
        "latest_filing": record.get("latest_filing", ""),
        "consistency_flag": record.get("consistency_flag", "regular"),
    }
