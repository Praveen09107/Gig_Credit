import requests
import json
import time

def run_tests():
    print("--- Testing API Connectivity ---")
    try:
        health = requests.get("http://localhost:8000/health")
        print(f"Health Check: {health.status_code}")
        print(f"Response: {health.json()}")
    except Exception as e:
        print(f"Health check failed: {e}")
        return

    print("\n--- Testing LLM Connectivity (Groq) ---")
    payload = {
        "credit_score": 750,
        "grade": "A",
        "risk_level": "Low",
        "work_type": "Freelancer",
        "language": "en",
        "pillar_scores": {
            "P1": 0.8,
            "P2": 0.9,
            "P3": 0.7,
            "P4": 0.85,
            "P5": 0.9,
            "P6": 0.75,
            "P7": 0.8
        },
        "positive_factors": [
            {"feature_label": "High consistent income", "pillar": "Income Stability", "impact": 0.2}
        ],
        "negative_factors": [
            {"feature_label": "Short credit history", "pillar": "Credit History", "impact": -0.05}
        ],
        "confidence_level": "High"
    }

    try:
        start_time = time.time()
        print("Sending request to LLM (this may take a few seconds)...")
        response = requests.post("http://localhost:8000/api/report/generate", json=payload)
        elapsed = time.time() - start_time
        
        print(f"LLM Status Code: {response.status_code}")
        print(f"Time Taken: {elapsed:.2f} seconds")
        
        if response.status_code == 200:
            data = response.json()
            print("\n[SUCCESS] Server to LLM Connectivity Confirmed!")
            print(f"Model Used: {data.get('model_used')}")
            print("\nExcerpt of LLM Explanation:")
            print(f"{data.get('explanation')[:300]}...")
            print("\nSuggestions:")
            for s in data.get('suggestions', []):
                print(f"- {s}")
        else:
            print(f"[FAILED] Server to LLM connection error.")
            print(response.text)
            
    except Exception as e:
        print(f"LLM request failed: {e}")

if __name__ == "__main__":
    run_tests()
