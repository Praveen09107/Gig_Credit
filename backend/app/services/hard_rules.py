from dataclasses import dataclass
from typing import Optional, List
from datetime import datetime, timedelta

@dataclass
class HardRuleResult:
    passed: bool
    rule_code: str
    rule_name: str
    rejection_type: Optional[str] = None
    aan_code: Optional[str] = None
    reason: Optional[str] = None
    remediation: Optional[str] = None
    counter_offer: Optional[dict] = None

@dataclass
class HardRulesOutcome:
    all_passed: bool
    results: List[HardRuleResult]
    first_failure: Optional[HardRuleResult] = None
    counter_offer: Optional[dict] = None

class HardRulesEngine:
    def __init__(self, products: dict):
        self.products = products

    def evaluate(self, application: dict, score_report: dict, product_id: str) -> HardRulesOutcome:
        product = self.products.get(product_id)
        if not product:
            raise ValueError("Invalid product ID")

        results = []
        results.append(self._check_kyc(application))
        results.append(self._check_age(application))
        results.append(self._check_bank_months(application))
        results.append(self._check_dscr(application, score_report, product))
        results.append(self._check_score(score_report, product))
        results.append(self._check_kfs(application))
        results.append(self._check_mobile(application))

        failures = [r for r in results if not r.passed]
        counter = None

        if failures:
            first = failures[0]
            if first.rule_code in ("HR-4", "HR-5"):
                counter = self._compute_counter_offer(application, score_report, product, first.rule_code)
                first.counter_offer = counter

            return HardRulesOutcome(
                all_passed=False,
                results=results,
                first_failure=first,
                counter_offer=counter,
            )

        return HardRulesOutcome(all_passed=True, results=results)

    def _check_kyc(self, app: dict) -> HardRuleResult:
        passed = (app.get("aadhaar_verified") in [1.0, 1, True] and app.get("pan_verified") in [1.0, 1, True])
        return HardRuleResult(
            passed=passed,
            rule_code="HR-1",
            rule_name="KYC Verification",
            rejection_type=None if passed else "REGULATORY",
            aan_code=None if passed else "HR-KYC-001",
            reason=None if passed else "Valid Aadhaar and PAN verification required for all loan products.",
            remediation=None if passed else "Complete Aadhaar OTP verification and PAN linking in the app."
        )

    def _check_age(self, app: dict) -> HardRuleResult:
        age = int(app.get("applicant_age", 25)) # Default to 25 if not provided for demo
        passed = 18 <= age <= 65
        return HardRuleResult(
            passed=passed,
            rule_code="HR-2",
            rule_name="Age Gate",
            rejection_type=None if passed else "REGULATORY",
            aan_code=None if passed else "HR-AGE-002",
            reason=None if passed else ("Applicants must be at least 18 years of age." if age < 18 else "Applicants must be below 65 years of age for this product.")
        )

    def _check_bank_months(self, app: dict) -> HardRuleResult:
        months = int(app.get("bank_statement_months", 3)) # Default to 3 for demo
        passed = months >= 3
        return HardRuleResult(
            passed=passed,
            rule_code="HR-3",
            rule_name="Bank Statement Minimum",
            rejection_type=None if passed else "DATA_QUALITY",
            aan_code=None if passed else "HR-BANK-003",
            reason=None if passed else "We need at least 3 months of bank statement data to assess your application.",
            remediation=None if passed else "Upload your last 3–12 months bank statements in the Documents section."
        )

    def _check_dscr(self, app: dict, report: dict, product: dict) -> HardRuleResult:
        income = float(app.get("net_monthly_income", 15000))
        exist_emi = float(app.get("existing_emi_total", 0))
        prop_emi = float(app.get("proposed_emi", 0))
        denom = exist_emi + prop_emi
        dscr = (income / denom) if denom > 0 else 99.0
        threshold = float(product.get("dscr_threshold", 1.40))
        passed = dscr >= threshold

        return HardRuleResult(
            passed=passed,
            rule_code="HR-4",
            rule_name="DSCR Gate",
            rejection_type=None if passed else "REGULATORY",
            aan_code=None if passed else "HR-DSCR-004",
            reason=None if passed else f"Your income relative to existing and proposed loan payments does not meet the minimum Debt Service Coverage Ratio of {threshold}. Your DSCR: {dscr:.2f}."
        )

    def _check_score(self, report: dict, product: dict) -> HardRuleResult:
        score = int(report.get("final_score", 0))
        if score == 0:
            score = int(report.get("finalScore", 0))
        min_score = int(product.get("min_score", 900))
        passed = score >= min_score
        gap = min_score - score

        reason = None
        if not passed:
            reason = f"Your current GigCredit Score ({score}) does not meet the minimum required for this product ({min_score}). "
            if gap <= 30:
                reason += f"You are only {gap} points away — take the recommended actions to qualify quickly."

        return HardRuleResult(
            passed=passed,
            rule_code="HR-5",
            rule_name="Minimum Score",
            rejection_type=None if passed else "MODEL_SCORE",
            aan_code=None if passed else "HR-SCORE-005",
            reason=reason
        )

    def _check_kfs(self, app: dict) -> HardRuleResult:
        ack = app.get("kfs_acknowledged", True) # Default True for demo
        t = app.get("kfs_acknowledged_at")
        fresh = True
        if t:
            try:
                fresh = (datetime.utcnow() - datetime.fromisoformat(t.replace('Z', '+00:00'))) < timedelta(hours=24)
            except:
                pass
        passed = ack and fresh

        return HardRuleResult(
            passed=passed,
            rule_code="HR-6",
            rule_name="KFS Acknowledgement",
            rejection_type=None if passed else "REGULATORY",
            aan_code=None if passed else "HR-KFS-006",
            reason=None if passed else "You must review and acknowledge the Key Fact Statement before applying.",
            remediation=None if passed else "kfs_redirect"
        )

    def _check_mobile(self, app: dict) -> HardRuleResult:
        passed = app.get("mobile_verified", True) # Default True for demo
        return HardRuleResult(
            passed=passed,
            rule_code="HR-7",
            rule_name="Mobile Verification",
            rejection_type=None if passed else "REGULATORY",
            aan_code=None if passed else "HR-MOB-007",
            reason=None if passed else "Mobile number must be verified and linked to your Aadhaar."
        )

    def _compute_counter_offer(self, app: dict, report: dict, product: dict, rule_code: str) -> dict:
        score = int(report.get("final_score", report.get("finalScore", 0)))
        income = float(app.get("net_monthly_income", 15000))
        ex_emi = float(app.get("existing_emi_total", 0))

        if rule_code == "HR-5":
            best_product = None
            for pid, prod in sorted(self.products.items(), key=lambda x: -x[1]["min_score"]):
                if score >= prod["min_score"]:
                    best_product = (pid, prod)
                    break
            if best_product:
                pid, prod = best_product
                max_amount = min(
                    income * prod["max_lti_ratio"],
                    prod.get("amount_range", [0, 100000])[1]
                )
                return {
                    "type": "downgrade_product",
                    "offered_product": pid,
                    "max_amount": int(max_amount),
                    "message": f"You qualify for our {prod['display_name']} with up to ₹{int(max_amount):,}."
                }

        if rule_code == "HR-4":
            threshold = float(product.get("dscr_threshold", 1.40))
            tenure = int(app.get("tenure_months", 12))
            apr = float(app.get("proposed_apr", 0.16))
            monthly_r = apr / 12
            max_emi = (income / threshold) - ex_emi
            if max_emi > 0 and monthly_r > 0:
                n = tenure
                r = monthly_r
                max_P = max_emi * ((1+r)**n - 1) / (r * (1+r)**n)
                max_P = max(0, int(max_P))
                pmin = product.get("amount_range", [0, 0])[0]
                if max_P >= pmin:
                    return {
                        "type": "reduce_amount",
                        "max_amount": max_P,
                        "message": f"Based on your income, you can comfortably borrow up to ₹{max_P:,}."
                    }
        return None
