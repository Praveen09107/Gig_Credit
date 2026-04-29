# V3.0 Fairness Engine

## Purpose
Runs asynchronously. Never blocks user decisions. Monitors every batch continuously.

---

## 5 Standard Metrics

| # | Metric | Threshold | Computed Across |
|---|--------|-----------|-----------------|
| 1 | **Demographic Parity** | No group's approval rate < 80% of highest (4/5ths rule) | work_type, state, income_band |
| 2 | **Equalized Odds** | TPR and FPR within 10% across groups | work_type |
| 3 | **Calibration Parity** | Calibration error < 0.08 per group | work_type |
| 4 | **Individual Fairness** | Similar applicants → similar decisions (k-NN pairs) | all |
| 5 | **Disparate Impact** | Formal EEOC 4/5ths rule | work_type, state |

---

## 2 Unique Layers

### Temporal Fairness
A platform worker applying in January (post-festival slump) may score differently than the same worker in October (pre-Diwali peak).

**Test**: If approval rates vary by >15 percentage points across months for the same work type → seasonal bias detected.

**Fix**: Trailing 12-month income normalisation, not just 3/6 month windows.

```python
def check_temporal_fairness(decisions_df):
    for wt in WORK_TYPES:
        subset = decisions_df[decisions_df['work_type'] == wt]
        monthly_rates = subset.groupby('month')['approved'].mean()
        if monthly_rates.max() - monthly_rates.min() > 0.15:
            flag_temporal_bias(wt, monthly_rates)
```

### Linguistic Bias Audit
Audits whether the explanation TEXT itself is fair. If Freelancers consistently get vaguer explanations than Platform Workers with identical scores → the XAI layer is biased.

**3 Dimensions**:
- **Specificity**: Does explanation contain actual numbers? (not just "your income is low")
- **Actionability**: Are suggestions achievable within 30 days?
- **Sentiment polarity**: Is the tone equally constructive across groups?

```python
def audit_linguistic_bias(explanations_df):
    for wt in WORK_TYPES:
        subset = explanations_df[explanations_df['work_type'] == wt]
        avg_specificity = subset['specificity_score'].mean()
        avg_actionability = subset['actionable_count'].mean()
        # Compare across work types — max 15% deviation
```

---

## Automated Mitigation (Not Just Detection)

| Violation Detected | Automated Response |
|-------------------|--------------------|
| Demographic parity violation | Upweight affected group in next training run |
| Equalized odds violation | Per-group threshold optimisation (Hardt et al.) |
| Calibration failure | Group-specific isotonic calibrator |
| Temporal bias | Switch to 12-month trailing normalisation |
| Linguistic bias | Force template-based explanations (bypass LLM) |

---

## Dev A Implementation

### File: `backend/app/services/fairness_engine.py`

```python
class FairnessEngine:
    async def run_audit(self, batch_decisions: List[dict]) -> FairnessReport:
        metrics = {}
        metrics['demographic_parity'] = self._check_demographic_parity(batch_decisions)
        metrics['equalized_odds'] = self._check_equalized_odds(batch_decisions)
        metrics['calibration'] = self._check_calibration_parity(batch_decisions)
        metrics['disparate_impact'] = self._check_disparate_impact(batch_decisions)
        metrics['temporal'] = self._check_temporal_fairness(batch_decisions)
        
        violations = [k for k, v in metrics.items() if not v['passed']]
        
        if violations:
            await self._apply_mitigations(violations, batch_decisions)
        
        return FairnessReport(metrics=metrics, violations=violations)
```

### API: GET /api/v1/fairness/report
Returns latest fairness audit report (for compliance dashboard).

## Dev B: Display in Score Report
Show one line: "Fairness Score: 0.95 — Your score was computed fairly across all demographic groups."
