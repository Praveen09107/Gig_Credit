import hashlib
import hmac
from datetime import datetime, timezone

from fastapi import Header

from app.config import settings
from app.utils.error_handlers import AppException


def _build_message(device_id: str, timestamp: str, body_hash: str) -> str:
    return f"{device_id}:{timestamp}:{body_hash}"


def compute_signature(device_id: str, timestamp: str, body: bytes) -> str:
    body_hash = hashlib.sha256(body).hexdigest()
    message = _build_message(device_id, timestamp, body_hash)
    return hmac.new(
        settings.HMAC_SECRET.encode("utf-8"),
        message.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()


def verify_timestamp(ts: str, max_skew_seconds: int = 300) -> bool:
    try:
        request_time = int(ts)
    except ValueError:
        return False
    now = int(datetime.now(timezone.utc).timestamp())
    return abs(now - request_time) <= max_skew_seconds


def verify_hmac_headers(
    x_api_key: str = Header(default=""),
    x_device_id: str = Header(default=""),
    x_timestamp: str = Header(default=""),
    x_signature: str = Header(default=""),
) -> None:
    if settings.SKIP_AUTH:
        return

    if x_api_key != settings.SERVER_API_KEY:
        raise AppException(401, "unauthorized", "Invalid API key")

    if not x_device_id or not x_timestamp or not x_signature:
        raise AppException(401, "unauthorized", "Missing auth headers")

    if settings.ENABLE_HMAC and not verify_timestamp(x_timestamp):
        raise AppException(401, "unauthorized", "Invalid timestamp")
