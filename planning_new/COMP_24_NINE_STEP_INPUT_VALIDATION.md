# ================================================================================
# GIGCREDIT — 9-STEP ONBOARDING: INPUT FIELDS AND VALIDATION
# Document 24 | planning_new
# Reference: input validation and verification/ spec files
# ================================================================================

## STEP 1 — BASIC PROFILE

### Mandatory Fields (12)
| Field                | Type         | Validation                          |
|---------------------|--------------|-------------------------------------|
| full_name           | text         | 2-50 chars, letters + spaces only   |
| date_of_birth       | date         | Age 18-80, DD/MM/YYYY               |
| mobile_number       | numeric      | 10 digits, starts with 6-9          |
| otp                 | numeric      | 6 digits                            |
| current_address     | text         | 10-200 chars                        |
| permanent_address   | text         | 10-200 chars (or "Same as current") |
| state_of_residence  | dropdown     | 36 Indian states/UTs                |
| work_type           | selector     | One of 4 types                      |
| self_declared_income| currency     | ₹1,000 - ₹5,00,000                 |
| years_in_profession | stepper      | 0-40                                |
| dependents          | stepper      | 0-10                                |
| vehicle_ownership   | toggle       | Yes/No                              |

### Optional Fields (1)
| Field                | Type         | Validation                          |
|---------------------|--------------|-------------------------------------|
| secondary_income    | currency     | ₹0 - ₹5,00,000                     |

### Backend Call
- POST /auth/otp/send (mobile)
- POST /auth/otp/verify (mobile, otp)

---

## STEP 2 — IDENTITY (KYC)

### Mandatory Fields (6)
| Field              | Type           | Validation                           |
|-------------------|----------------|--------------------------------------|
| aadhaar_front     | image upload   | JPG/PNG, < 5MB                       |
| aadhaar_back      | image upload   | JPG/PNG, < 5MB                       |
| pan_card          | image upload   | JPG/PNG, < 5MB                       |
| selfie            | camera capture | JPG, face detected, < 5MB            |
| aadhaar_number    | auto-OCR       | 12 digits (extracted from card)      |
| pan_number        | auto-OCR       | XXXXX0000X format (extracted)        |

### On-Device Processing
- OCR: Extract name, DOB, Aadhaar#, PAN#
- Face match: Compare selfie with Aadhaar photo (placeholder)
- Name cross-match: fuzzy(Aadhaar name, PAN name) ≥ 85%
- DOB cross-match: Aadhaar DOB == PAN DOB

### Backend Call
- POST /gov/aadhaar/verify (aadhaar_number)
- POST /gov/pan/verify (pan_number)

---

## STEP 3 — BANK VERIFICATION

### Mandatory Fields (6)
| Field              | Type           | Validation                           |
|-------------------|----------------|--------------------------------------|
| bank_name         | dropdown       | List of Indian banks                 |
| account_holder    | text           | Must match Aadhaar name (fuzzy ≥85%) |
| branch_name       | text           | 3-50 chars                           |
| ifsc_code         | text           | XXXX0XXXXXX format                   |
| account_number    | numeric        | 9-18 digits                          |
| bank_statement    | PDF upload     | PDF only, < 10MB, 6 months data      |

### Optional Fields (11)
| Field              | Type           | Validation                           |
|-------------------|----------------|--------------------------------------|
| micr_code         | text           | 9 digits                             |
| secondary bank    | expandable     | Same fields as primary               |
| upi_statement     | PDF upload     | Optional UPI statement               |

### On-Device Processing
- Parse bank statement → extract all transactions
- Monthly aggregation (credits, debits, balance)
- EMI auto-detection (recurring debits with same amount ±5%)
- Transaction categorization (income, EMI, utility, ATM)

### Backend Calls
- POST /bank/ifsc/verify
- POST /bank/account/verify
- POST /bank/loan/check

---

## STEP 4 — UTILITY BILLS

### Mandatory Fields (18 — 6 bills × 3 types)
| Field              | Type           | Validation                           |
|-------------------|----------------|--------------------------------------|
| electricity_bill_1-6 | image upload| JPG/PNG, < 5MB each, 6 months       |
| lpg_bill_1-6      | image upload   | JPG/PNG, < 5MB each, 6 months       |
| mobile_bill_1-6   | image upload   | JPG/PNG/PDF, < 5MB each, 6 months   |

### Optional Fields (13)
| Field              | Type           | Validation                           |
|-------------------|----------------|--------------------------------------|
| rent_receipt_1-6  | image upload   | Optional                             |
| wifi_bill_1-6     | image upload   | Optional                             |
| ott_receipt       | image upload   | Optional                             |

### On-Device Processing
- OCR each bill → extract consumer#, amount, due date, payment date
- Compute on-time payment ratio per utility type
- Cross-check bill amounts vs bank debit transactions
- Verify consumer numbers are consistent across 6 months

### NO Backend Call

---

## STEP 5 — WORK PROOF (Dynamic by Work Type)

### Platform Worker — Mandatory (8)
| Field              | Type           | Validation                           |
|-------------------|----------------|--------------------------------------|
| rc_book           | image upload   | Vehicle registration certificate     |
| dl_front          | image upload   | Driving licence front                |
| dl_back           | image upload   | Driving licence back                 |
| vehicle_insurance | image upload   | Valid insurance certificate           |
| earning_screenshot_1-3 | image     | Platform earnings (3 screenshots)    |
| upi_screenshot    | image upload   | UPI transaction proof                |

### Vendor — Mandatory (3)
| Field              | Type           |
|-------------------|----------------|
| svanidhi_id       | image upload   |
| approval_letter   | image upload   |
| trade_licence     | image upload   |

### Backend Call (Platform Worker Only)
- POST /gov/vehicle/rc/verify

---

## STEP 6 — GOVERNMENT SCHEME SIGNALS

### All Optional (7)
| Field              | Type           |
|-------------------|----------------|
| eshram_uan        | text input     |
| pmsym_id          | text input     |
| mudra_registration| image upload   |
| shg_membership    | image upload   |
| ppf_passbook      | image upload   |
| nps_statement     | image upload   |
| atal_pension_card  | image upload   |

### Backend Calls
- POST /gov/eshram/verify
- POST /gov/pmsym/verify

---

## STEP 7 — INSURANCE SIGNALS

### Conditional Mandatory (Platform Worker: vehicle insurance required)
| Field              | Type           |
|-------------------|----------------|
| health_insurance  | PDF upload     |
| vehicle_insurance | image upload   |
| life_insurance    | PDF upload     |
| accident_insurance| image upload   |

### Backend Call
- POST /gov/insurance/policy/verify (1-3 calls)

---

## STEP 8 — TAX AND COMPLIANCE

### All Optional
| Field              | Type           |
|-------------------|----------------|
| itr_acknowledgement| image upload  |
| assessment_year   | dropdown       |
| gst_registration  | PDF upload     |
| gst_return_1-3    | PDF upload     |
| form_26as         | PDF upload     |

### Backend Call
- POST /gov/income-tax/itr/verify

---

## STEP 9 — EMI AND LOAN BEHAVIOUR

### Mandatory (1)
| Field              | Type           |
|-------------------|----------------|
| has_active_loans  | toggle         |

### Conditional (if has_active_loans = Yes)
Up to 5 loan cards, each with:
| Field              | Type           |
|-------------------|----------------|
| lender_name       | text           |
| loan_type         | dropdown       |
| emi_amount        | currency       |
| prev_debit_date   | date           |
| latest_debit_date | date           |

### On-Device Processing
- Cross-check declared EMIs vs auto-detected EMIs (from Step 3)
- Flag mismatches: amount difference > 10% or date mismatch

### NO Backend Call
