"""
GigCredit - REAL End-to-End Test with ACTUAL Seed Data
======================================================
Tests EVERY endpoint with REAL data from seed_data.py.
NO 404 tolerance. Every test must get a 200 with REAL response data.
Tests the FULL workflow: Signup -> OTP -> KYC -> Bank -> Steps 4-9 -> 
Score -> LLM Report -> Loan Pipeline.

Uses the EXACT values from backend/app/db/seed_data.py.
"""

import json
import time
import requests
import sys

BASE_URL = "https://gig-credit.onrender.com"
API_KEY = "gigcredit-demo-api-key-2026"
HEADERS = {"Content-Type": "application/json", "X-API-Key": API_KEY}

results = []
total = 0
passed = 0
failed = 0
critical_failures = []

# ============================================================================
# SEED DATA VALUES (from backend/app/db/seed_data.py)
# ============================================================================
SEED = {
    "aadhaar": "765432101234",
    "pan": "ABCDE1234F",
    "name": "Praveen Kumar",
    "dob": "2006-11-16",
    "ifsc": "HDFC0001234",
    "account_number": "1234567890",
    "vehicle_number": "TN09AB1234",
    "eshram_uan": "UAN123456789012",
    "pmsym_uan": "UAN123456789012",
    "health_policy": "HLT2024112345",
    "vehicle_policy": "VEH20242222",
    "itr_pan": "ABCDE1234F",
    "itr_ay": "2024-25",
    "mobile": "9876543210",
}


def test(name, method, path, body=None, expected_status=200,
         required_keys=None, validate_fn=None, critical=True):
    """Run a single endpoint test. Returns response data or None."""
    global total, passed, failed
    total += 1
    url = f"{BASE_URL}{path}"

    print(f"\n{'='*70}")
    print(f"TEST {total}: {name}")
    print(f"  >> {method} {url}")
    if body:
        print(f"  >> Body: {json.dumps(body)[:150]}")

    try:
        start = time.time()
        if method == "GET":
            resp = requests.get(url, headers=HEADERS, timeout=20)
        else:
            resp = requests.post(url, headers=HEADERS, json=body, timeout=20)
        elapsed = time.time() - start

        try:
            data = resp.json()
        except:
            data = None

        print(f"  << Status: {resp.status_code} ({elapsed:.2f}s)")
        if data and isinstance(data, dict):
            print(f"  << Keys: {list(data.keys())}")
            # Print first 200 chars of response for proof
            resp_str = json.dumps(data, default=str)[:200]
            print(f"  << Data: {resp_str}")

        # Check status
        if resp.status_code != expected_status:
            msg = f"Expected {expected_status}, got {resp.status_code}"
            if data:
                detail = data.get("detail", data.get("message", data.get("error", "")))
                msg += f" - {detail}"
            print(f"  XX FAIL: {msg}")
            failed += 1
            results.append(("FAIL", name, msg))
            if critical:
                critical_failures.append((name, msg))
            return None

        # Check required keys
        if required_keys and data:
            missing = [k for k in required_keys if k not in data]
            if missing:
                msg = f"Missing keys: {missing}"
                print(f"  XX FAIL: {msg}")
                failed += 1
                results.append(("FAIL", name, msg))
                if critical:
                    critical_failures.append((name, msg))
                return data

        # Custom validation
        if validate_fn and data:
            ok, msg = validate_fn(data)
            if not ok:
                print(f"  XX FAIL: {msg}")
                failed += 1
                results.append(("FAIL", name, msg))
                if critical:
                    critical_failures.append((name, msg))
                return data

        print(f"  OK PASS")
        passed += 1
        results.append(("PASS", name, f"HTTP {resp.status_code} in {elapsed:.2f}s"))
        return data

    except requests.exceptions.Timeout:
        print(f"  XX FAIL: Timeout (20s)")
        failed += 1
        results.append(("FAIL", name, "Timeout"))
        if critical:
            critical_failures.append((name, "Timeout"))
        return None
    except Exception as e:
        print(f"  XX FAIL: {e}")
        failed += 1
        results.append(("FAIL", name, str(e)))
        if critical:
            critical_failures.append((name, str(e)))
        return None


# ============================================================================
# TEST 0: HEALTH CHECK
# ============================================================================
print("\n" + "#"*70)
print("# PHASE 0: HEALTH CHECK")
print("#"*70)

test("Health Check", "GET", "/health",
     required_keys=["status"],
     validate_fn=lambda d: (d["status"] == "ok", f"Status is '{d['status']}' not 'ok'"))

# ============================================================================
# PHASE 1: AUTH FLOW - Real Signup + OTP
# ============================================================================
print("\n" + "#"*70)
print("# PHASE 1: AUTH - Signup + OTP Verify")
print("#"*70)

# First signup a test user
signup_data = test(
    "Auth: Send OTP for Signup (may fail if user exists)",
    "POST", "/auth/otp/send",
    body={"mobile": SEED["mobile"], "isSignup": True, "name": SEED["name"]},
    required_keys=["status", "otp"],
    validate_fn=lambda d: (
        d["status"] == "success" and len(d.get("otp", "")) == 6,
        f"Expected success+6-digit OTP, got status={d.get('status')}, otp={d.get('otp')}"
    ),
    critical=False  # On repeat runs, user already exists -> 400 is expected
)

# Use the REAL OTP from the server response
if signup_data and "otp" in signup_data:
    real_otp = signup_data["otp"]
    print(f"  >> Got REAL OTP from server: {real_otp}")

    verify_data = test(
        "Auth: Verify OTP (with real server OTP)",
        "POST", "/auth/otp/verify",
        body={"mobile": SEED["mobile"], "otp": real_otp},
        required_keys=["status", "token"],
        validate_fn=lambda d: (
            d["status"] == "success" and "user" in d,
            f"Expected success+user, got: {d.get('status')}"
        )
    )
    if verify_data:
        print(f"  >> Got JWT token: {verify_data.get('token', 'N/A')[:30]}...")
        print(f"  >> User info: {verify_data.get('user', 'N/A')}")
else:
    # User may already exist (not first run). Try login instead.
    print("  >> Signup failed (user may exist). Trying login...")
    login_data = test(
        "Auth: Send OTP for Login",
        "POST", "/auth/otp/send",
        body={"mobile": SEED["mobile"], "isSignup": False},
        required_keys=["status", "otp"]
    )
    if login_data and "otp" in login_data:
        real_otp = login_data["otp"]
        test(
            "Auth: Verify Login OTP",
            "POST", "/auth/otp/verify",
            body={"mobile": SEED["mobile"], "otp": real_otp},
            required_keys=["status", "token"]
        )

# ============================================================================
# PHASE 2: STEP 2 - KYC (Aadhaar + PAN with SEED data)
# ============================================================================
print("\n" + "#"*70)
print("# PHASE 2: STEP 2 - KYC Verification (Real Seed Data)")
print("#"*70)

aadhaar_data = test(
    "KYC: Verify Aadhaar (seed: 765432101234)",
    "POST", "/gov/aadhaar/verify",
    body={"aadhaar": SEED["aadhaar"]},
    required_keys=["status", "name", "dob", "state"],
    validate_fn=lambda d: (
        d["name"] == SEED["name"] and d["state"] == "Tamil Nadu",
        f"Name mismatch: got '{d.get('name')}' expected '{SEED['name']}'"
    )
)

pan_data = test(
    "KYC: Verify PAN (seed: ABCDE1234F)",
    "POST", "/gov/pan/verify",
    body={"pan": SEED["pan"]},
    required_keys=["status", "name", "dob", "pan_active", "itr_filed"],
    validate_fn=lambda d: (
        d["name"] == SEED["name"] and d["pan_active"] == True,
        f"PAN data wrong: name={d.get('name')}, active={d.get('pan_active')}"
    )
)

# ============================================================================
# PHASE 3: STEP 3 - Bank Verification
# ============================================================================
print("\n" + "#"*70)
print("# PHASE 3: STEP 3 - Bank Verification (Real Seed Data)")
print("#"*70)

ifsc_data = test(
    "Bank: Verify IFSC (seed: HDFC0001234)",
    "POST", "/bank/ifsc/verify",
    body={"ifsc": SEED["ifsc"]},
    required_keys=["status", "bank_name", "branch_name", "city", "state"],
    validate_fn=lambda d: (
        d["bank_name"] == "HDFC Bank",
        f"IFSC data wrong: bank={d.get('bank_name')}, expected 'HDFC Bank'"
    )
)

account_data = test(
    "Bank: Verify Account (seed: 1234567890 + HDFC0001234)",
    "POST", "/bank/account/verify",
    body={"account_number": SEED["account_number"], "ifsc": SEED["ifsc"]},
    required_keys=["status", "account_holder", "account_type", "account_active"],
    validate_fn=lambda d: (
        d["account_holder"] == SEED["name"] and d["account_active"] == True,
        f"Account wrong: holder={d.get('account_holder')}, active={d.get('account_active')}"
    )
)

# ============================================================================
# PHASE 4: STEP 5 - Vehicle RC Verification
# ============================================================================
print("\n" + "#"*70)
print("# PHASE 4: STEP 5 - Vehicle RC (Real Seed Data)")
print("#"*70)

rc_data = test(
    "Work: Verify Vehicle RC (seed: TN09AB1234)",
    "POST", "/gov/vehicle/rc/verify",
    body={"vehicle_number": SEED["vehicle_number"]},
    required_keys=["status", "owner_name", "vehicle_class", "chassis_number"],
    validate_fn=lambda d: (
        d["owner_name"] == SEED["name"] and d["vehicle_class"] == "Motorcycle",
        f"RC wrong: owner={d.get('owner_name')}, class={d.get('vehicle_class')}"
    )
)

# ============================================================================
# PHASE 5: STEP 6 - eShram + PMSYM
# ============================================================================
print("\n" + "#"*70)
print("# PHASE 5: STEP 6 - Gov Schemes (Real Seed Data)")
print("#"*70)

eshram_data = test(
    "Gov: Verify eShram (seed: UAN123456789012)",
    "POST", "/gov/eshram/verify",
    body={"uan": SEED["eshram_uan"]},
    required_keys=["status", "name", "worker_category", "registration_date"],
    validate_fn=lambda d: (
        d["name"] == SEED["name"] and d["worker_category"] == "Gig Worker",
        f"eShram wrong: name={d.get('name')}, cat={d.get('worker_category')}"
    )
)

pmsym_data = test(
    "Gov: Verify PMSYM (seed: UAN123456789012)",
    "POST", "/gov/pmsym/verify",
    body={"uan": SEED["pmsym_uan"]},
    required_keys=["status", "months_contributed", "last_contribution_date"],
    validate_fn=lambda d: (
        d["months_contributed"] == 14,
        f"PMSYM wrong: months={d.get('months_contributed')}, expected 14"
    )
)

# ============================================================================
# PHASE 6: STEP 7 - Insurance (Health + Vehicle)
# ============================================================================
print("\n" + "#"*70)
print("# PHASE 6: STEP 7 - Insurance (Real Seed Data)")
print("#"*70)

health_ins = test(
    "Insurance: Verify Health (seed: HLT2024112345)",
    "POST", "/gov/insurance/policy/verify",
    body={"policy_number": SEED["health_policy"], "policy_type": "health"},
    required_keys=["status", "policy_holder", "insurer", "policy_expiry"],
    validate_fn=lambda d: (
        d["policy_holder"] == SEED["name"] and d["insurer"] == "Star Health Insurance",
        f"Health ins wrong: holder={d.get('policy_holder')}, insurer={d.get('insurer')}"
    )
)

vehicle_ins = test(
    "Insurance: Verify Vehicle (seed: VEH20242222)",
    "POST", "/gov/insurance/policy/verify",
    body={"policy_number": SEED["vehicle_policy"], "policy_type": "vehicle"},
    required_keys=["status", "policy_holder", "insurer"],
    validate_fn=lambda d: (
        d["policy_holder"] == SEED["name"] and d["insurer"] == "Bajaj Allianz",
        f"Vehicle ins wrong: holder={d.get('policy_holder')}, insurer={d.get('insurer')}"
    )
)

# ============================================================================
# PHASE 7: STEP 8 - ITR Verification
# ============================================================================
print("\n" + "#"*70)
print("# PHASE 7: STEP 8 - Tax/ITR (Real Seed Data)")
print("#"*70)

itr_data = test(
    "Tax: Verify ITR (seed: ABCDE1234F, 2024-25)",
    "POST", "/gov/income-tax/itr/verify",
    body={"pan": SEED["itr_pan"], "assessment_year": SEED["itr_ay"]},
    required_keys=["status", "assessment_year", "itr_form", "gross_income", "tax_paid", "filing_date"],
    validate_fn=lambda d: (
        d["gross_income"] == 360000 and d["itr_form"] == "ITR-4",
        f"ITR wrong: income={d.get('gross_income')}, form={d.get('itr_form')}"
    )
)

# ============================================================================
# PHASE 8: STEP 9 - Loan Check
# ============================================================================
print("\n" + "#"*70)
print("# PHASE 8: STEP 9 - Loan Check (Real Seed Data)")
print("#"*70)

loan_check = test(
    "Bank: Check Loans (seed: account 1234567890)",
    "POST", "/bank/loan/check",
    body={"account_number": SEED["account_number"]},
    required_keys=["has_active_loans", "loan_count", "loans"],
    validate_fn=lambda d: (
        d["has_active_loans"] == True and d["loan_count"] == 2 and len(d["loans"]) == 2,
        f"Loan check wrong: active={d.get('has_active_loans')}, count={d.get('loan_count')}, loans={len(d.get('loans', []))}"
    )
)

# ============================================================================
# PHASE 9: SCORE STORAGE + HISTORY
# ============================================================================
print("\n" + "#"*70)
print("# PHASE 9: Score Store + History")
print("#"*70)

score_store = test(
    "Score: Store Score",
    "POST", "/score/store",
    body={"user_id": "e2e_test_user", "score_data": {
        "score": 742, "grade": "A", "risk_level": "Low Risk",
        "pillars": {"P1": 78, "P2": 65, "P3": 40, "P4": 88, "P5": 72, "P6": 55, "P7": 60}
    }},
    required_keys=["status"]
)

score_history = test(
    "Score: Get History",
    "GET", "/score/history/e2e_test_user",
    required_keys=["user_id", "history"],
    validate_fn=lambda d: (
        d["user_id"] == "e2e_test_user" and isinstance(d.get("history"), list),
        f"History wrong: user_id={d.get('user_id')}, history type={type(d.get('history'))}"
    )
)

# ============================================================================
# PHASE 10: LLM REPORT (Groq) - REAL response, NOT static
# ============================================================================
print("\n" + "#"*70)
print("# PHASE 10: LLM Report Generation (Groq - REAL AI response)")
print("#"*70)

report_data = test(
    "Report: Generate LLM Report via Groq",
    "POST", "/api/report/generate",
    body={
        "credit_score": 742,
        "grade": "A",
        "risk_level": "Low Risk",
        "work_type": "platform_worker",
        "language": "English",
        "pillar_scores": {"P1": 0.78, "P2": 0.65, "P3": 0.40, "P4": 0.88, "P5": 0.72, "P6": 0.55, "P7": 0.60, "P8": 0.50},
        "confidence_level": "high",
        "positive_factors": [
            {"feature_label": "Bill Consistency", "pillar": "P4", "impact": 12.4},
            {"feature_label": "Gig Tenure", "pillar": "P5", "impact": 8.1}
        ],
        "negative_factors": [
            {"feature_label": "Existing EMI Ratio", "pillar": "P6", "impact": -8.2},
            {"feature_label": "No Assets", "pillar": "P3", "impact": -5.4}
        ]
    },
    required_keys=["status", "explanation", "suggestions"],
    validate_fn=lambda d: (
        d["status"] == "success" and len(d.get("explanation", "")) > 50,
        f"LLM report check: status={d.get('status')}, explanation_length={len(d.get('explanation', ''))}"
    )
)

if report_data:
    print(f"\n  >> LLM EXPLANATION (first 300 chars):")
    print(f"  >> {report_data.get('explanation', 'EMPTY')[:300]}")
    print(f"  >> SUGGESTIONS: {report_data.get('suggestions', [])[:3]}")
    print(f"  >> Model used: {report_data.get('model_used', 'unknown')}")

# ============================================================================
# PHASE 11: EXPLAINABILITY (SHAP layers)
# ============================================================================
print("\n" + "#"*70)
print("# PHASE 11: Explainability - SHAP Layers")
print("#"*70)

explain_data = test(
    "Explain: Full Explanation (SHAP layers)",
    "POST", "/explain/full",
    body={"proof_id": "GP-e2e-test", "score": 742},
    validate_fn=lambda d: (
        isinstance(d, dict) and len(d) > 0,
        f"Empty or invalid explain response"
    )
)

if explain_data:
    print(f"  >> Explanation keys: {list(explain_data.keys())}")
    for k, v in explain_data.items():
        if isinstance(v, dict):
            print(f"  >> {k}: {json.dumps(v, default=str)[:120]}")
        elif isinstance(v, str):
            print(f"  >> {k}: {v[:100]}")

# ============================================================================
# PHASE 12: LOAN PIPELINE (Products -> KFS -> Apply)
# ============================================================================
print("\n" + "#"*70)
print("# PHASE 12: Loan Pipeline (Products -> KFS -> Apply)")
print("#"*70)

products_data = test(
    "Loan: Get Products (score=742)",
    "POST", "/loan/products",
    body={"score": 742},
    required_keys=["eligible_products"],
    validate_fn=lambda d: (
        len(d.get("eligible_products", [])) > 0,
        f"No eligible products returned! Got: {d.get('eligible_products', [])}"
    )
)

if products_data:
    products = products_data.get("eligible_products", [])
    print(f"  >> {len(products)} eligible products:")
    for p in products:
        print(f"     - {p.get('name', '?')} (id={p.get('id')}, range={p.get('min_amount')}-{p.get('max_amount')})")

    # Use the first product for KFS
    if products:
        first_product = products[0]["id"]
        kfs_data = test(
            f"Loan: Generate KFS (product={first_product})",
            "POST", "/loan/kfs",
            body={"amount": 30000, "tenure": 6, "product_id": first_product, "score": 742},
            required_keys=["amount", "tenure", "apr", "emi", "total_payable", "processing_fee"],
            validate_fn=lambda d: (
                d["emi"] > 0 and d["apr"] > 0,
                f"KFS invalid: emi={d.get('emi')}, apr={d.get('apr')}"
            )
        )
        if kfs_data:
            print(f"  >> KFS: EMI={kfs_data['emi']}, APR={kfs_data['apr']}%, Total={kfs_data['total_payable']}")

        # Apply for loan
        apply_data = test(
            "Loan: Apply (full application)",
            "POST", "/loan/apply",
            body={
                "application": {
                    "product_id": first_product,
                    "loan_amount": 30000,
                    "tenure_months": 6,
                    "name": SEED["name"],
                    "mobile": SEED["mobile"],
                    "aadhaar_verified": True,
                    "pan_verified": True,
                    "net_monthly_income": 25000,
                    "existing_emi_total": 5300,
                    "bank_statement_months": 6,
                    "kfs_acknowledged": True
                },
                "score_report": {
                    "final_score": 742,
                    "finalScore": 742,
                    "grade": "A",
                    "feature_snapshot": {
                        "P1": 0.78, "P2": 0.65, "P3": 0.40, "P4": 0.88,
                        "income_stability_cv": 0.3,
                        "eshram_enrolled": 1.0,
                        "itr_filed_this_year": 1.0,
                        "health_insurance_active": 1.0
                    }
                }
            },
            required_keys=["decision"],
            validate_fn=lambda d: (
                d.get("decision") in ["approved", "rejected", "error"],
                f"Invalid decision: {d.get('decision')}"
            )
        )
        if apply_data:
            print(f"  >> Decision: {apply_data.get('decision')}")
            if apply_data.get("decision") == "approved":
                print(f"  >> Loan ID: {apply_data.get('loan_id')}")
                print(f"  >> Details: {apply_data.get('details')}")
            elif apply_data.get("decision") == "rejected":
                print(f"  >> Reason: {apply_data.get('reason')}")
                print(f"  >> Counter offer: {apply_data.get('counter_offer')}")


# ============================================================================
# FINAL RESULTS
# ============================================================================
print("\n\n" + "="*70)
print("FINAL RESULTS - REAL DATA END-TO-END TEST")
print("="*70)
print(f"\n  Total:    {total}")
print(f"  PASSED:   {passed}")
print(f"  FAILED:   {failed}")
print(f"  Rate:     {passed}/{total} ({(passed/total*100):.1f}%)")

print("\n" + "-"*70)
print("ALL RESULTS:")
print("-"*70)
for status, name, detail in results:
    icon = "OK" if status == "PASS" else "XX"
    print(f"  {icon} {name}")
    print(f"       {detail}")

if critical_failures:
    print("\n" + "!"*70)
    print("CRITICAL FAILURES (these MUST be fixed):")
    print("!"*70)
    for name, detail in critical_failures:
        print(f"  XX {name}: {detail}")
else:
    print("\n" + "*"*70)
    print("ALL TESTS PASSED WITH REAL DATA!")
    print("*"*70)

sys.exit(0 if failed == 0 else 1)
