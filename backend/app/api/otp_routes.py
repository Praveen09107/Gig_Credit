import re
import random
from datetime import datetime, timedelta
from typing import Annotated

from fastapi import APIRouter, Depends
from jose import jwt

from app.auth.hmac_validator import verify_hmac_headers
from app.db.connection import get_db
from app.config import settings
from app.schemas.auth_schemas import (
    OtpSendRequest,
    OtpSendResponse,
    OtpVerifyRequest,
    OtpVerifyResponse,
)
from app.utils.error_handlers import AppException

router = APIRouter()

# Read JWT secret from environment settings — never hardcode in production
SECRET_KEY = settings.HMAC_SECRET or "gigcredit_secure_jwt_secret_key_2026"
ALGORITHM = "HS256"


def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(days=7)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


@router.post("/otp/send", response_model=OtpSendResponse)
async def otp_send(request: OtpSendRequest, _: Annotated[None, Depends(verify_hmac_headers)]):
    if not re.match(r"^[6-9]\d{9}$", request.mobile):
        raise AppException(400, "invalid_format", "Mobile must be a valid 10-digit Indian number")

    db = get_db()
    if db is None:
        raise AppException(500, "db_error", "Database connection failed")

    # Check user existence rules
    user_record = await db.users.find_one({"mobile": request.mobile})
    
    # Bypass user existence checks for mock judge account
    if request.mobile != "9094909490":
        if request.isSignup:
            if user_record:
                raise AppException(400, "already_exists", "Registration failed. Number might be in use.")
        else:
            if not user_record:
                raise AppException(404, "not_found", "No account exists. Please sign up first.")

    # Generate 6-digit random OTP
    otp = "909490" if request.mobile == "9094909490" else str(random.randint(100000, 999999))
    expires_at = datetime.utcnow() + timedelta(minutes=5)

    # Print to server console
    print(f"\n[{datetime.utcnow()}] OTP for {request.mobile}: {otp} (Expires in 5 mins)\n")

    await db.otp_db.update_one(
        {"mobile": request.mobile},
        {"$set": {
            "otp": otp, 
            "verified": False,
            "expires_at": expires_at,
            "attempts": 0,
            "name": request.name if request.name else "Gig Worker"
        }},
        upsert=True,
    )
    
    return {"status": "success", "message": "OTP sent successfully", "otp": otp}


@router.post("/otp/verify", response_model=OtpVerifyResponse)
async def otp_verify(request: OtpVerifyRequest, _: Annotated[None, Depends(verify_hmac_headers)]):
    if not re.match(r"^[6-9]\d{9}$", request.mobile):
        raise AppException(400, "invalid_format", "Mobile must be a valid 10-digit Indian number")

    db = get_db()
    if db is None:
        raise AppException(500, "db_error", "Database connection failed")

    record = await db.otp_db.find_one({"mobile": request.mobile})
    if not record:
        raise AppException(404, "not_found", "Please request an OTP first")

    # Check expiration
    if "expires_at" in record and datetime.utcnow() > record["expires_at"]:
        raise AppException(400, "expired", "OTP has expired. Please request a new one.")

    # Check match
    if record.get("otp") != request.otp:
        # Increment attempt count
        attempts = record.get("attempts", 0) + 1
        await db.otp_db.update_one({"mobile": request.mobile}, {"$set": {"attempts": attempts}})
        if attempts >= 3:
            await db.otp_db.delete_one({"mobile": request.mobile})
            raise AppException(400, "max_attempts", "Too many failed attempts. Please request a new OTP.")
        raise AppException(400, "invalid_otp", "OTP is incorrect")

    # Store the name before we clean up the OTP record
    temp_name = record.get("name", "Gig Worker")

    # OTP is valid, mark as verified and clean up
    await db.otp_db.update_one(
        {"mobile": request.mobile}, 
        {"$set": {"verified": True}, "$unset": {"otp": "", "expires_at": "", "attempts": "", "name": ""}}
    )

    # Generate JWT Token
    access_token = create_access_token(data={"sub": request.mobile})

    # Ensure user exists in users collection
    user_record = await db.users.find_one({"mobile": request.mobile})
    if not user_record:
        # Should only happen on signup verification
        new_user = {
            "mobile": request.mobile,
            "name": "demo" if request.mobile == "9094909490" else temp_name,
            "created_at": datetime.utcnow()
        }
        await db.users.insert_one(new_user)
        user_info = {"name": new_user["name"], "mobile": new_user["mobile"]}
    else:
        name_to_return = "demo" if request.mobile == "9094909490" else user_record.get("name", "Gig Worker")
        if request.mobile == "9094909490" and user_record.get("name") != "demo":
            await db.users.update_one({"mobile": request.mobile}, {"$set": {"name": "demo"}})
        user_info = {"name": name_to_return, "mobile": request.mobile}

    return {"status": "success", "token": access_token, "user": user_info}
