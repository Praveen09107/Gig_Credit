"""
Classification-only stress test.
Bypasses quality check — forces OCR + classification on all docs.
Proves the keyword exclusion logic works independently of quality gate.
"""
import sys, os, re
sys.stdout.reconfigure(encoding='utf-8')
from paddleocr import PaddleOCR

_ocr = PaddleOCR(use_angle_cls=True, lang='en', show_log=False)

# ── Exact same keyword tables from ocr_pipeline_step2.py ─────────────────────
ESHRAM_STRONG = ["e-shram", "eshram", "universal account number", "uan",
                 "ministry of labour", "eshram.gov.in", "eshram-care",
                 "primary occupation", "blood group"]

AADHAAR_FRONT_POSITIVE  = ["uidai","aadhaar","aadhar","government of india","unique identification"]
AADHAAR_FRONT_STRONG    = ["male","female","dob","date of birth","year of birth"]
AADHAAR_FRONT_NEGATIVE  = ["address:","s/o:","c/o:","w/o:","d/o:",
                            "help@uidai","www.uidai","e-shram","eshram","uan",
                            "ministry of labour","income tax","permanent account number"]

AADHAAR_BACK_POSITIVE   = ["uidai","aadhaar","aadhar","unique identification authority"]
AADHAAR_BACK_STRONG     = ["address:","s/o:","c/o:","w/o:","d/o:","dist:","help@uidai","www.uidai.gov.in"]
AADHAAR_BACK_NEGATIVE   = ["e-shram","eshram","uan","ministry of labour","income tax","permanent account number"]

PAN_POSITIVE    = ["income tax","permanent account","income tax department"]
PAN_STRONG      = ["permanent account number card","father","fathers name"]
PAN_NEGATIVE    = ["uidai","aadhaar","aadhar","e-shram","eshram","uan","ministry of labour"]

def run_ocr(path):
    result = _ocr.ocr(path, cls=True)
    lines = []
    if result and result[0]:
        for item in result[0]:
            text = item[1][0] if isinstance(item[1], (list,tuple)) else str(item[1])
            if text.strip():
                lines.append(text.strip())
    return lines

def classify(lines):
    text_lower = " ".join(lines).lower()
    full_text  = " ".join(lines)

    # PRIORITY 1: eShram — hard exclusion
    eshram_hits = sum(1 for kw in ESHRAM_STRONG if kw in text_lower)
    if eshram_hits >= 2:
        matched = [kw for kw in ESHRAM_STRONG if kw in text_lower]
        return "eshram", min(0.5 + eshram_hits*0.1, 1.0), matched

    # PRIORITY 2: PAN
    pan_neg = sum(1 for kw in PAN_NEGATIVE if kw in text_lower)
    if pan_neg == 0:
        pan_score  = sum(0.25 for kw in PAN_POSITIVE if kw in text_lower)
        pan_score += sum(0.20 for kw in PAN_STRONG   if kw in text_lower)
        if re.findall(r'\b[A-Z]{5}[0-9]{4}[A-Z]\b', full_text):
            pan_score += 0.50
        if pan_score >= 0.50:
            return "pan", min(pan_score,1.0), []

    # PRIORITY 3: Aadhaar BACK
    back_neg = sum(1 for kw in AADHAAR_BACK_NEGATIVE if kw in text_lower)
    if back_neg == 0:
        back_score  = sum(0.20 for kw in AADHAAR_BACK_POSITIVE if kw in text_lower)
        back_score += sum(0.25 for kw in AADHAAR_BACK_STRONG   if kw in text_lower)
        if re.search(r'\b\d{4}\s?\d{4}\s?\d{4}\b', full_text): back_score += 0.20
        if back_score >= 0.50:
            return "aadhaar_back", min(back_score,1.0), []

    # PRIORITY 4: Aadhaar FRONT
    front_neg = sum(1 for kw in AADHAAR_FRONT_NEGATIVE if kw in text_lower)
    if front_neg == 0:
        front_score  = sum(0.20 for kw in AADHAAR_FRONT_POSITIVE if kw in text_lower)
        front_score += sum(0.15 for kw in AADHAAR_FRONT_STRONG   if kw in text_lower)
        if re.search(r'\b\d{4}\s?\d{4}\s?\d{4}\b', full_text): front_score += 0.20
        if front_score >= 0.40:
            return "aadhaar_front", min(front_score,1.0), []

    return "UNKNOWN", 0.0, []

SLOT_ACCEPT = {
    "aadhaar_front": ["aadhaar_front"],
    "aadhaar_back":  ["aadhaar_back"],
    "pan":           ["pan"],
    "eshram":        ["eshram"],
}

def validate(detected, slot):
    accepted = SLOT_ACCEPT.get(slot, [slot])
    if detected in accepted: return "ACCEPTED", None
    return "REJECTED", f"Uploaded '{detected}' → Expected '{slot}'"

# ── DOCUMENTS ─────────────────────────────────────────────────────────────────
S2 = r"C:\Users\PRAVEEN\Desktop\rotatech hackathon\Gig_Credit\specification folders_new\Inputs\inputs hardcopies\step -2"
S6 = r"C:\Users\PRAVEEN\Desktop\rotatech hackathon\Gig_Credit\specification folders_new\Inputs\inputs hardcopies\step-6\eShram Registration"

DOCS = [
    {"path": os.path.join(S2, "adar front card.jpeg"),       "label": "Aadhaar Front",    "truth": "aadhaar_front"},
    {"path": os.path.join(S2, "adar card bacck side .jpeg"), "label": "Aadhaar Back",     "truth": "aadhaar_back"},
    {"path": os.path.join(S2, "pan card front .jpeg"),       "label": "PAN Card",         "truth": "pan"},
    {"path": os.path.join(S6, "e sharm.jpeg"),               "label": "eShram Card",      "truth": "eshram"},
]

SLOTS = ["aadhaar_front", "aadhaar_back", "pan", "eshram"]

# ── RUN ───────────────────────────────────────────────────────────────────────
print("\n" + "GigCredit — Document Classifier Stress Test".center(75,"="))
print("(Quality check BYPASSED — testing raw classifier only)\n")

for doc in DOCS:
    print(f"\n{'─'*75}")
    print(f"  Document : {doc['label']}")
    print(f"  File     : {os.path.basename(doc['path'])}")

    lines = run_ocr(doc["path"])
    print(f"  OCR lines: {len(lines)}")

    detected, conf, matched_kw = classify(lines)
    print(f"  Detected : {detected.upper()}  (confidence={conf})")
    if matched_kw:
        print(f"  eShram KW: {matched_kw}")
    print(f"  Expected : {doc['truth'].upper()}")
    correct = "CORRECT" if detected == doc["truth"] else "WRONG"
    print(f"  Result   : [{correct}]")

    print(f"\n  Slot validation (what happens when uploaded to each slot):")
    for slot in SLOTS:
        verdict, reason = validate(detected, slot)
        marker = "OK " if verdict=="ACCEPTED" else "NO"
        print(f"    [{marker}] {slot:<16} → {verdict}" + (f" — {reason}" if reason else ""))
    print()

print("="*75)
print("LEGEND: [OK] = Accepted correctly  [NO] = Rejected correctly")
print("        Any ACCEPTED in wrong slot = classifier BUG")
print("="*75)
