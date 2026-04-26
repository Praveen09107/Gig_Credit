# ================================================================================
# GIGCREDIT — PHASE 2: DEV B DETAILED UI/UX SPECIFICATION
# Document 10 | Hours 4–12 | planning_new
# ================================================================================

## PURPOSE
Detailed UI/UX guidelines for every screen Dev B builds, with design specifications
that ensure the app looks premium and impresses judges at first glance.

---

## 1. DESIGN PRINCIPLES

1. **Dark Mode First** — Deep navy/charcoal backgrounds with vibrant accent colors
2. **Glassmorphic Cards** — Semi-transparent cards with blur and gradient borders
3. **Micro-Animations** — Every interaction has subtle feedback (scale, fade, slide)
4. **Premium Typography** — Google Fonts Inter/Outfit, proper hierarchy
5. **Consistent Spacing** — 8px grid system
6. **Status Indicators** — Clear green/yellow/red badges for verification status

---

## 2. SCREEN-BY-SCREEN SPECIFICATIONS

### 2.1 Login/Register Screen
```
Layout:
  - Full-screen gradient background (navy → deep blue)
  - App logo at top center (GigCredit with credit score icon)
  - Tagline: "Credit Scoring for India's Gig Workers"
  - Mobile number input with country code (+91)
  - "Send OTP" button (gradient purple → pink)
  - OTP input (6 boxes, auto-advance)
  - "Verify" button
  - Bottom: "Privacy-First | On-Device Processing"

Animations:
  - Logo fades in with scale (0.8 → 1.0)
  - Input fields slide up from bottom
  - OTP boxes appear one by one
  - Success: green ripple effect → navigate to dashboard
```

### 2.2 Dashboard Screen
```
Layout:
  - AppBar with user greeting "Hello, Ravi" and settings icon
  - Hero card: credit score circle (if exists) or "Get Started" CTA
  - If no score: Large "Get Started" button with glowing border animation
  - Two option cards below:
    - "📋 Input Guidelines" — opens guidelines page
    - "▶️ Continue" — goes directly to Step 1
  - If resuming: "Resume from Step X" button with pulsing animation
  - Bottom: Recent activity / privacy badge

Animations:
  - Score circle animates from 0 to actual score
  - Cards slide in from sides
  - CTA button has subtle glow pulse
```

### 2.3 Step Progress Bar (Shared Widget)
```
Design:
  - Horizontal bar at top of every step screen
  - 9 circles connected by lines
  - Completed: solid green circle with checkmark
  - Current: pulsing accent color circle
  - Upcoming: muted outline circle
  - Step labels below: "Profile", "KYC", "Bank", etc.

Implementation:
  - CustomPainter for the line + circles
  - AnimatedContainer for transitions
  - Tap on completed step → navigate back to review
```

### 2.4 Document Upload Card (Shared Widget)
```
Design:
  - Rounded card with dashed border (when empty)
  - Camera icon + "Upload Document" text
  - Two action buttons: "📷 Camera" and "🖼️ Gallery"
  - After upload: shows image thumbnail with:
    - File name
    - "Processing..." spinner
    - Then: extracted fields with green checkmarks
    - "Re-upload" option in corner

States:
  EMPTY → dashed border, upload icons
  UPLOADING → progress bar
  PROCESSING → shimmer loading effect
  EXTRACTED → thumbnail + parsed fields + ✓ badge
  ERROR → red border + error message + retry button
```

### 2.5 Step Screens — Common Structure
```
Every step screen follows this layout:
  [Step Progress Bar]
  [Step Title + Description]
  [Scrollable Form Content]
  [Bottom Action Bar: "Back" | "Continue"]

"Continue" button:
  - Disabled (grey) until all mandatory fields filled
  - Enabled (gradient accent) when ready
  - Shows loading spinner when processing
  - After verification: brief success animation → auto-advance
```

### 2.6 Processing Screen (After Step 9)
```
Design:
  - Full-screen dark background with particle effects
  - Central animated circle
  - Text updates sequentially:
    1. "Validating your data..."  [2 sec]
    2. "Computing 95 financial features..."  [2 sec]
    3. "Running credit assessment..."  [2 sec]
    4. "Analyzing your strengths..."  [2 sec]
    5. "Generating your report..."  [3 sec]
  - Progress bar fills gradually
  - Each step shows a checkmark when done

Animations:
  - Rotating gradient ring
  - Floating particles (small dots)
  - Text fade in/out transitions
  - Final: dramatic pause → "Your score is ready!" → navigate
```

### 2.7 Score Result Screen
```
Design:
  - Dramatic reveal animation
  - Large circular score display (300-900)
    - Animated counter from 0 to actual score
    - Color changes as number increases (red → yellow → green)
    - Grade letter appears below (B)
    - Risk band label (Medium Risk)
  - 7 pillar bars below in horizontal bar chart:
    - Each bar animates from 0 to actual value
    - Color coded per pillar
    - Label and percentage
  - "View Full Report" button at bottom

Animations:
  - Score counter: 0 → 682 over 3 seconds with easing
  - Pillar bars: staggered animation (each bar 200ms delayed)
  - Confetti/particles for scores above 700
```

### 2.8 Report Screen
```
Design:
  - Scrollable report with 4 components:
  
  Component 1: Score Summary Card
    - Score circle (smaller version)
    - Grade badge, risk band, confidence level
    - "Based on 95 financial data points"
  
  Component 2: SHAP Factors
    - "Your Strengths" section (3 green cards)
      - Icon + factor label + impact badge (+15)
    - "Areas to Improve" section (3 red cards)
      - Icon + factor label + impact badge (-18)
  
  Component 3: AI Explanation
    - Card with AI icon
    - LLM-generated text (in user's language)
    - Subtle typewriter animation
  
  Component 4: Improvement Suggestions
    - 3 numbered suggestion cards
    - Each with an actionable tip icon
  
  Bottom Actions:
    - "📄 Export PDF" button
    - "💳 View Loan Offers" button
```

### 2.9 Loan Marketplace Screen
```
Design:
  - "You're eligible for loans!" header
  - 3 lender offer cards:
    - Lender logo/name
    - "Up to ₹1,00,000"
    - Interest rate
    - Tenure
    - "Apply Now" button (glowing)
  - Tapping "Apply Now" → in-app form
    - Pre-filled fields from profile
    - Loan amount input (slider)
    - Purpose dropdown
    - Consent checkbox
    - "Submit Application" button
```

---

## 3. UI STATE MANAGEMENT (Riverpod)

```dart
// Step state provider
final stepStateProvider = StateNotifierProvider<StepStateNotifier, StepState>((ref) {
  return StepStateNotifier();
});

class StepState {
  final int currentStep;                    // 1-9
  final Map<int, StepStatus> stepStatuses;  // {1: VERIFIED, 2: IN_PROGRESS, ...}
  final VerifiedProfile profile;            // Accumulates data across steps
  final bool isProcessing;
}

enum StepStatus { NOT_STARTED, IN_PROGRESS, OCR_COMPLETE, PENDING_VERIFICATION, VERIFIED, REJECTED }
```

---

## 4. RESPONSIVE CONSIDERATIONS

- Target: Android phones, 5.5"–6.7" screens
- Min width: 360px
- Use `MediaQuery` for dynamic sizing
- Scrollable forms for all steps (no overflow)
- Bottom action bar always visible (not scrollable)
- Keyboard-aware: forms scroll when keyboard appears
