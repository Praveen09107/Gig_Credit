# ================================================================================
# GIGCREDIT — PHASE 6: POLISH, LOANS & ERROR HANDLING
# Document 14 | Hours 36–42 | planning_new
# ================================================================================

## PHASE OBJECTIVE
Polish the UI, add loan marketplace, implement error handling, and fix edge cases.

---

## DEV A TASKS (Hours 36–42)

### A6.1 — Backend Error Handling Hardening (2 hours)
- Add global exception handler for all unhandled errors
- Add input validation for every endpoint using Pydantic
- Add proper HTTP status codes for all error cases
- Add request/response logging to MongoDB report_logs collection
- Test all error scenarios:
  - Invalid Aadhaar format → 400
  - Unknown PAN → 404
  - Missing auth headers → 401
  - Rate limit exceeded → 429
  - Groq timeout → 503 with fallback

### A6.2 — Backend Monitoring (1 hour)
- Add `/metrics` endpoint showing:
  - Total requests served
  - Average response time
  - Error count by type
  - Last successful Groq call timestamp
- Add health check that verifies MongoDB connection + Groq API key validity

### A6.3 — Create Demo Script Data (1 hour)
Create `demo_data/expected_outputs/demo_verified_profile.json`:
- Pre-built VerifiedProfile for the demo user
- All fields filled with realistic data matching the demo inputs
- This serves as the "golden" VerifiedProfile for testing

Create `demo_data/expected_outputs/demo_feature_vector.json`:
- Pre-computed 95-feature array for the demo user

### A6.4 — Support Dev B with Final Integration (2 hours)
- Respond to integration issues
- Fix any remaining API bugs
- Optimize Groq prompt if needed
- Test the full flow from Dev A's perspective

**DELIVERABLES by Hour 42:**
- [ ] Backend handles all error cases gracefully
- [ ] No unhandled exceptions in logs
- [ ] Demo data files created for fallback
- [ ] Backend stable for 6+ hours

---

## DEV B TASKS (Hours 36–42)

### B6.1 — Loan Marketplace Screen (1 hour)
```dart
class LoanMarketplaceScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = DemoLoanMatcher().getOffers(score, riskBand, workType);
    
    return Scaffold(
      appBar: AppBar(title: Text('Loan Offers')),
      body: Column(
        children: [
          // Header: "Based on your score of 682, you're eligible for:"
          EligibilityHeader(score: 682),
          
          // Offer cards
          ...offers.map((offer) => LoanOfferCard(
            lenderName: offer.lender,
            maxAmount: offer.maxAmount,
            interestRate: offer.interestRate,
            tenure: offer.tenure,
            onApply: () => _openApplicationForm(offer),
          )),
        ],
      ),
    );
  }
}
```

### B6.2 — In-App Loan Application Form (1 hour)
```dart
class LoanApplicationForm extends StatefulWidget {
  // Pre-filled fields from verified profile:
  // - Name, mobile, occupation, income
  // - GigCredit score, grade, risk level
  
  // User fills:
  // - Loan purpose (dropdown)
  // - Requested amount (slider within eligible range)
  // - Address confirmation
  // - Consent checkbox
  
  // Submit: show success animation
}
```

### B6.3 — Error State UI (1.5 hours)
Build error handling for every possible failure:

```dart
// Network error
Widget buildNetworkError() => Column(
  children: [
    Icon(Icons.wifi_off, size: 64, color: AppColors.warning),
    Text('No Internet Connection'),
    Text('Your progress is saved. Please try again when connected.'),
    ElevatedButton(onPressed: retry, child: Text('Retry')),
  ],
);

// Verification failed
Widget buildVerificationFailed(String step) => Column(
  children: [
    Icon(Icons.warning, size: 64, color: AppColors.error),
    Text('Verification Failed'),
    Text('Please check your $step details and try again.'),
    ElevatedButton(onPressed: reupload, child: Text('Re-upload')),
  ],
);

// OCR low confidence
Widget buildLowConfidence() => Column(
  children: [
    Icon(Icons.camera_alt, size: 64, color: AppColors.warning),
    Text('Could Not Read Document'),
    Text('Please take a clearer photo with good lighting.'),
    ElevatedButton(onPressed: retakePhoto, child: Text('Retake Photo')),
  ],
);
```

### B6.4 — UI Polish & Animations (2 hours)
- Add page transition animations (slide left/right between steps)
- Add shimmer loading effect on cards while processing
- Add haptic feedback on button presses
- Add pull-to-refresh on dashboard
- Smooth scroll behavior on long forms
- Add success celebration animation after score reveal (confetti)
- Ensure all text is properly sized (no overflow)
- Test on different screen sizes (5.5", 6.1", 6.7")

### B6.5 — App Branding (30 min)
- Set app icon (GigCredit logo)
- Set splash screen (dark theme with logo)
- Set app name in AndroidManifest
- Set proper package name

### B6.6 — Session Persistence (1 hour)
```dart
// Save progress after each step
Future<void> saveProgress(int completedStep, VerifiedProfile profile) async {
  final box = await Hive.openBox('gigcredit_progress');
  await box.put('last_step', completedStep);
  await box.put('profile', profile.toJson());
}

// Restore on app launch
Future<ProgressState?> restoreProgress() async {
  final box = await Hive.openBox('gigcredit_progress');
  final lastStep = box.get('last_step');
  if (lastStep != null) {
    final profileJson = box.get('profile');
    return ProgressState(
      lastStep: lastStep,
      profile: VerifiedProfile.fromJson(profileJson),
    );
  }
  return null;
}
```

**DELIVERABLES by Hour 42:**
- [ ] Loan marketplace with 3 partner offer cards
- [ ] In-app loan application form
- [ ] Error states for all failure scenarios
- [ ] Smooth animations throughout the app
- [ ] App icon and splash screen set
- [ ] Session persistence (resume from last step)
