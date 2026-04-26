# ================================================================================
# GIGCREDIT — PHASE 3: INTEGRATION & OCR
# Document 11 | Hours 12–20 | planning_new
# ================================================================================

## PHASE OBJECTIVE
First real integration: Dev B's app calls Dev A's running backend. OCR pipeline
is implemented (real or mock). Gate G1 checkpoint at Hour 16.

---

## DEV A TASKS (Hours 12–20)

### A3.1 — Deploy Backend to Render (1 hour)

1. Create `Dockerfile` in repo root
2. Push to GitHub
3. Create Render Web Service:
   - Build command: `pip install -r backend/requirements.txt`
   - Start command: `uvicorn backend.app.main:app --host 0.0.0.0 --port $PORT`
4. Set environment variables on Render:
   - `MONGODB_URI` — MongoDB Atlas connection string
   - `GROQ_API_KEY` — Groq API key
   - `HMAC_SECRET` — shared secret
   - `SERVER_API_KEY` — API key
5. Verify: `curl https://<render-url>/health`
6. Share URL with Dev B

### A3.2 — MongoDB Atlas Setup (30 min)

1. Create MongoDB Atlas free cluster
2. Create database `gigcredit`
3. Whitelist Render's IP (or allow 0.0.0.0/0 for demo)
4. Get connection string
5. Run seed script remotely:
```bash
python -c "from backend.app.db.seed_data import seed_all; import asyncio; asyncio.run(seed_all())"
```

### A3.3 — Start ML Pipeline (3 hours)

Begin training the scoring models. This runs in parallel while backend stabilizes.

Create `ml_pipeline/data/synthetic_generator.py`:
```python
def generate_synthetic_profiles(n=15000):
    """Generate 15,000 synthetic gig worker profiles with 95 features each."""
    profiles = []
    for i in range(n):
        work_type = random.choice(['platform_worker', 'vendor', 'tradesperson', 'freelancer'])
        profile = generate_single_profile(work_type)
        profiles.append(profile)
    
    df = pd.DataFrame(profiles)
    df.to_csv('ml_pipeline/data/generated/synthetic_profiles.csv', index=False)
    return df
```

Key requirements for synthetic data:
- Cover all 4 work types evenly (3,750 each)
- Realistic income distributions per work type
- Correlated features (high income → higher savings → better score)
- Include edge cases (0 insurance, max EMI ratio, etc.)
- 95 features matching the feature vector contract EXACTLY

Create `ml_pipeline/training/train_pillars.py`:
```python
def train_pillar_models():
    """Train P1-P4 (XGBoost) + P6 (RandomForest)"""
    # P1: Income Stability (features 0-12)
    # P2: Payment Discipline (features 13-27)
    # P3: Debt Management (features 28-36)
    # P4: Savings Behaviour (features 37-48)
    # P6: Financial Resilience (features 67-77)
    
    for pillar_name, feature_range, model_type in PILLAR_CONFIG:
        X_train = df.iloc[:, feature_range]
        y_train = generate_pillar_target(df, pillar_name)
        
        if model_type == 'xgboost':
            model = XGBRegressor(n_estimators=100, max_depth=5, learning_rate=0.1)
        elif model_type == 'random_forest':
            model = RandomForestRegressor(n_estimators=100, max_depth=5)
        
        model.fit(X_train, y_train)
        
        # Export to Dart via m2cgen
        dart_code = m2cgen.export_to_dart(model, function_name=f'score_{pillar_name}')
        with open(f'ml_pipeline/output/dart_exports/{pillar_name}_scorer.dart', 'w') as f:
            f.write(dart_code)
```

### A3.4 — Write Dart Scorecards for P5 and P7 (1 hour)

P5 (Work and Identity) and P7 (Social Accountability) are deterministic scorecards:

```dart
// ml_pipeline/output/dart_exports/scorecard_p5.dart
double scorecardP5(List<double> features) {
  // features[49..66] = 18 features for Work and Identity
  double score = 0.0;
  
  // Identity strength
  score += features[49] * 0.15;  // aadhaar_verified (1.0 or 0.0)
  score += features[50] * 0.10;  // pan_verified
  score += features[51] * 0.08;  // face_match_score
  // ... all 18 features with hand-tuned weights
  
  return score.clamp(0.0, 1.0);
}
```

### A3.5 — Fix Any Backend Bugs (1.5 hours)

Respond to issues Dev B finds during integration testing.

**DELIVERABLES by Hour 20:**
- [ ] Backend deployed to Render (publicly accessible)
- [ ] MongoDB Atlas seeded with demo data
- [ ] All endpoints tested via curl from local machine
- [ ] ML pipeline started (synthetic data generated, training initiated)
- [ ] P5 and P7 scorecards written in Dart

---

## DEV B TASKS (Hours 12–20)

### B3.1 — Implement Real API Client (1.5 hours)

Create `app/lib/core/api/api_client.dart`:
```dart
class RealApiClient implements ApiClient {
  final String baseUrl;
  final HmacSigner signer;
  
  RealApiClient({required this.baseUrl, required this.signer});
  
  @override
  Future<Map<String, dynamic>> verifyAadhaar(String aadhaar) async {
    final body = jsonEncode({"aadhaar": aadhaar});
    final headers = signer.sign(body);
    
    final response = await http.post(
      Uri.parse('$baseUrl/gov/aadhaar/verify'),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: body,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      throw VerificationNotFoundException();
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }
  // ... all other endpoints
}
```

Create `app/lib/core/api/hmac_signer.dart`:
```dart
class HmacSigner {
  final String hmacSecret;
  final String apiKey;
  final String deviceId;
  
  Map<String, String> sign(String body) {
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final bodyHash = sha256.convert(utf8.encode(body)).toString();
    final message = '$deviceId:$timestamp:$bodyHash';
    final hmac = Hmac(sha256, utf8.encode(hmacSecret));
    final signature = hmac.convert(utf8.encode(message)).toString();
    
    return {
      'X-Api-Key': apiKey,
      'X-Device-Id': deviceId,
      'X-Timestamp': timestamp,
      'X-Signature': signature,
    };
  }
}
```

### B3.2 — Switchable API Client Provider (30 min)

```dart
// Use environment variable or config to switch
final apiClientProvider = Provider<ApiClient>((ref) {
  if (kDebugMode || USE_MOCK) {
    return MockApiClient();
  }
  return RealApiClient(
    baseUrl: 'https://<render-url>',
    signer: HmacSigner(
      hmacSecret: 'demo-secret-key',
      apiKey: 'demo-api-key',
      deviceId: '<device-hash>',
    ),
  );
});
```

### B3.3 — OCR Integration (2 hours)

**Option A — Real PaddleOCR (if time permits):**
- Set up Android native bridge (Kotlin)
- Bundle PaddleOCR Lite model
- Create `OcrService.process(filePath)` via MethodChannel

**Option B — Demo OCR Service (recommended for hackathon):**
```dart
class DemoOcrService implements OcrService {
  final Map<String, Map<String, dynamic>> _demoResults = {
    'aadhaar_front': {
      'name': 'Ravi Kumar',
      'dob': '12/06/1997',
      'aadhaar': '1234 5678 9012',
      'gender': 'Male',
    },
    'pan_card': {
      'pan': 'ABCDE1234F',
      'name': 'RAVI KUMAR',
      'dob': '12/06/1997',
    },
    // ... pre-defined results for all demo documents
  };
  
  @override
  Future<OcrResult> process(String filePath, String docType) async {
    // Simulate OCR processing time
    await Future.delayed(Duration(seconds: 2));
    
    final fields = _demoResults[docType] ?? {};
    return OcrResult(
      text: "Simulated OCR text for $docType",
      fields: fields,
      confidence: 0.94,
    );
  }
}
```

### B3.4 — Connect Step Screens to API (2 hours)

Update each step screen to:
1. Call OCR when document is uploaded
2. Call verification API with extracted identifiers
3. Show verification badge on success
4. Store verified data in VerifiedProfile

Example for Step 2:
```dart
// After Aadhaar image uploaded and OCR extracted
final ocrResult = await ocrService.process(aadhaarFrontPath, 'aadhaar_front');
final aadhaarNumber = ocrResult.fields['aadhaar']!.replaceAll(' ', '');

// Call backend verification
final verifyResult = await apiClient.verifyAadhaar(aadhaarNumber);

// Cross-match
if (verifyResult['status'] == 'valid') {
  final nameMatch = fuzzyMatch(ocrResult.fields['name']!, verifyResult['name']);
  if (nameMatch >= 0.85) {
    // Update verified profile
    ref.read(stepStateProvider.notifier).updateIdentity(
      aadhaarVerified: true,
      aadhaarName: verifyResult['name'],
    );
  }
}
```

### B3.5 — Bank Statement Parser (2 hours)

Create `app/lib/core/parser/bank_statement_parser.dart`:

For demo, parse the specific bank statement PDFs provided:
```dart
class BankStatementParser {
  Future<BankStatementResult> parse(String pdfPath) async {
    // Try real PDF text extraction
    try {
      final text = await PdfTextExtractor.extract(pdfPath);
      if (text.length > 100) {
        return _parseTextStatement(text);
      }
    } catch (e) {
      // Fallback to demo data
    }
    
    // Fallback: return pre-parsed transaction data for demo PDFs
    return _getDemoTransactions();
  }
  
  BankStatementResult _getDemoTransactions() {
    return BankStatementResult(
      bankName: 'HDFC Bank',
      accountNumber: '1234567890',
      transactions: [
        Transaction(date: '2025-10-01', narration: 'UPI/Swiggy', credit: 18500, balance: 25000),
        Transaction(date: '2025-10-05', narration: 'EMI/HDFC LOAN', debit: 3500, balance: 21500),
        // ... 100+ pre-defined transactions for demo
      ],
      monthlyCredits: [18000, 19500, 17800, 20000, 18500, 19000],
      monthlyDebits: [15000, 14500, 16000, 15500, 14000, 15200],
      avgBalance: 25000,
    );
  }
}
```

**DELIVERABLES by Hour 20:**
- [ ] Real API client with HMAC signing working
- [ ] App successfully calls backend `/health` endpoint
- [ ] OTP flow works with real backend
- [ ] At least Aadhaar + PAN verification works with real backend
- [ ] OCR service (real or demo) returns parsed data
- [ ] Bank statement parser returns transaction data
- [ ] Step screens connected to API and show verification badges

---

## GATE G1 CHECKPOINT (Hour 16)

```
□ Dev B's app can call Dev A's running backend (locally or remotely)
□ OTP flow works end-to-end
□ At least one verification endpoint returns real data
□ Both branches merged to develop
□ develop branch compiles on both machines
```
