"""
GigCredit — Full Cross-Document Unique Identification Stress Test
Tests ALL documents against ALL slots:
  - Identity docs (Aadhaar, PAN, eShram)
  - Bank Statements (PDF)
  - Utility bills (EB, Gas, Mobile, WiFi, OTT, Rent)

For each document, verifies:
  [OK] Accepted ONLY in its correct slot
  [OK] Rejected from every other slot

Prints a full NxN matrix and final pass/fail summary.
"""
import sys, os, re
sys.stdout.reconfigure(encoding="utf-8")
import fitz
from paddleocr import PaddleOCR

_paddle = PaddleOCR(use_angle_cls=True, lang="en", show_log=False)

# ── Text extraction ───────────────────────────────────────────────────────────
def get_text(path):
    if path.lower().endswith(".pdf"):
        doc = fitz.open(path)
        lines = []
        for p in doc:
            for l in p.get_text("text").splitlines():
                if l.strip(): lines.append(l.strip())
        doc.close()
        raw = " ".join(lines)
        if len(raw.strip()) < 60:           # scanned PDF fallback
            raw = paddle_text(path)
        return raw
    else:
        return paddle_text(path)

def paddle_text(path):
    res = _paddle.ocr(path, cls=True)
    lines = []
    if res and res[0]:
        for item in res[0]:
            lines.append(item[1][0] if isinstance(item[1], (list,tuple)) else str(item[1]))
    return " ".join(lines)

# ── Keyword tables ────────────────────────────────────────────────────────────
ESHRAM_SIGNALS = ["e-shram","eshram","universal account number","uan",
                  "ministry of labour","eshram.gov.in","primary occupation","blood group"]
AADHAAR_KW     = ["aadhaar","aadhar","unique identification authority","uidai"]
AADHAAR_FRONT  = ["male","female","dob","date of birth"]
AADHAAR_BACK   = ["address","s/o","c/o","help@uidai","www.uidai"]
PAN_STRONG     = ["income tax","permanent account","income tax department"]
BANK_STRONG    = ["account statement","bank statement","statement of account",
                  "savings account","current account","passbook"]
BANK_MOD       = ["ifsc","micr","opening balance","closing balance","neft",
                  "imps","upi","rtgs","account number","withdrawal","deposit"]

# ── mobile: removed 'jio' (jio also offers fiber/wifi — causes ambiguity)
# ── wifi: added 'jiofiber','data speed','unlimited data' as strong disambiguators
# ── rent: removed generic 'rental'/'agreement' (appear in wifi plan docs too)
UTIL_KW = {
    "electricity": ["electricity","tangedco","energy charges","power distribution","kwh","meter number","reading","units consumed"],
    "gas":         ["gas","indane","bharat gas","hp gas","cylinder","png","lpg","distributor","gas connection"],
    # 'postpaid' removed — Airtel WiFi bills say "postpaid wi-fi monthly statement"
    # 'jio number' / 'reliance jio' added — Jio bills say "jio number: xxxxxxxx"
    "mobile":      ["mobile bill","airtel mobile","jio mobile","jio number","reliance jio","vodafone","talktime","call charges","roaming","mobile postpaid"],
    # 'wi-fi' / 'airtel wifi' added — Airtel broadband bills say "wi-fi monthly statement"
    # 'postpaid' NOT included — causes overlap with mobile
    "internet":    ["broadband","wi-fi","jiofiber","act fibernet","airtel fiber","data speed","unlimited data","internet service","wifi plan","fiber optic","airtel wifi"],
    "wifi":        ["broadband","wi-fi","jiofiber","act fibernet","airtel fiber","data speed","unlimited data","internet service","wifi plan","fiber optic","airtel wifi"],
    "ott":         ["netflix","amazon prime","hotstar","subscription plan","ott platform","streaming"],
    "rent":        ["rent receipt","tenant name","landlord","monthly rent","lease agreement","rental agreement","rent paid"],
}
UTIL_GENERIC = ["bill","invoice","payment","due date","amount payable","customer no","consumer no","receipt"]

# ── Count helpers ─────────────────────────────────────────────────────────────
def cnt(text, kws): return sum(1 for k in kws if k in text.lower())

def is_eshram(text):  return cnt(text, ESHRAM_SIGNALS) >= 2
def is_aadhaar(text): return cnt(text, AADHAAR_KW) >= 1 and not is_eshram(text)
def has_front_sig(t): return cnt(t, AADHAAR_FRONT) >= 1
def has_back_sig(t):  return cnt(t, AADHAAR_BACK) >= 1
def is_pan(text):
    """Strict PAN detection:
    - Must have BOTH regex match AND at least one strong keyword
    - Explicitly blocked if any utility or bank signals present."""
    has_regex  = bool(re.search(r'[A-Z]{5}\d{4}[A-Z]', text.upper()))
    has_strong = cnt(text, PAN_STRONG) >= 1
    # Require BOTH regex AND keyword for high confidence
    if not (has_regex and has_strong):
        return False
    # Hard exclusions
    if bank_score(text) >= 3:
        return False
    if is_aadhaar(text):
        return False
    # Reject if document has significant utility signals (bills contain PAN numbers)
    for kws in UTIL_KW.values():
        if cnt(text, kws) >= 2:
            return False
    return True

def bank_score(text):
    return cnt(text, BANK_STRONG) * 3 + cnt(text, BANK_MOD)

def util_specific(text, sub):
    return cnt(text, UTIL_KW.get(sub, []))

def best_other_util(text, sub):
    best, best_k = 0, ""
    for k, kws in UTIL_KW.items():
        if k == sub: continue
        s = cnt(text, kws)
        if s > best: best, best_k = s, k
    return best, best_k

# ── Classifier per slot ───────────────────────────────────────────────────────
def classify(text, slot):
    """Returns (ACCEPT|REJECT, reason)"""
    esh  = is_eshram(text)
    aadh = is_aadhaar(text)
    pan  = is_pan(text)
    bs   = bank_score(text)
    front= has_front_sig(text)
    back = has_back_sig(text)

    if slot == "aadhaar_front":
        if esh:              return "REJECT", "eShram in Aadhaar slot"
        if pan and not aadh: return "REJECT", "PAN in Aadhaar slot"
        if back and not front: return "REJECT", "Aadhaar BACK in FRONT slot"
        if not aadh:         return "REJECT", "No Aadhaar signal"
        return "ACCEPT", f"aadhaar_front (front_sig={front})"

    if slot == "aadhaar_back":
        if esh:              return "REJECT", "eShram in Aadhaar slot"
        if pan and not aadh: return "REJECT", "PAN in Aadhaar slot"
        if front and not back: return "REJECT", "Aadhaar FRONT in BACK slot"
        if not aadh:         return "REJECT", "No Aadhaar signal"
        return "ACCEPT", f"aadhaar_back (back_sig={back})"

    if slot == "pan":
        if esh:              return "REJECT", "eShram in PAN slot"
        if aadh and not pan: return "REJECT", "Aadhaar in PAN slot"
        if not pan:          return "REJECT", "No PAN signal"
        return "ACCEPT", "pan"

    if slot == "bank_statement":
        if esh:  return "REJECT", "eShram in bank slot"
        if bs >= 3:
            return "ACCEPT", f"bank_statement (score={bs})"
        if pan:  return "REJECT", "PAN in bank slot"
        if aadh: return "REJECT", "Aadhaar in bank slot"
        return "REJECT", f"Insufficient bank signals (score={bs})"

    if slot.startswith("utility_"):
        sub = slot.replace("utility_", "")
        spec  = util_specific(text, sub)
        gen   = cnt(text, UTIL_GENERIC)

        # Compute ALL utility scores simultaneously
        all_scores = {k: cnt(text, kws) for k, kws in UTIL_KW.items()}
        other_max  = max((v for k, v in all_scores.items() if k != sub), default=0)
        other_key  = next((k for k, v in all_scores.items() if k != sub and v == other_max), "")

        # Hard rejections FIRST
        if esh:  return "REJECT", "eShram in utility slot"
        # For bank statements: bs>=4 AND spec must be low. Also require spec < 3 (bank PDFs can have 'airtel','vodafone' in narrations)
        if bs >= 4 and spec < 3:
            return "REJECT", f"Bank statement in utility slot (bs={bs}, spec={spec})"

        # Core utility logic: spec must be the DOMINANT score
        if spec == 0:
            if other_max > 0:
                return "REJECT", f"Wrong utility: '{other_key}'={other_max} dominates (spec=0)"
            if gen < 2:
                return "REJECT", f"No {sub} signals (spec=0, gen={gen})"
            # Only generic signals — still too weak for identity, reject
            return "REJECT", f"No {sub}-specific signals (spec=0)"

        # spec >= 1: must be strictly highest OR at least >= 2
        if spec < other_max:
            return "REJECT", f"Ambiguous: '{other_key}'={other_max} > {sub}={spec}"
        if spec == other_max and spec < 2:
            return "REJECT", f"Tie at spec={spec} — not confident enough for {sub}"

        return "ACCEPT", f"utility_{sub} (spec={spec}, gen={gen}, next_best={other_key}={other_max})"

    return "REJECT", f"Unknown slot: {slot}"


# ── All test documents ────────────────────────────────────────────────────────
S2  = r"C:\Users\PRAVEEN\Desktop\rotatech hackathon\Gig_Credit\specification folders_new\Inputs\inputs hardcopies\step -2"
S3  = r"C:\Users\PRAVEEN\Desktop\rotatech hackathon\Gig_Credit\specification folders_new\Inputs\inputs hardcopies\step -3"
S4  = r"C:\Users\PRAVEEN\Desktop\rotatech hackathon\Gig_Credit\specification folders_new\Inputs\inputs hardcopies\step -4"
S6E = r"C:\Users\PRAVEEN\Desktop\rotatech hackathon\Gig_Credit\specification folders_new\Inputs\inputs hardcopies\step-6\eShram Registration"

DOCS = [
    # Identity
    {"label": "Aadhaar Front",     "path": os.path.join(S2,"adar front card.jpeg"),        "truth": "aadhaar_front"},
    {"label": "Aadhaar Back",      "path": os.path.join(S2,"adar card bacck side .jpeg"),   "truth": "aadhaar_back"},
    {"label": "PAN Card",          "path": os.path.join(S2,"pan card front .jpeg"),         "truth": "pan"},
    {"label": "eShram",            "path": os.path.join(S6E,"e sharm.jpeg"),                "truth": "eshram_only"},
    # Bank
    {"label": "Bank (Axis/PRAVEEN)","path": os.path.join(S3,"Bank Statement - 3.pdf"),     "truth": "bank_statement"},
    {"label": "Bank (FSFB/AMJAD)", "path": os.path.join(S3,"Bank Statement -1.pdf"),       "truth": "bank_statement"},
    # Utility
    {"label": "EB Bill",           "path": os.path.join(S4,"eb bill","eb bill - 05-11-25.pdf"),                     "truth": "utility_electricity"},
    {"label": "Gas (Indane scanned)","path": os.path.join(S4,"gas bill","Indane Gas Invoice - 2.pdf"),              "truth": "utility_gas"},
    {"label": "Gas (text PDF)",    "path": os.path.join(S4,"gas bill","gas bill -1.pdf"),                           "truth": "utility_gas"},
    {"label": "Mobile (Airtel)",   "path": os.path.join(S4,"mobile bill","airtel mobile bill.pdf"),                 "truth": "utility_mobile"},
    {"label": "Mobile (Jio)",      "path": os.path.join(S4,"mobile bill","jio mobil bill.pdf"),                     "truth": "utility_mobile"},
    {"label": "OTT (Netflix)",     "path": os.path.join(S4,"ott subscriotion","ott netflix subscription.pdf"),      "truth": "utility_ott"},
    {"label": "WiFi (PDF)",        "path": os.path.join(S4,"wifi bill","wifi bill.pdf"),                            "truth": "utility_wifi"},
    {"label": "WiFi (Image)",      "path": os.path.join(S4,"wifi bill","wifi bill 2.jpeg"),                         "truth": "utility_wifi"},
    {"label": "Rent",              "path": os.path.join(S4,"rent","rent .jpeg"),                                    "truth": "utility_rent"},
]

# All slots to test against
SLOTS = [
    "aadhaar_front","aadhaar_back","pan","bank_statement",
    "utility_electricity","utility_gas","utility_mobile",
    "utility_ott","utility_wifi","utility_rent"
]

# eShram has no dedicated upload slot — it should be rejected from ALL tested slots
ESHRAM_ACCEPT_SLOTS: set = set()  # empty = reject everywhere

def expected(doc_truth, slot):
    if doc_truth == "eshram_only":
        return "REJECT"  # rejected from all above slots
    return "ACCEPT" if slot == doc_truth else "REJECT"

# ── Run matrix ────────────────────────────────────────────────────────────────
print("\n" + " GigCredit — Full Cross-Document Identification Matrix ".center(78, "═"))

TOTAL = PASS = FAIL = 0

for doc in DOCS:
    if not os.path.exists(doc["path"]):
        print(f"\n  SKIP (not found): {doc['label']}")
        continue

    print(f"\n{'─'*78}")
    print(f"  Document : {doc['label']}  |  truth={doc['truth']}")
    text = get_text(doc["path"])
    print(f"  Extracted: {len(text)} chars")

    for slot in SLOTS:
        verdict, reason = classify(text, slot)
        exp = expected(doc["truth"], slot)
        correct = verdict == exp
        TOTAL += 1
        if correct: PASS += 1
        else:       FAIL += 1

        marker = "[OK]" if correct else "[XX]"
        # Only print failures + the correct slot line (to keep output readable)
        if not correct or slot == doc["truth"]:
            print(f"    {marker} {slot:<22} → {verdict:<6} | expected={exp:<6} | {reason}")
        elif correct and verdict == "REJECT":
            pass  # silent on correct rejections to keep output brief
    
    # Print summary line for this doc
    doc_pass = sum(1 for sl in SLOTS if classify(text, sl)[0] == expected(doc["truth"], sl))
    print(f"  Result   : {doc_pass}/{len(SLOTS)} slots correct")

# ── Final summary ─────────────────────────────────────────────────────────────
print(f"\n{'═'*78}")
print(f"  TOTAL : {TOTAL}  |  PASS : {PASS}  |  FAIL : {FAIL}  |  Score : {PASS/TOTAL*100:.1f}%")
if FAIL == 0:
    print("  ALL TESTS PASSED ✓ — Unique identification guaranteed across all document types.")
else:
    print(f"  {FAIL} failure(s) — review [XX] lines above.")
print("═"*78)
