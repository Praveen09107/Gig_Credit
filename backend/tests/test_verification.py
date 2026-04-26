from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_aadhaar_invalid_format():
    response = client.post("/gov/aadhaar/verify", json={"aadhaar": "123"})
    assert response.status_code == 400
    assert response.json()["error"] == "invalid_format"


def test_pan_invalid_format():
    response = client.post("/gov/pan/verify", json={"pan": "PAN123"})
    assert response.status_code == 400
    assert response.json()["error"] == "invalid_format"
