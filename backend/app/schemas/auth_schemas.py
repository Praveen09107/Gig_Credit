from pydantic import BaseModel, Field


class OtpSendRequest(BaseModel):
    mobile: str = Field(..., examples=["9876543210"])


class OtpSendResponse(BaseModel):
    status: str
    expires_in_seconds: int
    otp: str


class OtpVerifyRequest(BaseModel):
    mobile: str
    otp: str


class OtpVerifyResponse(BaseModel):
    status: str
    mobile_verified: bool
