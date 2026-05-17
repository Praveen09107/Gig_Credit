import asyncio
from app.db.connection import get_db, connect_db, close_db

async def check():
    connect_db()
    db = get_db()
    docs = await db.score_history.find().to_list(3)
    if docs:
        for doc in docs:
            print("user_id:", doc.get("user_id"), "finalScore:", doc.get("finalScore"))
    else:
        print("none")
    close_db()

if __name__ == "__main__":
    asyncio.run(check())
