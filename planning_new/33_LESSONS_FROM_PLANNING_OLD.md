# ================================================================================
# GIGCREDIT — LESSONS LEARNED FROM PLANNING_OLD
# Document 33 | planning_new
# ================================================================================

## 1. ANALYSIS OF PREVIOUS 41 PLANNING DOCUMENTS

The previous `planning_old/` folder contained 41 planning documents that
resulted in a FAILED implementation. Here are the specific failure points
and how the NEW planning addresses each one:

---

## 2. FAILURE POINT ANALYSIS

### F1: Contracts Were Ambiguous
**Old Plan**: API schemas were described in prose, not structured JSON.
**Result**: Dev A returned different field names than Dev B expected.
**New Fix**: `contracts/` folder with exact JSON schemas (Doc 05).

### F2: No Mock-First Strategy
**Old Plan**: Dev B waited for Dev A's real backend before coding UI logic.
**Result**: Dev B had working screens but no API integration until the last hours.
**New Fix**: MockApiClient + MockOcrService created in Phase 1 (Doc 07).

### F3: Integration Was an Afterthought
**Old Plan**: "Integration" was mentioned but no specific checkpoints defined.
**Result**: Integration attempted at Hour 46 — catastrophic failure.
**New Fix**: 5 mandatory gates (G0-G4) with specific pass/fail criteria (Doc 04).

### F4: Model-Code Mismatch
**Old Plan**: ML models trained with different feature order than Dart scorer expected.
**Result**: Scores were nonsensical (negative numbers, >900).
**New Fix**: Golden parity test + feature_vector_contract.json (Doc 12).

### F5: Git Chaos
**Old Plan**: Both devs pushed to `main` branch directly.
**Result**: Merge conflicts, lost code, "files missing after pull."
**New Fix**: Strict branching protocol + beginner-friendly git guide (Doc 03).

### F6: File Ownership Conflicts
**Old Plan**: Both devs edited `lib/services/` and `lib/models/`.
**Result**: Constant merge conflicts, duplicated classes, broken imports.
**New Fix**: Directory-level ownership — Dev A never touches `app/lib/` (Doc 02).

### F7: OCR Was Assumed to Work
**Old Plan**: PaddleOCR integration was a single task with no fallback.
**Result**: OCR never worked on device. App showed blank extraction results.
**New Fix**: Tier B strategy — real OCR with DemoOcrService fallback (Doc 06).

### F8: No Artifact Tracking
**Old Plan**: Model files were trained locally but never tracked or versioned.
**Result**: Wrong model version bundled. Hash mismatches. Missing assets in APK.
**New Fix**: artifact_manifest.json with checksums + verify_artifacts.py (Doc 01).

### F9: Too Ambitious Scope
**Old Plan**: Aimed for production-grade deployment with full TFLite integration.
**Result**: Nothing was fully complete; everything was partially done.
**New Fix**: Demo-first strategy with Tier A/B/C classification (Doc 06).

### F10: Planning Was Too Abstract
**Old Plan**: Documents said "implement scoring engine" without specifying HOW.
**Result**: Dev B didn't know what function signatures, data types, or algorithms to use.
**New Fix**: 30+ detailed documents with code examples, data contracts, and algorithms.

---

## 3. QUALITY COMPARISON

| Metric                              | Old Planning    | New Planning     |
|-------------------------------------|----------------|------------------|
| Number of documents                 | 41             | 33+              |
| Code examples in docs               | Minimal        | Extensive        |
| Data contracts specified             | In prose       | In JSON          |
| Integration checkpoints defined      | 0              | 5 (G0-G4)       |
| Mock strategy specified              | No             | Yes (Phase 1)   |
| Git protocol specified               | Brief          | Comprehensive    |
| Error/fallback plan                  | None           | Full fallback    |
| Hour-by-hour task assignment         | No             | Yes (per dev)    |
| Parity test defined                  | No             | Yes (golden)     |
| Demo script included                 | No             | Yes              |
| Risk register                        | No             | Yes              |
| Artifact tracking                    | No             | Yes (manifest)   |
| Per-developer checklist              | No             | Yes (Docs 28,29) |

---

## 4. KEY PRINCIPLE CHANGES

### Old: "Build everything perfectly"
### New: "Build the demo path perfectly, placeholder everything else"

### Old: "Both devs work on everything"
### New: "Strict directory ownership with one-way artifact flow"

### Old: "Integrate at the end"
### New: "Integrate every 8-12 hours"

### Old: "Trust that it works"
### New: "Verify with parity tests, smoke tests, and rehearsals"

### Old: "Verbal decisions are fine"
### New: "Every decision is logged in contracts/decisions.md"
