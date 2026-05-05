"""
DevSecOps Demo - Application FastAPI.
Projet : pipeline CI/CD securise avec Jenkins et registre local.
"""

import os
import time

from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from src.utils import check_health, get_version


app = FastAPI(
    title="DevSecOps Demo API",
    description="Application de demonstration pour le pipeline CI/CD securise",
    version=get_version(),
    docs_url="/docs",
    redoc_url="/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

security = HTTPBearer(auto_error=False)


@app.get("/", tags=["Info"])
async def root():
    return {
        "app": "DevSecOps Demo API",
        "version": get_version(),
        "status": "running",
        "timestamp": int(time.time()),
    }


@app.get("/health", tags=["Info"])
async def health():
    return check_health()


@app.get("/version", tags=["Info"])
async def version():
    return {
        "version": get_version(),
        "build": os.getenv("BUILD_NUMBER", "local"),
        "commit": os.getenv("GIT_COMMIT", "unknown"),
    }


async def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    expected = os.getenv("API_SECRET_TOKEN", "demo-token-changeme")
    if not credentials or credentials.credentials != expected:
        raise HTTPException(status_code=401, detail="Token invalide ou manquant")
    return credentials.credentials


@app.get("/secure/data", tags=["Securise"], dependencies=[Depends(verify_token)])
async def secure_data():
    return {
        "message": "Acces autorise",
        "data": {
            "pipeline_status": "secured",
            "scanner": "Trivy",
            "registry": "Local Docker Registry",
        },
    }


@app.get("/secure/pipeline-info", tags=["Securise"], dependencies=[Depends(verify_token)])
async def pipeline_info():
    return {
        "pipeline": {
            "tool": "Jenkins",
            "registry": "Local Docker Registry",
            "scanner": "Trivy",
            "signer": "Cosign",
            "sast": ["Bandit", "Semgrep", "Gitleaks"],
        },
        "stages": [
            "SAST",
            "Build",
            "Scan dependances",
            "Signature",
            "Push registry",
            "Policy check",
            "Deploiement",
        ],
    }
