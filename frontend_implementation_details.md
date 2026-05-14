# GigCredit Frontend Implementation Guide

This document outlines the complete current implementation of the GigCredit Flutter frontend, detailing the routing, design system, core components, and application flow.

## 1. Tech Stack & Architecture
* **Framework**: Flutter (Dart)
* **State Management**: Riverpod (`ConsumerWidget`, `StateNotifierProvider`)
* **Navigation**: GoRouter (Declarative Routing)
* **Local Storage**: Hive (for session and demo states)
* **Animations**: `flutter_animate`
* **Architecture Pattern**: Feature-first architecture (`app/lib/features/...`)

## 2. Design System & UI Theme

The application uses a unified dark-mode-first premium aesthetic, configured centrally in `app.dart` and `app_colors.dart`.

### **Colors & Palette**
* **Backgrounds**: 
  * Primary Background: `#0D0F14` (Deep Space Dark)
  * Card/Surface Background: `#161B25`
  * Glassmorphism Backgrounds: `rgba(30, 37, 53, 0.8)`
* **Accents (Neon/Cyberpunk styling)**:
  * Teal (Primary Accent): `#00D4B4` (Used for active states, CTA, primary text)
  * Green (Success/Verified): `#3DD68C`
  * Gold (Warnings/Pending): `#F4B942`
  * Red (Errors/Rejections): `#FF4E6A`
  * Purple (Locked/AI Features): `#8B5CF6`
* **Text Colors**:
  * Primary Text: `#F0F4FF` (High contrast white-blue)
  * Secondary Text: `#8B95A8` (Muted gray)

### **Typography**
* **Primary Font**: `Inter` (via Google Fonts) - Used for all standard text, buttons, and labels.
* **Secondary Font**: `JetBrains Mono` - Used specifically for numerical outputs (Credit Score, Loan Amounts, AI probabilities) to give a technical, precise feel.

### **Borders & Shapes**
* **Border Radius**: Consistent `BorderRadius.circular(14)` or `16` for cards and modals, `10` or `12` for buttons/inputs.
* **Borders**: Specific emphasis on uniform glowing borders. Non-uniform borders (`Border.all`) are used with distinct `withOpacity(0.15)` background fills to create depth.

---

## 3. Application Flow & Screen Architecture

### **Authentication (`/auth`)**
* `LoginScreen`: Mobile number input.
* `OtpVerificationScreen`: 4-digit OTP input with generic validation. Transitions authenticated state in Riverpod, prompting GoRouter to redirect to `/app/home`.

### **Main Navigation (Bottom Navigation Bar)**
Managed by `AppShell` which provides persistent bottom navigation.
1. **Home (`/app/home`)**: Dashboard showing current score, "Improve Score" CTAs, and a high-level summary.
2. **Loans (`/app/loans`)**: Marketplace for pre-approved loan products.
3. **Profile (`/app/profile`)**: User settings, language preferences, and the **Logout** trigger.

### **The Verification Flow (Steps 1 to 9)**
Accessible via `/app/score/step/:id`. Uses `ScrollableStepLayout` to wrap each form.
* **Step 1**: Personal Info (Name, Age, Work Type Dropdown).
* **Step 2**: KYC (Aadhaar & PAN extraction via OCR).
* **Step 3**: Bank Info (IFSC, Account validation using Mock/Live APIs).
* **Step 4**: Utility Bills (Electricity, Broadband).
* **Step 5**: Work Proof (Dynamic UI based on Step 1: renders SVANidhi for vendors, platform ID for Gig Workers, or generic fallback for Salaried).
* **Step 6**: Govt Schemes (Ration Card, Ayushman Bharat).
* **Step 7**: Insurance (Life, Health, Vehicle).
* **Step 8**: Tax & Assets (ITR, Property).
* **Step 9**: EMI & Loans (Active external loans declarations).

### **Score Generation & AI Evaluation**
* **`ScoreGeneratingScreen`**: A blocking screen showing a pulsing AI loader. It executes `ScorePipeline.execute()` using the gathered `VerifiedProfile`, communicates with the FastAPI backend to fetch LLM explanations, and seeds targeted loan offers.
* **`ScoreReportScreen`**: Displays the final 3-digit score, Risk Grade (A-F), and the AI-generated "Explainability Report" (top strengths and concerns).

### **Loan Origination (`/app/loan/application`)**
A multi-stage modal screen handling the loan lifecycle:
* **Stage 1**: Product Selection (Emergency Micro Loan vs Income Bridge).
* **Stage 2**: Loan Configuration (Slider for Amount, Grid for Tenure).
* **Stage 3**: Key Fact Statement (KFS) legal disclosure and acceptance.
* **Stage 4**: Eligibility Engine (Live UI checklist validating DSCR and LTI ratios).
* **Stage 5**: AI Decision Processing.
* **Stage 6/7**: Final Approval/Rejection and Digital Signature.

---

## 4. Reusable Core Components

* **`ScrollableStepLayout`**: The backbone of the verification flow. Provides the persistent top progress bar, a scrollable form body, and a sticky bottom CTA container with a subtle drop-shadow.
* **`AppTextField`**: Standardized text input with custom active borders (Teal focus ring) and consistent error states.
* **`DocumentUploadCard`**: A highly interactive widget representing OCR uploads. Handles 4 visual states (Empty, Processing Shimmer, Success Green, Fallback/Error Red).
* **`PrimaryButton`**: A 56px height, full-width `ElevatedButton` with `AppColors.accent` background. Displays an inline `CircularProgressIndicator` when `isLoading` is true.
* **`StepProgressBar`**: A custom widget painting horizontal lines connecting circles. Calculates the delta between current step and total steps to paint the active green trail.
* **`HeroScoreCard`**: Used on the Dashboard and Report screens to show the radial or semi-circle gauge indicating the credit score.

## 5. Dynamic Data Capabilities
* **Demo Auto-Fill (`DemoProfileManager`)**: Double-tapping a header in Steps 1-9 triggers the `DemoProfileManager`. It dynamically rotates through 50+ pre-configured user personas (JSON datasets).
* **State Persistence**: The `VerifiedProfileNotifier` accumulates data throughout steps 1-9. When the user completes the flow, the pipeline reads this exact snapshot to generate the ML inference. Upon completion, `reset()` is called, wiping the active state and rotating the `DemoProfileManager` index so the next run generates completely unique UI and API outputs.
