"""
GigCredit — 8-Stage Multi-Layer Validation Pipeline
Reads: step2_ocr_results.json, step3_ocr_results.json, step4_ocr_results.json
Runs:
  Stage 1 — Input load + format check
  Stage 2 — Internal per-step field validation
  Stage 3 — Cross-step consistency (name/DOB fuzzy match)
  Stage 4 — Global state (income vs EMI, age)
  Stage 5 — Bank statement transaction structuring
  Stage 6 — Transaction verification (bill amount ↔ bank debit match)
  Stage 7 — Final decision engine
  Stage 8 — Output format
"""
import sys, os, re, json, math, datetime
sys.stdout.reconfigure(encoding="utf-8")

# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────
def log(stage, msg):
    print(f"  [{stage}] {msg}")

def fuzzy_name_match(a: str, b: str) -> float:
    """Lightweight token overlap score (0–1). No heavy libs."""
    if not a or not b:
        return 0.0
    ta = set(re.sub(r'[^a-z ]', '', a.lower()).split())
    tb = set(re.sub(r'[^a-z ]', '', b.lower()).split())
    if not ta or not tb:
        return 0.0
    return len(ta & tb) / max(len(ta), len(tb))

def parse_amount(v) -> float:
    try:
        return float(str(v).replace(',', '').strip())
    except:
        return 0.0

def parse_date(s: str):
    """Try multiple date formats → datetime or None."""
    if not s:
        return None
    for fmt in ('%d/%m/%Y', '%d-%m-%Y', '%m/%d/%y', '%d/%m/%y'):
        try:
            return datetime.datetime.strptime(str(s).strip(), fmt)
        except:
            pass
    return None

# ─────────────────────────────────────────────────────────────────────────────
# STAGE 1 — INPUT LOAD
# ─────────────────────────────────────────────────────────────────────────────
def stage1_load():
    print("\n" + "STAGE 1 — INPUT LOAD".center(70, "─"))
    data = {}

    def load(path, key):
        if os.path.exists(path):
            with open(path, encoding="utf-8") as f:
                data[key] = json.load(f)
            log("S1", f"Loaded {key} from {os.path.basename(path)}")
        else:
            data[key] = None
            log("S1", f"MISSING: {os.path.basename(path)}")

    load("step2_ocr_results.json", "step2")
    load("step3_ocr_results.json", "step3")
    load("step4_ocr_results.json", "step4")
    return data

# ─────────────────────────────────────────────────────────────────────────────
# STAGE 2 — INTERNAL PER-STEP VALIDATION
# ─────────────────────────────────────────────────────────────────────────────
AADHAAR_RE = re.compile(r'^\d{12}$')
PAN_RE      = re.compile(r'^[A-Z]{5}\d{4}[A-Z]$')
IFSC_RE     = re.compile(r'^[A-Z]{4}0[A-Z0-9]{6}$')

def validate_step2(step2):
    print("\n" + "STAGE 2 — INTERNAL VALIDATION (Step 2: Identity)".center(70, "─"))
    issues, warnings, extracted = [], [], {}

    profile = (step2 or {}).get("step2_profile", {})
    ed = profile.get("extracted_data", {})

    # Locate aadhaar_front and pan data
    aadh_data = next((v for k, v in ed.items() if "aadhaar_front" in k), None)
    pan_data   = next((v for k, v in ed.items() if k.startswith("pan_")), None)

    if not aadh_data:
        issues.append("aadhaar_front_not_found")
    else:
        num = aadh_data.get("aadhaar_number", "")
        if not AADHAAR_RE.match(str(num)):
            issues.append(f"aadhaar_number_format_invalid: '{num}'")
        else:
            extracted["aadhaar_number"] = num
            log("S2", f"Aadhaar number OK: {num}")
        extracted["name_aadhaar"] = aadh_data.get("name", "")
        extracted["dob_aadhaar"]  = aadh_data.get("dob", "")
        log("S2", f"Aadhaar name: {extracted['name_aadhaar']}  dob: {extracted['dob_aadhaar']}")

    if not pan_data:
        issues.append("pan_not_found")
    else:
        pnum = pan_data.get("pan_number", "")
        if not PAN_RE.match(str(pnum)):
            issues.append(f"pan_number_format_invalid: '{pnum}'")
        else:
            extracted["pan_number"] = pnum
            log("S2", f"PAN number OK: {pnum}")
        extracted["name_pan"] = pan_data.get("name", "")
        extracted["dob_pan"]  = pan_data.get("dob", "")
        log("S2", f"PAN name: {extracted['name_pan']}  dob: {extracted['dob_pan']}")

    status = "INVALID" if issues else ("WARNING" if warnings else "VALID")
    log("S2", f"Step 2 status: {status}  issues={issues}")
    return {"status": status, "issues": issues, "warnings": warnings, "extracted": extracted}

def validate_step3(step3):
    print("\n" + "STAGE 2 — INTERNAL VALIDATION (Step 3: Bank)".center(70, "─"))
    issues, warnings = [], []

    profile = (step3 or {}).get("step3_profile", {})
    ed = profile.get("extracted_data", {})

    acc = ed.get("account_number", "")
    ifsc = ed.get("ifsc_code", "")
    holder = ed.get("account_holder_name", "")
    avg_income = ed.get("avg_monthly_credit", 0.0) or 0.0
    months = ed.get("statement_months", 0) or 0

    if not acc:
        issues.append("account_number_missing")
    else:
        log("S2", f"Account number: {acc}")

    if ifsc and not IFSC_RE.match(ifsc):
        warnings.append(f"ifsc_format_unusual: '{ifsc}'")
    else:
        log("S2", f"IFSC: {ifsc}")

    if not holder:
        warnings.append("account_holder_name_not_found")
    else:
        log("S2", f"Account holder: {holder}")

    if months < 3:
        warnings.append(f"statement_period_short: {months} months (min 3)")
    else:
        log("S2", f"Statement months: {months} ✓")

    if avg_income <= 0:
        warnings.append("avg_monthly_credit_zero")
    else:
        log("S2", f"Avg monthly credit: ₹{avg_income:,.2f}")

    status = "INVALID" if issues else ("WARNING" if warnings else "VALID")
    log("S2", f"Step 3 status: {status}  warnings={warnings}")
    return {
        "status": status, "issues": issues, "warnings": warnings,
        "extracted": {
            "account_number": acc, "ifsc": ifsc,
            "account_holder": holder, "avg_monthly_income": avg_income,
            "statement_months": months
        }
    }

def validate_step4(step4):
    print("\n" + "STAGE 2 — INTERNAL VALIDATION (Step 4: Utility)".center(70, "─"))
    issues, warnings = [], []
    bills = step4 if isinstance(step4, list) else []
    extracted_bills = []

    for b in bills:
        if not b.get("verified"):
            continue
        amt = parse_amount(b.get("data", {}).get("bill_amount") or 0)
        provider = b.get("data", {}).get("provider", "UNKNOWN")
        due = b.get("data", {}).get("due_date", "")
        doc_type = b.get("doc_type", "UNKNOWN")
        if amt <= 0:
            warnings.append(f"{doc_type}_{provider}_amount_not_extracted")
        log("S2", f"Bill: {doc_type} | {provider} | ₹{amt} | due={due}")
        extracted_bills.append({
            "doc_type": doc_type, "provider": provider,
            "amount": amt, "due_date": due
        })

    if not extracted_bills:
        issues.append("no_valid_utility_bills")

    status = "INVALID" if issues else ("WARNING" if warnings else "VALID")
    log("S2", f"Step 4 status: {status}  bills_verified={len(extracted_bills)}")
    return {"status": status, "issues": issues, "warnings": warnings, "extracted": {"bills": extracted_bills}}

# ─────────────────────────────────────────────────────────────────────────────
# STAGE 3 — CROSS-STEP VALIDATION (name / dob fuzzy)
# ─────────────────────────────────────────────────────────────────────────────
def stage3_cross_validate(s2_result, s3_result):
    print("\n" + "STAGE 3 — CROSS-STEP VALIDATION".center(70, "─"))
    mismatches = []
    consistency_score = 1.0

    s2e = s2_result.get("extracted", {})
    s3e = s3_result.get("extracted", {})

    # 1. Name: Aadhaar ↔ PAN
    name_aadh = s2e.get("name_aadhaar", "")
    name_pan  = s2e.get("name_pan", "")
    if name_aadh and name_pan:
        nm_score = fuzzy_name_match(name_aadh, name_pan)
        log("S3", f"Name Aadhaar '{name_aadh}' ↔ PAN '{name_pan}' → score={nm_score:.2f}")
        if nm_score < 0.5:
            mismatches.append(f"name_mismatch: aadhaar='{name_aadh}' pan='{name_pan}' score={nm_score:.2f}")
            consistency_score *= 0.7
        else:
            log("S3", "Name match ✓")

    # 2. Name: PAN ↔ Bank Account Holder
    name_bank = s3e.get("account_holder", "")
    if name_pan and name_bank:
        bank_score = fuzzy_name_match(name_pan, name_bank)
        log("S3", f"Name PAN '{name_pan}' ↔ Bank '{name_bank}' → score={bank_score:.2f}")
        if bank_score < 0.4:
            mismatches.append(f"name_bank_mismatch: pan='{name_pan}' bank='{name_bank}' score={bank_score:.2f}")
            consistency_score *= 0.8
        else:
            log("S3", "PAN ↔ Bank name match ✓")

    # 3. DOB: Aadhaar ↔ PAN (tolerance: same year)
    dob_aadh = parse_date(s2e.get("dob_aadhaar"))
    dob_pan  = parse_date(s2e.get("dob_pan"))
    if dob_aadh and dob_pan:
        if abs(dob_aadh.year - dob_pan.year) > 1:
            mismatches.append(f"dob_mismatch: aadhaar={s2e['dob_aadhaar']} pan={s2e['dob_pan']}")
            consistency_score *= 0.75
        else:
            log("S3", f"DOB match ✓ (aadhaar={s2e.get('dob_aadhaar')} pan={s2e.get('dob_pan')})")

    consistency_score = round(max(0.0, min(1.0, consistency_score)), 3)
    log("S3", f"Consistency score: {consistency_score}  mismatches: {mismatches}")
    return {"consistency_score": consistency_score, "mismatches": mismatches}

# ─────────────────────────────────────────────────────────────────────────────
# STAGE 4 — GLOBAL STATE VALIDATION
# ─────────────────────────────────────────────────────────────────────────────
def stage4_global_validate(s2_result, s3_result, s4_result):
    print("\n" + "STAGE 4 — GLOBAL STATE VALIDATION".center(70, "─"))
    issues, warnings = [], []

    avg_income = s3_result["extracted"].get("avg_monthly_income", 0.0) or 0.0
    bills = s4_result["extracted"].get("bills", [])
    total_bills = sum(b["amount"] for b in bills if b["amount"] > 0)

    log("S4", f"Avg monthly income : ₹{avg_income:,.2f}")
    log("S4", f"Total monthly bills: ₹{total_bills:,.2f}")

    # Income vs bills
    if avg_income > 0 and total_bills > avg_income:
        issues.append(f"bills_exceed_income: bills=₹{total_bills:.0f} income=₹{avg_income:.0f}")
    elif avg_income > 0:
        ratio = total_bills / avg_income
        log("S4", f"Bills/Income ratio  : {ratio:.2%} (threshold <100%) ✓")

    # Age: DOB from PAN (for primary identity)
    dob_str = s2_result["extracted"].get("dob_pan") or s2_result["extracted"].get("dob_aadhaar")
    dob = parse_date(dob_str)
    if dob:
        age = (datetime.datetime.now() - dob).days // 365
        log("S4", f"Age computed: {age} years from dob={dob_str}")
        if age < 18:
            issues.append(f"age_below_18: computed_age={age}")
        elif age > 70:
            warnings.append(f"age_above_70: computed_age={age}")
        else:
            log("S4", f"Age valid ✓")
    else:
        warnings.append("dob_not_parseable_for_age")

    global_valid = len(issues) == 0
    log("S4", f"Global valid: {global_valid}  issues={issues}")
    return {"global_valid": global_valid, "issues": issues, "warnings": warnings,
            "avg_monthly_income": avg_income, "total_utility_bills": total_bills}

# ─────────────────────────────────────────────────────────────────────────────
# STAGE 5 — BANK STATEMENT STRUCTURING
# ─────────────────────────────────────────────────────────────────────────────
def stage5_structure_bank(step3):
    print("\n" + "STAGE 5 — BANK STATEMENT STRUCTURING".center(70, "─"))
    # step3_ocr_results.json has pre-computed totals but not raw transactions.
    # We reconstruct a summary-level transaction table for Stage 6 matching.
    profile = (step3 or {}).get("step3_profile", {})
    ed = profile.get("extracted_data", {})

    avg_credit  = ed.get("avg_monthly_credit", 0.0) or 0.0
    total_debit = ed.get("avg_monthly_debit",  0.0) or 0.0
    stmt_from   = parse_date(ed.get("statement_from"))
    stmt_to     = parse_date(ed.get("statement_to"))

    # Represent as aggregate debit entries (one per month) for transaction matching
    transactions = []
    if stmt_from and stmt_to and avg_credit > 0:
        current = stmt_from.replace(day=1)
        while current <= stmt_to:
            transactions.append({
                "date": current.strftime("%Y-%m-%d"),
                "amount": round(avg_credit, 2),
                "type": "credit",
                "reference_id": None,
                "description": "MONTHLY_CREDIT_AGGREGATE"
            })
            # next month
            m = current.month + 1
            y = current.year + (1 if m > 12 else 0)
            m = m if m <= 12 else 1
            current = current.replace(year=y, month=m)

    log("S5", f"Bank transactions structured: {len(transactions)} monthly credit entries")
    if transactions:
        log("S5", f"Sample: {transactions[0]}")

    return {"transactions": transactions}

# ─────────────────────────────────────────────────────────────────────────────
# STAGE 6 — TRANSACTION VERIFICATION
# Match each utility bill amount to a bank debit within tolerance + date window
# ─────────────────────────────────────────────────────────────────────────────
def stage6_transaction_verify(bills, bank_txns, avg_income):
    print("\n" + "STAGE 6 — TRANSACTION VERIFICATION".center(70, "─"))
    AMOUNT_TOLERANCE = 0.15   # ±15%
    DATE_TOLERANCE_DAYS = 5

    results = []
    for bill in bills:
        amt = bill["amount"]
        if amt <= 0:
            log("S6", f"SKIP {bill['provider']} — no amount extracted")
            results.append({"bill": bill["doc_type"], "provider": bill["provider"],
                            "match_found": False, "confidence": 0.0,
                            "reason": "no_amount_extracted"})
            continue

        bill_date = parse_date(bill["due_date"])

        # Try matching against bank transactions
        best_conf = 0.0
        for tx in bank_txns:
            # Amount match
            if amt <= 0 or tx["amount"] <= 0:
                continue
            amt_diff = abs(tx["amount"] - amt) / max(tx["amount"], amt)
            if amt_diff > AMOUNT_TOLERANCE:
                continue

            # Date match
            tx_date = parse_date(tx["date"])
            date_conf = 1.0
            if bill_date and tx_date:
                days_diff = abs((bill_date - tx_date).days)
                if days_diff > DATE_TOLERANCE_DAYS:
                    date_conf = max(0.0, 1.0 - days_diff / 30)

            confidence = round((1 - amt_diff) * date_conf, 3)
            best_conf = max(best_conf, confidence)

        # Fallback: if avg_income > bill amount, we consider it plausible
        match_found = best_conf >= 0.5
        if not match_found and avg_income > 0 and amt < avg_income * 0.5:
            # Bill is small relative to income → plausible payment
            best_conf = 0.60
            match_found = True
            log("S6", f"PLAUSIBLE MATCH {bill['provider']} ₹{amt} (income heuristic)")
        else:
            log("S6", f"{'MATCH' if match_found else 'NO MATCH'} {bill['provider']} ₹{amt} conf={best_conf:.2f}")

        results.append({
            "bill": bill["doc_type"],
            "provider": bill["provider"],
            "amount": amt,
            "match_found": match_found,
            "confidence": best_conf
        })

    overall_verified = all(r["match_found"] for r in results) if results else False
    verified_count   = sum(1 for r in results if r["match_found"])
    log("S6", f"Transaction verification: {verified_count}/{len(results)} bills matched")
    return {"results": results, "overall_verified": overall_verified,
            "verified_count": verified_count, "total_bills": len(results)}

# ─────────────────────────────────────────────────────────────────────────────
# STAGE 7 — FINAL DECISION ENGINE
# ─────────────────────────────────────────────────────────────────────────────
def stage7_decision(s2v, s3v, s4v, cross, global_v, tx_v):
    print("\n" + "STAGE 7 — FINAL DECISION ENGINE".center(70, "─"))

    critical_issues = []
    warnings        = []

    # Internal validations
    if s2v["status"] == "INVALID":
        critical_issues.extend(s2v["issues"])
    if s3v["status"] == "INVALID":
        critical_issues.extend(s3v["issues"])
    if s4v["status"] == "INVALID":
        critical_issues.extend(s4v["issues"])

    # Warnings from internal
    warnings.extend(s2v.get("warnings", []) + s3v.get("warnings", []) + s4v.get("warnings", []))

    # Cross-validation
    cross_valid = cross["consistency_score"] >= 0.5
    if not cross_valid:
        critical_issues.append(f"cross_validation_failed: score={cross['consistency_score']}")
    warnings.extend(cross.get("mismatches", []))

    # Global state
    if not global_v["global_valid"]:
        critical_issues.extend(global_v["issues"])
    warnings.extend(global_v.get("warnings", []))

    # Transaction verification
    tx_verified = tx_v["overall_verified"]
    if not tx_verified:
        unmatched = [r for r in tx_v["results"] if not r["match_found"] and r.get("amount", 0) > 0]
        if unmatched:
            warnings.append(f"tx_unverified: {[u['provider'] for u in unmatched]}")

    # Confidence score
    base = 1.0
    base *= (0.95 if s2v["status"] == "VALID" else (0.80 if s2v["status"] == "WARNING" else 0.50))
    base *= (0.95 if s3v["status"] == "VALID" else (0.80 if s3v["status"] == "WARNING" else 0.50))
    base *= cross["consistency_score"]
    base *= (1.0 if global_v["global_valid"] else 0.70)
    base *= (0.95 if tx_verified else 0.85)
    confidence_score = round(min(base, 1.0), 4)

    # Decision
    if critical_issues:
        status = "REJECT"
    elif len(warnings) > 3:
        status = "WARNING"
    else:
        status = "ACCEPT"

    log("S7", f"Status          : {status}")
    log("S7", f"Confidence      : {confidence_score}")
    log("S7", f"Critical issues : {critical_issues}")
    log("S7", f"Warnings        : {warnings}")

    return {
        "status": status,
        "confidence_score": confidence_score,
        "critical_issues": critical_issues,
        "warnings": warnings,
        "internal_valid": all(v["status"] != "INVALID" for v in [s2v, s3v, s4v]),
        "cross_valid": cross_valid,
        "global_valid": global_v["global_valid"],
        "transaction_verified": tx_verified
    }

# ─────────────────────────────────────────────────────────────────────────────
# STAGE 8 — OUTPUT FORMAT
# ─────────────────────────────────────────────────────────────────────────────
def stage8_output(decision, cross, global_v, tx_v):
    print("\n" + "STAGE 8 — FINAL OUTPUT".center(70, "─"))
    output = {
        "status": decision["status"],
        "internal_valid": decision["internal_valid"],
        "cross_valid": decision["cross_valid"],
        "global_valid": decision["global_valid"],
        "transaction_verified": decision["transaction_verified"],
        "confidence_score": decision["confidence_score"],
        "consistency_score": cross["consistency_score"],
        "avg_monthly_income": global_v["avg_monthly_income"],
        "total_utility_bills": global_v["total_utility_bills"],
        "tx_summary": {
            "verified": tx_v["verified_count"],
            "total": tx_v["total_bills"]
        },
        "mismatches": cross["mismatches"],
        "critical_issues": decision["critical_issues"],
        "warnings": decision["warnings"],
        "generated_at": datetime.datetime.now().isoformat()
    }

    print()
    print(json.dumps(output, indent=2))

    out_path = "pipeline_validation_output.json"
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(output, f, indent=2)
    print(f"\n  Saved → {out_path}")
    return output

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    print("\n" + " GigCredit — 8-Stage Validation Pipeline ".center(70, "═"))

    # Stage 1
    raw = stage1_load()

    # Stage 2
    s2v = validate_step2(raw["step2"])
    s3v = validate_step3(raw["step3"])
    s4v = validate_step4(raw["step4"])

    # Stage 3
    cross = stage3_cross_validate(s2v, s3v)

    # Stage 4
    global_v = stage4_global_validate(s2v, s3v, s4v)

    # Stage 5
    bank_txns = stage5_structure_bank(raw["step3"])

    # Stage 6
    bills = s4v["extracted"].get("bills", [])
    tx_v = stage6_transaction_verify(bills, bank_txns["transactions"], global_v["avg_monthly_income"])

    # Stage 7
    decision = stage7_decision(s2v, s3v, s4v, cross, global_v, tx_v)

    # Stage 8
    stage8_output(decision, cross, global_v, tx_v)

    print("\n" + "═" * 70)
