import json
import logging

from groq import AsyncGroq, GroqError
from tenacity import retry, stop_after_attempt, wait_exponential

from app.config import settings
from app.schemas.report_schemas import ReportGenerateRequest
from app.services.prompt_builder import build_prompt


def _fallback(language: str, score: int, grade: str) -> dict:
    text_map = {
        "English": f"Your credit score is {score} with grade {grade}. Your financial behavior is moderate and can improve with disciplined repayments and stable savings.",
        "Tamil": f"உங்கள் கிரெடிட் ஸ்கோர் {score}, கிரேடு {grade}. தொடர்ந்து கட்டுப்பாட்டுடன் பணப்பரிவர்த்தனை செய்தால் மேலும் மேம்படும்.",
        "Hindi": f"आपका क्रेडिट स्कोर {score} और ग्रेड {grade} है। नियमित भुगतान और बचत से स्कोर बेहतर हो सकता है।",
        "Telugu": f"మీ క్రెడిట్ స్కోర్ {score}, గ్రేడ్ {grade}. క్రమమైన చెల్లింపులు మరియు పొదుపులతో మెరుగుపడుతుంది.",
        "Kannada": f"ನಿಮ್ಮ ಕ್ರೆಡಿಟ್ ಸ್ಕೋರ್ {score}, ಗ್ರೇಡ್ {grade}. ನಿಯಮಿತ ಪಾವತಿ ಮತ್ತು ಉಳಿತಾಯದಿಂದ ಇದು ಸುಧಾರಿಸುತ್ತದೆ.",
    }
    return {
        "status": "fallback",
        "language": language if language in text_map else "English",
        "explanation": text_map.get(language, text_map["English"]),
        "suggestions": [
            "Pay EMIs on time every month",
            "Keep a stable monthly savings habit",
            "Maintain active insurance coverage",
        ],
        "model_used": None,
    }


logger = logging.getLogger("gigcredit.llm")


@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=2, max=10),
    reraise=True,
)
async def _call_groq_api(client: AsyncGroq, prompt: str) -> dict:
    response = await client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        temperature=0.4,
        max_tokens=600,
        response_format={"type": "json_object"},
        messages=[
            {"role": "system", "content": "You are a helpful financial report writer."},
            {"role": "user", "content": prompt},
        ],
    )
    content = response.choices[0].message.content
    return json.loads(content)


async def generate_report_text(payload: ReportGenerateRequest) -> dict:
    if not settings.GROQ_API_KEY:
        logger.warning("GROQ_API_KEY missing, using fallback")
        return _fallback(payload.language, payload.credit_score, payload.grade)

    prompt = build_prompt(payload)
    client = AsyncGroq(api_key=settings.GROQ_API_KEY)

    try:
        parsed = await _call_groq_api(client, prompt)
        explanation = parsed.get("explanation", "")
        suggestions = parsed.get("suggestions", [])
        if not explanation or len(suggestions) < 3:
            logger.warning("Groq response incomplete, using fallback")
            return _fallback(payload.language, payload.credit_score, payload.grade)
        return {
            "status": "success",
            "language": payload.language,
            "explanation": explanation,
            "suggestions": suggestions[:3],
            "model_used": "llama-3.3-70b-versatile",
        }
    except Exception as e:
        logger.error(f"Groq API call failed after retries: {e}")
        return _fallback(payload.language, payload.credit_score, payload.grade)
