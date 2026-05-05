import asyncio
import os

import httpx
import pytest

os.environ["API_SECRET_TOKEN"] = "test-token"

from src.app import app
from src.utils import sanitize_input


async def _request(method: str, path: str, **kwargs):
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        return await client.request(method, path, **kwargs)


def get(path: str, **kwargs):
    return asyncio.run(_request("GET", path, **kwargs))


def test_root_returns_200():
    response = get("/")

    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "running"
    assert "version" in data


def test_health_returns_healthy():
    response = get("/health")

    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_version_endpoint():
    response = get("/version")

    assert response.status_code == 200
    assert "version" in response.json()


def test_secure_without_token_returns_401_or_403():
    response = get("/secure/data")

    assert response.status_code in (401, 403)


def test_secure_with_wrong_token_returns_401():
    response = get("/secure/data", headers={"Authorization": "Bearer mauvais-token"})

    assert response.status_code == 401


def test_secure_with_valid_token_returns_200():
    response = get("/secure/data", headers={"Authorization": "Bearer test-token"})

    assert response.status_code == 200
    assert response.json()["message"] == "Acces autorise"


def test_pipeline_info_structure():
    response = get(
        "/secure/pipeline-info",
        headers={"Authorization": "Bearer test-token"},
    )

    assert response.status_code == 200
    data = response.json()
    assert "pipeline" in data
    assert "stages" in data
    assert len(data["stages"]) == 7


def test_sanitize_input_strips_spaces():
    assert sanitize_input("  hello  ") == "hello"


def test_sanitize_input_rejects_long_string():
    with pytest.raises(ValueError):
        sanitize_input("a" * 300)


def test_sanitize_input_rejects_non_string():
    with pytest.raises(ValueError):
        sanitize_input(123)
