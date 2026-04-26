import logging
from datetime import datetime, timezone

logger = logging.getLogger("gigcredit.api")
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse


def _timestamp() -> str:
    return datetime.now(timezone.utc).isoformat()


class AppException(Exception):
    def __init__(self, status_code: int, error: str, message: str):
        self.status_code = status_code
        self.error = error
        self.message = message


def register_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(AppException)
    async def app_exception_handler(_: Request, exc: AppException):
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "error": exc.error,
                "message": exc.message,
                "timestamp": _timestamp(),
            },
        )

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(_: Request, exc: RequestValidationError):
        first = exc.errors()[0] if exc.errors() else {"msg": "invalid request"}
        return JSONResponse(
            status_code=422,
            content={
                "error": "validation_error",
                "message": first.get("msg", "invalid request"),
                "timestamp": _timestamp(),
            },
        )

    @app.exception_handler(Exception)
    async def unhandled_exception_handler(request: Request, exc: Exception):
        logger.error(f"Unhandled exception at {request.url.path}: {exc}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={
                "error": "server_error",
                "message": "An unexpected error occurred",
                "timestamp": _timestamp(),
            },
        )
