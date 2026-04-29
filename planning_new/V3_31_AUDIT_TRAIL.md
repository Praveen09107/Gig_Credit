# V3.0 Tamper-Evident Audit Trail

## Purpose
SHA-256 hash-chained records for every decision. Regulators can verify no historical decision was modified retroactively.

---

## What Each Record Stores

```python
audit_record = {
    "seq": 42,                              # sequential ID
    "timestamp": "2026-04-29T15:06:00Z",
    "action": "score_generated",             # or "loan_decision"
    "entity_id": "GC-1714400000123",         # report_id or decision_id
    "user_id": "firebase_uid",
    
    # Decision inputs (frozen at decision time)
    "feature_vector": [0.45, 0.62, ...],     # full 115 features
    "pillar_scores": {"P1": 0.72, ...},      # all 8
    "conformal_intervals": {"P1": {"low": 0.68, "high": 0.76}, ...},
    "shap_values": {"avg_monthly_income_norm": 0.018, ...},  # L5 exact SHAP
    
    # Loan-specific (if loan decision)
    "loan_request": {"product_id": "nano_10k", "amount": 8000},
    "loan_decision": "approved",
    "aan_generated": false,
    "hard_rules_result": {"pass": true, "failed": []},
    "affordability_result": {"dscr": 1.85, "emi_ratio": 0.28},
    "ml_probability": 0.82,
    
    # Model artifacts at decision time
    "model_hashes": {
        "p1_lgbm": "sha256:abc123...",
        "p2_xgb": "sha256:def456...",
        "loan_lgbm": "sha256:ghi789...",
    },
    
    # EFS
    "efs_score": 0.92,
    
    # Chain integrity
    "prev_hash": "sha256:previous_record_hash",
    "hash": "sha256:this_record_hash",
}
```

---

## Hash Chain Implementation

```python
import hashlib, json

class AuditChain:
    def __init__(self, db):
        self.db = db
    
    async def append(self, record: dict) -> str:
        # Get previous record
        prev = await self.db.audit_chain.find_one(sort=[("seq", -1)])
        
        record["seq"] = (prev["seq"] + 1) if prev else 0
        record["prev_hash"] = prev["hash"] if prev else "GENESIS"
        
        # Compute hash (excludes the hash field itself)
        hashable = {k: v for k, v in record.items() if k != "hash"}
        record["hash"] = hashlib.sha256(
            json.dumps(hashable, sort_keys=True, default=str).encode()
        ).hexdigest()
        
        await self.db.audit_chain.insert_one(record)
        return record["hash"]
    
    async def verify_chain(self) -> bool:
        """Verify no record was tampered with."""
        records = await self.db.audit_chain.find().sort("seq", 1).to_list(None)
        for i, record in enumerate(records):
            # Recompute hash
            stored_hash = record.pop("hash")
            recomputed = hashlib.sha256(
                json.dumps(record, sort_keys=True, default=str).encode()
            ).hexdigest()
            if recomputed != stored_hash:
                return False  # TAMPERED at record i
            # Check chain link
            if i > 0 and record["prev_hash"] != records[i-1]["hash"]:
                return False  # CHAIN BROKEN at record i
            record["hash"] = stored_hash
        return True
```

---

## Decision Replay

From any audit trail ID, a regulator can reconstruct the exact decision:

```python
async def replay_decision(self, audit_id: str):
    record = await self.db.audit_chain.find_one({"entity_id": audit_id})
    
    # Reload the model that was used (by hash)
    models = load_models_by_hash(record["model_hashes"])
    
    # Re-run scoring on stored features
    replayed_pillars = score_all_pillars(models, record["feature_vector"])
    replayed_score = meta_learner_predict(replayed_pillars)
    
    # Compare with stored result
    match = abs(replayed_score - record["pillar_scores"]) < 0.01
    
    # Check if models have changed since decision
    current_hashes = get_current_model_hashes()
    models_same = current_hashes == record["model_hashes"]
    
    return {
        "replayed_score": replayed_score,
        "stored_score": record["pillar_scores"],
        "match": match,
        "models_same_as_production": models_same,
        "integrity_note": "Model integrity verified" if models_same 
                         else "⚠️ Models changed since decision time"
    }
```

---

## API Endpoints (Dev A)

| Endpoint | Purpose |
|----------|---------|
| `POST /api/v1/audit/record` | Store new audit record (called internally) |
| `GET /api/v1/audit/verify` | Verify full chain integrity |
| `GET /api/v1/audit/replay/{id}` | Decision replay for regulator |
| `GET /api/v1/audit/trail/{user_id}` | Full trail for a user |

---

## What This Proves to Regulators

1. **Tamper detection**: If any historical record is modified, all subsequent hashes break
2. **Decision provenance**: Exact model version that produced each decision
3. **Reproducibility**: Re-run the model on stored inputs and get the same answer
4. **Timeline**: Complete chronological trail of all scoring and lending decisions
