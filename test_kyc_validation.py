"""
Test: KYC cross-document validation
Simulates the Flutter cross-check logic using real OCR output from the test PAN card image.
"""

def name_similarity(a, b):
    a, b = a.strip().lower(), b.strip().lower()
    if a == b: return 1.0
    if not a or not b: return 0.0
    # Token match
    at = [t for t in a.split() if len(t) > 1]
    bt = [t for t in b.split() if len(t) > 1]
    common = len([t for t in at if t in bt])
    maxlen = max(len(at), len(bt), 1)
    token_score = common / maxlen
    if token_score >= 0.6:
        return token_score
    # Bigram fallback
    def bigrams(s):
        return set(s[i:i+2] for i in range(len(s)-1))
    ab, bb = bigrams(a), bigrams(b)
    if not ab and not bb: return 1.0
    inter = len(ab & bb)
    return 2.0 * inter / (len(ab) + len(bb))


def run_pan_validation(api_pan, api_aadhaar, ocr_pan, label):
    print(f"\n{'='*60}")
    print(f"SCENARIO: {label}")
    print(f"{'='*60}")
    print(f"  API (entered+verified): PAN={api_pan['pan_number']}  Name={api_pan['name']}  DOB={api_pan['dob']}")
    print(f"  OCR (uploaded image):   PAN={ocr_pan['pan_number']}  Name={ocr_pan['name']}  DOB={ocr_pan['dob']}")
    print()

    blocked = False
    banner = None

    # Check 1: PAN number match
    entered = api_pan['pan_number'].strip().upper()
    from_card = ocr_pan['pan_number'].strip().upper()
    if from_card and entered and from_card != entered:
        banner = f'PAN number on the uploaded card ({from_card}) does not match the PAN you entered ({entered}). Please upload your own PAN card.'
        blocked = True

    # Check 2: Name OCR vs API-verified PAN name
    if not blocked:
        api_name = api_pan['name']
        ocr_name = ocr_pan['name']
        if api_name and ocr_name:
            score = name_similarity(api_name, ocr_name)
            print(f"  Name similarity (OCR vs API): '{ocr_name}' vs '{api_name}' = {score:.2f}")
            if score < 0.60:
                banner = f'Name on the uploaded PAN card ("{ocr_name}") does not match the verified PAN record ("{api_name}"). You must upload your own PAN card.'
                blocked = True

    # Check 3: PAN name vs Aadhaar name (cross-document)
    if not blocked and api_aadhaar.get('name') and api_pan.get('name'):
        aa = api_aadhaar['name']
        pn = api_pan['name']
        score3 = name_similarity(aa, pn)
        print(f"  Cross-doc similarity (Aadhaar vs PAN): '{aa}' vs '{pn}' = {score3:.2f}")
        if score3 < 0.55:
            banner = f'The name on your PAN ("{pn}") does not match the name on your Aadhaar ("{aa}"). Both documents must belong to the same person.'
            blocked = True

    # Check 4: DOB match
    if not blocked:
        api_dob = api_pan.get('dob', '')
        ocr_dob = ocr_pan.get('dob', '')
        if api_dob and ocr_dob and api_dob != ocr_dob:
            # Loose check: same year+month
            def ym(d):
                parts = d.replace('-', '/').split('/')
                if len(parts) == 3:
                    first = int(parts[0])
                    if first > 31:  # YYYY-MM-DD
                        return (int(parts[0]), int(parts[1]))
                    return (int(parts[2]), int(parts[1]))
                return None
            d1, d2 = ym(api_dob), ym(ocr_dob)
            if d1 and d2 and d1 != d2:
                banner = f'Date of birth on the uploaded PAN card ({ocr_dob}) does not match the verified record ({api_dob}). This does not appear to be your PAN card.'
                blocked = True
                print(f"  DOB mismatch: API={api_dob}  OCR={ocr_dob}")

    print()
    if blocked:
        print(f"  RESULT: BLOCKED")
        print(f"  BANNER: {banner}")
    else:
        print(f"  RESULT: ACCEPTED — all checks passed")

    return blocked


# ── API data (what server returns after PAN+Aadhaar verify) ────────────────────
api_aadhaar_data = {
    'aadhaar_number': '749420067990',
    'name': 'Praveen Kumar P',
    'dob': '09/01/2007',
}
api_pan_data_praveen_p = {
    'pan_number': 'IPZPP3254R',
    'name': 'Praveen Kumar P',
    'dob': '09/01/2007',
}

# ── OCR output from the test PAN card (Praveen S's card) ──────────────────────
ocr_praveen_s_pan = {
    'pan_number': 'IQHPP7233R',   # different PAN number
    'name': 'PRAVEENS',            # OCR merged "PRAVEEN S"
    'dob': '16/11/2006',           # different DOB
}

# ── OCR output from Praveen Kumar P's own PAN (expected pass scenario) ────────
ocr_praveen_p_own_pan = {
    'pan_number': 'IPZPP3254R',   # same PAN number
    'name': 'PRAVEEN KUMAR P',     # same name (different case, OCR spacing)
    'dob': '09/01/2007',           # same DOB
}

# ── Run tests ──────────────────────────────────────────────────────────────────
print("GigCredit KYC Cross-Validation Test")
print("Testing: API-verified data vs uploaded document OCR")
print()

# Test 1: Wrong PAN card uploaded (Praveen S's)
run_pan_validation(api_pan_data_praveen_p, api_aadhaar_data, ocr_praveen_s_pan,
                   "User enters Praveen Kumar P's PAN, uploads PRAVEEN S's card")

# Test 2: Correct PAN card uploaded (own card)
run_pan_validation(api_pan_data_praveen_p, api_aadhaar_data, ocr_praveen_p_own_pan,
                   "User enters Praveen Kumar P's PAN, uploads OWN card")

# Test 3: Edge case — OCR name has slight variation (should still pass)
ocr_slight_variation = {
    'pan_number': 'IPZPP3254R',
    'name': 'PRAVEEN K P',         # abbreviated middle name
    'dob': '09/01/2007',
}
run_pan_validation(api_pan_data_praveen_p, api_aadhaar_data, ocr_slight_variation,
                   "Slight OCR variation in name (abbreviated) — should pass")
