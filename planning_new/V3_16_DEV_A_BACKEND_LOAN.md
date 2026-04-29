# V3.0 Dev A — Backend Loan API Spec (CORRECTED)

## File: `backend/app/api/loan_router.py`

## 3 Products (Real Gig Worker Needs)

```python
PRODUCTS = [
    {
        "id": "emergency_micro",
        "name": "Emergency Micro Loan",
        "amount_range": [5000, 25000],
        "min_score": 450,
        "tenure_range": [1, 3],
        "use_case": "Bike breakdown, medical emergency",
    },
    {
        "id": "income_bridge",
        "name": "Income Bridge Loan",
        "amount_range": [25000, 100000],
        "min_score": 550,
        "tenure_range": [3, 6],
        "use_case": "Seasonal income gap (e.g., post-festival)",
    },
    {
        "id": "growth",
        "name": "Growth Loan",
        "amount_range": [100000, 500000],
        "min_score": 650,
        "tenure_range": [6, 12],
        "use_case": "Equipment, business expansion",
    },
]
```

---

## Risk-Based Pricing (NOT flat rate)

```python
def get_interest_rate(score: int) -> float:
    if score >= 800: return 12.0
    elif score >= 720: return 15.0
    elif score >= 640: return 18.0
    elif score >= 560: return 21.0
    elif score >= 480: return 24.0
    else: return None  # micro-finance referral only

def get_discount_factor(score: int) -> float:
    """Penalises uncertainty — lower score = smaller max amount"""
    if score >= 800: return 1.0
    elif score >= 720: return 0.90
    elif score >= 640: return 0.75
    elif score >= 560: return 0.60
    else: return 0.55
```

---

## POST /api/v1/loan/products

Returns eligible products WITH max eligible amount pre-computed.

```python
@router.post("/loan/products")
async def get_products(req: ProductRequest):
    report = await db.scores.find_one({"report_id": req.report_id})
    interest_rate = get_interest_rate(report["final_score"])
    
    eligible = []
    for p in PRODUCTS:
        if report["final_score"] >= p["min_score"]:
            # Pre-compute max eligible amount (prevents over-requesting)
            income = estimate_income(report)
            existing_emi = estimate_existing_emi(report)
            max_affordable_emi = income * 0.50 - existing_emi
            
            rate = interest_rate / 100 / 12
            tenure = p["tenure_range"][1]
            if rate > 0 and max_affordable_emi > 0:
                max_amount = max_affordable_emi * ((1+rate)**tenure - 1) / (rate * (1+rate)**tenure)
            else:
                max_amount = 0
            
            discount = get_discount_factor(report["final_score"])
            max_amount = min(max_amount * discount, p["amount_range"][1])
            max_amount = max(max_amount, p["amount_range"][0])
            
            eligible.append({
                **p,
                "eligible": True,
                "interest_rate": interest_rate,
                "max_eligible_amount": int(max_amount),
                "discount_factor": discount,
            })
        else:
            eligible.append({**p, "eligible": False, "gap": p["min_score"] - report["final_score"]})
    
    return {"products": eligible}
```

---

## POST /api/v1/loan/kfs

RBI-compliant Key Fact Statement — MUST be shown and acknowledged BEFORE application.

```python
@router.post("/loan/kfs")
async def generate_kfs(req: KfsRequest):
    report = await db.scores.find_one({"report_id": req.report_id})
    interest_rate = get_interest_rate(report["final_score"])
    rate = interest_rate / 100 / 12
    n = req.tenure_months
    
    emi = req.amount * rate * (1+rate)**n / ((1+rate)**n - 1)
    total = emi * n
    fee_pct = 2.0 if interest_rate >= 21 else 1.5 if interest_rate >= 15 else 1.0
    fee = req.amount * fee_pct / 100
    
    return {
        "kfs_id": f"KFS-{int(time.time()*1000)}",
        "product_name": req.product_name,
        "lender": "GigCredit NBFC Partner",
        "principal": req.amount,
        "interest_rate_annual": interest_rate,
        "tenure_months": n,
        "emi": round(emi),
        "total_interest": round(total - req.amount),
        "total_repayable": round(total),
        "processing_fee": round(fee),
        "processing_fee_pct": fee_pct,
        "net_disbursement": round(req.amount - fee),
        "annual_percentage_rate": round(interest_rate * 1.15, 1),
        "penalties": {
            "late_payment_per_day": 10,
            "bounce_charge": 250,
            "prepayment_charge": 0,    # Zero prepayment penalty
        },
        "cooling_off_period_days": 3,  # RBI minimum — can cancel with zero penalty
        "grievance_officer": "grievance@gigcredit.in",
        "generated_at": datetime.utcnow().isoformat(),
    }
```

---

## POST /api/v1/loan/apply

3-stage decision engine with separate Loan XAI.

```python
@router.post("/loan/apply")
async def apply_loan(req: LoanApplyRequest):
    report = await db.scores.find_one({"report_id": req.report_id})
    
    # ── GATE 1: Hard Rules (7 binary checks) ──────────────
    hard_result = check_hard_rules(report, req)
    if not hard_result["pass"]:
        decision = build_rejection(report, req, "hard_rule", hard_result)
        await db.loan_decisions.insert_one(decision)
        await audit_chain.append("loan_rejected_hard", decision)
        return decision
    
    # ── GATE 2: Affordability Engine ──────────────
    income = estimate_income(report)
    existing_emi = estimate_existing_emi(report)
    rate = get_interest_rate(report["final_score"]) / 100 / 12
    n = req.tenure_months
    proposed_emi = req.amount * rate * (1+rate)**n / ((1+rate)**n - 1)
    
    affordability = {
        "dscr": round(income / (existing_emi + proposed_emi), 2) if (existing_emi + proposed_emi) > 0 else 999,
        "post_loan_emi_ratio": round((existing_emi + proposed_emi) / income, 2) if income > 0 else 999,
        "loan_to_income": round(req.amount / (income * 12), 2) if income > 0 else 999,
        "proposed_emi": round(proposed_emi),
    }
    affordability["pass"] = (
        affordability["dscr"] >= 1.25 and
        affordability["post_loan_emi_ratio"] <= 0.50 and
        affordability["loan_to_income"] <= 10.0
    )
    
    if not affordability["pass"]:
        decision = build_rejection(report, req, "affordability", affordability)
        await db.loan_decisions.insert_one(decision)
        await audit_chain.append("loan_rejected_affordability", decision)
        return decision
    
    # ── GATE 3: LightGBM Classifier ──────────────
    loan_features = build_loan_features(report, affordability)
    prob = loan_model.predict_proba([loan_features])[0][1]
    threshold = thresholds[req.product_id][report["work_type"]]
    
    ml_result = {
        "pass": prob >= threshold,
        "probability": round(float(prob), 4),
        "threshold": threshold,
    }
    
    if not ml_result["pass"]:
        decision = build_rejection(report, req, "ml_scored", ml_result)
        await db.loan_decisions.insert_one(decision)
        await audit_chain.append("loan_rejected_ml", decision)
        return decision
    
    # ── APPROVED ──────────────
    decision = {
        "decision_id": f"LD-{int(time.time()*1000)}",
        "decision": "approved",
        "approved_amount": req.amount,
        "interest_rate": get_interest_rate(report["final_score"]),
        "emi": round(proposed_emi),
        "tenure_months": req.tenure_months,
        "hard_rules": hard_result,
        "affordability": affordability,
        "ml_decision": ml_result,
        "counterfactual_paths": generate_counterfactuals(report, "upgrade"),
        "decided_at": datetime.utcnow().isoformat(),
    }
    await db.loan_decisions.insert_one(decision)
    await audit_chain.append("loan_approved", decision)
    return decision
```

---

## Rejection Builder — 4 Buckets

```python
def build_rejection(report, req, bucket, details):
    decision = {
        "decision_id": f"LD-{int(time.time()*1000)}",
        "decision": "rejected",
        "rejection_bucket": bucket,  # "hard_rule" | "affordability" | "ml_scored"
        "details": details,
        "decided_at": datetime.utcnow().isoformat(),
    }
    
    # AAN (Adverse Action Notice — RBI mandatory)
    decision["aan"] = generate_aan(bucket, details, report)
    
    # DiCE Counterfactual Paths (always 3)
    decision["counterfactual_paths"] = generate_counterfactuals(report, bucket)
    
    # Product Mismatch: ALWAYS offer lower tier if available
    decision["alternative_offer"] = find_alternative_product(report["final_score"], req)
    
    return decision
```

---

## DiCE Counterfactual Paths (Always 3)

```python
def generate_counterfactuals(report, context):
    paths = []
    
    # Path 1: Debt Reduction
    if estimate_existing_emi(report) > 0:
        paths.append({
            "type": "debt_reduction",
            "change": f"Close smallest EMI loan (₹{estimate_smallest_emi(report)}/month)",
            "effect": f"DSCR rises to {compute_new_dscr(report):.2f}",
            "outcome": f"Qualify for ₹{compute_new_eligible(report):,}",
        })
    
    # Path 2: Documentation
    missing_docs = find_missing_actionable_docs(report)
    if missing_docs:
        pts = sum(d['gain'] for d in missing_docs[:3])
        paths.append({
            "type": "documentation",
            "change": f"Upload {', '.join(d['name'] for d in missing_docs[:3])}",
            "effect": f"Score rises by +{pts} pts",
            "outcome": f"Max eligible increases to ₹{compute_doc_boost_eligible(report, pts):,}",
        })
    
    # Path 3: Amount Adjustment (ALWAYS — the one nobody thinks of)
    lower_amount = find_max_approvable_amount(report)
    if lower_amount > 0:
        paths.append({
            "type": "amount_adjustment",
            "change": f"Request ₹{lower_amount:,} instead",
            "effect": "Immediately approvable at current score",
            "outcome": f"Approved right now at {get_interest_rate(report['final_score'])}% APR",
        })
    
    return paths[:3]
```

---

## AAN (Adverse Action Notice — RBI Mandatory)

```python
def generate_aan(bucket, details, report):
    aan = {
        "primary_reason": "",
        "secondary_reasons": [],
        "fixable_factors": [],
        "regulatory_factors": [],
        "alternative_product": None,
        "cooling_off_reminder": "3-day cancellation with zero penalty",
        "grievance_contact": "grievance@gigcredit.in",
    }
    
    if bucket == "hard_rule":
        for rule in details.get("failed_rules", []):
            if rule in ["dscr_minimum", "score_threshold"]:
                aan["regulatory_factors"].append(RULE_DESCRIPTIONS[rule])
            else:
                aan["secondary_reasons"].append(RULE_DESCRIPTIONS[rule])
        aan["primary_reason"] = aan["regulatory_factors"][0] if aan["regulatory_factors"] else "Hard rule check failed"
    
    elif bucket == "affordability":
        if details["dscr"] < 1.25:
            aan["primary_reason"] = f"DSCR would be {details['dscr']} (RBI minimum: 1.25)"
            aan["regulatory_factors"].append("This is a legal requirement and cannot be waived")
        if details["post_loan_emi_ratio"] > 0.50:
            aan["secondary_reasons"].append(f"Post-loan EMI ratio would be {details['post_loan_emi_ratio']*100:.0f}% (max 50%)")
    
    elif bucket == "ml_scored":
        aan["primary_reason"] = "Credit risk assessment below approval threshold"
        # Find top SHAP factors from scoring report
        factors = get_top_negative_shap(report, n=3)
        aan["fixable_factors"] = [f for f in factors if is_actionable(f)]
    
    return aan
```
