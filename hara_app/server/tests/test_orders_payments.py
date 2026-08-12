import pytest

import main as m


def _make_order(client, headers, **over):
    uid = client.get("/api/auth/me", headers=headers).json()["user"]["uid"]
    base = {
        "buyerId": uid,
        "buyerName": "المشتري",
        "buyerPhone": "0599000001",
        "buyerAddress": "رام الله",
        "buyerArea": "رام الله",
        "items": [{"id": "p1", "title": "سلعة", "price": 10, "quantity": 2}],
        "subtotal": 20,
        "total": 27,
        "paymentMethod": "cash",
        "paymentStatus": "pending",
    }
    base.update(over)
    return base


def _create_order(client, headers, **over):
    r = client.post("/api/orders", json=_make_order(client, headers, **over), headers=headers)
    assert r.status_code == 200, r.text
    return r.json()


def test_create_order(client, auth_headers):
    headers = auth_headers()
    order = _create_order(client, headers)
    assert order["status"] == "pending"
    assert order["items"][0]["title"] == "سلعة"
    assert order["total"] == 27


def test_list_buyer_orders(client, auth_headers):
    headers = auth_headers()
    oid = _create_order(client, headers)["id"]
    orders = client.get("/api/orders?scope=buyer", headers=headers).json()
    assert [o["id"] for o in orders] == [oid]


def test_update_status_notifies_buyer(client, auth_headers):
    buyer_headers = auth_headers("buyer@example.com", name="المشتري")
    seller_headers = auth_headers("seller@example.com", name="البائع")
    oid = _create_order(client, buyer_headers)["id"]

    r = client.patch(
        f"/api/orders/{oid}",
        json={"status": "accepted", "deliveryPersonId": "d1", "deliveryPersonName": "موصل"},
        headers=seller_headers,
    )
    assert r.status_code == 200
    assert r.json()["status"] == "accepted"

    notes = client.get("/api/notifications", headers=buyer_headers).json()
    assert any(n["iconKey"] == "order" and "accepted" in n["body"] for n in notes)


def test_update_missing_order_404(client, auth_headers):
    r = client.patch("/api/orders/nope", json={"status": "accepted"}, headers=auth_headers())
    assert r.status_code == 404


def test_mark_delivered_sets_delivered_at(client, auth_headers):
    headers = auth_headers()
    oid = _create_order(client, headers)["id"]
    r = client.patch(f"/api/orders/{oid}", json={"status": "delivered"}, headers=headers)
    assert r.status_code == 200
    assert r.json()["status"] == "delivered"
    assert r.json()["deliveredAt"]


# ---------------- payments ----------------


def test_payment_intent_missing_order_404(client, auth_headers):
    r = client.post(
        "/api/payments/intent", json={"orderId": "nope"}, headers=auth_headers()
    )
    assert r.status_code == 404


def test_payment_intent_foreign_order_404(client, auth_headers):
    h1 = auth_headers("a@example.com")
    h2 = auth_headers("b@example.com")
    oid = _create_order(client, h1)["id"]
    r = client.post("/api/payments/intent", json={"orderId": oid}, headers=h2)
    assert r.status_code == 404


def test_payment_intent_simulation_mode(client, auth_headers):
    headers = auth_headers()
    oid = _create_order(client, headers)["id"]
    r = client.post("/api/payments/intent", json={"orderId": oid}, headers=headers)
    assert r.status_code == 200, r.text
    data = r.json()
    assert data["paid"] is False
    assert data["simulated"] is True


def test_simulate_payment_marks_paid(client, auth_headers):
    headers = auth_headers()
    oid = _create_order(client, headers)["id"]
    r = client.post(f"/api/payments/simulate/{oid}", headers=headers)
    assert r.status_code == 200, r.text
    assert r.json()["paymentStatus"] == "paid"
    assert r.json()["paidAt"]
    assert r.json()["paymentRef"].startswith("sim-")

    again = client.post("/api/payments/intent", json={"orderId": oid}, headers=headers)
    assert again.json()["paid"] is True


def test_simulate_payment_missing_order_404(client, auth_headers):
    r = client.post("/api/payments/simulate/nope", headers=auth_headers())
    assert r.status_code == 404


def test_simulate_payment_blocked_when_gateway_active(client, auth_headers, monkeypatch):
    monkeypatch.setattr(m, "GATEWAY", "myfatoorah")
    headers = auth_headers()
    oid = _create_order(client, headers)["id"]
    r = client.post(f"/api/payments/simulate/{oid}", headers=headers)
    assert r.status_code == 400


def test_webhook_success_marks_paid(client, auth_headers):
    headers = auth_headers()
    oid = _create_order(client, headers)["id"]
    r = client.post(
        "/api/payments/webhook",
        json={"Event": "TRANSACTIONS.UPDATED", "Data": {"CustomerReference": oid, "TransactionStatus": "SUCCESS"}},
    )
    assert r.status_code == 200
    assert r.json() == {"received": True, "ok": True}
    assert client.get("/api/orders?scope=buyer", headers=headers).json()[0]["paymentStatus"] == "paid"


def test_webhook_unknown_order(client, auth_headers):
    r = client.post(
        "/api/payments/webhook",
        json={"Event": "SUCCESS", "Data": {"CustomerReference": "nope", "TransactionStatus": "SUCCESS"}},
    )
    assert r.json() == {"received": True, "ok": False}


def test_webhook_failed_transaction_not_paid(client, auth_headers):
    headers = auth_headers()
    oid = _create_order(client, headers)["id"]
    r = client.post(
        "/api/payments/webhook",
        json={"Event": "SUCCESS", "Data": {"CustomerReference": oid, "TransactionStatus": "FAILED"}},
    )
    assert r.json()["ok"] is False
    assert client.get("/api/orders?scope=buyer", headers=headers).json()[0]["paymentStatus"] == "pending"


# ---------------- live gateways (mocked) ----------------


class FakeResp:
    def __init__(self, status_code, payload):
        self.status_code = status_code
        self._payload = payload

    def json(self):
        return self._payload


def test_myfatoorah_intent_success(client, auth_headers, monkeypatch):
    monkeypatch.setattr(m, "GATEWAY", "myfatoorah")
    monkeypatch.setattr(m, "MYFATOORAH_TOKEN", "tok")
    calls = {}

    def fake_post(url, json=None, headers=None, timeout=None):
        calls["url"] = url
        calls["body"] = json
        return FakeResp(200, {"IsSuccess": True, "Data": {"InvoiceId": 999, "InvoiceURL": "https://pay/x"}})

    monkeypatch.setattr(m.requests, "post", fake_post)

    headers = auth_headers()
    oid = _create_order(client, headers)["id"]
    r = client.post("/api/payments/intent", json={"orderId": oid, "paymentMethod": "wallet"}, headers=headers)
    assert r.status_code == 200, r.text
    assert r.json()["paid"] is False
    assert r.json()["paymentUrl"] == "https://pay/x"
    assert r.json()["ref"] == "999"
    assert "myfatoorah.com" in calls["url"]
    assert calls["body"]["PaymentMethodId"] == 2
    assert calls["body"]["InvoiceValue"] == 27
    assert calls["body"]["CustomerReference"] == oid


def test_myfatoorah_intent_failure_502(client, auth_headers, monkeypatch):
    monkeypatch.setattr(m, "GATEWAY", "myfatoorah")
    monkeypatch.setattr(m, "MYFATOORAH_TOKEN", "tok")

    def fake_post(url, json=None, headers=None, timeout=None):
        return FakeResp(200, {"IsSuccess": False, "Message": "رصيد غير كاف"})

    monkeypatch.setattr(m.requests, "post", fake_post)

    headers = auth_headers()
    oid = _create_order(client, headers)["id"]
    r = client.post("/api/payments/intent", json={"orderId": oid}, headers=headers)
    assert r.status_code == 502
    assert "رصيد غير كاف" in r.json()["detail"]


def test_myfatoorah_intent_network_error_502(client, auth_headers, monkeypatch):
    monkeypatch.setattr(m, "GATEWAY", "myfatoorah")
    monkeypatch.setattr(m, "MYFATOORAH_TOKEN", "tok")

    def fake_post(url, json=None, headers=None, timeout=None):
        raise RuntimeError("conn refused")

    monkeypatch.setattr(m.requests, "post", fake_post)

    headers = auth_headers()
    oid = _create_order(client, headers)["id"]
    r = client.post("/api/payments/intent", json={"orderId": oid}, headers=headers)
    assert r.status_code == 502


def test_palpay_incomplete_503(client, auth_headers, monkeypatch):
    monkeypatch.setattr(m, "GATEWAY", "palpay")
    monkeypatch.setattr(m, "PALPAY_MERCHANT", "")
    headers = auth_headers()
    oid = _create_order(client, headers)["id"]
    r = client.post("/api/payments/intent", json={"orderId": oid}, headers=headers)
    assert r.status_code == 503
    assert "PalPay" in r.json()["detail"]
