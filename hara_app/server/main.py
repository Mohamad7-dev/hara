import base64
import hashlib
import json
import os
import secrets
import sqlite3
import time
import uuid
from datetime import datetime, timezone
from typing import List, Optional

import requests
from fastapi import Depends, FastAPI, Header, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from pydantic import BaseModel

DB_PATH = os.path.join(os.path.dirname(__file__), "hara.db")

GATEWAY = os.getenv("GATEWAY", "").strip().lower()

MYFATOORAH_TOKEN = os.getenv("MYFATOORAH_TOKEN", "").strip()
MYFATOORAH_BASE = os.getenv(
    "MYFATOORAH_BASE",
    "https://apitest.myfatoorah.com" if not os.getenv("MYFATOORAH_LIVE") else "https://api.myfatoorah.com",
).strip()
MYFATOORAH_CALLBACK = os.getenv("MYFATOORAH_CALLBACK", "").strip()
MYFATOORAH_ERROR_URL = os.getenv("MYFATOORAH_ERROR_URL", "").strip()

PALPAY_BASE = os.getenv("PALPAY_BASE", "https://sandbox.palpay.ps").strip()
PALPAY_MERCHANT = os.getenv("PALPAY_MERCHANT", "").strip()
PALPAY_USERNAME = os.getenv("PALPAY_USERNAME", "").strip()
PALPAY_PASSWORD = os.getenv("PALPAY_PASSWORD", "").strip()
PALPAY_SIGNATURE = os.getenv("PALPAY_SIGNATURE", "").strip()
PALPAY_CALLBACK = os.getenv("PALPAY_CALLBACK", "").strip()

WEBHOOK_PATH = os.getenv("WEBHOOK_PATH", "/api/payments/webhook").strip()

GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID", "").strip()

app = FastAPI(title="Hara API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def utcnow() -> str:
    return datetime.now(timezone.utc).isoformat()


# ---------------------------------------------------------------- DB helpers

def db() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    conn = db()
    conn.executescript(
        """
        CREATE TABLE IF NOT EXISTS users (
            uid TEXT PRIMARY KEY,
            email TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            name TEXT NOT NULL,
            phone TEXT NOT NULL DEFAULT '',
            address TEXT NOT NULL DEFAULT '',
            area TEXT,
            photo TEXT,
            user_type TEXT NOT NULL DEFAULT 'regular',
            store_name TEXT,
            store_description TEXT,
            delivery_fee REAL,
            delivery_areas TEXT,
            vehicle_type TEXT,
            rating REAL DEFAULT 0,
            rating_count INTEGER DEFAULT 0,
            phone_verified INTEGER DEFAULT 0,
            is_active INTEGER DEFAULT 1,
            created_at TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS tokens (
            token TEXT PRIMARY KEY,
            uid TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS products (
            id TEXT PRIMARY KEY,
            seller_id TEXT NOT NULL,
            seller_name TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT NOT NULL DEFAULT '',
            price REAL NOT NULL,
            currency TEXT NOT NULL DEFAULT 'شيكل',
            category TEXT NOT NULL DEFAULT '',
            images TEXT NOT NULL DEFAULT '[]',
            stock INTEGER NOT NULL DEFAULT 1,
            unit TEXT,
            is_available INTEGER NOT NULL DEFAULT 1,
            featured INTEGER NOT NULL DEFAULT 0,
            rating REAL NOT NULL DEFAULT 0,
            rating_count INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS posts (
            id TEXT PRIMARY KEY,
            author_uid TEXT NOT NULL,
            author TEXT NOT NULL,
            role TEXT NOT NULL DEFAULT '',
            avatar_key TEXT NOT NULL DEFAULT 'person',
            category TEXT NOT NULL DEFAULT 'منشور',
            time TEXT NOT NULL,
            text TEXT NOT NULL DEFAULT '',
            has_image INTEGER NOT NULL DEFAULT 0
        );
        CREATE TABLE IF NOT EXISTS post_likes (
            post_id TEXT NOT NULL,
            uid TEXT NOT NULL,
            PRIMARY KEY (post_id, uid)
        );
        CREATE TABLE IF NOT EXISTS comments (
            id TEXT PRIMARY KEY,
            kind TEXT NOT NULL,
            target_id TEXT NOT NULL,
            author_uid TEXT NOT NULL,
            author TEXT NOT NULL,
            role TEXT NOT NULL DEFAULT '',
            avatar_key TEXT NOT NULL DEFAULT 'person',
            text TEXT NOT NULL DEFAULT '',
            rating INTEGER NOT NULL DEFAULT 0,
            time TEXT NOT NULL,
            parent_id TEXT
        );
        CREATE TABLE IF NOT EXISTS conversations (
            uid_a TEXT NOT NULL,
            uid_b TEXT NOT NULL,
            PRIMARY KEY (uid_a, uid_b)
        );
        CREATE TABLE IF NOT EXISTS messages (
            id TEXT PRIMARY KEY,
            uid_a TEXT NOT NULL,
            uid_b TEXT NOT NULL,
            sender_uid TEXT NOT NULL,
            text TEXT NOT NULL DEFAULT '',
            img TEXT,
            audio TEXT,
            time TEXT NOT NULL,
            read_a INTEGER NOT NULL DEFAULT 1,
            read_b INTEGER NOT NULL DEFAULT 1
        );
        CREATE TABLE IF NOT EXISTS orders (
            id TEXT PRIMARY KEY,
            buyer_id TEXT NOT NULL,
            buyer_name TEXT NOT NULL,
            buyer_phone TEXT NOT NULL,
            buyer_address TEXT NOT NULL,
            buyer_area TEXT,
            delivery_person_id TEXT,
            delivery_person_name TEXT,
            delivery_fee REAL,
            status TEXT NOT NULL DEFAULT 'pending',
            items TEXT NOT NULL,
            subtotal REAL NOT NULL,
            total REAL NOT NULL,
            payment_method TEXT NOT NULL DEFAULT 'cash',
            payment_status TEXT NOT NULL DEFAULT 'pending',
            payment_ref TEXT,
            paid_at TEXT,
            notes TEXT,
            created_at TEXT NOT NULL,
            delivered_at TEXT
        );
        CREATE TABLE IF NOT EXISTS notifications (
            id TEXT PRIMARY KEY,
            uid TEXT NOT NULL,
            icon_key TEXT NOT NULL DEFAULT 'info',
            title TEXT NOT NULL,
            body TEXT NOT NULL DEFAULT '',
            time TEXT NOT NULL,
            read INTEGER NOT NULL DEFAULT 0
        );
        CREATE TABLE IF NOT EXISTS favorites (
            uid TEXT NOT NULL,
            product_id TEXT NOT NULL,
            PRIMARY KEY (uid, product_id)
        );
        CREATE TABLE IF NOT EXISTS media (
            id TEXT PRIMARY KEY,
            data BLOB NOT NULL,
            mime TEXT NOT NULL DEFAULT 'image/png'
        );
        """
    )
    conn.commit()
    for col in ("payment_ref", "paid_at"):
        try:
            conn.execute(f"ALTER TABLE orders ADD COLUMN {col} TEXT")
            conn.commit()
        except sqlite3.OperationalError:
            pass
    try:
        conn.execute("ALTER TABLE users ADD COLUMN photo TEXT")
        conn.commit()
    except sqlite3.OperationalError:
        pass
    try:
        conn.execute("ALTER TABLE users ADD COLUMN phone_verified INTEGER DEFAULT 0")
        conn.commit()
    except sqlite3.OperationalError:
        pass
    try:
        conn.execute("ALTER TABLE messages ADD COLUMN audio TEXT")
        conn.commit()
    except sqlite3.OperationalError:
        pass
    conn.close()


def _hash_password(password: str) -> str:
    salt = secrets.token_bytes(16)
    dk = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, 200_000)
    return salt.hex() + "$" + dk.hex()


def _verify_password(password: str, stored: str) -> bool:
    try:
        salt_hex, dk_hex = stored.split("$")
        salt = bytes.fromhex(salt_hex)
        dk = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, 200_000)
        return secrets.compare_digest(dk.hex(), dk_hex)
    except Exception:
        return False


# ---------------------------------------------------------------- auth

def _user_json(row: sqlite3.Row) -> dict:
    return {
        "uid": row["uid"],
        "email": row["email"],
        "name": row["name"],
        "phone": row["phone"],
        "address": row["address"],
        "area": row["area"],
        "photo": row["photo"],
        "userType": row["user_type"],
        "storeName": row["store_name"],
        "storeDescription": row["store_description"],
        "deliveryFee": row["delivery_fee"],
        "deliveryAreas": _load_json(row["delivery_areas"], None),
        "vehicleType": row["vehicle_type"],
        "rating": row["rating"],
        "ratingCount": row["rating_count"],
        "phoneVerified": bool(row["phone_verified"]),
        "isActive": bool(row["is_active"]),
        "createdAt": row["created_at"],
    }


def _user_from_uid(uid: str) -> Optional[sqlite3.Row]:
    conn = db()
    row = conn.execute("SELECT * FROM users WHERE uid = ?", (uid,)).fetchone()
    conn.close()
    return row


def _require_user(authorization: Optional[str] = Header(None)) -> sqlite3.Row:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="غير مصرح")
    token = authorization.split(" ", 1)[1].strip()
    conn = db()
    row = conn.execute(
        "SELECT u.* FROM users u JOIN tokens t ON t.uid = u.uid WHERE t.token = ?",
        (token,),
    ).fetchone()
    conn.close()
    if row is None:
        raise HTTPException(status_code=401, detail="غير مصرح")
    return row


# ---------------------------------------------------------------- request models

class RegisterIn(BaseModel):
    name: str
    email: str
    phone: str = ""
    address: str = ""
    password: str
    userType: str = "regular"
    deliveryAreas: Optional[List[str]] = None
    deliveryFee: Optional[float] = None
    vehicleType: Optional[str] = None


class LoginIn(BaseModel):
    email: str
    password: str


class GoogleAuthIn(BaseModel):
    idToken: str
    photo: Optional[str] = None


class ProfileIn(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    photo: Optional[str] = None
    area: Optional[str] = None
    deliveryAreas: Optional[List[str]] = None
    deliveryFee: Optional[float] = None
    vehicleType: Optional[str] = None
    userType: Optional[str] = None


class ProductIn(BaseModel):
    title: str
    description: str = ""
    price: float
    currency: str = "شيكل"
    category: str = ""
    images: List[str] = []
    stock: int = 1
    unit: Optional[str] = None
    isAvailable: bool = True
    featured: bool = False


class PostIn(BaseModel):
    category: str = "منشور"
    text: str = ""
    hasImage: bool = False


class CommentIn(BaseModel):
    kind: str = "post"
    targetId: str
    text: str = ""
    rating: int = 0


class ReplyIn(BaseModel):
    text: str = ""


class OrderIn(BaseModel):
    buyerId: str
    buyerName: str
    buyerPhone: str
    buyerAddress: str
    buyerArea: Optional[str] = None
    deliveryPersonId: Optional[str] = None
    deliveryPersonName: Optional[str] = None
    deliveryFee: Optional[float] = None
    status: str = "pending"
    items: List[dict]
    subtotal: float
    total: float
    paymentMethod: str = "cash"
    paymentStatus: str = "pending"
    notes: Optional[str] = None


class OrderStatusIn(BaseModel):
    status: str
    deliveryPersonId: Optional[str] = None
    deliveryPersonName: Optional[str] = None
    paymentStatus: Optional[str] = None
    paymentRef: Optional[str] = None


class MessageIn(BaseModel):
    text: str = ""
    img: Optional[str] = None
    audio: Optional[str] = None


class ChatOpenIn(BaseModel):
    peerName: str


class MediaIn(BaseModel):
    base64: str


# ---------------------------------------------------------------- helpers

def _load_json(raw, default):
    if not raw:
        return default
    try:
        return json.loads(raw)
    except Exception:
        return default


def _role_for(user_type: str) -> str:
    return {
        "seller": "بائع",
        "delivery": "موصل",
        "admin": "الإدارة",
    }.get(user_type, "مستخدم")


def _avatar_for(user_type: str) -> str:
    if user_type == "seller":
        return "store"
    if user_type == "delivery":
        return "motor"
    return "person"


def _post_json(row: sqlite3.Row, viewer_uid: Optional[str] = None) -> dict:
    conn = db()
    likes = conn.execute(
        "SELECT COUNT(*) FROM post_likes WHERE post_id = ?", (row["id"],)
    ).fetchone()[0]
    comments = conn.execute(
        "SELECT COUNT(*) FROM comments WHERE parent_id IS NULL AND kind = 'post' AND target_id = ?",
        (row["id"],),
    ).fetchone()[0]
    liked = False
    if viewer_uid:
        liked = (
            conn.execute(
                "SELECT 1 FROM post_likes WHERE post_id = ? AND uid = ?",
                (row["id"], viewer_uid),
            ).fetchone()
            is not None
        )
    conn.close()
    return {
        "id": row["id"],
        "author": row["author"],
        "role": row["role"],
        "avatarKey": row["avatar_key"],
        "category": row["category"],
        "time": row["time"],
        "text": row["text"],
        "hasImage": bool(row["has_image"]),
        "likes": likes,
        "comments": comments,
        "liked": liked,
    }


def _comment_json(row: sqlite3.Row, conn: sqlite3.Connection) -> dict:
    replies = conn.execute(
        "SELECT * FROM comments WHERE parent_id = ? ORDER BY time ASC",
        (row["id"],),
    ).fetchall()
    return {
        "id": row["id"],
        "kind": row["kind"],
        "targetId": row["target_id"],
        "author": row["author"],
        "role": row["role"],
        "avatarKey": row["avatar_key"],
        "text": row["text"],
        "rating": row["rating"],
        "time": row["time"],
        "replies": [_comment_json(r, conn) for r in replies],
    }


def _product_json(row: sqlite3.Row) -> dict:
    return {
        "id": row["id"],
        "sellerId": row["seller_id"],
        "sellerName": row["seller_name"],
        "title": row["title"],
        "description": row["description"],
        "price": row["price"],
        "currency": row["currency"],
        "category": row["category"],
        "images": _load_json(row["images"], []),
        "stock": row["stock"],
        "unit": row["unit"],
        "isAvailable": bool(row["is_available"]),
        "featured": bool(row["featured"]),
        "rating": row["rating"],
        "ratingCount": row["rating_count"],
        "createdAt": row["created_at"],
    }


def _order_json(row: sqlite3.Row) -> dict:
    return {
        "id": row["id"],
        "buyerId": row["buyer_id"],
        "buyerName": row["buyer_name"],
        "buyerPhone": row["buyer_phone"],
        "buyerAddress": row["buyer_address"],
        "buyerArea": row["buyer_area"],
        "deliveryPersonId": row["delivery_person_id"],
        "deliveryPersonName": row["delivery_person_name"],
        "deliveryFee": row["delivery_fee"],
        "status": row["status"],
        "items": _load_json(row["items"], []),
        "subtotal": row["subtotal"],
        "total": row["total"],
        "paymentMethod": row["payment_method"],
        "paymentStatus": row["payment_status"],
        "paymentRef": row["payment_ref"],
        "paidAt": row["paid_at"],
        "notes": row["notes"],
        "createdAt": row["created_at"],
        "deliveredAt": row["delivered_at"],
    }


def _message_json(row: sqlite3.Row, me: str) -> dict:
    is_mine = row["sender_uid"] == me
    read = True
    if is_mine:
        read = row["read_a"] if me == row["uid_b"] else row["read_b"]
    return {
        "id": row["id"],
        "from": "me" if is_mine else "them",
        "text": row["text"],
        "img": row["img"],
        "audio": row["audio"],
        "read": bool(read),
        "time": row["time"],
    }


def _conversation_json(peer: sqlite3.Row, me: str, conn: sqlite3.Connection) -> dict:
    a, b = sorted([me, peer["uid"]])
    msgs = conn.execute(
        "SELECT * FROM messages WHERE uid_a = ? AND uid_b = ? ORDER BY time ASC",
        (a, b),
    ).fetchall()
    unread = 0
    for m in msgs:
        if m["sender_uid"] != me:
            if (m["uid_a"] == me and not m["read_a"]) or (
                m["uid_b"] == me and not m["read_b"]
            ):
                unread += 1
    return {
        "id": peer["uid"],
        "name": peer["name"],
        "photo": peer["photo"],
        "role": _role_for(peer["user_type"]),
        "iconKey": _avatar_for(peer["user_type"]),
        "unread": unread,
        "messages": [_message_json(m, me) for m in msgs],
    }


def _add_notification(
    conn: sqlite3.Connection, uid: str, icon_key: str, title: str, body: str
):
    if not uid:
        return
    conn.execute(
        "INSERT INTO notifications (id, uid, icon_key, title, body, time, read) VALUES (?,?,?,?,?,?,0)",
        ("n" + uuid.uuid4().hex[:16], uid, icon_key, title, body, utcnow()),
    )


def _open_conversation(conn: sqlite3.Connection, me: str, peer: sqlite3.Row):
    a, b = sorted([me, peer["uid"]])
    conn.execute(
        "INSERT OR IGNORE INTO conversations (uid_a, uid_b) VALUES (?,?)",
        (a, b),
    )


# ---------------------------------------------------------------- seed
# لا يتم إنشاء أي حسابات أو محتوى تجريبي. كل المستخدمين ينشؤون عبر تسجيل
# الدخول بحساب جوجل فقط.

def _seed():
    return


# ---------------------------------------------------------------- auth endpoints

@app.get("/api/health")
def health():
    return {"ok": True}


@app.post("/api/auth/register")
def register(body: RegisterIn):
    conn = db()
    if conn.execute("SELECT 1 FROM users WHERE email = ?", (body.email,)).fetchone():
        conn.close()
        raise HTTPException(status_code=400, detail="البريد الإلكتروني مستخدم مسبقاً")
    uid = "u" + uuid.uuid4().hex[:12]
    conn.execute(
        "INSERT INTO users (uid, email, password, name, phone, address, user_type, delivery_fee, delivery_areas, vehicle_type, created_at) VALUES (?,?,?,?,?,?,?,?,?,?,?)",
        (
            uid, body.email, _hash_password(body.password), body.name, body.phone,
            body.address, body.userType, body.deliveryFee,
            json.dumps(body.deliveryAreas) if body.deliveryAreas else None,
            body.vehicleType, utcnow(),
        ),
    )
    token = uuid.uuid4().hex
    conn.execute("INSERT INTO tokens (token, uid) VALUES (?,?)", (token, uid))
    conn.commit()
    row = conn.execute("SELECT * FROM users WHERE uid = ?", (uid,)).fetchone()
    conn.close()
    return {"token": token, "user": _user_json(row)}


@app.post("/api/auth/login")
def login(body: LoginIn):
    conn = db()
    row = conn.execute("SELECT * FROM users WHERE email = ?", (body.email,)).fetchone()
    if row is None or not _verify_password(body.password, row["password"]):
        conn.close()
        raise HTTPException(status_code=401, detail="البريد الإلكتروني أو كلمة المرور غير صحيحة")
    token = uuid.uuid4().hex
    conn.execute("INSERT INTO tokens (token, uid) VALUES (?,?)", (token, row["uid"]))
    conn.commit()
    conn.close()
    return {"token": token, "user": _user_json(row)}


@app.post("/api/auth/google")
def google_auth(body: GoogleAuthIn):
    try:
        r = requests.get(
            "https://oauth2.googleapis.com/tokeninfo",
            params={"id_token": body.idToken},
            timeout=20,
        )
    except Exception:
        raise HTTPException(status_code=502, detail="تعذر الاتصال بجوجل")
    if r.status_code != 200:
        raise HTTPException(status_code=401, detail="توكن جوجل غير صالح")
    info = r.json()
    if GOOGLE_CLIENT_ID and info.get("aud") != GOOGLE_CLIENT_ID:
        raise HTTPException(status_code=401, detail="توكن جوجل غير صالح")
    if str(info.get("email_verified", "")).lower() not in ("true", "1"):
        raise HTTPException(status_code=401, detail="البريد الإلكتروني غير موثق")
    email = info.get("email")
    sub = info.get("sub")
    name = info.get("name") or (email or "").split("@")[0]
    photo = body.photo or info.get("picture")
    if not email or not sub:
        raise HTTPException(status_code=401, detail="توكن جوجل غير صالح")

    conn = db()
    row = conn.execute("SELECT * FROM users WHERE email = ?", (email,)).fetchone()
    if row is None:
        uid = "g" + hashlib.sha256(sub.encode()).hexdigest()[:12]
        conn.execute(
            "INSERT INTO users (uid, email, password, name, phone, address, photo, user_type, created_at) VALUES (?,?,?,?,?,?,?,?,?)",
            (uid, email, _hash_password(secrets.token_urlsafe(16)), name, "", "", photo, "regular", utcnow()),
        )
        row = conn.execute("SELECT * FROM users WHERE uid = ?", (uid,)).fetchone()
    elif photo and not row["photo"]:
        conn.execute("UPDATE users SET photo = ?, name = ? WHERE uid = ?", (photo, name, row["uid"]))
        row = conn.execute("SELECT * FROM users WHERE uid = ?", (row["uid"],)).fetchone()
    token = uuid.uuid4().hex
    conn.execute("INSERT INTO tokens (token, uid) VALUES (?,?)", (token, row["uid"]))
    conn.commit()
    conn.close()
    return {"token": token, "user": _user_json(row)}


@app.get("/api/auth/me")
def me(user: sqlite3.Row = Depends(_require_user)):
    return {"user": _user_json(user)}


@app.put("/api/auth/profile")
def update_profile(body: ProfileIn, user: sqlite3.Row = Depends(_require_user)):
    conn = db()
    fields = []
    vals = []
    if body.name is not None:
        fields.append("name = ?"); vals.append(body.name)
    if body.phone is not None and body.phone != user["phone"]:
        fields.append("phone = ?"); vals.append(body.phone)
        fields.append("phone_verified = ?"); vals.append(0)
    if body.photo is not None:
        fields.append("photo = ?"); vals.append(body.photo)
    if body.area is not None:
        fields.append("area = ?"); vals.append(body.area)
    if body.deliveryAreas is not None:
        fields.append("delivery_areas = ?"); vals.append(json.dumps(body.deliveryAreas))
    if body.deliveryFee is not None:
        fields.append("delivery_fee = ?"); vals.append(body.deliveryFee)
    if body.vehicleType is not None:
        fields.append("vehicle_type = ?"); vals.append(body.vehicleType)
    if body.userType is not None:
        fields.append("user_type = ?"); vals.append(body.userType)
    if fields:
        vals.append(user["uid"])
        conn.execute(f"UPDATE users SET {', '.join(fields)} WHERE uid = ?", vals)
        conn.commit()
    row = conn.execute("SELECT * FROM users WHERE uid = ?", (user["uid"],)).fetchone()
    conn.close()
    return {"user": _user_json(row)}


class SendCodeIn(BaseModel):
    phone: str


class VerifyCodeIn(BaseModel):
    phone: str
    code: str


_sms_codes: dict = {}


def _phone_ok(phone: str) -> bool:
    return len("".join(ch for ch in phone if ch.isdigit())) >= 9


@app.post("/api/auth/send-code")
def send_code(body: SendCodeIn, user: sqlite3.Row = Depends(_require_user)):
    if not _phone_ok(body.phone):
        raise HTTPException(status_code=400, detail="رقم الجوال غير صحيح")
    code = str(secrets.randbelow(1000000)).zfill(6)
    _sms_codes[body.phone] = (code, time.time() + 300)
    return {"ok": True, "expiresIn": 300, "debugCode": code if GATEWAY == "simulation" else None}


@app.post("/api/auth/verify-code")
def verify_code(body: VerifyCodeIn, user: sqlite3.Row = Depends(_require_user)):
    entry = _sms_codes.get(body.phone)
    if not entry or entry[1] < time.time():
        raise HTTPException(status_code=400, detail="انتهت صلاحية الرمز، أرسل رمزاً جديداً")
    if entry[0] != body.code.strip():
        raise HTTPException(status_code=400, detail="الرمز غير صحيح")
    _sms_codes.pop(body.phone, None)
    conn = db()
    conn.execute(
        "UPDATE users SET phone = ?, phone_verified = 1 WHERE uid = ?",
        (body.phone, user["uid"]),
    )
    conn.commit()
    row = conn.execute("SELECT * FROM users WHERE uid = ?", (user["uid"],)).fetchone()
    conn.close()
    return {"user": _user_json(row)}


@app.post("/api/auth/logout")
def logout(user: sqlite3.Row = Depends(_require_user)):
    conn = db()
    conn.execute("DELETE FROM tokens WHERE uid = ?", (user["uid"],))
    conn.commit()
    conn.close()
    return {"ok": True}


# ---------------------------------------------------------------- products

@app.get("/api/products")
def list_products():
    conn = db()
    rows = conn.execute("SELECT * FROM products ORDER BY created_at DESC").fetchall()
    conn.close()
    return [_product_json(r) for r in rows]


@app.post("/api/products")
def create_product(body: ProductIn, user: sqlite3.Row = Depends(_require_user)):
    pid = "p" + uuid.uuid4().hex[:12]
    conn = db()
    conn.execute(
        "INSERT INTO products (id, seller_id, seller_name, title, description, price, currency, category, images, stock, unit, is_available, featured, created_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
        (
            pid, user["uid"], user["name"], body.title, body.description, body.price,
            body.currency, body.category, json.dumps(body.images), body.stock,
            body.unit, 1 if body.isAvailable else 0, 1 if body.featured else 0,
            utcnow(),
        ),
    )
    conn.commit()
    row = conn.execute("SELECT * FROM products WHERE id = ?", (pid,)).fetchone()
    conn.close()
    return _product_json(row)


@app.post("/api/products/{pid}/stock")
def decrement_stock(pid: str, quantity: int = Query(1), user: sqlite3.Row = Depends(_require_user)):
    conn = db()
    row = conn.execute("SELECT * FROM products WHERE id = ?", (pid,)).fetchone()
    if row is None:
        conn.close()
        raise HTTPException(status_code=404, detail="المنتج غير موجود")
    new_stock = max(0, row["stock"] - quantity)
    conn.execute(
        "UPDATE products SET stock = ?, is_available = ? WHERE id = ?",
        (new_stock, 1 if new_stock > 0 else 0, pid),
    )
    conn.commit()
    updated = conn.execute("SELECT * FROM products WHERE id = ?", (pid,)).fetchone()
    conn.close()
    return _product_json(updated)


@app.post("/api/products/{pid}/review")
def add_review(pid: str, rating: int = Query(5), user: sqlite3.Row = Depends(_require_user)):
    if rating < 1 or rating > 5:
        raise HTTPException(status_code=400, detail="التقييم بين 1 و 5")
    conn = db()
    row = conn.execute("SELECT * FROM products WHERE id = ?", (pid,)).fetchone()
    if row is None:
        conn.close()
        raise HTTPException(status_code=404, detail="المنتج غير موجود")
    new_count = row["rating_count"] + 1
    new_rating = (row["rating"] * row["rating_count"] + rating) / new_count
    new_rating = round(new_rating, 1)
    conn.execute(
        "UPDATE products SET rating = ?, rating_count = ? WHERE id = ?",
        (new_rating, new_count, pid),
    )
    conn.commit()
    updated = conn.execute("SELECT * FROM products WHERE id = ?", (pid,)).fetchone()
    conn.close()
    return _product_json(updated)


# ---------------------------------------------------------------- posts

@app.get("/api/posts")
def list_posts(user: Optional[sqlite3.Row] = Depends(_require_user)):
    viewer = user["uid"] if user else None
    conn = db()
    rows = conn.execute("SELECT * FROM posts ORDER BY time DESC").fetchall()
    conn.close()
    return [_post_json(r, viewer) for r in rows]


@app.post("/api/posts")
def create_post(body: PostIn, user: sqlite3.Row = Depends(_require_user)):
    pid = "post" + uuid.uuid4().hex[:10]
    conn = db()
    conn.execute(
        "INSERT INTO posts (id, author_uid, author, role, avatar_key, category, time, text, has_image) VALUES (?,?,?,?,?,?,?,?,?)",
        (
            pid, user["uid"], user["name"], _role_for(user["user_type"]),
            _avatar_for(user["user_type"]), body.category, utcnow(),
            body.text, 1 if body.hasImage else 0,
        ),
    )
    conn.commit()
    row = conn.execute("SELECT * FROM posts WHERE id = ?", (pid,)).fetchone()
    conn.close()
    return _post_json(row)


@app.post("/api/posts/{pid}/like")
def toggle_like(pid: str, user: sqlite3.Row = Depends(_require_user)):
    conn = db()
    row = conn.execute("SELECT * FROM posts WHERE id = ?", (pid,)).fetchone()
    if row is None:
        conn.close()
        raise HTTPException(status_code=404, detail="المنشور غير موجود")
    existing = conn.execute(
        "SELECT 1 FROM post_likes WHERE post_id = ? AND uid = ?", (pid, user["uid"])
    ).fetchone()
    if existing:
        conn.execute("DELETE FROM post_likes WHERE post_id = ? AND uid = ?", (pid, user["uid"]))
    else:
        conn.execute("INSERT INTO post_likes (post_id, uid) VALUES (?,?)", (pid, user["uid"]))
        if row["author_uid"] != user["uid"]:
            _add_notification(
                conn, row["author_uid"], "like", "إعجاب جديد",
                f"{user['name']} أعجب بمنشورك",
            )
    conn.commit()
    updated = conn.execute("SELECT * FROM posts WHERE id = ?", (pid,)).fetchone()
    conn.close()
    return _post_json(updated, user["uid"])


# ---------------------------------------------------------------- comments

@app.get("/api/comments")
def list_comments(kind: str = "post", targetId: str = ""):
    conn = db()
    rows = conn.execute(
        "SELECT * FROM comments WHERE kind = ? AND target_id = ? AND parent_id IS NULL ORDER BY time DESC",
        (kind, targetId),
    ).fetchall()
    result = [_comment_json(r, conn) for r in rows]
    conn.close()
    return result


@app.post("/api/comments")
def add_comment(body: CommentIn, user: sqlite3.Row = Depends(_require_user)):
    cid = "c" + uuid.uuid4().hex[:12]
    conn = db()
    conn.execute(
        "INSERT INTO comments (id, kind, target_id, author_uid, author, role, avatar_key, text, rating, time) VALUES (?,?,?,?,?,?,?,?,?,?)",
        (
            cid, body.kind, body.targetId, user["uid"], user["name"],
            _role_for(user["user_type"]), _avatar_for(user["user_type"]),
            body.text, body.rating, utcnow(),
        ),
    )
    if body.kind == "post":
        post = conn.execute("SELECT * FROM posts WHERE id = ?", (body.targetId,)).fetchone()
        if post is not None and post["author_uid"] != user["uid"]:
            _add_notification(
                conn, post["author_uid"], "comment", "تعليق جديد",
                f"{user['name']}: {body.text[:60]}",
            )
    conn.commit()
    row = conn.execute("SELECT * FROM comments WHERE id = ?", (cid,)).fetchone()
    result = _comment_json(row, conn)
    conn.close()
    return result


@app.post("/api/comments/{cid}/replies")
def add_reply(cid: str, body: ReplyIn, user: sqlite3.Row = Depends(_require_user)):
    rid = "r" + uuid.uuid4().hex[:12]
    conn = db()
    parent = conn.execute("SELECT * FROM comments WHERE id = ?", (cid,)).fetchone()
    if parent is None:
        conn.close()
        raise HTTPException(status_code=404, detail="التعليق غير موجود")
    conn.execute(
        "INSERT INTO comments (id, kind, target_id, author_uid, author, role, avatar_key, text, rating, time, parent_id) VALUES (?,?,?,?,?,?,?,?,?,?,?)",
        (
            rid, parent["kind"], parent["target_id"], user["uid"], user["name"],
            _role_for(user["user_type"]), _avatar_for(user["user_type"]),
            body.text, 0, utcnow(), cid,
        ),
    )
    if parent["author_uid"] != user["uid"]:
        _add_notification(
            conn, parent["author_uid"], "comment", "رد جديد",
            f"{user['name']} رد عليك: {body.text[:60]}",
        )
    conn.commit()
    row = conn.execute("SELECT * FROM comments WHERE id = ?", (rid,)).fetchone()
    result = _comment_json(row, conn)
    conn.close()
    return result


# ---------------------------------------------------------------- delivery

@app.get("/api/delivery")
def list_delivery(area: str = Query(""), user: sqlite3.Row = Depends(_require_user)):
    conn = db()
    rows = conn.execute(
        "SELECT * FROM users WHERE user_type = 'delivery' AND is_active = 1 ORDER BY COALESCE(delivery_fee, 999) ASC, rating DESC"
    ).fetchall()
    result = []
    for r in rows:
        areas = _load_json(r["delivery_areas"], []) or []
        if area and area not in areas:
            continue
        result.append(
            {
                "uid": r["uid"],
                "name": r["name"],
                "phone": r["phone"],
                "deliveryFee": r["delivery_fee"],
                "deliveryAreas": areas,
                "vehicleType": r["vehicle_type"],
                "rating": r["rating"],
                "ratingCount": r["rating_count"],
            }
        )
    conn.close()
    return result


# ---------------------------------------------------------------- orders

@app.get("/api/orders")
def list_orders(scope: str = "buyer", user: sqlite3.Row = Depends(_require_user)):
    conn = db()
    if scope == "delivery":
        areas = _load_json(user["delivery_areas"], []) or []
        rows = conn.execute(
            "SELECT * FROM orders WHERE status = 'pending' ORDER BY created_at DESC"
        ).fetchall()
        available = [
            o for o in (_order_json(r) for r in rows)
            if o["deliveryPersonId"] == user["uid"]
            or any(a in (o["buyerArea"] or "") for a in areas)
        ]
        mine_rows = conn.execute(
            "SELECT * FROM orders WHERE delivery_person_id = ? AND status IN ('accepted','delivering','delivered') ORDER BY created_at DESC",
            (user["uid"],),
        ).fetchall()
        conn.close()
        return {"available": available, "mine": [_order_json(r) for r in mine_rows]}
    rows = conn.execute(
        "SELECT * FROM orders WHERE buyer_id = ? ORDER BY created_at DESC", (user["uid"],)
    ).fetchall()
    conn.close()
    return [_order_json(r) for r in rows]


@app.post("/api/orders")
def create_order(body: OrderIn, user: sqlite3.Row = Depends(_require_user)):
    oid = "ord" + uuid.uuid4().hex[:10]
    conn = db()
    conn.execute(
        "INSERT INTO orders (id, buyer_id, buyer_name, buyer_phone, buyer_address, buyer_area, delivery_person_id, delivery_person_name, delivery_fee, status, items, subtotal, total, payment_method, payment_status, notes, created_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
        (
            oid, body.buyerId, body.buyerName, body.buyerPhone, body.buyerAddress,
            body.buyerArea, body.deliveryPersonId, body.deliveryPersonName,
            body.deliveryFee, body.status, json.dumps(body.items),
            body.subtotal, body.total, body.paymentMethod, body.paymentStatus,
            body.notes, utcnow(),
        ),
    )
    if body.deliveryPersonId:
        _add_notification(
            conn, body.deliveryPersonId, "order", "طلب جديد",
            f"{body.buyerName} اختارك لتوصيل طلبه ({body.subtotal} شيكل)",
        )
    conn.commit()
    row = conn.execute("SELECT * FROM orders WHERE id = ?", (oid,)).fetchone()
    conn.close()
    return _order_json(row)


@app.patch("/api/orders/{oid}")
def update_order_status(oid: str, body: OrderStatusIn, user: sqlite3.Row = Depends(_require_user)):
    conn = db()
    row = conn.execute("SELECT * FROM orders WHERE id = ?", (oid,)).fetchone()
    if row is None:
        conn.close()
        raise HTTPException(status_code=404, detail="الطلب غير موجود")
    fields = ["status = ?"]
    vals = [body.status]
    if body.deliveryPersonId is not None:
        fields.append("delivery_person_id = ?"); vals.append(body.deliveryPersonId)
    if body.deliveryPersonName is not None:
        fields.append("delivery_person_name = ?"); vals.append(body.deliveryPersonName)
    if body.status == "delivered":
        fields.append("delivered_at = ?"); vals.append(utcnow())
    if body.paymentStatus is not None:
        fields.append("payment_status = ?"); vals.append(body.paymentStatus)
    if body.paymentStatus == "paid":
        fields.append("paid_at = ?"); vals.append(utcnow())
    if body.paymentRef:
        fields.append("payment_ref = ?"); vals.append(body.paymentRef)
    vals.append(oid)
    conn.execute(f"UPDATE orders SET {', '.join(fields)} WHERE id = ?", vals)
    if body.status in ("accepted", "delivering", "delivered"):
        _add_notification(
            conn, row["buyer_id"], "order", "تحديث الطلب",
            f"طلبك {body.status} " + (f"بواسطة {body.deliveryPersonName}" if body.deliveryPersonName else ""),
        )
    if body.status == "pending" and body.deliveryPersonId:
        _add_notification(
            conn, body.deliveryPersonId, "order", "طلب جديد",
            f"طلب جديد من {row['buyer_name']} بانتظارك",
        )
    if body.paymentStatus == "paid":
        _add_notification(
            conn, row["buyer_id"], "payment", "تم استلام الدفع",
            "تم تأكيد دفع طلبك بنجاح، شكراً لك",
        )
    conn.commit()
    updated = conn.execute("SELECT * FROM orders WHERE id = ?", (oid,)).fetchone()
    conn.close()
    return _order_json(updated)


# ---------------------------------------------------------------- payments

class PaymentIn(BaseModel):
    orderId: str
    paymentMethod: str = "card"


def _active_gateway() -> str:
    if GATEWAY:
        return GATEWAY
    if MYFATOORAH_TOKEN:
        return "myfatoorah"
    if PALPAY_MERCHANT:
        return "palpay"
    return ""


def _mark_order_paid(oid: str, ref: str = "") -> dict:
    conn = db()
    row = conn.execute("SELECT * FROM orders WHERE id = ?", (oid,)).fetchone()
    if row is None:
        conn.close()
        return {}
    conn.execute(
        "UPDATE orders SET payment_status = 'paid', paid_at = ?, payment_ref = COALESCE(payment_ref, ?) WHERE id = ?",
        (utcnow(), ref, oid),
    )
    _add_notification(
        conn, row["buyer_id"], "payment", "تم استلام الدفع",
        "تم تأكيد دفع طلبك بنجاح، شكراً لك",
    )
    conn.commit()
    updated = conn.execute("SELECT * FROM orders WHERE id = ?", (oid,)).fetchone()
    conn.close()
    return _order_json(updated)


@app.post("/api/payments/intent")
def payment_intent(body: PaymentIn, user: sqlite3.Row = Depends(_require_user)):
    conn = db()
    row = conn.execute("SELECT * FROM orders WHERE id = ?", (body.orderId,)).fetchone()
    conn.close()
    if row is None or row["buyer_id"] != user["uid"]:
        raise HTTPException(status_code=404, detail="الطلب غير موجود")
    if row["payment_status"] == "paid":
        return {"paid": True, "paymentUrl": None}
    gateway = _active_gateway()
    if not gateway:
        return {
            "paid": False,
            "simulated": True,
            "paymentUrl": None,
            "message": "الدفع الإلكتروني غير مفعّل في هذا الخادم (جرّب وضع المحاكاة)",
        }
    if gateway == "myfatoorah":
        return _myfatoorah_intent(row, user["email"], body.paymentMethod)
    if gateway == "palpay":
        return _palpay_intent(row, user["email"], body.paymentMethod)
    raise HTTPException(status_code=502, detail=f"بوابة غير معروفة: {gateway}")


def _myfatoorah_intent(row, email, method):
    method_id = 0
    if method == "wallet":
        method_id = 2
    payload = {
        "PaymentMethodId": method_id,
        "CustomerName": row["buyer_name"][:100],
        "DisplayCurrencyIso": os.getenv("MYFATOORAH_CURRENCY", "USD"),
        "MobileCountryCode": "+970",
        "CustomerMobile": (row["buyer_phone"] or "000000000")[:15],
        "CustomerEmail": email,
        "InvoiceValue": row["total"],
        "CallBackUrl": MYFATOORAH_CALLBACK or f"https://example.com/pay/callback/{row['id']}",
        "ErrorUrl": MYFATOORAH_ERROR_URL or f"https://example.com/pay/error/{row['id']}",
        "Language": "ar",
        "CustomerReference": row["id"],
        "SessionId": "",
    }
    try:
        resp = requests.post(
            f"{MYFATOORAH_BASE}/v2/ExecutePayment",
            json=payload,
            headers={"Authorization": f"Bearer {MYFATOORAH_TOKEN}"},
            timeout=20,
        )
        data = resp.json()
        if resp.status_code != 200 or data.get("IsSuccess") is not True:
            raise HTTPException(status_code=502, detail=data.get("Message", "فشل إنشاء عملية الدفع"))
        invoice = data["Data"]["InvoiceId"]
        conn = db()
        conn.execute("UPDATE orders SET payment_ref = ? WHERE id = ?", (str(invoice), row["id"]))
        conn.commit()
        conn.close()
        return {"paid": False, "paymentUrl": data["Data"]["InvoiceURL"], "ref": str(invoice)}
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"تعذر الاتصال ببوابة الدفع: {exc}")


def _palpay_intent(row, email, method):
    if not (PALPAY_MERCHANT and PALPAY_USERNAME and PALPAY_PASSWORD):
        raise HTTPException(status_code=503, detail="بيانات تاجر PalPay غير مكتملة")
    raise HTTPException(
        status_code=501,
        detail="مستندات API الخاصة بـ PalPay تُسلَّم مع اتفاقية التاجر — أضِف التكامل هنا بعد استلامها",
    )


@app.post("/api/payments/webhook")
def payment_webhook(body: dict):
    event = (body.get("Event") or "").upper()
    data = body.get("Data") or body.get("data") or {}
    invoice_id = str(data.get("InvoiceId") or data.get("InvoiceID") or "")
    ref = str(data.get("CustomerReference") or "")
    conn = db()
    row = None
    if invoice_id:
        row = conn.execute("SELECT * FROM orders WHERE payment_ref = ?", (invoice_id,)).fetchone()
    if row is None and ref:
        row = conn.execute("SELECT * FROM orders WHERE id = ?", (ref,)).fetchone()
    if row is None:
        conn.close()
        return {"received": True, "ok": False}
    if event in ("SUCCESS", "TRANSACTIONS.UPDATED", "") and data.get("TransactionStatus") in ("SUCCESS", None):
        conn.execute(
            "UPDATE orders SET payment_status = 'paid', paid_at = ?, payment_ref = COALESCE(payment_ref, ?) WHERE id = ?",
            (utcnow(), invoice_id, row["id"]),
        )
        _add_notification(conn, row["buyer_id"], "payment", "تم استلام الدفع", "تم تأكيد دفع طلبك بنجاح، شكراً لك")
        conn.commit()
        conn.close()
        return {"received": True, "ok": True}
    conn.close()
    return {"received": True, "ok": False}


@app.post("/api/payments/simulate/{oid}")
def simulate_payment(oid: str, user: sqlite3.Row = Depends(_require_user)):
    conn = db()
    row = conn.execute("SELECT * FROM orders WHERE id = ?", (oid,)).fetchone()
    conn.close()
    if row is None:
        raise HTTPException(status_code=404, detail="الطلب غير موجود")
    if _active_gateway():
        raise HTTPException(status_code=400, detail="الدفع الإلكتروني مفعّل — لا حاجة للمحاكاة")
    return _mark_order_paid(oid, "sim-" + uuid.uuid4().hex[:8])


# ---------------------------------------------------------------- chat

@app.get("/api/chats")
def list_chats(user: sqlite3.Row = Depends(_require_user)):
    conn = db()
    rows = conn.execute(
        "SELECT CASE WHEN uid_a = ? THEN uid_b ELSE uid_a END AS peer FROM conversations WHERE uid_a = ? OR uid_b = ?",
        (user["uid"], user["uid"], user["uid"]),
    ).fetchall()
    result = []
    for r in rows:
        peer_uid = r["peer"]
        if not peer_uid or peer_uid == user["uid"]:
            continue
        peer = conn.execute("SELECT * FROM users WHERE uid = ?", (peer_uid,)).fetchone()
        if peer is not None:
            result.append(_conversation_json(peer, user["uid"], conn))
    result.sort(key=lambda c: (-c["unread"], c["name"]))
    conn.close()
    return result


@app.get("/api/chats/{peer_uid}")
def get_chat(peer_uid: str, user: sqlite3.Row = Depends(_require_user)):
    conn = db()
    peer = conn.execute("SELECT * FROM users WHERE uid = ?", (peer_uid,)).fetchone()
    if peer is None:
        conn.close()
        raise HTTPException(status_code=404, detail="المستخدم غير موجود")
    result = _conversation_json(peer, user["uid"], conn)
    conn.close()
    return result


@app.post("/api/chats/open")
def open_chat(body: ChatOpenIn, user: sqlite3.Row = Depends(_require_user)):
    conn = db()
    peer = conn.execute("SELECT * FROM users WHERE name = ?", (body.peerName,)).fetchone()
    if peer is None or peer["uid"] == user["uid"]:
        conn.close()
        raise HTTPException(status_code=404, detail="المستخدم غير موجود")
    _open_conversation(conn, user["uid"], peer)
    conn.commit()
    result = _conversation_json(peer, user["uid"], conn)
    conn.close()
    return result


@app.post("/api/chats/{peer_uid}/messages")
def send_message(peer_uid: str, body: MessageIn, user: sqlite3.Row = Depends(_require_user)):
    if peer_uid == user["uid"]:
        raise HTTPException(status_code=400, detail="لا يمكن مراسلة النفس")
    conn = db()
    peer = conn.execute("SELECT * FROM users WHERE uid = ?", (peer_uid,)).fetchone()
    if peer is None:
        conn.close()
        raise HTTPException(status_code=404, detail="المستخدم غير موجود")
    a, b = sorted([user["uid"], peer_uid])
    mid = "m" + uuid.uuid4().hex[:14]
    if user["uid"] == a:
        read_a, read_b = 1, 0
    else:
        read_a, read_b = 0, 1
    conn.execute(
        "INSERT INTO messages (id, uid_a, uid_b, sender_uid, text, img, audio, time, read_a, read_b) VALUES (?,?,?,?,?,?,?,?,?,?)",
        (mid, a, b, user["uid"], body.text, body.img, body.audio, utcnow(), read_a, read_b),
    )
    _add_notification(conn, peer_uid, "message", "رسالة جديدة", f"{user['name']}: {body.text[:60]}")
    conn.commit()
    row = conn.execute("SELECT * FROM messages WHERE id = ?", (mid,)).fetchone()
    conn.close()
    return _message_json(row, user["uid"])


@app.post("/api/chats/{peer_uid}/read")
def mark_chat_read(peer_uid: str, user: sqlite3.Row = Depends(_require_user)):
    conn = db()
    a, b = sorted([user["uid"], peer_uid])
    if user["uid"] == a:
        conn.execute("UPDATE messages SET read_a = 1 WHERE uid_a = ? AND uid_b = ? AND sender_uid = ?", (a, b, b))
    else:
        conn.execute("UPDATE messages SET read_b = 1 WHERE uid_a = ? AND uid_b = ? AND sender_uid = ?", (a, b, a))
    conn.commit()
    conn.close()
    return {"ok": True}


# ---------------------------------------------------------------- notifications

@app.get("/api/notifications")
def list_notifications(user: sqlite3.Row = Depends(_require_user)):
    conn = db()
    rows = conn.execute(
        "SELECT * FROM notifications WHERE uid = ? ORDER BY time DESC", (user["uid"],)
    ).fetchall()
    conn.close()
    return [
        {
            "id": r["id"],
            "iconKey": r["icon_key"],
            "title": r["title"],
            "body": r["body"],
            "time": r["time"],
            "read": bool(r["read"]),
        }
        for r in rows
    ]


@app.post("/api/notifications/read")
def mark_all_read(user: sqlite3.Row = Depends(_require_user)):
    conn = db()
    conn.execute("UPDATE notifications SET read = 1 WHERE uid = ?", (user["uid"],))
    conn.commit()
    conn.close()
    return {"ok": True}


# ---------------------------------------------------------------- favorites

@app.get("/api/favorites")
def list_favorites(user: sqlite3.Row = Depends(_require_user)):
    conn = db()
    rows = conn.execute(
        "SELECT product_id FROM favorites WHERE uid = ?", (user["uid"],)
    ).fetchall()
    conn.close()
    return [{"id": r["product_id"]} for r in rows]


@app.post("/api/favorites/{pid}")
def toggle_favorite(pid: str, user: sqlite3.Row = Depends(_require_user)):
    conn = db()
    existing = conn.execute(
        "SELECT 1 FROM favorites WHERE uid = ? AND product_id = ?", (user["uid"], pid)
    ).fetchone()
    if existing:
        conn.execute("DELETE FROM favorites WHERE uid = ? AND product_id = ?", (user["uid"], pid))
    else:
        conn.execute("INSERT INTO favorites (uid, product_id) VALUES (?,?)", (user["uid"], pid))
    conn.commit()
    conn.close()
    return {"ok": True}


# ---------------------------------------------------------------- media

@app.post("/api/media")
def upload_media(body: MediaIn, user: sqlite3.Row = Depends(_require_user)):
    try:
        raw = body.base64
        if "," in raw:
            header, raw = raw.split(",", 1)
            mime = header.replace("data:", "").split(";")[0]
        else:
            mime = "image/png"
        data = base64.b64decode(raw)
    except Exception:
        raise HTTPException(status_code=400, detail="صورة غير صالحة")
    mid = "m" + uuid.uuid4().hex[:16]
    conn = db()
    conn.execute("INSERT INTO media (id, data, mime) VALUES (?,?,?)", (mid, data, mime))
    conn.commit()
    conn.close()
    return {"url": f"/api/media/{mid}"}


@app.get("/api/media/{mid}")
def get_media(mid: str):
    conn = db()
    row = conn.execute("SELECT * FROM media WHERE id = ?", (mid,)).fetchone()
    conn.close()
    if row is None:
        raise HTTPException(status_code=404)
    return Response(content=bytes(row["data"]), media_type=row["mime"])


# ---------------------------------------------------------------- config

@app.get("/api/config")
def config():
    return {
        "deliveryFee": 7,
        "places": ["البيرة", "رام الله", "الماصيون", "الخليل"],
        "areas": ["البيرة", "رام الله", "الماصيون", "الخليل", "نابلس"],
        "onlinePayment": bool(_active_gateway()),
        "gateway": _active_gateway() or "simulate",
    }


init_db()
_seed()
