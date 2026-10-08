"""Quick front-view (looking down -Z) SVG preview of a .rbxmx so proportions can be sanity-checked
without opening Studio. Usage: python preview.py Cactus.rbxmx"""
import sys
import xml.dom.minidom as m

src = sys.argv[1]
doc = m.parse(src)
shapes = []
for item in doc.getElementsByTagName("Item"):
    if item.getAttribute("class") != "Part":
        continue
    props = {}
    for el in item.getElementsByTagName("Properties")[0].childNodes:
        if el.nodeType != el.ELEMENT_NODE:
            continue
        props[el.getAttribute("name")] = el
    def num(el, tag):
        return float(el.getElementsByTagName(tag)[0].firstChild.data)
    cf = props["CFrame"]; sz = props["size"]
    x, y, z = num(cf, "X"), num(cf, "Y"), num(cf, "Z")
    sx, sy, sz_ = num(sz, "X"), num(sz, "Y"), num(sz, "Z")
    rot = num(cf, "R01") != 0          # our upright rotation swaps X and Y extents
    w, h = (sy, sx) if rot else (sx, sy)
    shape = int(props["shape"].firstChild.data)
    if any(c.getAttribute("class") == "SpecialMesh" for c in item.getElementsByTagName("Item")):
        shape = 0
    c = int(props["Color3uint8"].firstChild.data)
    col = f"rgb({(c>>16)&255},{(c>>8)&255},{c&255})"
    shapes.append((z, x, y, w, h, shape, col, sz_))

shapes.sort(key=lambda s: s[0])   # paint back to front
S = 40  # px per stud
minx = min(s[1] - s[3]/2 for s in shapes) - 0.5
maxx = max(s[1] + s[3]/2 for s in shapes) + 0.5
maxy = max(s[2] + s[4]/2 for s in shapes) + 0.5
W, H = (maxx - minx) * S, (maxy + 0.5) * S
out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W:.0f}" height="{H:.0f}" viewBox="0 0 {W:.0f} {H:.0f}">',
       f'<rect width="100%" height="100%" fill="#cfe8ff"/>',
       f'<rect y="{H - 0.5*S}" width="100%" height="{0.5*S}" fill="#e8d3a0"/>']
for z, x, y, w, h, shape, col, d in shapes:
    px, py = (x - minx) * S, (maxy - y) * S
    if shape == 0:     # ball
        out.append(f'<ellipse cx="{px}" cy="{py}" rx="{w/2*S}" ry="{h/2*S}" fill="{col}" stroke="#333" stroke-width="1"/>')
    else:
        r = 0 if shape == 1 else min(w, h) / 2 * S * 0.5
        out.append(f'<rect x="{px - w/2*S}" y="{py - h/2*S}" width="{w*S}" height="{h*S}" rx="{r}" fill="{col}" stroke="#333" stroke-width="1"/>')
out.append("</svg>")
dst = src.rsplit(".", 1)[0] + "_preview.svg"
open(dst, "w").write("\n".join(out))
print("wrote", dst, f"{len(shapes)} parts")
