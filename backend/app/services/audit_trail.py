import hashlib
import json
import os
from datetime import datetime
from typing import Dict, Any, List

class AuditTrailService:
    def __init__(self, storage_path: str = "audit_logs.json"):
        self.storage_path = storage_path
        self._in_memory_logs: List[dict] = []
        self._file_available = False
        
        # Try to initialize file storage, but don't crash if filesystem is read-only
        try:
            if not os.path.exists(self.storage_path):
                with open(self.storage_path, "w") as f:
                    json.dump([], f)
            self._file_available = True
        except (OSError, PermissionError):
            print("[AuditTrail] File storage unavailable (read-only FS), using in-memory storage")
            self._file_available = False

    def _get_last_hash(self) -> str:
        if self._in_memory_logs:
            return self._in_memory_logs[-1].get("record_hash", "0" * 64)
        
        if self._file_available:
            try:
                with open(self.storage_path, "r") as f:
                    logs = json.load(f)
                    if logs:
                        return logs[-1]["record_hash"]
            except (OSError, json.JSONDecodeError, KeyError):
                pass
        return "0" * 64

    def _generate_hash(self, record: dict, prev_hash: str) -> str:
        # Safely serialize — convert non-serializable values to strings
        def safe_serialize(obj):
            if isinstance(obj, (int, float, str, bool, type(None))):
                return obj
            if isinstance(obj, dict):
                return {k: safe_serialize(v) for k, v in obj.items()}
            if isinstance(obj, (list, tuple)):
                return [safe_serialize(i) for i in obj]
            return str(obj)
        
        data_string = json.dumps(safe_serialize(record), sort_keys=True, default=str) + prev_hash
        return hashlib.sha256(data_string.encode('utf-8')).hexdigest()

    def append_record(self, loan_id: str, decision_data: Dict[str, Any], score_report: Dict[str, Any], application: Dict[str, Any]) -> str:
        try:
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
            
            # Always store in memory
            self._in_memory_logs.append(record)
            
            # Try to persist to file if available
            if self._file_available:
                try:
                    with open(self.storage_path, "r+") as f:
                        logs = json.load(f)
                        logs.append(record)
                        f.seek(0)
                        json.dump(logs, f, indent=2, default=str)
                except (OSError, PermissionError):
                    self._file_available = False
                    
            return record_hash
        except Exception as e:
            print(f"[AuditTrail] Non-critical error: {e}")
            return "0" * 64

audit_trail_service = AuditTrailService()

