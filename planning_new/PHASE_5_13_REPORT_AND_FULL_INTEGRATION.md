# ================================================================================
# GIGCREDIT — PHASE 5: REPORT GENERATION & REAL INTEGRATION
# Document 13 | Hours 28–36 | planning_new
# ================================================================================

## PHASE OBJECTIVE
Full pipeline connected: Input → OCR → Verify → Score → SHAP → LLM Report.
Gate G3 checkpoint at Hour 36.

---

## DEV A TASKS (Hours 28–36)

### A5.1 — Stabilize Backend on Render (1 hour)
- Fix any deployment issues
- Monitor logs for errors during Dev B's integration tests
- Ensure Groq API key is valid and working
- Add timeout handling for Groq calls (8 second max)

### A5.2 — Add Rate Limiting (30 min)
```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@app.get("/health")
@limiter.limit("60/minute")
async def health(request: Request):
    return {"status": "ok"}
```

### A5.3 — Add Comprehensive Logging (1 hour)
```python
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("gigcredit")

# Log every API request
@app.middleware("http")
async def log_requests(request: Request, call_next):
    logger.info(f"→ {request.method} {request.url.path}")
    response = await call_next(request)
    logger.info(f"← {response.status_code}")
    return response
```

### A5.4 — Backend Bug Fixes (4 hours)
Dedicated time for fixing issues Dev B discovers during real integration.
Common issues to anticipate:
- CORS headers missing
- HMAC timestamp drift between devices
- MongoDB connection timeouts on Render free tier
- Groq rate limits
- JSON serialization issues (ObjectId, datetime)

### A5.5 — Generate `feature_means.json` (30 min)
Fallback values for each feature when data is missing:
```json
{
  "income_to_anchor_ratio": 0.50,
  "income_stability_cv": 0.60,
  "income_growth_trend": 0.50,
  // ... all 95 features with sensible defaults
}
```

**DELIVERABLES by Hour 36:**
- [ ] Backend stable with no crashes for 2+ hours
- [ ] All API responses < 2 seconds
- [ ] Groq integration working with fallback
- [ ] Rate limiting active
- [ ] Logging captures all requests

---

## DEV B TASKS (Hours 28–36)

### B5.1 — Connect Real Backend (1 hour)
Switch from MockApiClient to RealApiClient:
```dart
// Update the provider to use real backend
final apiClientProvider = Provider<ApiClient>((ref) {
  return RealApiClient(
    baseUrl: 'https://gigcredit-api.onrender.com',
    signer: HmacSigner(hmacSecret: 'demo-secret-key', apiKey: 'demo-api-key', deviceId: deviceHash),
  );
});
```

Test each step with demo inputs against the real backend.

### B5.2 — Confidence Engine (1 hour)
Create `app/lib/scoring/confidence_engine.dart`:
```dart
class ConfidenceEngine {
  Map<String, double> computeConfidence(VerifiedProfile profile) {
    return {
      'p1': _computeP1Confidence(profile),
      'p2': _computeP2Confidence(profile),
      'p3': _computeP3Confidence(profile),
      'p4': _computeP4Confidence(profile),
      'p5': _computeP5Confidence(profile),
      'p6': _computeP6Confidence(profile),
      'p7': _computeP7Confidence(profile),
    };
  }
  
  double _computeP1Confidence(VerifiedProfile p) {
    double conf = 0.0;
    int factors = 0;
    
    // Bank statement parsed → 1.0
    if (p.bank.primary.transactions.isNotEmpty) { conf += 1.0; factors++; }
    // Income declared → 0.60
    if (p.professional.selfDeclaredIncome > 0) { conf += 0.60; factors++; }
    // API verified bank → 1.0
    if (p.bank.primary.accountVerified) { conf += 1.0; factors++; }
    
    return factors > 0 ? conf / factors : 0.40;
  }
  
  double adjustScore(double rawScore, double confidence) {
    // adjusted = raw × confidence + 0.50 × (1 − confidence)
    return rawScore * confidence + 0.50 * (1.0 - confidence);
  }
}
```

### B5.3 — Full Scoring Pipeline (2 hours)
Connect everything in the processing screen:
```dart
Future<ScoreResult> runFullPipeline(VerifiedProfile profile) async {
  // 1. Feature engineering
  final features = FeatureEngineer().engineer(profile);
  
  // 2. Score pillars
  final pillarScores = ScoringEngine().scorePillars(features);
  
  // 3. Apply debt band cap
  if (features[28] > 0.80) { // emi_to_income_ratio
    pillarScores['p3'] = min(pillarScores['p3']!, 0.30);
  }
  
  // 4. Confidence adjustment
  final confidence = ConfidenceEngine().computeConfidence(profile);
  final adjustedPillars = <String, double>{};
  for (final p in pillarScores.keys) {
    adjustedPillars[p] = ConfidenceEngine().adjustScore(
      pillarScores[p]!, confidence[p]!
    );
  }
  
  // 5. Meta-learner
  final finalScore = MetaLearner.fromAsset().predict(adjustedPillars, profile.professional.workType);
  
  // 6. Grade and risk band
  final grade = assignGrade(finalScore);
  final riskBand = assignRiskBand(finalScore);
  
  // 7. SHAP lookup
  final shapResult = ShapLookup.fromAsset().analyze(features);
  
  return ScoreResult(
    finalScore: finalScore,
    grade: grade,
    riskBand: riskBand,
    pillarScores: adjustedPillars,
    confidence: confidence,
    shapPositive: shapResult.positiveFactors,
    shapNegative: shapResult.negativeFactors,
  );
}
```

### B5.4 — LLM Report Integration (1 hour)
After on-device scoring, call the backend for LLM explanation:
```dart
Future<ReportData> generateReport(ScoreResult score, String language) async {
  // Build explanation payload
  final payload = {
    "credit_score": score.finalScore,
    "grade": score.grade,
    "risk_level": score.riskBand,
    "work_type": profile.professional.workType,
    "language": language,
    "pillar_scores": score.pillarScoresToMap(),
    "positive_factors": score.shapPositive.map((f) => f.toJson()).toList(),
    "negative_factors": score.shapNegative.map((f) => f.toJson()).toList(),
    "confidence_level": score.overallConfidence,
  };
  
  try {
    final response = await apiClient.generateReport(payload);
    return ReportData(
      score: score,
      explanation: response['explanation'],
      suggestions: List<String>.from(response['suggestions']),
      language: language,
    );
  } catch (e) {
    // Fallback template
    return ReportData.fallback(score);
  }
}
```

### B5.5 — Report Screen Rendering (2 hours)
Build the full report UI with all 4 components:
1. Score summary card with animated score reveal
2. SHAP factors (3 green strength cards + 3 red concern cards)
3. LLM explanation text (with typewriter animation)
4. Improvement suggestions (numbered cards)

### B5.6 — PDF Export (1 hour)
```dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<void> exportPdf(ReportData report) async {
  final pdf = pw.Document();
  
  pdf.addPage(pw.MultiPage(
    build: (context) => [
      _buildHeader(),
      _buildScoreSection(report.score),
      _buildPillarChart(report.score.pillarScores),
      _buildShapSection(report.score.shapPositive, report.score.shapNegative),
      _buildExplanation(report.explanation),
      _buildSuggestions(report.suggestions),
    ],
  ));
  
  final output = await getTemporaryDirectory();
  final file = File('${output.path}/GigCredit_Report.pdf');
  await file.writeAsBytes(await pdf.save());
  
  // Open or share the PDF
  await OpenFile.open(file.path);
}
```

**DELIVERABLES by Hour 36:**
- [ ] Full pipeline: Input → Score → Report works end-to-end
- [ ] LLM explanation appears in report
- [ ] PDF export generates readable document
- [ ] Confidence engine adjusts pillar scores
- [ ] SHAP factors displayed correctly in report

---

## GATE G3 CHECKPOINT (Hour 36)

```
□ Full demo flow runs end-to-end with demo inputs
□ Score is between 300-900
□ 7 pillar scores displayed in report
□ SHAP top 3 positive + negative shown
□ LLM explanation text in report (in selected language)
□ PDF export works
□ Parity test passes (or known acceptable delta)
□ develop branch has all integrated code
```
