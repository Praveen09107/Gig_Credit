import requests

headers = {"X-API-Key": "gigcredit-demo-api-key-2026"}
url = "https://gig-credit.onrender.com/score/history/USR_9876543210"

res = requests.get(url, headers=headers)
print(res.status_code)
print(res.json())
