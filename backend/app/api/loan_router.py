from fastapi import APIRouter
from pydantic import BaseModel
from typing import Dict, Any

router = APIRouter()

@router.post("/products")
async def get_products(req: Dict[str, Any]):
    score = req.get("score", 600)
    products = []
    if score >= 450:
        products.append({"id": "emergency_micro", "name": "Emergency Micro", "max_amount": 25000})
    if score >= 550:
        products.append({"id": "income_bridge", "name": "Income Bridge", "max_amount": 100000})
    if score >= 650:
        products.append({"id": "growth", "name": "Growth Loan", "max_amount": 500000})
        
    return {"eligible_products": products}

@router.post("/kfs")
async def generate_kfs(req: Dict[str, Any]):
    amount = req.get("amount", 10000)
    tenure = req.get("tenure", 6)
    return {
        "amount": amount,
        "tenure": tenure,
        "apr": 18.0,
        "emi": (amount * 1.09) / tenure,
        "total_payable": amount * 1.09,
        "processing_fee": 500
    }

@router.post("/apply")
async def apply_loan(req: Dict[str, Any]):
    score = req.get("score", 600)
    if score < 450:
        return {
            "decision": "rejected", 
            "aan": {"reason": "Credit score below minimum requirement."}, 
            "counterfactuals": [
                {"action": "Reduce requested amount by 50%", "result": "Approved"},
                {"action": "Increase loan term by 6 months", "result": "Approved"},
                {"action": "Maintain payment streak for 2 more months", "result": "Approved"}
            ]
        }
    return {"decision": "approved", "loan_id": "L123456"}

@router.get("/decision/{loan_id}")
async def get_decision(loan_id: str):
    return {"loan_id": loan_id, "status": "approved"}
