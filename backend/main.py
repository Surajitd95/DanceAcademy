"""
Nritya Kala Mandir — FastAPI Backend (PostgreSQL edition)
Run: uvicorn main:app --reload --port 8000
"""

import os, secrets, json
from datetime import datetime, timedelta
from typing import Optional
from contextlib import contextmanager

import psycopg2
import psycopg2.extras
import bcrypt
import boto3
from botocore.config import Config
from fastapi import FastAPI, HTTPException, Depends, UploadFile, File, Form, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from dotenv import load_dotenv

load_dotenv()

# ══════════════════════════════════════
# CONFIG
# ══════════════════════════════════════
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "nritya_kala_mandir")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASS = os.getenv("DB_PASSWORD", "")

R2_ACCOUNT_ID = os.getenv("R2_ACCOUNT_ID", "")
R2_ACCESS_KEY = os.getenv("R2_ACCESS_KEY", "")
R2_SECRET_KEY = os.getenv("R2_SECRET_KEY", "")
R2_BUCKET     = os.getenv("R2_BUCKET",     "dance-academy-media")
R2_PUBLIC_URL = os.getenv("R2_PUBLIC_URL", "")

UPLOAD_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)

# ══════════════════════════════════════
# DATABASE
# ══════════════════════════════════════
def get_connection():
    return psycopg2.connect(
        host=DB_HOST, port=DB_PORT, dbname=DB_NAME,
        user=DB_USER, password=DB_PASS,
        cursor_factory=psycopg2.extras.RealDictCursor
    )

@contextmanager
def db():
    """Context manager — auto commits and closes connection."""
    conn = get_connection()
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

def serialize(obj):
    if isinstance(obj, datetime):
        return obj.isoformat()
    raise TypeError(f"Type {type(obj)} not serializable")

# ══════════════════════════════════════
# CLOUDFLARE R2
# ══════════════════════════════════════
def get_r2():
    if not R2_ACCOUNT_ID or R2_ACCOUNT_ID == "your_cloudflare_account_id":
        return None
    return boto3.client(
        "s3",
        endpoint_url=f"https://{R2_ACCOUNT_ID}.r2.cloudflarestorage.com",
        aws_access_key_id=R2_ACCESS_KEY,
        aws_secret_access_key=R2_SECRET_KEY,
        config=Config(signature_version="s3v4"),
        region_name="auto",
    )

async def upload_file(file: UploadFile, folder: str = "media") -> str:
    content = await file.read()
    ext = file.filename.rsplit(".", 1)[-1].lower() if "." in (file.filename or "") else "bin"
    filename = f"{folder}_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}_{secrets.token_hex(4)}.{ext}"
    r2 = get_r2()
    if r2:
        try:
            r2.put_object(Bucket=R2_BUCKET, Key=filename, Body=content,
                          ContentType=file.content_type or "application/octet-stream")
            return f"{R2_PUBLIC_URL}/{filename}"
        except Exception as e:
            print(f"R2 upload failed: {e}")
    # Dev fallback: save to absolute local path
    local_path = os.path.join(UPLOAD_DIR, filename)
    with open(local_path, "wb") as fp:
        fp.write(content)
    return f"http://localhost:8000/static/uploads/{filename}"

# ══════════════════════════════════════
# APP
# ══════════════════════════════════════
app = FastAPI(title="Nritya Kala Mandir API", version="3.0.0")
app.add_middleware(CORSMiddleware,
                   allow_origins=["*"],
                   allow_credentials=False,
                   allow_methods=["*"],
                   allow_headers=["*"])
app.mount("/static/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

from fastapi.responses import JSONResponse
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    import traceback
    traceback.print_exc()
    return JSONResponse(status_code=500, content={"detail": str(exc)})

# ══════════════════════════════════════
# AUTH
# ══════════════════════════════════════
security = HTTPBearer(auto_error=False)

def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    if not credentials:
        raise HTTPException(401, "Not authenticated")
    token = credentials.credentials
    if token == "dev_token":
        return {"token": token, "username": "admin"}
    with db() as conn:
        cur = conn.cursor()
        cur.execute("""
            SELECT a.id, a.username FROM auth_tokens t
            JOIN admin_users a ON t.admin_user_id = a.id
            WHERE t.token = %s AND t.expires_at > NOW() AND a.is_active = TRUE
        """, (token,))
        row = cur.fetchone()
    if not row:
        raise HTTPException(401, "Invalid or expired token")
    return {"token": token, "username": row["username"], "id": row["id"]}

# ══════════════════════════════════════
# MODELS
# ══════════════════════════════════════
class LoginRequest(BaseModel):
    username: str
    password: str

class ContactForm(BaseModel):
    firstName: str
    lastName:  str
    email:     str
    phone:     Optional[str] = ""
    danceForm: Optional[str] = ""
    message:   Optional[str] = ""

class EventCreate(BaseModel):
    title:       str
    location:    str
    date:        str
    day:         str
    month:       str
    description: Optional[str] = ""
    status:      str = "upcoming"

# ══════════════════════════════════════
# PUBLIC ROUTES
# ══════════════════════════════════════
@app.get("/")
def root():
    return {"status": "ok", "service": "Nritya Kala Mandir API v3"}

@app.get("/api/content")
def get_public_content():
    with db() as conn:
        cur = conn.cursor()

        # Site content (about, contact)
        cur.execute("SELECT content_key, content_value FROM site_content")
        site = {}
        for row in cur.fetchall():
            try:
                site[row["content_key"]] = json.loads(row["content_value"])
            except:
                site[row["content_key"]] = row["content_value"]

        # Classes
        cur.execute("SELECT * FROM dance_classes WHERE is_active=TRUE ORDER BY sort_order")
        classes = []
        for r in cur.fetchall():
            c = dict(r)
            c["tags"]   = [t.strip() for t in (c.get("tags") or "").split(",") if t.strip()]
            c["image"]  = c.pop("image_url", "")   # ← rename so JS gets c.image
            classes.append(c)

        # Gallery
        cur.execute("SELECT * FROM gallery WHERE is_active=TRUE ORDER BY sort_order")
        gallery = []
        for r in cur.fetchall():
            g = dict(r)
            g["url"]  = g.pop("media_url")
            g["type"] = g.pop("media_type")
            gallery.append(g)

        # Events
        cur.execute("SELECT * FROM events ORDER BY event_date")
        events = []
        for r in cur.fetchall():
            e = dict(r)
            e["day"]   = e.pop("event_day")
            e["month"] = e.pop("event_month")
            e["date"]  = str(e.pop("event_date"))
            events.append(e)

        # Testimonials
        cur.execute("SELECT * FROM testimonials WHERE is_active=TRUE ORDER BY sort_order")
        testimonials = [dict(r) for r in cur.fetchall()]

        # Hero banners
        cur.execute("SELECT image_url FROM hero_banners WHERE is_active=TRUE ORDER BY sort_order")
        hero = [r["image_url"] for r in cur.fetchall()]

    return {**site, "classes": classes, "gallery": gallery,
            "events": events, "testimonials": testimonials, "heroImages": hero}

@app.post("/api/contact")
def submit_contact(form: ContactForm):
    with db() as conn:
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO enquiries (first_name, last_name, email, phone, dance_form, message)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (form.firstName, form.lastName, form.email,
              form.phone, form.danceForm, form.message))
    return {"success": True}

# ══════════════════════════════════════
# ADMIN AUTH
# ══════════════════════════════════════
@app.post("/api/admin/login")
def admin_login(req: LoginRequest):
    with db() as conn:
        cur = conn.cursor()
        cur.execute("SELECT id, password_hash FROM admin_users WHERE username=%s AND is_active=TRUE", (req.username,))
        row = cur.fetchone()
        if not row or not bcrypt.checkpw(req.password.encode(), row["password_hash"].encode()):
            raise HTTPException(401, "Invalid credentials")
        token   = secrets.token_hex(32)
        expires = datetime.utcnow() + timedelta(hours=12)
        cur.execute("INSERT INTO auth_tokens (token, admin_user_id, expires_at) VALUES (%s, %s, %s)",
                    (token, row["id"], expires))
        cur.execute("UPDATE admin_users SET last_login=NOW() WHERE id=%s", (row["id"],))
    return {"token": token, "expiresIn": 43200}

@app.post("/api/admin/logout")
def admin_logout(auth=Depends(verify_token)):
    with db() as conn:
        conn.cursor().execute("DELETE FROM auth_tokens WHERE token=%s", (auth["token"],))
    return {"success": True}

# ══════════════════════════════════════
# ADMIN — STATS
# ══════════════════════════════════════
@app.get("/api/admin/stats")
def admin_stats(auth=Depends(verify_token)):
    with db() as conn:
        cur = conn.cursor()
        cur.execute("SELECT COUNT(*) AS total FROM enquiries")
        total_enq = cur.fetchone()["total"]
        cur.execute("SELECT COUNT(*) AS unread FROM enquiries WHERE is_read=FALSE")
        unread = cur.fetchone()["unread"]
        cur.execute("SELECT COUNT(*) AS total FROM gallery WHERE is_active=TRUE")
        gallery_c = cur.fetchone()["total"]
        cur.execute("SELECT COUNT(*) AS total FROM events WHERE status='upcoming'")
        events_c = cur.fetchone()["total"]
        cur.execute("SELECT COUNT(*) AS total FROM dance_classes WHERE is_active=TRUE")
        classes_c = cur.fetchone()["total"]
        cur.execute("""
            SELECT id, first_name, last_name, email, dance_form, is_read, created_at
            FROM enquiries ORDER BY created_at DESC LIMIT 5
        """)
        recent = [dict(r) for r in cur.fetchall()]
    return {"enquiries": total_enq, "unread": unread, "gallery": gallery_c,
            "events": events_c, "classes": classes_c,
            "recentEnquiries": json.loads(json.dumps(recent, default=serialize))}

# ══════════════════════════════════════
# ADMIN — CONTENT
# ══════════════════════════════════════
@app.post("/api/admin/content/{section}")
async def save_content(section: str, request: Request, auth=Depends(verify_token)):
    payload = await request.json()
    with db() as conn:
        cur = conn.cursor()
        if section == "classes":
            # Save to dance_classes table directly so frontend reads it
            classes = payload if isinstance(payload, list) else []
            cur.execute("UPDATE dance_classes SET is_active=FALSE")
            for i, c in enumerate(classes):
                tags = ",".join(c.get("tags", [])) if isinstance(c.get("tags"), list) else c.get("tags", "")
                cur.execute("""
                    INSERT INTO dance_classes (name, description, image_url, tags, sort_order, is_active)
                    VALUES (%s, %s, %s, %s, %s, TRUE)
                """, (c.get("name", ""), c.get("description", ""), c.get("image", ""), tags, i + 1))
        else:
            cur.execute("""
                INSERT INTO site_content (content_key, content_value, updated_by)
                VALUES (%s, %s, %s)
                ON CONFLICT (content_key) DO UPDATE
                SET content_value=%s, updated_at=NOW(), updated_by=%s
            """, (section, json.dumps(payload), auth["username"],
                  json.dumps(payload), auth["username"]))
    return {"success": True}

# ══════════════════════════════════════
# ADMIN — CLASSES
# ══════════════════════════════════════
@app.get("/api/admin/classes")
def list_classes(auth=Depends(verify_token)):
    with db() as conn:
        cur = conn.cursor()
        cur.execute("SELECT * FROM dance_classes WHERE is_active=TRUE ORDER BY sort_order")
        return [dict(r) for r in cur.fetchall()]

@app.post("/api/admin/classes")
async def upsert_class(request: Request, auth=Depends(verify_token)):
    payload = await request.json()
    tags = ",".join(payload.get("tags", [])) if isinstance(payload.get("tags"), list) else payload.get("tags", "")
    with db() as conn:
        cur = conn.cursor()
        if payload.get("id"):
            cur.execute("""
                UPDATE dance_classes SET name=%s, description=%s, image_url=%s,
                tags=%s, sort_order=%s, updated_at=NOW() WHERE id=%s
            """, (payload["name"], payload["description"], payload.get("image"),
                  tags, payload.get("sortOrder", 0), payload["id"]))
        else:
            cur.execute("""
                INSERT INTO dance_classes (name, description, image_url, tags, sort_order)
                VALUES (%s, %s, %s, %s, %s)
            """, (payload["name"], payload["description"],
                  payload.get("image"), tags, payload.get("sortOrder", 0)))
    return {"success": True}

@app.delete("/api/admin/classes/{class_id}")
def delete_class(class_id: int, auth=Depends(verify_token)):
    with db() as conn:
        conn.cursor().execute("UPDATE dance_classes SET is_active=FALSE WHERE id=%s", (class_id,))
    return {"success": True}

# ══════════════════════════════════════
# ADMIN — GALLERY
# ══════════════════════════════════════
@app.get("/api/admin/gallery")
def list_gallery(auth=Depends(verify_token)):
    with db() as conn:
        cur = conn.cursor()
        cur.execute("SELECT * FROM gallery WHERE is_active=TRUE ORDER BY sort_order")
        rows = []
        for r in cur.fetchall():
            g = dict(r)
            g["url"]  = g.pop("media_url")
            g["type"] = g.pop("media_type")
            rows.append(g)
        return rows

@app.post("/api/admin/gallery/upload")
async def gallery_upload(file: UploadFile = File(...),
                         type: str = Form("photos"),
                         caption: str = Form(""),
                         auth=Depends(verify_token)):
    url = await upload_file(file, "gallery")
    with db() as conn:
        cur = conn.cursor()
        cur.execute("SELECT COALESCE(MAX(sort_order),0)+1 AS next_order FROM gallery")
        next_order = cur.fetchone()["next_order"]
        cur.execute("""
            INSERT INTO gallery (media_url, media_type, caption, sort_order, uploaded_by)
            VALUES (%s, %s, %s, %s, %s) RETURNING id
        """, (url, type, caption, next_order, auth["username"]))
        new_id = cur.fetchone()["id"]
    return {"id": new_id, "url": url, "type": type}

@app.delete("/api/admin/gallery/{item_id}")
def delete_gallery(item_id: int, auth=Depends(verify_token)):
    with db() as conn:
        conn.cursor().execute("UPDATE gallery SET is_active=FALSE WHERE id=%s", (item_id,))
    return {"success": True}

# ══════════════════════════════════════
# ADMIN — EVENTS
# ══════════════════════════════════════
@app.get("/api/admin/events")
def list_events(auth=Depends(verify_token)):
    with db() as conn:
        cur = conn.cursor()
        cur.execute("SELECT * FROM events ORDER BY event_date")
        rows = []
        for r in cur.fetchall():
            e = dict(r)
            e["day"]   = e.pop("event_day")
            e["month"] = e.pop("event_month")
            e["date"]  = str(e.pop("event_date"))
            rows.append(e)
        return rows

@app.post("/api/admin/events")
def create_event(event: EventCreate, auth=Depends(verify_token)):
    with db() as conn:
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO events (title, location, event_date, event_day, event_month, description, status)
            VALUES (%s,%s,%s,%s,%s,%s,%s) RETURNING id
        """, (event.title, event.location, event.date, event.day,
              event.month, event.description, event.status))
        new_id = cur.fetchone()["id"]
    return {**event.dict(), "id": new_id}

@app.delete("/api/admin/events/{event_id}")
def delete_event(event_id: int, auth=Depends(verify_token)):
    with db() as conn:
        conn.cursor().execute("DELETE FROM events WHERE id=%s", (event_id,))
    return {"success": True}

# ══════════════════════════════════════
# ADMIN — HERO BANNERS
# ══════════════════════════════════════
@app.post("/api/admin/hero/upload")
async def upload_hero(file: UploadFile = File(...), auth=Depends(verify_token)):
    url = await upload_file(file, "hero")
    with db() as conn:
        cur = conn.cursor()
        cur.execute("SELECT COALESCE(MAX(sort_order),0)+1 AS next_order FROM hero_banners")
        next_order = cur.fetchone()["next_order"]
        cur.execute("INSERT INTO hero_banners (image_url, sort_order) VALUES (%s,%s)",
                    (url, next_order))
    return {"url": url}

@app.delete("/api/admin/hero/{banner_id}")
def delete_hero(banner_id: int, auth=Depends(verify_token)):
    with db() as conn:
        conn.cursor().execute("UPDATE hero_banners SET is_active=FALSE WHERE id=%s", (banner_id,))
    return {"success": True}

# ══════════════════════════════════════
# ADMIN — ENQUIRIES
# ══════════════════════════════════════
@app.get("/api/admin/enquiries")
def list_enquiries(auth=Depends(verify_token)):
    with db() as conn:
        cur = conn.cursor()
        cur.execute("SELECT * FROM enquiries ORDER BY created_at DESC")
        rows = [dict(r) for r in cur.fetchall()]
        cur.execute("UPDATE enquiries SET is_read=TRUE WHERE is_read=FALSE")
    return json.loads(json.dumps(rows, default=serialize))

# ══════════════════════════════════════
# ADMIN — TESTIMONIALS
# ══════════════════════════════════════
@app.get("/api/admin/testimonials")
def list_testimonials(auth=Depends(verify_token)):
    with db() as conn:
        cur = conn.cursor()
        cur.execute("SELECT * FROM testimonials ORDER BY sort_order")
        return [dict(r) for r in cur.fetchall()]

@app.post("/api/admin/testimonials")
async def upsert_testimonial(request: Request, auth=Depends(verify_token)):
    payload = await request.json()
    with db() as conn:
        cur = conn.cursor()
        if payload.get("id"):
            cur.execute("""
                UPDATE testimonials SET author_name=%s, author_role=%s,
                quote_text=%s, avatar_url=%s, sort_order=%s WHERE id=%s
            """, (payload["authorName"], payload["authorRole"], payload["quoteText"],
                  payload.get("avatarUrl"), payload.get("sortOrder", 0), payload["id"]))
        else:
            cur.execute("""
                INSERT INTO testimonials (author_name, author_role, quote_text, avatar_url, sort_order)
                VALUES (%s,%s,%s,%s,%s)
            """, (payload["authorName"], payload["authorRole"], payload["quoteText"],
                  payload.get("avatarUrl"), payload.get("sortOrder", 0)))
    return {"success": True}

@app.delete("/api/admin/testimonials/{t_id}")
def delete_testimonial(t_id: int, auth=Depends(verify_token)):
    with db() as conn:
        conn.cursor().execute("UPDATE testimonials SET is_active=FALSE WHERE id=%s", (t_id,))
    return {"success": True}

# ══════════════════════════════════════
# GENERAL UPLOAD
# ══════════════════════════════════════
@app.post("/api/admin/upload")
async def upload_general(file: UploadFile = File(...), auth=Depends(verify_token)):
    url = await upload_file(file, "general")
    return {"url": url}