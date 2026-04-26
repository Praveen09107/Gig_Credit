# TeamUnicorns - GigCredit

**Privacy-First Credit Scoring for India's Gig Workers**

## What is GigCredit?

GigCredit is an alternative credit scoring platform that enables gig workers, delivery partners, freelancers, and financially underserved users to generate a credit score using real financial behavior — entirely on-device, privacy-first.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart) + Riverpod |
| Backend | FastAPI (Python) + MongoDB |
| ML | XGBoost + m2cgen (pure Dart export) |
| AI | Groq LLaMA 3 70B (report explanation) |
| Deploy | Render (backend) + Android APK |

## Project Structure

```
gig_credit/
├── app/            → Flutter application (Dev B)
├── backend/        → FastAPI server (Dev A)
├── ml_pipeline/    → ML training + export (Dev A)
├── contracts/      → Frozen API/data schemas (shared)
├── demo_data/      → Demo inputs + expected outputs (shared)
├── scripts/        → Utility scripts (shared)
└── planning_new/   → 35 planning documents
```

## Quick Start

**Dev A (Backend):**
```bash
cd backend
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

**Dev B (Flutter):**
```bash
cd app
flutter pub get
flutter run
```

## Integration Gates

| Gate | Hour | Checkpoint |
|------|------|-----------|
| G0 | 4 | Contracts frozen, mocks working |
| G1 | 16 | App calls backend |
| G2 | 24 | All APIs + all screens |
| G3 | 36 | Scoring + report working |
| G4 | 48 | Demo-ready |

## Team

- **Dev A**: Backend + ML Pipeline + AI Report
- **Dev B**: Flutter UI + Scoring Integration + On-Device
