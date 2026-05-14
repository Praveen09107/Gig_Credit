from fastapi import APIRouter
from pydantic import BaseModel
from typing import Dict, Any
from app.utils.loan_products import LOAN_PRODUCTS
from app.services.hard_rules import HardRulesEngine
from app.services.affordability import AffordabilityEngine
from app.services.audit_trail import audit_trail_service
import uuid
import datetime

router = APIRouter()
hard_rules_engine = HardRulesEngine(LOAN_PRODUCTS)
affordability_engine = AffordabilityEngine(LOAN_PRODUCTS)

@router.post("/products")
async def get_products(req: Dict[str, Any]):
    score = int(req.get("score", 600))
    products = []
    
    for pid, product in LOAN_PRODUCTS.items():
        if score >= product["min_score"]:
            products.append({
                "id": pid,
                "name": product["display_name"],
                "description": product["description"],
                "max_amount": product["amount_range"][1],
                "min_amount": product["amount_range"][0],
                "tenures": product["tenure_options"],
                "apr": product["apr_by_score_band"]
            })
            
    return {"eligible_products": products}

@router.post("/kfs")
async def generate_kfs(req: Dict[str, Any]):
    amount = float(req.get("amount", 10000))
    tenure = int(req.get("tenure", 6))
    product_id = req.get("product_id", "emergency_advance")
    product = LOAN_PRODUCTS.get(product_id, LOAN_PRODUCTS["emergency_advance"])
    
    score = int(req.get("score", 600))
    apr = 18.0
    for band, rate in product["apr_by_score_band"].items():
        lo = int(band.split("-")[0].rstrip("+"))
        if score >= lo:
            apr = float(rate.rstrip("%"))
            break
            
    monthly_r = apr / 12 / 100
    if monthly_r > 0:
        emi = (amount * monthly_r * (1 + monthly_r)**tenure) / ((1 + monthly_r)**tenure - 1)
    else:
        emi = amount / tenure
        
    proc_fee_pct = float(product.get("processing_fee_pct", 2.0)) / 100
    proc_fee = max(amount * proc_fee_pct, float(product.get("processing_fee_min", 100)))
    
    return {
        "amount": amount,
        "tenure": tenure,
        "apr": apr,
        "emi": round(emi, 2),
        "total_payable": round(emi * tenure + proc_fee * 1.18, 2),
        "processing_fee": proc_fee
    }

@router.post("/apply")
async def apply_loan(req: Dict[str, Any]):
    try:
        application = req.get("application", {})
        score_report = req.get("score_report", {})
        product_id = application.get("product_id", "emergency_advance")
        loan_id = f"L{uuid.uuid4().hex[:8].upper()}"
        
        decision_payload = {}

        # Safe vars() conversion that handles non-serializable fields
        def safe_vars(obj):
            d = vars(obj)
            result = {}
            for k, v in d.items():
                if v is None or isinstance(v, (str, int, float, bool, list, dict)):
                    result[k] = v
                else:
                    result[k] = str(v)
            return result

        hr_outcome = hard_rules_engine.evaluate(application, score_report, product_id)
        if not hr_outcome.all_passed:
            failure = hr_outcome.first_failure
            decision_payload = {
                "decision": "rejected",
                "rejection_bucket": "HARD_RULE",
                "reason": failure.reason,
                "remediation": failure.remediation,
                "counter_offer": failure.counter_offer,
                "hard_rules": [safe_vars(r) for r in hr_outcome.results]
            }
            audit_trail_service.append_record(loan_id, decision_payload, score_report, application)
            return decision_payload
            
        aff_result = affordability_engine.compute(application, score_report, product_id)
        if not aff_result.passed:
            decision_payload = {
                "decision": "rejected",
                "rejection_bucket": "AFFORDABILITY",
                "reason": aff_result.rejection_reason,
                "counter_offer": aff_result.counter_offer,
                "affordability_metrics": safe_vars(aff_result)
            }
            audit_trail_service.append_record(loan_id, decision_payload, score_report, application)
            return decision_payload
            
        repayment_prob = 0.85
        if repayment_prob < 0.65:
            decision_payload = {
                "decision": "rejected",
                "rejection_bucket": "MODEL_SCORED",
                "reason": "Our AI model predicts a higher risk of repayment difficulties based on your financial behaviour."
            }
            audit_trail_service.append_record(loan_id, decision_payload, score_report, application)
            return decision_payload
            
        decision_payload = {
            "decision": "approved",
            "loan_id": loan_id,
            "details": {
                "approved_amount": application.get("loan_amount", application.get("amount")),
                "emi": aff_result.proposed_emi,
                "apr": aff_result.adjusted_apr,
                "tenure": application.get("tenure_months", application.get("tenure"))
            }
        }
        audit_trail_service.append_record(loan_id, decision_payload, score_report, application)
        return decision_payload
    except Exception as e:
        import traceback
        traceback.print_exc()
        return {
            "decision": "error",
            "reason": f"Loan processing error: {str(e)}",
            "loan_id": f"L{uuid.uuid4().hex[:8].upper()}"
        }

@router.get("/decision/{loan_id}")
async def get_decision(loan_id: str):
    return {"loan_id": loan_id, "status": "approved"}


