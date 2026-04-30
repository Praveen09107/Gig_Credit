import hashlib
import json
import os
from datetime import datetime
from typing import Dict, Any

class AuditTrailService:
    def __init__(self, storage_path: str = "audit_logs.json"):
        self.storage_path = storage_path
        if not os.path.exists(self.storage_path):
            with open(self.storage_path, "w") as f:
                json.dump([], f)

    def _get_last_hash(self) -> str:
        with open(self.storage_path, "r") as f:
            logs = json.load(f)
            if not logs:
                return "0" * 64
            return logs[-1]["record_hash"]

    def _generate_hash(self, record: dict, prev_hash: str) -> str:
        data_string = json.dumps(record, sort_keys=True) + prev_hash
        return hashlib.sha256(data_string.encode('utf-8')).hexdigest()

    def append_record(self, loan_id: str, decision_data: Dict[str, Any], score_report: Dict[str, Any], application: Dict[str, Any]) -> str:
        prev_hash = self._get_last_hash()
        
        record = {
            "audit_id": f"GC-LOAN-{datetime.utcnow().strftime('%Y%m%d%H%M%S')}",
            "loan_id": loan_id,
            "created_at": datetime.utcnow().isoformat() + "Z",
            "prev_hash": prev_hash,
            "identity_snapshot": {
                "aadhaar_verified": application.get("aadhaar_verified", True),
                "pan_verified": application.get("pan_verified", True),
            },
            "score_snapshot": score_report,
            "loan_request": {
                "product_type": application.get("product_id"),
                "amount": application.get("loan_amount"),
                "tenure": application.get("tenure_months"),
                "kfs_acknowledged": application.get("kfs_acknowledged")
            },
            "decision": decision_data
        }
        
        record_hash = self._generate_hash(record, prev_hash)
        record["record_hash"] = record_hash
        
        # Append to log
        with open(self.storage_path, "r+") as f:
            logs = json.load(f)
            logs.append(record)
            f.seek(0)
            json.dump(logs, f, indent=2)
            
        return record_hash

audit_trail_service = AuditTrailService()
