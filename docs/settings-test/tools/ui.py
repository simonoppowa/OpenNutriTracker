#!/usr/bin/env python3
"""uiautomator dump reader and screenshot pixel probe for the settings run.

Stdlib only. Run with `python3 -I` so nothing next to the dump is imported.

  ui.py ls DUMP                 every node worth tapping, one per line:
                                `x,y  resource-id | text-or-desc  {flags}`
  ui.py find DUMP SELECTOR      centre "x y" of the first match (exit 1 if none)
  ui.py bounds DUMP SELECTOR    "x1 y1 x2 y2" of the first match
  ui.py get DUMP SELECTOR       the match's text/content-desc, then the text of
                                every EditText inside it (one per line)
  ui.py pixel PNG X Y           "r g b hue lum" at X,Y of a screencap PNG

SELECTOR is one of
  id=RESOURCE_ID        exact resource-id (a Semantics(identifier:))
  text=LABEL            exact text or content-desc
  text~=FRAGMENT        text or content-desc contains FRAGMENT (case-sensitive)
  text^=PREFIX          text or content-desc starts with PREFIX (merged Flutter
                        tiles read "Title\nSubtitle", so match the title)
  edit=N                the N-th EditText on screen, 1-based, top to bottom
and may end in @K to take the K-th match instead of the first (1-based).
"""
import colorsys
import re
import sys
import xml.etree.ElementTree as ET
import zlib

BOUNDS = re.compile(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]")


def _load(path):
    raw = open(path, "rb").read()
    end = raw.rfind(b"</hierarchy>")
    if end != -1:
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
    d = node.attrib.get("content-desc", "")
    return t if t else d


def _matches(node, kind, value):
    if kind == "id":
        return node.attrib.get("resource-id", "") == value
    if kind == "text":
        return value in (node.attrib.get("text", ""), node.attrib.get("content-desc", ""))
    if kind == "text~":
        return value in node.attrib.get("text", "") or value in node.attrib.get("content-desc", "")
    if kind == "text^":
        return node.attrib.get("text", "").startswith(value) or node.attrib.get(
            "content-desc", ""
        ).startswith(value)
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
    if selector.startswith("text~="):
        kind, value = "text~", selector[6:]
    elif selector.startswith("text^="):
        kind, value = "text^", selector[6:]
    elif "=" in selector:
        kind, value = selector.split("=", 1)
    else:
        raise SystemExit(f"bad selector: {selector}")
    hits = [n for n in root.iter() if _box(n) and _matches(n, kind, value)]
    return hits[nth - 1] if len(hits) >= nth else None


def cmd_ls(path):
    root = _load(path)
    for n in root.iter():
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
        if n.attrib.get("enabled") == "false":
            flags.append("disabled")
        x = (box[0] + box[2]) // 2
        y = (box[1] + box[3]) // 2
        head = rid if rid else "-"
        tail = f"  {{{','.join(flags)}}}" if flags else ""
        print(f"{x},{y}  {head} | {label}{tail}")


def cmd_find(path, selector):
    node = _select(_load(path), selector)
    if node is None:
        sys.exit(1)
    x1, y1, x2, y2 = _box(node)
    print(f"{(x1 + x2) // 2} {(y1 + y2) // 2}")


def cmd_bounds(path, selector):
    node = _select(_load(path), selector)
    if node is None:
        sys.exit(1)
    print(" ".join(str(v) for v in _box(node)))


def cmd_get(path, selector):
    node = _select(_load(path), selector)
    if node is None:
        sys.exit(1)
    print(_label(node).replace("\n", " / "))
    for child in node.iter():
        if child is not node and "EditText" in child.attrib.get("class", ""):
            print(child.attrib.get("text", ""))


def _png_pixel(path, x, y):
    data = open(path, "rb").read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise SystemExit("not a PNG")
    pos, idat, width = 8, b"", 0
    while pos < len(data):
        length = int.from_bytes(data[pos:pos + 4], "big")
        ctype = data[pos + 4:pos + 8]
        body = data[pos + 8:pos + 8 + length]
        if ctype == b"IHDR":
            width = int.from_bytes(body[0:4], "big")
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
    for row in range(y + 1):
        start = row * (stride + 1)
        ftype = raw[start]
        line = bytearray(raw[start + 1:start + 1 + stride])
        for i in range(stride):
            a = line[i - bpp] if i >= bpp else 0
            b = prev[i]
            c = prev[i - bpp] if i >= bpp else 0
            if ftype == 1:
                line[i] = (line[i] + a) & 0xFF
            elif ftype == 2:
                line[i] = (line[i] + b) & 0xFF
            elif ftype == 3:
                line[i] = (line[i] + ((a + b) >> 1)) & 0xFF
            elif ftype == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pred = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
                line[i] = (line[i] + pred) & 0xFF
        prev = line
    r, g, b = prev[x * bpp], prev[x * bpp + 1], prev[x * bpp + 2]
    return r, g, b


def cmd_pixel(path, x, y):
    r, g, b = _png_pixel(path, int(x), int(y))
    h, l, _ = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
    print(f"{r} {g} {b} hue={round(h * 360)} lum={round(l * 255)}")


def main(argv):
    if len(argv) < 3:
        raise SystemExit(__doc__)
    cmd, path = argv[1], argv[2]
    if cmd == "ls":
        cmd_ls(path)
    elif cmd == "find":
        cmd_find(path, argv[3])
    elif cmd == "bounds":
        cmd_bounds(path, argv[3])
    elif cmd == "get":
        cmd_get(path, argv[3])
    elif cmd == "pixel":
        cmd_pixel(path, argv[3], argv[4])
    else:
        raise SystemExit(__doc__)


if __name__ == "__main__":
    main(sys.argv)
