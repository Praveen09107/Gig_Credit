import asyncio
import os
from app.db.connection import get_db, connect_db, close_db

async def check():
    connect_db()
    db = get_db()
    if db is None:
        print("DB connection failed")
        return
        
    history = await db.score_history.find().to_list(10)
    print('History count:', len(history))
    if history:
        for h in history[:3]:
            print(f"- History item: user={h.get('user_id')}, score={h.get('score_data', {}).get('finalScore')}")
            
    loans = await db.loan_applications.find().to_list(10)
    print('Loans count:', len(loans))
    if loans:
        for l in loans[:3]:
            print(f"- Loan item: id={l.get('_id')}")
            
    close_db()

if __name__ == "__main__":
    asyncio.run(check())
