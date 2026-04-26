# ================================================================================
# GIGCREDIT — CROSS-STEP VALIDATION AND VERIFIED PROFILE
# Document 30 | planning_new
# ================================================================================

## 1. VERIFIED PROFILE — THE CENTRAL DATA OBJECT

The VerifiedProfile is the SINGLE source of truth built incrementally across
all 9 steps. It's stored encrypted on-device and NEVER sent to the backend.

### 1.1 How It's Built

```
Step 1 → profile.personal (name, dob, mobile, work_type, income)
Step 2 → profile.identity (aadhaar, pan, face_match)
Step 3 → profile.bank (transactions, balances, EMIs)
Step 4 → profile.utility (bills, on-time ratios)
Step 5 → profile.work_proof (RC, DL, earnings)
Step 6 → profile.gov_schemes (eShram, PMSYM)
Step 7 → profile.insurance (health, life, vehicle)
Step 8 → profile.tax (ITR, GST)
Step 9 → profile.emi_loans (declared loans, cross-check)
```

### 1.2 Update Rules

- Profile fields are updated ONLY after validation passes
- Previous step data is NEVER overwritten by later steps
- Each step appends to the profile, never replaces
- Step status tracks completion state

---

## 2. CROSS-STEP VALIDATION MATRIX

These validations run after ALL steps are complete (before scoring):

| Validation                      | Steps    | Rule                                    | Severity |
|--------------------------------|----------|------------------------------------------|----------|
| Name consistency               | 1,2,3    | fuzzy(aadhaar, pan, bank) ≥ 85%          | WARNING  |
| DOB consistency                | 1,2      | aadhaar_dob == pan_dob                    | WARNING  |
| Address consistency            | 2,4      | fuzzy(aadhaar_addr, utility_addr) ≥ 70%   | INFO     |
| Mobile consistency             | 1,4      | step1_mobile == mobile_bill_number        | WARNING  |
| Bank holder vs identity        | 2,3      | fuzzy(aadhaar_name, bank_holder) ≥ 85%    | WARNING  |
| EMI declared vs detected       | 3,9      | each declared EMI found in bank debits    | INFO     |
| Vehicle RC vs insurance         | 5,7      | rc_vehicle_number == insurance_vehicle    | WARNING  |
| DL class vs RC class           | 5        | DL covers RC vehicle class                | WARNING  |
| Insurance name vs identity      | 2,7      | fuzzy(aadhaar_name, policy_holder) ≥ 85%  | WARNING  |
| ITR PAN vs identity PAN         | 2,8      | step2_pan == step8_itr_pan                | ERROR    |
| Income consistency             | 1,3,5    | declared ≈ bank_avg ≈ platform_earnings   | WARNING  |
| Utility bill continuity        | 4        | same consumer# across all 6 months       | INFO     |

### Severity Actions:
- **ERROR**: Block scoring — user must fix
- **WARNING**: Allow scoring but show yellow badge
- **INFO**: No badge — logged internally

---

## 3. EMI AUTO-DETECTION ALGORITHM

```dart
List<DetectedEmi> detectEmis(List<Transaction> transactions) {
  // Group by narration similarity
  final groups = groupBySimilarNarration(transactions.where((t) => t.isDebit));
  
  final emis = <DetectedEmi>[];
  
  for (final group in groups) {
    // Check recurrence: appears in 3+ months
    if (group.months.length >= 3) {
      // Check amount consistency: stddev/mean < 0.05 (5% tolerance)
      if (group.amountCV < 0.05) {
        // Check date consistency: same day ±3
        if (group.dayStddev < 3) {
          emis.add(DetectedEmi(
            narration: group.commonNarration,
            amount: group.avgAmount,
            monthCount: group.months.length,
            avgDay: group.avgDay,
            confidence: group.confidence,
          ));
        }
      }
    }
  }
  
  return emis;
}
```

---

## 4. CONFIDENCE ENGINE DETAILS

Each pillar's confidence is computed from data quality/completeness:

```dart
// P1 Income Stability confidence
double _computeP1Confidence(VerifiedProfile p) {
  double score = 0.0;
  int checks = 0;
  
  // Bank statement exists with enough transactions
  if (p.bank.primary.transactions.length >= 50) { score += 1.0; checks++; }
  else if (p.bank.primary.transactions.length >= 30) { score += 0.7; checks++; }
  else { score += 0.3; checks++; }
  
  // 6 months coverage
  if (p.bank.primary.monthlyCredits.length >= 6) { score += 1.0; checks++; }
  else { score += p.bank.primary.monthlyCredits.length / 6.0; checks++; }
  
  // Income verified (API + bank match)
  if (p.bank.primary.accountVerified) { score += 1.0; checks++; }
  else { score += 0.5; checks++; }
  
  // Platform earnings present (for platform workers)
  if (p.professional.workType == 'platform_worker') {
    if (p.workProof.platformEarnings.isNotEmpty) { score += 1.0; checks++; }
    else { score += 0.3; checks++; }
  }
  
  return checks > 0 ? score / checks : 0.40;
}
```

### Confidence Adjustment Formula
```
adjusted_score = raw_score × confidence + 0.50 × (1 − confidence)
```

Effect:
- confidence = 1.00 → adjusted = raw_score (no change)
- confidence = 0.50 → adjusted = midpoint between raw and 0.50
- confidence = 0.00 → adjusted = 0.50 (forced neutral)

### Minimum Confidence Gate
If pillar confidence < 0.30:
- Pillar excluded from meta-learner
- Set to 0.50 neutral
- Report shows "Not enough data for this pillar"
