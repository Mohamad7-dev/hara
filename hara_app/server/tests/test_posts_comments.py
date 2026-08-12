def _create_post(client, headers, text="منشور تجريبي"):
    r = client.post("/api/posts", json={"category": "منشور", "text": text}, headers=headers)
    assert r.status_code == 200, r.text
    return r.json()


def test_create_post(client, auth_headers):
    headers = auth_headers()
    post = _create_post(client, headers)
    assert post["author"] == "مستخدم 1"
    assert post["text"] == "منشور تجريبي"
    assert post["likes"] == 0
    assert post["liked"] is False
    assert post["comments"] == 0


def test_list_posts_without_auth(client, auth_headers):
    _create_post(client, auth_headers())
    posts = client.get("/api/posts").json()
    assert len(posts) == 1
    assert posts[0]["liked"] is False


def test_create_post_requires_auth(client):
    assert client.post("/api/posts", json={"text": "x"}).status_code == 401


def test_like_toggle(client, auth_headers):
    headers = auth_headers()
    pid = _create_post(client, headers)["id"]

    liked = client.post(f"/api/posts/{pid}/like", headers=headers).json()
    assert liked["liked"] is True
    assert liked["likes"] == 1

    unliked = client.post(f"/api/posts/{pid}/like", headers=headers).json()
    assert unliked["liked"] is False
    assert unliked["likes"] == 0


def test_like_missing_post_404(client, auth_headers):
    r = client.post("/api/posts/nope/like", headers=auth_headers())
    assert r.status_code == 404


def test_like_notifies_author(client, auth_headers):
    author_headers = auth_headers("author@example.com", name="المؤلف")
    post_id = _create_post(client, author_headers)["id"]
    fan_headers = auth_headers("fan@example.com", name="المعجب")

    client.post(f"/api/posts/{post_id}/like", headers=fan_headers)

    notes = client.get("/api/notifications", headers=author_headers).json()
    assert any(n["iconKey"] == "like" and "أعجب" in n["body"] for n in notes)


def test_add_comment_and_list(client, auth_headers):
    headers = auth_headers()
    post_id = _create_post(client, headers)["id"]

    r = client.post(
        "/api/comments",
        json={"kind": "post", "targetId": post_id, "text": "تعليق أول"},
        headers=headers,
    )
    assert r.status_code == 200, r.text
    cid = r.json()["id"]
    assert r.json()["replies"] == []

    listed = client.get(f"/api/comments?kind=post&targetId={post_id}").json()
    assert len(listed) == 1
    assert listed[0]["text"] == "تعليق أول"


def test_add_reply(client, auth_headers):
    headers = auth_headers()
    post_id = _create_post(client, headers)["id"]
    cid = client.post(
        "/api/comments", json={"kind": "post", "targetId": post_id, "text": "أصل"}, headers=headers
    ).json()["id"]

    r = client.post(f"/api/comments/{cid}/replies", json={"text": "رد"}, headers=headers)
    assert r.status_code == 200, r.text
    assert r.json()["text"] == "رد"

    listed = client.get(f"/api/comments?kind=post&targetId={post_id}").json()
    assert len(listed[0]["replies"]) == 1
    assert listed[0]["replies"][0]["text"] == "رد"


def test_reply_missing_comment_404(client, auth_headers):
    r = client.post("/api/comments/nope/replies", json={"text": "رد"}, headers=auth_headers())
    assert r.status_code == 404


def test_comment_on_product_kind(client, auth_headers):
    headers = auth_headers()
    prod = client.post(
        "/api/products",
        json={"title": "سلعة", "price": 10},
        headers=headers,
    ).json()
    r = client.post(
        "/api/comments",
        json={"kind": "product", "targetId": prod["id"], "text": "تعليق", "rating": 5},
        headers=headers,
    )
    assert r.status_code == 200
    assert r.json()["kind"] == "product"
    assert r.json()["rating"] == 5
