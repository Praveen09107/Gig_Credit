from typing import List, Literal, Optional

from pydantic import BaseModel


class AadhaarVerifyRequest(BaseModel):
    aadhaar: str


class AadhaarOtpValidateRequest(BaseModel):
    aadhaar: str
    otp: str


class PanVerifyRequest(BaseModel):
    pan: str


class PanOtpValidateRequest(BaseModel):
    pan: str
    otp: str


class IfscVerifyRequest(BaseModel):
    ifsc: str


class AccountVerifyRequest(BaseModel):
    account_number: str
    ifsc: str


class LoanCheckRequest(BaseModel):
    account_number: str


class VehicleRcVerifyRequest(BaseModel):
    vehicle_number: str


class EshramVerifyRequest(BaseModel):
    uan: str


class PmsymVerifyRequest(BaseModel):
    uan: str


class InsurancePolicyVerifyRequest(BaseModel):
    policy_number: str
    policy_type: Literal["health", "vehicle", "life"]


class ItrVerifyRequest(BaseModel):
    pan: str
    assessment_year: str


class LoanItem(BaseModel):
    type: str
    emi_amount: int
    remaining_months: int


# ── New schemas for Steps 4-9 ─────────────────────────────────────────────────

class EbVerifyRequest(BaseModel):
    service_number: str


class LpgVerifyRequest(BaseModel):
    consumer_number: str
    provider: str


class UdyamVerifyRequest(BaseModel):
    udyam_number: str


class LoanVerifyRequest(BaseModel):
    lender_name: str
    emi_amount: float
    latest_debit_date: str


class GstFilingHistoryRequest(BaseModel):
    gstin: str


class LoanCheckResponse(BaseModel):
    has_active_loans: bool
    loan_count: int
    loans: List[LoanItem]


class AadhaarVerifyResponse(BaseModel):
    status: str
    name: str
    dob: str
    state: str
    otp: Optional[str] = None


class PanVerifyResponse(BaseModel):
    status: str
    name: str
    dob: str
    pan_active: bool
    itr_filed: bool
    itr_years: List[int]
    otp: Optional[str] = None


class IfscVerifyResponse(BaseModel):
    status: str
    bank_name: str
    branch_name: str
    city: str
    state: str


class AccountVerifyResponse(BaseModel):
    status: str
    account_holder: str
    account_type: str
    account_active: bool


class VehicleRcVerifyResponse(BaseModel):
    status: str
    owner_name: str
    vehicle_class: str
    chassis_number: str
    engine_number: str
    registration_date: str
    rc_expiry: str
    fitness_expiry: str


class EshramVerifyResponse(BaseModel):
    status: str
    name: str
    worker_category: str
    registration_date: str


class PmsymVerifyResponse(BaseModel):
    status: str
    months_contributed: int
    last_contribution_date: str


class InsuranceVerifyResponse(BaseModel):
    status: str
    policy_holder: str
    insurer: str
    sum_insured: Optional[int] = None
    premium_annual: Optional[int] = None
    policy_start: Optional[str] = None
    policy_expiry: str
    vehicle_number: Optional[str] = None


class ItrVerifyResponse(BaseModel):
    status: str
    assessment_year: str
    itr_form: str
    gross_income: int
    tax_paid: int
    filing_date: str
