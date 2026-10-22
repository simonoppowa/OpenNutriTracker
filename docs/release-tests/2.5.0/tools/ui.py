#!/usr/bin/env python3
"""Screen, log and key-file reader for the 2.5.0 release run (rt.sh).

Stdlib only. Always run with `python3 -I` so nothing next to a dump is imported.
Nothing in here ever prints the AI key: the key-file commands answer with exit
codes and fixed words only.

Dumps (uiautomator XML):
  ls DUMP                  every node worth acting on: `x,y  resource-id | label  {flags}`
  find DUMP SEL            centre "x y" of the match. Exit 1 none, 3 occluded by the
                           FAB or the nav bar, 5 the node belongs to a foreign package
                           (allowed packages come from $RT_ALLOW_PKGS, space separated)
  bounds DUMP SEL          "x1 y1 x2 y2" of the match (same exit codes as find)
  get DUMP SEL             the match's label, then the text of each EditText inside it
  usable DUMP              exit 0 if the dump is complete and shows content from an
                           allowed package (the first dump after a launch is often bare)
  state DUMP               key=value lines: nav, modal, back, edit, password, bullets
Screens:
  screen RAW OUT.png|-     `screencap` raw output -> PNG (RGB), prints `red=F`;
                           exit 4 if F >= RED_LIMIT (Flutter's red ErrorWidget)
  redpng PNG               the same red fraction for a PNG (slow; tests and triage)
  pixel PNG X Y            "r g b hue lum" at X,Y
Logs:
  logscan FILE OFFSET PKG  new findings in a logcat file since byte OFFSET:
                           `CRASH|ANR|FLUTTER <line>`; last line `offset=N`
  crashscan PKG            the same rules on stdin (logcat -b crash); exit 0 if PKG crashed
Key file (never printed):
  keycheck KEYFILE         0 ok, 10 missing/empty, 11 placeholder, 12 not one line of
                           [A-Za-z0-9_-], 13 mode is not 600
  textcheck KEYFILE TEXT   exit 1 if TEXT contains the key or looks like an API key
  secretlen KEYFILE DUMP   exit 0 if the focused EditText shows exactly len(key) bullets
  audit KEYFILE DIR        every file under DIR that contains the key, by name; exit 1 if any

SEL is one of
  id=RESOURCE_ID   text=LABEL   text~=FRAGMENT   text^=PREFIX   edit=N
and may end in @K to take the K-th match (1-based). Labels are text or content-desc.
"""
import colorsys
import os
import re
import stat
import sys
import xml.etree.ElementTree as ET
import zlib

BOUNDS = re.compile(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]")
# Occluders: a tap whose centre falls inside one of these lands on it instead
# (the FAB covered the bottom row of the You list in the settings run).
OCCLUDERS = ("fab-add-item", "nav-home", "nav-diary", "nav-trends", "nav-you")
BACK_LABELS = {"Back", "Zurück", "Close", "Schließen", "Navigate up", "Nach oben"}
RED_LIMIT = 0.02
PLACEHOLDER = b"PASTE_YOUR_KEY_HERE"
KEY_RE = re.compile(rb"^[A-Za-z0-9_-]{16,512}$")
LOOKS_LIKE_KEY = re.compile(r"(sk-[A-Za-z0-9_-]{12,}|AIza[A-Za-z0-9_-]{20,})")


# --- dumps -------------------------------------------------------------------

def _load(path):
    raw = open(path, "rb").read()
    end = raw.rfind(b"</hierarchy>")
    if end == -1:
        raise ValueError("incomplete dump")
    raw = raw[: end + len(b"</hierarchy>")]
    start = raw.find(b"<?xml")
    if start > 0:
        raw = raw[start:]
    return ET.fromstring(raw)


def _box(node):
    m = BOUNDS.match(node.attrib.get("bounds", ""))
    if not m:
        return None
    x1, y1, x2, y2 = (int(g) for g in m.groups())
    if x2 <= x1 or y2 <= y1:
        return None
    return x1, y1, x2, y2


def _label(node):
    t = node.attrib.get("text", "")
    return t if t else node.attrib.get("content-desc", "")


def _allowed():
    return set(os.environ.get("RT_ALLOW_PKGS", "").split())


def _matches(node, kind, value):
    t = node.attrib.get("text", "")
    d = node.attrib.get("content-desc", "")
    if kind == "id":
        return node.attrib.get("resource-id", "") == value
    if kind == "text":
        return value in (t, d)
    if kind == "text~":
        return value in t or value in d
    if kind == "text^":
        return t.startswith(value) or d.startswith(value)
    return False


def _select(root, selector):
    nth = 1
    if "@" in selector and selector.rsplit("@", 1)[1].isdigit():
        selector, k = selector.rsplit("@", 1)
        nth = int(k)
    if selector.startswith("edit="):
        nth = int(selector[5:])
        edits = [n for n in root.iter() if "EditText" in n.attrib.get("class", "") and _box(n)]
        edits.sort(key=lambda n: (_box(n)[1], _box(n)[0]))
        return edits[nth - 1] if len(edits) >= nth else None
    for prefix, kind in (("text~=", "text~"), ("text^=", "text^"), ("text=", "text"), ("id=", "id")):
        if selector.startswith(prefix):
            value = selector[len(prefix):]
            break
    else:
        raise SystemExit(f"bad selector: {selector}")
    hits = [n for n in root.iter() if _box(n) and _matches(n, kind, value)]
    return hits[nth - 1] if len(hits) >= nth else None


def _checked_node(path, selector):
    """The selected node, or exit 1 (none) / 3 (occluded) / 5 (foreign package)."""
    root = _load(path)
    node = _select(root, selector)
    if node is None:
        sys.exit(1)
    allowed = _allowed()
    if allowed and node.attrib.get("package", "") not in allowed:
        print(f"foreign package: {node.attrib.get('package', '')}", file=sys.stderr)
        sys.exit(5)
    x1, y1, x2, y2 = _box(node)
    cx, cy = (x1 + x2) // 2, (y1 + y2) // 2
    rid = node.attrib.get("resource-id", "")
    for occ in root.iter():
        oid = occ.attrib.get("resource-id", "")
        if oid not in OCCLUDERS or oid == rid:
            continue
        ob = _box(occ)
        if not ob:
            continue
        inside_target = x1 >= ob[0] and y1 >= ob[1] and x2 <= ob[2] and y2 <= ob[3]
        if ob[0] <= cx <= ob[2] and ob[1] <= cy <= ob[3] and not inside_target:
            print(f"occluded by {oid} at {cx},{cy}", file=sys.stderr)
            sys.exit(3)
    return node


def cmd_ls(path):
    for n in _load(path).iter():
        box = _box(n)
        if not box:
            continue
        rid = n.attrib.get("resource-id", "")
        label = _label(n).replace("\n", " / ")
        is_edit = "EditText" in n.attrib.get("class", "")
        if not (rid or label or is_edit):
            continue
        flags = []
        if n.attrib.get("checkable") == "true":
            flags.append("checked" if n.attrib.get("checked") == "true" else "unchecked")
        if is_edit:
            flags.append("edit")
            if n.attrib.get("focused") == "true":
                flags.append("focused")
            if n.attrib.get("password") == "true":
                flags.append("password")
        if n.attrib.get("enabled") == "false":
            flags.append("disabled")
        x, y = (box[0] + box[2]) // 2, (box[1] + box[3]) // 2
        tail = f"  {{{','.join(flags)}}}" if flags else ""
        print(f"{x},{y}  {rid or '-'} | {label}{tail}")


def cmd_find(path, selector):
    x1, y1, x2, y2 = _box(_checked_node(path, selector))
    print(f"{(x1 + x2) // 2} {(y1 + y2) // 2}")


def cmd_bounds(path, selector):
    print(" ".join(str(v) for v in _box(_checked_node(path, selector))))


def cmd_get(path, selector):
    node = _select(_load(path), selector)
    if node is None:
        sys.exit(1)
    print(_label(node).replace("\n", " / "))
    for child in node.iter():
        if child is not node and "EditText" in child.attrib.get("class", ""):
            print(child.attrib.get("text", ""))


def cmd_usable(path):
    try:
        root = _load(path)
    except (ValueError, ET.ParseError, OSError):
        sys.exit(1)
    allowed = _allowed()
    for n in root.iter():
        if allowed and n.attrib.get("package", "") not in allowed:
            continue
        rid = n.attrib.get("resource-id", "")
        if (rid and not rid.startswith("android:id/content")) or _label(n):
            sys.exit(0)
    sys.exit(1)


def _state(root):
    nodes = [n for n in root.iter() if _box(n)]
    width = max((_box(n)[2] for n in nodes), default=1080)
    height = max((_box(n)[3] for n in nodes), default=2400)
    ids = {n.attrib.get("resource-id", "") for n in nodes}
    nav = any(i.startswith("nav-") for i in ids)
    back = False
    content = []
    for n in nodes:
        b = _box(n)
        lab = _label(n)
        if lab in BACK_LABELS and (b[1] + b[3]) // 2 < 420:
            back = True
        rid = n.attrib.get("resource-id", "")
        if rid.startswith("android:id/") or (b[2] - b[0] >= width and b[3] - b[1] >= height * 0.9):
            continue
        if rid or lab or n.attrib.get("clickable") == "true" or "EditText" in n.attrib.get("class", ""):
            content.append(b)
    modal = False
    if content:
        u = (min(b[0] for b in content), min(b[1] for b in content),
             max(b[2] for b in content), max(b[3] for b in content))
        # The smallest node that holds all the content is the route's frame:
        # a dialog card is inset from both edges, a sheet starts low with no
        # app bar and no nav bar above it. (Labels alone are narrower than the
        # screen on ordinary pages, so they can't decide this.)
        frames = [b for b in (_box(n) for n in nodes)
                  if b[0] <= u[0] and b[1] <= u[1] and b[2] >= u[2] and b[3] >= u[3]]
        fx1, fy1, fx2, _ = min(frames, key=lambda b: (b[2] - b[0]) * (b[3] - b[1]))
        if fx2 - fx1 < width * 0.9:
            modal = True
        elif not nav and not back and fy1 > height * 0.3:
            modal = True
    edit = next((n for n in nodes if "EditText" in n.attrib.get("class", "")
                 and n.attrib.get("focused") == "true"), None)
    return {
        "nodes": len(nodes),
        "nav": int(nav),
        "modal": int(modal),
        "back": int(back),
        "edit": int(edit is not None),
        "password": int(edit is not None and edit.attrib.get("password") == "true"),
    }


def cmd_state(path):
    for k, v in _state(_load(path)).items():
        print(f"{k}={v}")


# --- screens -----------------------------------------------------------------

def _is_red(r, g, b):
    # Flutter's debug ErrorWidget: 0xF0900000 over the page, (137,2,1) on the
    # dark theme, about (150,15,15) on the light one. Material error colours
    # carry more green/blue than this.
    return 120 <= r <= 165 and g <= 20 and b <= 20 and abs(g - b) <= 10


def _red_fraction_rows(rows, bpp, step=4):
    hit = total = 0
    for row in rows[::step]:
        rs, gs, bs = row[0::bpp * step], row[1::bpp * step], row[2::bpp * step]
        for r, g, b in zip(rs, gs, bs):
            total += 1
            if _is_red(r, g, b):
                hit += 1
    return hit / total if total else 0.0


def _write_png(path, width, height, rows_rgb):
    def chunk(tag, body):
        return (len(body).to_bytes(4, "big") + tag + body
                + zlib.crc32(tag + body).to_bytes(4, "big"))
    raw = b"".join(b"\x00" + bytes(r) for r in rows_rgb)
    ihdr = width.to_bytes(4, "big") + height.to_bytes(4, "big") + bytes([8, 2, 0, 0, 0])
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr)
                + chunk(b"IDAT", zlib.compress(raw, 3)) + chunk(b"IEND", b""))


def cmd_screen(raw_path, out):
    data = open(raw_path, "rb").read()
    if len(data) < 16:
        raise SystemExit("screen: empty capture")
    w = int.from_bytes(data[0:4], "little")
    h = int.from_bytes(data[4:8], "little")
    header = len(data) - w * h * 4
    if w <= 0 or h <= 0 or header not in (12, 16):
        raise SystemExit(f"screen: unexpected raw format ({w}x{h}, header {header})")
    px = memoryview(data)[header:]
    stride = w * 4
    rows = [px[y * stride:(y + 1) * stride] for y in range(h)]
    frac = _red_fraction_rows(rows, 4)
    if out != "-":
        rgb_rows = []
        for r in rows:
            line = bytearray(w * 3)
            line[0::3] = r[0::4]
            line[1::3] = r[1::4]
            line[2::3] = r[2::4]
            rgb_rows.append(line)
        _write_png(out, w, h, rgb_rows)
    print(f"red={frac:.4f}")
    sys.exit(4 if frac >= RED_LIMIT else 0)


def _png_rows(path):
    data = open(path, "rb").read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise SystemExit("not a PNG")
    pos, idat, width, height, bpp = 8, b"", 0, 0, 3
    while pos < len(data):
        length = int.from_bytes(data[pos:pos + 4], "big")
        ctype = data[pos + 4:pos + 8]
        body = data[pos + 8:pos + 8 + length]
        if ctype == b"IHDR":
            width = int.from_bytes(body[0:4], "big")
            height = int.from_bytes(body[4:8], "big")
            depth, colour, interlace = body[8], body[9], body[12]
            if depth != 8 or colour not in (2, 6) or interlace:
                raise SystemExit("unsupported PNG (need 8-bit RGB/RGBA, no interlace)")
            bpp = 4 if colour == 6 else 3
        elif ctype == b"IDAT":
            idat += body
        pos += 12 + length
    raw = zlib.decompress(idat)
    stride = width * bpp
    prev = bytearray(stride)
    rows = []
    for row in range(height):
        start = row * (stride + 1)
        ftype = raw[start]
        line = bytearray(raw[start + 1:start + 1 + stride])
        if ftype == 2:
            line = bytearray((a + b) & 0xFF for a, b in zip(line, prev))
        elif ftype in (1, 3, 4):
            for i in range(stride):
                a = line[i - bpp] if i >= bpp else 0
                b = prev[i]
                c = prev[i - bpp] if i >= bpp else 0
                if ftype == 1:
                    line[i] = (line[i] + a) & 0xFF
                elif ftype == 3:
                    line[i] = (line[i] + ((a + b) >> 1)) & 0xFF
                else:
                    p = a + b - c
                    pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                    pred = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
                    line[i] = (line[i] + pred) & 0xFF
        rows.append(line)
        prev = line
    return rows, bpp


def cmd_redpng(path):
    rows, bpp = _png_rows(path)
    frac = _red_fraction_rows(rows, bpp)
    print(f"red={frac:.4f}")
    sys.exit(4 if frac >= RED_LIMIT else 0)


def cmd_pixel(path, x, y):
    rows, bpp = _png_rows(path)
    x, y = int(x), int(y)
    r, g, b = rows[y][x * bpp:x * bpp + 3]
    h, l, _ = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
    print(f"{r} {g} {b} hue={round(h * 360)} lum={round(l * 255)}")


# --- logs --------------------------------------------------------------------

# threadtime: "10-22 13:05:01.123  1234  1250 E AndroidRuntime: FATAL EXCEPTION: main"
LINE = re.compile(r"^\S+ \S+\s+(\d+)\s+\d+ ([VDIWEFA]) ([^:]*?)\s*: ?(.*)$")
FLUTTER_ERR = re.compile(r"EXCEPTION CAUGHT BY|Another exception was thrown|Unhandled Exception|"
                         r"Failed assertion")


def _scan(lines, pkg):
    """Findings for PKG only. uiautomator, am and input run as app_process and
    log AndroidRuntime START / Calling main entry / Shutting down VM, and now
    and then a FATAL EXCEPTION of their own: those name another process and are
    dropped."""
    out = []
    pending = {}            # pid -> FATAL line waiting for its Process: line
    for line in lines:
        m = LINE.match(line)
        if not m:
            continue
        pid, _level, tag, msg = m.groups()
        if tag == "AndroidRuntime":
            if msg.startswith("FATAL EXCEPTION"):
                pending[pid] = line
            elif msg.startswith("Process: ") and pid in pending:
                first = pending.pop(pid)
                proc = msg[len("Process: "):].split(",")[0].strip()
                if proc == pkg or proc.startswith(pkg + ":"):
                    out.append(("CRASH", first))
        elif tag in ("DEBUG", "libc", "crash_dump64", "crash_dump32") and f">>> {pkg} <<<" in msg:
            out.append(("CRASH", line))
        elif tag == "ActivityManager" and (msg.startswith(f"ANR in {pkg}")
                                           or (msg.startswith("ANR in") and f" {pkg} " in msg + " ")):
            out.append(("ANR", line))
        elif tag == "flutter" and FLUTTER_ERR.search(msg):
            out.append(("FLUTTER", line))
    return out, pending


def cmd_logscan(path, offset, pkg):
    offset = int(offset)
    try:
        with open(path, "rb") as f:
            f.seek(offset)
            chunk = f.read()
    except OSError:
        print(f"offset={offset}")
        return
    end = chunk.rfind(b"\n")
    if end == -1:
        print(f"offset={offset}")
        return
    text = chunk[:end + 1].decode("utf-8", "replace")
    lines = text.splitlines()
    findings, pending = _scan(lines, pkg)
    consumed = end + 1
    if pending:
        # A FATAL whose Process: line hasn't been written yet: rescan from it.
        first = min(text.find(p) for p in pending.values())
        consumed = len(text[:first].encode("utf-8"))
    for kind, line in findings:
        print(f"{kind} {line}")
    print(f"offset={offset + consumed}")


def cmd_crashscan(pkg):
    findings, _ = _scan(sys.stdin.read().splitlines(), pkg)
    for kind, line in findings:
        print(f"{kind} {line}")
    sys.exit(0 if any(k in ("CRASH", "ANR") for k, _ in findings) else 1)


# --- key file ----------------------------------------------------------------

def _key(path):
    try:
        raw = open(path, "rb").read()
    except OSError:
        return None
    return raw.strip()


def cmd_keycheck(path):
    if not os.path.isfile(path):
        sys.exit(10)
    raw = open(path, "rb").read()
    key = raw.strip()
    if not key:
        sys.exit(10)
    if PLACEHOLDER in raw:
        sys.exit(11)
    # Exactly the key plus at most one "\n": `read -r k` on the phone must get
    # the key and nothing else (no "\r", no second line).
    if not KEY_RE.match(key) or raw not in (key, key + b"\n"):
        sys.exit(12)
    if stat.S_IMODE(os.stat(path).st_mode) & 0o077:
        sys.exit(13)
    sys.exit(0)


def cmd_textcheck(path, text):
    key = _key(path)
    if key and len(key) >= 8 and key.decode("ascii", "replace") in text:
        sys.exit(1)
    if LOOKS_LIKE_KEY.search(text):
        sys.exit(1)
    sys.exit(0)


def cmd_secretlen(path, dump):
    key = _key(path) or b""
    nodes = [n for n in _load(dump).iter() if "EditText" in n.attrib.get("class", "")
             and n.attrib.get("focused") == "true"]
    if len(nodes) != 1:
        sys.exit(1)
    shown = nodes[0].attrib.get("text", "")
    ok = (nodes[0].attrib.get("password") == "true"
          and len(shown) == len(key) and set(shown) <= {"•", "*", "•"})
    sys.exit(0 if ok else 1)


def cmd_audit(path, root):
    key = _key(path)
    if not key or len(key) < 8:
        raise SystemExit("audit: no usable key to look for")
    hits = []
    for d, _, files in os.walk(root):
        for name in files:
            p = os.path.join(d, name)
            try:
                with open(p, "rb") as f:
                    tail = b""
                    while True:
                        block = f.read(1 << 22)
                        if not block:
                            break
                        if key in tail + block:
                            hits.append(p)
                            break
                        tail = block[-len(key):]
            except OSError:
                continue
    for p in hits:
        print(f"KEY FOUND IN {p}")
    sys.exit(1 if hits else 0)


COMMANDS = {
    "ls": cmd_ls, "find": cmd_find, "bounds": cmd_bounds, "get": cmd_get,
    "usable": cmd_usable, "state": cmd_state, "screen": cmd_screen,
    "redpng": cmd_redpng, "pixel": cmd_pixel, "logscan": cmd_logscan,
    "crashscan": cmd_crashscan, "keycheck": cmd_keycheck, "textcheck": cmd_textcheck,
    "secretlen": cmd_secretlen, "audit": cmd_audit,
}

if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] not in COMMANDS:
        raise SystemExit(__doc__)
    try:
        COMMANDS[sys.argv[1]](*sys.argv[2:])
    except TypeError:
        raise SystemExit(__doc__)
    except (ValueError, ET.ParseError) as e:
        print(f"ui.py: {e}", file=sys.stderr)
        sys.exit(1)
