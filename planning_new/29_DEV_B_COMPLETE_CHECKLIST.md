# ================================================================================
# GIGCREDIT — DEV B COMPLETE TASK CHECKLIST
# Document 29 | planning_new
# ================================================================================

## HOUR-BY-HOUR TASK LIST FOR DEV B (Flutter + UI/UX + On-Device)

### Phase 1: Hours 0–4 (Setup & Mocks)
- [ ] Create Flutter project: flutter create --org com.gigcredit app
- [ ] Add all pub dependencies (riverpod, go_router, google_fonts, etc.)
- [ ] Create app_colors.dart with premium dark theme palette
- [ ] Create app_theme.dart with complete ThemeData
- [ ] Create app_typography.dart with text styles
- [ ] Create app.dart with GoRouter navigation (all routes)
- [ ] Create main.dart with ProviderScope and theme
- [ ] Create ApiClient interface (abstract class)
- [ ] Create MockApiClient with static responses for ALL endpoints
- [ ] Create OcrService interface
- [ ] Create MockOcrService with pre-extracted results
- [ ] Create StepProgressBar widget
- [ ] Create DocumentUploadCard widget
- [ ] Create VerificationBadge widget
- [ ] Create placeholder screens for all routes
- [ ] Verify: flutter run launches and navigates through all screens
- [ ] Push to dev-b/ui

### Phase 2: Hours 4–12 (All 9 Step Screens)
- [ ] Build LoginScreen (mobile + OTP flow)
- [ ] Build DashboardScreen (hero card + CTA)
- [ ] Build GuidelinesScreen (input requirements info)
- [ ] Build Step1BasicProfileScreen (12 mandatory + 1 optional fields)
- [ ] Build Step2IdentityKycScreen (Aadhaar + PAN + Selfie upload)
- [ ] Build Step3BankVerificationScreen (bank details + PDF upload)
- [ ] Build Step4UtilityBillsScreen (3×6 bill grid)
- [ ] Build Step5WorkProofScreen (dynamic by work type)
- [ ] Build Step6GovSchemesScreen (7 optional fields)
- [ ] Build Step7InsuranceScreen (health + vehicle + life sections)
- [ ] Build Step8TaxComplianceScreen (ITR + GST fields)
- [ ] Build Step9EmiLoansScreen (loan cards, up to 5)
- [ ] Implement step navigation (forward/back/skip optional)
- [ ] Connect MockApiClient to OTP flow
- [ ] Connect MockOcrService to document uploads
- [ ] Apply premium dark theme to all screens
- [ ] Push to dev-b/ui

### Phase 3: Hours 12–20 (Real Integration + OCR)
- [ ] Implement HmacSigner class in Dart
- [ ] Implement RealApiClient with HMAC signing
- [ ] Create switchable apiClientProvider (mock vs real)
- [ ] Test: app calls backend /health successfully
- [ ] Test: OTP flow works with real backend
- [ ] Test: Aadhaar verification works with real backend
- [ ] Implement DemoOcrService with pre-extracted results
- [ ] Implement BankStatementParser (real or demo)
- [ ] Connect step screens to real API calls
- [ ] Show verification badges after successful API calls
- [ ] Build VerifiedProfile object (accumulate data across steps)
- [ ] Push to dev-b/logic

### Phase 4: Hours 20–28 (Scoring Engine Integration)
- [ ] Receive m2cgen .dart files from Dev A
- [ ] Copy .dart files to app/lib/scoring/models/
- [ ] Copy .json configs to app/assets/config/
- [ ] Implement FeatureEngineer class (95 features)
- [ ] Implement ScoringEngine class (calls all 7 pillar scorers)
- [ ] Implement MetaLearner class (LR dot product + sigmoid)
- [ ] Implement ConfidenceEngine class
- [ ] Implement ShapLookup class
- [ ] Run parity test (golden inference)
- [ ] Build ProcessingScreen (animated progress)
- [ ] Build ScoreResultScreen (animated score reveal)
- [ ] Test: full pipeline produces score 300-900
- [ ] Push to dev-b/scoring

### Phase 5: Hours 28–36 (Report + Full Pipeline)
- [ ] Switch to RealApiClient for all API calls
- [ ] Call /api/report/generate after scoring
- [ ] Implement LlmReportService (call + fallback)
- [ ] Build ReportScreen with all 4 components:
  - [ ] Score summary card
  - [ ] SHAP factors (3 green + 3 red cards)
  - [ ] LLM explanation text
  - [ ] Improvement suggestions
- [ ] Implement PDF export (pdf package)
- [ ] Test: full demo flow end-to-end
- [ ] Push to dev-b/scoring

### Phase 6: Hours 36–42 (Polish + Loans)
- [ ] Build LoanMarketplaceScreen (3 offer cards)
- [ ] Build LoanApplicationForm (pre-filled + user inputs)
- [ ] Implement error state UI for all failure types
- [ ] Add page transition animations
- [ ] Add shimmer loading effects
- [ ] Add haptic feedback on buttons
- [ ] Add confetti animation for score reveal
- [ ] Set app icon
- [ ] Set splash screen
- [ ] Implement session persistence (Hive)
- [ ] Test on different screen sizes
- [ ] Push to dev-b/ui

### Phase 7: Hours 42–48 (Final Assembly)
- [ ] Build release APK: flutter build apk --release
- [ ] Install on test device
- [ ] Run full demo flow on release APK
- [ ] Join Dev A for demo rehearsal (3 runs)
- [ ] Fix any UI issues found
- [ ] Final merge to develop and main
- [ ] Tag v1.0-release
- [ ] Prepare for demo

---

## TOTAL FILE COUNT (Dev B)

Estimated Dart files Dev B creates:
- Core services: ~15 files
- Feature screens: ~25 files (screens + widgets + providers)
- Scoring integration: ~10 files
- Theme + utils: ~8 files
- Tests: ~5 files
- **Total: ~63 Dart files**
