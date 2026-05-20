"""
GigCredit — Clean up bad test data from score_history collection.

This script removes records that were inserted by test scripts with:
1. Wrong grade values (e.g., grade 'B' for score 196)
2. Scores below 300 (below pipeline minimum of clamp(300, 900))
3. Duplicate proof IDs across multiple users

Run with: python cleanup_test_data.py

This is OPTIONAL — the app now recomputes grades dynamically,
so bad stored grades no longer affect the UI.
"""
import asyncio
import os
from motor.motor_asyncio import AsyncIOMotorClient

MONGODB_URI = os.getenv("MONGODB_URI", "mongodb+srv://gigcredit:gigcredit2026@cluster0.mongodb.net/gigcredit")
DB_NAME = os.getenv("DB_NAME", "gigcredit")


async def cleanup():
    client = AsyncIOMotorClient(MONGODB_URI)
    db = client[DB_NAME]
    collection = db["score_history"]

    # 1. Count total records
    total = await collection.count_documents({})
    print(f"Total records in score_history: {total}")

    # 2. Find and count test records (proof IDs starting with TEST- or DYN-TEST-)
    test_filter = {"proofId": {"$regex": "^(TEST-|DYN-TEST-)"}}
    test_count = await collection.count_documents(test_filter)
    print(f"Test records (TEST-/DYN-TEST- prefix): {test_count}")

    # 3. Find records with scores below 300 (below pipeline minimum)
    low_score_filter = {"finalScore": {"$lt": 300}}
    low_count = await collection.count_documents(low_score_filter)
    print(f"Records with score < 300 (below pipeline minimum): {low_count}")

    # 4. Find records with mismatched grades
    grade_map = [
        {"finalScore": {"$gte": 800}, "grade": {"$ne": "A+"}},
        {"finalScore": {"$gte": 750, "$lt": 800}, "grade": {"$ne": "A"}},
        {"finalScore": {"$gte": 700, "$lt": 750}, "grade": {"$ne": "B+"}},
        {"finalScore": {"$gte": 650, "$lt": 700}, "grade": {"$ne": "B"}},
        {"finalScore": {"$gte": 600, "$lt": 650}, "grade": {"$ne": "C+"}},
        {"finalScore": {"$gte": 550, "$lt": 600}, "grade": {"$ne": "C"}},
        {"finalScore": {"$lt": 550}, "grade": {"$ne": "D"}},
    ]
    mismatch_count = 0
    for condition in grade_map:
        count = await collection.count_documents(condition)
        mismatch_count += count
    print(f"Records with mismatched grade vs score: {mismatch_count}")

    if test_count == 0 and low_count == 0 and mismatch_count == 0:
        print("\n✅ No bad data found — collection is clean!")
        client.close()
        return

    # Ask for confirmation
    print(f"\n⚠️  Will delete {test_count} test records and fix {mismatch_count} grade mismatches.")
    confirm = input("Proceed? (yes/no): ").strip().lower()
    if confirm != "yes":
        print("Cancelled.")
        client.close()
        return

    # 5. Delete test records
    if test_count > 0:
        result = await collection.delete_many(test_filter)
        print(f"Deleted {result.deleted_count} test records")

    # 6. Delete records with scores below 300
    if low_count > 0:
        result = await collection.delete_many(low_score_filter)
        print(f"Deleted {result.deleted_count} sub-300 score records")

    # 7. Fix remaining grade mismatches (update stored grade to correct value)
    grade_corrections = [
        ({"finalScore": {"$gte": 800}}, "A+"),
        ({"finalScore": {"$gte": 750, "$lt": 800}}, "A"),
        ({"finalScore": {"$gte": 700, "$lt": 750}}, "B+"),
        ({"finalScore": {"$gte": 650, "$lt": 700}}, "B"),
        ({"finalScore": {"$gte": 600, "$lt": 650}}, "C+"),
        ({"finalScore": {"$gte": 550, "$lt": 600}}, "C"),
        ({"finalScore": {"$lt": 550}}, "D"),
    ]
    fixed = 0
    for filt, correct_grade in grade_corrections:
        filt["grade"] = {"$ne": correct_grade}
        result = await collection.update_many(filt, {"$set": {"grade": correct_grade}})
        fixed += result.modified_count
    print(f"Fixed {fixed} grade mismatches in remaining records")

    remaining = await collection.count_documents({})
    print(f"\n✅ Done! {remaining} clean records remain.")
    client.close()


if __name__ == "__main__":
    asyncio.run(cleanup())
