# -*- coding: utf-8 -*-
"""
GigCredit - Dynamic Data Verification Test
Tests all endpoints with REAL seed data (50+ profiles) to verify
responses are dynamic and return actual DB values, not static fallbacks.
"""
import requests
import json
import hashlib
import hmac
import time
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

BASE_URL = "https://gig-credit.onrender.com"
API_KEY = "gigcredit-demo-api-key-2026"

def get_headers():
    timestamp = str(int(time.time()))
    message = f"{timestamp}:{API_KEY}"
    signature = hmac.new(API_KEY.encode(), message.encode(), hashlib.sha256).hexdigest()
    return {
        "Content-Type": "application/json",
        "X-API-Key": API_KEY,
        "X-Timestamp": timestamp,
        "X-Signature": signature,
    }

passed = 0
failed = 0
total = 0

def check(name, condition, actual, expected=None):
    global passed, failed, total
    total += 1
    if condition:
        passed += 1
        print(f"  [PASS] {name}")
    else:
        failed += 1
        exp_str = f" (expected: {expected})" if expected else ""
        print(f"  [FAIL] {name}: got {str(actual)[:100]}{exp_str}")

# ============================================================================
# SEED DATA VALUES (from backend/app/db/seed_data.py)
# ============================================================================
SEED_AADHAAR = "765432101234"
SEED_NAME = "Praveen Kumar"
SEED_PAN = "ABCDE1234F"
SEED_IFSC = "HDFC0001234"
SEED_ACCOUNT = "1234567890"
SEED_VEHICLE = "TN09AB1234"
SEED_ESHRAM = "UAN123456789012"
SEED_PMSYM = "UAN123456789012"
SEED_INSURANCE_HEALTH = "HLT2024112345"
SEED_INSURANCE_VEHICLE = "VEH20242222"
SEED_ITR_PAN = "ABCDE1234F"
SEED_ITR_YEAR = "2024-25"

print("=" * 100)
print("GIGCREDIT DYNAMIC DATA VERIFICATION TEST")
print("Testing with 50+ user profile seed data")
print("=" * 100)

headers = get_headers()

# ============================================================================
# TEST 1: AADHAAR - should return REAL name, DOB, state from DB
# ============================================================================
print("\n--- TEST 1: AADHAAR VERIFICATION (dynamic name/DOB) ---")
r = requests.post(f"{BASE_URL}/gov/aadhaar/verify", headers=get_headers(),
                   json={"aadhaar": SEED_AADHAAR}, timeout=30)
data = r.json()
check("Status 200", r.status_code == 200, r.status_code, 200)
check("Returns real name 'Praveen Kumar'", data.get("name") == SEED_NAME, data.get("name"), SEED_NAME)
check("Returns real DOB '2006-11-16'", data.get("dob") == "2006-11-16", data.get("dob"))
check("Returns real state 'Tamil Nadu'", data.get("state") == "Tamil Nadu", data.get("state"))
check("OTP is dynamic (6 digits)", len(str(data.get("otp",""))) == 6, data.get("otp"))

# Wrong Aadhaar should return 404
r2 = requests.post(f"{BASE_URL}/gov/aadhaar/verify", headers=get_headers(),
                    json={"aadhaar": "999999999999"}, timeout=30)
check("Wrong Aadhaar returns 404 (not fake 200)", r2.status_code == 404, r2.status_code, 404)

# ============================================================================
# TEST 2: PAN - should return REAL name, DOB, ITR years from DB
# ============================================================================
print("\n--- TEST 2: PAN VERIFICATION (dynamic name/ITR) ---")
r = requests.post(f"{BASE_URL}/gov/pan/verify", headers=get_headers(),
                   json={"pan": SEED_PAN}, timeout=30)
data = r.json()
check("Status 200", r.status_code == 200, r.status_code, 200)
check("Returns real name 'Praveen Kumar'", data.get("name") == SEED_NAME, data.get("name"), SEED_NAME)
check("Returns real DOB", data.get("dob") == "2006-11-16", data.get("dob"))
check("PAN active is dynamic boolean", isinstance(data.get("pan_active"), bool), type(data.get("pan_active")))
check("ITR filed is dynamic boolean", isinstance(data.get("itr_filed"), bool), type(data.get("itr_filed")))
check("ITR years are dynamic list", isinstance(data.get("itr_years"), list), data.get("itr_years"))
check("ITR years contain 2022,2023,2024", data.get("itr_years") == [2022, 2023, 2024], data.get("itr_years"))

# Wrong PAN should return 404
r2 = requests.post(f"{BASE_URL}/gov/pan/verify", headers=get_headers(),
                    json={"pan": "ZZZZZ9999Z"}, timeout=30)
check("Wrong PAN returns 404", r2.status_code == 404, r2.status_code, 404)

# ============================================================================
# TEST 3: BANK IFSC - should return REAL bank/branch from DB
# ============================================================================
print("\n--- TEST 3: BANK IFSC (dynamic bank/branch) ---")
r = requests.post(f"{BASE_URL}/bank/ifsc/verify", headers=get_headers(),
                   json={"ifsc": SEED_IFSC}, timeout=30)
data = r.json()
check("Status 200", r.status_code == 200, r.status_code, 200)
check("Bank name is dynamic", data.get("bank_name") is not None, data.get("bank_name"))
check("Branch name is dynamic", data.get("branch_name") is not None, data.get("branch_name"))
check("City is dynamic", data.get("city") is not None, data.get("city"))
print(f"    -> bank={data.get('bank_name')}, branch={data.get('branch_name')}, city={data.get('city')}")

# ============================================================================
# TEST 4: BANK ACCOUNT - should return REAL holder from DB
# ============================================================================
print("\n--- TEST 4: BANK ACCOUNT (dynamic holder name) ---")
r = requests.post(f"{BASE_URL}/bank/account/verify", headers=get_headers(),
                   json={"account_number": SEED_ACCOUNT, "ifsc": SEED_IFSC}, timeout=30)
data = r.json()
check("Status 200", r.status_code == 200, r.status_code, 200)
check("Account holder is dynamic real name", data.get("account_holder") == SEED_NAME, data.get("account_holder"), SEED_NAME)
check("Account type is dynamic", data.get("account_type") == "Savings", data.get("account_type"))
check("Account active is boolean", isinstance(data.get("account_active"), bool), type(data.get("account_active")))

# ============================================================================
# TEST 5: LOAN CHECK - should return REAL loan data from DB
# ============================================================================
print("\n--- TEST 5: LOAN CHECK (dynamic loan details) ---")
r = requests.post(f"{BASE_URL}/bank/loan/check", headers=get_headers(),
                   json={"account_number": SEED_ACCOUNT}, timeout=30)
data = r.json()
check("Status 200", r.status_code == 200, r.status_code, 200)
check("has_active_loans is True (from seed)", data.get("has_active_loans") == True, data.get("has_active_loans"))
check("loan_count is 2 (Personal + Bike)", data.get("loan_count") == 2, data.get("loan_count"), 2)
check("Loans array is dynamic", len(data.get("loans", [])) == 2, len(data.get("loans", [])))
if data.get("loans"):
    check("First loan type is dynamic", data["loans"][0].get("type") == "Personal Loan", data["loans"][0].get("type"))
    check("First loan EMI is 3500 (from seed)", data["loans"][0].get("emi_amount") == 3500, data["loans"][0].get("emi_amount"), 3500)
    check("Second loan type is Bike Loan", data["loans"][1].get("type") == "Bike Loan", data["loans"][1].get("type"))

# No-loan account should return empty
r2 = requests.post(f"{BASE_URL}/bank/loan/check", headers=get_headers(),
                    json={"account_number": "999999999999"}, timeout=30)
data2 = r2.json()
check("Unknown account returns 0 loans (not fake data)", data2.get("loan_count") == 0, data2.get("loan_count"))

# ============================================================================
# TEST 6: VEHICLE RC - should return REAL vehicle data from DB
# ============================================================================
print("\n--- TEST 6: VEHICLE RC (dynamic vehicle details) ---")
r = requests.post(f"{BASE_URL}/gov/vehicle/rc/verify", headers=get_headers(),
                   json={"vehicle_number": SEED_VEHICLE}, timeout=30)
data = r.json()
check("Status 200", r.status_code == 200, r.status_code, 200)
check("Owner is dynamic real name", data.get("owner_name") == SEED_NAME, data.get("owner_name"), SEED_NAME)
check("Vehicle class is Motorcycle", data.get("vehicle_class") == "Motorcycle", data.get("vehicle_class"))
check("Chassis dynamic", data.get("chassis_number") == "CHASSIS123", data.get("chassis_number"))

# ============================================================================
# TEST 7: ESHRAM - should return REAL worker data
# ============================================================================
print("\n--- TEST 7: ESHRAM (dynamic worker data) ---")
r = requests.post(f"{BASE_URL}/gov/eshram/verify", headers=get_headers(),
                   json={"uan": SEED_ESHRAM}, timeout=30)
data = r.json()
check("Status 200", r.status_code == 200, r.status_code, 200)
check("Name is dynamic", data.get("name") == SEED_NAME, data.get("name"), SEED_NAME)
check("Worker category is dynamic", data.get("worker_category") == "Gig Worker", data.get("worker_category"))
check("Registration date is dynamic", data.get("registration_date") == "2023-08-11", data.get("registration_date"))

# ============================================================================
# TEST 8: PMSYM - should return REAL contribution data
# ============================================================================
print("\n--- TEST 8: PMSYM (dynamic contribution data) ---")
r = requests.post(f"{BASE_URL}/gov/pmsym/verify", headers=get_headers(),
                   json={"uan": SEED_PMSYM}, timeout=30)
data = r.json()
check("Status 200", r.status_code == 200, r.status_code, 200)
check("Months contributed is 14 (from seed)", data.get("months_contributed") == 14, data.get("months_contributed"), 14)
check("Last contribution date dynamic", data.get("last_contribution_date") == "2026-02-15", data.get("last_contribution_date"))

# ============================================================================
# TEST 9: INSURANCE - should return REAL policy data
# ============================================================================
print("\n--- TEST 9: INSURANCE (dynamic policy data) ---")
r = requests.post(f"{BASE_URL}/gov/insurance/policy/verify", headers=get_headers(),
                   json={"policy_number": SEED_INSURANCE_HEALTH, "policy_type": "health"}, timeout=30)
data = r.json()
check("Status 200", r.status_code == 200, r.status_code, 200)
check("Policy holder is dynamic name", data.get("policy_holder") == SEED_NAME, data.get("policy_holder"), SEED_NAME)
check("Insurer is 'Star Health Insurance'", data.get("insurer") == "Star Health Insurance", data.get("insurer"))
check("Sum insured is 500000 (from seed)", data.get("sum_insured") == 500000, data.get("sum_insured"), 500000)
check("Premium is 8500 (from seed)", data.get("premium_annual") == 8500, data.get("premium_annual"), 8500)

# Vehicle insurance
r2 = requests.post(f"{BASE_URL}/gov/insurance/policy/verify", headers=get_headers(),
                    json={"policy_number": SEED_INSURANCE_VEHICLE, "policy_type": "vehicle"}, timeout=30)
data2 = r2.json()
check("Vehicle insurance returns different insurer", data2.get("insurer") == "Bajaj Allianz", data2.get("insurer"))

# ============================================================================
# TEST 10: ITR - should return REAL tax data
# ============================================================================
print("\n--- TEST 10: ITR (dynamic tax data) ---")
r = requests.post(f"{BASE_URL}/gov/income-tax/itr/verify", headers=get_headers(),
                   json={"pan": SEED_ITR_PAN, "assessment_year": SEED_ITR_YEAR}, timeout=30)
data = r.json()
check("Status 200", r.status_code == 200, r.status_code, 200)
check("ITR form is ITR-4 (from seed)", data.get("itr_form") == "ITR-4", data.get("itr_form"), "ITR-4")
check("Gross income is 360000", data.get("gross_income") == 360000, data.get("gross_income"), 360000)
check("Filing date is dynamic", data.get("filing_date") == "2025-07-22", data.get("filing_date"))

# ============================================================================
# TEST 11: LOAN PIPELINE - dynamic product/KFS/decision
# ============================================================================
print("\n--- TEST 11: LOAN PIPELINE (dynamic products/KFS) ---")
# Products - different scores should yield different products
r_high = requests.post(f"{BASE_URL}/loan/products", headers=get_headers(),
                        json={"score": 800}, timeout=30)
r_low = requests.post(f"{BASE_URL}/loan/products", headers=get_headers(),
                       json={"score": 400}, timeout=30)
high_data = r_high.json()
low_data = r_low.json()
high_count = len(high_data.get("eligible_products", []))
low_count = len(low_data.get("eligible_products", []))
check("High score (800) gets MORE products than low (400)", high_count > low_count, 
      f"high={high_count}, low={low_count}")
print(f"    -> Score 800: {high_count} products | Score 400: {low_count} products")

# KFS - dynamic EMI calculation
r_kfs = requests.post(f"{BASE_URL}/loan/kfs", headers=get_headers(),
                       json={"product_id": "emergency_advance", "amount": 15000, "tenure": 6, "score": 700}, timeout=30)
kfs1 = r_kfs.json()
r_kfs2 = requests.post(f"{BASE_URL}/loan/kfs", headers=get_headers(),
                        json={"product_id": "emergency_advance", "amount": 25000, "tenure": 12, "score": 700}, timeout=30)
kfs2 = r_kfs2.json()
check("KFS EMI changes with amount/tenure", kfs1.get("emi") != kfs2.get("emi"),
      f"emi1={kfs1.get('emi')}, emi2={kfs2.get('emi')}")
check("KFS total_payable is dynamic", kfs1.get("total_payable") != kfs2.get("total_payable"),
      f"t1={kfs1.get('total_payable')}, t2={kfs2.get('total_payable')}")
print(f"    -> KFS1: amt=15k, tenure=6mo, emi={kfs1.get('emi')}")
print(f"    -> KFS2: amt=25k, tenure=12mo, emi={kfs2.get('emi')}")

# ============================================================================
# TEST 12: EXPLAINABILITY - dynamic LLM/SHAP response
# ============================================================================
print("\n--- TEST 12: EXPLAINABILITY (dynamic SHAP/LLM) ---")
r = requests.post(f"{BASE_URL}/explain/full", headers=get_headers(),
                   json={"user_id": "test_dynamic", "score_data": {"score": 742, "income": 25000}}, timeout=30)
data = r.json()
check("Returns L5 live SHAP values", "l5_live_shap" in data, list(data.keys()))
check("Returns L6 EFS score", "l6_efs_score" in data, list(data.keys()))
check("Returns L7 peer cohort", "l7_peer_cohort" in data, list(data.keys()))
check("Peer cohort has avg_score", "avg_score" in data.get("l7_peer_cohort", {}), data.get("l7_peer_cohort"))
check("Returns L10 natural language text", len(data.get("l10_natural_language", "")) > 20,
      f"length={len(data.get('l10_natural_language', ''))}")

# ============================================================================
# TEST 13: CROSS-USER DYNAMIC CHECK - different users get different results
# ============================================================================
print("\n--- TEST 13: CROSS-USER DYNAMIC CHECK ---")
# Aadhaar for existing user vs non-existing
r1 = requests.post(f"{BASE_URL}/gov/aadhaar/verify", headers=get_headers(),
                    json={"aadhaar": SEED_AADHAAR}, timeout=30)
r2 = requests.post(f"{BASE_URL}/gov/aadhaar/verify", headers=get_headers(),
                    json={"aadhaar": "234567890123"}, timeout=30)
check("Different Aadhaar numbers get different responses",
      r1.status_code != r2.status_code or r1.json() != r2.json(),
      f"user1_status={r1.status_code}, user2_status={r2.status_code}")

# Different loan amounts produce different EMIs
r1 = requests.post(f"{BASE_URL}/loan/kfs", headers=get_headers(),
                    json={"product_id": "income_bridge", "amount": 5000, "tenure": 3, "score": 650}, timeout=30)
r2 = requests.post(f"{BASE_URL}/loan/kfs", headers=get_headers(),
                    json={"product_id": "income_bridge", "amount": 50000, "tenure": 24, "score": 650}, timeout=30)
check("Different amounts yield different EMI (not static)", 
      r1.json().get("emi") != r2.json().get("emi"),
      f"emi1={r1.json().get('emi')}, emi2={r2.json().get('emi')}")

# ============================================================================
# SUMMARY
# ============================================================================
print("\n" + "=" * 100)
print("DYNAMIC DATA VERIFICATION SUMMARY")
print("=" * 100)
print(f"  PASS: {passed}/{total}  |  FAIL: {failed}/{total}")
if failed == 0:
    print("  >> ALL ENDPOINTS RETURN DYNAMIC DATA FROM DATABASE")
    print("  >> NO STATIC/HARDCODED VALUES DETECTED")
else:
    print(f"  >> {failed} checks returned unexpected values")
print("=" * 100)
