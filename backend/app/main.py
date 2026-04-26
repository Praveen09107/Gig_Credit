from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api import (
    bank_verification,
    gov_verification,
    insurance_verification,
    otp_routes,
    report_routes,
)
from app.db.connection import close_db, connect_db
from app.utils.error_handlers import register_error_handlers


@asynccontextmanager
async def lifespan(_: FastAPI):
    connect_db()
    yield
    close_db()


app = FastAPI(title="GigCredit API", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

register_error_handlers(app)


@app.get("/health")
async def health():
    return {"status": "ok", "service": "gigcredit-api", "version": "1.0.0"}


app.include_router(otp_routes.router, prefix="/auth", tags=["auth"])
app.include_router(gov_verification.router, prefix="/gov", tags=["government"])
app.include_router(bank_verification.router, prefix="/bank", tags=["bank"])
app.include_router(
    insurance_verification.router,
    prefix="/gov/insurance",
    tags=["insurance"],
)
app.include_router(report_routes.router, prefix="/api", tags=["report"])