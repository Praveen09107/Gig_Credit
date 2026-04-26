from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_report_generate_fallback_without_groq_key():
    payload = {
        "credit_score": 682,
        "grade": "B",
        "risk_level": "Medium",
        "work_type": "platform_worker",
        "language": "English",
        "pillar_scores": {"income_stability": 72},
        "positive_factors": [{"feature_label": "Income consistency", "pillar": "P1", "impact": 15}],
        "negative_factors": [{"feature_label": "EMI ratio high", "pillar": "P3", "impact": -10}],
        "confidence_level": "High",
    }
    response = client.post("/api/report/generate", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] in ["success", "fallback"]
    assert isinstance(data["suggestions"], list)
