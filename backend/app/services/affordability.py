from dataclasses import dataclass
from typing import Optional
import numpy as np

@dataclass
class AffordabilityResult:
    passed: bool
    net_monthly_income: float
    existing_emi_total: float
    proposed_emi: float
    post_loan_emi_ratio: float
    proposed_dscr: float
    loan_to_income: float
    base_apr: float
    adjusted_apr: float
    processing_fee: float
    total_cost_of_credit: float
    effective_apr: float
    max_eligible_amount: int
    max_eligible_emi: float
    rejection_type: Optional[str] = None
    rejection_reason: Optional[str] = None
    counter_offer: Optional[dict] = None

class AffordabilityEngine:
    def __init__(self, products: dict):
        self.products = products

    def compute(self, application: dict, score_report: dict, product_id: str) -> AffordabilityResult:
        product = self.products.get(product_id)
        if not product:
            raise ValueError("Invalid product ID")

        score = int(score_report.get("final_score", score_report.get("finalScore", 0)))
        features = score_report.get("feature_snapshot", {})

        income = float(application.get("net_monthly_income", 15000))
        ex_emi = float(application.get("existing_emi_total", 0))
        amount = float(application.get("loan_amount", 0))
        tenure_mo = int(application.get("tenure_months", 12))
        
        base_apr = self._get_base_apr(score, product)
        adj_apr = self._apply_adjustments(base_apr, features, score)

        monthly_r = adj_apr / 12 / 100
        if monthly_r > 0:
            proposed_emi = (amount * monthly_r * (1 + monthly_r)**tenure_mo / ((1 + monthly_r)**tenure_mo - 1))
        else:
            proposed_emi = amount / tenure_mo

        total_emi = ex_emi + proposed_emi
        post_loan_ratio = total_emi / income if income > 0 else 1.0
        dscr = income / total_emi if total_emi > 0 else 99.0
        lti = amount / income if income > 0 else 99.0

        proc_fee_pct = float(product.get("processing_fee_pct", 2.0)) / 100
        proc_fee = max(amount * proc_fee_pct, float(product.get("processing_fee_min", 100)))
        gst_on_fee = proc_fee * 0.18
        total_cost = proposed_emi * tenure_mo + proc_fee + gst_on_fee

        cashflows = [-amount] + [proposed_emi] * tenure_mo
        eff_apr = self._compute_irr(cashflows) * 12 * 100

        emi_cap = float(product.get("emi_ratio_cap", 0.50))
        max_emi = income * emi_cap - ex_emi
        max_by_dscr = income / float(product.get("dscr_threshold", 1.40)) - ex_emi
        max_emi = min(max_emi, max_by_dscr)
        max_by_lti = income * float(product.get("max_lti_ratio", 6.0))

        if monthly_r > 0 and max_emi > 0:
            n = tenure_mo; r = monthly_r
            max_P_by_emi = max_emi * ((1+r)**n - 1) / (r * (1+r)**n)
        else:
            max_P_by_emi = max_emi * tenure_mo

        max_eligible = int(min(
            max_P_by_emi,
            max_by_lti,
            float(product.get("amount_range", [0, 1e7])[1]),
        ))

        passed = True
        rej_type, rej_reason, counter = None, None, None

        if post_loan_ratio > emi_cap:
            passed = False
            rej_type = "AFFORDABILITY"
            rej_reason = f"Your post-loan EMI-to-income ratio would be {post_loan_ratio:.0%}, exceeding the maximum of {int(emi_cap*100)}%. Based on your income, you can borrow up to ₹{max_eligible:,}."
            counter = {
                "type": "reduce_amount",
                "max_amount": max_eligible,
                "message": f"You can comfortably borrow up to ₹{max_eligible:,}."
            }
        elif lti > float(product.get("max_lti_ratio", 6.0)):
            passed = False
            rej_type = "AFFORDABILITY"
            rej_reason = f"Requested amount exceeds the maximum loan-to-income ratio of {product['max_lti_ratio']}× your monthly income."
            counter = {
                "type": "reduce_amount",
                "max_amount": int(income * product["max_lti_ratio"]),
                "message": f"Maximum eligible: ₹{int(income * product['max_lti_ratio']):,} ({product['max_lti_ratio']}× monthly income)."
            }

        return AffordabilityResult(
            passed=passed,
            net_monthly_income=income,
            existing_emi_total=ex_emi,
            proposed_emi=round(proposed_emi, 2),
            post_loan_emi_ratio=round(post_loan_ratio, 4),
            proposed_dscr=round(dscr, 3),
            loan_to_income=round(lti, 3),
            base_apr=base_apr,
            adjusted_apr=round(adj_apr, 2),
            processing_fee=round(proc_fee, 2),
            total_cost_of_credit=round(total_cost, 2),
            effective_apr=round(eff_apr, 2),
            max_eligible_amount=max_eligible,
            max_eligible_emi=round(max_emi, 2),
            rejection_type=rej_type,
            rejection_reason=rej_reason,
            counter_offer=counter,
        )

    def _get_base_apr(self, score: int, product: dict) -> float:
        bands = product.get("apr_by_score_band", {})
        for band, rate in sorted(bands.items(), key=lambda x: -int(x[0].split("-")[0].rstrip("+"))):
            lo = int(band.split("-")[0].rstrip("+"))
            if score >= lo:
                return float(rate.rstrip("%"))
        return float(list(bands.values())[-1].rstrip("%"))

    def _apply_adjustments(self, base: float, features: dict, score: int) -> float:
        adj = base
        if float(features.get("P2", 0.5)) < 0.50:
            adj += 2.0
        if float(features.get("P4", 0.5)) < 0.40:
            adj += 1.5
        if 1.0 - float(features.get("income_stability_cv", 0.5)) < 0.50:
            adj += 1.0
        if float(features.get("eshram_enrolled", 0)) == 1.0:
            adj -= 0.5
        if float(features.get("itr_filed_this_year", 0)) == 1.0:
            adj -= 0.5
        if float(features.get("health_insurance_active", 0)) == 1.0:
            adj -= 1.0
        if score >= 750:
            adj -= 1.0
        return max(adj, 10.0)

    @staticmethod
    def _compute_irr(cashflows: list) -> float:
        rate = 0.01
        for _ in range(200):
            npv = sum(cf / (1 + rate)**i for i, cf in enumerate(cashflows))
            npv_d = sum(-i * cf / (1 + rate)**(i + 1) for i, cf in enumerate(cashflows))
            if abs(npv_d) < 1e-10:
                break
            rate -= npv / npv_d
            rate = max(0.0001, min(rate, 10.0))
        return rate
