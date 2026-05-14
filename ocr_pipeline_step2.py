"""
GigCredit — Step 2 OCR Validation Pipeline
PP-OCRv5 compatible pipeline for Aadhaar (Front/Back) and PAN card.
Runs: Quality Check → OCR → Classification → Validation → Extraction → Storage
"""

import os, re, json, math, datetime
from pathlib import Path

# ── Try PaddleOCR, fallback to EasyOCR, fallback to pytesseract ──────────────
OCR_ENGINE = None

try:
    from paddleocr import PaddleOCR
    _ocr_instance = PaddleOCR(use_angle_cls=True, lang='en', show_log=False)
    OCR_ENGINE = "paddleocr"
    print("✅ Engine: PaddleOCR")
except Exception as e:
    print(f"⚠️  PaddleOCR not available: {e}")

if not OCR_ENGINE:
    try:
        import easyocr
        _easy_reader = easyocr.Reader(['en'], verbose=False)
        OCR_ENGINE = "easyocr"
        print("✅ Engine: EasyOCR")
    except Exception as e:
        print(f"⚠️  EasyOCR not available: {e}")

if not OCR_ENGINE:
    try:
        import pytesseract
        from PIL import Image
        pytesseract.get_tesseract_version()
        OCR_ENGINE = "tesseract"
        print("✅ Engine: Tesseract")
    except Exception as e:
        print(f"⚠️  Tesseract not available: {e}")

if not OCR_ENGINE:
    print("❌ No OCR engine available. Install: pip install paddlepaddle paddleocr")
    exit(1)

# ── OpenCV for image quality ──────────────────────────────────────────────────
try:
    import cv2
    import numpy as np
    CV2_AVAILABLE = True
except ImportError:
    CV2_AVAILABLE = False
    print("⚠️  OpenCV not available — skipping blur/brightness check")

# ─────────────────────────────────────────────────────────────────────────────
# CONSTANTS
# ─────────────────────────────────────────────────────────────────────────────
BLUR_THRESHOLD = 80.0        # Laplacian variance below this = blurry
MIN_BRIGHTNESS = 40          # Mean pixel value below this = too dark
MAX_BRIGHTNESS = 220         # Mean pixel value above this = overexposed
MIN_RESOLUTION = (100, 100)  # Minimum width x height

# ── Sub-type keyword tables ────────────────────────────────────────────────

# eShram card — HARD EXCLUSION: if these appear, it is NEVER aadhaar or pan
ESHRAM_STRONG = ["e-shram", "eshram", "universal account number", "uan",
                 "ministry of labour", "eshram.gov.in", "eshram-care",
                 "primary occupation", "blood group"]

# Aadhaar FRONT — has photo side (name, DOB printed, gender)
AADHAAR_FRONT_POSITIVE = [
    "uidai", "aadhaar", "aadhar", "government of india",
    "unique identification", "आधार"
]
AADHAAR_FRONT_STRONG_SIGNALS = ["male", "female", "dob", "date of birth", "year of birth"]
AADHAAR_FRONT_NEGATIVE = [
    "address:", "s/o:", "c/o:", "w/o:", "d/o:",  # address block = back side
    "help@uidai", "www.uidai",                    # footer = back side
    "e-shram", "eshram", "uan", "ministry of labour",  # eShram
    "income tax", "permanent account number",          # PAN
]

# Aadhaar BACK — has address block
AADHAAR_BACK_POSITIVE = [
    "uidai", "aadhaar", "aadhar", "unique identification authority"
]
AADHAAR_BACK_STRONG_SIGNALS = [
    "address:", "s/o:", "c/o:", "w/o:", "d/o:", "dist:",
    "help@uidai", "www.uidai.gov.in"
]
AADHAAR_BACK_NEGATIVE = [
    "e-shram", "eshram", "uan", "ministry of labour",
    "income tax", "permanent account number",
]

# PAN keywords
PAN_POSITIVE = [
    "income tax", "permanent account", "income tax department"
]
PAN_STRONG_SIGNALS = ["permanent account number card", "father", "fathers name"]
PAN_NEGATIVE = [
    "uidai", "aadhaar", "aadhar",
    "e-shram", "eshram", "uan", "ministry of labour",
]

# ─────────────────────────────────────────────────────────────────────────────
# STEP 1: IMAGE QUALITY CHECK
# ─────────────────────────────────────────────────────────────────────────────
def check_image_quality(image_path: str) -> dict:
    if not CV2_AVAILABLE:
        return {"passed": True, "reason": "quality_check_skipped"}

    img = cv2.imread(image_path)
    if img is None:
        return {"passed": False, "reason": "FILE_UNREADABLE"}

    h, w = img.shape[:2]
    if w < MIN_RESOLUTION[0] or h < MIN_RESOLUTION[1]:
        return {"passed": False, "reason": "LOW_RESOLUTION", "resolution": f"{w}x{h}"}

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    # Blur check (Laplacian variance)
    blur_score = cv2.Laplacian(gray, cv2.CV_64F).var()

    # Brightness check
    brightness = gray.mean()

    if blur_score < BLUR_THRESHOLD:
        return {"passed": False, "reason": "BLURRY_IMAGE",
                "blur_score": round(blur_score, 2), "threshold": BLUR_THRESHOLD}

    if brightness < MIN_BRIGHTNESS:
        return {"passed": False, "reason": "TOO_DARK", "brightness": round(brightness, 2)}

    if brightness > MAX_BRIGHTNESS:
        return {"passed": False, "reason": "OVEREXPOSED", "brightness": round(brightness, 2)}

    return {
        "passed": True,
        "resolution": f"{w}x{h}",
        "blur_score": round(blur_score, 2),
        "brightness": round(brightness, 2)
    }

# ─────────────────────────────────────────────────────────────────────────────
# STEP 2: OCR PROCESSING
# ─────────────────────────────────────────────────────────────────────────────
def run_ocr(image_path: str) -> list[str]:
    """Returns list of extracted text lines, normalised."""
    lines = []

    if OCR_ENGINE == "paddleocr":
        result = _ocr_instance.ocr(image_path, cls=True)
        if result and result[0]:
            for item in result[0]:
                if item and len(item) >= 2:
                    text = item[1][0] if isinstance(item[1], (list, tuple)) else str(item[1])
                    lines.append(text.strip())

    elif OCR_ENGINE == "easyocr":
        result = _easy_reader.readtext(image_path)
        for (_, text, conf) in result:
            if conf > 0.3:
                lines.append(text.strip())

    elif OCR_ENGINE == "tesseract":
        img = Image.open(image_path)
        raw = pytesseract.image_to_string(img, config='--psm 6')
        lines = [l.strip() for l in raw.splitlines() if l.strip()]

    # Normalise: lowercase for matching, keep original for extraction
    return lines

def normalize(lines: list[str]) -> str:
    return " ".join(lines).lower()

# ─────────────────────────────────────────────────────────────────────────────
# STEP 3: STRICT MULTI-CLASS DOCUMENT CLASSIFICATION
# Priority order: eShram > PAN > aadhaar_back > aadhaar_front > UNKNOWN
# Uses POSITIVE signals for detection + NEGATIVE signals for exclusion
# ─────────────────────────────────────────────────────────────────────────────
def classify_document(lines: list[str]) -> tuple[str, float]:
    """
    Returns (sub_doc_type, confidence_score)
    sub_doc_type: 'aadhaar_front' | 'aadhaar_back' | 'pan' | 'eshram' | 'UNKNOWN'
    """
    text_lower = normalize(lines)
    full_text  = " ".join(lines)

    # ── PRIORITY 1: eShram card (hard exclusion — check FIRST) ──────────────
    eshram_hits = sum(1 for kw in ESHRAM_STRONG if kw in text_lower)
    if eshram_hits >= 2:  # 2+ strong signals = definitely eShram
        return ("eshram", min(0.5 + eshram_hits * 0.1, 1.0))

    # ── PRIORITY 2: PAN card ─────────────────────────────────────────────────
    pan_score = 0.0
    # Negative check first
    pan_neg_hits = sum(1 for kw in PAN_NEGATIVE if kw in text_lower)
    if pan_neg_hits == 0:
        for kw in PAN_POSITIVE:
            if kw in text_lower:
                pan_score += 0.25
        for kw in PAN_STRONG_SIGNALS:
            if kw in text_lower:
                pan_score += 0.20
        pan_match = re.findall(r'\b[A-Z]{5}[0-9]{4}[A-Z]\b', full_text)
        if pan_match:
            pan_score += 0.50
    if pan_score >= 0.50:
        return ("pan", min(pan_score, 1.0))

    # ── PRIORITY 3: Aadhaar BACK (address side) ──────────────────────────────
    back_score = 0.0
    back_neg_hits = sum(1 for kw in AADHAAR_BACK_NEGATIVE if kw in text_lower)
    if back_neg_hits == 0:
        for kw in AADHAAR_BACK_POSITIVE:
            if kw in text_lower:
                back_score += 0.20
        for kw in AADHAAR_BACK_STRONG_SIGNALS:
            if kw in text_lower:
                back_score += 0.25
        # Aadhaar 12-digit on back
        if re.search(r'\b\d{4}\s?\d{4}\s?\d{4}\b', full_text):
            back_score += 0.20
    if back_score >= 0.50:
        return ("aadhaar_back", min(back_score, 1.0))

    # ── PRIORITY 4: Aadhaar FRONT (photo side) ───────────────────────────────
    front_score = 0.0
    front_neg_hits = sum(1 for kw in AADHAAR_FRONT_NEGATIVE if kw in text_lower)
    if front_neg_hits == 0:
        for kw in AADHAAR_FRONT_POSITIVE:
            if kw in text_lower:
                front_score += 0.20
        for kw in AADHAAR_FRONT_STRONG_SIGNALS:
            if kw in text_lower:
                front_score += 0.15
        if re.search(r'\b\d{4}\s?\d{4}\s?\d{4}\b', full_text):
            front_score += 0.20
    if front_score >= 0.40:
        return ("aadhaar_front", min(front_score, 1.0))

    return ("UNKNOWN", 0.0)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 4: VALIDATION
# ─────────────────────────────────────────────────────────────────────────────
CONFIDENCE_THRESHOLD = 0.40

# Maps the user-facing slot name to the accepted sub_doc_types
SLOT_TO_DOC_TYPES = {
    "aadhaar_front": ["aadhaar_front"],
    "aadhaar_back":  ["aadhaar_back"],
    "aadhaar":       ["aadhaar_front", "aadhaar_back"],  # generic slot
    "pan":           ["pan"],
    "eshram":        ["eshram"],
}

DOC_TYPE_LABELS = {
    "aadhaar_front": "Aadhaar Front (photo side)",
    "aadhaar_back":  "Aadhaar Back (address side)",
    "pan":           "PAN Card",
    "eshram":        "eShram Card",
    "UNKNOWN":       "Unknown Document",
}

def validate_document(detected_type: str, expected_slot: str, confidence: float) -> dict:
    if detected_type == "UNKNOWN":
        return {"valid": False, "reason": "INVALID_DOCUMENT",
                "message": "Could not identify any known document type. Please upload the correct document."}

    accepted_types = SLOT_TO_DOC_TYPES.get(expected_slot, [expected_slot])
    if detected_type not in accepted_types:
        detected_label  = DOC_TYPE_LABELS.get(detected_type, detected_type)
        expected_labels = [DOC_TYPE_LABELS.get(t, t) for t in accepted_types]
        return {
            "valid": False,
            "reason": "WRONG_DOCUMENT",
            "message": f"Uploaded: '{detected_label}'. Expected: '{' or '.join(expected_labels)}'. Please upload the correct document."
        }

    if confidence < CONFIDENCE_THRESHOLD:
        return {"valid": False, "reason": "LOW_CONFIDENCE",
                "message": f"Confidence {confidence:.2f} below threshold {CONFIDENCE_THRESHOLD}. Image may be unclear."}

    return {"valid": True, "reason": "OK"}

# ─────────────────────────────────────────────────────────────────────────────
# STEP 5: FIELD EXTRACTION
# ─────────────────────────────────────────────────────────────────────────────
def extract_aadhaar_fields(lines: list[str]) -> dict:
    full_text = " ".join(lines)
    text_lower = normalize(lines)
    fields = {}
    warnings = []

    # Aadhaar Number (12-digit, may have spaces)
    aadhaar_matches = re.findall(r'\b\d{4}\s?\d{4}\s?\d{4}\b', full_text)
    if aadhaar_matches:
        fields["aadhaar_number"] = aadhaar_matches[0].replace(" ", "")
    else:
        warnings.append("aadhaar_number_not_found")

    # Name (typically on 2nd or 3rd line, skip header lines)
    # Look for a line that looks like a proper name (2+ words, all alpha)
    skip_keywords = ["uidai", "government", "india", "unique", "aadhar",
                     "aadhaar", "enrollment", "male", "female", "address",
                     "dob", "date", "year", "district", "state"]
    for line in lines:
        words = line.strip().split()
        if (len(words) >= 2 and
            all(w.replace(".", "").isalpha() for w in words) and
            not any(sk in line.lower() for sk in skip_keywords) and
            len(line) > 3):
            fields["name"] = line.strip()
            break

    # DOB
    dob_match = re.search(r'\b(\d{2}[/\-]\d{2}[/\-]\d{4})\b', full_text)
    if dob_match:
        fields["dob"] = dob_match.group(1)
    else:
        year_match = re.search(r'\b(19[6-9]\d|200[0-9]|201[0-9])\b', full_text)
        if year_match:
            fields["year_of_birth"] = year_match.group(1)
            warnings.append("dob_partial_only_year")

    # Gender
    gender_match = re.search(r'\b(male|female)\b', text_lower)
    if gender_match:
        fields["gender"] = gender_match.group(1).capitalize()

    # Address hint (look for PIN code)
    pin_match = re.search(r'\b(\d{6})\b', full_text)
    if pin_match and pin_match.group(1) != fields.get("aadhaar_number", ""):
        fields["pin_code"] = pin_match.group(1)

    return {"fields": fields, "warnings": warnings}


def extract_pan_fields(lines: list[str]) -> dict:
    full_text = " ".join(lines)
    text_lower = normalize(lines)
    fields = {}
    warnings = []

    # PAN Number
    pan_matches = re.findall(r'\b([A-Z]{5}[0-9]{4}[A-Z])\b', full_text)
    if pan_matches:
        fields["pan_number"] = pan_matches[0]
    else:
        warnings.append("pan_number_not_found")

    # Name (line with proper name — skip PAN/govt lines)
    skip_keywords = ["income", "tax", "department", "government", "india",
                     "permanent", "account", "number", "pan"]
    for line in lines:
        words = line.strip().split()
        if (len(words) >= 2 and
            all(w.replace(".", "").isalpha() for w in words) and
            not any(sk in line.lower() for sk in skip_keywords) and
            len(line) > 3):
            fields["name"] = line.strip()
            break

    # Father's name (line after name typically)
    if "name" in fields:
        name_idx = next((i for i, l in enumerate(lines) if fields["name"] in l), -1)
        if name_idx >= 0 and name_idx + 1 < len(lines):
            candidate = lines[name_idx + 1].strip()
            words = candidate.split()
            if (len(words) >= 2 and
                all(w.replace(".", "").isalpha() for w in words) and
                not any(sk in candidate.lower() for sk in skip_keywords)):
                fields["father_name"] = candidate

    # DOB on PAN card
    dob_match = re.search(r'\b(\d{2}/\d{2}/\d{4})\b', full_text)
    if dob_match:
        fields["dob"] = dob_match.group(1)
    else:
        warnings.append("dob_not_found")

    return {"fields": fields, "warnings": warnings}

# ─────────────────────────────────────────────────────────────────────────────
# STEP 6 + 7: STRUCTURED OUTPUT + TEMP STORAGE
# ─────────────────────────────────────────────────────────────────────────────
def build_output(status: str, doc_type: str, confidence: float,
                 fields: dict, warnings: list, quality: dict,
                 raw_lines: list[str], file_name: str) -> dict:

    extraction_result = {
        "status": status,
        "doc_type": doc_type,
        "confidence": confidence,
        "file": file_name,
        "ocr_engine": OCR_ENGINE,
        "quality": quality,
        "fields": fields,
        "warnings": warnings,
        "lines_extracted": len(raw_lines),
    }

    temp_storage = {
        "step": "step_2",
        "doc_type": doc_type,
        "verified": status == "ACCEPTED",
        "timestamp": datetime.datetime.now().isoformat(),
        "data": fields,
        "warnings": warnings,
    }

    return {"extraction": extraction_result, "temp_storage": temp_storage}


# ─────────────────────────────────────────────────────────────────────────────
# MAIN PIPELINE
# ─────────────────────────────────────────────────────────────────────────────
def process_document(image_path: str, expected_doc_type: str) -> dict:
    file_name = Path(image_path).name
    print(f"\n{'='*60}")
    print(f"📄 Processing: {file_name}")
    print(f"   Expected  : {expected_doc_type.upper()}")
    print(f"{'='*60}")

    # STEP 1: Quality Check
    quality = check_image_quality(image_path)
    print(f"   🔍 Quality: {quality}")
    if not quality.get("passed", True):
        return build_output(
            "LOW_QUALITY_IMAGE", "UNKNOWN", 0.0, {}, [quality["reason"]], quality, [], file_name
        )

    # STEP 2: OCR
    print(f"   🔠 Running OCR ({OCR_ENGINE})...")
    lines = run_ocr(image_path)
    print(f"   📝 Extracted {len(lines)} text lines")
    for i, line in enumerate(lines[:20]):  # Print first 20 lines
        print(f"      [{i+1:02d}] {line}")
    if len(lines) > 20:
        print(f"      ... and {len(lines)-20} more lines")

    if not lines:
        return build_output(
            "NO_TEXT_FOUND", "UNKNOWN", 0.0, {}, ["ocr_returned_empty"], quality, [], file_name
        )

    # STEP 3: Classification
    detected_type, confidence = classify_document(lines)
    print(f"   🏷️  Detected: {detected_type.upper()} (confidence: {confidence})")

    # STEP 4: Validation (strict sub-type check)
    validation = validate_document(detected_type, expected_doc_type, confidence)
    print(f"   Valid    : {validation['valid']} — {validation['reason']}")
    if not validation["valid"]:
        print(f"   REJECT   : {validation['message']}")
        return build_output(
            validation["reason"], detected_type, confidence,
            {}, [validation["message"]], quality, lines, file_name
        )

    # STEP 5: Field Extraction
    if detected_type in ("aadhaar_front", "aadhaar_back", "aadhaar"):
        extraction = extract_aadhaar_fields(lines)
    elif detected_type == "pan":
        extraction = extract_pan_fields(lines)
    else:
        extraction = {"fields": {}, "warnings": ["no_extractor_for_type"]}

    fields = extraction["fields"]
    warnings = extraction["warnings"]
    status = "ACCEPTED" if fields else "PARTIAL_EXTRACTION"

    print(f"   📦 Fields  : {json.dumps(fields, indent=6)}")
    if warnings:
        print(f"   ⚠️  Warnings: {warnings}")

    return build_output(status, detected_type, confidence, fields, warnings, quality, lines, file_name)


# ─────────────────────────────────────────────────────────────────────────────
# STEP 2 DOCUMENT SET
# ─────────────────────────────────────────────────────────────────────────────
BASE_PATH = r"C:\Users\PRAVEEN\Desktop\rotatech hackathon\Gig_Credit\specification folders_new\Inputs\inputs hardcopies\step -2"

ESHRAM_PATH = r"C:\Users\PRAVEEN\Desktop\rotatech hackathon\Gig_Credit\specification folders_new\Inputs\inputs hardcopies\step-6\eShram Registration\e sharm.jpeg"

STEP2_DOCS = [
    {"path": os.path.join(BASE_PATH, "adar front card.jpeg"),        "expected": "aadhaar_front", "label": "Aadhaar Front [CORRECT]"},
    {"path": os.path.join(BASE_PATH, "adar card bacck side .jpeg"),  "expected": "aadhaar_front", "label": "Aadhaar BACK in FRONT slot [WRONG]"},
    {"path": ESHRAM_PATH,                                             "expected": "aadhaar_front", "label": "eShram in Aadhaar Front slot [WRONG]"},
    {"path": ESHRAM_PATH,                                             "expected": "pan",           "label": "eShram in PAN slot [WRONG]"},
    {"path": os.path.join(BASE_PATH, "pan card front .jpeg"),        "expected": "pan",           "label": "PAN Card Front [CORRECT]"},
    {"path": os.path.join(BASE_PATH, "adar front card.jpeg"),        "expected": "pan",           "label": "Aadhaar Front in PAN slot [WRONG]"},
    {"path": os.path.join(BASE_PATH, "adar card bacck side .jpeg"),  "expected": "aadhaar_back",  "label": "Aadhaar Back [CORRECT]"},
    {"path": ESHRAM_PATH,                                             "expected": "aadhaar_back",  "label": "eShram in Aadhaar Back slot [WRONG]"},
]

# ─────────────────────────────────────────────────────────────────────────────
# RUN
# ─────────────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    print("\n" + "🚀 GigCredit Step 2 — OCR Validation Pipeline ".center(60, "="))
    print(f"Engine: {OCR_ENGINE}")
    print(f"Docs  : {len(STEP2_DOCS)}\n")

    all_results = []
    temp_store  = {}  # Cumulative verified profile for Step 2

    for doc in STEP2_DOCS:
        print(f"\n📌 [{doc['label']}]")
        result = process_document(doc["path"], doc["expected"])
        all_results.append({doc["label"]: result})

        # Merge verified fields into temp store
        storage = result.get("temp_storage", {})
        if storage.get("verified"):
            doc_key = f"{doc['expected']}_{doc['label'].lower().replace(' ', '_')}"
            temp_store[doc_key] = storage["data"]

    # Final consolidated Step 2 temp profile
    step2_profile = {
        "step": "step_2",
        "completed_at": datetime.datetime.now().isoformat(),
        "aadhaar_verified": any(
            r.get(k, {}).get("temp_storage", {}).get("verified", False)
            for r in all_results for k in r
            if "aadhaar" in k.lower()
        ),
        "pan_verified": any(
            r.get(k, {}).get("temp_storage", {}).get("verified", False)
            for r in all_results for k in r
            if "pan" in k.lower()
        ),
        "extracted_data": temp_store,
    }

    # Save to JSON
    output_path = os.path.join(
        r"C:\Users\PRAVEEN\Desktop\rotatech hackathon\Gig_Credit",
        "step2_ocr_results.json"
    )
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump({
            "pipeline_results": all_results,
            "step2_profile": step2_profile
        }, f, indent=2, ensure_ascii=False)

    print("\n" + "="*60)
    print("📊 STEP 2 SUMMARY")
    print("="*60)
    for doc in STEP2_DOCS:
        for r in all_results:
            if doc["label"] in r:
                status = r[doc["label"]]["extraction"]["status"]
                conf   = r[doc["label"]]["extraction"]["confidence"]
                fields = r[doc["label"]]["extraction"]["fields"]
                icon = "✅" if status == "ACCEPTED" else "⚠️ " if "PARTIAL" in status else "❌"
                print(f"  {icon} {doc['label']:<22} │ {status:<22} │ conf={conf} │ fields={list(fields.keys())}")

    print("\n📦 STEP 2 PROFILE (for ML feature pipeline):")
    print(json.dumps(step2_profile, indent=2, ensure_ascii=False))
    print(f"\n💾 Full results saved to: {output_path}")
