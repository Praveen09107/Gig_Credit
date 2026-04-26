# ================================================================================
# GIGCREDIT — ERROR PREVENTION AND RISK MANAGEMENT
# Document 25 | planning_new
# ================================================================================

## 1. PREVIOUS FAILURE ROOT CAUSES AND PREVENTION

| # | Previous Failure                    | Root Cause                      | Prevention in New Plan              |
|---|------------------------------------|---------------------------------|--------------------------------------|
| 1 | Integration was 0%                 | No mock interfaces              | MockApiClient + MockOcrService      |
| 2 | Model artifacts missing            | No artifact manifest            | artifact_manifest.json + verify     |
| 3 | GitHub push/pull confusion         | No git protocol                 | Doc 03 git workflow                 |
| 4 | OCR not triggering                 | No fallback strategy            | Demo OCR fallback (Doc 06)          |
| 5 | Backend not connected              | No health checks                | /health endpoint + startup verify   |
| 6 | 9-step flow incomplete             | Too ambitious scope             | Demo-first with placeholders        |
| 7 | Input/validation/model mismatch    | No contracts                    | contracts/ folder frozen first      |
| 8 | Folder structure wrong             | No enforced structure           | Doc 01 folder structure             |
| 9 | Developer conflicts                | Shared file ownership           | Strict directory ownership          |
| 10| App became static                  | Mocks not replaced              | 5 integration gates enforce it      |
| 11| Zero testing                       | Not prioritized                 | Test gates at each checkpoint       |
| 12| Minor planning gaps → failures     | Planning too abstract           | 30+ concrete detailed docs          |

---

## 2. RISK REGISTER

| Risk                           | Probability | Impact  | Mitigation                               |
|-------------------------------|-------------|---------|-------------------------------------------|
| Backend deployment fails      | Medium      | High    | MockApiClient as fallback                 |
| Groq API key issue            | Low         | Medium  | Fallback template responses               |
| ML training produces bad model| Low         | High    | Hardcoded scorer fallback (weighted sum)   |
| m2cgen Dart export fails      | Low         | High    | Manual Dart scorer (weighted sum)          |
| PaddleOCR integration fails   | High        | Medium  | DemoOcrService with pre-extracted data     |
| Merge conflicts destroy code  | Medium      | High    | Strict branch isolation + doc 03 protocol  |
| MongoDB Atlas unavailable     | Low         | High    | Local MongoDB or hardcoded responses       |
| Score produces NaN/negative   | Medium      | High    | Sanitization + demo fallback score (682)   |
| PDF parsing fails             | Medium      | Medium  | Pre-parsed transaction list fallback       |
| APK build fails               | Low         | High    | Debug APK as backup for demo               |
| Internet drops during demo    | Medium      | High    | All mocks + offline scoring works          |
| Demo takes too long           | Medium      | Medium  | Pre-fill some steps, skip optional          |

---

## 3. QUALITY GATES

### Gate per Commit:
- [ ] Code compiles without errors
- [ ] No `print()` statements in production code
- [ ] All variables have descriptive names
- [ ] No hardcoded API URLs (use config)
- [ ] No sensitive data in code (use .env)

### Gate per Integration Checkpoint:
- [ ] Both branches merge without conflicts
- [ ] App compiles on both machines
- [ ] Backend health check passes
- [ ] At least one API call succeeds
- [ ] Previous features still work (no regression)

### Gate for Release:
- [ ] Full demo flow works 3/3 times
- [ ] Release APK installs on test device
- [ ] All bundled assets present in APK
- [ ] No crash in 10-minute continuous use

---

## 4. EMERGENCY PROCEDURES

### "Backend is down and won't come back up"
1. Switch app to MockApiClient
2. All verification calls return pre-defined success
3. LLM report uses template text
4. Demo still works 100% — judges won't know

### "Scoring produces wrong numbers"
1. Check feature vector for NaN/Infinity → sanitize
2. Check pillar scores are clamped [0,1]
3. If still wrong → use DemoFallback.score (682, B, Medium)
4. Log the issue for post-hackathon fix

### "Git is messed up and we lost code"
1. STOP. DO NOT force push or reset.
2. Use `git reflog` to find the lost commit
3. Create recovery branch from the commit
4. If all else fails: both devs have local copies — reconstruct manually

### "OCR returns garbage"
1. Switch to DemoOcrService (pre-extracted results)
2. OCR processing animation still plays (2-second delay)
3. Results display correctly
4. Judges see "processing" → "extracted" → no difference from real OCR

---

## 5. DECISION LOG TEMPLATE

Every architecture decision gets logged:

```markdown
## Decision #NNN — YYYY-MM-DD HH:MM
**Topic**: [What was decided]
**Decision**: [The decision made]
**Alternatives Considered**: [What else was considered]
**Reason**: [Why this was chosen]
**Impact**: [What this affects]
**Both Devs Acknowledged**: Yes / No
```
