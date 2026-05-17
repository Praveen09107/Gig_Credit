import asyncio
from app.db.connection import get_db, connect_db, close_db

async def check():
    connect_db()
    db = get_db()
    
    # Check distinct user_ids in score_history
    user_ids = await db.score_history.distinct("user_id")
    print("Distinct user_ids in score_history:", user_ids)
    
    close_db()

if __name__ == "__main__":
    asyncio.run(check())
