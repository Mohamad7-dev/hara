def _product_payload(**over):
    base = {
        "title": "منتج تجريبي",
        "description": "وصف",
        "price": 25.5,
        "currency": "شيكل",
        "category": "مواد غذائية",
        "images": ["img1", "img2"],
        "stock": 5,
        "unit": "كيلو",
        "isAvailable": True,
        "featured": True,
    }
    base.update(over)
    return base


def test_list_products_empty(client):
    assert client.get("/api/products").json() == []


def test_create_product_requires_auth(client):
    r = client.post("/api/products", json=_product_payload())
    assert r.status_code == 401


def test_create_and_list_product(client, auth_headers):
    headers = auth_headers()
    r = client.post("/api/products", json=_product_payload(), headers=headers)
    assert r.status_code == 200, r.text
    p = r.json()
    assert p["title"] == "منتج تجريبي"
    assert p["price"] == 25.5
    assert p["stock"] == 5
    assert p["isAvailable"] is True
    assert p["featured"] is True
    assert p["images"] == ["img1", "img2"]
    assert p["rating"] == 0

    listed = client.get("/api/products").json()
    assert len(listed) == 1
    assert listed[0]["id"] == p["id"]


def test_decrement_stock(client, auth_headers):
    headers = auth_headers()
    pid = client.post("/api/products", json=_product_payload(stock=3), headers=headers).json()["id"]

    r = client.post(f"/api/products/{pid}/stock?quantity=2", headers=headers)
    assert r.status_code == 200
    assert r.json()["stock"] == 1
    assert r.json()["isAvailable"] is True

    r = client.post(f"/api/products/{pid}/stock?quantity=10", headers=headers)
    assert r.json()["stock"] == 0
    assert r.json()["isAvailable"] is False


def test_decrement_stock_missing_product_404(client, auth_headers):
    r = client.post("/api/products/nope/stock?quantity=1", headers=auth_headers())
    assert r.status_code == 404


def test_review_out_of_bounds_400(client, auth_headers):
    headers = auth_headers()
    pid = client.post("/api/products", json=_product_payload(), headers=headers).json()["id"]
    assert client.post(f"/api/products/{pid}/review?rating=0", headers=headers).status_code == 400
    assert client.post(f"/api/products/{pid}/review?rating=6", headers=headers).status_code == 400


def test_review_averages(client, auth_headers):
    headers = auth_headers()
    pid = client.post("/api/products", json=_product_payload(), headers=headers).json()["id"]

    client.post(f"/api/products/{pid}/review?rating=4", headers=headers)
    r = client.post(f"/api/products/{pid}/review?rating=2", headers=headers)
    assert r.status_code == 200
    assert r.json()["ratingCount"] == 2
    assert r.json()["rating"] == 3.0


def test_review_missing_product_404(client, auth_headers):
    r = client.post("/api/products/nope/review?rating=4", headers=auth_headers())
    assert r.status_code == 404
