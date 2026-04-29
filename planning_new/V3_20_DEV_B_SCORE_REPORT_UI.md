# V3.0 Dev B — Score Report UI Spec (CORRECTED)

## Screen: `features/report/screens/score_report_screen.dart`

## Layout (top to bottom — matches 10-layer XAI)

```
┌─────────────────────────────┐
│ 1. Score Header             │  Grade badge + animated score gauge
│    ┌───────────────┐        │
│    │  720 / 900    │        │  Count-up animation (300 → 720)
│    │   Grade: B+   │        │  Risk band: Low (green)
│    │   Low Risk    │        │
│    └───────────────┘        │
├─────────────────────────────┤
│ 2. L1: Pillar Waterfall     │  Point contribution per pillar
│    P1 Income   ████████ +142│  Stacked horizontal bars
│    P2 Payment  ██████   +118│  Shows exact point contribution
│    P3 Debt     ███       +48│  Floor: +300
│    P4 Savings  █████     +72│  Total must add to final score
│    P5 Work     ██████    +95│
│    P6 Resilience █       +24│  ← "Your weakest area"
│    P7 Social   ██        +36│
│    P8 Tax      █         +12│
│    Floor       ─────    +300│
│    ────────────────── = 647 │
├─────────────────────────────┤
│ 3. Pillar Radar Chart       │  8-axis radar chart
│    ┌───────────────┐        │  Each axis = one pillar
│    │   P1  P2  P3  │        │  Filled area = calibrated score
│    │ P8        P4  │        │  Shaded band = conformal interval
│    │   P7  P6  P5  │        │  Grow-in animation from center
│    └───────────────┘        │
├─────────────────────────────┤
│ 4. L2: Top Strengths (3-5)  │  Green cards (from SHAP positive)
│    ✅ Strong Income (+0.024)│  Work-type-aware SHAP values
│    ✅ KYC Complete  (+0.019)│  Display name + impact bar
│    ✅ Regular Payments      │  Per-pillar label shown
├─────────────────────────────┤
│ 5. L2: Top Concerns (3-5)   │  Orange/red cards (SHAP negative)
│    ⚠️ No Health Insurance   │  Only 🟢/🟡 items have action link
│    ⚠️ Low Savings Rate      │  🔴 items NOT shown here
│    ⚠️ No ITR Filed          │  "How to improve →" button
├─────────────────────────────┤
│ 6. Pillar Detail Cards (8)  │  Expandable cards
│    ┌─ P1: Income ──────┐    │  Score bar + conformal range (±)
│    │ 117/150   ████░░░  │    │  Top SHAP factor for this pillar
│    │ ±4.5pts [0.68-0.76]│    │  L2 pillar SHAP aggregation
│    │ Weight: 22%        │    │  Expand → all factors + attention
│    └────────────────────┘    │
├─────────────────────────────┤
│ 7. L8: Causal Insight       │  If causal chain triggered (on-device)
│    ┌────────────────────┐    │  Shows root cause + chain + fix
│    │ 🔗 Root Cause:     │    │  "Your debt is high BECAUSE
│    │ Seasonal income    │    │   income is seasonal — stabilise
│    │ → EMI difficulty   │    │   income first, then debt will
│    │ → Low debt score   │    │   improve naturally"
│    └────────────────────┘    │
├─────────────────────────────┤
│ 8. L3+L4: Action Items      │  Actionable improvement cards
│    ┌────────────────────┐    │
│    │ 🟢 Upload Insurance│    │  🟢 = immediate, 🟡 = behavioural
│    │ Easy • 1-7 days    │    │  Difficulty badge (easy/med/hard)
│    │ Expected: +18 pts  │    │  Expected gain in score points
│    └────────────────────┘    │
│                             │
│ L4 Trajectory:              │
│    7-day:   → 665 (Grade C+)│  3 projected paths
│    1-3 mo:  → 687 (Grade B) │
│    Full:    → 710 (Grade B+)│
├─────────────────────────────┤
│ 9. Apply for Loan Button    │  → navigates to loan flow
│    [💰 Apply for Loan]      │
├─────────────────────────────┤
│ 10. Share/Download          │  Share score card as image
│     [📤 Share] [📥 Download]│
└─────────────────────────────┘
```

## Widgets to Create

| Widget | File | Purpose | XAI Layer |
|--------|------|---------|-----------|
| ScoreGaugeWidget | `score_gauge_widget.dart` | Animated circular gauge (300-900) | — |
| PillarWaterfallChart | `pillar_waterfall_chart.dart` | Stacked horizontal bar (pt contribution) | **L1** |
| PillarRadarChart | `pillar_radar_chart.dart` | 8-axis radar with conformal band | — |
| StrengthCard | `strength_card.dart` | Green card with SHAP impact bar | **L2** |
| ConcernCard | `concern_card.dart` | Orange card with action link (🟢/🟡 only) | **L2+L3** |
| PillarDetailCard | `pillar_detail_card.dart` | Expandable pillar card with ± conformal | — |
| ConformalBar | `conformal_bar_widget.dart` | Score bar with shaded ± range | — |
| CausalInsightCard | `causal_insight_card.dart` | Root cause chain display | **L8** |
| ActionImprovementCard | `action_improvement_card.dart` | 🟢🟡 tagged action with gain | **L3** |
| TrajectoryWidget | `trajectory_widget.dart` | 3-path score projection timeline | **L4** |

## Animation Specs
- Score gauge: count-up 300 → final over 1.5s (ease-out curve)
- Waterfall: staggered bar fill (100ms between bars)
- Pillar radar: grow-in from center over 0.8s
- Pillar cards: staggered fade-in (100ms delay between cards)
- Strengths: slide-in from left
- Concerns: slide-in from right
- Trajectory: animated line drawing

## When Connected — Server Enrichment
If backend reachable, call `POST /api/v1/explain/full` and add:
- **L7 Peer Cohort**: "14 of 25 similar workers scored higher — 93% had insurance"
- **L6 EFS note**: "Score near boundary" if EFS < 0.85
- **L9 Delta-SHAP**: "Score changed −35 pts: EMI +23, income dip −12" (returning users)
- **L10 NL Report**: Full Gemini-translated report in user's language
