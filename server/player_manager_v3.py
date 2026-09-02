import sqlite3
import json
import sys
import os
import struct
import re
import socket
import urllib.request
import xml.etree.ElementTree as ET
import bcrypt
import base64

PZ_DB_PATH = "/home/pzserver/Zomboid/db/pzserver.db"
PLAYERS_DB_PATH = "/home/pzserver/Zomboid/Saves/Multiplayer/pzserver/players.db"
STEAM_CACHE_PATH = "/var/lib/zomboclat/steam_player_cache.json"
INI_PATH = "/home/pzserver/Zomboid/Server/pzserver.ini"
CATALOG_PATH = "/var/lib/zomboclat/items_catalog.json"
METADATA_PATH = "/var/lib/zomboclat/game_metadata.json"

# ============================================================================
# Binary save-blob extraction (reverse-engineered from B42 networkPlayers.data)
#
# Layout (big-endian):
#   Stats.save()          = 24 x f32 in CharacterStat.ORDERED_STATS order:
#                           ANGER BOREDOM DISCOMFORT ENDURANCE FATIGUE FITNESS
#                           FOOD_SICKNESS HUNGER IDLENESS INTOXICATION MORALE
#                           NICOTINE PAIN PANIC POISON SANITY SICKNESS STRESS
#                           TEMPERATURE THIRST UNHAPPINESS WETNESS ZOMBIE_FEVER
#                           ZOMBIE_INFECTION
#   BodyDamage.save()     = 17 body parts (Hand_L..Foot_R), each:
#                           8x u8 bool (cut,bitten,scratched,bandaged,bleeding,
#                           deepWounded,fakeInfected,infected)
#                           f32 health
#                           [f32 bandageLife]            if bandaged
#                           u8 infectedWound
#                           [f32 woundInfectionLevel]    if infectedWound
#                           f32 cutTime,biteTime,scratchTime,bleedingTime,
#                               alcoholLevel,additionalPain,deepWoundTime
#                           3x u8, f32 stitchTime, 2x u8
#                           f32 fractureTime, u8 splint, [f32 splintFactor]
#                           u8 haveBullet, f32 burnTime, u8 burnWash, f32 lastBurnWash
#                           str splintItem, str bandageType (u16-len prefixed)
#                           6x f32 (cutTime,wetness,stiffness,comfrey,garlic,plantain)
#   Traits                = [u32 count][count x [u16 len][mod:traitId]]
#   XP.save()             = [u32 count][count x [u16 len][perkName][f32 xp]]
#   Perk levels           = [u32 count][count x [u16 len][perkName][u32 level]]
#   hours/kills/worn      = [f64 hoursSurvived][i32 zombieKills][u8 wornCount]
#                           followed by worn items ([u16 len][itemId] + item data)
#   Nutrition.save()      = [f32 calories][f32 proteins][f32 lipids][f32 carbs][f32 weight]
# ============================================================================

STAT_NAMES = ['ANGER','BOREDOM','DISCOMFORT','ENDURANCE','FATIGUE','FITNESS','FOOD_SICKNESS',
              'HUNGER','IDLENESS','INTOXICATION','MORALE','NICOTINE','PAIN','PANIC','POISON',
              'SANITY','SICKNESS','STRESS','TEMPERATURE','THIRST','UNHAPPINESS','WETNESS',
              'ZOMBIE_FEVER','ZOMBIE_INFECTION']

BODY_PART_NAMES = ['Hand_L','Hand_R','ForeArm_L','ForeArm_R','UpperArm_L','UpperArm_R',
                   'Torso_Upper','Torso_Lower','Head','Neck','Groin','UpperLeg_L','UpperLeg_R',
                   'LowerLeg_L','LowerLeg_R','Foot_L','Foot_R']

# ============================================================================
# Item display names (game-authentic) - B42 translations from server install
# Priority: server install Translate dir -> workshop mods -> projectzomboid.jar
#           -> /var/lib/zomboclat/item_display_names.json (uploaded fallback)
# ============================================================================
_TRANSLATE_CACHE = None

def _parse_itemname_txt(path):
    try:
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            txt = f.read()
    except Exception:
        return {}
    out = {}
    for m in re.finditer(r'ItemName_([A-Za-z0-9_]+)\.([A-Za-z0-9_\-]+)\s*=\s*"(.+?)"', txt):
        out[f'{m.group(1)}.{m.group(2)}'.lower()] = m.group(3)
    return out

def _iter_server_roots():
    yield "/home/pzserver/pzserver"
    yield "/home/pzserver/pzserver/pzserver"

def _load_translations():
    global _TRANSLATE_CACHE
    if _TRANSLATE_CACHE is not None:
        return _TRANSLATE_CACHE
    merged = {}

    # 1) Uploaded static file (B41-era fallback)
    for p in ("/var/lib/zomboclat/item_display_names.json",):
        if os.path.exists(p):
            try:
                with open(p, "r", encoding="utf-8") as f:
                    merged.update(json.load(f))
            except Exception:
                pass

    # 2) Vanilla server install: media/lua/shared/Translate/EN/ItemName_EN.txt
    for root in _iter_server_roots():
        p = os.path.join(root, "media", "lua", "shared", "Translate", "EN", "ItemName_EN.txt")
        if os.path.exists(p):
            merged.update(_parse_itemname_txt(p))

    # 3) Workshop mods translations (B42 layout variants)
    try:
        base = WORKSHOP_CONTENT_PATH
        if os.path.isdir(base):
            for wid in os.listdir(base):
                wdir = os.path.join(base, wid)
                if not os.path.isdir(wdir):
                    continue
                for dirpath, _dirs, files in os.walk(wdir):
                    if dirpath.endswith(os.sep + "EN") or os.path.basename(dirpath) == "EN":
                        fn = os.path.join(dirpath, "ItemName_EN.txt")
                        if os.path.isfile(fn):
                            merged.update(_parse_itemname_txt(fn))
                        # stop walking deep once found
    except Exception:
        pass

    _TRANSLATE_CACHE = merged
    return merged

def get_display_name(item_id):
    return _load_translations().get(item_id.lower())

def _resolve_display(item_id, raw_name, cat_info):
    dn = get_display_name(item_id)
    if dn:
        return dn
    # B41 translations repo fallback file: keys lowercase, values display
    dn = get_display_name(item_id.lower())
    if dn:
        return dn
    # Script raw name fallback: CamelCase -> spaced words
    raw = raw_name or item_id.split('.')[-1]
    words = re.sub(r'(?<=[a-z0-9])(?=[A-Z])', ' ', raw)
    words = words.replace('_', ' ')
    return words.strip() or raw

def level_from_xp(xp):
    lvl = 0
    need = 75.0
    total = 0.0
    while total + need <= xp and lvl < 10:
        total += need
        lvl += 1
        need *= 3.0
    return lvl

def xp_for_level(level):
    total = 0.0
    need = 75.0
    for _ in range(level):
        total += need
        need *= 3.0
    return total

_TRAIT_RE = re.compile(rb'(?:base|toadtraits|lifestyle|survivorquirks|toc|vanilla):[a-z0-9_]+')

def _read_table(blob, off, valtype):
    """[u32 count][count x [u16 len][name][val]] -> (count, dict, end_off) or None."""
    if off + 4 > len(blob):
        return None
    cnt = struct.unpack('>I', blob[off:off + 4])[0]
    if not (0 <= cnt <= 80):
        return None
    o = off + 4
    out = {}
    for _ in range(cnt):
        if o + 2 > len(blob):
            return None
        ln = struct.unpack('>H', blob[o:o + 2])[0]
        if ln == 0 or ln > 40 or o + 2 + ln + 4 > len(blob):
            return None
        try:
            nm = blob[o + 2:o + 2 + ln].decode('ascii')
        except Exception:
            return None
        if not re.match(r'^[A-Za-z0-9_]+$', nm):
            return None
        raw = blob[o + 2 + ln:o + 6 + ln]
        if valtype == 'u32':
            v = struct.unpack('>I', raw)[0]
            if v > 10:
                return None
        else:
            v = struct.unpack('>f', raw)[0]
            if v < 0 or v > 10_000_000:
                return None
        out[nm] = v
        o += 6 + ln
    return cnt, out, o

def parse_perk_levels(blob):
    KNOWN = _known_perks()
    cands = []
    for off in range(0, len(blob) - 10):
        r = _read_table(blob, off, 'u32')
        if not r:
            continue
        cnt, out, end = r
        if cnt < 5 or not out:
            continue
        if sum(1 for k in out if k in KNOWN) < 3:
            continue
        cands.append((off, cnt, out, end))
    best = None
    for i, (off, cnt, out, end) in enumerate(cands):
        nested = any(j != i and off2 < off < e2 - 6 for j, (off2, _c, _o, e2) in enumerate(cands))
        if not nested and (best is None or cnt > best[1]):
            best = (off, cnt, out, end)
    return best[2] if best else {}

def parse_perk_xp(blob):
    KNOWN = _known_perks()
    best = None
    for off in range(0, len(blob) - 10):
        r = _read_table(blob, off, 'f32')
        if not r:
            continue
        cnt, out, end = r
        if cnt < 5:
            continue
        if sum(1 for k in out if k in KNOWN) < 3:
            continue
        if all(v == 0 for v in out.values()):
            continue
        if best is None or sum(out.values()) > sum(best[1].values()):
            best = (off, out, end)
    return best[1] if best else {}

def parse_traits(blob):
    best = None
    for m in _TRAIT_RE.finditer(blob):
        start = m.start()
        for back in range(2, 12):
            off = start - back
            if off < 0:
                continue
            if off + 4 > len(blob):
                continue
            cnt = struct.unpack('>I', blob[off:off + 4])[0]
            if not (1 <= cnt <= 120):
                continue
            o = off + 4
            names = []
            ok = True
            for _ in range(cnt):
                if o + 2 > len(blob):
                    ok = False
                    break
                ln = struct.unpack('>H', blob[o:o + 2])[0]
                if ln == 0 or ln > 80 or o + 2 + ln > len(blob):
                    ok = False
                    break
                try:
                    nm = blob[o + 2:o + 2 + ln].decode('utf-8')
                except Exception:
                    ok = False
                    break
                if not re.match(r'^[a-z0-9_]+:[a-z0-9_ ]+$', nm):
                    ok = False
                    break
                names.append(nm)
                o += 2 + ln
            if ok and names and len(names) >= 2:
                best = names
    return best or []

def parse_profession(blob):
    for prof in ['unemployed', 'policeofficer', 'fireofficer', 'parkranger', 'constructionworker',
                 'securityguard', 'carpenter', 'burglar', 'chef', 'repairman', 'farmer', 'fisherman',
                 'doctor', 'nurse', 'lumberjack', 'fitnessInstructor', 'electrician', 'engineer',
                 'metalworker', 'mechanics', 'veteran']:
        if f'base:{prof}'.encode('utf-8') in blob:
            return prof
    return 'unemployed'

def parse_body_parts(blob, off):
    """17 body parts -> (list, end_off) or None."""
    parts = []
    for k in range(17):
        p = {}
        bools = blob[off:off + 8]
        if any(x > 1 for x in bools):
            return None
        p['cut'] = bools[0]
        p['bitten'] = bools[1]
        p['scratched'] = bools[2]
        p['bandaged'] = bools[3]
        p['bleeding'] = bools[4]
        p['deepWounded'] = bools[5]
        p['fakeInfected'] = bools[6]
        p['infected'] = bools[7]
        off += 8
        p['health'] = struct.unpack('>f', blob[off:off + 4])[0]
        if not (0 <= p['health'] <= 100.01):
            return None
        off += 4
        if p['bandaged']:
            p['bandageLife'] = struct.unpack('>f', blob[off:off + 4])[0]
            off += 4
        if blob[off] > 1:
            return None
        p['infectedWound'] = blob[off]
        off += 1
        if p['infectedWound']:
            p['woundInfectionLevel'] = struct.unpack('>f', blob[off:off + 4])[0]
            off += 4
        for key in ('cutTime', 'biteTime', 'scratchTime', 'bleedingTime',
                    'alcoholLevel', 'additionalPain', 'deepWoundTime'):
            p[key] = struct.unpack('>f', blob[off:off + 4])[0]
            if p[key] < -0.001 or p[key] > 100000:
                return None
            off += 4
        for _ in range(3):
            if blob[off] > 1:
                return None
            off += 1
        p['stitchTime'] = struct.unpack('>f', blob[off:off + 4])[0]
        if p['stitchTime'] < -0.001 or p['stitchTime'] > 100000:
            return None
        off += 4
        for _ in range(2):
            if blob[off] > 1:
                return None
            off += 1
        p['fractureTime'] = struct.unpack('>f', blob[off:off + 4])[0]
        if p['fractureTime'] < -0.001 or p['fractureTime'] > 100000:
            return None
        off += 4
        if blob[off] > 1:
            return None
        p['splint'] = blob[off]
        off += 1
        if p['splint']:
            p['splintFactor'] = struct.unpack('>f', blob[off:off + 4])[0]
            off += 4
        if blob[off] > 1:
            return None
        off += 1
        p['burnTime'] = struct.unpack('>f', blob[off:off + 4])[0]
        if p['burnTime'] < -0.001 or p['burnTime'] > 100000:
            return None
        off += 4
        if blob[off] > 1:
            return None
        off += 1
        p['lastTimeBurnWash'] = struct.unpack('>f', blob[off:off + 4])[0]
        if not (-100000 < p['lastTimeBurnWash'] < 100000):
            return None
        off += 4
        for key in ('splintItem', 'bandageType'):
            ln = struct.unpack('>H', blob[off:off + 2])[0]
            if ln > 120:
                return None
            p[key] = blob[off + 2:off + 2 + ln].decode('utf-8', errors='ignore') if ln else ''
            off += 2 + ln
        for _ in range(6):
            v = struct.unpack('>f', blob[off:off + 4])[0]
            if v < -0.001 or v > 100000:
                return None
            off += 4
        parts.append(p)
    return parts, off

def find_stats_bodydamage(blob):
    """Locate [Stats 24f32][BodyDamage 17 parts]. Returns (stats, parts, end) or None."""
    for start in range(0, len(blob) - 96 - 1700):
        vals = struct.unpack('>24f', blob[start:start + 96])
        temp = vals[18]
        if not (34.0 <= temp <= 40.0):
            continue
        endurance = vals[3]
        if not (0 <= endurance <= 1.0):
            continue
        morale = vals[10]
        sanity = vals[15]
        if not (0 <= morale <= 1.0 and 0 <= sanity <= 1.0):
            continue
        bad = False
        for i, v in enumerate(vals):
            if i in (18, 3, 10, 15):
                continue
            if v < -2 or v > 120:
                bad = True
                break
        if bad:
            continue
        r = parse_body_parts(blob, start + 96)
        if r:
            stats = dict(zip(STAT_NAMES, [round(v, 4) for v in vals]))
            return stats, r[0], r[1]
    return None

def find_hours_kills_nutrition(blob):
    """[f64 hours][i32 kills][u8 wornCount][worn items...] ... [Nutrition 5f32]."""
    hk = None
    for off in range(len(blob) - 6000, len(blob) - 12):
        dv = struct.unpack('>d', blob[off:off + 8])[0]
        if not (0.05 <= dv <= 3000):
            continue
        iv = struct.unpack('>i', blob[off + 8:off + 12])[0]
        if not (0 <= iv <= 30000):
            continue
        nb = blob[off + 12]
        if not (0 <= nb <= 100):
            continue
        ln = struct.unpack('>H', blob[off + 13:off + 15])[0]
        if not (2 <= ln <= 40):
            continue
        s = blob[off + 15:off + 15 + ln].decode('ascii', errors='ignore')
        if re.match(r'^[a-z0-9_]+:[a-z0-9_]+$', s):
            hk = off
            break
    if not hk:
        return None
    hours = round(struct.unpack('>d', blob[hk:hk + 8])[0], 2)
    kills = struct.unpack('>i', blob[hk + 8:hk + 12])[0]
    worn = blob[hk + 12]
    nut = None
    for off in range(hk, min(len(blob) - 20, hk + 25000)):
        w = struct.unpack('>f', blob[off + 16:off + 20])[0]
        if 25 <= w <= 150:
            c = struct.unpack('>f', blob[off:off + 4])[0]
            p = struct.unpack('>f', blob[off + 4:off + 8])[0]
            l = struct.unpack('>f', blob[off + 8:off + 12])[0]
            ch = struct.unpack('>f', blob[off + 12:off + 16])[0]
            if all(abs(x) <= 600 for x in (p, l, ch)) and -4000 <= c <= 4000:
                if not (p == 0 and l == 0 and ch == 0):
                    nut = {'calories': round(c, 1), 'proteins': round(p, 1),
                           'lipids': round(l, 1), 'carbs': round(ch, 1), 'weight': round(w, 2)}
                    break
    return hours, kills, worn, nut

_PERKS_CACHE = None
def _known_perks():
    global _PERKS_CACHE
    if _PERKS_CACHE is None:
        meta = get_metadata()
        perks = meta.get('perks', [])
        base = [p['id'] for p in perks]
        extra = ['FlintKnapping', 'ProstFamiliarity', 'Side_L', 'SmallBlade', 'Husbandry',
                 'Butchering', 'Tracking', 'Music', 'Cleaning', 'Searching', 'VoiceMale',
                 'VoiceFemale', 'Passiv']
        _PERKS_CACHE = set(base) | set(extra)
    return _PERKS_CACHE

# Item block markers in the save blob (reverse-engineered):
#   Root item:   0x48 0x0D + [u16 BE len] + "Module.ItemID" + [u16 BE len] + rawName ...
#   Nested item: 0x42 0x00 0x20 0x01 0x00 0x00 0x00 0x01 0x00 0x00
#                + [u16 len=10] "customName" + [u16 len] + DisplayName ...
# Nested items carry NO Module.ItemID; identity only via customName (game display name).
# Container items (bags etc.) are root items; the nested blocks that follow until the
# next root block belong to that container's contents.
_CHILD_MARKER = b'\x00\x20\x01\x00\x00\x00\x01\x00\x00'
_CUSTOM_NAME_KEY = b'\x00\x0AcustomName'

def _read_u16str(b, off):
    """Read [u16 BE len][ascii]. Returns (text, next_off)."""
    if off + 2 > len(b):
        return None, off
    ln = (b[off] << 8) | b[off + 1]
    if ln > 300 or off + 2 + ln > len(b):
        return None, off + 2
    try:
        return b[off + 2:off + 2 + ln].decode('latin-1'), off + 2 + ln
    except Exception:
        return None, off + 2 + ln

def _read_custom_name(b, off):
    """After 'customName' key: [u16=0][u16 len][value]  (observed \x00\x00\x19ALICE...)"""
    # variants: \x00\x00 + u16 len, or u16 len directly. Detect: if next 2 bytes are 00 00 -> len at +2
    if off + 2 <= len(b) and b[off] == 0 and b[off + 1] == 0:
        return _read_u16str(b, off + 2)
    return _read_u16str(b, off)

def extract_inventory_from_blob(data):
    """Container-aware inventory parser.

    Returns flat list of entries:
      container entries: {'id','name','display_name','cat','count':1,'is_mod','mod_name','is_container':True,'children':[entry,...]}
      plain entries:     {...,'is_container':False}
    Children of non-container root items are merged as sibling plain entries.
    """
    if not data:
        return []
    catalog = get_catalog()
    catalog_map = {x['id'].lower(): x for x in catalog}

    def make_entry(item_id, count=1, display=None):
        cat_info = catalog_map.get(item_id.lower(), {}) if item_id else {}
        raw = item_id.split('.')[-1] if item_id else ''
        name = cat_info.get('name') or raw
        cat = cat_info.get('cat') or 'Genel (General)'
        is_mod = cat_info.get('is_mod', False)
        mod_name = cat_info.get('mod_name')
        icon_file = cat_info.get('icon_file')
        dn = display or _resolve_display(item_id, name, cat_info)
        e = {
            'id': item_id,
            'name': dn,                    # game-authentic display name for UI
            'raw_name': name,              # script name
            'cat': cat,
            'count': count,
            'is_mod': is_mod,
            'mod_name': mod_name,
            'icon_file': icon_file,
            'is_container': False,
            'children': [],
        }
        # container?
        if not is_mod and (item_id.startswith('Base.Bag_') or 'container' in (cat_info.get('type') or '').lower()):
            e['is_container'] = True
        return e

    entries = []

    # Sequential scan: root blocks 48 0D, child blocks 42 00 20 01 ...
    pos = 0
    current_container = None
    while pos < len(data):
        r = data.find(b'\x48\x0D', pos)
        c = data.find(_CHILD_MARKER, pos)
        if r == -1 and c == -1:
            break
        if r != -1 and (c == -1 or r <= c):
            # ---- root item: [48 0D][u16 len][Module.ItemID] ----
            txt, nxt = _read_u16str(data, r + 2)
            pos = nxt
            if not txt or not re.match(r'^[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+$', txt):
                current_container = None
                continue
            if txt in ('Base.Default', 'Base.Male', 'Base.Female'):
                current_container = None
                continue
            # container child-of-child? nested containers keep their own children
            e = make_entry(txt)
            if e['is_container']:
                entries.append(e)
                current_container = e
            else:
                # merge into existing flat entry (same id) or append
                flat = next((x for x in entries if not x['is_container'] and x['id'] == txt), None)
                if flat:
                    flat['count'] += 1
                else:
                    entries.append(e)
                current_container = None
        else:
            # ---- nested child ----
            kpos = data.find(_CUSTOM_NAME_KEY, c, c + 60)
            if kpos == -1:
                pos = c + 4
                continue
            o = kpos + len(_CUSTOM_NAME_KEY)
            # observed value formats: [00][u16 len][str] or [u16 len][str]
            dn = None
            for tryoff in (o + 1, o):
                if tryoff + 2 <= len(data):
                    ln = (data[tryoff] << 8) | data[tryoff + 1]
                    if 0 < ln < 300 and tryoff + 2 + ln <= len(data):
                        dn = data[tryoff + 2:tryoff + 2 + ln].decode('latin-1', errors='replace')
                        nxt = tryoff + 2 + ln
                        break
            pos = nxt if dn else (o + 4)
            if not dn:
                continue
            if current_container is not None and current_container.get('is_container'):
                ce = _make_child_entry(dn, catalog_map)
                current_container['children'].append(ce)
            # children of non-container roots are ignored (they're equipment details)

    return entries

def _make_child_entry(display, catalog_map):
    """Child items in the blob carry ONLY the game display name.
    Resolve identity by reverse-mapping display -> item id via translations."""
    display_l = display.lower()
    # 1) translations reversed: display name -> list of ids (prefer Base./vanilla first)
    trans = _load_translations()
    cand = [iid for iid, dn in trans.items() if dn.lower() == display_l]
    if not cand:
        # 2) catalog raw names
        for cid, ci in catalog_map.items():
            if (ci.get('name') or '').lower() == display_l:
                cand = [cid]
                break
    item_id = None
    if cand:
        vanilla = [x for x in cand if x.startswith('base.')]
        pick = vanilla[0] if vanilla else cand[0]
        item_id = pick
    cat_info = catalog_map.get(item_id.lower(), {}) if item_id else {}
    return {
        'id': item_id or '',
        'name': display,
        'raw_name': cat_info.get('name') or display,
        'cat': cat_info.get('cat') or 'Genel (General)',
        'count': 1,
        'is_mod': cat_info.get('is_mod', False),
        'mod_name': cat_info.get('mod_name'),
        'icon_file': cat_info.get('icon_file'),
        'is_container': False,
        'resolved': bool(item_id),
    }
    return items_list

def extract_player_blob(data, is_dead=False):
    info = {
        'profession': 'unemployed',
        'traits': [],
        'skills': {},
        'skill_xp': {},
        'inventory': [],
        'hours_survived': 0.0,
        'zombie_kills': 0,
        'weight': 80.0,
        'health': 0.0 if is_dead else 100.0,
        'is_infected': False,
        'hunger': 0.0,
        'thirst': 0.0,
        'fatigue': 0.0,
        'stress': 0.0,
        'boredom': 0.0,
        'unhappiness': 0.0,
        'pain': 0.0,
        'body_parts': [],
        'parse_ok': False,
    }

    if not data or len(data) < 20:
        return info

    try:
        info['parse_ok'] = True

        # 1. Profession
        info['profession'] = parse_profession(data)

        # 2. Traits
        raw_traits = parse_traits(data)
        traits = []
        for t in raw_traits:
            short = t.split(':', 1)[1] if ':' in t else t
            if short not in traits:
                traits.append(short)
        info['traits'] = traits

        # 3. Stats (24 floats)
        sb = find_stats_bodydamage(data)
        if sb:
            smap, parts, bd_end = sb
            info['hunger'] = round(smap.get('HUNGER', 0.0) * 100.0, 1)
            info['thirst'] = round(smap.get('THIRST', 0.0) * 100.0, 1)
            info['fatigue'] = round(smap.get('FATIGUE', 0.0) * 100.0, 1)
            info['stress'] = round(smap.get('STRESS', 0.0) * 100.0, 1)
            info['boredom'] = round(smap.get('BOREDOM', 0.0), 1)
            info['unhappiness'] = round(smap.get('UNHAPPINESS', 0.0), 1)
            info['pain'] = round(smap.get('PAIN', 0.0), 1)
            infection = smap.get('ZOMBIE_INFECTION', 0.0)
            info['is_infected'] = infection > 0.0 or any(p['infected'] for p in parts)
            # overall health = average body part health (PZ has per-part health only)
            avg = sum(p['health'] for p in parts) / 17.0
            info['health'] = 0.0 if is_dead else round(avg, 1)
            info['body_parts'] = [
                {'name': BODY_PART_NAMES[i], 'health': round(parts[i]['health'], 1),
                 'bitten': bool(parts[i]['bitten']), 'bleeding': bool(parts[i]['bleeding']),
                 'scratched': bool(parts[i]['scratched']), 'bandaged': bool(parts[i]['bandaged']),
                 'fracture': round(parts[i].get('fractureTime', 0.0), 1),
                 'infected': bool(parts[i]['infected'])}
                for i in range(17)
            ]

        # 4. Perk LEVELS + XP
        levels = parse_perk_levels(data)
        xp_map = parse_perk_xp(data)
        meta = get_metadata()
        perks_meta = meta.get('perks', [])
        save_to_panel = {'Butchering': 'Butchery'}
        panel_to_save = {'Butchery': 'Butchering'}
        skills = {}
        skill_xp = {}
        for p in perks_meta:
            pid = p['id']
            sid = panel_to_save.get(pid, pid)
            lvl = levels.get(sid, levels.get(pid, 0))
            xp = xp_map.get(sid, xp_map.get(pid))
            if lvl == 0 and xp is not None:
                lvl = level_from_xp(xp)
            skills[pid] = int(lvl)
            if xp is not None:
                skill_xp[pid] = round(xp, 1)
        info['skills'] = skills
        info['skill_xp'] = skill_xp

        # 5. Inventory
        info['inventory'] = extract_inventory_from_blob(data)

        # 6. hours survived, zombie kills, weight (Nutrition)
        hkn = find_hours_kills_nutrition(data)
        if hkn:
            hours, kills, worn, nut = hkn
            info['hours_survived'] = hours
            info['zombie_kills'] = int(kills)
            if nut:
                info['weight'] = nut['weight']
    except Exception:
        info['parse_ok'] = False

    return info
def get_catalog():
    if os.path.exists(CATALOG_PATH):
        try:
            with open(CATALOG_PATH, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            return []
    return []

def get_metadata():
    if os.path.exists(METADATA_PATH):
        try:
            with open(METADATA_PATH, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            return {}
    return {}
def get_rcon_credentials():
    port = 27015
    pwd = ""
    if os.path.exists(INI_PATH):
        try:
            with open(INI_PATH, "r", encoding="utf-8", errors="ignore") as f:
                for line in f:
                    line = line.strip()
                    if line.startswith("RCONPort="):
                        port = int(line.split("=", 1)[1])
                    elif line.startswith("RCONPassword="):
                        pwd = line.split("=", 1)[1]
        except Exception:
            pass
    return "127.0.0.1", port, pwd

def send_rcon(cmd):
    host, port, pwd = get_rcon_credentials()
    if not pwd:
        return {"status": "error", "message": "RCON sifresi bulunamadi"}
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(2.5)
    try:
        s.connect((host, port))
        req_id = 1
        payload = pwd.encode('utf-8') + b'\x00\x00'
        pkt = struct.pack('<iii', len(payload) + 8, req_id, 3) + payload
        s.sendall(pkt)
        s.recv(4096)
        
        req_id = 2
        payload = cmd.encode('utf-8') + b'\x00\x00'
        pkt = struct.pack('<iii', len(payload) + 8, req_id, 2) + payload
        s.sendall(pkt)
        resp = s.recv(4096)
        body = ""
        if len(resp) >= 12:
            body = resp[12:-2].decode('utf-8', errors='ignore')
        return {"status": "ok", "response": body.strip()}
    except Exception as e:
        return {"status": "error", "message": str(e)}
    finally:
        try:
            s.close()
        except Exception:
            pass

def load_steam_cache():
    if os.path.exists(STEAM_CACHE_PATH):
        try:
            with open(STEAM_CACHE_PATH, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            return {}
    return {}

def save_steam_cache(cache):
    try:
        os.makedirs(os.path.dirname(STEAM_CACHE_PATH), exist_ok=True)
        with open(STEAM_CACHE_PATH, "w", encoding="utf-8") as f:
            json.dump(cache, f, indent=2)
    except Exception:
        pass

def fetch_steam_player_avatars(steam_ids):
    cache = load_steam_cache()
    missing_ids = [str(sid) for sid in steam_ids if str(sid) and str(sid) not in cache]

    for sid in missing_ids:
        url = f"https://steamcommunity.com/profiles/{sid}/?xml=1"
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"})
            with urllib.request.urlopen(req, timeout=4) as resp:
                content = resp.read().decode("utf-8", errors="ignore")
                root = ET.fromstring(content)
                avatar = root.findtext("avatarFull") or root.findtext("avatarMedium") or root.findtext("avatarIcon") or ""
                persona = root.findtext("steamID") or ""
                cache[sid] = {
                    "avatar": avatar,
                    "persona_name": persona
                }
        except Exception:
            cache[sid] = {
                "avatar": "",
                "persona_name": ""
            }

    if missing_ids:
        save_steam_cache(cache)

    return cache

def get_db():
    if not os.path.exists(PZ_DB_PATH):
        return None
    conn = sqlite3.connect(PZ_DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def get_players():
    conn = get_db()
    if not conn:
        print(json.dumps({"status": "error", "message": f"{PZ_DB_PATH} bulunamadi"}))
        return

    cur = conn.cursor()

    # 1. Whitelist / Players
    cur.execute("""
        SELECT w.id, w.username, w.lastConnection, w.steamid, w.displayName, w.role as role_id,
               r.name as role_name, r.description as role_desc
        FROM whitelist w
        LEFT JOIN role r ON w.role = r.id
        ORDER BY w.role DESC, w.lastConnection DESC
    """)
    players_raw = [dict(row) for row in cur.fetchall()]

    # 2. In-game character data from players.db
    char_map = {}
    if os.path.exists(PLAYERS_DB_PATH):
        try:
            p_conn = sqlite3.connect(PLAYERS_DB_PATH)
            p_cur = p_conn.cursor()
            p_cur.execute("SELECT username, name, steamid, x, y, z, isDead, data FROM networkPlayers")
            for row in p_cur.fetchall():
                u = row[0]
                is_dead = bool(row[6])
                blob_data = row[7]
                b_info = extract_player_blob(blob_data, is_dead) if blob_data else {}
                
                char_map[u] = {
                    "char_name": row[1],
                    "steamid": str(row[2]) if row[2] else "",
                    "pos_x": round(row[3], 1) if row[3] else b_info.get("pos_x", 0),
                    "pos_y": round(row[4], 1) if row[4] else b_info.get("pos_y", 0),
                    "pos_z": int(row[5]) if row[5] else b_info.get("pos_z", 0),
                    "is_dead": is_dead,
                    "profession": b_info.get("profession", "unemployed"),
                    "traits": b_info.get("traits", []),
                    "skills": b_info.get("skills", {}),
                    "skill_xp": b_info.get("skill_xp", {}),
                    "blob_parsed": b_info.get("parse_ok", False),
                    "inventory": b_info.get("inventory", []),
                    "hours_survived": b_info.get("hours_survived", 0.0),
                    "zombie_kills": b_info.get("zombie_kills", 0),
                    "weight": b_info.get("weight", 80.0),
                    "health": b_info.get("health", 100.0),
                    "is_infected": b_info.get("is_infected", False),
                    "hunger": b_info.get("hunger", 0.0),
                    "thirst": b_info.get("thirst", 0.0),
                    "fatigue": b_info.get("fatigue", 0.0),
                    "stress": b_info.get("stress", 0.0),
                    "boredom": b_info.get("boredom", 0.0),
                    "unhappiness": b_info.get("unhappiness", 0.0),
                    "pain": b_info.get("pain", 0.0),
                    "body_parts": b_info.get("body_parts", [])
                }
            p_conn.close()
        except Exception as e:
            pass

    # 3. Steam Avatars
    steam_ids = [str(p.get("steamid", "")) for p in players_raw if p.get("steamid")]
    steam_avatars = fetch_steam_player_avatars(steam_ids)

    players = []
    for p in players_raw:
        uname = p.get("username", "")
        sid = str(p.get("steamid", "")) if p.get("steamid") else ""
        c_info = char_map.get(uname, {})

        char_name = c_info.get("char_name") or p.get("displayName") or uname
        s_data = steam_avatars.get(sid, {})
        steam_avatar = s_data.get("avatar", "")
        steam_persona = s_data.get("persona_name", "")

        seed_name = char_name.replace(" ", "+")
        pixel_avatar = f"https://api.dicebear.com/7.x/adventurer/png?seed={seed_name}&scale=110&radius=10"

        players.append({
            "id": p["id"],
            "username": uname,
            "char_name": char_name,
            "lastConnection": p.get("lastConnection"),
            "steamid": sid,
            "steam_persona": steam_persona,
            "steam_avatar": steam_avatar,
            "pixel_avatar": pixel_avatar,
            "role_id": p.get("role_id", 2),
            "role_name": p.get("role_name", "user"),
            "role_desc": p.get("role_desc", ""),
            "pos_x": c_info.get("pos_x"),
            "pos_y": c_info.get("pos_y"),
            "pos_z": c_info.get("pos_z"),
            "is_dead": c_info.get("is_dead", False),
            "profession": c_info.get("profession", "unemployed"),
            "traits": c_info.get("traits", []),
            "skills": c_info.get("skills", {}),
            "skill_xp": c_info.get("skill_xp", {}),
            "blob_parsed": c_info.get("blob_parsed", False),
            "inventory": c_info.get("inventory", []),
            "hours_survived": c_info.get("hours_survived", 0.0),
            "zombie_kills": c_info.get("zombie_kills", 0),
            "weight": c_info.get("weight", 80.0),
            "health": c_info.get("health", 100.0),
            "is_infected": c_info.get("is_infected", False),
            "hunger": c_info.get("hunger", 0.0),
            "thirst": c_info.get("thirst", 0.0),
            "fatigue": c_info.get("fatigue", 0.0),
            "stress": c_info.get("stress", 0.0),
            "boredom": c_info.get("boredom", 0.0),
            "unhappiness": c_info.get("unhappiness", 0.0),
            "pain": c_info.get("pain", 0.0),
            "body_parts": c_info.get("body_parts", [])
        })

    # 4. Roles
    cur.execute("SELECT id, name, description FROM role ORDER BY id ASC")
    roles = [dict(row) for row in cur.fetchall()]

    # 5. Bans
    cur.execute("SELECT steamid, reason FROM bannedid")
    banned_ids = [dict(row) for row in cur.fetchall()]

    # 6. User logs
    cur.execute("SELECT id, username, type, text, issuedBy, amount, lastUpdate FROM userlog ORDER BY id DESC LIMIT 100")
    user_logs = [dict(row) for row in cur.fetchall()]

    conn.close()

    meta = get_metadata()

    print(json.dumps({
        "status": "ok",
        "players": players,
        "roles": roles,
        "banned_ids": banned_ids,
        "user_logs": user_logs,
        "userlogs": user_logs,
        "metadata": meta
    }))

def add_player(username, password, role_id=2):
    conn = get_db()
    if not conn:
        print(json.dumps({"status": "error", "message": "Database not found"}))
        return
    cur = conn.cursor()
    cur.execute("SELECT id FROM whitelist WHERE username = ?", (username,))
    if cur.fetchone():
        conn.close()
        print(json.dumps({"status": "error", "message": "Bu kullanici adi zaten whitelistte kayitli"}))
        return

    hashed_pwd = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt(12, prefix=b"2a")).decode("utf-8")
    cur.execute("INSERT INTO whitelist (world, username, password, role) VALUES ('pzserver', ?, ?, ?)", (username, hashed_pwd, role_id))
    conn.commit()
    conn.close()
    print(json.dumps({"status": "ok", "message": "Oyuncu eklendi"}))

def del_player(username):
    conn = get_db()
    if not conn:
        print(json.dumps({"status": "error", "message": "Database not found"}))
        return
    cur = conn.cursor()
    cur.execute("DELETE FROM whitelist WHERE username = ?", (username,))
    conn.commit()
    conn.close()
    print(json.dumps({"status": "ok", "message": "Oyuncu silindi"}))

def update_player_full(username, payload_json_str):
    try:
        data = json.loads(payload_json_str)
    except Exception as e:
        print(json.dumps({"status": "error", "message": f"JSON parse hatasi: {e}"}))
        return

    conn = get_db()
    if not conn:
        print(json.dumps({"status": "error", "message": "Database not found"}))
        return
    cur = conn.cursor()

    char_name = data.get("char_name", "").strip()
    role_id = data.get("role_id", 2)
    steamid = data.get("steamid", "").strip()
    password = data.get("password", "").strip()
    pos_x = data.get("pos_x")
    pos_y = data.get("pos_y")
    pos_z = data.get("pos_z", 0)
    is_dead = data.get("is_dead", False)
    is_banned = data.get("is_banned", False)
    ban_reason = data.get("ban_reason", "Admin Panel tarafindan yasaklandi")
    skills = data.get("skills", {})
    godmode = data.get("godmode", False)
    invisible = data.get("invisible", False)
    heal = data.get("heal", False)
    add_items = data.get("add_items", []) # List of {id, count}
    # Save uses 'Butchering' while the panel catalog id is 'Butchery'
    panel_to_save = {'Butchery': 'Butchering'}

    # 1. Update whitelist table in pzserver.db
    if password:
        hashed_pwd = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt(12, prefix=b"2a")).decode("utf-8")
        cur.execute("UPDATE whitelist SET role = ?, steamid = ?, displayName = ?, password = ? WHERE username = ?", (role_id, steamid, char_name, hashed_pwd, username))
    else:
        cur.execute("UPDATE whitelist SET role = ?, steamid = ?, displayName = ? WHERE username = ?", (role_id, steamid, char_name, username))

    # Ban check
    if is_banned or role_id == 1:
        if steamid:
            cur.execute("SELECT steamid FROM bannedid WHERE steamid = ?", (steamid,))
            if not cur.fetchone():
                cur.execute("INSERT INTO bannedid (steamid, reason) VALUES (?, ?)", (steamid, ban_reason))
    else:
        if steamid:
            cur.execute("DELETE FROM bannedid WHERE steamid = ?", (steamid,))

    conn.commit()
    conn.close()

    # 2. Update networkPlayers table in players.db
    if os.path.exists(PLAYERS_DB_PATH):
        try:
            p_conn = sqlite3.connect(PLAYERS_DB_PATH)
            p_cur = p_conn.cursor()
            if pos_x is not None and pos_y is not None:
                p_cur.execute("UPDATE networkPlayers SET name = ?, steamid = ?, x = ?, y = ?, z = ?, isDead = ? WHERE username = ?", (char_name, steamid, pos_x, pos_y, pos_z, 1 if is_dead else 0, username))
            else:
                p_cur.execute("UPDATE networkPlayers SET name = ?, steamid = ?, isDead = ? WHERE username = ?", (char_name, steamid, 1 if is_dead else 0, username))
            p_conn.commit()
            p_conn.close()
        except Exception:
            pass

    # 3. Apply live in-game changes via RCON
    try:
        role_names = {1: "none", 2: "none", 3: "none", 4: "observer", 5: "gm", 6: "moderator", 7: "admin"}
        target_role = role_names.get(role_id, "none")
        if target_role != "none":
            send_rcon(f'setaccesslevel "{username}" "{target_role}"')
        
        if is_banned:
            send_rcon(f'banuser "{username}" -ip -r "{ban_reason}"')
            
        if godmode:
            send_rcon(f'godmode "{username}" -true')
        if invisible:
            send_rcon(f'invisible "{username}" -true')
        if heal:
            send_rcon(f'heal "{username}"')
            
        if pos_x is not None and pos_y is not None:
            send_rcon(f'teleportto "{username}" {pos_x},{pos_y},{pos_z}')
            
        if skills:
            # Read current levels from the save so we compute the XP DELTA needed,
            # then grant only the difference via addxp (addxp adds to existing XP).
            cur_levels = {}
            cur_xp = {}
            try:
                if os.path.exists(PLAYERS_DB_PATH):
                    pc = sqlite3.connect(PLAYERS_DB_PATH)
                    cc = pc.cursor()
                    cc.execute("SELECT data FROM networkPlayers WHERE username = ?", (username,))
                    row = cc.fetchone()
                    pc.close()
                    if row and row[0]:
                        blob = row[0]
                        levels_tbl = parse_perk_levels(blob)
                        xp_tbl = parse_perk_xp(blob)
                        for k, v in levels_tbl.items():
                            if k not in cur_levels or v > cur_levels[k]:
                                cur_levels[k] = v
                        for k, v in xp_tbl.items():
                            cur_xp[k] = v
            except Exception:
                pass
            for sname, lvl in skills.items():
                target = int(lvl)
                sid = panel_to_save.get(sname, sname)
                cur = cur_levels.get(sid, 0)
                if target > cur:
                    # XP needed to go from current level's floor to target level's floor
                    need = xp_for_level(target) - xp_for_level(cur)
                    if cur_xp.get(sid, 0.0) > xp_for_level(cur):
                        # player has partial XP into current level; give only remainder to reach target floor
                        need = max(0.0, xp_for_level(target) - cur_xp.get(sid, 0.0))
                    if need > 0:
                        send_rcon(f'addxp "{username}" "{sid}={int(need)}"')
                    
        if add_items:
            for item in add_items:
                iid = item.get("id")
                cnt = item.get("count", 1)
                if iid:
                    send_rcon(f'additem "{username}" "{iid}" {cnt}')
    except Exception:
        pass

    print(json.dumps({"status": "ok", "message": "Oyuncu ve karakter verileri kaydedildi"}))

def search_catalog(query="", category="", limit=100):
    catalog = get_catalog()
    q = query.lower().strip()
    cat = category.lower().strip()
    
    results = []
    for item in catalog:
        if cat and cat not in item.get('cat', '').lower():
            continue
        if q:
            name_match = q in item.get('name', '').lower()
            id_match = q in item.get('id', '').lower()
            mod_match = q in (item.get('mod_name') or '').lower()
            if not (name_match or id_match or mod_match):
                continue
        results.append(item)
        if len(results) >= limit:
            break
    print(json.dumps({"status": "ok", "items": results, "total_matches": len(results)}))

def main():
    if len(sys.argv) < 2:
        print("Usage: player_manager.py [list|get|add|del|update|update_full|update_full_b64|ban|unban|rcon|catalog]")
        return

    cmd = sys.argv[1]

    if cmd in ["list", "get"]:
        get_players()
    elif cmd == "catalog":
        query = sys.argv[2] if len(sys.argv) > 2 else ""
        category = sys.argv[3] if len(sys.argv) > 3 else ""
        limit = int(sys.argv[4]) if len(sys.argv) > 4 else 200
        search_catalog(query, category, limit)
    elif cmd == "add":
        username = sys.argv[2]
        password = sys.argv[3]
        role_id = int(sys.argv[4]) if len(sys.argv) > 4 else 2
        add_player(username, password, role_id)
    elif cmd == "del":
        username = sys.argv[2]
        del_player(username)
    elif cmd == "update_full_b64":
        username = sys.argv[2]
        b64 = sys.argv[3]
        payload = base64.b64decode(b64.encode("utf-8")).decode("utf-8")
        update_player_full(username, payload)
    elif cmd == "update_full":
        username = sys.argv[2]
        payload = sys.argv[3]
        update_player_full(username, payload)
    elif cmd == "rcon":
        raw_cmd = " ".join(sys.argv[2:])
        res = send_rcon(raw_cmd)
        print(json.dumps(res))
    else:
        print(json.dumps({"status": "error", "message": f"Bilinmeyen komut: {cmd}"}))

if __name__ == "__main__":
    main()
