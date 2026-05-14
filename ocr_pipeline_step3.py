"""
GigCredit — Step 3 Bank Statement OCR Pipeline v2
Fixed transaction parser using PyMuPDF blocks mode for columnar PDFs.
"""
import sys, os, re, json, datetime
from pathlib import Path
sys.stdout.reconfigure(encoding='utf-8')
import fitz

# ─────────────────────────────────────────────────────────────────────────────
BANK_STRONG = ["account statement","bank statement","statement of account",
               "current & saving account","savings account statement"]
BANK_MODERATE = ["account number","ifsc","opening balance","closing balance",
                 "credit","debit","balance","neft","imps","upi","transaction",
                 "hdfc","sbi","icici","axis","kotak","canara","pnb",
                 "union bank","indusind","yes bank","federal","rbl","fsfb"]
BANK_NEGATIVE = ["aadhaar","uidai","income tax","permanent account",
                 "e-shram","eshram","electricity bill","insurance policy"]
BANK_NAME_PAT = [r"(HDFC Bank|Axis Bank|State Bank of India|ICICI Bank|"
                 r"Kotak Mahindra Bank|Punjab National Bank|Canara Bank|"
                 r"Bank of Baroda|IndusInd Bank|Yes Bank|Federal Bank|"
                 r"RBL Bank|IDBI Bank|UCO Bank|Bandhan Bank|"
                 r"City Union Bank|South Indian Bank|Indian Bank|"
                 r"Union Bank of India|Fincare Small Finance Bank|FSFB)"]

def _amount(s):
    try:
        return float(re.sub(r'[^\d.]','', s.replace(',','')))
    except:
        return None

# ─────────────────────────────────────────────────────────────────────────────
# STEP 1: Quality
# ─────────────────────────────────────────────────────────────────────────────
def check_quality(path):
    try:
        doc = fitz.open(path)
        n = len(doc); doc.close()
        if n == 0: return {"passed":False,"reason":"EMPTY_PDF"}
        return {"passed":True,"page_count":n,
                "file_size_kb":round(os.path.getsize(path)/1024,1)}
    except Exception as e:
        return {"passed":False,"reason":str(e)}

# ─────────────────────────────────────────────────────────────────────────────
# STEP 2: Extract text using BLOCKS mode (preserves columns)
# ─────────────────────────────────────────────────────────────────────────────
def extract_text_blocks(path):
    doc = fitz.open(path)
    all_blocks = []   # list of {y, text, page}
    all_lines  = []

    for pg_idx, page in enumerate(doc):
        blocks = page.get_text("blocks")
        for b in blocks:
            raw = b[4].strip()
            if not raw: continue
            # Flatten block text into one string (pipes between sub-lines)
            flat = " | ".join(l.strip() for l in raw.splitlines() if l.strip())
            all_blocks.append({"y": b[1], "text": flat, "page": pg_idx+1})
            # Also collect individual lines for header parsing
            for l in raw.splitlines():
                l = l.strip()
                if l: all_lines.append(l)

    total_pages = len(all_blocks)  # approximate
    doc.close()
    return {"blocks": all_blocks, "all_lines": all_lines,
            "total_lines": len(all_lines), "total_pages": total_pages}

# ─────────────────────────────────────────────────────────────────────────────
# STEP 3: Classify
# ─────────────────────────────────────────────────────────────────────────────
def classify(all_lines):
    txt = " ".join(all_lines).lower()
    if sum(1 for k in BANK_NEGATIVE if k in txt) >= 2:
        return ("UNKNOWN", 0.0)
    score = sum(0.30 for k in BANK_STRONG if k in txt)
    score += min(sum(0.05 for k in BANK_MODERATE if k in txt), 0.55)
    if re.search(r'\b[A-Z]{4}0[A-Z0-9]{6}\b'," ".join(all_lines)): score += 0.10
    score = min(score, 1.0)
    return ("bank_statement", round(score,2)) if score >= 0.35 else ("UNKNOWN", round(score,2))

# ─────────────────────────────────────────────────────────────────────────────
# STEP 4: Validate
# ─────────────────────────────────────────────────────────────────────────────
def validate(detected, expected, conf):
    if detected == "UNKNOWN":
        return {"valid":False,"reason":"INVALID_DOCUMENT",
                "message":"Not a bank statement. Upload your bank account statement PDF."}
    if detected != expected:
        return {"valid":False,"reason":"WRONG_DOCUMENT",
                "message":f"Got '{detected}', expected '{expected}'."}
    if conf < 0.35:
        return {"valid":False,"reason":"LOW_CONFIDENCE","message":f"Confidence {conf:.2f} too low."}
    return {"valid":True,"reason":"OK"}

# ─────────────────────────────────────────────────────────────────────────────
# STEP 5: Field extraction
# ─────────────────────────────────────────────────────────────────────────────
DATE_RE    = re.compile(r'\b(\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4})\b')
AMOUNT_RE  = re.compile(r'\b([\d,]+\.\d{2})\b')
CREDIT_KW  = {"cr","credit","deposit","neft cr","imps cr","upi cr","salary",
              "transfer in","received","p2a"}      # p2a = person-to-account = received
DEBIT_KW   = {"dr","debit","withdrawal","wthdrl","atm","emi","purchase",
              "payment","p2m"}                     # p2m = person-to-merchant = paid

def _is_credit(text):
    tl = text.lower()
    return any(k in tl for k in CREDIT_KW)

def _is_debit(text):
    tl = text.lower()
    return any(k in tl for k in DEBIT_KW)

def parse_transactions(blocks, all_lines):
    """
    Handles 3 PDF column layouts:
    Layout A (Axis Bank): date-block | narration+amounts block (pipe-separated)
    Layout B (FSFB):      narration lines | date line | amount | balance
    Layout C (Canara):    header + table rows with all cols on one line
    """
    credits = []
    debits  = []
    monthly_credits = {}
    monthly_debits  = {}

    DATE_ONLY_RE = re.compile(r'^\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4}$')

    # --- Try Layout A: blocks with pipe separators containing amounts --------
    for blk in blocks:
        txt = blk["text"]
        parts = [p.strip() for p in txt.split("|") if p.strip()]
        amounts_in_block = [_amount(p) for p in parts if AMOUNT_RE.fullmatch(p.strip())]
        date_in_block = DATE_RE.search(txt)

        if not date_in_block or len(amounts_in_block) < 2:
            continue

        date_str = date_in_block.group(1)
        parts_d = re.split(r'[/\-]', date_str)
        if len(parts_d) == 3:
            y = parts_d[2] if len(parts_d[2])==4 else "20"+parts_d[2]
            mk = f"{parts_d[1].zfill(2)}/{y}"
        else:
            mk = "unknown"

        # Last amount = balance, second-to-last = transaction
        # If 3 amounts: debit | credit | balance
        narration = " ".join(p for p in parts
                             if not AMOUNT_RE.fullmatch(p) and not DATE_ONLY_RE.match(p)
                             and len(p) > 3)

        if len(amounts_in_block) >= 3:
            debit_a, credit_a = amounts_in_block[-3], amounts_in_block[-2]
            if debit_a > 0:
                debits.append(debit_a)
                monthly_debits[mk] = monthly_debits.get(mk,0) + debit_a
            if credit_a > 0:
                credits.append(credit_a)
                monthly_credits[mk] = monthly_credits.get(mk,0) + credit_a
        else:
            tx_amt = amounts_in_block[-2]
            if _is_credit(narration):
                credits.append(tx_amt)
                monthly_credits[mk] = monthly_credits.get(mk,0) + tx_amt
            elif _is_debit(narration):
                debits.append(tx_amt)
                monthly_debits[mk] = monthly_debits.get(mk,0) + tx_amt

    # --- Layout B fallback: scan all_lines with sliding window ---------------
    if not credits and not debits:
        i = 0
        while i < len(all_lines) - 2:
            line = all_lines[i]
            if DATE_ONLY_RE.match(line.strip()):
                # Look ahead up to 3 lines for amounts
                window = all_lines[i:i+5]
                amounts = [_amount(l) for l in window if AMOUNT_RE.fullmatch(l.strip())]
                narration = " ".join(l for l in window
                                     if not DATE_ONLY_RE.match(l.strip())
                                     and not AMOUNT_RE.fullmatch(l.strip())
                                     and len(l) > 3)
                if len(amounts) >= 2:
                    d_match = re.split(r'[/\-]', line.strip())
                    if len(d_match) == 3:
                        y = d_match[2] if len(d_match[2])==4 else "20"+d_match[2]
                        mk = f"{d_match[1].zfill(2)}/{y}"
                    else:
                        mk = "unknown"

                    tx_amt = amounts[-2]
                    if _is_credit(narration):
                        credits.append(tx_amt)
                        monthly_credits[mk] = monthly_credits.get(mk,0) + tx_amt
                    elif _is_debit(narration):
                        debits.append(tx_amt)
                        monthly_debits[mk] = monthly_debits.get(mk,0) + tx_amt
            i += 1

    return credits, debits, monthly_credits, monthly_debits


def extract_fields(blocks_data, all_lines):
    full_text = " ".join(all_lines)
    txt_lo    = full_text.lower()
    fields    = {}
    warnings  = []

    # Account holder name
    for pat in [r"(?:account holder|customer name|name)[:\s]+([A-Z][A-Z\s\.]+?)(?:\s{2,}|\n|$)",
                r"^([A-Z][A-Z\s\.]{4,30})$"]:
        m = re.search(pat, full_text, re.IGNORECASE|re.MULTILINE)
        if m and len(m.group(1).split()) >= 2:
            fields["account_holder_name"] = m.group(1).strip()
            break
    # Try first line if all-caps name
    if "account_holder_name" not in fields and all_lines:
        first = all_lines[0].strip()
        if re.match(r'^[A-Z][A-Z\s\.]{3,}$', first) and len(first.split()) >= 2:
            fields["account_holder_name"] = first

    if "account_holder_name" not in fields:
        warnings.append("account_holder_name_not_found")

    # Account number
    for pat in [r"(?:account no|account number|a/c no|acc(?:ount)? no)[:\s.]+(\d[\d\s\-]{7,17}\d)",
                r"Axis Account No\s*:(\d{10,16})",
                r"\b(\d{11,16})\b"]:
        m = re.search(pat, full_text, re.IGNORECASE)
        if m:
            fields["account_number"] = re.sub(r'[\s\-]','', m.group(1))
            break
    if "account_number" not in fields:
        warnings.append("account_number_not_found")

    # Bank name
    for pat in BANK_NAME_PAT:
        m = re.search(pat, full_text, re.IGNORECASE)
        if m:
            fields["bank_name"] = m.group(1).strip()
            break
    # Axis special case (UTIB IFSC)
    if "account_number" not in fields or "bank_name" not in fields:
        if "utib" in txt_lo or "axis" in txt_lo:
            fields["bank_name"] = "Axis Bank"
    if "bank_name" not in fields:
        warnings.append("bank_name_not_found")

    # IFSC
    m = re.search(r'\b([A-Z]{4}0[A-Z0-9]{6})\b', full_text)
    if m: fields["ifsc_code"] = m.group(1)
    else: warnings.append("ifsc_not_found")

    # Statement period
    m = re.search(r'[Ff]rom\s*[:\s]*(\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4}).*?[Tt]o\s*[:\s]*(\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4})',
                  full_text, re.DOTALL)
    if m:
        fields["statement_from"] = m.group(1)
        fields["statement_to"]   = m.group(2)
    else:
        dates = DATE_RE.findall(full_text)
        if len(dates) >= 2:
            fields["statement_from"] = dates[0]
            fields["statement_to"]   = dates[-1]
            warnings.append("period_inferred")

    # Opening/Closing balance
    for pat, key in [
        (r"(?:opening balance)[:\s]*([\d,]+\.\d{2})", "opening_balance"),
        (r"(?:closing balance)[:\s]*([\d,]+\.\d{2})", "closing_balance"),
    ]:
        m = re.search(pat, txt_lo)
        if m:
            # Get actual text with proper case for amount
            m2 = re.search(pat, full_text, re.IGNORECASE)
            if m2: fields[key] = _amount(m2.group(1))

    # Transactions
    credits, debits, monthly_cr, monthly_dr = parse_transactions(
        blocks_data["blocks"], all_lines
    )

    print(f"  [TX Parser] credits={len(credits)}, debits={len(debits)}, "
          f"months_cr={len(monthly_cr)}, months_dr={len(monthly_dr)}")

    if credits:
        fields["total_credits"]  = round(sum(credits), 2)
        fields["credit_count"]   = len(credits)
    if debits:
        fields["total_debits"]   = round(sum(debits), 2)
        fields["debit_count"]    = len(debits)

    if monthly_cr:
        vals = list(monthly_cr.values())
        avg  = sum(vals) / len(vals)
        fields["avg_monthly_credit"]        = round(avg, 2)
        fields["monthly_credit_months"]     = len(vals)
        if len(vals) > 1:
            mean = avg
            std  = (sum((x-mean)**2 for x in vals)/len(vals))**0.5
            fields["income_stability_cv"]   = round(std/mean if mean>0 else 1.0, 4)
            fields["income_growth_slope"]   = round((vals[-1]-vals[0])/(vals[0]+1), 4)
        if monthly_dr:
            dr_vals = list(monthly_dr.values())
            avg_dr  = sum(dr_vals)/len(dr_vals)
            fields["avg_monthly_debit"]     = round(avg_dr, 2)
            fields["income_expense_ratio"]  = round(avg/(avg_dr+1), 3)

    all_months = set(list(monthly_cr)+list(monthly_dr))
    fields["statement_months"] = len(all_months) or 1
    if not monthly_cr:
        warnings.append("avg_monthly_income_not_computable")

    MAX_INC = 200000.0
    if "avg_monthly_credit" in fields:
        fields["avg_monthly_income_norm"] = round(
            min(fields["avg_monthly_credit"]/MAX_INC, 1.0), 4)

    return {"fields": fields, "warnings": warnings}


def build_output(status, doc_type, conf, fields, warnings, quality, n_lines, fname):
    return {
        "extraction": {"status":status,"doc_type":doc_type,"confidence":conf,
                       "file":fname,"quality":quality,"fields":fields,
                       "warnings":warnings,"lines_extracted":n_lines},
        "temp_storage": {"step":"step_3","doc_type":doc_type,
                         "verified": status in ("ACCEPTED","PARTIAL_EXTRACTION"),
                         "timestamp":datetime.datetime.now().isoformat(),
                         "data":fields,"warnings":warnings}
    }


def process(pdf_path, expected="bank_statement"):
    fname = Path(pdf_path).name
    print(f"\n{'='*65}\n  File : {fname}\n{'='*65}")

    quality = check_quality(pdf_path)
    print(f"  Quality : {quality}")
    if not quality["passed"]:
        return build_output("LOW_QUALITY_PDF","UNKNOWN",0.0,{},
                            [quality["reason"]],quality,0,fname)

    print(f"  Extracting (PyMuPDF blocks mode)...")
    data = extract_text_blocks(pdf_path)
    all_lines, n_lines = data["all_lines"], data["total_lines"]
    print(f"  Pages={data['total_pages']}, Lines={n_lines}, Blocks={len(data['blocks'])}")

    if n_lines < 5:
        return build_output("NO_TEXT_FOUND","UNKNOWN",0.0,{},
                            ["too_few_lines"],quality,n_lines,fname)

    detected, conf = classify(all_lines)
    print(f"  Detected : {detected} (conf={conf})")
    v = validate(detected, expected, conf)
    print(f"  Valid    : {v['valid']} — {v['reason']}")
    if not v["valid"]:
        print(f"  REJECT   : {v['message']}")
        return build_output(v["reason"],detected,conf,{},
                            [v["message"]],quality,n_lines,fname)

    extraction = extract_fields(data, all_lines)
    fields, warnings = extraction["fields"], extraction["warnings"]
    status = "ACCEPTED" if fields.get("avg_monthly_credit") else "PARTIAL_EXTRACTION"

    print(f"\n  --- Extracted Fields ---")
    for k, val in fields.items():
        print(f"  {k:<38}: {val}")
    if warnings: print(f"  Warnings: {warnings}")

    return build_output(status, detected, conf, fields, warnings, quality, n_lines, fname)


# ─────────────────────────────────────────────────────────────────────────────
BASE = r"C:\Users\PRAVEEN\Desktop\rotatech hackathon\Gig_Credit\specification folders_new\Inputs\inputs hardcopies\step -3"
STEP3_DOCS = [
    {"path": os.path.join(BASE,"Bank Statement - 2.pdf"), "label":"Type-1 (Canara/RAHUL)"},
    {"path": os.path.join(BASE,"Bank Statement -1.pdf"),  "label":"Type-2 (FSFB/AMJAD)"},
    {"path": os.path.join(BASE,"Bank Statement - 3.pdf"), "label":"Type-3 (Axis/PRAVEEN)"},
]

if __name__ == "__main__":
    print("GigCredit Step 3 — Bank Statement OCR Pipeline v2".center(65,"="))
    all_results = []
    best = {}

    for doc in STEP3_DOCS:
        print(f"\n{'*'*65}\n  [{doc['label']}]\n{'*'*65}")
        r = process(doc["path"])
        all_results.append({doc["label"]: r})
        ts = r["temp_storage"]
        if ts["verified"]:
            d = ts["data"]
            if d.get("avg_monthly_credit",0) > best.get("avg_monthly_credit",0):
                best = d

    step3_profile = {
        "step": "step_3",
        "completed_at": datetime.datetime.now().isoformat(),
        "bank_verified": bool(best),
        "ml_features": {
            "avg_monthly_income_norm": best.get("avg_monthly_income_norm"),
            "income_stability_cv":     best.get("income_stability_cv"),
            "income_growth_slope":     best.get("income_growth_slope"),
            "income_expense_ratio":    best.get("income_expense_ratio"),
            "statement_months":        best.get("statement_months"),
        },
        "extracted_data": best,
    }

    print(f"\n{'='*65}\n  STEP 3 ML PROFILE\n{'='*65}")
    print(json.dumps(step3_profile, indent=2, ensure_ascii=False))

    out = r"C:\Users\PRAVEEN\Desktop\rotatech hackathon\Gig_Credit\step3_ocr_results.json"
    with open(out,"w",encoding="utf-8") as f:
        json.dump({"results":all_results,"step3_profile":step3_profile},
                  f, indent=2, ensure_ascii=False)
    print(f"\n  Saved: {out}")
