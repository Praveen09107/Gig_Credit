import asyncio
from app.db.connection import get_db, connect_db, close_db

async def check():
    connect_db()
    db = get_db()
    
    docs = await db.score_history.find({"user_id": "USR_9876543210"}).to_list(1)
    if docs:
        print(docs[0])
    
    close_db()

if __name__ == "__main__":
    asyncio.run(check())
