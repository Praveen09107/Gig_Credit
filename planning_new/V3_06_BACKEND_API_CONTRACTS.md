# V3.0 Backend API Contracts (CORRECTED)

## Base URL: `http://localhost:8000/api/v1`

---

## 1. POST /score/store

### Request
```json
{
  "user_id": "firebase_uid",
  "final_score": 720,
  "grade": "B+",
  "probability": 0.68,
  "work_type": "platform_worker",
  "pillar_scores": {"P1": 0.72, "P2": 0.78, "P3": 0.55, "P4": 0.60, "P5": 0.85, "P6": 0.45, "P7": 0.52, "P8": 0.30},
  "pillar_scores_raw": {"P1": 0.70, ...},
  "pillar_scores_calibrated": {"P1": 0.74, ...},
  "confidence_values": {"P1": 1.0, "P2": 0.75, ...},
  "feature_vector": [0.45, 0.62, ...115 values...]
}
```

### Response
```json
{
  "report_id": "GC-1714400000123",
  "stored_at": "2026-04-29T15:06:00Z"
}
```

---

## 2. GET /score/history/{user_id}

### Response
```json
{
  "scores": [
    {"report_id": "GC-123", "final_score": 720, "grade": "B+", "stored_at": "...", "work_type": "..."},
    {"report_id": "GC-100", "final_score": 685, "grade": "B", "stored_at": "..."}
  ]
}
```

---

## 3. POST /explain/full

### Request
```json
{
  "report_id": "GC-1714400000123",
  "user_id": "firebase_uid",
  "language": "en"
}
```

### Response
```json
{
  "L5_live_shap": {"P1": [0.018, -0.012, ...], "P2": [...]},
  "L6_efs": {"score": 0.92, "label": "STABLE", "note": ""},
  "L7_peer_cohort": {
    "cohort_size": 25,
    "high_scorers": 14,
    "key_differences": [
      {"feature": "health_insurance_active", "display_name": "Health Insurance", "high_group_avg": 0.93, "low_group_avg": 0.27, "diff": 0.66}
    ]
  },
  "L8_causal_server": {...},
  "L9_delta_shap": {
    "previous_score": 685,
    "current_score": 720,
    "score_change": 35,
    "improved": [{"display_name": "Insurance", "delta": 0.012, "score_impact_pts": 18}],
    "declined": [],
    "fully_explained": true
  },
  "L10_nl_report": "Your GigCredit score is 720 (Grade B+)..."
}
```

---

## 4. POST /loan/products

### Request
```json
{
  "report_id": "GC-1714400000123",
  "final_score": 720,
  "work_type": "platform_worker"
}
```

### Response
```json
{
  "products": [
    {
      "id": "emergency_micro",
      "name": "Emergency Micro Loan",
      "amount_range": [5000, 25000],
      "min_score": 450,
      "tenure_range": [1, 3],
      "use_case": "Bike breakdown, medical",
      "eligible": true,
      "interest_rate": 15.0,
      "max_eligible_amount": 22000,
      "discount_factor": 0.90
    },
    {
      "id": "growth",
      "name": "Growth Loan",
      "eligible": false,
      "gap": 30
    }
  ]
}
```

---

## 5. POST /loan/kfs

### Request
```json
{
  "report_id": "GC-123",
  "product_id": "emergency_micro",
  "product_name": "Emergency Micro Loan",
  "amount": 18000,
  "tenure_months": 3
}
```

### Response
```json
{
  "kfs_id": "KFS-1714400001234",
  "product_name": "Emergency Micro Loan",
  "lender": "GigCredit NBFC Partner",
  "principal": 18000,
  "interest_rate_annual": 21.0,
  "tenure_months": 3,
  "emi": 6350,
  "total_interest": 1050,
  "total_repayable": 19050,
  "processing_fee": 360,
  "processing_fee_pct": 2.0,
  "net_disbursement": 17640,
  "annual_percentage_rate": 24.2,
  "penalties": {"late_payment_per_day": 10, "bounce_charge": 250, "prepayment_charge": 0},
  "cooling_off_period_days": 3,
  "grievance_officer": "grievance@gigcredit.in",
  "generated_at": "2026-04-29T15:10:00Z"
}
```

---

## 6. POST /loan/apply

### Request
```json
{
  "report_id": "GC-123",
  "kfs_id": "KFS-123",
  "kfs_acknowledged": true,
  "product_id": "emergency_micro",
  "requested_amount": 18000,
  "tenure_months": 3,
  "purpose": "working_capital",
  "user_id": "firebase_uid"
}
```

### Response (Approved)
```json
{
  "decision_id": "LD-1714400002345",
  "decision": "approved",
  "approved_amount": 18000,
  "interest_rate": 21.0,
  "emi": 6350,
  "tenure_months": 3,
  "hard_rules": {"pass": true, "failed_rules": []},
  "affordability": {"pass": true, "dscr": 2.67, "post_loan_emi_ratio": 0.37, "loan_to_income": 0.72, "proposed_emi": 6350},
  "ml_decision": {"pass": true, "probability": 0.82, "threshold": 0.42},
  "counterfactual_paths": [
    {"type": "documentation", "change": "Upload insurance + ITR", "effect": "Score +28 pts", "outcome": "Eligible for Income Bridge (₹85K at 15%)"}
  ],
  "decided_at": "2026-04-29T15:12:00Z"
}
```

### Response (Rejected)
```json
{
  "decision_id": "LD-123",
  "decision": "rejected",
  "rejection_bucket": "affordability",
  "details": {"dscr": 0.91, "post_loan_emi_ratio": 0.62, "loan_to_income": 2.1},
  "aan": {
    "primary_reason": "DSCR would be 0.91 (RBI minimum: 1.25)",
    "secondary_reasons": ["EMI ratio would be 62% (max 50%)"],
    "fixable_factors": ["Close smallest EMI loan"],
    "regulatory_factors": ["DSCR minimum is a legal requirement"],
    "cooling_off_reminder": "3-day cancellation with zero penalty",
    "grievance_contact": "grievance@gigcredit.in"
  },
  "counterfactual_paths": [
    {"type": "debt_reduction", "change": "Close ₹3K/mo EMI", "effect": "DSCR rises to 1.31", "outcome": "Qualify for ₹18K"},
    {"type": "documentation", "change": "Upload insurance + ITR", "effect": "Score +28 pts", "outcome": "Higher max eligible"},
    {"type": "amount_adjustment", "change": "Request ₹12,000 instead", "effect": "Immediately approvable", "outcome": "Approved now at 24%"}
  ],
  "alternative_offer": {"product_id": "emergency_micro", "product_name": "Emergency Micro", "max_amount": 12000, "interest_rate": 24.0},
  "decided_at": "2026-04-29T15:12:00Z"
}
```

---

## 7. GET /loan/decision/{decision_id}

### Response
Same as POST /loan/apply response (fetches stored decision).

---

## 8. GET /audit/verify

### Response
```json
{"chain_valid": true, "total_records": 42}
```

---

## 9. GET /audit/replay/{report_id}

### Response
```json
{
  "replayed_score": 720,
  "stored_score": 720,
  "match": true,
  "models_same_as_production": true,
  "integrity_note": "Model integrity verified"
}
```

---

## 10. GET /fairness/report

### Response
```json
{
  "metrics": {
    "demographic_parity": {"passed": true, "min_ratio": 0.87},
    "equalized_odds": {"passed": true, "tpr_diff": 0.06},
    "calibration": {"passed": true, "max_ece": 0.04},
    "temporal": {"passed": true, "max_monthly_diff": 0.11},
    "linguistic": {"passed": true, "specificity_diff": 0.08}
  },
  "violations": [],
  "mitigations_applied": []
}
```
