# V3.0 Dev B — Loan UI Spec (CORRECTED — 4 Screens)

---

## Screen 1: Product Selection (with Max Eligible Amount)

### File: `features/loans/screens/product_selection_screen.dart`

### Flow
1. Call `POST /api/v1/loan/products` with report_id + score
2. Response includes max_eligible_amount per product (pre-computed)
3. Display 3 product cards with risk-based interest rate
4. Ineligible products greyed with score gap

```
┌─────────────────────────────┐
│ 💰 Your Loan Options         │
│ Interest rate: 15% (based   │  ← Risk-based pricing
│ on your B+ score)           │
│                             │
│ ┌─────────────────────────┐ │
│ │ 🟢 Emergency Micro Loan │ │  Eligible
│ │ ₹5,000 – ₹22,000       │ │  Max amount = pre-computed
│ │ 21-24% APR • 1-3 months │ │
│ │ For: Bike repair, medical│ │
│ │ Max eligible: ₹22,000   │ │  ← Prevents over-requesting
│ │         [Select →]      │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ 🟢 Income Bridge Loan   │ │  Eligible
│ │ ₹25,000 – ₹85,000      │ │
│ │ 15-21% APR • 3-6 months │ │
│ │ For: Seasonal income gap │ │
│ │ Max eligible: ₹85,000   │ │
│ │         [Select →]      │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ 🔴 Growth Loan          │ │  Not eligible (greyed)
│ │ ₹1,00,000 – ₹5,00,000  │ │
│ │ 12-18% APR • 6-12 months│ │
│ │ Need 30 more score pts  │ │  ← Gap shown
│ │    [Score: 720/750]     │ │
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

---

## Screen 2: KFS Display (RBI Mandatory)

### File: `features/loans/screens/kfs_display_screen.dart`

### Flow
1. Call `POST /api/v1/loan/kfs`
2. Display ALL KFS fields
3. MANDATORY checkbox — cannot proceed without checking

```
┌─────────────────────────────┐
│ 📋 Key Fact Statement       │
│ (RBI Digital Lending 2025)  │
│                             │
│ Lender: GigCredit NBFC     │
│ Product: Emergency Micro    │
│ ─────────────────────────── │
│ Principal:        ₹18,000   │
│ Interest Rate:    21.0% p.a.│
│ Tenure:           3 months  │
│ EMI:              ₹6,350    │
│ Total Interest:   ₹1,050    │
│ Total Repayable:  ₹19,050   │
│ ─────────────────────────── │
│ Processing Fee:   ₹360(2.0%)│
│ Net Disbursement: ₹17,640   │
│ APR (all-in):     24.2%     │
│ ─────────────────────────── │
│ Late Payment:     ₹10/day   │
│ Bounce Charge:    ₹250      │
│ Prepayment:       ₹0 (FREE)│
│ ─────────────────────────── │
│ ⚠️ Cooling-Off Period:      │  ← Highlighted
│ 3 days to cancel with ZERO  │
│ penalty after acceptance     │
│ ─────────────────────────── │
│ Grievance: grievance@       │
│ gigcredit.in                │
│                             │
│ ☑ I have read and          │  ← Must check
│   understood the KFS        │
│                             │
│ [Proceed to Application →]  │  ← Active only when checked
└─────────────────────────────┘
```

---

## Screen 3: Loan Application Form

### File: `features/loans/screens/loan_application_screen.dart`

```
┌─────────────────────────────┐
│ 📝 Loan Application         │
│                             │
│ Product: Emergency Micro    │
│ ─────────────────────────── │
│ Amount: ₹18,000             │
│ ├──────●────────────┤       │  Slider: min to max_eligible
│ Min: ₹5,000  Max: ₹22,000  │
│                             │
│ Estimated EMI: ₹6,350/mo   │  ← Live recalculation
│ Total repayable: ₹19,050    │
│ Net you receive: ₹17,640    │
│                             │
│ Purpose:                    │
│ [Working Capital     ▼]     │  Dropdown: working_capital,
│                             │  equipment, emergency,
│                             │  education, other
│                             │
│ ─────────────────────────── │
│ Affordability Check:        │
│ Your monthly income: ₹25K   │  From verified data
│ Existing EMI: ₹3,000        │
│ + This EMI: ₹6,350          │
│ = Total EMI: ₹9,350         │
│ EMI/Income: 37%  ✅ (≤50%)  │  Green if OK
│ DSCR: 2.67        ✅ (≥1.25)│
│                             │
│ [Submit Application →]      │
└─────────────────────────────┘
```

---

## Screen 4: Loan Decision (2 States + Always Alternative)

### File: `features/loans/screens/loan_decision_screen.dart`

#### State A: Approved ✅
```
┌─────────────────────────────┐
│ 🎉 Loan Approved!           │
│                             │
│ ┌─────────────────────────┐ │
│ │ ✅ Amount: ₹18,000      │ │  Green card
│ │ Interest: 21% APR       │ │  Risk-based rate shown
│ │ EMI: ₹6,350/month       │ │
│ │ Tenure: 3 months        │ │
│ │ First EMI: 29 May 2026  │ │
│ │ Net disbursement: ₹17,640│ │
│ └─────────────────────────┘ │
│                             │
│ Decision Trail:             │  ← Transparent stages
│ ✅ Hard Rules: All passed   │
│ ✅ Affordability:           │
│    DSCR: 2.67 (≥1.25) ✓   │
│    EMI ratio: 37% (≤50%) ✓ │
│ ✅ ML Assessment: 82% ✓    │
│                             │
│ 📈 Upgrade Path:            │  ← DiCE counterfactual
│ ┌─────────────────────────┐ │
│ │ Upload insurance + ITR  │ │  Path to higher product
│ │ → Eligible for Income   │ │
│ │   Bridge (₹85K at 15%)  │ │
│ └─────────────────────────┘ │
│                             │
│ [Accept Loan] [Decline]     │
│ ℹ️ 3-day cooling-off period │
└─────────────────────────────┘
```

#### State B: Rejected ❌
```
┌─────────────────────────────┐
│ ❌ Application Not Approved  │
│                             │
│ Adverse Action Notice (AAN) │  ← RBI mandatory
│ ┌─────────────────────────┐ │
│ │ Rejection: Affordability│ │  Bucket shown
│ │                         │ │
│ │ Primary: DSCR 0.91      │ │  Clear reason
│ │ (RBI minimum: 1.25)     │ │  Regulatory = cannot waive
│ │                         │ │
│ │ Secondary:              │ │
│ │ • EMI ratio 62% (>50%)  │ │
│ └─────────────────────────┘ │
│                             │
│ 🔄 3 Paths to Approval:     │  ← DiCE counterfactuals
│                             │
│ 1️⃣ Close smallest EMI       │  Debt reduction path
│    (₹3K/mo) → DSCR rises   │
│    to 1.31 → Qualify ₹18K  │
│                             │
│ 2️⃣ Upload insurance + ITR   │  Documentation path
│    → Score +28 pts → higher │
│    max eligible amount      │
│                             │
│ 3️⃣ Request ₹12,000 instead  │  ← Amount adjustment
│    → Immediately approvable │  (the one nobody thinks of)
│    at current score         │
│                             │
│ ┌─────────────────────────┐ │
│ │ 🟢 Alternative Offer:   │ │  ALWAYS show lower tier
│ │ You qualify for ₹12,000 │ │
│ │ Emergency Micro at 24%  │ │
│ │ [Apply for ₹12,000 →]   │ │
│ └─────────────────────────┘ │
│                             │
│ [Back to Score Report]      │
└─────────────────────────────┘
```

---

## Navigation Flow
```
Score Report → [Apply for Loan]
  → Product Selection (with max eligible pre-computed)
    → [Select Product]
      → KFS Display (RBI mandatory, must acknowledge)
        → [Acknowledge + Proceed]
          → Application Form (slider within max eligible)
            → [Submit]
              → Decision Screen
                → If approved: [Accept] or [Decline]
                → If rejected: [Alternative Offer] or [Back]
```

## Route Registration
```dart
'/loan/products': (context) => ProductSelectionScreen(reportId: ..., score: ...),
'/loan/kfs': (context) => KfsDisplayScreen(productId: ..., amount: ...),
'/loan/apply': (context) => LoanApplicationScreen(kfsData: ..., product: ...),
'/loan/decision': (context) => LoanDecisionScreen(decisionData: ...),
```
