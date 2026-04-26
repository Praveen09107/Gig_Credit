# ================================================================================
# GIGCREDIT — DEV A COMPLETE TASK CHECKLIST
# Document 28 | planning_new
# ================================================================================

## HOUR-BY-HOUR TASK LIST FOR DEV A (Backend + ML + AI)

### Phase 1: Hours 0–4 (Setup & Contracts)
- [ ] Set up Python virtual environment
- [ ] Install all pip packages (fastapi, uvicorn, pymongo, groq, etc.)
- [ ] Create backend/app/main.py with FastAPI app
- [ ] Create backend/app/config.py with Settings class
- [ ] Create backend/app/db/connection.py with MongoDB setup
- [ ] Write ALL Pydantic schemas in verification_schemas.py
- [ ] Write ALL contract JSON files in contracts/
- [ ] Create .env.example with all environment variables
- [ ] Initialize git, create branches, push to GitHub
- [ ] Verify /health endpoint returns {"status": "ok"}

### Phase 2: Hours 4–12 (Backend APIs)
- [ ] Implement HMAC authentication middleware
- [ ] Implement POST /auth/otp/send
- [ ] Implement POST /auth/otp/verify
- [ ] Implement POST /gov/aadhaar/verify
- [ ] Implement POST /gov/pan/verify
- [ ] Implement POST /bank/ifsc/verify
- [ ] Implement POST /bank/account/verify
- [ ] Implement POST /bank/loan/check
- [ ] Implement POST /gov/vehicle/rc/verify
- [ ] Implement POST /gov/eshram/verify
- [ ] Implement POST /gov/pmsym/verify
- [ ] Implement POST /gov/insurance/policy/verify
- [ ] Implement POST /gov/income-tax/itr/verify
- [ ] Implement POST /api/report/generate (LLM)
- [ ] Create seed_data.py with ALL demo records
- [ ] Open demo input images and extract REAL identifiers
- [ ] Seed MongoDB with demo data
- [ ] Write backend unit tests (at least 5)
- [ ] Run all tests: pytest passes
- [ ] Push to dev-a/backend

### Phase 3: Hours 12–20 (Deployment + ML Start)
- [ ] Set up MongoDB Atlas free cluster
- [ ] Get connection string and configure
- [ ] Create Dockerfile for backend
- [ ] Deploy backend to Render
- [ ] Verify /health on Render URL
- [ ] Run seed script against Atlas
- [ ] Test ALL endpoints via curl from remote
- [ ] Share Render URL with Dev B
- [ ] Create synthetic_generator.py
- [ ] Generate 15,000 synthetic profiles
- [ ] Create train_pillars.py
- [ ] Start training P1-P4 (XGBoost) + P6 (RF)
- [ ] Write scorecard_p5.dart (deterministic)
- [ ] Write scorecard_p7.dart (deterministic)
- [ ] Push to dev-a/ml

### Phase 4: Hours 20–28 (ML Export)
- [ ] Complete all model training
- [ ] Validate models (RMSE targets met)
- [ ] Export P1-P4 via m2cgen to .dart
- [ ] Export P6 via m2cgen to .dart
- [ ] Train meta-learner (LogisticRegression)
- [ ] Export scoring_constants.dart with LR coefficients
- [ ] Generate meta_coefficients.json
- [ ] Generate shap_lookup.json via SHAP
- [ ] Generate feature_means.json
- [ ] Generate golden_inference.json (5 test cases)
- [ ] Commit all artifacts to ml_pipeline/output/
- [ ] NOTIFY Dev B: "HANDOFF ready"
- [ ] Push to dev-a/exports

### Phase 5: Hours 28–36 (Backend Stabilize)
- [ ] Add rate limiting to all endpoints
- [ ] Add comprehensive logging middleware
- [ ] Add global exception handler
- [ ] Fix bugs reported by Dev B
- [ ] Optimize Groq prompt if output quality is low
- [ ] Generate demo expected outputs JSONs
- [ ] Verify backend stability (no crashes for 2+ hours)
- [ ] Test fallback path (Groq timeout → template response)

### Phase 6: Hours 36–42 (Error Handling)
- [ ] Add request/response logging to MongoDB
- [ ] Add /metrics endpoint
- [ ] Test ALL error scenarios (400, 401, 404, 429, 500, 503)
- [ ] Fix any remaining integration bugs
- [ ] Final backend stability check

### Phase 7: Hours 42–48 (Final Assembly)
- [ ] Join Dev B for demo rehearsal (3 runs)
- [ ] Fix any backend issues found
- [ ] Ensure Render deployment is stable
- [ ] Final merge to develop and main
- [ ] Tag v1.0-release
- [ ] Prepare for demo presentation
