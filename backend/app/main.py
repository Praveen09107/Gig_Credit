from contextlib import asynccontextmanager

from fastapi import FastAPI
import fastapi
from fastapi.middleware.cors import CORSMiddleware

from app.api import (
    bank_verification,
    gov_verification,
    insurance_verification,
    otp_routes,
    report_routes,
    scoring_router,
    loan_router,
    explainability_router,
    utility_verification,
    explain_routes,
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
async def health(response: fastapi.Response):
    db_status = False
    try:
        from app.db.connection import get_db
        db = get_db()
        if db is not None:
            await db.command("ping")
            db_status = True
    except Exception:
        db_status = False
        
    if not db_status:
        response.status_code = 503

    return {
        "status": "ok" if db_status else "degraded",
        "service": "gigcredit-api",
        "version": "1.0.0",
        "database_connected": db_status,
    }


app.include_router(otp_routes.router, prefix="/auth", tags=["auth"])
app.include_router(gov_verification.router, prefix="/gov", tags=["government"])
app.include_router(bank_verification.router, prefix="/bank", tags=["bank"])
app.include_router(
    insurance_verification.router,
    prefix="/gov/insurance",
    tags=["insurance"],
)
app.include_router(report_routes.router, prefix="/api", tags=["report"])
app.include_router(scoring_router.router, prefix="/score", tags=["scoring"])
app.include_router(loan_router.router, prefix="/loan", tags=["loan"])
app.include_router(explainability_router.router, prefix="/explain", tags=["explainability"])
app.include_router(explain_routes.router, tags=["explainability_full"])
app.include_router(utility_verification.router, prefix="/utility", tags=["utility"])
app.include_router(utility_verification.router, prefix="/gov", tags=["gov-extra"])