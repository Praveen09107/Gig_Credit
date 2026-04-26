# GigCredit – Full Flutter On-Device Technical Specification

## 1. Scope
This document defines ONLY the on-device technical architecture for the Flutter Android application. It excludes backend business logic except optional verification APIs.

## 2. Target Platform
- Flutter (Dart) UI + orchestration
- Android primary target
- Kotlin platform channels for native security / ML integrations
- Android 10+
- Mid-range devices: 6GB RAM preferred

---

## 3. Core On-Device Engines
1. Security Engine
2. Asset Loader Engine
3. OCR Engine
4. Parser Engine
5. Validation Engine
6. Trusted State Engine
7. Transaction Ledger Engine
8. Feature Engineering Engine
9. Scoring Engine
10. Explainability Engine
11. Cleanup Engine

---

## 4. Flutter Project Structure
```text
lib/
 app.dart
 main.dart
 core/
   security/
   storage/
   assets/
   ocr/
   parser/
   validation/
   ledger/
   features/
   scoring/
   explainability/
   cleanup/
 features/
   onboarding/
   dashboard/
   reports/
 platform/
   android_native/
```

---

## 5. Startup Runtime Flow
```text
main()
↓
WidgetsFlutterBinding.ensureInitialized()
↓
SecurityBootstrap.init()
↓
KeystoreService.init()
↓
EncryptedDbService.open()
↓
AssetRegistry.scan()
↓
SessionManager.restore()
↓
RunApp()
```

### Startup Checks
- Root detection (native)
- Debugger detection
- APK signature verification
- Device storage available
- RAM threshold check

---

## 6. Security Layer Technical Design
### 6.1 Code Protection
- Flutter obfuscation build flag
- Android R8 enabled
- Remove logs in release mode
- Split sensitive logic into native code if required

### 6.2 Key Management
Use Android Keystore alias:
`gigcredit_master_key`

Flow:
1. Generate AES-256 key first run
2. Store in Keystore
3. Use key to unwrap local data keys

### 6.3 Storage Encryption
- SQLCipher / encrypted sqlite DB
- Secure storage for tiny secrets
- Private cache directories only

---

## 7. Encrypted Asset System
Bundled assets:
```text
assets/models/
 score_p1.enc
 score_p2.enc
 score_meta.enc
assets/ocr/
 det.enc
 rec.enc
assets/config/
 shap.enc
 rules.enc
```

### Runtime Load Flow
```text
Read encrypted bytes
↓
Get key from Keystore
↓
Decrypt in memory
↓
Pass bytes to runtime engine
↓
Dispose plaintext buffer after load
```

---

## 8. State Management (Flutter)
Recommended: Riverpod / Bloc

State Domains:
- authState
- onboardingState
- trustedProfileState
- documentProcessingState
- scoreState
- reportState

Global trusted profile stored in DB, mirrored in memory provider.

---

## 9. Input Intake Flow
Supported Inputs:
- Camera image
- Gallery image
- PDF picker
- Screenshot
- Manual forms

Flow:
```text
User selects file
↓
Copy to app cache/temp UUID path
↓
Detect mime type
↓
Route to processor
```

Temp path:
```text
/cache/uploads/{uuid}/
```

---

## 10. OCR Engine (Flutter Integration)
### Engine
PaddleOCR Lite via native Android bridge or embedded SDK.

### Dart Service
`OcrService.process(filePath)`

### Native Flow
1. Resize image
2. Orientation correction
3. Text detect
4. Text recognize
5. Return JSON to Dart

Output:
```json
{
  "text":"...",
  "blocks":[],
  "confidence":0.94
}
```

Use isolate for background processing.

---

## 11. PDF Processing
### If digital PDF
Use native parser extract text.

### If scanned PDF
Render pages -> images -> OCR queue.

Flow:
```text
PDF -> pages -> OCR page queue -> merged text
```

---

## 12. Parser Engine
Dart parser services:
- AadhaarParser
n- PanParser
- StatementParser
- BillParser

Outputs structured maps.

Example:
```json
{
 "name":"Praveen",
 "dob":"16/11/2006"
}
```

Use regex + heuristics + templates.

---

## 13. Validation Engine
### APIs
`ValidationService.validate(stepData, trustedState)`

### Layers
1. Field validation
2. Cross-document matching
3. Cross-step matching
4. Confidence scoring

Outputs:
- pass
- warning
- fail
- reasons[]

---

## 14. Trusted State Engine
Encrypted SQLite tables:
- profile
- identities
n- transactions
- step_status
- scores

Canonical profile example:
```json
{
 "name":"Praveen",
 "dob":"16/11/2006",
 "panVerified":true
}
```

Update only after validation pass.

---

## 15. Transaction Ledger Engine
Statement parser writes normalized rows.

Schema:
- ts_epoch
- amount
- type
- counterparty
- ref_id
- category

Indexes:
- ts_epoch
- amount
- counterparty

Used for fast reconciliation.

---

## 16. Reconciliation Engine
Used in later steps.

Examples:
- EMI receipt vs recurring debit rows
- Utility payment vs same-date debit
- Income screenshot vs credit rows

Algorithm:
- amount score
- date proximity score
- merchant similarity score
- recurrence score

Return confidence %.

---

## 17. Feature Engineering Engine
Input sources:
- trusted profile
- transaction ledger
- validations
- parsed docs

Generate 95 normalized features.

Examples:
- avg_income_3m
- emi_ratio
- payment_consistency
- identity_confidence

Run in isolate.

---

## 18. Scoring Engine
### Runtime
TensorFlow Lite or compiled Dart logic.

### Sequence
```text
Load model bytes
↓
P1 infer
P2 infer
P3 infer
P4 infer
P5 infer
Rules infer
Meta combine
```

Output:
- FHI score 300–900
- risk band
- pillar scores

Unload interpreters after use.

---

## 19. Explainability Engine
Use local SHAP lookup tables.

Input:
- feature vector
- score outputs

Output:
- top positive factors
- top negative factors
- confidence level
- improvement hints

---

## 20. UI Flow
```text
Home
↓
Step forms
↓
Processing screen
↓
Validation result
↓
Continue next step
↓
Final score screen
↓
Detailed report screen
```

Use progress indicators for OCR/model tasks.

---

## 21. Performance Rules
- Heavy tasks in isolates/native threads
- Never block UI thread
- Load models lazily
- Reuse OCR interpreter session
- Resize huge images before OCR
- Process PDF pages sequentially

---

## 22. Memory Budget
Approx:
- OCR active: 300–700MB
- Scoring active: 100–300MB
- Idle: low

Unload unused engines between phases.

---

## 23. Cleanup Engine
Trigger after step success / final score.

Delete:
- temp uploads
- page renders
- OCR raw cache
- temporary CSV files

Clear:
- decrypted buffers
- isolate temp memory

Keep:
- encrypted trusted profile
- score summary

---

## 24. Connectivity Rules
Offline mode:
- onboarding works
- OCR works
- scoring works
- report works

Online optional:
- PAN verify
- bank verify
- narrative API

---

## 25. Build Commands
Release example:
```text
flutter build apk --release --obfuscate --split-debug-info=build/symbols
```

Android Gradle:
- minifyEnabled true
- shrinkResources true

---

## 26. Testing Matrix
Devices:
- 4GB RAM low tier
- 6GB RAM mid tier
- 8GB RAM high tier

Test:
- OCR latency
- PDF parse speed
- model accuracy parity
- temp cleanup
- rooted device behavior

---

## 27. Execution Summary
GigCredit on-device runtime is a modular Flutter app where secure assets are unlocked locally, documents are processed in private storage, trusted state is built incrementally, financial behavior features are generated, lightweight models compute FHI, explanations are generated locally, and temporary sensitive data is automatically removed.

