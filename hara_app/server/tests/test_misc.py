import base64

import main as m


def test_health(client):
    r = client.get("/api/health")
    assert r.status_code == 200
    assert r.json() == {"ok": True}


def test_config_defaults_to_simulation(client):
    r = client.get("/api/config")
    assert r.status_code == 200
    data = r.json()
    assert data["onlinePayment"] is False
    assert data["gateway"] == "simulate"


def test_config_gateway_active(client, monkeypatch):
    monkeypatch.setattr(m, "GATEWAY", "myfatoorah")
    data = client.get("/api/config").json()
    assert data["onlinePayment"] is True
    assert data["gateway"] == "myfatoorah"


# ---------------- favorites ----------------


def test_favorites_toggle_and_list(client, auth_headers):
    headers = auth_headers()
    pid = client.post(
        "/api/products", json={"title": "سلعة", "price": 5}, headers=headers
    ).json()["id"]

    assert client.get("/api/favorites", headers=headers).json() == []
    client.post(f"/api/favorites/{pid}", headers=headers)
    assert [f["id"] for f in client.get("/api/favorites", headers=headers).json()] == [pid]

    client.post(f"/api/favorites/{pid}", headers=headers)
    assert client.get("/api/favorites", headers=headers).json() == []


# ---------------- delivery ----------------


def test_delivery_list_and_area_filter(client, auth_headers):
    headers = auth_headers()
    client.post(
        "/api/auth/register",
        json={
            "name": "موصل رام الله",
            "email": "d1@example.com",
            "password": "secret123",
            "userType": "delivery",
            "deliveryAreas": ["رام الله"],
            "deliveryFee": 8,
        },
    )
    client.post(
        "/api/auth/register",
        json={
            "name": "موصل الخليل",
            "email": "d2@example.com",
            "password": "secret123",
            "userType": "delivery",
            "deliveryAreas": ["الخليل"],
            "deliveryFee": 10,
        },
    )

    all_deliveries = client.get("/api/delivery", headers=headers).json()
    assert len(all_deliveries) == 2

    ramallah = client.get("/api/delivery?area=رام الله", headers=headers).json()
    assert [d["name"] for d in ramallah] == ["موصل رام الله"]

    hebron = client.get("/api/delivery?area=الخليل", headers=headers).json()
    assert [d["name"] for d in hebron] == ["موصل الخليل"]


def test_delivery_list_orders_scope(client, auth_headers):
    buyer = auth_headers("buyer@example.com", name="مشتري")
    delivery = client.post(
        "/api/auth/register",
        json={
            "name": "موصل",
            "email": "del2@example.com",
            "password": "secret123",
            "userType": "delivery",
            "deliveryAreas": ["رام الله"],
            "deliveryFee": 7,
        },
    ).json()
    delivery_headers = {"Authorization": f"Bearer {delivery['token']}"}

    client.post(
        "/api/orders",
        json={
            "buyerId": "x",
            "buyerName": "مشتري",
            "buyerPhone": "0599000001",
            "buyerAddress": "رام الله",
            "buyerArea": "رام الله",
            "items": [],
            "subtotal": 0,
            "total": 7,
        },
        headers=buyer,
    )

    scope = client.get("/api/orders?scope=delivery", headers=delivery_headers).json()
    assert len(scope["available"]) == 1
    assert scope["mine"] == []


# ---------------- media ----------------


def test_upload_and_get_media(client, auth_headers):
    headers = auth_headers()
    b64 = base64.b64encode(b"\x89PNG fake image bytes").decode()
    r = client.post("/api/media", json={"base64": b64}, headers=headers)
    assert r.status_code == 200, r.text
    url = r.json()["url"]
    assert url.startswith("/api/media/")

    media = client.get(url)
    assert media.status_code == 200
    assert media.headers["content-type"] == "image/png"
    assert media.content == b"\x89PNG fake image bytes"


def test_upload_media_data_uri(client, auth_headers):
    headers = auth_headers()
    b64 = base64.b64encode(b"raw").decode()
    r = client.post(
        "/api/media", json={"base64": f"data:image/jpeg;base64,{b64}"}, headers=headers
    )
    assert r.status_code == 200
    media = client.get(r.json()["url"])
    assert media.headers["content-type"] == "image/jpeg"


def test_upload_invalid_base64_400(client, auth_headers):
    r = client.post("/api/media", json={"base64": "!!not-base64!!"}, headers=auth_headers())
    assert r.status_code == 400


def test_upload_media_requires_auth(client):
    assert client.post("/api/media", json={"base64": "AAAA"}).status_code == 401


def test_media_missing_404(client):
    assert client.get("/api/media/nope").status_code == 404
