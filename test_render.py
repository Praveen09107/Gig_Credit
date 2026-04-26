import json
import urllib.request
import sys

# Windows console encoding fix
sys.stdout.reconfigure(encoding='utf-8')

url = "https://gig-credit.onrender.com/api/report/generate"
payload = {
    "credit_score": 750,
    "grade": "A",
    "risk_level": "Low",
    "work_type": "Platform Worker",
    "language": "en",
    "pillar_scores": {
        "Personal Info": 90,
        "KYC": 100,
        "Bank Activity": 80
    },
    "positive_factors": [
        {"feature_label": "Aadhaar Match", "pillar": "KYC", "impact": 10.0}
    ],
    "negative_factors": [],
    "confidence_level": "High"
}

req = urllib.request.Request(url, data=json.dumps(payload).encode('utf-8'), method="POST")
req.add_header("Content-Type", "application/json")
# We need to add the HMAC signature or bypass it depending on SKIP_AUTH/ENABLE_HMAC.
# Since it's SKIP_AUTH=true, we don't need HMAC, but we might need the SERVER_API_KEY
req.add_header("X-API-Key", "gigcredit-demo-api-key-2026")

print(f"Sending request to {url}...")
try:
    with urllib.request.urlopen(req) as response:
        print("\n✅ SUCCESS! Server responded with:")
        print(json.dumps(json.loads(response.read().decode('utf-8')), indent=2))
except Exception as e:
    error_msg = getattr(e, 'read', lambda: b"")().decode('utf-8')
    print("\n❌ ERROR:", str(e))
    if error_msg:
        print("Details:", error_msg)
