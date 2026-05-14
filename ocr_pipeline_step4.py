"""
GigCredit Step 4 — Utility Bills OCR Pipeline
Extracts structured data from EB, Gas, Mobile, OTT, and WiFi bills.
"""
import sys, os, re, json, datetime, cv2
import numpy as np

sys.stdout.reconfigure(encoding='utf-8')

import fitz  # PyMuPDF
from paddleocr import PaddleOCR

# ── 1. Init OCR Engine ────────────────────────────────────────────────────────
_paddle = PaddleOCR(use_angle_cls=True, lang='en', show_log=False)

# ── 2. Quality Gate ───────────────────────────────────────────────────────────
def check_image_quality(image_path):
    if image_path.lower().endswith(".pdf"):
        doc = fitz.open(image_path)
        pc = len(doc)
        doc.close()
        return {"passed": True, "reason": "PDF bypassed quality check", "page_count": pc, "file_size_kb": round(os.path.getsize(image_path)/1024, 1)}
    
    img = cv2.imread(image_path)
    if img is None:
        return {"passed": False, "reason": "Cannot read image"}

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    blur_val = cv2.Laplacian(gray, cv2.CV_64F).var()
    brightness = np.mean(gray)
    h, w = img.shape[:2]

    # Thresholds
    BLUR_THRESH = 30.0
    BRIGHT_MAX = 240.0
    RES_MIN = 300

    reasons = []
    if blur_val < BLUR_THRESH: reasons.append(f"Too blurry ({blur_val:.1f})")
    if brightness > BRIGHT_MAX: reasons.append(f"Too bright/overexposed ({brightness:.1f})")
    if h < RES_MIN or w < RES_MIN: reasons.append(f"Low resolution ({w}x{h})")

    passed = len(reasons) == 0
    return {
        "passed": passed,
        "reason": "OK" if passed else " | ".join(reasons),
        "blur_score": round(blur_val, 2),
        "brightness": round(brightness, 2),
        "resolution": f"{w}x{h}"
    }

# ── 3. Text Extraction ────────────────────────────────────────────────────────
def extract_text(path):
    if path.lower().endswith(".pdf"):
        pdf_res = _extract_pdf(path)
        # If PyMuPDF yields almost nothing, it's likely a scanned PDF. Fallback to image extraction (conceptually, or let OCR handle if converted, but PaddleOCR handles PDFs too)
        if len(pdf_res["raw"].strip()) < 50:
            print("  [Fallback] Scanned PDF detected. Using PaddleOCR...")
            return _extract_image(path)
        return pdf_res
    else:
        return _extract_image(path)

def _extract_pdf(path):
    doc = fitz.open(path)
    all_lines = []
    for page in doc:
        raw = page.get_text("text")
        for line in raw.splitlines():
            line = line.strip()
            if line:
                all_lines.append(line)
    doc.close()
    return {"lines": all_lines, "raw": " ".join(all_lines)}

def _extract_image(path):
    result = _paddle.ocr(path, cls=True)
    all_lines = []
    if result and result[0]:
        for item in result[0]:
            text = item[1][0] if isinstance(item[1], (list,tuple)) else str(item[1])
            text = text.strip()
            if text:
                all_lines.append(text)
    return {"lines": all_lines, "raw": " ".join(all_lines)}

# ── 4. Classification & Validation ────────────────────────────────────────────
def count_matches(text, keywords):
    t = text.lower()
    return sum(1 for k in keywords if k in t)

UTILITY_KEYWORDS = {
    "eb_bill": ["electricity", "tangedco", "energy charges", "power distribution", "kwh", "meter number", "reading"],
    "gas_bill": ["gas", "indane", "bharat gas", "hp gas", "cylinder", "png", "lpg", "distributor"],
    "mobile_bill": ["mobile", "airtel", "jio", "vodafone", "postpaid", "telecom", "talktime", "data usage"],
    "ott_subscription": ["netflix", "amazon prime", "hotstar", "subscription", "ott", "plan details"],
    "wifi_bill": ["wifi", "broadband", "fiber", "internet", "act fibernet", "jiofiber", "airtel xstream", "data balance"]
}

def classify_document(raw_text):
    scores = {}
    for doc_type, keywords in UTILITY_KEYWORDS.items():
        scores[doc_type] = count_matches(raw_text, keywords)
    
    # Sort by score
    sorted_scores = sorted(scores.items(), key=lambda x: x[1], reverse=True)
    best_match, best_score = sorted_scores[0]

    # Additional generic utility checks
    generic_utility = count_matches(raw_text, ["bill", "invoice", "payment", "due date", "amount payable", "customer no", "consumer no"])
    
    if best_score > 0 or generic_utility >= 2:
        # If specific score is 0 but generic is high, fallback to unknown_utility
        return best_match if best_score > 0 else "unknown_utility", max(best_score, generic_utility)
    
    return "UNKNOWN", 0

# ── 5. Field Extraction ───────────────────────────────────────────────────────
def extract_fields(lines, doc_type):
    data = {
        "bill_amount": None,
        "due_date": None,
        "invoice_number": None,
        "provider": None
    }
    
    raw_text_upper = " ".join(lines).upper()

    # Generic Money Regex
    # Looks for Rs, INR, ₹ followed by numbers, or Amount Payable: X
    money_pattern = re.compile(r'(?:RS\.?|INR|₹|AMOUNT\s*PAYABLE|TOTAL\s*AMOUNT|TOTAL|DUE)[\s:]*([0-9,]+(?:\.[0-9]{1,2})?)', re.IGNORECASE)
    
    # Generic Date Regex
    date_pattern = re.compile(r'\b(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})\b')
    
    # Generic Invoice/Bill No Regex
    invoice_pattern = re.compile(r'(?:INVOICE\s*NO|BILL\s*NO|RECEIPT\s*NO)[\s\.:]*([A-Z0-9-]+)', re.IGNORECASE)

    amounts = []
    dates = []
    
    for line in lines:
        line_clean = line.replace(',', '') # simplify for regex
        
        # Try finding amounts
        for match in money_pattern.finditer(line_clean):
            try:
                amt_str = match.group(1).replace(',', '')
                amounts.append(float(amt_str))
            except:
                pass
                
        # Try finding dates
        for match in date_pattern.finditer(line):
            dates.append(match.group(1))
            
        # Try finding invoice number
        inv_match = invoice_pattern.search(line)
        if inv_match and not data["invoice_number"]:
            data["invoice_number"] = inv_match.group(1)

    if amounts:
        # Usually the bill amount is the maximum or appears multiple times. We'll take the max as a heuristic for total amount.
        data["bill_amount"] = max(amounts)
        
    if dates:
        # Take the last date as due date heuristically
        data["due_date"] = dates[-1]

    # Extract Provider Heuristically
    if doc_type == "eb_bill" and "TANGEDCO" in raw_text_upper: data["provider"] = "TANGEDCO"
    elif doc_type == "gas_bill":
        if "INDANE" in raw_text_upper: data["provider"] = "INDANE"
        elif "BHARAT" in raw_text_upper: data["provider"] = "BHARAT GAS"
    elif doc_type == "mobile_bill" or doc_type == "wifi_bill":
        if "AIRTEL" in raw_text_upper: data["provider"] = "AIRTEL"
        elif "JIO" in raw_text_upper: data["provider"] = "JIO"
        elif "ACT" in raw_text_upper: data["provider"] = "ACT FIBERNET"
    elif doc_type == "ott_subscription":
        if "NETFLIX" in raw_text_upper: data["provider"] = "NETFLIX"
        elif "AMAZON" in raw_text_upper: data["provider"] = "AMAZON"

    return data

# ── 6. Main Pipeline ──────────────────────────────────────────────────────────
def process_step4(file_path):
    print(f"\n=================================================================")
    print(f"  File : {os.path.basename(file_path)}")
    print(f"=================================================================")
    
    # 1. Quality
    quality = check_image_quality(file_path)
    print(f"  Quality : {quality}")
    if not quality["passed"]:
        return {"status": "LOW_QUALITY_IMAGE", "reason": quality["reason"]}

    # 2. Extract
    print(f"  Extracting text...")
    ext = extract_text(file_path)
    lines, raw = ext["lines"], ext["raw"]
    print(f"  Lines extracted: {len(lines)}")

    # 3. Classify
    doc_type, score = classify_document(raw)
    print(f"  Detected : {doc_type} (score={score})")

    # 4. Validate
    if doc_type == "UNKNOWN":
        print(f"  Status   : WRONG_DOCUMENT")
        return {"status": "WRONG_DOCUMENT", "reason": "Could not identify utility bill type."}

    # 5. Extract Fields
    fields = extract_fields(lines, doc_type)
    
    print(f"\n  --- Extracted Fields ---")
    for k, v in fields.items():
        print(f"  {k:<30}: {v}")

    # ML Feature formatting (for temp storage)
    ml_features = {
        "utility_type": doc_type,
        "bill_amount": fields["bill_amount"],
        "has_recent_bill": True if fields["due_date"] else False
    }

    result = {
        "step": "step_4",
        "status": "ACCEPTED",
        "doc_type": doc_type,
        "completed_at": datetime.datetime.now().isoformat(),
        "verified": True,
        "ml_features": ml_features,
        "data": fields
    }
    return result

if __name__ == "__main__":
    S4 = r"C:\Users\PRAVEEN\Desktop\rotatech hackathon\Gig_Credit\specification folders_new\Inputs\inputs hardcopies\step -4"
    
    test_files = [
        os.path.join(S4, "eb bill", "eb bill - 05-11-25.pdf"),
        os.path.join(S4, "gas bill", "Indane Gas Invoice - 2.pdf"),
        os.path.join(S4, "mobile bill", "airtel mobile bill.pdf"),
        os.path.join(S4, "mobile bill", "jio mobil bill.pdf"),
        os.path.join(S4, "ott subscriotion", "ott netflix subscription.pdf"),
        os.path.join(S4, "wifi bill", "wifi bill 2.jpeg")
    ]

    results = []
    print("\n========GigCredit Step 4 — Utility Bills OCR Pipeline========")
    for path in test_files:
        if os.path.exists(path):
            r = process_step4(path)
            results.append(r)
        else:
            print(f"\nFile not found: {path}")

    # 7. Save Temp Storage
    out_file = "step4_ocr_results.json"
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)
    print(f"\n=================================================================")
    print(f"  STEP 4 ML PROFILE SAVED TO: {out_file}")
    print(f"=================================================================\n")
