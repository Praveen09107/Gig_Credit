from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_otp_send_invalid_mobile_format():
    response = client.post("/auth/otp/send", json={"mobile": "123"})
    assert response.status_code == 400
    data = response.json()
    assert data["error"] == "invalid_format"


def test_otp_verify_invalid_otp():
    response = client.post("/auth/otp/verify", json={"mobile": "9876543210", "otp": "000000"})
    assert response.status_code == 400
    data = response.json()
    assert data["error"] == "invalid_otp"
