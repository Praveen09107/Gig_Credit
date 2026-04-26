import asyncio

from app.db.connection import close_db, connect_db, get_db


DEMO_AADHAAR = {
    "aadhaar": "765432101234",
    "name": "Praveen Kumar",
    "dob": "2006-11-16",
    "state": "Tamil Nadu",
    "status": "active",
}

DEMO_NAME = DEMO_AADHAAR["name"]

DEMO_PAN = {
    "pan": "ABCDE1234F",
    "name": DEMO_NAME,
    "dob": "2006-11-16",
    "pan_active": True,
    "itr_filed": True,
    "itr_years": [2022, 2023, 2024],
}


async def seed() -> None:
    connect_db()
    db = get_db()

    await db.aadhaar_db.update_one({"aadhaar": DEMO_AADHAAR["aadhaar"]}, {"$set": DEMO_AADHAAR}, upsert=True)
    await db.pan_db.update_one({"pan": DEMO_PAN["pan"]}, {"$set": DEMO_PAN}, upsert=True)

    await db.ifsc_db.update_one(
        {"ifsc": "HDFC0001234"},
        {
            "$set": {
                "ifsc": "HDFC0001234",
                "bank_name": "HDFC Bank",
                "branch_name": "Chennai Main",
                "city": "Chennai",
                "state": "Tamil Nadu",
            }
        },
        upsert=True,
    )

    await db.bank_accounts_db.update_one(
        {"account_number": "1234567890", "ifsc": "HDFC0001234"},
        {
            "$set": {
                "account_number": "1234567890",
                "ifsc": "HDFC0001234",
                "account_holder": DEMO_NAME,
                "account_type": "Savings",
                "account_active": True,
            }
        },
        upsert=True,
    )

    await db.loan_accounts_db.update_one(
        {"account_number": "1234567890"},
        {
            "$set": {
                "has_active_loans": True,
                "loans": [
                    {"type": "Personal Loan", "emi_amount": 3500, "remaining_months": 18},
                    {"type": "Bike Loan", "emi_amount": 1800, "remaining_months": 6},
                ],
            }
        },
        upsert=True,
    )

    await db.vehicle_rc_db.update_one(
        {"vehicle_number": "TN09AB1234"},
        {
            "$set": {
                "vehicle_number": "TN09AB1234",
                "owner_name": DEMO_NAME,
                "vehicle_class": "Motorcycle",
                "chassis_number": "CHASSIS123",
                "engine_number": "ENGINE123",
                "registration_date": "2021-01-12",
                "rc_expiry": "2036-01-11",
                "fitness_expiry": "2031-01-11",
            }
        },
        upsert=True,
    )

    await db.eshram_db.update_one(
        {"uan": "UAN123456789012"},
        {
            "$set": {
                "uan": "UAN123456789012",
                "name": DEMO_NAME,
                "worker_category": "Gig Worker",
                "registration_date": "2023-08-11",
            }
        },
        upsert=True,
    )

    await db.pmsym_db.update_one(
        {"uan": "UAN123456789012"},
        {
            "$set": {
                "uan": "UAN123456789012",
                "months_contributed": 14,
                "last_contribution_date": "2026-02-15",
            }
        },
        upsert=True,
    )

    await db.insurance_db.update_one(
        {"policy_number": "HLT2024112345", "policy_type": "health"},
        {
            "$set": {
                "policy_number": "HLT2024112345",
                "policy_type": "health",
                "policy_holder": DEMO_NAME,
                "insurer": "Star Health Insurance",
                "sum_insured": 500000,
                "premium_annual": 8500,
                "policy_start": "2024-01-01",
                "policy_expiry": "2027-01-01",
            }
        },
        upsert=True,
    )

    await db.insurance_db.update_one(
        {"policy_number": "VEH20242222", "policy_type": "vehicle"},
        {
            "$set": {
                "policy_number": "VEH20242222",
                "policy_type": "vehicle",
                "policy_holder": DEMO_NAME,
                "insurer": "Bajaj Allianz",
                "vehicle_number": "TN09AB1234",
                "policy_expiry": "2027-06-30",
            }
        },
        upsert=True,
    )

    await db.itr_db.update_one(
        {"pan": "ABCDE1234F", "assessment_year": "2024-25"},
        {
            "$set": {
                "pan": "ABCDE1234F",
                "assessment_year": "2024-25",
                "itr_form": "ITR-4",
                "gross_income": 360000,
                "tax_paid": 0,
                "filing_date": "2025-07-22",
            }
        },
        upsert=True,
    )

    print("Seed data upsert complete")
    close_db()


if __name__ == "__main__":
    asyncio.run(seed())
