import time

import pytest

import main as m

PHONE = "0599123456"


@pytest.fixture()
def headers(client):
    r = client.post(
        "/api/auth/register",
        json={"name": "مستخدم", "email": "otp@example.com", "password": "secret123"},
    )
    assert r.status_code == 200, r.text
    return {"Authorization": f"Bearer {r.json()['token']}"}


def test_send_code_requires_auth(client):
    assert client.post("/api/auth/send-code", json={"phone": PHONE}).status_code == 401


def test_send_code_invalid_phone_400(client, headers):
    r = client.post("/api/auth/send-code", json={"phone": "123"}, headers=headers)
    assert r.status_code == 400
    assert "غير صحيح" in r.json()["detail"]


def test_send_code_valid_no_debug_in_production_mode(client, headers):
    r = client.post("/api/auth/send-code", json={"phone": PHONE}, headers=headers)
    assert r.status_code == 200, r.text
    data = r.json()
    assert data["ok"] is True
    assert data["expiresIn"] == 300
    assert data["debugCode"] is None
    assert PHONE in m._sms_codes


def test_send_code_simulation_returns_debug_code(client, headers, monkeypatch):
    monkeypatch.setattr(m, "GATEWAY", "simulation")
    r = client.post("/api/auth/send-code", json={"phone": PHONE}, headers=headers)
    assert r.status_code == 200
    code = r.json()["debugCode"]
    assert code and len(code) == 6 and code.isdigit()
    stored = m._sms_codes[PHONE]
    assert stored[0] == code


def test_verify_code_wrong_code_400(client, headers):
    client.post("/api/auth/send-code", json={"phone": PHONE}, headers=headers)
    r = client.post("/api/auth/verify-code", json={"phone": PHONE, "code": "000000"}, headers=headers)
    assert r.status_code == 400
    assert "غير صحيح" in r.json()["detail"]


def test_verify_code_expired_400(client, headers):
    m._sms_codes[PHONE] = ("123456", time.time() - 1)
    r = client.post("/api/auth/verify-code", json={"phone": PHONE, "code": "123456"}, headers=headers)
    assert r.status_code == 400
    assert "انتهت صلاحية" in r.json()["detail"]


def test_verify_code_never_sent_400(client, headers):
    r = client.post("/api/auth/verify-code", json={"phone": PHONE, "code": "123456"}, headers=headers)
    assert r.status_code == 400
    assert "انتهت صلاحية" in r.json()["detail"]


def test_verify_code_success_marks_phone_verified(client, headers):
    m._sms_codes[PHONE] = ("654321", time.time() + 300)
    r = client.post("/api/auth/verify-code", json={"phone": PHONE, "code": " 654321 "}, headers=headers)
    assert r.status_code == 200, r.text
    user = r.json()["user"]
    assert user["phone"] == PHONE
    assert user["phoneVerified"] is True
    assert PHONE not in m._sms_codes

    me = client.get("/api/auth/me", headers=headers).json()["user"]
    assert me["phoneVerified"] is True


def test_verify_code_updates_phone_column(client, headers):
    client.put("/api/auth/profile", json={"phone": "0599999999"}, headers=headers)
    m._sms_codes["0599111111"] = ("111222", time.time() + 300)
    r = client.post(
        "/api/auth/verify-code", json={"phone": "0599111111", "code": "111222"}, headers=headers
    )
    assert r.status_code == 200
    me = client.get("/api/auth/me", headers=headers).json()["user"]
    assert me["phone"] == "0599111111"
    assert me["phoneVerified"] is True


def test_full_send_verify_flow_with_debug_code(client, headers, monkeypatch):
    monkeypatch.setattr(m, "GATEWAY", "simulation")
    sent = client.post("/api/auth/send-code", json={"phone": PHONE}, headers=headers)
    code = sent.json()["debugCode"]
    verified = client.post(
        "/api/auth/verify-code", json={"phone": PHONE, "code": code}, headers=headers
    )
    assert verified.status_code == 200
    assert verified.json()["user"]["phoneVerified"] is True
