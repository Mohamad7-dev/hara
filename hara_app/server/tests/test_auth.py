import time

import pytest

import main as m


class FakeResp:
    def __init__(self, status_code, payload):
        self.status_code = status_code
        self._payload = payload

    def json(self):
        return self._payload


def test_register_creates_user_and_token(client):
    r = client.post(
        "/api/auth/register",
        json={"name": "سارة", "email": "sara@example.com", "password": "secret123"},
    )
    assert r.status_code == 200, r.text
    data = r.json()
    assert data["token"]
    assert data["user"]["email"] == "sara@example.com"
    assert data["user"]["name"] == "سارة"
    assert data["user"]["phoneVerified"] is False
    assert "password" not in data["user"]


def test_register_duplicate_email_400(client):
    payload = {"name": "سارة", "email": "sara@example.com", "password": "secret123"}
    assert client.post("/api/auth/register", json=payload).status_code == 200
    r = client.post("/api/auth/register", json=payload)
    assert r.status_code == 400
    assert "مستخدم مسبقاً" in r.json()["detail"]


def test_login_success(client):
    client.post(
        "/api/auth/register",
        json={"name": "سارة", "email": "sara@example.com", "password": "secret123"},
    )
    r = client.post(
        "/api/auth/login", json={"email": "sara@example.com", "password": "secret123"}
    )
    assert r.status_code == 200, r.text
    assert r.json()["token"]
    assert r.json()["user"]["email"] == "sara@example.com"


def test_login_wrong_password_401(client):
    client.post(
        "/api/auth/register",
        json={"name": "سارة", "email": "sara@example.com", "password": "secret123"},
    )
    r = client.post(
        "/api/auth/login", json={"email": "sara@example.com", "password": "wrong"}
    )
    assert r.status_code == 401


def test_login_unknown_email_401(client):
    r = client.post(
        "/api/auth/login", json={"email": "nobody@example.com", "password": "x"}
    )
    assert r.status_code == 401


def test_me_requires_token(client):
    assert client.get("/api/auth/me").status_code == 401
    assert (
        client.get("/api/auth/me", headers={"Authorization": "Bearer bad-token"}).status_code
        == 401
    )


def test_me_returns_user(client, auth_headers):
    headers = auth_headers()
    r = client.get("/api/auth/me", headers=headers)
    assert r.status_code == 200
    assert r.json()["user"]["email"] == "u1@example.com"


def test_update_profile_name(client, auth_headers):
    headers = auth_headers()
    r = client.put("/api/auth/profile", json={"name": "اسم جديد"}, headers=headers)
    assert r.status_code == 200, r.text
    assert r.json()["user"]["name"] == "اسم جديد"


def test_update_profile_change_phone_resets_verification(client, auth_headers):
    headers = auth_headers()
    r = client.put("/api/auth/profile", json={"phone": "0599000001"}, headers=headers)
    assert r.status_code == 200
    assert r.json()["user"]["phone"] == "0599000001"
    assert r.json()["user"]["phoneVerified"] is False

    m._sms_codes["0599000001"] = ("111111", time.time() + 300)
    client.post("/api/auth/verify-code", json={"phone": "0599000001", "code": "111111"}, headers=headers)

    assert client.get("/api/auth/me", headers=headers).json()["user"]["phoneVerified"] is True

    client.put("/api/auth/profile", json={"phone": "0599000002"}, headers=headers)
    me = client.get("/api/auth/me", headers=headers).json()["user"]
    assert me["phone"] == "0599000002"
    assert me["phoneVerified"] is False


def test_update_profile_same_phone_keeps_verification(client, auth_headers):
    headers = auth_headers()
    client.put("/api/auth/profile", json={"phone": "0599000001"}, headers=headers)
    m._sms_codes["0599000001"] = ("222222", time.time() + 300)
    client.post("/api/auth/verify-code", json={"phone": "0599000001", "code": "222222"}, headers=headers)

    client.put("/api/auth/profile", json={"phone": "0599000001"}, headers=headers)
    me = client.get("/api/auth/me", headers=headers).json()["user"]
    assert me["phoneVerified"] is True


def test_logout_invalidates_token(client, auth_headers):
    headers = auth_headers()
    assert client.post("/api/auth/logout", headers=headers).status_code == 200
    assert client.get("/api/auth/me", headers=headers).status_code == 401


def test_register_delivery_user(client):
    r = client.post(
        "/api/auth/register",
        json={
            "name": "موصل",
            "email": "del@example.com",
            "password": "secret123",
            "userType": "delivery",
            "deliveryAreas": ["رام الله"],
            "deliveryFee": 8,
            "vehicleType": "دراجة",
        },
    )
    assert r.status_code == 200, r.text
    user = r.json()["user"]
    assert user["userType"] == "delivery"
    assert user["deliveryAreas"] == ["رام الله"]
    assert user["deliveryFee"] == 8


# ---------------- google ----------------

def _patch_tokeninfo(monkeypatch, status_code, payload, raise_exc=None):
    def fake_get(url, params, timeout):
        assert url == "https://oauth2.googleapis.com/tokeninfo"
        if raise_exc:
            raise raise_exc
        return FakeResp(status_code, payload)

    monkeypatch.setattr(m.requests, "get", fake_get)


def test_google_auth_success(client, monkeypatch):
    _patch_tokeninfo(
        monkeypatch,
        200,
        {"email": "g@example.com", "sub": "sub-1", "email_verified": "true", "name": "جوجل"},
    )
    r = client.post("/api/auth/google", json={"idToken": "fake-token"})
    assert r.status_code == 200, r.text
    data = r.json()
    assert data["token"]
    assert data["user"]["email"] == "g@example.com"
    assert data["user"]["name"] == "جوجل"

    me = client.get("/api/auth/me", headers={"Authorization": f"Bearer {data['token']}"})
    assert me.status_code == 200


def test_google_auth_existing_user_returns_new_token(client, monkeypatch):
    _patch_tokeninfo(
        monkeypatch,
        200,
        {"email": "g@example.com", "sub": "sub-1", "email_verified": "true", "name": "جوجل"},
    )
    t1 = client.post("/api/auth/google", json={"idToken": "fake"}).json()["token"]
    t2 = client.post("/api/auth/google", json={"idToken": "fake"}).json()["token"]
    assert t1 != t2
    assert client.get("/api/auth/me", headers={"Authorization": f"Bearer {t1}"}).status_code == 200


def test_google_auth_invalid_token_401(client, monkeypatch):
    _patch_tokeninfo(monkeypatch, 400, {})
    r = client.post("/api/auth/google", json={"idToken": "bad"})
    assert r.status_code == 401


def test_google_auth_network_error_502(client, monkeypatch):
    _patch_tokeninfo(monkeypatch, 0, {}, raise_exc=RuntimeError("boom"))
    r = client.post("/api/auth/google", json={"idToken": "x"})
    assert r.status_code == 502


def test_google_auth_unverified_email_401(client, monkeypatch):
    _patch_tokeninfo(
        monkeypatch,
        200,
        {"email": "g@example.com", "sub": "sub-1", "email_verified": "false"},
    )
    r = client.post("/api/auth/google", json={"idToken": "x"})
    assert r.status_code == 401
    assert "غير موثق" in r.json()["detail"]


def test_google_auth_aud_mismatch_401(client, monkeypatch):
    monkeypatch.setattr(m, "GOOGLE_CLIENT_ID", "expected-client")
    _patch_tokeninfo(
        monkeypatch,
        200,
        {"email": "g@example.com", "sub": "sub-1", "email_verified": "true", "aud": "other-client"},
    )
    r = client.post("/api/auth/google", json={"idToken": "x"})
    assert r.status_code == 401


@pytest.mark.parametrize(
    "payload,detail",
    [
        ({"email": "g@example.com"}, "توكن جوجل غير صالح"),
        ({"sub": "sub-1", "email_verified": "true"}, "توكن جوجل غير صالح"),
    ],
)
def test_google_auth_missing_claims_401(client, monkeypatch, payload, detail):
    _patch_tokeninfo(monkeypatch, 200, {**payload, "email_verified": "true"})
    r = client.post("/api/auth/google", json={"idToken": "x"})
    assert r.status_code == 401
