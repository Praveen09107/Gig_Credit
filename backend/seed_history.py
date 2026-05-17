import asyncio
from app.db.connection import get_db, connect_db, close_db
from datetime import datetime, timezone

async def migrate():
    connect_db()
    db = get_db()
    
    # 1. Get all actual users from users collection
    users = await db.users.find().to_list(100)
    user_ids = [f"USR_{u.get('mobile')}" for u in users if u.get('mobile')]
    
    print(f"Found {len(user_ids)} real users: {user_ids}")
    
    # 2. Get the test reports
    test_reports = await db.score_history.find({"user_id": "test_user_id"}).to_list(100)
    print(f"Found {len(test_reports)} test reports to duplicate.")
    
    # 3. For each real user, check if they have reports. If not, give them the test reports.
    for uid in user_ids:
        existing = await db.score_history.count_documents({"user_id": uid})
        if existing == 0:
            print(f"Giving {len(test_reports)} reports to {uid}")
            for report in test_reports:
                new_report = report.copy()
                if "_id" in new_report:
                    del new_report["_id"] # generate new ObjectId
                new_report["user_id"] = uid
                new_report["stored_at"] = datetime.now(timezone.utc).isoformat()
                await db.score_history.insert_one(new_report)
        else:
            print(f"User {uid} already has {existing} reports.")

    close_db()

if __name__ == "__main__":
    asyncio.run(migrate())
