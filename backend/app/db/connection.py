from motor.motor_asyncio import AsyncIOMotorClient

from app.config import settings

client = None
db = None


import certifi

def connect_db() -> None:
    global client, db
    client = AsyncIOMotorClient(settings.MONGODB_URI, tlsCAFile=certifi.where())
    db = client[settings.DB_NAME]


def close_db() -> None:
    global client
    if client:
        client.close()


def get_db():
    return db
