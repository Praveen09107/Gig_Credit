import hashlib
import json
import datetime

class AuditChain:
    """
    Minimal implementation of the SHA-256 hash chain for audit logs.
    """
    def __init__(self, db_client):
        self.db = db_client
        self.collection = self.db["audit_chain"] if self.db is not None else None

    def _get_last_hash(self):
        if self.collection is None:
            return "GENESIS_HASH"
        last_doc = self.collection.find_one(sort=[("timestamp", -1)])
        return last_doc["current_hash"] if last_doc else "GENESIS_HASH"

    def record_decision(self, user_id: str, decision_type: str, input_features: dict, result: dict):
        last_hash = self._get_last_hash()
        
        record = {
            "user_id": user_id,
            "decision_type": decision_type,
            "input_features": input_features,
            "result": result,
            "timestamp": datetime.datetime.utcnow().isoformat(),
            "previous_hash": last_hash
        }
        
        record_string = json.dumps(record, sort_keys=True)
        current_hash = hashlib.sha256(record_string.encode('utf-8')).hexdigest()
        
        record["current_hash"] = current_hash
        
        if self.collection is not None:
            self.collection.insert_one(record)
            
        return current_hash
