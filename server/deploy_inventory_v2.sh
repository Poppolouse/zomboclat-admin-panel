#!/bin/bash
# ============================================================================
# Zomboclat - Envanter v2 deploy (container-aware + oyun ici isimler)
# ============================================================================
# Bu script VPS'te (root olarak veya pzserver yetkisiyle) calistirilir.
# 1) Yeni player_manager_v3.py kurulumu
# 2) Fallback ceviri dosyasinin kurulumu (B42 server cevirileri yoksa)
# 3) Dogrulama testleri
set -e

PM_DST="/var/lib/zomboclat/player_manager_v3.py"
PM_SERVICE_REF="/usr/local/bin/player_manager.py"
TRANS_DST="/var/lib/zomboclat/item_display_names.json"

echo "=== 1) Yedek aliniyor ==="
cp "$PM_DST" "/tmp/player_manager_v3.bak.$(date +%s)" 2>/dev/null || true

echo "=== 2) player_manager_v3.py kopyalaniyor ==="
# Bu script ile ayni klasorde player_manager_v3.py olmali
cp "$(dirname "$0")/player_manager_v3.py" "$PM_DST"
chmod 644 "$PM_DST"

echo "=== 3) Fallback ceviriler kuruluyor ==="
python3 - <<'PYEOF'
import re, json
txt = open("ItemName_EN_fallback.txt", "r", encoding="utf-8", errors="ignore").read()
d = {}
for m in re.finditer(r'ItemName_([A-Za-z0-9_]+)\.([A-Za-z0-9_\-]+)\s*=\s*"(.+?)"', txt):
    d[f'{m.group(1)}.{m.group(2)}'.lower()] = m.group(3)
json.dump(d, open("/var/lib/zomboclat/item_display_names.json", "w", encoding="utf-8"), ensure_ascii=False)
print("fallback display names:", len(d))
PYEOF

echo "=== 4) Parser dogrulama ==="
python3 - <<'PYEOF'
import sys
sys.path.insert(0, "/var/lib/zomboclat")
import importlib, player_manager_v3 as pm
importlib.reload(pm)
import sqlite3
conn = sqlite3.connect("/home/pzserver/Zomboid/Saves/Multiplayer/pzserver/players.db")
cur = conn.cursor()
cur.execute("SELECT username, data FROM networkPlayers LIMIT 3")
for uname, blob in cur.fetchall():
    entries = pm.extract_inventory_from_blob(blob)
    containers = [e for e in entries if e['is_container']]
    kids = sum(len(e['children']) for e in containers)
    print(f"{uname}: {len(entries)} esya, {len(containers)} konteyner, {kids} ic icerik")
    for c in containers:
        names = [x['name'] for x in c['children'][:4]]
        print(f"   {c['name']} -> {names}")
PYEOF

echo "=== 5) Bitti. Paneli yeniden baslatmayi unutmayin. ==="