import requests
import json
import time

BASE_URL = "https://gig-credit.onrender.com"
HEADERS = {
    "Content-Type": "application/json",
    "X-API-Key": "gigcredit-demo-api-key-2026"
}

def print_header(title):
    print(f"\n{'='*60}")
    print(f" {title}")
    print(f"{'='*60}")

def test_gov_verification():
    print_header("1. API Verification Endpoints (PAN Verification)")
    
    # 1. Valid PAN format, exists in DB (Assuming ABCDE1234F is in mock DB)
    print("Testing VALID PAN (Format & DB Match)...")
    try:
        res = requests.post(f"{BASE_URL}/gov/pan/verify", json={"pan": "ABCDE1234F"}, headers=HEADERS)
        print(f"Status: {res.status_code}")
        print(f"Response: {res.json()}")
        if res.status_code == 200 and 'otp' in res.json():
            print("SUCCESS: Expected OTP returned.")
    except Exception as e:
        print(f"ERROR: {e}")

    # 2. Invalid PAN format
    print("\nTesting INVALID PAN FORMAT...")
    try:
        res = requests.post(f"{BASE_URL}/gov/pan/verify", json={"pan": "1234567890"}, headers=HEADERS)
        print(f"Status: {res.status_code}")
        print(f"Response: {res.json()}")
        if res.status_code == 400:
            print("SUCCESS: Correctly caught invalid format.")
    except Exception as e:
        print(f"ERROR: {e}")

    # 3. Valid PAN format, but NOT in DB
    print("\nTesting NON-EXISTENT PAN...")
    try:
        res = requests.post(f"{BASE_URL}/gov/pan/verify", json={"pan": "ZZZZZ9999Z"}, headers=HEADERS)
        print(f"Status: {res.status_code}")
        print(f"Response: {res.json()}")
        if res.status_code == 404:
            print("SUCCESS: Correctly handled non-existent PAN.")
    except Exception as e:
        print(f"ERROR: {e}")


def test_score_pipeline_and_db():
    print_header("2. Score Report Generation & MongoDB Storage")
    
    # Load Golden 100 profiles to act as dynamic frontend data
    import random
    with open("app/assets/constants/golden_100.json", "r") as f:
        profiles = json.load(f)
    
    print(f"Loaded {len(profiles)} dynamic user profiles.")
    
    selected_profiles = random.sample(profiles, 2)
    
    for idx, p in enumerate(selected_profiles):
        print(f"\n--- Testing Dynamic Profile {idx+1} ---")
        print(f"Work Type: {p.get('work_type')}, Category: {p.get('category')}")
        
        # We will mock the payload sent from frontend to `/score/store`
        score_payload = {
            "score_data": {
                "proofId": f"TEST-{int(time.time())}-{idx}",
                "finalScore": int(p['features'].get('avg_monthly_income_norm', 0.5) * 850),
                "grade": "B",
                "riskBand": "Medium",
                "workType": p.get('work_type', 'unknown'),
                "computeTimeMs": 150,
                "overallConfidence": 0.88,
                "generatedAt": time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
                "pillars": [],
                "pillarContributions": {},
                "topStrengths": [],
                "topConcerns": [],
                "llmExplanation": "Dynamic test explanation",
                "tailoredSuggestions": []
            },
            "user_id": "test_user_id"
        }
        
        try:
            res = requests.post(f"{BASE_URL}/score/store", json=score_payload, headers=HEADERS)
            print(f"Store Score Status: {res.status_code}")
            print(f"Response: {res.json()}")
            if res.status_code == 200:
                print("SUCCESS: Score stored in MongoDB.")
        except Exception as e:
            print(f"ERROR: {e}")


def test_loan_pipeline_and_db():
    print_header("3. Loan Application Pipeline & MongoDB Storage")
    
    loan_payload = {
        "application": {
            "product_id": "emergency_advance",
            "loan_amount": 5000,
            "tenure_months": 3,
            "user_id": "test_user_id",
            "aadhaar_verified": True,
            "pan_verified": True
        },
        "score_report": {
            "finalScore": 750,
            "proofId": "TEST-LOAN-APP",
            "riskBand": "Low"
        }
    }
    
    try:
        res = requests.post(f"{BASE_URL}/loan/apply", json=loan_payload, headers=HEADERS)
        print(f"Apply Loan Status: {res.status_code}")
        print(f"Response: {res.json()}")
        if res.status_code == 200:
            print("SUCCESS: Loan applied, evaluated, and stored in MongoDB.")
    except Exception as e:
        print(f"ERROR: {e}")


def test_history_retrieval():
    print_header("4. History Retrieval (MongoDB Fetch)")
    
    try:
        res = requests.get(f"{BASE_URL}/score/history/test_user_id", headers=HEADERS)
        print(f"History Fetch Status: {res.status_code}")
        if res.status_code == 200:
            data = res.json()
            print(f"Retrieved {len(data)} past reports for test_user_id.")
            if len(data) > 0:
                print(f"Latest Report Proof ID: {data[0].get('proofId')}")
                print("SUCCESS: Dynamic data retrieved correctly from MongoDB history.")
        else:
            print(f"Response: {res.json()}")
    except Exception as e:
        print(f"ERROR: {e}")


if __name__ == "__main__":
    test_gov_verification()
    test_score_pipeline_and_db()
    test_loan_pipeline_and_db()
    test_history_retrieval()
