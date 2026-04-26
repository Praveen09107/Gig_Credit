from app.schemas.report_schemas import ReportGenerateRequest


def build_prompt(payload: ReportGenerateRequest) -> str:
    positives = payload.positive_factors[:3]
    negatives = payload.negative_factors[:3]

    pos_lines = "\n".join(
        [f"{idx + 1}. {f.feature_label} (Impact: +{f.impact})" for idx, f in enumerate(positives)]
    )
    neg_lines = "\n".join(
        [f"{idx + 1}. {f.feature_label} (Impact: {f.impact})" for idx, f in enumerate(negatives)]
    )

    return f"""You are a financial advisor for Indian gig workers.

A gig worker has been assessed using alternative financial data.
Credit Score: {payload.credit_score}/900 (Grade: {payload.grade}, Risk: {payload.risk_level})
Work Type: {payload.work_type}

Strongest financial behaviors:
{pos_lines if pos_lines else '1. Consistent profile data'}

Areas needing improvement:
{neg_lines if neg_lines else '1. Improve financial consistency'}

Write your response in {payload.language} language.
Respond ONLY as JSON with this schema:
{{"explanation":"4-5 simple sentences","suggestions":["action 1","action 2","action 3"]}}
"""
