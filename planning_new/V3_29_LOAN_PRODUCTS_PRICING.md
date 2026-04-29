# V3.0 Loan Products, Pricing & Decision Engine (CORRECTED)

## 3 Products (Mapped to Real Gig Worker Needs)

| Product | Amount | Min Score | APR | Tenure | Use Case |
|---------|--------|-----------|-----|--------|----------|
| Emergency Micro Loan | ₹5K–₹25K | 450 | 21–24% | 1–3 mo | Bike breakdown, medical |
| Income Bridge Loan | ₹25K–₹1L | 550 | 15–21% | 3–6 mo | Seasonal income gap |
| Growth Loan | ₹1L–₹5L | 650 | 12–18% | 6–12 mo | Equipment, business |

## Risk-Based Pricing (NOT flat rate)

| Score Range | APR | Grade |
|------------|-----|-------|
| 800+ | 12% | A+/A |
| 720–799 | 15% | B+/B |
| 640–719 | 18% | C+/C |
| 560–639 | 21% | C/D |
| 480–559 | 24% | D |
| Below 480 | Micro-finance referral only | — |

---

## 7 Hard Rules Gate (Binary — fail any = reject)

```python
HARD_RULES = [
    ("aadhaar_pan_verified", lambda r: r.kyc_complete),
    ("age_18_65", lambda r: 18 <= r.age <= 65),
    ("bank_3_months", lambda r: r.bank_months >= 3),
    ("dscr_minimum", lambda r, emi: r.dscr_post_loan(emi) >= 1.25),
    ("score_threshold", lambda r, product: r.score >= product.min_score),
    ("kfs_acknowledged", lambda r: r.kfs_ack == True),
    ("mobile_verified", lambda r: r.mobile_verified),
]
```

**Rejection language**: "Your DSCR would fall to 0.91. RBI minimum is 1.25. This is a legal requirement and cannot be waived."

---

## Affordability Engine (3 Calculations)

```python
# All from verified data — NOT self-reported
dscr = net_income / (existing_emi + proposed_emi)      # must be ≥ 1.25
post_loan_emi_ratio = (existing_emi + proposed_emi) / income  # must be ≤ 0.50
loan_to_income = requested_amount / (avg_monthly_income * 12)  # must be ≤ 10×

# Max eligible amount (computed BEFORE user types a number)
max_emi_affordable = income * 0.50 - existing_emi
discount_factor = score_to_discount(score)  # 524 → 0.55, 720 → 0.90, 800+ → 1.0
max_amount = max_emi_affordable * tenure * discount_factor
```

**Showing max upfront prevents over-requesting → fewer unnecessary rejections.**

---

## LightGBM Loan Classifier (Stage 3)

**Different question than scoring**: Not "what is creditworthiness?" but "given this person requesting this amount, will they repay?"

### Input Features (18)
```python
[
    "final_score",
    "P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8",  # 8 pillar scores
    "dscr", "post_loan_emi_ratio", "loan_to_income",    # affordability
    "payment_streak", "insurance_coverage",               # soft factors
    "savings_buffer_months", "income_growth_slope",
    "w_platform", "w_vendor",                             # work type
]
```

---

## Rejection Taxonomy (4 Buckets)

| Bucket | Explanation Style | Example |
|--------|------------------|---------|
| **Hard Rule Failure** | Regulatory language | "DSCR 0.91 < minimum 1.25 (RBI requirement)" |
| **Model-Scored** | SHAP attribution | "Income stability (P1: 0.52) below threshold" |
| **Affordability** | Pure arithmetic | "EMI burden would be 79% (max 50%)" |
| **Product Mismatch** | Redirect to lower tier | "Score 524 qualifies for Emergency (₹22K at 24%)" |

> **Key UX**: A rejected applicant ALWAYS leaves with an alternative product offer.

---

## DiCE Counterfactual Paths (Always 3)

```python
paths = [
    # Debt Reduction Path
    {"change": "Close ₹8K/month EMI loan",
     "effect": "DSCR rises to 1.31",
     "outcome": "Qualify for ₹70K at 21%"},
    
    # Documentation Path
    {"change": "Upload health insurance + file ITR",
     "effect": "P6 +18pts, P8 +10pts",
     "outcome": "Max eligible rises from ₹55K to ₹82K"},
    
    # Amount Adjustment Path (the one nobody thinks of)
    {"change": "Request ₹55K instead of ₹80K",
     "effect": "Immediately approvable",
     "outcome": "Approved right now at current score"},
]
```

---

## KFS (Key Fact Statement — RBI Mandatory)

Must show BEFORE user can proceed:
- APR including all fees
- Total rupee cost of loan
- EMI schedule
- Prepayment terms
- Cooling-off period (minimum 3 days, zero penalty cancellation)
- Grievance officer contact

## AAN (Adverse Action Notice — RBI Mandatory)

Every rejection generates:
- Primary rejection factor (ranked #1 by SHAP)
- Up to 3 secondary factors
- Which factors are fixable and how
- Which are regulatory (cannot be waived)
- Alternative product offer
- Cooling-off reminder for approved
- Grievance contact
