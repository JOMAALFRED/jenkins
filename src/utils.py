"""Fonctions utilitaires pour l'application DevSecOps."""

import os
import time


APP_VERSION = "1.0.0"


def get_version() -> str:
    """Retourne la version de l'application."""
    return os.getenv("APP_VERSION", APP_VERSION)


def check_health() -> dict:
    """Verifie l'etat de sante de l'application."""
    return {
        "status": "healthy",
        "version": get_version(),
        "uptime": int(time.time()),
        "checks": {
            "api": "ok",
            "env": "ok" if os.getenv("API_SECRET_TOKEN") else "warning: token par defaut",
        },
    }


def sanitize_input(value: str, max_length: int = 255) -> str:
    """Nettoie et valide une entree utilisateur."""
    if not isinstance(value, str):
        raise ValueError("La valeur doit etre une chaine")
    value = value.strip()
    if len(value) > max_length:
        raise ValueError(f"Valeur trop longue (max {max_length} caracteres)")
    return value
