import json
import urllib.request
import sys

# Windows console encoding fix
sys.stdout.reconfigure(encoding='utf-8')

BASE = "https://gig-credit.onrender.com"
HEADERS = {
    "Content-Type": "application/json",
    "X-API-Key": "gigcredit-demo-api-key-2026"
}

def make_post_request(endpoint, payload_dict):
    url = BASE + endpoint
    req = urllib.request.Request(url, data=json.dumps(payload_dict).encode('utf-8'), method="POST")
    for k, v in HEADERS.items():
        req.add_header(k, v)
    
    print(f"\n--- POST {endpoint} ---")
    print(f"Payload: {payload_dict}")
    try:
        with urllib.request.urlopen(req) as response:
            res_data = json.loads(response.read().decode('utf-8'))
            print(f"✅ SUCCESS (Status {response.getcode()}):")
            print(json.dumps(res_data, indent=2))
    except urllib.error.HTTPError as e:
        error_msg = e.read().decode('utf-8')
        print(f"⚠️ HTTP {e.code} (This is expected if mock data isn't in DB yet):")
        print(error_msg)
    except Exception as e:
        print(f"❌ ERROR: {e}")

# 1. Test Aadhaar Verification (Expected: 404 Not Found if no mock data, but proves DB connection)
make_post_request("/gov/aadhaar/verify", {"aadhaar": "234567891234"})

# 2. Test PAN Verification
make_post_request("/gov/pan/verify", {"pan": "ABCDE1234F"})

# 3. Test LLM Report Generation
llm_payload = {
    "credit_score": 780,
    "grade": "A+",
    "risk_level": "Very Low",
    "work_type": "Skilled Trade",
    "language": "en",
    "pillar_scores": {
        "Personal Info": 90,
        "KYC": 100,
        "Bank Activity": 90
    },
    "positive_factors": [
        {"feature_label": "PAN Active", "pillar": "KYC", "impact": 15.0}
    ],
    "negative_factors": [],
    "confidence_level": "High"
}
make_post_request("/api/report/generate", llm_payload)
