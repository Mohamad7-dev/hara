import os
import sys
import tempfile
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

os.environ.setdefault("GATEWAY", "")
os.environ.setdefault("GOOGLE_CLIENT_ID", "")
os.environ.setdefault("MYFATOORAH_TOKEN", "")
os.environ.setdefault("MYFATOORAH_LIVE", "0")
os.environ.setdefault("PALPAY_MERCHANT", "")
os.environ.setdefault("PALPAY_USERNAME", "")
os.environ.setdefault("PALPAY_PASSWORD", "")

import main as m  # noqa: E402

m.DB_PATH = os.path.join(tempfile.gettempdir(), "hara_test_boot.db")
m.init_db()


@pytest.fixture()
def fresh_db(tmp_path, monkeypatch):
    monkeypatch.setattr(m, "DB_PATH", str(tmp_path / "test.db"))
    monkeypatch.setattr(m, "_sms_codes", {})
    m.init_db()
    yield


@pytest.fixture()
def client(fresh_db):
    with TestClient(m.app) as c:
        yield c


@pytest.fixture()
def auth_headers(client):
    def _make(email="u1@example.com", password="pass1234", name="مستخدم 1", **extra):
        payload = {"name": name, "email": email, "password": password, **extra}
        r = client.post("/api/auth/register", json=payload)
        assert r.status_code == 200, r.text
        return {"Authorization": f"Bearer {r.json()['token']}"}

    return _make
