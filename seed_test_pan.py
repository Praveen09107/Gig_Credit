"""Seed Praveen S's PAN into pan_db for cross-validation testing"""
from pymongo import MongoClient

c = MongoClient('mongodb+srv://hackathonproject789_db_user:praveen@cluster0.c4lcly9.mongodb.net/?appName=Cluster0')
db = c['gigcredit']

# Seed Praveen S's PAN (used in fraud-prevention testing)
result = db['pan_db'].update_one(
    {'pan': 'IQHPP7233R'},
    {'$set': {
        'pan': 'IQHPP7233R',
        'name': 'Praveen S',
        'dob': '16/11/2006',
        'fathers_name': 'Srinivasan',
        'pan_active': True,
        'itr_filed': False,
        'itr_years': []
    }},
    upsert=True
)
print('Praveen S PAN seeded:', result.upserted_id or 'updated existing')

# Verify all PANs in DB
print('\nAll PAN records:')
for p in db['pan_db'].find({}, {'pan': 1, 'name': 1, 'dob': 1}):
    print(f"  {p['pan']} | {p.get('name')} | {p.get('dob')}")
