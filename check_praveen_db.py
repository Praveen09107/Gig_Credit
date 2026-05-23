import asyncio
import sys
sys.path.insert(0, 'backend')

from dotenv import load_dotenv
load_dotenv('backend/.env')

async def check():
    from backend.app.db.connection import connect_db, get_db
    await connect_db()
    db = get_db()

    print('=== AADHAAR DB ===')
    docs = await db.aadhaar_db.find({}).to_list(20)
    for d in docs:
        print(f"  Aadhaar: {d.get('aadhaar')}, Name: {d.get('name')}, DOB: {d.get('dob')}, State: {d.get('state')}")

    print('\n=== PAN DB ===')
    docs = await db.pan_db.find({}).to_list(20)
    for d in docs:
        print(f"  PAN: {d.get('pan')}, Name: {d.get('name')}, DOB: {d.get('dob')}, Active: {d.get('pan_active')}, ITR: {d.get('itr_filed')}")

    print('\n=== BANK ACCOUNTS DB ===')
    docs = await db.bank_accounts_db.find({}).to_list(20)
    for d in docs:
        print(f"  Account: {d.get('account_number')}, IFSC: {d.get('ifsc')}, Holder: {d.get('account_holder')}, Active: {d.get('account_active')}")

    print('\n=== IFSC DB (sample) ===')
    docs = await db.ifsc_db.find({}).to_list(5)
    for d in docs:
        print(f"  IFSC: {d.get('ifsc')}, Bank: {d.get('bank_name')}, Branch: {d.get('branch_name')}")

    print('\n=== OTP STORE ===')
    docs = await db.otp_store.find({}).to_list(20)
    for d in docs:
        print(f"  Key: {d.get('key')}, OTP: {d.get('otp')}, Expires: {d.get('expires_at')}")

asyncio.run(check())
