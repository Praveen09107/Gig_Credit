from pydantic import BaseModel, Field
from typing import Optional, Dict


class OtpSendRequest(BaseModel):
    mobile: str = Field(..., examples=["9876543210"])
    isSignup: Optional[bool] = False
    name: Optional[str] = None


class OtpSendResponse(BaseModel):
    status: str
    message: str
    otp: Optional[str] = None


class OtpVerifyRequest(BaseModel):
    mobile: str
    otp: str


class OtpVerifyResponse(BaseModel):
    status: str
    token: Optional[str] = None
    user: Optional[Dict] = None
