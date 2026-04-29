# V3.0 Explainability — 10-Layer Architecture (CORRECTED)

## Layer Summary

| Layer | Name | Location | Latency | Always Available? |
|-------|------|----------|---------|-------------------|
| L1 | Pillar Contribution Decomposition | On-device | <1ms | ✅ Always |
| L2 | Enhanced SHAP Lookup (20-bin, work-type-aware) | On-device | <2ms | ✅ Always |
| L3 | Actionable / Non-Actionable Tagging | On-device | <1ms | ✅ Always |
| L4 | Score Trajectory Simulation | On-device | <2ms | ✅ Always |
| L5 | Live SHAP (exact, fresh) | Server | <3s | When connected |
| L6 | Explanation Faithfulness Score (EFS) | Server | <5s | When connected |
| L7 | Peer Cohort Mirror | Server | <2s | When connected |
| L8 | Causal Attribution | On-device + Server | <1ms / <3s | Partial |
| L9 | Delta-SHAP (returning users) | Server | <2s | Returning users only |
| L10 | LLM Translation | Server | <3s | When connected |

---

## L1 — Pillar Contribution Decomposition (On-Device)

**Pure arithmetic — no SHAP, no lookups.**

```dart
Map<String, int> decomposePillarContributions(
  Map<String, double> adjustedPillars,
  Map<String, double> pillarWeights,
  List<double> metaCoefficients,
  int finalScore,
) {
  double totalContrib = 0;
  final raw = <String, double>{};
  for (final p in adjustedPillars.keys) {
    final contrib = adjustedPillars[p]! * pillarWeights[p]! * metaCoefficients[pillarIndex(p)];
    raw[p] = contrib;
    totalContrib += contrib;
  }
  // Normalise to score points above floor (300)
  final scoreAboveFloor = finalScore - 300;
  return raw.map((k, v) => MapEntry(k, (v / totalContrib * scoreAboveFloor).round()));
}
```

**User sees**: Waterfall chart showing exact point contribution per pillar.

---

## L2 — Enhanced SHAP Lookup (On-Device)

**Improvements over old system**:
1. **20 bins** instead of 10 (captures sharp transitions)
2. **Work-type-aware bins** (separate SHAP per work type)
3. **115 features** including cross-pillar interactions
4. **Pillar-level SHAP aggregation** (sum feature SHAPs per pillar)

**Dev A generates**: `shap_lookup_v3.json` with structure:
```json
{
  "avg_monthly_income_norm": {
    "pillar": "P1",
    "display_name": "Average Monthly Income",
    "bins": [0.0, 0.05, 0.10, ..., 0.95, 1.0],
    "shap_by_work_type": {
      "platform_worker": [-0.02, -0.018, ..., 0.022],
      "street_vendor": [-0.025, -0.020, ..., 0.019],
      "skilled_tradesperson": [...],
      "freelancer": [...]
    },
    "mean_abs_shap": 0.0098
  }
}
```

---

## L3 — Actionable / Non-Actionable Tagging (On-Device)

Three categories:

**🟢 Immediately Actionable (days)**:
- `health_insurance_active` → "Upload health insurance document"
- `eshram_enrolled` → "Register on e-Shram portal (free)"
- `itr_filed_this_year` → "File ITR on Income Tax portal"
- `life_insurance_active` → "Upload life insurance policy"

**🟡 Behaviourally Actionable (weeks/months)**:
- `utility_ontime_ratio` → "Pay utility bills before due date"
- `emi_to_income_ratio` → "Reduce EMI burden by closing one loan"
- `savings_rate` → "Increase monthly savings by ₹500"
- `bounce_count_norm` → "Maintain sufficient balance to avoid bounces"

**🔴 Non-Actionable (NEVER shown as improvements)**:
- `avg_monthly_income_norm` → income level (cannot change instantly)
- Work type → immutable
- Age → immutable
- Credit history length → immutable
- `income_growth_slope` → trailing 6-month trend (cannot retroactively change)

**Rule**: Non-actionable factors appear ONLY in compliance view. Never in user-facing suggestions.

---

## L4 — Score Trajectory Simulation (On-Device)

For each 🟢 actionable feature with negative SHAP:
```dart
estimatedGain = abs(shapDelta) * 600 * metaCoefficientForPillar;
```

**User sees**:
```
"Your score could reach 687 within 7 days if you:
  1. Upload health insurance         → +18 pts
  2. Register on e-Shram portal      → +12 pts
  3. Upload ITR acknowledgement      → +10 pts
  ──────────────────────────────────────────
  Potential score: 687 (Grade B → Grade A)"
```

---

## L5 — Live SHAP (Server)

Fresh SHAP computation per model type:
```python
# P1, P4 (LightGBM): built-in SHAP — fastest
shap_p1 = model_p1.predict(X, pred_contrib=True)

# P2, P3 (XGBoost): TreeExplainer — exact
shap_p2 = shap.TreeExplainer(model_p2).shap_values(X)

# P6 (ExtraTrees): TreeExplainer — supported
shap_p6 = shap.TreeExplainer(model_p6).shap_values(X)
```

Results stored in audit trail. Used for compliance waterfall chart (all 115 features).

---

## L6 — Explanation Faithfulness Score (EFS) (Server)

**50-run perturbation test**:
```python
efs_count = 0
for run in range(50):
    noisy = features + np.random.normal(0, 0.02 * features)
    noisy_shap = compute_shap(noisy)
    noisy_top3 = get_top3_features(noisy_shap)
    if noisy_top3 == original_top3:
        efs_count += 1
efs = efs_count / 50
```

| EFS | Label | Action |
|-----|-------|--------|
| ≥ 0.85 | STABLE | Show explanation normally |
| 0.50–0.84 | MODERATE | Show with note: "Score near a boundary" |
| < 0.50 | UNSTABLE | Flag for human review, show fallback message |

---

## L7 — Peer Cohort Mirror (Server)

Find 25 most similar profiles (cosine similarity on 115 features). Split into score≥650 and score<550 groups. Show top 5 feature differences.

**User sees**: "Among 25 similar gig workers: 14 scored above 650. 93% of them had health insurance."

---

## L8 — Causal Attribution (On-Device Rules + Server DoWhy)

**On-device**: 15 pre-defined causal chain rules in `causal_chains.json`:
```json
{
  "high_emi_low_income": {
    "trigger": "F[28] < 0.40 AND F[1] < 0.50",
    "chain": "Seasonal income drop → difficulty meeting EMI → low debt score",
    "message": "Your debt is high relative to volatile income. Stabilising income is the root fix.",
    "fix": "Consider multi-platform registration to smooth seasonal dips"
  }
}
```

**Server**: Full DoWhy causal graph for compliance view.

---

## L9 — Delta-SHAP (Server, Returning Users)

```
delta_shap[feature] = new_shap[feature] - old_shap[feature]
```

**User sees**: "Your score dropped 35 pts: EMI burden increased (−23), April income dip (−12). Every point accounted for."

---

## L10 — LLM Translation (Server)

LLM is a TRANSLATOR, not a reasoner. It receives structured data from L1–L9 and converts to Tamil/Hindi/Telugu/Kannada/English. All numbers come from the layers, not from the LLM.

---

## Three-Audience Output

| Audience | Layers Used | Content |
|----------|-------------|---------|
| **Applicant** | L1–L4 (offline) + L7,L8,L9,L10 (online) | Waterfall, actions, trajectory, peer comparison, NL report |
| **Compliance** | L5, L6, L8 | Full SHAP waterfall, EFS score, causal graph, model hashes |
| **Regulator** | All | + SHA-256 audit trail, decision replay, fairness metrics, RBI flags |
