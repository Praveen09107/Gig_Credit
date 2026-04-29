from pymongo import MongoClient
import certifi

# Connect to the MongoDB Atlas cluster
client = MongoClient("mongodb+srv://hackathonproject789_db_user:praveen@cluster0.c4lcly9.mongodb.net/?appName=Cluster0", tlsCAFile=certifi.where())
db = client["gigcredit"]

# Seed IFSC
ifsc_collection = db["ifsc_db"]
ifsc_collection.update_one(
    {"ifsc": "HDFC0001234"},
    {"$set": {
        "ifsc": "HDFC0001234",
        "bank_name": "HDFC Bank",
        "branch_name": "Tech Park Branch",
        "city": "Bangalore",
        "state": "Karnataka"
    }},
    upsert=True
)

# Seed Account
account_collection = db["bank_accounts_db"]
account_collection.update_one(
    {"account_number": "098765432123", "ifsc": "HDFC0001234"},
    {"$set": {
        "account_number": "098765432123",
        "ifsc": "HDFC0001234",
        "account_holder": "Praveen",
        "account_type": "Savings",
        "account_active": True
    }},
    upsert=True
)

print("Database successfully seeded for testing!")
