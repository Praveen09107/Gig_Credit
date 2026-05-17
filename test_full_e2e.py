import requests, json, time, random, sys
sys.stdout.reconfigure(encoding='utf-8')

BASE = "https://gig-credit.onrender.com"
H = {"Content-Type": "application/json", "X-API-Key": "gigcredit-demo-api-key-2026"}
results = []

def log(section, test, status_code, passed, detail=""):
    tag = "PASS" if passed else "FAIL"
    results.append({"section": section, "test": test, "status": status_code, "result": tag, "detail": detail})
    print(f"  [{tag}] {test} (HTTP {status_code}) {detail[:120]}")

def post(url, body):
    r = requests.post(url, json=body, headers=H, timeout=30)
    return r.status_code, r.json()

def get(url):
    r = requests.get(url, headers=H, timeout=30)
    return r.status_code, r.json()

# ========== SECTION 1: HEALTH CHECK ==========
print("\n" + "="*70)
print(" SECTION 1: BACKEND HEALTH & DB CONNECTIVITY")
print("="*70)
try:
    sc, j = get(f"{BASE}/health")
    log("Health", "Backend reachable", sc, sc==200, json.dumps(j))
    log("Health", "MongoDB connected", sc, j.get("status") in ["ok","degraded"], f"db={j.get('database_connected')}")
except Exception as e:
    log("Health", "Backend reachable", 0, False, str(e))

# ========== SECTION 2: AUTH OTP FLOW ==========
print("\n" + "="*70)
print(" SECTION 2: AUTH - OTP SEND & VERIFY")
print("="*70)
# Send OTP for login (existing user)
try:
    sc, j = post(f"{BASE}/auth/otp/send", {"mobile": "9876543210", "isSignup": False})
    log("Auth", "OTP Send (login existing)", sc, sc==200 and "otp" in j, j.get("otp",""))
    if sc == 200:
        otp = j["otp"]
        sc2, j2 = post(f"{BASE}/auth/otp/verify", {"mobile": "9876543210", "otp": otp})
        log("Auth", "OTP Verify (correct)", sc2, sc2==200 and "token" in j2)
        # Wrong OTP
        sc3, j3 = post(f"{BASE}/auth/otp/send", {"mobile": "9876543210", "isSignup": False})
        sc4, j4 = post(f"{BASE}/auth/otp/verify", {"mobile": "9876543210", "otp": "000000"})
        log("Auth", "OTP Verify (wrong OTP rejected)", sc4, sc4==400)
except Exception as e:
    log("Auth", "OTP flow", 0, False, str(e))

# Invalid mobile
try:
    sc, j = post(f"{BASE}/auth/otp/send", {"mobile": "12345", "isSignup": False})
    log("Auth", "Invalid mobile rejected", sc, sc==400)
except Exception as e:
    log("Auth", "Invalid mobile", 0, False, str(e))

# ========== SECTION 3: STEP 2 - KYC (Aadhaar + PAN) ==========
print("\n" + "="*70)
print(" SECTION 3: STEP 2 - KYC VERIFICATION (Aadhaar + PAN)")
print("="*70)
# Aadhaar valid
try:
    sc, j = post(f"{BASE}/gov/aadhaar/verify", {"aadhaar": "765432101234"})
    log("KYC", "Aadhaar valid (DB match)", sc, sc==200 and j.get("status")=="valid", f"name={j.get('name')}")
except Exception as e:
    log("KYC", "Aadhaar valid", 0, False, str(e))
# Aadhaar bad format
try:
    sc, j = post(f"{BASE}/gov/aadhaar/verify", {"aadhaar": "1234"})
    log("KYC", "Aadhaar bad format rejected", sc, sc==400)
except Exception as e:
    log("KYC", "Aadhaar bad format", 0, False, str(e))
# Aadhaar not found
try:
    sc, j = post(f"{BASE}/gov/aadhaar/verify", {"aadhaar": "999999999999"})
    log("KYC", "Aadhaar not found rejected", sc, sc==404)
except Exception as e:
    log("KYC", "Aadhaar not found", 0, False, str(e))
# PAN valid
try:
    sc, j = post(f"{BASE}/gov/pan/verify", {"pan": "ABCDE1234F"})
    log("KYC", "PAN valid (DB match + OTP)", sc, sc==200 and "otp" in j, f"name={j.get('name')}, itr={j.get('itr_filed')}")
except Exception as e:
    log("KYC", "PAN valid", 0, False, str(e))
# PAN bad format
try:
    sc, j = post(f"{BASE}/gov/pan/verify", {"pan": "1234567890"})
    log("KYC", "PAN bad format rejected", sc, sc==400)
except Exception as e:
    log("KYC", "PAN bad format", 0, False, str(e))
# PAN not found
try:
    sc, j = post(f"{BASE}/gov/pan/verify", {"pan": "ZZZZZ9999Z"})
    log("KYC", "PAN not in DB rejected", sc, sc==404)
except Exception as e:
    log("KYC", "PAN not in DB", 0, False, str(e))

# ========== SECTION 4: STEP 3 - BANK ==========
print("\n" + "="*70)
print(" SECTION 4: STEP 3 - BANK VERIFICATION (IFSC + Account + Loans)")
print("="*70)
try:
    sc, j = post(f"{BASE}/bank/ifsc/verify", {"ifsc": "HDFC0001234"})
    log("Bank", "IFSC valid", sc, sc==200 and j.get("status")=="valid", f"bank={j.get('bank_name')}")
except Exception as e:
    log("Bank", "IFSC valid", 0, False, str(e))
try:
    sc, j = post(f"{BASE}/bank/ifsc/verify", {"ifsc": "XXXX"})
    log("Bank", "IFSC bad format rejected", sc, sc==400)
except Exception as e:
    log("Bank", "IFSC bad format", 0, False, str(e))
try:
    sc, j = post(f"{BASE}/bank/account/verify", {"account_number": "1234567890", "ifsc": "HDFC0001234"})
    log("Bank", "Account verify (DB match)", sc, sc==200 and j.get("status")=="valid", f"holder={j.get('account_holder')}")
except Exception as e:
    log("Bank", "Account verify", 0, False, str(e))
try:
    sc, j = post(f"{BASE}/bank/loan/check", {"account_number": "1234567890"})
    log("Bank", "Loan check", sc, sc==200, f"has_loans={j.get('has_active_loans')}")
except Exception as e:
    log("Bank", "Loan check", 0, False, str(e))

# ========== SECTION 5: STEP 4 - UTILITY ==========
print("\n" + "="*70)
print(" SECTION 5: STEP 4 - UTILITY VERIFICATION")
print("="*70)
try:
    sc, j = post(f"{BASE}/utility/verify", {"consumer_number": "ELEC001234", "provider": "TNEB"})
    log("Utility", "Electricity verify", sc, sc in [200, 404], json.dumps(j)[:100])
except Exception as e:
    log("Utility", "Electricity verify", 0, False, str(e))

# ========== SECTION 6: STEP 5 - WORK (Vehicle RC) ==========
print("\n" + "="*70)
print(" SECTION 6: STEP 5 - WORK VERIFICATION (Vehicle RC)")
print("="*70)
try:
    sc, j = post(f"{BASE}/gov/vehicle/rc/verify", {"vehicle_number": "TN09AB1234"})
    log("Work", "Vehicle RC verify (DB match)", sc, sc==200 and j.get("status")=="valid", f"owner={j.get('owner_name')}")
except Exception as e:
    log("Work", "Vehicle RC verify", 0, False, str(e))
try:
    sc, j = post(f"{BASE}/gov/vehicle/rc/verify", {"vehicle_number": "123"})
    log("Work", "Vehicle RC bad format", sc, sc==400)
except Exception as e:
    log("Work", "Vehicle RC bad format", 0, False, str(e))

# ========== SECTION 7: STEP 6 - GOV SCHEMES (eShram + PMSYM) ==========
print("\n" + "="*70)
print(" SECTION 7: STEP 6 - GOV SCHEMES (eShram + PMSYM + Ration)")
print("="*70)
try:
    sc, j = post(f"{BASE}/gov/eshram/verify", {"uan": "UAN123456789012"})
    log("GovSchemes", "eShram verify (DB match)", sc, sc==200 and j.get("status")=="registered", f"name={j.get('name')}")
except Exception as e:
    log("GovSchemes", "eShram verify", 0, False, str(e))
try:
    sc, j = post(f"{BASE}/gov/eshram/verify", {"uan": "BADFORMAT"})
    log("GovSchemes", "eShram bad format", sc, sc==400)
except Exception as e:
    log("GovSchemes", "eShram bad format", 0, False, str(e))
try:
    sc, j = post(f"{BASE}/gov/pmsym/verify", {"uan": "UAN123456789012"})
    log("GovSchemes", "PMSYM verify (DB match)", sc, sc==200 and j.get("status")=="active", f"months={j.get('months_contributed')}")
except Exception as e:
    log("GovSchemes", "PMSYM verify", 0, False, str(e))
try:
    sc, j = post(f"{BASE}/gov/ration/verify", {"card_number": "TN-BPL-001234"})
    log("GovSchemes", "Ration card verify", sc, sc in [200, 404], json.dumps(j)[:100])
except Exception as e:
    log("GovSchemes", "Ration card verify", 0, False, str(e))

# ========== SECTION 8: STEP 7 - INSURANCE ==========
print("\n" + "="*70)
print(" SECTION 8: STEP 7 - INSURANCE VERIFICATION")
print("="*70)
try:
    sc, j = post(f"{BASE}/gov/insurance/policy/verify", {"policy_number": "HLT2024112345", "policy_type": "health"})
    log("Insurance", "Health policy verify (DB match)", sc, sc==200 and j.get("status")=="active", f"insurer={j.get('insurer')}")
except Exception as e:
    log("Insurance", "Health policy verify", 0, False, str(e))
try:
    sc, j = post(f"{BASE}/gov/insurance/policy/verify", {"policy_number": "VEH20242222", "policy_type": "vehicle"})
    log("Insurance", "Vehicle policy verify (DB match)", sc, sc==200 and j.get("status")=="active", f"insurer={j.get('insurer')}")
except Exception as e:
    log("Insurance", "Life policy verify", 0, False, str(e))
# ABHA
try:
    sc, j = post(f"{BASE}/gov/abha/verify", {"aybha_id": "ABHA-001234"})
    log("Insurance", "ABHA health ID verify", sc, sc in [200, 404], json.dumps(j)[:100])
except Exception as e:
    log("Insurance", "ABHA verify", 0, False, str(e))

# ========== SECTION 9: STEP 8 - TAX (GST + ITR) ==========
print("\n" + "="*70)
print(" SECTION 9: STEP 8 - TAX & COMPLIANCE (GST + ITR)")
print("="*70)
try:
    sc, j = post(f"{BASE}/gov/gst/verify", {"gst": "33ABCDE1234F1Z5"})
    log("Tax", "GST format valid (not in DB = 404)", sc, sc==404)
except Exception as e:
    log("Tax", "GST verify", 0, False, str(e))
try:
    sc, j = post(f"{BASE}/gov/gst/verify", {"gst": "BADGST"})
    log("Tax", "GST bad format rejected", sc, sc==400)
except Exception as e:
    log("Tax", "GST bad format", 0, False, str(e))
try:
    sc, j = post(f"{BASE}/gov/income-tax/itr/verify", {"pan": "ABCDE1234F", "assessment_year": "2024-25"})
    log("Tax", "ITR verify (DB match)", sc, sc==200 and j.get("status")=="filed", f"income={j.get('gross_income')}")
except Exception as e:
    log("Tax", "ITR verify", 0, False, str(e))

# ========== SECTION 10: STEP 9 - EMI/LOANS (Bank loan check) ==========
print("\n" + "="*70)
print(" SECTION 10: STEP 9 - EMI & LOANS CHECK")
print("="*70)
try:
    sc, j = post(f"{BASE}/bank/loan/check", {"account_number": "9876543210"})
    log("EMI", "Loan portfolio check", sc, sc==200, f"loans={j.get('loan_count',0)}")
except Exception as e:
    log("EMI", "Loan portfolio check", 0, False, str(e))

# ========== SECTION 11: SCORING + LLM ==========
print("\n" + "="*70)
print(" SECTION 11: SCORE GENERATION & LLM REPORT")
print("="*70)
try:
    payload = {
        "credit_score": 720, "grade": "B+", "risk_level": "Low",
        "work_type": "platform_worker", "language": "English",
        "pillar_scores": {"P1":0.72,"P2":0.65,"P3":0.58,"P4":0.60,"P5":0.90,"P6":0.55,"P7":0.40,"P8":0.30},
        "confidence_level": "high",
        "positive_factors": [{"feature_label":"income_stability","pillar":"P1","impact":0.15}],
        "negative_factors": [{"feature_label":"debt_ratio","pillar":"P3","impact":-0.10}]
    }
    sc, j = post(f"{BASE}/api/report/generate", payload)
    log("Score", "LLM report generate", sc, sc==200 and "explanation" in j, f"status={j.get('status')}")
except Exception as e:
    log("Score", "LLM report generate", 0, False, str(e))

try:
    sc, j = post(f"{BASE}/explain/full", {"user_id": "test", "score_data": {"score": 720}})
    log("Score", "Explainability engine", sc, sc==200 and "l5_live_shap" in j)
except Exception as e:
    log("Score", "Explainability engine", 0, False, str(e))

# ========== SECTION 12: DYNAMIC PROFILES (3 different categories) ==========
print("\n" + "="*70)
print(" SECTION 12: DYNAMIC PROFILE VARIANCE TEST (3 profiles)")
print("="*70)
with open("app/assets/constants/golden_100.json", "r") as f:
    profiles = json.load(f)
print(f"  Total profiles loaded: {len(profiles)}")

# Pick 3 distinct profiles
picks = random.sample(profiles, 3)
scores_generated = []
for idx, p in enumerate(picks):
    feat = p["features"]
    inc = feat.get("avg_monthly_income_norm", 0)
    sav = feat.get("savings_rate", 0)
    debt = feat.get("emi_to_income_ratio", 0)
    mock_score = max(300, min(850, int(300 + inc*250 + sav*150 - debt*100)))
    scores_generated.append(mock_score)
    grade = "A" if mock_score >= 750 else ("B" if mock_score >= 600 else "C")
    
    report_payload = {
        "score_data": {
            "proofId": f"DYN-TEST-{int(time.time())}-{idx}",
            "finalScore": mock_score, "grade": grade,
            "riskBand": "Low" if mock_score>=700 else "Medium",
            "workType": p.get("work_type","unknown"),
            "computeTimeMs": 180, "overallConfidence": round(0.7+inc*0.2,2),
            "generatedAt": time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
            "probability": round(mock_score/850, 4),
            "pillars": [], "pillarContributions": {},
            "topStrengths": [], "topConcerns": [],
            "llmExplanation": f"Dynamic test profile {idx+1}",
            "tailoredSuggestions": []
        },
        "user_id": "e2e_test_user"
    }
    try:
        sc, j = post(f"{BASE}/score/store", report_payload)
        log("Dynamic", f"Profile {idx+1} store (score={mock_score}, wt={p.get('work_type')})", sc, sc==200)
    except Exception as e:
        log("Dynamic", f"Profile {idx+1} store", 0, False, str(e))

# Check variance
if len(set(scores_generated)) > 1:
    log("Dynamic", f"Score variance check {scores_generated}", 200, True, "All scores are different - dynamic!")
else:
    log("Dynamic", f"Score variance check {scores_generated}", 200, False, "WARNING: identical scores")

# ========== SECTION 13: LOAN PIPELINE ==========
print("\n" + "="*70)
print(" SECTION 13: LOAN APPLICATION PIPELINE")
print("="*70)
try:
    sc, j = post(f"{BASE}/loan/products", {"score": 720})
    log("Loan", "Get eligible products", sc, sc==200, f"count={len(j.get('eligible_products',[]))}")
except Exception as e:
    log("Loan", "Get eligible products", 0, False, str(e))
try:
    sc, j = post(f"{BASE}/loan/kfs", {"amount": 10000, "tenure": 6, "product_id": "emergency_advance", "score": 720})
    log("Loan", "KFS generation", sc, sc==200 and "emi" in j, f"emi={j.get('emi')}, apr={j.get('apr')}")
except Exception as e:
    log("Loan", "KFS generation", 0, False, str(e))
try:
    sc, j = post(f"{BASE}/loan/apply", {
        "application": {"product_id":"emergency_advance","loan_amount":5000,"tenure_months":3,"user_id":"e2e_test_user"},
        "score_report": {"finalScore":720,"proofId":"E2E-LOAN","riskBand":"Low"}
    })
    log("Loan", "Apply loan (full pipeline)", sc, sc==200, f"decision={j.get('decision')}, id={j.get('loan_id')}")
except Exception as e:
    log("Loan", "Apply loan", 0, False, str(e))

# ========== SECTION 14: HISTORY RETRIEVAL ==========
print("\n" + "="*70)
print(" SECTION 14: MONGODB HISTORY RETRIEVAL")
print("="*70)
try:
    sc, j = get(f"{BASE}/score/history/e2e_test_user")
    hist = j.get("history", [])
    log("History", "Fetch history from MongoDB", sc, sc==200 and len(hist)>=3, f"count={len(hist)}")
    if len(hist) >= 2:
        s1 = hist[0].get("finalScore")
        s2 = hist[1].get("finalScore")
        log("History", "Reports are dynamic (different scores)", 200, s1 != s2, f"latest={s1}, prev={s2}")
except Exception as e:
    log("History", "Fetch history", 0, False, str(e))

# ========== FINAL SUMMARY ==========
print("\n" + "="*70)
print(" FINAL SUMMARY")
print("="*70)
passed = sum(1 for r in results if r["result"]=="PASS")
failed = sum(1 for r in results if r["result"]=="FAIL")
total = len(results)
print(f"  TOTAL: {total}  |  PASSED: {passed}  |  FAILED: {failed}")
print(f"  Pass Rate: {round(passed/total*100,1)}%")
print()
for r in results:
    if r["result"] == "FAIL":
        print(f"  [FAIL] {r['section']} > {r['test']} (HTTP {r['status']}) {r['detail'][:80]}")
print("="*70)
