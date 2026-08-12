def test_open_chat_by_name(client, auth_headers):
    me = auth_headers("me@example.com", name="أنا")
    peer = auth_headers("peer@example.com", name="الطرف الآخر")

    r = client.post("/api/chats/open", json={"peerName": "الطرف الآخر"}, headers=me)
    assert r.status_code == 200, r.text
    chat = r.json()
    assert chat["id"] != "me@example.com"
    assert chat["messages"] == []

    listed = client.get("/api/chats", headers=me).json()
    assert len(listed) == 1
    assert listed[0]["name"] == "الطرف الآخر"


def test_open_chat_missing_peer_404(client, auth_headers):
    headers = auth_headers()
    r = client.post("/api/chats/open", json={"peerName": "غير موجود"}, headers=headers)
    assert r.status_code == 404


def test_open_chat_self_404(client, auth_headers):
    headers = auth_headers()
    r = client.post("/api/chats/open", json={"peerName": "مستخدم 1"}, headers=headers)
    assert r.status_code == 404


def test_send_message_and_unread(client, auth_headers):
    me = auth_headers("me@example.com", name="أنا")
    peer_headers = auth_headers("peer@example.com", name="الطرف الآخر")
    peer_uid = client.get("/api/auth/me", headers=peer_headers).json()["user"]["uid"]

    r = client.post(f"/api/chats/{peer_uid}/messages", json={"text": "مرحباً"}, headers=me)
    assert r.status_code == 200, r.text
    msg = r.json()
    assert msg["from"] == "me"
    assert msg["text"] == "مرحباً"
    assert msg["read"] is False

    peer_view = client.get("/api/chats", headers=peer_headers).json()
    assert len(peer_view) == 1
    assert peer_view[0]["unread"] == 1
    assert peer_view[0]["messages"][0]["from"] == "them"
    assert peer_view[0]["messages"][0]["read"] is True


def test_send_message_to_self_400(client, auth_headers):
    headers = auth_headers()
    uid = client.get("/api/auth/me", headers=headers).json()["user"]["uid"]
    r = client.post(f"/api/chats/{uid}/messages", json={"text": "أنا"}, headers=headers)
    assert r.status_code == 400


def test_send_message_missing_peer_404(client, auth_headers):
    r = client.post("/api/chats/nobody/messages", json={"text": "هلا"}, headers=auth_headers())
    assert r.status_code == 404


def test_mark_chat_read(client, auth_headers):
    me = auth_headers("me@example.com", name="أنا")
    peer_headers = auth_headers("peer@example.com", name="الطرف الآخر")
    my_uid = client.get("/api/auth/me", headers=me).json()["user"]["uid"]
    peer_uid = client.get("/api/auth/me", headers=peer_headers).json()["user"]["uid"]

    client.post(f"/api/chats/{peer_uid}/messages", json={"text": "مرحباً"}, headers=me)
    assert client.post(f"/api/chats/{my_uid}/read", headers=peer_headers).status_code == 200

    peer_view = client.get("/api/chats", headers=peer_headers).json()
    assert peer_view[0]["unread"] == 0

    my_view = client.get("/api/chats", headers=me).json()
    assert my_view[0]["messages"][0]["from"] == "me"
    assert my_view[0]["messages"][0]["read"] is True


def test_notifications_created_by_actions_and_mark_read(client, auth_headers):
    author_headers = auth_headers("author@example.com", name="المؤلف")
    other_headers = auth_headers("other@example.com", name="الآخر")
    author_uid = client.get("/api/auth/me", headers=author_headers).json()["user"]["uid"]

    post_id = client.post(
        "/api/posts", json={"text": "منشور مهم"}, headers=author_headers
    ).json()["id"]
    client.post(f"/api/posts/{post_id}/like", headers=other_headers)
    client.post(f"/api/chats/{author_uid}/messages", json={"text": "رسالة"}, headers=other_headers)

    notes = client.get("/api/notifications", headers=author_headers).json()
    assert len(notes) == 2
    assert all(n["read"] is False for n in notes)

    r = client.post("/api/notifications/read", headers=author_headers)
    assert r.status_code == 200
    notes = client.get("/api/notifications", headers=author_headers).json()
    assert all(n["read"] is True for n in notes)


def test_notifications_requires_auth(client):
    assert client.get("/api/notifications").status_code == 401
