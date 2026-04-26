# ================================================================================
# GIGCREDIT — COMPONENT: LLM REPORT PIPELINE
# Document 20 | planning_new
# Owner: Dev A (backend) + Dev B (integration)
# ================================================================================

## 1. PIPELINE OVERVIEW

```
On-Device (Dev B)                          Backend (Dev A)
    │                                           │
    ├─ Scoring complete                         │
    ├─ SHAP top 3+/3- selected                  │
    ├─ Build explanation payload                 │
    ├─ HMAC sign request                         │
    ├─ POST /api/report/generate ──────────────►│
    │                                           ├─ Validate HMAC
    │                                           ├─ Parse payload
    │                                           ├─ Build Groq prompt
    │                                           ├─ Call Groq API
    │                                           ├─ Parse JSON response
    │                                           ├─ Log to report_logs
    │◄───────────────────────────────────────── ├─ Return response
    ├─ Validate response                         │
    ├─ Merge with on-device score data           │
    ├─ Assemble final report                     │
    └─ Render report UI                          │
```

---

## 2. EXPLANATION PAYLOAD (App → Backend)

```json
{
  "credit_score": 682,
  "grade": "B",
  "risk_level": "Medium",
  "work_type": "platform_worker",
  "language": "Tamil",
  "pillar_scores": {
    "income_stability": 72,
    "payment_discipline": 68,
    "debt_management": 55,
    "savings_behaviour": 61,
    "work_identity": 78,
    "financial_resilience": 45,
    "social_accountability": 60
  },
  "positive_factors": [
    { "feature_label": "Consistent monthly income", "pillar": "Income Stability", "impact": 15 },
    { "feature_label": "Utility bills paid on time", "pillar": "Payment Discipline", "impact": 12 },
    { "feature_label": "Bank balance growing steadily", "pillar": "Savings Behaviour", "impact": 9 }
  ],
  "negative_factors": [
    { "feature_label": "EMI payments high relative to income", "pillar": "Debt Management", "impact": -18 },
    { "feature_label": "No active health insurance", "pillar": "Financial Resilience", "impact": -10 },
    { "feature_label": "Low monthly savings rate", "pillar": "Savings Behaviour", "impact": -7 }
  ],
  "confidence_level": "High"
}
```

**CRITICAL**: No Aadhaar, PAN, bank transactions, or raw feature values sent.

---

## 3. GROQ PROMPT TEMPLATE

```python
PROMPT_TEMPLATE = """You are a financial advisor for Indian gig workers.

A gig worker has been assessed using alternative financial data.
Their credit assessment results are:

Credit Score: {credit_score}/900 (Grade: {grade}, Risk: {risk_level})
Work Type: {work_type}

Their strongest financial behaviors:
1. {pos_1_label} (Impact: +{pos_1_impact}, Pillar: {pos_1_pillar})
2. {pos_2_label} (Impact: +{pos_2_impact}, Pillar: {pos_2_pillar})
3. {pos_3_label} (Impact: +{pos_3_impact}, Pillar: {pos_3_pillar})

Areas needing improvement:
1. {neg_1_label} (Impact: {neg_1_impact}, Pillar: {neg_1_pillar})
2. {neg_2_label} (Impact: {neg_2_impact}, Pillar: {neg_2_pillar})
3. {neg_3_label} (Impact: {neg_3_impact}, Pillar: {neg_3_pillar})

Write your response in {language} language.

Respond in JSON format with:
{{
  "explanation": "4-5 sentence plain language explanation of their credit score, mentioning their strengths and areas to improve. Write simply for someone who may not understand financial terms.",
  "suggestions": [
    "Specific actionable suggestion based on their top negative factor",
    "Specific actionable suggestion based on their second negative factor",
    "Specific actionable suggestion based on their third negative factor"
  ]
}}"""
```

---

## 4. GROQ API CALL

```python
from groq import Groq

async def call_groq(prompt: str) -> dict:
    client = Groq(api_key=settings.GROQ_API_KEY)
    
    try:
        response = client.chat.completions.create(
            model="llama3-70b-8192",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.4,
            max_tokens=600,
            response_format={"type": "json_object"},
            timeout=8,  # 8 second max
        )
        
        result = json.loads(response.choices[0].message.content)
        
        # Validate response structure
        if "explanation" not in result or "suggestions" not in result:
            raise ValueError("Missing required fields")
        if len(result["suggestions"]) != 3:
            raise ValueError("Must have exactly 3 suggestions")
        
        return result
    
    except TimeoutError:
        return fallback_response(prompt)
    except json.JSONDecodeError:
        return fallback_response(prompt)
    except Exception as e:
        logger.error(f"Groq API error: {e}")
        return fallback_response(prompt)
```

---

## 5. FALLBACK RESPONSE TEMPLATES

```python
FALLBACK_EXPLANATIONS = {
    "English": "Your credit score is {score} out of 900 (Grade {grade}, {risk} Risk). "
               "Your strongest areas are {pos1} and {pos2}. "
               "The main areas to improve are {neg1} and {neg2}. "
               "Overall, you have a {risk_adj} financial profile with room for improvement.",
    
    "Tamil": "உங்கள் கிரெடிட் ஸ்கோர் 900-ல் {score} (கிரேடு {grade}, {risk} ரிஸ்க்). "
             "உங்கள் வலிமையான பகுதிகள் {pos1} மற்றும் {pos2}. "
             "மேம்படுத்த வேண்டிய முக்கிய பகுதிகள் {neg1} மற்றும் {neg2}.",
    
    "Hindi": "आपका क्रेडिट स्कोर 900 में से {score} है (ग्रेड {grade}, {risk} जोखिम)। "
             "आपकी सबसे मजबूत क्षेत्र {pos1} और {pos2} हैं। "
             "सुधार के मुख्य क्षेत्र {neg1} और {neg2} हैं।",
    
    "Telugu": "మీ క్రెడిట్ స్కోర్ 900 లో {score} (గ్రేడ్ {grade}, {risk} రిస్క్)। "
              "మీ బలమైన ప్రాంతాలు {pos1} మరియు {pos2}. "
              "మెరుగుపరచాల్సిన ప్రధాన ప్రాంతాలు {neg1} మరియు {neg2}.",
    
    "Kannada": "ನಿಮ್ಮ ಕ್ರೆಡಿಟ್ ಸ್ಕೋರ್ 900 ರಲ್ಲಿ {score} (ಗ್ರೇಡ್ {grade}, {risk} ರಿಸ್ಕ್). "
               "ನಿಮ್ಮ ಪ್ರಬಲ ಪ್ರದೇಶಗಳು {pos1} ಮತ್ತು {pos2}.",
}

FALLBACK_SUGGESTIONS = {
    "EMI payments high": [
        "Try to pay off your smallest loan first, then redirect that EMI amount to the next loan.",
        "Consider refinancing your personal loan at a lower interest rate.",
    ],
    "No active health insurance": [
        "Get a basic health insurance policy. Even ₹3,000/year cover can protect your savings.",
    ],
    "Low monthly savings rate": [
        "Start a ₹500/month recurring deposit. Small consistent savings build over time.",
    ],
    # ... more templates per negative factor
}
```

---

## 6. SUPPORTED LANGUAGES

| Language | Code | Groq Support | Fallback Quality |
|----------|------|-------------|-----------------|
| English  | en   | Excellent   | Full template   |
| Hindi    | hi   | Good        | Full template   |
| Tamil    | ta   | Good        | Full template   |
| Telugu   | te   | Moderate    | Basic template  |
| Kannada  | kn   | Moderate    | Basic template  |

For the hackathon demo, recommend English or Tamil for best LLM output quality.

---

## 7. REPORT ASSEMBLY (On-Device — Dev B)

After receiving LLM response, Dev B assembles the final report:

```dart
class ReportAssembler {
  ReportData assemble({
    required ScoreResult score,
    required LlmResponse llmResponse,
    required List<LoanOffer> loanOffers,
  }) {
    return ReportData(
      // Component 1: Score Output (from on-device scoring)
      creditScore: score.finalScore,
      grade: score.grade,
      riskBand: score.riskBand,
      pillarScores: score.pillarScores,
      confidence: score.confidence,
      
      // Component 2: SHAP Factors (from on-device SHAP lookup)
      positiveFactors: score.shapPositive,
      negativeFactors: score.shapNegative,
      
      // Component 3: LLM Explanation (from backend/Groq)
      explanation: llmResponse.explanation,
      language: llmResponse.language,
      
      // Component 4: Suggestions (from backend/Groq)
      suggestions: llmResponse.suggestions,
      
      // Loan Offers (from on-device matching)
      loanOffers: loanOffers,
      
      // Metadata
      generatedAt: DateTime.now(),
      reportVersion: "1.0",
    );
  }
}
```
