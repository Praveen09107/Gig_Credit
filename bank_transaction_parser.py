"""
GigCredit — Bank Statement → Structured Transaction Table
+ Cross-verification with Utility Bill payments

FLOW:
  Step 1: Parse bank PDF → list of {date, amount, type, ref_id, description}
  Step 2: Store as temp JSON table
  Step 3: From each utility bill OCR, extract {amount, ref_id, date, payee_name}
  Step 4: Match each bill payment against bank table
  Step 5: Return verification result per bill

Supports:
  - Axis Bank (UPI/P2A/XXXXXXXXXX/...)
  - Fincare/FSFB (RRN:XXXXXXXXXXXX)
  - Canara Bank (UPI/DR/XXXXXXXXXX/... with timestamp)
"""

import sys, os, re, json, datetime
sys.stdout.reconfigure(encoding="utf-8")
import fitz
from paddleocr import PaddleOCR

_paddle = PaddleOCR(use_angle_cls=True, lang="en", show_log=False)

# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────
DATE_FMTS = ["%d-%m-%Y", "%d/%m/%Y", "%m/%d/%Y", "%Y-%m-%d",
             "%d-%m-%Y %H:%M:%S", "%d-%m-%Y %I:%M:%S %p"]

def parse_date(s):
    if not s: return None
    s = re.sub(r'\s+', ' ', s.strip())
    # Strip trailing time if present: "17-10-2022 14:57:48"
    s = re.sub(r'\s+\d{2}:\d{2}:\d{2}.*$', '', s)
    for fmt in DATE_FMTS:
        try: return datetime.datetime.strptime(s, fmt).date()
        except: pass
    return None

def parse_amount(s):
    if not s: return None
    s = str(s).replace(',', '').strip()
    try: return float(s)
    except: return None

def extract_ref_id(narration: str):
    """Extract UPI/IMPS/NEFT reference number from narration text."""
    # UPI ref: UPI/P2A/562856503400/... or UPI/DR/218330734706/...
    m = re.search(r'UPI/(?:P2[AM]|[DC]R)/(\d{10,})', narration, re.IGNORECASE)
    if m: return m.group(1)
    # IMPS RRN: RRN:334497449222 or IMPS/P2A/123...
    m = re.search(r'RRN[:\s]*(\d{9,})', narration, re.IGNORECASE)
    if m: return m.group(1)
    # IMPS: IMPS/P2A/XXXXXXXXXX
    m = re.search(r'IMPS/[^/]*/(\d{9,})', narration, re.IGNORECASE)
    if m: return m.group(1)
    # Cheque number fallback
    m = re.search(r'\b(\d{12,})\b', narration)
    if m: return m.group(1)
    return None

# ─────────────────────────────────────────────────────────────────────────────
# STAGE 1 — BANK STATEMENT PARSER
# ─────────────────────────────────────────────────────────────────────────────
def parse_bank_statement(pdf_path: str) -> list:
    """
    Parse a bank statement PDF into a list of transaction dicts.
    Handles Axis, Fincare/FSFB, and Canara formats.
    Returns list of:
      {date, amount, type (credit|debit), ref_id, description, balance}
    """
    doc = fitz.open(pdf_path)
    all_text_lines = []
    for page in doc:
        raw = page.get_text("text")
        for l in raw.splitlines():
            l = l.strip()
            if l: all_text_lines.append(l)
    doc.close()

    full_text = "\n".join(all_text_lines)

    # Detect format
    if "UTIB" in full_text or "Axis" in full_text.lower() or "Tran Date" in full_text:
        return _parse_axis_format(all_text_lines)
    elif "FSFB" in full_text or "RRN:" in full_text or "WTHDRL" in full_text:
        return _parse_fincare_format(all_text_lines)
    elif "CNRB" in full_text or "Canara" in full_text.lower() or "Txn Date" in full_text:
        return _parse_canara_format(all_text_lines)
    else:
        print("  [WARN] Unknown bank format, attempting generic parse...")
        return _parse_generic(all_text_lines)


def _parse_axis_format(lines):
    """
    Axis Bank exact line structure (from PDF inspection):
      DD-MM-YYYY
      UPI/P2A/REFID/PAYEE/...   ← narration line 1
      /continuation              ← narration line 2 (optional)
      12.00                      ← single amount (debit OR credit)
      10.93                      ← balance
      345                        ← branch code (skip)

    Debit/Credit determined by: if balance INCREASED → credit, else → debit.
    """
    transactions = []
    date_re    = re.compile(r'^(\d{2}-\d{2}-\d{4})$')
    decimal_re = re.compile(r'^\.?\d{1,3}(?:,\d{3})*(?:\.\d{2})$')   # matches "12.00", "1,234.56", ".93"
    branch_re  = re.compile(r'^\d{3,4}$')

    def is_amount(s):
        s = s.replace(',', '')
        try:
            float(s)
            return '.' in s
        except:
            return False

    prev_balance = None
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        dm = date_re.match(line)
        if not dm:
            # Track opening balance
            if 'OPENING BALANCE' in line.upper() and i + 1 < len(lines):
                ob = lines[i+1].strip().replace(',','')
                try:
                    prev_balance = float(ob)
                except:
                    pass
            i += 1
            continue

        txn_date = parse_date(dm.group(1))
        narration_parts = []
        i += 1

        # Collect narration lines until we hit the amount
        while i < len(lines):
            nxt = lines[i].strip()
            if date_re.match(nxt):
                break  # Next date — no amounts found for this txn
            if branch_re.match(nxt):
                i += 1
                break  # Branch code — end of this transaction
            if is_amount(nxt):
                # First amount = transaction amount
                txn_amount = float(nxt.replace(',', ''))
                i += 1
                # Next line should be balance
                balance = None
                if i < len(lines) and is_amount(lines[i].strip()):
                    balance = float(lines[i].strip().replace(',', ''))
                    i += 1
                # Skip branch code
                if i < len(lines) and branch_re.match(lines[i].strip()):
                    i += 1

                # Determine credit vs debit from balance delta
                if balance is not None and prev_balance is not None:
                    txn_type = "credit" if balance > prev_balance else "debit"
                else:
                    # Fallback: P2A pattern check on narration
                    narr = " ".join(narration_parts).upper()
                    # In Axis: P2A typically = debit (you transferred out), P2M = merchant debit
                    # But some P2A are incoming. Use balance delta only if available.
                    txn_type = "debit"

                if balance is not None:
                    prev_balance = balance

                narration = " ".join(narration_parts)
                ref_id = extract_ref_id(narration)
                if txn_date and txn_amount > 0:
                    transactions.append({
                        "date": str(txn_date),
                        "amount": txn_amount,
                        "type": txn_type,
                        "ref_id": ref_id,
                        "description": narration[:120],
                        "balance": balance
                    })
                break
            else:
                if nxt:
                    narration_parts.append(nxt)
                i += 1

    return transactions


def _parse_fincare_format(lines):
    """
    Fincare / FSFB format:
      Date    Narration (multi-line)    Amount    Balance
    Pattern: line starting with dd/mm/yyyy, followed by narration, then amounts.
    """
    transactions = []
    date_re = re.compile(r'^(\d{2}/\d{2}/\d{4})')

    i = 0
    while i < len(lines):
        line = lines[i]
        dm = date_re.match(line)
        if dm:
            txn_date = parse_date(dm.group(1))
            rest = line[len(dm.group(0)):].strip()
            narration_parts = [rest] if rest else []
            i += 1
            # Collect narration until we find a line with two decimal amounts
            while i < len(lines):
                amounts = re.findall(r'([\d,]+\.\d{2})', lines[i])
                if len(amounts) >= 2:
                    # Format: amount  balance  (or balance  amount)
                    txn_amount = parse_amount(amounts[0])
                    balance = parse_amount(amounts[-1])
                    # Detect type from narration
                    full_narration = " ".join(narration_parts + [lines[i]])
                    txn_type = "credit" if ("DEPOSIT" in full_narration.upper() or "CR" in full_narration.upper()) else "debit"
                    ref_id = extract_ref_id(full_narration)
                    if txn_date and txn_amount:
                        transactions.append({
                            "date": str(txn_date),
                            "amount": txn_amount,
                            "type": txn_type,
                            "ref_id": ref_id,
                            "description": full_narration[:120],
                            "balance": balance
                        })
                    i += 1
                    break
                elif date_re.match(lines[i]):
                    break  # Next transaction
                else:
                    narration_parts.append(lines[i])
                    i += 1
        else:
            i += 1
    return transactions


def _parse_canara_format(lines):
    """
    Canara Bank format:
      DD-MM-YYYY HH:MM:SS   DD Mon YYYY   CHEQUENO   DESCRIPTION   BRCODE   DEBIT   CREDIT   BALANCE
    Lines contain timestamp + amounts on same or next line.
    """
    transactions = []
    # Pattern: starts with date-timestamp
    ts_re = re.compile(r'^(\d{2}-\d{2}-\d{4})\s+\d{2}:\d{2}:\d{2}')

    i = 0
    while i < len(lines):
        line = lines[i]
        m = ts_re.match(line)
        if m:
            txn_date = parse_date(m.group(1))
            # Everything on this line after the timestamp is the narration start
            rest = line[m.end():].strip()
            # Remove cheque number and branch code patterns
            rest = re.sub(r'\d{2}\s+\w+\s+\d{4}', '', rest)
            narration_parts = [rest] if rest else []
            i += 1
            # Collect next lines until another timestamp
            while i < len(lines) and not ts_re.match(lines[i]):
                amounts = re.findall(r'([\d,]+\.\d{2})', lines[i])
                if len(amounts) >= 2:
                    txn_amount = parse_amount(amounts[0])
                    balance = parse_amount(amounts[-1])
                    full_narration = " ".join(narration_parts + [lines[i]])
                    txn_type = "credit" if "CR" in full_narration.upper() else "debit"
                    ref_id = extract_ref_id(full_narration)
                    if txn_date and txn_amount:
                        transactions.append({
                            "date": str(txn_date),
                            "amount": txn_amount,
                            "type": txn_type,
                            "ref_id": ref_id,
                            "description": full_narration[:120],
                            "balance": balance
                        })
                    i += 1
                    break
                narration_parts.append(lines[i])
                i += 1
        else:
            i += 1
    return transactions


def _parse_generic(lines):
    """Fallback: look for lines with date + two decimal amounts."""
    transactions = []
    pattern = re.compile(r'(\d{2}[-/]\d{2}[-/]\d{4}).*?([\d,]+\.\d{2})\s+([\d,]+\.\d{2})')
    for line in lines:
        m = pattern.search(line)
        if m:
            txn_date = parse_date(m.group(1))
            txn_amount = parse_amount(m.group(2))
            balance = parse_amount(m.group(3))
            ref_id = extract_ref_id(line)
            if txn_date and txn_amount:
                transactions.append({
                    "date": str(txn_date),
                    "amount": txn_amount,
                    "type": "debit",
                    "ref_id": ref_id,
                    "description": line[:120],
                    "balance": balance
                })
    return transactions


# ─────────────────────────────────────────────────────────────────────────────
# STAGE 2 — UTILITY BILL PAYMENT EXTRACTOR
# ─────────────────────────────────────────────────────────────────────────────
def extract_bill_payment_info(pdf_path: str) -> dict:
    """
    Extract payment details from a utility bill PDF:
    - amount paid
    - transaction/reference ID (UPI ref, RRN, receipt number)
    - payment date
    - payee name (optional)
    """
    # Try PDF text first
    doc = fitz.open(pdf_path) if pdf_path.lower().endswith('.pdf') else None
    if doc:
        lines = []
        for p in doc:
            for l in p.get_text("text").splitlines():
                if l.strip(): lines.append(l.strip())
        doc.close()
        raw = " ".join(lines)
    else:
        # Image — use PaddleOCR
        res = _paddle.ocr(pdf_path, cls=True)
        lines = [item[1][0] if isinstance(item[1],(list,tuple)) else str(item[1])
                 for item in (res[0] or []) if res and res[0]]
        raw = " ".join(lines)

    result = {"amount": None, "ref_id": None, "payment_date": None, "payee_name": None, "raw_snippet": raw[:300]}

    # Amount — look for "Amount Paid", "Total Amount", "Net Payable"
    for pat in [
        r'(?:amount paid|total paid|net payable|total amount|grand total|amount)[:\s₹]*([\d,]+(?:\.\d{2})?)',
        r'(?:RS\.?|INR|₹)\s*([\d,]+(?:\.\d{2})?)',
    ]:
        m = re.search(pat, raw, re.IGNORECASE)
        if m:
            result["amount"] = parse_amount(m.group(1))
            break

    # Reference ID — UPI/payment ref
    for pat in [
        r'(?:payment ref(?:erence)?|transaction id|ref no|upi ref|rrn|receipt no)[.:\s#]*([\w\d]{8,})',
        r'UPI/(?:P2[AM]|[DC]R)/(\d{9,})',
        r'RRN[:\s]*(\d{9,})',
    ]:
        m = re.search(pat, raw, re.IGNORECASE)
        if m:
            result["ref_id"] = m.group(1)
            break

    # Date
    for pat in [
        r'(?:payment date|paid on|date of payment|invoice date|bill date)[:\s]*([\d]{1,2}[-/][\d]{1,2}[-/][\d]{2,4})',
        r'\b(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})\b',
    ]:
        m = re.search(pat, raw, re.IGNORECASE)
        if m:
            result["payment_date"] = str(parse_date(m.group(1))) if parse_date(m.group(1)) else m.group(1)
            if result["payment_date"]: break

    # Payee name (optional — provider/company name)
    for keyword in ["TANGEDCO","AIRTEL","JIO","NETFLIX","INDANE","BHARAT GAS","ACT FIBERNET","VODAFONE"]:
        if keyword in raw.upper():
            result["payee_name"] = keyword
            break

    return result


# ─────────────────────────────────────────────────────────────────────────────
# STAGE 3 — TRANSACTION MATCHING ENGINE
# ─────────────────────────────────────────────────────────────────────────────
AMOUNT_TOLERANCE  = 0.12   # ±12%
DATE_WINDOW_DAYS  = 5      # ±5 days

def match_transaction(bill_info: dict, bank_table: list) -> dict:
    """
    Match a bill payment against the bank transaction table.
    Priority: ref_id exact → amount+date fuzzy → amount only (low confidence)
    """
    bill_amount = bill_info.get("amount")
    bill_ref    = bill_info.get("ref_id", "").replace(" ", "") if bill_info.get("ref_id") else ""
    bill_date   = parse_date(bill_info.get("payment_date"))

    best = {"match_found": False, "confidence": 0.0, "matched_txn": None}

    for txn in bank_table:
        txn_amount = txn.get("amount", 0) or 0
        txn_ref    = (txn.get("ref_id") or "").strip()
        txn_date   = parse_date(txn.get("date"))
        txn_desc   = txn.get("description", "")

        confidence = 0.0

        # 1. Reference ID match (highest confidence)
        if bill_ref and txn_ref and bill_ref in txn_ref:
            confidence += 0.60
            print(f"    [REF MATCH] bill_ref={bill_ref} in txn_ref={txn_ref}")

        # 2. Amount match
        if bill_amount and txn_amount > 0:
            diff = abs(txn_amount - bill_amount) / max(txn_amount, bill_amount)
            if diff <= AMOUNT_TOLERANCE:
                amt_conf = round(1.0 - diff, 3)
                confidence += amt_conf * 0.30
                # Bonus if payee name in description
                payee = (bill_info.get("payee_name") or "").upper()
                if payee and payee in txn_desc.upper():
                    confidence += 0.10

        # 3. Date proximity
        if bill_date and txn_date:
            days_diff = abs((bill_date - txn_date).days)
            if days_diff <= DATE_WINDOW_DAYS:
                date_conf = round(1.0 - days_diff / (DATE_WINDOW_DAYS * 2), 3)
                confidence += date_conf * 0.10

        confidence = round(min(confidence, 1.0), 3)

        if confidence > best["confidence"]:
            best = {
                "match_found": confidence >= 0.35,
                "confidence": confidence,
                "matched_txn": {
                    "date": txn.get("date"),
                    "amount": txn_amount,
                    "type": txn.get("type"),
                    "ref_id": txn_ref,
                    "description": txn_desc[:80]
                }
            }

    return best


# ─────────────────────────────────────────────────────────────────────────────
# MAIN — Run on real data
# ─────────────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    S3 = r"C:\Users\PRAVEEN\Desktop\rotatech hackathon\Gig_Credit\specification folders_new\Inputs\inputs hardcopies\step -3"
    S4 = r"C:\Users\PRAVEEN\Desktop\rotatech hackathon\Gig_Credit\specification folders_new\Inputs\inputs hardcopies\step -4"

    BANK_PDF = os.path.join(S3, "Bank Statement - 3.pdf")   # Axis/PRAVEEN — best structured

    print("\n" + "═"*70)
    print("  GigCredit — Bank Statement Structuring & Bill Verification")
    print("═"*70)

    # ── Parse bank statement ──────────────────────────────────────────────
    print(f"\n[STAGE 1] Parsing: {os.path.basename(BANK_PDF)}")
    transactions = parse_bank_statement(BANK_PDF)
    print(f"  → {len(transactions)} transactions extracted")

    # Show sample
    print("\n  Sample transactions (first 5):")
    for t in transactions[:5]:
        print(f"    {t['date']} | {'CR' if t['type']=='credit' else 'DR'} | ₹{t['amount']:>10,.2f} | ref={t['ref_id']} | {t['description'][:50]}")

    # Save bank table to temp storage
    bank_table_path = "temp_bank_table.json"
    with open(bank_table_path, "w", encoding="utf-8") as f:
        json.dump({
            "source": os.path.basename(BANK_PDF),
            "total_transactions": len(transactions),
            "transactions": transactions
        }, f, indent=2)
    print(f"\n  ✓ Bank table saved → {bank_table_path}")

    # ── Extract utility bill payment info ─────────────────────────────────
    UTILITY_BILLS = [
        {"label": "EB Bill",        "path": os.path.join(S4, "eb bill", "eb bill - 05-11-25.pdf")},
        {"label": "Mobile (Airtel)","path": os.path.join(S4, "mobile bill", "airtel mobile bill.pdf")},
        {"label": "Mobile (Jio)",   "path": os.path.join(S4, "mobile bill", "jio mobil bill.pdf")},
        {"label": "OTT (Netflix)",  "path": os.path.join(S4, "ott subscriotion", "ott netflix subscription.pdf")},
        {"label": "WiFi",           "path": os.path.join(S4, "wifi bill", "wifi bill.pdf")},
    ]

    print("\n" + "─"*70)
    print("[STAGE 2] Extracting payment info from utility bills...")

    verification_results = []

    for bill in UTILITY_BILLS:
        if not os.path.exists(bill["path"]): continue
        print(f"\n  Bill: {bill['label']}")

        payment_info = extract_bill_payment_info(bill["path"])
        print(f"    Amount  : ₹{payment_info['amount']}")
        print(f"    Ref ID  : {payment_info['ref_id']}")
        print(f"    Date    : {payment_info['payment_date']}")
        print(f"    Payee   : {payment_info['payee_name']}")

        # ── Match against bank table ──────────────────────────────────────
        print(f"  → Matching against {len(transactions)} bank transactions...")
        match = match_transaction(payment_info, transactions)
        print(f"    Match found : {match['match_found']}")
        print(f"    Confidence  : {match['confidence']:.2f}")
        if match.get("matched_txn"):
            m = match["matched_txn"]
            print(f"    Matched txn : {m['date']} | ₹{m['amount']} | {m['description'][:60]}")

        verification_results.append({
            "bill": bill["label"],
            "payment_info": payment_info,
            "verification": match
        })

    # ── Save full temp storage ────────────────────────────────────────────
    out = {
        "generated_at": datetime.datetime.now().isoformat(),
        "bank_source": os.path.basename(BANK_PDF),
        "total_bank_transactions": len(transactions),
        "bill_verifications": verification_results
    }
    with open("temp_transaction_verification.json", "w", encoding="utf-8") as f:
        json.dump(out, f, indent=2)

    passed = sum(1 for r in verification_results if r["verification"]["match_found"])
    print(f"\n{'═'*70}")
    print(f"  SUMMARY: {passed}/{len(verification_results)} utility bills verified against bank statement")
    print(f"  Saved → temp_transaction_verification.json")
    print("═"*70)
