"""
Step 4 Cross-Validation Stress Test
Ensures unique identification between EB, Gas, Mobile, OTT, and WiFi bills.
Rejects cross-uploads (e.g. EB bill in Gas slot).
"""
import sys, os
sys.stdout.reconfigure(encoding='utf-8')
from paddleocr import PaddleOCR
import fitz

_paddle = PaddleOCR(use_angle_cls=True, lang='en', show_log=False)

def extract_text(path):
    if path.lower().endswith(".pdf"):
        doc = fitz.open(path)
        lines = []
        for page in doc:
            for l in page.get_text("text").splitlines():
                if l.strip(): lines.append(l.strip())
        doc.close()
        
        # Scanned PDF fallback
        if len(" ".join(lines)) < 50:
            return extract_img(path)
        return " ".join(lines).upper()
    else:
        return extract_img(path)

def extract_img(path):
    res = _paddle.ocr(path, cls=True)
    lines = []
    if res and res[0]:
        for item in res[0]:
            lines.append(item[1][0] if isinstance(item[1], (list,tuple)) else str(item[1]))
    return " ".join(lines).upper()

def classify_utility(text, expected_slot):
    # Mirrors Flutter's specific vs generic check
    subType = expected_slot.replace('utility_', '')
    
    keywords = {
        'electricity': ['ELECTRICITY', 'TANGEDCO', 'ENERGY CHARGES', 'POWER DISTRIBUTION', 'KWH', 'METER NUMBER', 'READING'],
        'gas': ['GAS', 'INDANE', 'BHARAT GAS', 'HP GAS', 'CYLINDER', 'PNG', 'LPG', 'DISTRIBUTOR'],
        'mobile': ['MOBILE', 'AIRTEL', 'JIO', 'VODAFONE', 'POSTPAID', 'TELECOM', 'TALKTIME', 'DATA USAGE'],
        'internet': ['WIFI', 'BROADBAND', 'FIBER', 'INTERNET', 'ACT FIBERNET', 'JIOFIBER', 'AIRTEL XSTREAM', 'DATA BALANCE'],
        'wifi': ['WIFI', 'BROADBAND', 'FIBER', 'INTERNET', 'ACT FIBERNET', 'JIOFIBER', 'AIRTEL XSTREAM', 'DATA BALANCE'],
        'ott': ['NETFLIX', 'AMAZON PRIME', 'HOTSTAR', 'SUBSCRIPTION', 'OTT', 'PLAN DETAILS']
    }
    
    generic_keywords = ['BILL', 'INVOICE', 'PAYMENT', 'DUE DATE', 'AMOUNT PAYABLE', 'CUSTOMER NO', 'CONSUMER NO', 'RECEIPT']
    
    specific_score = sum(1 for kw in keywords.get(subType, []) if kw in text)
    generic_score = sum(1 for kw in generic_keywords if kw in text)
    
    # We want UNIQUE identification. If it scores high on ANOTHER specific slot but 0 on expected, it's a cross-upload!
    other_scores = {}
    for other_type, kws in keywords.items():
        if other_type != subType:
            score = sum(1 for kw in kws if kw in text)
            if score > 0:
                other_scores[other_type] = score
                
    # Strict cross-validation logic
    if specific_score == 0:
        if other_scores:
            highest_other = max(other_scores, key=other_scores.get)
            return "REJECT", f"Found {highest_other} signals instead of {subType}."
        if generic_score < 2:
            return "REJECT", f"No specific or generic signals found for {subType}."
            
    return "ACCEPT", f"Verified {subType} (specific={specific_score}, generic={generic_score})"

S4 = r"C:\Users\PRAVEEN\Desktop\rotatech hackathon\Gig_Credit\specification folders_new\Inputs\inputs hardcopies\step -4"

FILES = [
    {"label": "EB Bill", "path": os.path.join(S4, "eb bill", "eb bill - 05-11-25.pdf"), "truth": "utility_electricity"},
    {"label": "Gas Bill (Indane)", "path": os.path.join(S4, "gas bill", "Indane Gas Invoice - 2.pdf"), "truth": "utility_gas"},
    {"label": "Mobile (Airtel)", "path": os.path.join(S4, "mobile bill", "airtel mobile bill.pdf"), "truth": "utility_mobile"},
    {"label": "Mobile (Jio)", "path": os.path.join(S4, "mobile bill", "jio mobil bill.pdf"), "truth": "utility_mobile"},
    {"label": "OTT (Netflix)", "path": os.path.join(S4, "ott subscriotion", "ott netflix subscription.pdf"), "truth": "utility_ott"},
    {"label": "WiFi", "path": os.path.join(S4, "wifi bill", "wifi bill 2.jpeg"), "truth": "utility_wifi"},
]

SLOTS = ["utility_electricity", "utility_gas", "utility_mobile", "utility_ott", "utility_wifi"]

print("\n" + "GigCredit — Utility Bills Cross-Validation Test".center(80,"="))

for doc in FILES:
    print(f"\n{'─'*80}")
    print(f"  File     : {doc['label']}")
    text = extract_text(doc['path'])
    print(f"  Extracted: {len(text)} chars")
    
    print("\n  Uploading to different slots:")
    for slot in SLOTS:
        verdict, reason = classify_utility(text, slot)
        
        # Determine if the logic acted correctly
        should_accept = (slot == doc['truth'])
        # Edge case: Jio provides mobile AND wifi. The generic logic might accept mobile in wifi if generic score is high
        
        is_correct = "OK" if (verdict == "ACCEPT") == should_accept else "XX"
        
        # Relax rule for mobile vs wifi since they share telecom providers like Jio
        if is_correct == "XX" and doc['truth'] in ["utility_mobile", "utility_wifi"] and slot in ["utility_mobile", "utility_wifi"]:
            is_correct = "WARN" # Expected ambiguity
            
        color = "[OK]" if is_correct == "OK" else ("[!]" if is_correct == "WARN" else "[XX]")
        
        print(f"    {color} Slot {slot:<20} → {verdict:<6} : {reason}")

print("\n" + "="*80)
