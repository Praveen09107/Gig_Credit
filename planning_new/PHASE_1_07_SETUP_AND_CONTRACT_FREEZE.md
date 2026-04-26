# ================================================================================
# GIGCREDIT — PHASE 1: SETUP & CONTRACT FREEZE
# Document 07 | Hours 0–4 | planning_new
# ================================================================================

## PHASE OBJECTIVE
Both devs independently set up their environments and agree on all data contracts.
By Hour 4, both sides can run locally, mocks are functional, and git is verified.

---

## DEV A TASKS (Hours 0–4)

### A1.1 — Python Environment Setup (30 min)
```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # or venv\Scripts\activate on Windows

# Install dependencies
pip install fastapi uvicorn pymongo motor python-dotenv pydantic
pip install httpx groq python-jose passlib
pip install pytest httpx  # for testing
pip freeze > backend/requirements.txt
```

### A1.2 — FastAPI Project Skeleton (30 min)

Create `backend/app/main.py`:
```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="GigCredit API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health():
    return {"status": "ok", "service": "gigcredit-api", "version": "1.0.0"}
```

Create `backend/app/config.py`:
```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    MONGODB_URI: str = "mongodb://localhost:27017"
    DB_NAME: str = "gigcredit"
    GROQ_API_KEY: str = ""
    HMAC_SECRET: str = "demo-secret-key"
    SERVER_API_KEY: str = "demo-api-key"
    
    class Config:
        env_file = ".env"
```

### A1.3 — MongoDB Connection + Collections (30 min)

Create `backend/app/db/connection.py`:
```python
from motor.motor_asyncio import AsyncIOMotorClient
from app.config import Settings

settings = Settings()
client = AsyncIOMotorClient(settings.MONGODB_URI)
db = client[settings.DB_NAME]

# Collection references
otp_db = db["otp"]
aadhaar_db = db["aadhaar"]
pan_db = db["pan"]
ifsc_db = db["ifsc"]
bank_accounts_db = db["bank_accounts"]
loan_accounts_db = db["loan_accounts"]
vehicle_rc_db = db["vehicle_rc"]
eshram_db = db["eshram"]
pmsym_db = db["pmsym"]
insurance_db = db["insurance"]
itr_db = db["itr"]
report_logs = db["report_logs"]
```

### A1.4 — Pydantic Schemas (30 min)

Create `backend/app/models/verification_schemas.py`:
- Define request/response models for ALL 13 endpoints
- Must match `contracts/api_contract.json` EXACTLY

### A1.5 — Write contracts/*.json (30 min)

Create the following files based on Document 05:
- `contracts/api_contract.json`
- `contracts/feature_vector_contract.json`
- `contracts/verified_profile_contract.json`
- `contracts/score_output_contract.json`
- `contracts/report_payload_contract.json`

### A1.6 — Git Setup (30 min)
```bash
git init
git add .
git commit -m "chore: initial project structure"
git remote add origin <github-url>
git push -u origin main
git checkout -b develop
git push -u origin develop
git checkout -b dev-a/backend
git push -u origin dev-a/backend
```

**DELIVERABLES by Hour 4:**
- [ ] `backend/app/main.py` runs with `/health` endpoint
- [ ] MongoDB connection working
- [ ] All Pydantic schemas written
- [ ] `contracts/*.json` files committed
- [ ] Git branches created and pushed

---

## DEV B TASKS (Hours 0–4)

### B1.1 — Flutter Project Setup (30 min)
```bash
flutter create --org com.gigcredit app
cd app
flutter pub add flutter_riverpod
flutter pub add go_router
flutter pub add google_fonts
flutter pub add hive hive_flutter
flutter pub add image_picker
flutter pub add file_picker
flutter pub add http
flutter pub add crypto
flutter pub add pdf
flutter pub add flutter_animate
```

### B1.2 — Design System (60 min)

Create `app/lib/core/theme/app_colors.dart`:
```dart
class AppColors {
  // Primary palette — Deep Navy + Electric Blue
  static const primary = Color(0xFF1A1A2E);
  static const primaryLight = Color(0xFF16213E);
  static const accent = Color(0xFF0F3460);
  static const highlight = Color(0xFFE94560);
  
  // Score colors
  static const scoreExceptional = Color(0xFF00C853);
  static const scoreExcellent = Color(0xFF2E7D32);
  static const scoreGood = Color(0xFF43A047);
  static const scoreAverage = Color(0xFFFFA726);
  static const scoreBelowAverage = Color(0xFFFF7043);
  static const scorePoor = Color(0xFFE53935);
  
  // Surfaces
  static const surface = Color(0xFF0A0A1A);
  static const card = Color(0xFF1E1E3A);
  static const cardLight = Color(0xFF2A2A4A);
  
  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0B0C8);
  static const textMuted = Color(0xFF6B6B8D);
  
  // Status
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFC107);
  static const error = Color(0xFFF44336);
  static const verified = Color(0xFF00E676);
}
```

Create `app/lib/core/theme/app_theme.dart`:
```dart
ThemeData gigCreditTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.surface,
    colorScheme: ColorScheme.dark(
      primary: AppColors.highlight,
      secondary: AppColors.accent,
      surface: AppColors.card,
    ),
    fontFamily: GoogleFonts.inter().fontFamily,
    // ... complete theme setup
  );
}
```

### B1.3 — Navigation Shell (30 min)

Create `app/lib/app.dart` with GoRouter:
```dart
final router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (_, __) => LoginScreen()),
    GoRoute(path: '/dashboard', builder: (_, __) => DashboardScreen()),
    GoRoute(path: '/guidelines', builder: (_, __) => GuidelinesScreen()),
    GoRoute(path: '/step/:stepNumber', builder: (_, state) {
      final step = int.parse(state.pathParameters['stepNumber']!);
      return StepScreen(stepNumber: step);
    }),
    GoRoute(path: '/processing', builder: (_, __) => ProcessingScreen()),
    GoRoute(path: '/score', builder: (_, __) => ScoreResultScreen()),
    GoRoute(path: '/report', builder: (_, __) => ReportScreen()),
    GoRoute(path: '/loans', builder: (_, __) => LoanMarketplaceScreen()),
  ],
);
```

### B1.4 — MockApiClient (30 min)

Create `app/lib/core/api/mock_api_client.dart`:
```dart
class MockApiClient implements ApiClient {
  @override
  Future<Map<String, dynamic>> sendOtp(String mobile) async {
    await Future.delayed(Duration(milliseconds: 500));
    return {"status": "sent", "expires_in_seconds": 300, "otp": "123456"};
  }
  
  @override
  Future<Map<String, dynamic>> verifyOtp(String mobile, String otp) async {
    await Future.delayed(Duration(milliseconds: 300));
    return {"status": "verified", "mobile_verified": true};
  }
  
  @override
  Future<Map<String, dynamic>> verifyAadhaar(String aadhaar) async {
    await Future.delayed(Duration(seconds: 1));
    return {
      "status": "valid",
      "name": "Ravi Kumar",
      "dob": "1997-06-12",
      "state": "Tamil Nadu"
    };
  }
  // ... all other endpoints with static responses
}
```

### B1.5 — MockOcrService (15 min)

Create `app/lib/core/ocr/mock_ocr_service.dart`:
```dart
class MockOcrService implements OcrService {
  @override
  Future<OcrResult> process(String filePath, String docType) async {
    await Future.delayed(Duration(seconds: 2)); // simulate processing
    switch (docType) {
      case 'AADHAAR_FRONT':
        return OcrResult(
          text: "GOVERNMENT OF INDIA AADHAAR...",
          fields: {"name": "Ravi Kumar", "dob": "12/06/1997", "aadhaar": "1234 5678 9012"},
          confidence: 0.94,
        );
      // ... other document types
    }
  }
}
```

### B1.6 — Git Setup (15 min)
```bash
git checkout develop
git pull origin develop
git checkout -b dev-b/ui
# Commit Flutter project
git add .
git commit -m "feat(ui): initialize Flutter project with design system and routing"
git push -u origin dev-b/ui
```

**DELIVERABLES by Hour 4:**
- [ ] Flutter app runs with login → dashboard → step navigation
- [ ] Dark theme with premium colors applied
- [ ] MockApiClient returns static responses for all endpoints
- [ ] MockOcrService returns static parsed data
- [ ] Git branch `dev-b/ui` created and pushed

---

## GATE G0 CHECKPOINT (Hour 4)

Both devs stop and verify:
```
□ contracts/*.json files reviewed and agreed
□ Backend /health endpoint responds
□ Flutter app navigates through all screens
□ Both devs have pushed to their branches
□ develop branch has initial project structure
□ Both devs can pull each other's code without errors
```
