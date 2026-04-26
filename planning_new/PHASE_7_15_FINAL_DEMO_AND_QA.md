# ================================================================================
# GIGCREDIT — PHASE 7: FINAL DEMO ASSEMBLY & QA
# Document 15 | Hours 42–48 | planning_new
# ================================================================================

## PHASE OBJECTIVE
Final testing, demo rehearsal, release APK build, and preparation for judges.
Gate G4 checkpoint covers the entire final phase.

---

## BOTH DEVS — JOINT TASKS (Hours 42–48)

### 7.1 — Full Demo Rehearsal (2 hours)

Run the complete demo flow 3 times:

**Run 1: Happy Path (30 min)**
1. Fresh install on device
2. Login with demo mobile → OTP → Dashboard
3. Step 1: Enter all profile fields → Continue
4. Step 2: Upload demo Aadhaar + PAN + selfie → Verified
5. Step 3: Upload demo bank statement → Parsed + Verified
6. Steps 4-9: Upload all demo documents → All verified
7. Processing screen → Score reveal → Report → PDF → Loans
8. **Pass/Fail**: Everything works without errors?

**Run 2: Edge Case Testing (30 min)**
1. What happens if internet drops during verification?
2. What happens if OTP is entered wrong?
3. What happens if user presses back during processing?
4. What happens if Groq API is slow?
5. What happens if user skips optional steps?
6. **Fix**: Any issues found → fix immediately

**Run 3: Final Polish Run (30 min)**
1. Time the demo (target: < 5 minutes for judges)
2. Check all animations are smooth
3. Check all text is readable (no overflow, no truncation)
4. Check score looks reasonable (between 600-750 for demo)
5. Check PDF looks professional
6. **Sign-off**: Both devs agree the demo is ready

### 7.2 — Bug Fix Sprint (2 hours)

Fix any issues found during rehearsal:
- UI overflow on specific screens
- API timeout not handled gracefully
- Animation jank
- Wrong text/labels
- Color contrast issues
- Navigation bugs

**Priority**: CRITICAL bugs only. Do NOT add new features.

### 7.3 — Build Release APK (1 hour)

```bash
cd app

# Clean build
flutter clean
flutter pub get

# Build release APK
flutter build apk --release --split-per-abi

# Verify APK
ls -la build/app/outputs/flutter-apk/
# Should see: app-arm64-v8a-release.apk (~30-50MB)
```

Install on test device:
```bash
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

Run full demo on release APK (not debug). Check:
- Performance (no jank in release mode)
- All assets loaded (models, configs, fonts)
- API calls work from release build
- No debug banners/logs visible

### 7.4 — Prepare Demo Script (30 min)

Write a script for the demo presentation:

```
DEMO SCRIPT — GIGCREDIT

SLIDE 1 (30 sec): "The Problem"
- 300M+ gig workers in India
- No CIBIL score, no salary slips
- Denied credit by banks
- Need alternative credit assessment

SLIDE 2 (30 sec): "Our Solution"
- GigCredit: Privacy-first, on-device credit scoring
- Converts real financial behavior into a credit score
- All processing on device — no data leaves the phone
- Connects verified workers to lending partners

LIVE DEMO (4 min):
- [Presenter opens app]
- "Let me show you how a delivery partner can get a credit score in 15 minutes"
- [Walk through the 9 steps with demo inputs]
- "The app processes 95 financial data points entirely on the user's device"
- [Show processing animation]
- "Here's the credit score — 682, Grade B"
- [Show pillar breakdown]
- "The AI explains in simple language what boosted and what hurt the score"
- [Show LLM explanation in Tamil]
- "Now the user can apply for loans right inside the app"
- [Show loan marketplace]
- [Show PDF export]

CLOSING (30 sec):
- Privacy-first: raw data deleted after scoring
- Tech: Flutter + FastAPI + XGBoost + LLM
- Business model: Free for workers, commission from lenders
```

### 7.5 — Final Code Merge (30 min)

```bash
# Both devs merge to develop
git checkout develop
git pull origin develop
git merge dev-a/backend
git merge dev-b/ui
git push origin develop

# Final merge to main
git checkout main
git merge develop
git push origin main
git tag -a v1.0-release -m "GigCredit Hackathon Release"
git push origin --tags
```

### 7.6 — Backup Plan (15 min)

Prepare for demo day failures:
1. **Backend down**: Switch to MockApiClient (pre-built)
2. **Groq API down**: Fallback template text already implemented
3. **APK won't install**: Have debug APK ready as backup
4. **Internet slow**: Pre-cache all API responses
5. **Wrong score**: Demo fallback score (682, B) kicks in

---

## GATE G4 FINAL CHECKLIST

```
FUNCTIONALITY:
□ App installs and launches on Android device
□ Login → OTP → Dashboard works
□ All 9 steps navigate correctly
□ Document upload works (camera + gallery)
□ OCR extracts data (real or demo)
□ Verification APIs return valid responses
□ Score computing produces 300-900 range
□ 7 pillar scores displayed in report
□ SHAP factors shown correctly
□ LLM explanation in user's language
□ PDF export generates readable document
□ Loan marketplace shows offers
□ In-app loan application form works

UI/UX:
□ Dark theme looks premium
□ All animations are smooth
□ No text overflow anywhere
□ Loading states show progress
□ Error states show user-friendly messages
□ App icon and splash screen present
□ No debug banners in release build

BACKEND:
□ Render deployment is stable
□ All API endpoints respond < 2 seconds
□ MongoDB has demo data seeded
□ Groq API integration works (or fallback active)

DEMO:
□ Full demo rehearsed 3+ times
□ Demo completes in < 5 minutes
□ Demo script prepared
□ Backup plan in place
□ Release APK built and tested
□ Presentation slides ready (if needed)
□ Team is confident and prepared
```

---

## POST-HACKATHON NOTES

If you WIN or advance to the next round, here are the improvements to make:

1. **Real PaddleOCR**: Implement native Android bridge for on-device OCR
2. **Real Face Verification**: Integrate MobileFaceNet TFLite
3. **Real Document Authenticity**: Integrate EfficientNet-Lite0
4. **More Bank Parsers**: Support 10+ Indian banks
5. **Real OTP**: Integrate SMS gateway (Twilio, etc.)
6. **Real NBFC Partners**: Integrate with lending APIs
7. **Proper Security**: Production HMAC, certificate pinning, root detection
8. **CI/CD**: GitHub Actions for automated testing and deployment
9. **Monitoring**: Sentry for crash reporting, Grafana for metrics
10. **Scalability**: Load testing, horizontal scaling, CDN
