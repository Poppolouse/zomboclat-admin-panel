import os
import sys
import json
import time
import sqlite3
import subprocess
import base64
import secrets
import threading
import re
from contextvars import ContextVar
from datetime import datetime
from typing import Optional, Dict, Any, List, Sequence
from fastapi import FastAPI, HTTPException, Header, Query, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import uvicorn

sys.path.insert(0, "/var/lib/zomboclat")

import db
import config_manager
import player_manager

app = FastAPI(
    title="Zomboclat Admin Panel API",
    version="1.0.15",
    docs_url=None,
    redoc_url=None,
    openapi_url=None,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[],
    allow_credentials=False,
    allow_methods=[],
    allow_headers=[],
)

SESSION_TTL_SECONDS = 12 * 60 * 60
MAX_REQUEST_BYTES = 256 * 1024
_sessions: Dict[str, Dict[str, Any]] = {}
_login_attempts: Dict[str, List[float]] = {}
_security_lock = threading.Lock()
_actor: ContextVar[Optional[Dict[str, Any]]] = ContextVar("actor", default=None)


def run_cmd(cmd: Sequence[str], timeout: int = 10) -> str:
    if isinstance(cmd, (str, bytes)):
        raise TypeError("Commands must be passed as an argument list")
    res = subprocess.run(list(cmd), shell=False, capture_output=True, text=True, timeout=timeout)
    return res.stdout


def current_actor() -> Dict[str, Any]:
    actor = _actor.get()
    if not actor:
        raise HTTPException(status_code=401, detail="Authentication required.")
    return actor


def require_admin() -> Dict[str, Any]:
    actor = current_actor()
    if (actor.get("role") or "").upper() != "ADMIN":
        raise HTTPException(status_code=403, detail="Administrator permission required.")
    return actor


def _issue_session(user: Dict[str, Any]) -> str:
    token = secrets.token_urlsafe(48)
    now = time.time()
    with _security_lock:
        _sessions[token] = {
            "id": user["id"],
            "username": user["username"],
            "role": (user.get("role") or "OPERATOR").upper(),
            "expires": now + SESSION_TTL_SECONDS,
        }
    return token


def _session_from_request(request: Request) -> Optional[Dict[str, Any]]:
    authorization = request.headers.get("authorization", "")
    if not authorization.startswith("Bearer "):
        return None
    token = authorization[7:].strip()
    now = time.time()
    with _security_lock:
        session = _sessions.get(token)
        if not session or session["expires"] <= now:
            _sessions.pop(token, None)
            return None
        session["expires"] = now + SESSION_TTL_SECONDS
        return dict(session)


def _login_allowed(client_key: str) -> bool:
    now = time.time()
    with _security_lock:
        attempts = [t for t in _login_attempts.get(client_key, []) if now - t < 300]
        if len(attempts) >= 10:
            _login_attempts[client_key] = attempts
            return False
        attempts.append(now)
        _login_attempts[client_key] = attempts
        return True


def _clear_login_attempts(client_key: str) -> None:
    with _security_lock:
        _login_attempts.pop(client_key, None)


def _revoke_user_sessions(username: str) -> None:
    with _security_lock:
        for token, session in list(_sessions.items()):
            if session["username"].lower() == username.lower():
                _sessions.pop(token, None)


def _validate_name(value: str, field: str, max_length: int = 64) -> str:
    value = value.strip()
    if not value or len(value) > max_length or not re.fullmatch(r"[A-Za-z0-9_.@ -]+", value):
        raise HTTPException(status_code=422, detail=f"Invalid {field}.")
    return value


def _validate_ini_payload(settings: Dict[str, Any], mods: List[str], workshop_items: List[str]) -> None:
    if len(settings) > 500 or len(mods) > 500 or len(workshop_items) > 500:
        raise HTTPException(status_code=422, detail="Too many settings or mods.")
    for key, value in settings.items():
        if not re.fullmatch(r"[A-Za-z][A-Za-z0-9_.]{0,99}", str(key)):
            raise HTTPException(status_code=422, detail="Invalid setting name.")
        if len(str(value)) > 4096 or "\n" in str(value) or "\r" in str(value):
            raise HTTPException(status_code=422, detail="Invalid setting value.")
    for value in [*mods, *workshop_items]:
        if not re.fullmatch(r"[A-Za-z0-9_.-]{1,128}", str(value)):
            raise HTTPException(status_code=422, detail="Invalid mod identifier.")


@app.middleware("http")
async def security_middleware(request: Request, call_next):
    if int(request.headers.get("content-length", "0") or 0) > MAX_REQUEST_BYTES:
        return JSONResponse(status_code=413, content={"detail": "Request body too large."})
    path = request.url.path
    if path == "/api/auth/login":
        client_key = request.headers.get("x-real-ip") or (request.client.host if request.client else "unknown")
        if not _login_allowed(client_key):
            return JSONResponse(status_code=429, content={"detail": "Too many login attempts."})
        request.state.login_client_key = client_key
        return await call_next(request)
    if path.startswith("/api/"):
        actor = _session_from_request(request)
        if not actor:
            return JSONResponse(status_code=401, content={"detail": "Authentication required."})
        marker = _actor.set(actor)
        try:
            return await call_next(request)
        finally:
            _actor.reset(marker)
    return await call_next(request)

class LoginRequest(BaseModel):
    username: str
    password: str = ""

class ServerCommandRequest(BaseModel):
    action: str
    username: str

class UserAddRequest(BaseModel):
    username: str
    role: str
    by_user: str
    password: str = ""

class UserDeleteRequest(BaseModel):
    username: str
    by_user: str

class UserPasswordRequest(BaseModel):
    username: str
    new_password: str
    by_user: str
    old_password: str = ""

class AuditLogRequest(BaseModel):
    username: str
    action: str
    details: str

class PlayerBanRequest(BaseModel):
    username: str
    steamid: Optional[str] = ""
    reason: Optional[str] = "Admin panel yasagi"
    by_user: str

class PlayerUnbanRequest(BaseModel):
    username: str
    steamid: Optional[str] = ""
    by_user: str

class PlayerAddRequest(BaseModel):
    username: str
    password: Optional[str] = ""
    role_id: Optional[int] = 2
    by_user: str

class PlayerDeleteRequest(BaseModel):
    username: str
    by_user: str

class PlayerUpdateRequest(BaseModel):
    username: str
    payload: Dict[str, Any]
    by_user: str

class RconRequest(BaseModel):
    command: str
    by_user: Optional[str] = ""

class IniSaveRequest(BaseModel):
    settings: Dict[str, Any]
    mods: List[str]
    workshop_items: List[str]
    username: str

class SandboxSaveRequest(BaseModel):
    categories: Dict[str, Any]
    username: str

WORKSHOP_CONTENT_PATH = "/home/pzserver/pzserver/steamapps/workshop/content/108600"
CATALOG_PATH = "/var/lib/zomboclat/items_catalog.json"
WORKSHOP_CACHE_PATH = "/var/lib/zomboclat/workshop_cache.json"

# ---- Mod ikon cozumleme -----------------------------------------------------
# items_catalog'daki "mod_name" degeri, gercek workshop klasorune eslestirilir.
# Eslestirme workshop_cache.json basliklari + mod.info id/klasor adlari ile yapilir.
# Sonuc bir JSON dosyasinda onbelleklenir; mod kurulumu degisince gecersiz kilinir.

_MOD_MAP_PATH = "/var/lib/zomboclat/mod_name_map.json"
_icon_index_cache: Optional[Dict[str, str]] = None
_icon_index_built_at: float = 0.0
ICON_INDEX_TTL = 900  # saniye; yeni mod kurulumlarini yakalamak icin


def _safe_resolve_mod_icon(workshop_id: str, rel_path: str) -> Optional[str]:
    """Workshop ikon yolunu dogrular; path traversal engellenir."""
    try:
        wid = str(int(str(workshop_id).strip()))
    except Exception:
        return None
    rel = str(rel_path).strip().lstrip("/")
    if not rel or ".." in rel or rel.startswith("/"):
        return None
    full = os.path.join(WORKSHOP_CONTENT_PATH, wid, rel)
    base = os.path.realpath(WORKSHOP_CONTENT_PATH)
    real = os.path.realpath(full)
    if not real.startswith(base + os.sep):
        return None
    if not os.path.isfile(real):
        return None
    return real


def _norm_key(s: Any) -> str:
    return "".join(ch for ch in str(s or "").lower() if ch.isalnum())


def _load_catalog_names() -> list:
    try:
        with open(CATALOG_PATH, "r", encoding="utf-8") as f:
            cat = json.load(f)
        return sorted({(it.get("mod_name") or "") for it in cat if it.get("is_mod") and it.get("icon_file")})
    except Exception:
        return []


def _build_mod_name_map() -> Dict[str, str]:
    """mod_name -> workshop_id haritasi. Baslik eslesmesi + mod.info taramasi."""
    title_map: Dict[str, str] = {}
    try:
        with open(WORKSHOP_CACHE_PATH, "r", encoding="utf-8") as f:
            cache = json.load(f)
        for wid, info in cache.items():
            title_map[_norm_key(info.get("title", ""))] = str(wid)
    except Exception:
        pass

    info_ids: Dict[str, str] = {}
    try:
        for wid in os.listdir(WORKSHOP_CONTENT_PATH):
            wdir = os.path.join(WORKSHOP_CONTENT_PATH, wid)
            if not os.path.isdir(wdir):
                continue
            for root, _dirs, files in os.walk(wdir):
                if "mod.info" in files:
                    try:
                        with open(os.path.join(root, "mod.info"), "r", encoding="utf-8", errors="ignore") as f:
                            content = f.read(4096)
                    except Exception:
                        continue
                    modid = None
                    for line in content.split("\n"):
                        if line.strip().startswith("id="):
                            modid = line.split("=", 1)[1].strip()
                            break
                    if modid:
                        info_ids.setdefault(_norm_key(modid), wid)
                        info_ids.setdefault(_norm_key(os.path.basename(root)), wid)
    except Exception:
        pass

    mapping: Dict[str, str] = {}
    for name in _load_catalog_names():
        key = _norm_key(name)
        wid = title_map.get(key) or info_ids.get(key)
        if not wid:
            for tnorm, twid in title_map.items():
                if key and key in tnorm:
                    wid = twid
                    break
        if not wid:
            for tnorm, twid in title_map.items():
                if tnorm and tnorm in key:
                    wid = twid
                    break
        if wid:
            mapping[name] = wid
    return mapping


def _get_mod_name_map(force: bool = False) -> Dict[str, str]:
    """Haritayi dosyadan okur; yoksa/tTL dolmissa yeniden insa eder."""
    now = time.time()
    if not force and os.path.exists(_MOD_MAP_PATH):
        try:
            if now - os.path.getmtime(_MOD_MAP_PATH) < 86400:
                with open(_MOD_MAP_PATH, "r", encoding="utf-8") as f:
                    return json.load(f)
        except Exception:
            pass
    mapping = _build_mod_name_map()
    try:
        with open(_MOD_MAP_PATH, "w", encoding="utf-8") as f:
            json.dump(mapping, f)
    except Exception:
        pass
    return mapping


def _get_icon_index() -> Dict[str, str]:
    """Tum workshop png dosyalari: ad -> goreceli yol (global fallback icin)."""
    global _icon_index_cache, _icon_index_built_at
    now = time.time()
    if _icon_index_cache is not None and now - _icon_index_built_at < ICON_INDEX_TTL:
        return _icon_index_cache
    idx: Dict[str, str] = {}
    try:
        for wid in os.listdir(WORKSHOP_CONTENT_PATH):
            wdir = os.path.join(WORKSHOP_CONTENT_PATH, wid)
            if not os.path.isdir(wdir):
                continue
            for root, _dirs, files in os.walk(wdir):
                for fn in files:
                    if fn.endswith(".png") and fn not in idx:
                        idx[fn] = f"{wid}/{os.path.relpath(os.path.join(root, fn), wdir).replace(os.sep, '/')}"
    except Exception:
        pass
    _icon_index_cache = idx
    _icon_index_built_at = now
    return idx


def _find_in_workshop(wid: str, filename: str) -> Optional[str]:
    wdir = os.path.join(WORKSHOP_CONTENT_PATH, wid)
    if not os.path.isdir(wdir):
        return None
    try:
        for root, _dirs, files in os.walk(wdir):
            if filename in files:
                return f"{wid}/{os.path.relpath(os.path.join(root, filename), wdir).replace(os.sep, '/')}"
    except Exception:
        pass
    return None


def _resolve_mod_icon_rel(mod_name: str, icon_file: str, item_id: str) -> Optional[str]:
    """Sirasiyla: dogru modda icon_file -> global icon_file -> dogru modda Item_<raw>/<raw> -> global."""
    raw = str(item_id or "").split(".")[-1]
    candidates = [c for c in (icon_file, f"Item_{raw}.png", f"{raw}.png") if c]
    mapping = _get_mod_name_map()
    wid = mapping.get(mod_name or "")
    if wid:
        for c in candidates:
            hit = _find_in_workshop(wid, c)
            if hit:
                return hit
    idx = _get_icon_index()
    for c in candidates:
        if c in idx:
            return idx[c]
    for c in candidates:
        for k, v in idx.items():
            if k.lower() == c.lower():
                return v
    return None


@app.get("/api/mods/icon")
def get_mod_icon(
    workshop_id: Optional[str] = Query(None),
    path: Optional[str] = Query(None),
    mod_name: Optional[str] = Query(None),
    icon_file: Optional[str] = Query(None),
    item_id: Optional[str] = Query(None),
):
    """Mod ikonunu workshop klasorunden servis eder.

    Iki kullanim:
      1) workshop_id + path  -> dogrudan dosya (path traversal korumali)
      2) mod_name + icon_file (+ item_id) -> otomatik cozumleme
    """
    from fastapi.responses import FileResponse
    rel: Optional[str] = None
    if workshop_id and path:
        resolved = _safe_resolve_mod_icon(workshop_id, path)
        if not resolved:
            raise HTTPException(status_code=404, detail="Icon not found")
        return FileResponse(resolved, media_type="image/png")
    if mod_name:
        rel = _resolve_mod_icon_rel(mod_name, icon_file or "", item_id or "")
    elif icon_file:
        idx = _get_icon_index()
        rel = idx.get(icon_file)
        if not rel:
            for k, v in idx.items():
                if k.lower() == icon_file.lower():
                    rel = v
                    break
    if not rel:
        raise HTTPException(status_code=404, detail="Icon not found")
    resolved = _safe_resolve_mod_icon(rel.split("/", 1)[0], rel.split("/", 1)[1])
    if not resolved:
        raise HTTPException(status_code=404, detail="Icon not found")
    return FileResponse(resolved, media_type="image/png")

@app.get("/api/items/icon")
def get_item_icon(
    icon: Optional[str] = Query(None),
    item_id: Optional[str] = Query(None),
):
    """Vanilla + mod item ikonunu ismiyle servis eder.
    Sirasiyla: /var/lib/zomboclat/vanilla_icons/<icon>.png
              -> vanilla_icons icin buyuk-kucuk harf duyarsiz eslesme
              -> /api/mods/icon global fallback (workshop)
    icon parametresi item_icons.json'daki script 'Icon' degeridir (png'siz).
    """
    from fastapi.responses import FileResponse
    if not icon:
        raise HTTPException(status_code=400, detail="icon required")
    name = icon.strip()
    if not name.lower().endswith(".png"):
        name += ".png"
    # path traversal korumasi
    if "/" in name or "..\\" in name or ".." in name:
        raise HTTPException(status_code=400, detail="bad icon name")
    base = "/var/lib/zomboclat/vanilla_icons"
    candidates = [name, "Item_" + name]
    for cand in candidates:
        direct = os.path.join(base, cand)
        if os.path.isfile(direct):
            return FileResponse(direct, media_type="image/png")
    # case-insensitive fallback
    lows = [c.lower() for c in candidates]
    try:
        for fn in os.listdir(base):
            if fn.lower() in lows:
                return FileResponse(os.path.join(base, fn), media_type="image/png")
    except Exception:
        pass
    # workshop fallback (mod ikonlari)
    idx = _get_icon_index()
    rel = idx.get(name)
    if not rel:
        for k, v in idx.items():
            if k.lower() == name.lower():
                rel = v
                break
    if rel and "/" in rel:
        resolved = _safe_resolve_mod_icon(rel.split("/", 1)[0], rel.split("/", 1)[1])
        if resolved:
            return FileResponse(resolved, media_type="image/png")
    raise HTTPException(status_code=404, detail="Icon not found")

@app.get("/api/mods/rehash-icons")
def rehash_mod_icons():
    require_admin()
    """mod_name->workshop_id haritasini yeniden insa eder (mod kurulumu sonrasi)."""
    mapping = _get_mod_name_map(force=True)
    return {"status": "ok", "mapped": len(mapping)}

# -----------------------------------------------------------------------------

@app.get("/health")
def health():
    return {"status": "ok", "version": "1.0.15", "time": datetime.now().isoformat()}

@app.post("/api/auth/login")
def auth_login(req: LoginRequest, request: Request):
    uname = req.username.strip()
    if not uname or len(uname) > 64:
        return {"status": "error", "message": "Username cannot be empty."}
    if not req.password or len(req.password) > 128:
        return {"status": "error", "message": "Password is required."}
    conn = db.get_db()
    c = conn.cursor()
    row = c.execute("SELECT * FROM users WHERE username = ? COLLATE NOCASE", (uname,)).fetchone()
    if row:
        user_dict = dict(row)
        if not db.verify_password(req.password, user_dict.get("password_hash") or ""):
            c.execute("INSERT INTO audit_logs (username, action, details, created_at) VALUES (?, 'LOGIN_FAILED', 'Incorrect password entered', ?)", (user_dict['username'], db.now_str()))
            conn.commit()
            conn.close()
            return {"status": "error", "message": "Incorrect password."}
        c.execute("INSERT INTO audit_logs (username, action, details, created_at) VALUES (?, 'LOGIN', 'Session Started', ?)", (user_dict['username'], db.now_str()))
        conn.commit()
        conn.close()
        user_dict.pop("password_hash", None)
        _clear_login_attempts(request.state.login_client_key)
        return {"status": "ok", "user": user_dict, "token": _issue_session(user_dict)}
    else:
        conn.close()
        return {"status": "error", "message": "User not registered in database. Please ask the administrator (Poppolouse) to add you."}

@app.get("/api/server/status")
def server_status():
    # Accurate host-wide metrics straight from /proc (matches hosting panel graphs).
    def read_cpu():
        with open("/proc/stat") as f:
            for line in f:
                if line.startswith("cpu "):
                    return list(map(int, line.split()[1:]))
        return [0] * 10

    p1 = read_cpu()
    time.sleep(0.8)
    p2 = read_cpu()
    d = [b - a for a, b in zip(p1, p2)]
    total = sum(d)
    idle = d[3] + d[4]
    busy = 100.0 * (1 - idle / total) if total > 0 else 0.0
    busy = max(0.0, min(100.0, busy))
    idle_pct = 100.0 - busy

    mi = {}
    with open("/proc/meminfo") as f:
        for line in f:
            k, v = line.split(":")
            mi[k] = int(v.split()[0])
    total_b = mi["MemTotal"] * 1024
    free_b = mi["MemFree"] * 1024
    avail_b = mi["MemAvailable"] * 1024
    buffers_b = mi.get("Buffers", 0) * 1024
    cached_b = (mi.get("Cached", 0) + mi.get("SReclaimable", 0) - mi.get("Shmem", 0)) * 1024
    # hosting-panel style "used": everything not free (incl. page cache & tmpfs)
    used_b = total_b - free_b
    if used_b < 0:
        used_b = 0

    uptime_out = run_cmd(["uptime", "-p"], timeout=3).strip()
    service_out = run_cmd(["systemctl", "is-active", "pzserver"], timeout=3).strip()
    service_state = service_out.strip() if service_out.strip() in ("active", "inactive") else "active"

    raw = (
        f"%Cpu(s):  {busy:.1f} us,  0.0 sy,  0.0 ni, {idle_pct:.1f} id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st\n"
        f"               total        used        free      shared  buff/cache   available\n"
        f"Mem:     {total_b}  {used_b}  {free_b}  {mi.get('Shmem', 0) * 1024}  {buffers_b + cached_b}  {avail_b}\n"
        f"{uptime_out}\n"
        f"{service_state}"
    )
    return {"status": "ok", "raw": raw}

@app.get("/api/server/logs")
def server_logs(lines: int = 250):
    lines = max(1, min(lines, 1000))
    output = run_cmd(["journalctl", "-u", "pzserver", "-n", str(lines), "--no-pager"], timeout=15)
    log_lines = [l for l in output.split('\n') if l.strip()]
    return {"status": "ok", "lines": log_lines}

@app.post("/api/server/command")
def server_command(req: ServerCommandRequest):
    actor = current_actor()
    action = req.action.lower().strip()
    if action not in ("restart", "start", "stop"):
        raise HTTPException(status_code=400, detail="Gecersiz eylem.")
    
    user_role = (actor['role'] or '').upper()
    is_admin = user_role == 'ADMIN'
    can_restart = is_admin or user_role == 'OPERATOR'

    if action == 'restart' and not can_restart:
        raise HTTPException(status_code=403, detail="Yetersiz yetki (Restart icin Operator veya Admin gereklidir).")
    elif action in ('start', 'stop') and not is_admin:
        raise HTTPException(status_code=403, detail="Yetersiz yetki (Start/Stop icin Admin gereklidir).")

    res = subprocess.run(["systemctl", action, "pzserver"], capture_output=True, text=True)
    if res.returncode != 0:
        return {"status": "error", "message": res.stderr.strip() or f"systemctl {action} pzserver failed"}
    
    db.log_action(actor['username'], f"SERVER_{action.upper()}", f"pzserver.service {action} executed")
    return {"status": "ok", "message": f"pzserver.service {action} executed successfully"}

@app.get("/api/server/ini")
def get_ini_config():
    require_admin()
    res_str = run_cmd(["python3", "/var/lib/zomboclat/config_manager.py", "get_ini"])
    try:
        result = json.loads(res_str)
        for key in list(result.get("settings", {})):
            if any(part in key.lower() for part in ("password", "secret", "token", "apikey", "api_key")):
                result["settings"].pop(key, None)
        return result
    except Exception as e:
        return {"status": "error", "message": str(e), "raw": res_str}

@app.post("/api/server/ini")
def save_ini_config(req: IniSaveRequest):
    actor = require_admin()
    _validate_ini_payload(req.settings, req.mods, req.workshop_items)
    payload = {
        "settings": req.settings,
        "mods": req.mods,
        "workshop_items": req.workshop_items
    }
    payload_str = json.dumps(payload)
    b64 = base64.b64encode(payload_str.encode("utf-8")).decode("utf-8")
    res_str = run_cmd(["python3", "/var/lib/zomboclat/config_manager.py", "save_ini_b64", b64])
    db.log_action(actor["username"], "INI_UPDATE", "pzserver.ini and mod settings updated")
    try:
        return json.loads(res_str)
    except Exception:
        return {"status": "ok", "message": "Saved"}

@app.get("/api/server/sandbox")
def get_sandbox_config():
    require_admin()
    res_str = run_cmd(["python3", "/var/lib/zomboclat/config_manager.py", "get_sandbox"])
    try:
        return json.loads(res_str)
    except Exception as e:
        return {"status": "error", "message": str(e), "raw": res_str}

@app.post("/api/server/sandbox")
def save_sandbox_config(req: SandboxSaveRequest):
    actor = require_admin()
    payload = {"categories": req.categories}
    payload_str = json.dumps(payload)
    b64 = base64.b64encode(payload_str.encode("utf-8")).decode("utf-8")
    res_str = run_cmd(["python3", "/var/lib/zomboclat/config_manager.py", "save_sandbox_b64", b64])
    db.log_action(actor["username"], "SANDBOX_UPDATE", "pzserver_SandboxVars.lua settings updated")
    try:
        return json.loads(res_str)
    except Exception:
        return {"status": "ok", "message": "Saved"}

@app.get("/api/players")
def get_players():
    res_str = run_cmd(["python3", "/var/lib/zomboclat/player_manager.py", "list"], timeout=15)
    try:
        return json.loads(res_str)
    except Exception as e:
        return {"status": "error", "message": str(e), "raw": res_str}

@app.post("/api/players/ban")
def ban_player(req: PlayerBanRequest):
    actor = require_admin()
    res_str = run_cmd(["python3", "/var/lib/zomboclat/player_manager.py", "ban", req.steamid or "", req.username, req.reason or "Admin panel yasagi"])
    db.log_action(actor["username"], "PLAYER_BAN", f"Player {req.username} banned")
    return {"status": "ok", "message": "Player banned"}

@app.post("/api/players/unban")
def unban_player(req: PlayerUnbanRequest):
    actor = require_admin()
    res_str = run_cmd(["python3", "/var/lib/zomboclat/player_manager.py", "unban", req.steamid or "", req.username])
    db.log_action(actor["username"], "PLAYER_UNBAN", f"Player {req.username} unbanned")
    return {"status": "ok", "message": "Player unbanned"}

@app.post("/api/players/add")
def add_game_player(req: PlayerAddRequest):
    actor = require_admin()
    res_str = run_cmd(["python3", "/var/lib/zomboclat/player_manager.py", "add", req.username, req.password or "", str(req.role_id or 2)])
    db.log_action(actor["username"], "PLAYER_ADD", f"Player {req.username} added to whitelist")
    try:
        return json.loads(res_str)
    except Exception:
        return {"status": "ok", "message": "Player added"}

@app.post("/api/players/delete")
def delete_game_player(req: PlayerDeleteRequest):
    actor = require_admin()
    res_str = run_cmd(["python3", "/var/lib/zomboclat/player_manager.py", "del", req.username])
    db.log_action(actor["username"], "PLAYER_DELETE", f"Player {req.username} removed from whitelist")
    try:
        return json.loads(res_str)
    except Exception:
        return {"status": "ok", "message": "Player deleted"}

@app.post("/api/players/update")
def update_game_player(req: PlayerUpdateRequest):
    actor = require_admin()
    payload_str = json.dumps(req.payload)
    b64 = base64.b64encode(payload_str.encode("utf-8")).decode("utf-8")
    res_str = run_cmd(["python3", "/var/lib/zomboclat/player_manager.py", "update_full_b64", req.username, b64], timeout=15)
    char_name = req.payload.get("char_name", "")
    db.log_action(actor["username"], "PLAYER_UPDATE", f"Player {req.username} ({char_name}) updated from Studio")
    try:
        return json.loads(res_str)
    except Exception:
        return {"status": "ok", "message": "Player updated"}

@app.post("/api/players/rcon")
def send_rcon_cmd(req: RconRequest):
    actor = require_admin()
    res = player_manager.send_rcon(req.command)
    db.log_action(actor["username"], "RCON_COMMAND", "Authorized RCON command executed")
    return res

@app.get("/api/users")
def get_panel_users():
    require_admin()
    conn = db.get_db()
    c = conn.cursor()
    rows = c.execute("SELECT * FROM users ORDER BY id ASC").fetchall()
    users = []
    for r in rows:
        d = dict(r)
        d.pop("password_hash", None)
        users.append(d)
    conn.close()
    return {"status": "ok", "users": users}

@app.post("/api/users/add")
def add_panel_user(req: UserAddRequest):
    actor = require_admin()
    conn = db.get_db()
    c = conn.cursor()
    try:
        if actor['id'] != 1:
            return {"status": "error", "message": "Only the root administrator (id 1) can add panel users."}
        uname = _validate_name(req.username, "username")
        if not req.password or not req.password.strip():
            return {"status": "error", "message": "Password is required."}
        if len(req.password) < 10 or len(req.password) > 128:
            return {"status": "error", "message": "Password must be 10-128 characters."}
        if req.role.upper() not in ("ADMIN", "OPERATOR"):
            return {"status": "error", "message": "Invalid role."}
        try:
            c.execute("INSERT INTO users (username, role, created_at, password_hash) VALUES (?, ?, ?, ?)", (uname, req.role.upper(), db.now_str(), db.hash_password(req.password)))
        except sqlite3.IntegrityError:
            return {"status": "error", "message": "This username already exists."}
        c.execute("INSERT INTO audit_logs (username, action, details, created_at) VALUES (?, 'USER_CREATE', ?, ?)", (actor['username'], f"'{uname}' ({req.role.upper()}) added", db.now_str()))
        conn.commit()
        return {"status": "ok", "message": "User added successfully."}
    except Exception as e:
        return {"status": "error", "message": str(e)}
    finally:
        conn.close()

@app.post("/api/users/delete")
def delete_panel_user(req: UserDeleteRequest):
    actor = require_admin()
    conn = db.get_db()
    c = conn.cursor()
    try:
        if actor['id'] != 1:
            return {"status": "error", "message": "Only the root administrator (id 1) can delete panel users."}
        uname = req.username.strip()
        target = c.execute("SELECT * FROM users WHERE username = ? COLLATE NOCASE", (uname,)).fetchone()
        if not target:
            return {"status": "error", "message": "User not found."}
        if target['id'] == 1:
            return {"status": "error", "message": "The root administrator account (id 1) cannot be deleted."}
        real_username = target['username']
        c.execute("DELETE FROM users WHERE username = ? COLLATE NOCASE", (uname,))
        c.execute("INSERT INTO audit_logs (username, action, details, created_at) VALUES (?, 'USER_DELETE', ?, ?)", (actor['username'], f"'{real_username}' user deleted", db.now_str()))
        conn.commit()
        _revoke_user_sessions(real_username)
        return {"status": "ok", "message": "User deleted."}
    except Exception as e:
        return {"status": "error", "message": str(e)}
    finally:
        conn.close()

@app.post("/api/users/password")
def change_panel_user_password(req: UserPasswordRequest):
    actor = current_actor()
    conn = db.get_db()
    c = conn.cursor()
    try:
        is_root = actor['id'] == 1
        target = c.execute("SELECT * FROM users WHERE username = ? COLLATE NOCASE", (req.username.strip(),)).fetchone()
        if not target:
            return {"status": "error", "message": "User not found."}
        if not req.new_password or not req.new_password.strip():
            return {"status": "error", "message": "New password is required."}
        if len(req.new_password) < 10 or len(req.new_password) > 128:
            return {"status": "error", "message": "Password must be 10-128 characters."}
        if not is_root and actor['username'].lower() != target['username'].lower():
            raise HTTPException(status_code=403, detail="Users can only change their own password.")
        if is_root and actor['username'].lower() != target['username'].lower():
            # root changing someone else's password: no old password needed
            pass
        else:
            # self-change (root included): current password required
            if not db.verify_password(req.old_password, target["password_hash"] or ""):
                c.execute("INSERT INTO audit_logs (username, action, details, created_at) VALUES (?, 'PASSWORD_CHANGE_FAILED', 'Incorrect current password entered', ?)", (target['username'], db.now_str()))
                conn.commit()
                return {"status": "error", "message": "Current password is incorrect."}
        c.execute("UPDATE users SET password_hash = ? WHERE username = ? COLLATE NOCASE", (db.hash_password(req.new_password), req.username.strip()))
        c.execute("INSERT INTO audit_logs (username, action, details, created_at) VALUES (?, 'USER_PASSWORD_SET', ?, ?)", (actor['username'], f"'{target['username']}' password updated", db.now_str()))
        conn.commit()
        _revoke_user_sessions(target['username'])
        return {"status": "ok", "message": "Password updated successfully."}
    except Exception as e:
        return {"status": "error", "message": str(e)}
    finally:
        conn.close()

@app.get("/api/audit-logs")
def get_audit_logs():
    require_admin()
    conn = db.get_db()
    c = conn.cursor()
    logs = [dict(r) for r in c.execute("SELECT * FROM audit_logs ORDER BY id DESC LIMIT 100").fetchall()]
    conn.close()
    return {"status": "ok", "logs": logs}

@app.post("/api/audit-logs/log")
def create_audit_log(req: AuditLogRequest):
    actor = current_actor()
    if req.action.upper() != "LOGOUT":
        raise HTTPException(status_code=403, detail="Client audit action not allowed.")
    db.log_action(actor["username"], "LOGOUT", "Session Closed")
    _revoke_user_sessions(actor["username"])
    return {"status": "ok"}

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=28080, log_level="info", server_header=False)
