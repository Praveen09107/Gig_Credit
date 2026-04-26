import requests
import json
import time

BASE = "http://localhost:8000"
results = []

# 1. Health Check
print("=" * 60)
print("TEST 1: API Health Check")
print("=" * 60)
try:
    r = requests.get(f"{BASE}/health", timeout=5)
    print(f"  Status: {r.status_code}")
    print(f"  Body:   {r.json()}")
    results.append(("Health Check", "PASS" if r.status_code == 200 else "FAIL"))
except Exception as e:
    print(f"  ERROR: {e}")
    results.append(("Health Check", "FAIL"))

# 2. OTP Send  (route: /auth/otp/send)
print()
print("=" * 60)
print("TEST 2: Auth - Send OTP (/auth/otp/send)")
print("=" * 60)
try:
    r = requests.post(f"{BASE}/auth/otp/send", json={"mobile": "9876543210"}, timeout=5)
    print(f"  Status: {r.status_code}")
    print(f"  Body:   {r.json()}")
    results.append(("Auth OTP Send", "PASS" if r.status_code == 200 else "FAIL"))
except Exception as e:
    print(f"  ERROR: {e}")
    results.append(("Auth OTP Send", "FAIL"))

# 3. OTP Verify (route: /auth/otp/verify)
print()
print("=" * 60)
print("TEST 3: Auth - Verify OTP (/auth/otp/verify)")
print("=" * 60)
try:
    r = requests.post(
        f"{BASE}/auth/otp/verify",
        json={"mobile": "9876543210", "otp": "123456"},
        timeout=5,
    )
    print(f"  Status: {r.status_code}")
    print(f"  Body:   {r.json()}")
    results.append(("Auth OTP Verify", "PASS" if r.status_code == 200 else "FAIL"))
except Exception as e:
    print(f"  ERROR: {e}")
    results.append(("Auth OTP Verify", "FAIL"))

# 4. Gov Verification - Aadhaar (route: /gov/aadhaar/verify)
print()
print("=" * 60)
print("TEST 4: Gov - Aadhaar Verify (/gov/aadhaar/verify)")
print("=" * 60)
try:
    r = requests.post(
        f"{BASE}/gov/aadhaar/verify",
        json={"aadhaar": "234567891234"},
        timeout=5,
    )
    print(f"  Status: {r.status_code}")
    body = json.dumps(r.json(), indent=2)
    print(f"  Body:   {body[:300]}")
    # 404 = not_found (expected for test data), 200 = found, both are valid API responses
    results.append(("Aadhaar Verify", "PASS" if r.status_code in [200, 404] else "FAIL"))
except Exception as e:
    print(f"  ERROR: {e}")
    results.append(("Aadhaar Verify", "FAIL"))

# 5. Gov Verification - PAN (route: /gov/pan/verify)
print()
print("=" * 60)
print("TEST 5: Gov - PAN Verify (/gov/pan/verify)")
print("=" * 60)
try:
    r = requests.post(
        f"{BASE}/gov/pan/verify",
        json={"pan": "ABCDE1234F"},
        timeout=5,
    )
    print(f"  Status: {r.status_code}")
    body = json.dumps(r.json(), indent=2)
    print(f"  Body:   {body[:300]}")
    results.append(("PAN Verify", "PASS" if r.status_code in [200, 404] else "FAIL"))
except Exception as e:
    print(f"  ERROR: {e}")
    results.append(("PAN Verify", "FAIL"))

# 6. Bank - Account Verify (route: /bank/account/verify)
print()
print("=" * 60)
print("TEST 6: Bank - Account Verify (/bank/account/verify)")
print("=" * 60)
try:
    r = requests.post(
        f"{BASE}/bank/account/verify",
        json={"account_number": "1234567890", "ifsc": "SBIN0001234"},
        timeout=5,
    )
    print(f"  Status: {r.status_code}")
    body = json.dumps(r.json(), indent=2)
    print(f"  Body:   {body[:300]}")
    results.append(("Bank Account", "PASS" if r.status_code in [200, 404] else "FAIL"))
except Exception as e:
    print(f"  ERROR: {e}")
    results.append(("Bank Account", "FAIL"))

# 7. Bank - IFSC Verify (route: /bank/ifsc/verify)
print()
print("=" * 60)
print("TEST 7: Bank - IFSC Verify (/bank/ifsc/verify)")
print("=" * 60)
try:
    r = requests.post(
        f"{BASE}/bank/ifsc/verify",
        json={"ifsc": "SBIN0001234"},
        timeout=5,
    )
    print(f"  Status: {r.status_code}")
    body = json.dumps(r.json(), indent=2)
    print(f"  Body:   {body[:300]}")
    results.append(("IFSC Verify", "PASS" if r.status_code in [200, 404] else "FAIL"))
except Exception as e:
    print(f"  ERROR: {e}")
    results.append(("IFSC Verify", "FAIL"))

# 8. Insurance Verify (route: /gov/insurance/policy/verify)
print()
print("=" * 60)
print("TEST 8: Insurance - Policy Verify (/gov/insurance/policy/verify)")
print("=" * 60)
try:
    r = requests.post(
        f"{BASE}/gov/insurance/policy/verify",
        json={"policy_number": "POL123", "policy_type": "health"},
        timeout=5,
    )
    print(f"  Status: {r.status_code}")
    body = json.dumps(r.json(), indent=2)
    print(f"  Body:   {body[:300]}")
    results.append(("Insurance Policy", "PASS" if r.status_code in [200, 404] else "FAIL"))
except Exception as e:
    print(f"  ERROR: {e}")
    results.append(("Insurance Policy", "FAIL"))

# 9. LLM Report Generation (route: /api/report/generate)
print()
print("=" * 60)
print("TEST 9: Server -> LLM (Groq) Report Generation")
print("=" * 60)
payload = {
    "credit_score": 720,
    "grade": "A",
    "risk_level": "Low",
    "work_type": "platform_worker",
    "language": "English",
    "pillar_scores": {
        "P1": 0.78, "P2": 0.85, "P3": 0.65, "P4": 0.72,
        "P5": 0.90, "P6": 0.60, "P7": 0.75,
    },
    "positive_factors": [
        {"feature_label": "Consistent income", "pillar": "Income Stability", "impact": 0.15}
    ],
    "negative_factors": [
        {"feature_label": "No insurance", "pillar": "Financial Resilience", "impact": -0.08}
    ],
    "confidence_level": "High",
}
try:
    t0 = time.time()
    r = requests.post(f"{BASE}/api/report/generate", json=payload, timeout=30)
    elapsed = time.time() - t0
    data = r.json()
    model_used = data.get("model_used")
    status_val = data.get("status")
    explanation = data.get("explanation", "")
    suggestions = data.get("suggestions", [])
    print(f"  Status:      {r.status_code}")
    print(f"  Latency:     {elapsed:.2f}s")
    print(f"  LLM Model:   {model_used}")
    print(f"  LLM Status:  {status_val}")
    print(f"  Excerpt:     {explanation[:200]}...")
    print(f"  Suggestions: {suggestions}")
    results.append(("LLM Report Gen", "PASS" if r.status_code == 200 else "FAIL"))
except Exception as e:
    print(f"  ERROR: {e}")
    results.append(("LLM Report Gen", "FAIL"))

# 10. MongoDB Connectivity (already tested via API calls above)
print()
print("=" * 60)
print("TEST 10: MongoDB Connectivity (via API data queries)")
print("=" * 60)
# If any of the DB-backed endpoints returned 200 or 404 (not 500), DB is live
db_tests = [r for name, r in results if name in ["Aadhaar Verify", "PAN Verify", "Bank Account", "IFSC Verify"]]
db_ok = all(s == "PASS" for s in db_tests)
print(f"  All DB-backed endpoints responded (no 500 errors): {db_ok}")
results.append(("MongoDB Live", "PASS" if db_ok else "FAIL"))

# ========================================
# FINAL SUMMARY
# ========================================
print()
print("=" * 60)
print("FINAL VERIFICATION SUMMARY")
print("=" * 60)
pass_count = sum(1 for _, s in results if s == "PASS")
fail_count = sum(1 for _, s in results if s != "PASS")
for name, status in results:
    icon = "[PASS]" if status == "PASS" else "[FAIL]"
    print(f"  {icon} {name}")
print()
print(f"  Total: {pass_count} passed, {fail_count} failed out of {len(results)} tests")
if fail_count == 0:
    print("  ALL SYSTEMS OPERATIONAL!")
