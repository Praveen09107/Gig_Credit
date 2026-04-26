from datetime import datetime, timezone

from pydantic import BaseModel


class ErrorResponse(BaseModel):
    error: str
    message: str
    timestamp: str

    @staticmethod
    def now() -> str:
        return datetime.now(timezone.utc).isoformat()
