import asyncio
from app.db.connection import get_db, connect_db, close_db
from datetime import datetime, timezone

async def migrate_all():
    connect_db()
    db = get_db()
    
    # 1. Get ALL users
    users = await db.users.find().to_list(10000)
    user_ids = [f"USR_{u.get('mobile')}" for u in users if u.get('mobile')]
    
    print(f"Found {len(user_ids)} total real users in users collection.")
    
    # 2. Get the test reports
    test_reports = await db.score_history.find({"user_id": "test_user_id"}).to_list(100)
    
    # 3. Give it to ALL users who don't have it
    for uid in user_ids:
        existing = await db.score_history.count_documents({"user_id": uid})
        if existing == 0:
            print(f"Giving reports to {uid}")
            for report in test_reports:
                new_report = report.copy()
                if "_id" in new_report:
                    del new_report["_id"] # generate new ObjectId
                new_report["user_id"] = uid
                new_report["stored_at"] = datetime.now(timezone.utc).isoformat()
                await db.score_history.insert_one(new_report)

    close_db()

if __name__ == "__main__":
    asyncio.run(migrate_all())
