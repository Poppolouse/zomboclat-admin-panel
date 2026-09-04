import sqlite3
import json
import sys
import os
import bcrypt
from datetime import datetime

DB_DIR = "/var/lib/zomboclat"
DB_PATH = "/var/lib/zomboclat/zomboclat.db"

def now_str():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")

def get_db():
    os.makedirs(DB_DIR, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    c = conn.cursor()
    c.execute("""CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE COLLATE NOCASE NOT NULL,
        role TEXT NOT NULL DEFAULT 'OPERATOR',
        created_at TEXT NOT NULL,
        password_hash TEXT
    )""")
    c.execute("PRAGMA table_info(users)")
    cols = [r[1] for r in c.fetchall()]
    if "password_hash" not in cols:
        c.execute("ALTER TABLE users ADD COLUMN password_hash TEXT")
    c.execute("""CREATE TABLE IF NOT EXISTS audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        action TEXT NOT NULL,
        details TEXT,
        created_at TEXT NOT NULL
    )""")
    conn.commit()
    return conn

def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt(12, prefix=b"2a")).decode("utf-8")

def verify_password(password: str, password_hash: str) -> bool:
    if not password_hash:
        return False
    try:
        return bcrypt.checkpw(password.encode("utf-8"), password_hash.encode("utf-8"))
    except Exception:
        return False

def auth(username, password=""):
    conn = get_db()
    c = conn.cursor()
    row = c.execute("SELECT * FROM users WHERE username = ? COLLATE NOCASE", (username,)).fetchone()
    if not row:
        conn.close()
        print(json.dumps({"status": "error", "message": "Kullanici veritabaninda kayitli degil."}))
        return
    if not verify_password(password or "", row["password_hash"] or ""):
        c.execute("INSERT INTO audit_logs (username, action, details, created_at) VALUES (?, 'LOGIN_FAILED', 'Incorrect password entered', ?)", (row['username'], now_str()))
        conn.commit()
        conn.close()
        print(json.dumps({"status": "error", "message": "Hatali sifre."}))
        return
    c.execute("INSERT INTO audit_logs (username, action, details, created_at) VALUES (?, 'LOGIN', 'Session Started', ?)", (row['username'], now_str()))
    conn.commit()
    user_dict = dict(row)
    user_dict.pop("password_hash", None)
    conn.close()
    print(json.dumps({"status": "ok", "user": user_dict}))

def add_user(username, role, by_user, password=""):
    username = username.strip()
    if not username:
        print(json.dumps({"status": "error", "message": "Gecersiz kullanici adi."}))
        return
    if not password or not password.strip():
        print(json.dumps({"status": "error", "message": "Sifre zorunludur."}))
        return
    conn = get_db()
    c = conn.cursor()
    try:
        c.execute("INSERT INTO users (username, role, created_at, password_hash) VALUES (?, ?, ?, ?)", (username, role.upper(), now_str(), hash_password(password)))
        c.execute("INSERT INTO audit_logs (username, action, details, created_at) VALUES (?, 'USER_CREATE', ?, ?)", (by_user, f"'{username}' ({role.upper()}) added", now_str()))
        conn.commit()
        print(json.dumps({"status": "ok", "message": "Kullanici basariyla eklendi."}))
    except sqlite3.IntegrityError:
        print(json.dumps({"status": "error", "message": "Bu kullanici adi zaten mevcut."}))
    except Exception as e:
        print(json.dumps({"status": "error", "message": str(e)}))
    conn.close()

def set_user_password(username, password, by_user):
    username = username.strip()
    if not password:
        print(json.dumps({"status": "error", "message": "Sifre bos olamaz."}))
        return
    conn = get_db()
    c = conn.cursor()
    row = c.execute("SELECT id FROM users WHERE username = ? COLLATE NOCASE", (username,)).fetchone()
    if not row:
        conn.close()
        print(json.dumps({"status": "error", "message": "Kullanici bulunamadi."}))
        return
    c.execute("UPDATE users SET password_hash = ? WHERE username = ? COLLATE NOCASE", (hash_password(password), username))
    c.execute("INSERT INTO audit_logs (username, action, details, created_at) VALUES (?, 'USER_PASSWORD_SET', ?, ?)", (by_user, f"'{username}' password updated", now_str()))
    conn.commit()
    conn.close()
    print(json.dumps({"status": "ok", "message": "Sifre guncellendi."}))

def delete_user(username, by_user):
    username = username.strip()
    if username.lower() == "poppolouse":
        print(json.dumps({"status": "error", "message": "Poppolouse ana yonetici hesabi silinemez."}))
        return
    conn = get_db()
    c = conn.cursor()
    row = c.execute("SELECT * FROM users WHERE username = ? COLLATE NOCASE", (username,)).fetchone()
    if not row:
        print(json.dumps({"status": "error", "message": "Kullanici bulunamadi."}))
        conn.close()
        return
    real_username = row['username']
    c.execute("DELETE FROM users WHERE username = ? COLLATE NOCASE", (username,))
    c.execute("INSERT INTO audit_logs (username, action, details, created_at) VALUES (?, 'USER_DELETE', ?, ?)", (by_user, f"'{real_username}' user deleted", now_str()))
    conn.commit()
    print(json.dumps({"status": "ok", "message": "Kullanici silindi."}))
    conn.close()

def list_users():
    conn = get_db()
    c = conn.cursor()
    rows = c.execute("SELECT * FROM users ORDER BY id ASC").fetchall()
    users = []
    for r in rows:
        d = dict(r)
        d.pop("password_hash", None)
        users.append(d)
    print(json.dumps({"status": "ok", "users": users}))
    conn.close()

def list_logs():
    conn = get_db()
    c = conn.cursor()
    logs = [dict(r) for r in c.execute("SELECT * FROM audit_logs ORDER BY id DESC LIMIT 100").fetchall()]
    print(json.dumps({"status": "ok", "logs": logs}))
    conn.close()

def log_action(username, action, details):
    conn = get_db()
    c = conn.cursor()
    c.execute("INSERT INTO audit_logs (username, action, details, created_at) VALUES (?, ?, ?, ?)", (username, action, details, now_str()))
    conn.commit()
    print(json.dumps({"status": "ok"}))
    conn.close()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        list_users()
        sys.exit(0)
    cmd = sys.argv[1]
    if cmd == "auth" and len(sys.argv) >= 4:
        auth(sys.argv[2], sys.argv[3])
    elif cmd == "add" and len(sys.argv) >= 6:
        add_user(sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])
    elif cmd == "passwd" and len(sys.argv) >= 5:
        set_user_password(sys.argv[2], sys.argv[3], sys.argv[4])
    elif cmd == "del" and len(sys.argv) >= 4:
        delete_user(sys.argv[2], sys.argv[3])
    elif cmd == "users":
        list_users()
    elif cmd == "logs":
        list_logs()
    elif cmd == "log" and len(sys.argv) >= 5:
        log_action(sys.argv[2], sys.argv[3], sys.argv[4])
    else:
        list_users()
