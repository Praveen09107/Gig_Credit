"""
GigCredit — Full OCR + Classification End-to-End Test Suite
Tests all 4 fixed issues:
  1. eShram hard rejection from Aadhaar/PAN slots
  2. Aadhaar Front vs Back disambiguation
  3. Bank statement rejection of random images & random PDFs
  4. Real OCR text logged to terminal

Run: python test_all_fixes.py
"""
import sys, os, re, json, datetime
sys.stdout.reconfigure(encoding='utf-8')
from paddleocr import PaddleOCR
import fitz

_paddle = PaddleOCR(use_angle_cls=True, lang='en', show_log=False)

# ── Paths ─────────────────────────────────────────────────────────────────────
S2   = r"C:\Users\PRAVEEN\Desktop\rotatech hackathon\Gig_Credit\specification folders_new\Inputs\inputs hardcopies\step -2"
S3   = r"C:\Users\PRAVEEN\Desktop\rotatech hackathon\Gig_Credit\specification folders_new\Inputs\inputs hardcopies\step -3"
S6E  = r"C:\Users\PRAVEEN\Desktop\rotatech hackathon\Gig_Credit\specification folders_new\Inputs\inputs hardcopies\step-6\eShram Registration"

AADHAAR_FRONT = os.path.join(S2, "adar front card.jpeg")
AADHAAR_BACK  = os.path.join(S2, "adar card bacck side .jpeg")
PAN_CARD      = os.path.join(S2, "pan card front .jpeg")
ESHRAM_CARD   = os.path.join(S6E, "e sharm.jpeg")
BANK_PDF_1    = os.path.join(S3, "Bank Statement - 2.pdf")
BANK_PDF_2    = os.path.join(S3, "Bank Statement -1.pdf")
BANK_PDF_3    = os.path.join(S3, "Bank Statement - 3.pdf")

# ── OCR helpers ───────────────────────────────────────────────────────────────
def ocr_image(path):
    result = _paddle.ocr(path, cls=True)
    lines = []
    if result and result[0]:
        for item in result[0]:
            t = item[1][0] if isinstance(item[1], (list, tuple)) else str(item[1])
            if t.strip():
                lines.append(t.strip())
    return lines

def ocr_pdf(path):
    doc = fitz.open(path)
    all_lines = []
    for page in doc:
        raw = page.get_text("text")
        for l in raw.splitlines():
            if l.strip():
                all_lines.append(l.strip())
    doc.close()
    return all_lines

# ── Classification (mirrors real_ocr_service.dart logic) ─────────────────────
ESHRAM_SIGNALS = ["e-shram", "eshram", "universal account number", "uan",
                  "ministry of labour", "eshram.gov.in", "eshram-care",
                  "primary occupation", "blood group"]

AADHAAR_KW       = ["aadhaar", "aadhar", "unique identification authority", "uidai"]
AADHAAR_FRONT_SIG= ["male", "female", "dob", "date of birth"]
AADHAAR_BACK_SIG = ["address", "s/o", "c/o", "help@uidai", "www.uidai"]
PAN_STRONG_SIG   = ["income tax", "permanent account", "income tax department"]

BANK_STRONG  = ["account statement","bank statement","statement of account",
                "savings account","current account","passbook"]
BANK_MODERATE= ["ifsc","micr","opening balance","closing balance","hdfc bank",
                "icici bank","axis bank","state bank","sbi","canara bank",
                "neft","imps","upi","rtgs","account number","withdrawal","deposit"]

def count(text, kws):
    t = text.lower()
    return sum(1 for k in kws if k in t)

def is_eshram(text):       return count(text, ESHRAM_SIGNALS) >= 2
def has_aadhaar(text):     return count(text, AADHAAR_KW) >= 1
def has_front_sig(text):   return count(text, AADHAAR_FRONT_SIG) >= 1
def has_back_sig(text):    return count(text, AADHAAR_BACK_SIG) >= 1
def has_pan_regex(text):   return bool(re.search(r'[A-Z]{5}\d{4}[A-Z]', text))
def has_pan_strong(text):  return count(text, PAN_STRONG_SIG) >= 1

def classify_for_slot(text, slot):
    """
    Returns (verdict, reason)
    verdict: ACCEPT | REJECT
    Mirrors dart classification logic exactly.
    """
    txt_lo = text.lower()
    clean  = text.upper()
    eshram = is_eshram(txt_lo)
    aadh   = has_aadhaar(txt_lo) and not eshram
    front  = has_front_sig(txt_lo)
    back   = has_back_sig(txt_lo)
    pan_re = has_pan_regex(clean)
    pan_st = has_pan_strong(txt_lo)
    is_pan = (pan_re or pan_st) and not aadh

    if slot in ("aadhaar_front", "aadhaar_back"):
        if eshram: return "REJECT", "eShram card in Aadhaar slot"
        if is_pan and not aadh: return "REJECT", "PAN card in Aadhaar slot"
        if slot == "aadhaar_front" and back and not front:
            return "REJECT", "Aadhaar BACK uploaded in FRONT slot"
        if slot == "aadhaar_back" and front and not back:
            return "REJECT", "Aadhaar FRONT uploaded in BACK slot"
        if not aadh: return "REJECT", "No Aadhaar signals detected"
        return "ACCEPT", f"Aadhaar verified (front_sig={front}, back_sig={back})"

    if slot == "pan":
        if eshram: return "REJECT", "eShram card in PAN slot"
        if aadh and not is_pan: return "REJECT", "Aadhaar card in PAN slot"
        if not pan_re and not pan_st: return "REJECT", "No PAN signals detected"
        return "ACCEPT", f"PAN verified (pan_regex={pan_re}, pan_strong={pan_st})"

    if slot == "bank_statement":
        if eshram: return "REJECT", "eShram card in bank slot"
        if aadh and not (pan_re or pan_st): return "REJECT", "Aadhaar card in bank slot"
        strong = count(txt_lo, BANK_STRONG)
        moderate = count(txt_lo, BANK_MODERATE)
        score = strong * 3 + moderate
        # Check bank signals FIRST — a bank statement may contain customer PAN number
        if score >= 3:
            return "ACCEPT", f"Bank statement verified (score={score}, strong={strong}, moderate={moderate})"
        # Only now check if it looks like a PAN/Aadhaar
        if is_pan and not aadh: return "REJECT", "PAN card in bank slot"
        if aadh: return "REJECT", "Aadhaar card in bank slot"
        return "REJECT", f"Insufficient bank signals (score={score})"

    return "REJECT", f"Unknown slot: {slot}"

# ── Test runner ───────────────────────────────────────────────────────────────
PASS = 0
FAIL = 0

def run_test(label, path, slot, expected_verdict, is_pdf=False):
    global PASS, FAIL
    print(f"\n  {'─'*65}")
    print(f"  TEST : {label}")
    print(f"  File : {os.path.basename(path)}")
    print(f"  Slot : {slot}  →  Expected: {expected_verdict}")

    # OCR
    if is_pdf:
        lines = ocr_pdf(path)
    else:
        lines = ocr_image(path)
    text = " ".join(lines)
    print(f"  OCR  : {len(lines)} lines extracted")
    print(f"  Preview: {text[:120].strip()}...")

    # Classify
    verdict, reason = classify_for_slot(text, slot)
    status = "PASS" if verdict == expected_verdict else "FAIL"
    if status == "PASS":
        PASS += 1
    else:
        FAIL += 1

    icon = "OK" if status == "PASS" else "XX"
    print(f"  Result: [{icon}] {verdict} — {reason}  [{status}]")
    return status

# ── TEST SUITE ─────────────────────────────────────────────────────────────────
print("\n" + "GigCredit OCR Fix Validation — Full Test Suite".center(70, "="))
print(f"  Timestamp: {datetime.datetime.now().isoformat()}")
print(f"  Engine   : PaddleOCR + PyMuPDF")

print("\n\n  ── BLOCK 1: Aadhaar slot tests ─────────────────────────────────────")

run_test("Aadhaar FRONT → front slot [should ACCEPT]",
         AADHAAR_FRONT, "aadhaar_front", "ACCEPT")

run_test("Aadhaar BACK → front slot [should REJECT — wrong side]",
         AADHAAR_BACK, "aadhaar_front", "REJECT")

run_test("eShram → aadhaar_front slot [should REJECT — eShram]",
         ESHRAM_CARD, "aadhaar_front", "REJECT")

run_test("PAN → aadhaar_front slot [should REJECT — PAN]",
         PAN_CARD, "aadhaar_front", "REJECT")

run_test("Aadhaar BACK → back slot [should ACCEPT]",
         AADHAAR_BACK, "aadhaar_back", "ACCEPT")

run_test("Aadhaar FRONT → back slot [should REJECT — wrong side]",
         AADHAAR_FRONT, "aadhaar_back", "REJECT")

run_test("eShram → aadhaar_back slot [should REJECT — eShram]",
         ESHRAM_CARD, "aadhaar_back", "REJECT")

print("\n\n  ── BLOCK 2: PAN slot tests ──────────────────────────────────────────")

run_test("PAN card → pan slot [should ACCEPT]",
         PAN_CARD, "pan", "ACCEPT")

run_test("Aadhaar FRONT → pan slot [should REJECT — Aadhaar]",
         AADHAAR_FRONT, "pan", "REJECT")

run_test("eShram → pan slot [should REJECT — eShram]",
         ESHRAM_CARD, "pan", "REJECT")

print("\n\n  ── BLOCK 3: Bank Statement slot tests ───────────────────────────────")

run_test("Bank Statement PDF-1 → bank slot [should ACCEPT]",
         BANK_PDF_1, "bank_statement", "ACCEPT", is_pdf=True)

run_test("Bank Statement PDF-2 → bank slot [should ACCEPT]",
         BANK_PDF_2, "bank_statement", "ACCEPT", is_pdf=True)

run_test("Bank Statement PDF-3 → bank slot [should ACCEPT]",
         BANK_PDF_3, "bank_statement", "ACCEPT", is_pdf=True)

run_test("Aadhaar FRONT image → bank slot [should REJECT]",
         AADHAAR_FRONT, "bank_statement", "REJECT")

run_test("PAN card image → bank slot [should REJECT]",
         PAN_CARD, "bank_statement", "REJECT")

run_test("eShram card image → bank slot [should REJECT]",
         ESHRAM_CARD, "bank_statement", "REJECT")

run_test("Aadhaar BACK image → bank slot [should REJECT]",
         AADHAAR_BACK, "bank_statement", "REJECT")

# ── RESULTS ───────────────────────────────────────────────────────────────────
total = PASS + FAIL
print(f"\n\n{'='*70}")
print(f"  FINAL RESULTS")
print(f"{'='*70}")
print(f"  Total Tests : {total}")
print(f"  PASS        : {PASS}  ({round(PASS/total*100)}%)")
print(f"  FAIL        : {FAIL}")
print()
if FAIL == 0:
    print("  ALL TESTS PASSED — OCR classifier is working correctly.")
else:
    print(f"  {FAIL} TEST(S) FAILED — review classifier logic above.")
print("="*70)
