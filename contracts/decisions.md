# GigCredit Contract Decisions

## 2026-04-25
- Contract set initialized for Dev A and Dev B integration.
- API endpoint list frozen to 13 routes defined in `DEV_A_AGENT_IMPLEMENTATION_GUIDE.md`.
- Scoring architecture fixed at 7 pillars and 95 features for current implementation.
- Missing value default fixed at `0.4` in feature vector preprocessing.

## Demo Credentials (2026-04-25)
The backend database is seeded with these exact credentials. Dev B MUST use these during the demo for successful verification screens:
# GigCredit Contract Decisions

## 2026-04-25
- Contract set initialized for Dev A and Dev B integration.
- API endpoint list frozen to 13 routes defined in `DEV_A_AGENT_IMPLEMENTATION_GUIDE.md`.
- Scoring architecture fixed at 7 pillars and 95 features for current implementation.
- Missing value default fixed at `0.4` in feature vector preprocessing.

## Demo Credentials (2026-04-25)
The backend database is seeded with these exact credentials. Dev B MUST use these during the demo for successful verification screens:
- **Aadhaar**: `765432101234`
- **PAN**: `ABCDE1234F`
- **Name**: `Ravi Kumar`
- **DOB**: `2006-11-16`
- **IFSC**: `HDFC0001234`
- **Account Number**: `1234567890`
- **Vehicle Number**: `TN09AB1234`
- **UAN**: `UAN123456789012`
- **Policy Number**: `HLT2024112345`

## Decision #003 — 2026-04-25
**Topic**: Meta-Learner Upgraded to XGBoost
**Decision**: The Logistic Regression Meta-Learner has been replaced with an XGBoost Classifier with monotonic constraints. 
**Impact on Dev B**: You no longer need to implement array-dot-products or manual standard-scaling for the Meta-Learner. Instead, a new `meta_scorer.dart` file has been generated. Simply call `scoreMeta(List<double> 19_features)` to receive the final probability. The `scoring_constants.dart` file has been stripped of the old linear weights.
