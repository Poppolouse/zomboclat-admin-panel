import re
import json
import re
import sys
import os
import shutil
import base64
import urllib.request
import urllib.parse

INI_PATH = "/home/pzserver/Zomboid/Server/pzserver.ini"
SANDBOX_PATH = "/home/pzserver/Zomboid/Server/pzserver_SandboxVars.lua"
WORKSHOP_CONTENT_PATH = "/home/pzserver/pzserver/steamapps/workshop/content/108600"
WORKSHOP_CACHE_PATH = "/var/lib/zomboclat/workshop_cache.json"

def clean_bbcode(text):
    if not text:
        return ""
    t = re.sub(r"\[/?(b|i|u|h1|h2|h3|url|img|list|olist|\*|strike|code|table|tr|th|td|quote|spoiler|hr)[^\]]*\]", " ", text, flags=re.IGNORECASE)
    t = re.sub(r"\s+", " ", t).strip()
    return t[:300]

def clean_str(s):
    if not s:
        return ""
    return re.sub(r"[^a-zA-Z0-9]", "", str(s)).lower()

def load_workshop_cache():
    if os.path.exists(WORKSHOP_CACHE_PATH):
        try:
            with open(WORKSHOP_CACHE_PATH, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            return {}
    return {}

def save_workshop_cache(cache):
    try:
        os.makedirs(os.path.dirname(WORKSHOP_CACHE_PATH), exist_ok=True)
        with open(WORKSHOP_CACHE_PATH, "w", encoding="utf-8") as f:
            json.dump(cache, f, indent=2)
    except Exception:
        pass

def fetch_steam_workshop_details(workshop_ids):
    if not workshop_ids:
        return {}

    cache = load_workshop_cache()
    missing_ids = [wid for wid in workshop_ids if str(wid) not in cache]

    if missing_ids:
        chunk_size = 50
        for i in range(0, len(missing_ids), chunk_size):
            chunk = missing_ids[i:i + chunk_size]
            post_data = {"itemcount": len(chunk)}
            for idx, wid in enumerate(chunk):
                post_data[f"publishedfileids[{idx}]"] = wid

            try:
                encoded_data = urllib.parse.urlencode(post_data).encode()
                req = urllib.request.Request(
                    "https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/",
                    data=encoded_data,
                    headers={"User-Agent": "ZomboclatAdminPanel/1.0"}
                )
                with urllib.request.urlopen(req, timeout=8) as response:
                    res_json = json.loads(response.read().decode("utf-8"))
                    details = res_json.get("response", {}).get("publishedfiledetails", [])
                    for d in details:
                        wid = str(d.get("publishedfileid", ""))
                        if wid and d.get("result") == 1:
                            tags = [t.get("tag", "") for t in d.get("tags", []) if isinstance(t, dict)]
                            desc_raw = d.get("description", "")
                            cache[wid] = {
                                "title": d.get("title", ""),
                                "preview_url": d.get("preview_url", ""),
                                "description": clean_bbcode(desc_raw),
                                "subscriptions": d.get("subscriptions", 0),
                                "views": d.get("views", 0),
                                "file_size": d.get("file_size", "0"),
                                "tags": tags
                            }
            except Exception:
                pass

        save_workshop_cache(cache)

    return {str(wid): cache.get(str(wid)) for wid in workshop_ids if str(wid) in cache}

def scan_installed_mod_infos():
    mapping = {}
    if not os.path.exists(WORKSHOP_CONTENT_PATH):
        return mapping

    try:
        for wid in os.listdir(WORKSHOP_CONTENT_PATH):
            wid_dir = os.path.join(WORKSHOP_CONTENT_PATH, wid)
            if not os.path.isdir(wid_dir):
                continue
            for root, dirs, files in os.walk(wid_dir):
                if "mod.info" in files:
                    mpath = os.path.join(root, "mod.info")
                    m_id = None
                    m_name = None
                    m_desc = None
                    try:
                        with open(mpath, "r", encoding="utf-8", errors="ignore") as f:
                            for line in f:
                                line_s = line.strip()
                                if line_s.startswith("id="):
                                    m_id = line_s.split("id=", 1)[1].strip()
                                elif line_s.startswith("name="):
                                    m_name = line_s.split("name=", 1)[1].strip()
                                elif line_s.startswith("description="):
                                    m_desc = line_s.split("description=", 1)[1].strip()
                        if m_id:
                            mapping[m_id] = {
                                "workshop_id": str(wid),
                                "name": m_name or m_id,
                                "description": m_desc or ""
                            }
                    except Exception:
                        pass
    except Exception:
        pass

    return mapping

def get_ini():
    if not os.path.exists(INI_PATH):
        print(json.dumps({"status": "error", "message": f"{INI_PATH} not found"}))
        return

    settings = {}
    comments = {}
    mods = []
    workshop_items = []
    ordered_keys = []

    pending_comments = []

    with open(INI_PATH, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            line_str = line.strip()
            if not line_str:
                pending_comments = []
                continue
            if line_str.startswith("#"):
                comment_text = line_str.lstrip("#").strip()
                if comment_text:
                    pending_comments.append(comment_text)
                continue
            if "=" in line_str:
                key, val = line_str.split("=", 1)
                key = key.strip()
                val = val.strip()
                comment = " ".join(pending_comments).strip()
                pending_comments = []

                if key == "Mods":
                    mods = [m.strip() for m in val.split(";") if m.strip()]
                elif key == "WorkshopItems":
                    workshop_items = [w.strip() for w in val.split(";") if w.strip()]
                else:
                    settings[key] = val
                    if comment:
                        comments[key] = comment
                    if key not in ordered_keys:
                        ordered_keys.append(key)

    workshop_details = fetch_steam_workshop_details(workshop_items)
    installed_map = scan_installed_mod_infos()

    mod_details = {}
    for mod_id in mods:
        info = installed_map.get(mod_id, {})
        wid = info.get("workshop_id")
        steam_data = workshop_details.get(str(wid), {}) if wid else {}

        name = info.get("name") or steam_data.get("title") or mod_id
        desc = info.get("description") or steam_data.get("description") or ""
        preview_url = steam_data.get("preview_url") or ""
        subs = steam_data.get("subscriptions") or 0

        mod_details[mod_id] = {
            "name": name,
            "workshop_id": str(wid) if wid else "",
            "workshop_title": steam_data.get("title") or "",
            "preview_url": preview_url,
            "description": desc,
            "subscriptions": subs
        }

    print(json.dumps({
        "status": "ok",
        "settings": settings,
        "comments": comments,
        "mods": mods,
        "workshop_items": workshop_items,
        "workshop_details": workshop_details,
        "mod_details": mod_details,
        "keys": ordered_keys
    }))

def save_ini(payload_str):
    if not os.path.exists(INI_PATH):
        print(json.dumps({"status": "error", "message": "INI file not found"}))
        return

    try:
        data = json.loads(payload_str)
    except Exception as e:
        print(json.dumps({"status": "error", "message": f"JSON parse error: {e}"}))
        return

    settings = data.get("settings", {})
    mods = data.get("mods", [])
    workshop_items = data.get("workshop_items", [])

    shutil.copyfile(INI_PATH, INI_PATH + ".bak")

    new_lines = []
    handled_keys = set()

    with open(INI_PATH + ".bak", "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                new_lines.append(line)
                continue
            if "=" in stripped:
                k, _ = stripped.split("=", 1)
                k = k.strip()
                if k == "Mods":
                    new_lines.append(f"Mods={';'.join(mods)}\n")
                    handled_keys.add("Mods")
                elif k == "WorkshopItems":
                    new_lines.append(f"WorkshopItems={';'.join(workshop_items)}\n")
                    handled_keys.add("WorkshopItems")
                elif k in settings:
                    new_lines.append(f"{k}={settings[k]}\n")
                    handled_keys.add(k)
                else:
                    new_lines.append(line)
            else:
                new_lines.append(line)

    for k, v in settings.items():
        if k not in handled_keys:
            new_lines.append(f"{k}={v}\n")

    with open(INI_PATH, "w", encoding="utf-8") as f:
        f.writelines(new_lines)

    print(json.dumps({"status": "ok", "message": "INI settings saved successfully"}))

def parse_lua_value(val_str):
    val_str = val_str.strip().rstrip(",")
    if val_str.lower() == "true":
        return True, "bool"
    if val_str.lower() == "false":
        return False, "bool"
    if (val_str.startswith('"') and val_str.endswith('"')) or (val_str.startswith("'") and val_str.endswith("'")):
        return val_str[1:-1], "string"
    try:
        if "." in val_str:
            return float(val_str), "float"
        return int(val_str), "int"
    except ValueError:
        return val_str, "string"

KNOWN_VANILLA_CATEGORIES = {
    "General": "General Settings",
    "ZombieLore": "Zombie Lore",
    "ZombieConfig": "Zombie Population & Distribution",
    "MultiplierConfig": "XP & Multiplier Settings",
    "Vehicle": "Vehicle Settings",
    "Map": "Map & World Settings",
    "Basement": "Basements"
}

SPECIAL_ACRONYM_MAP = {
    "toc": "The Only Cure",
    "dhbc": "Dynamic Handedness",
    "ls": "Lifestyle: Hobbies",
    "lsambt": "Lifestyle: Ambient",
    "lsmeditation": "Lifestyle: Meditation",
    "lshygiene": "Lifestyle: Hygiene",
    "lsart": "Lifestyle: Art",
    "lscomfort": "Lifestyle: Comfort",
    "zcollision": "Skully's Zombie Collision",
    "rhcr": "Real High-Capacity Radios",
    "biabox": "Bia's Mystery Box",
    "zombievirusvaccinebeta": "Zombie Virus Vaccine"
}

def get_sandbox():
    if not os.path.exists(SANDBOX_PATH):
        print(json.dumps({"status": "error", "message": f"{SANDBOX_PATH} not found"}))
        return

    categories = {}
    current_category = "General"
    categories[current_category] = []

    with open(SANDBOX_PATH, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    lines = content.splitlines()
    in_subtable = None
    pending_comments = []

    for line in lines:
        stripped = line.strip()
        if not stripped:
            pending_comments = []
            continue

        if stripped == "SandboxVars = {" or stripped == "}":
            continue

        if stripped.startswith("--"):
            c_text = stripped.lstrip("-").strip()
            if c_text:
                pending_comments.append(c_text)
            continue

        m_table_start = re.match(r"^([a-zA-Z0-9_]+)\s*=\s*\{", stripped)
        if m_table_start:
            in_subtable = m_table_start.group(1)
            if in_subtable not in categories:
                categories[in_subtable] = []
            pending_comments = []
            continue

        if stripped == "}," and in_subtable:
            in_subtable = None
            pending_comments = []
            continue

        m_kv = re.match(r"^([a-zA-Z0-9_]+)\s*=\s*([^,]+),?", stripped)
        if m_kv:
            key = m_kv.group(1)
            raw_val = m_kv.group(2).strip()
            inline_comment = ""
            if "--" in raw_val:
                parts = raw_val.split("--", 1)
                raw_val = parts[0].strip()
                inline_comment = parts[1].strip()

            val, val_type = parse_lua_value(raw_val)
            all_comments = list(pending_comments)
            if inline_comment:
                all_comments.append(inline_comment)
            comment_str = "\n".join(all_comments).strip()
            pending_comments = []

            target_cat = in_subtable if in_subtable else "General"
            if target_cat not in categories:
                categories[target_cat] = []

            categories[target_cat].append({
                "key": key,
                "value": val,
                "type": val_type,
                "comment": comment_str
            })

    # Build smart category_meta for every sandbox category
    installed = scan_installed_mod_infos()
    all_wids = list(set([v["workshop_id"] for v in installed.values() if v.get("workshop_id")]))
    ws_details = fetch_steam_workshop_details(all_wids)

    category_meta = {}
    for cat in categories.keys():
        if cat in KNOWN_VANILLA_CATEGORIES and cat not in ("Basement",):
            category_meta[cat] = {
                "display_name": KNOWN_VANILLA_CATEGORIES[cat],
                "workshop_id": "",
                "preview_url": "",
                "is_mod": False
            }
            continue

        clean_cat = clean_str(cat)
        matched_info = None
        matched_wid = None

        # 1. Exact match in installed
        if cat in installed:
            matched_info = installed[cat]
            matched_wid = matched_info["workshop_id"]
        else:
            # 2. Clean match in installed
            for mid, info in installed.items():
                clean_mid = clean_str(mid)
                clean_name = clean_str(info.get("name", ""))
                if clean_mid == clean_cat or clean_name == clean_cat or \
                   (len(clean_cat) >= 4 and (clean_cat in clean_mid or clean_mid in clean_cat or clean_cat in clean_name or clean_name in clean_cat)):
                    matched_info = info
                    matched_wid = info["workshop_id"]
                    break

        # 3. Match in workshop details
        if not matched_wid:
            for wid, details in ws_details.items():
                clean_title = clean_str(details.get("title", ""))
                if clean_title and (clean_title == clean_cat or (len(clean_cat) >= 4 and (clean_cat in clean_title or clean_title in clean_cat))):
                    matched_wid = wid
                    matched_info = {"name": details.get("title", cat), "workshop_id": wid}
                    break

        # 4. Special acronym match
        if not matched_wid and clean_cat in SPECIAL_ACRONYM_MAP:
            ac_name = SPECIAL_ACRONYM_MAP[clean_cat]
            for wid, details in ws_details.items():
                if clean_str(ac_name) in clean_str(details.get("title", "")):
                    matched_wid = wid
                    matched_info = {"name": details.get("title", ac_name), "workshop_id": wid}
                    break

        if matched_wid:
            steam_data = ws_details.get(str(matched_wid), {})
            title = steam_data.get("title") or (matched_info.get("name") if matched_info else cat)
            category_meta[cat] = {
                "display_name": title,
                "workshop_id": str(matched_wid),
                "preview_url": steam_data.get("preview_url", ""),
                "is_mod": True
            }
        else:
            category_meta[cat] = {
                "display_name": cat,
                "workshop_id": "",
                "preview_url": "",
                "is_mod": cat not in ("General", "Map", "ZombieLore", "ZombieConfig", "MultiplierConfig", "Vehicle")
            }

    print(json.dumps({
        "status": "ok",
        "categories": categories,
        "category_meta": category_meta
    }))

def _lua_identifier(value):
    value = str(value)
    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", value):
        raise ValueError("Invalid Lua identifier")
    return value


def _lua_string(value):
    return json.dumps(str(value), ensure_ascii=False)


def save_sandbox(payload_str):
    if not os.path.exists(SANDBOX_PATH):
        print(json.dumps({"status": "error", "message": "SandboxVars file not found"}))
        return

    try:
        data = json.loads(payload_str)
        categories = data.get("categories", {})
    except Exception as e:
        print(json.dumps({"status": "error", "message": f"JSON parse error: {e}"}))
        return

    shutil.copyfile(SANDBOX_PATH, SANDBOX_PATH + ".bak")

    out = ["SandboxVars = {"]

    # General first
    if "General" in categories:
        for item in categories["General"]:
            k = _lua_identifier(item["key"])
            v = item["value"]
            t = item.get("type", "string")
            c = item.get("comment", "")
            if c:
                for cl in c.splitlines():
                    out.append(f"    -- {cl}")
            if t == "bool":
                val_str = "true" if v else "false"
            elif t in ("int", "float"):
                if isinstance(v, bool) or not isinstance(v, (int, float)):
                    raise ValueError("Invalid numeric sandbox value")
                val_str = str(v)
            else:
                val_str = _lua_string(v)
            out.append(f"    {k} = {val_str},")

    for cat_name, items in categories.items():
        if cat_name == "General":
            continue
        cat_name = _lua_identifier(cat_name)
        out.append(f"    {cat_name} = {{")
        for item in items:
            k = _lua_identifier(item["key"])
            v = item["value"]
            t = item.get("type", "string")
            c = item.get("comment", "")
            if c:
                for cl in c.splitlines():
                    out.append(f"        -- {cl}")
            if t == "bool":
                val_str = "true" if v else "false"
            elif t in ("int", "float"):
                if isinstance(v, bool) or not isinstance(v, (int, float)):
                    raise ValueError("Invalid numeric sandbox value")
                val_str = str(v)
            else:
                val_str = _lua_string(v)
            out.append(f"        {k} = {val_str},")
        out.append("    },")

    out.append("}\n")

    with open(SANDBOX_PATH, "w", encoding="utf-8") as f:
        f.write("\n".join(out))

    print(json.dumps({"status": "ok", "message": "SandboxVars saved successfully"}))

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps({"status": "error", "message": "Komut belirtilmedi"}))
        sys.exit(1)

    cmd = sys.argv[1]
    if cmd == "get_ini":
        get_ini()
    elif cmd == "save_ini":
        payload = sys.stdin.read() if len(sys.argv) < 3 else sys.argv[2]
        save_ini(payload)
    elif cmd == "save_ini_b64" and len(sys.argv) >= 3:
        payload = base64.b64decode(sys.argv[2]).decode("utf-8")
        save_ini(payload)
    elif cmd == "get_sandbox":
        get_sandbox()
    elif cmd == "save_sandbox":
        payload = sys.stdin.read() if len(sys.argv) < 3 else sys.argv[2]
        save_sandbox(payload)
    elif cmd == "save_sandbox_b64" and len(sys.argv) >= 3:
        payload = base64.b64decode(sys.argv[2]).decode("utf-8")
        save_sandbox(payload)
    elif cmd == "fetch_workshop":
        ids = sys.argv[2].split(";") if len(sys.argv) >= 3 else []
        print(json.dumps(fetch_steam_workshop_details(ids)))
    else:
        print(json.dumps({"status": "error", "message": f"Bilinmeyen komut: {cmd}"}))
