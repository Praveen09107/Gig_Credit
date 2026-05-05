import asyncio
import httpx
import time

async def test_otp_flow():
    base_url = "http://localhost:8000"
    mobile = "9876543210"
    
    print("--- TEST 1: Requesting OTP ---")
    async with httpx.AsyncClient() as client:
        # We need the HMAC headers if required, but for local testing maybe we can just hit it.
        # Let's see if hmac is strictly enforced.
        headers = {"X-API-Key": "gigcredit-demo-api-key-2026", "X-Signature": "fake_sig", "X-Timestamp": "1234"}
        
        try:
            res1 = await client.post(f"{base_url}/auth/otp/send", json={"mobile": mobile}, headers=headers)
            print(f"Send OTP Response: {res1.status_code} - {res1.text}")
        except Exception as e:
            print(f"Error: {e}")

if __name__ == "__main__":
    asyncio.run(test_otp_flow())
