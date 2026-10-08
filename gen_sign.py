"""
Area 51 neon sign as a textured mesh for Roblox Studio (Import 3D).

Outputs, next to this script:
  area51_sign.obj / .mtl     board, frame, posts, neon letters and tubes, each its own object
  area51_sign_texture.png    texture atlas (board, panel, metal, neon colors)
  sign_neon_setup.lua        paste into Studio's command bar after import: turns the Neon*
                             objects into real Neon, adds lights, and sets up dusk + bloom
  preview_sign.html          3D preview

Run:  python gen_sign.py
Import in Studio:  Home tab > Import (Import 3D) > area51_sign.obj, Merge Meshes OFF

Letters are cut from a real bold font (Segoe UI Black) with rounded corners and extruded,
so they read as chunky sign lettering rather than piped tubes.
"""
import base64
import math
from pathlib import Path

import numpy as np
import mapbox_earcut as earcut
from fontTools.ttLib import TTFont
from fontTools.pens.basePen import BasePen
from PIL import Image, ImageDraw, ImageFilter

from gen_mesh import add, sub, mul, dot, cross, length, norm, lathe, blob, grain, paint_gradient

OUT = Path(__file__).parent
TEX = 512
FONT = Path("C:/Windows/Fonts/seguibl.ttf")     # Segoe UI Black; swap for any bold .ttf
TEXT = "AREA 51"

# ---------------------------------------------------------------- obj -----
class Obj:
    def __init__(self):
        self.v, self.vt, self.vn, self.objects = [], [], [], []

    def add_smooth(self, name, verts, uvs, faces, center_fn):
        keys = [(round(p[0], 4), round(p[1], 4), round(p[2], 4)) for p in verts]
        acc, flip = {}, 0
        for a, b, c in faces:
            pa, pb, pc = verts[a], verts[b], verts[c]
            fn = cross(sub(pb, pa), sub(pc, pa))
            cen = mul(add(add(pa, pb), pc), 1 / 3)
            flip += 1 if dot(fn, sub(cen, center_fn(cen))) >= 0 else -1
            for i in (a, b, c):
                acc[keys[i]] = add(acc.get(keys[i], (0, 0, 0)), fn)
        sign = 1 if flip >= 0 else -1
        if sign < 0:
            faces = [(a, c, b) for a, b, c in faces]
        normals = [norm(mul(acc[k], sign)) for k in keys]
        self._push(name, verts, uvs, normals, faces)

    def add_flat(self, name, tris, center=None):
        """tris: list of ((p0,uv0),(p1,uv1),(p2,uv2)). If center is given, each triangle is
        flipped to face away from it; otherwise the given winding is trusted (CCW = front)."""
        verts, uvs, normals, faces = [], [], [], []
        for tri in tris:
            (p0, t0), (p1, t1), (p2, t2) = tri
            fn = cross(sub(p1, p0), sub(p2, p0))
            if center is not None:
                cen = mul(add(add(p0, p1), p2), 1 / 3)
                if dot(fn, sub(cen, center)) < 0:
                    p1, t1, p2, t2 = p2, t2, p1, t1
                    fn = mul(fn, -1)
            if length(fn) < 1e-9:
                continue
            n = norm(fn); b = len(verts)
            verts += [p0, p1, p2]; uvs += [t0, t1, t2]; normals += [n, n, n]
            faces.append((b, b + 1, b + 2))
        self._push(name, verts, uvs, normals, faces)

    def _push(self, name, verts, uvs, normals, faces):
        base = len(self.v)
        self.v += verts; self.vt += uvs; self.vn += normals
        self.objects.append((name, [(a + base, b + base, c + base) for a, b, c in faces]))

    def write(self, path, texture_name):
        lines = [f"mtllib {Path(path).with_suffix('.mtl').name}"]
        lines += [f"v {x:.4f} {y:.4f} {z:.4f}" for x, y, z in self.v]
        lines += [f"vt {u:.5f} {v:.5f}" for u, v in self.vt]
        lines += [f"vn {x:.4f} {y:.4f} {z:.4f}" for x, y, z in self.vn]
        for name, faces in self.objects:
            lines += [f"o {name}", f"g {name}", f"usemtl m_{name}", "s 1"]
            lines += [f"f {a+1}/{a+1}/{a+1} {b+1}/{b+1}/{b+1} {c+1}/{c+1}/{c+1}" for a, b, c in faces]
        Path(path).write_text("\n".join(lines) + "\n", encoding="utf-8")
        mtl = "".join(f"newmtl m_{name}\nKd 1 1 1\nKa 1 1 1\nKs 0 0 0\nd 1\nillum 1\nmap_Kd {texture_name}\n\n" for name, _ in self.objects)
        Path(path).with_suffix(".mtl").write_text(mtl, encoding="utf-8")
        return sum(len(f) for _, f in self.objects)

# ------------------------------------------------------------ 2D tools ----
def signed_area(poly):
    return 0.5 * sum(poly[i][0] * poly[(i + 1) % len(poly)][1] - poly[(i + 1) % len(poly)][0] * poly[i][1] for i in range(len(poly)))

def point_in_poly(pt, poly):
    x, y = pt; inside = False
    for i in range(len(poly)):
        (x0, y0), (x1, y1) = poly[i], poly[(i + 1) % len(poly)]
        if (y0 > y) != (y1 > y) and x < (x1 - x0) * (y - y0) / (y1 - y0) + x0:
            inside = not inside
    return inside

def dedupe(poly, eps=1e-4):
    out = []
    for p in poly:
        if not out or math.hypot(p[0] - out[-1][0], p[1] - out[-1][1]) > eps:
            out.append(p)
    if len(out) > 1 and math.hypot(out[0][0] - out[-1][0], out[0][1] - out[-1][1]) <= eps:
        out.pop()
    return out

def round_corners(poly, r, steps=5):
    """Replace every corner with a small quadratic arc, like CSS border-radius."""
    n = len(poly); out = []
    for i in range(n):
        p, v, q = poly[i - 1], poly[i], poly[(i + 1) % n]
        e1 = (p[0] - v[0], p[1] - v[1]); e2 = (q[0] - v[0], q[1] - v[1])
        l1, l2 = math.hypot(*e1), math.hypot(*e2)
        if l1 < 1e-9 or l2 < 1e-9:
            continue
        d = min(r, l1 / 2, l2 / 2)
        a = (v[0] + e1[0] / l1 * d, v[1] + e1[1] / l1 * d)
        b = (v[0] + e2[0] / l2 * d, v[1] + e2[1] / l2 * d)
        for k in range(steps + 1):
            t = k / steps
            out.append(((1 - t) ** 2 * a[0] + 2 * (1 - t) * t * v[0] + t * t * b[0],
                        (1 - t) ** 2 * a[1] + 2 * (1 - t) * t * v[1] + t * t * b[1]))
    return dedupe(out)

def shapes_from_contours(contours):
    """Group contours into (outer, [holes]) with outer CCW and holes CW."""
    contours = [dedupe(c) for c in contours if len(c) >= 3]
    depth = []
    for i, c in enumerate(contours):
        depth.append(sum(1 for j, o in enumerate(contours) if j != i and point_in_poly(c[0], o)))
    shapes = []
    for i, c in enumerate(contours):
        if depth[i] % 2 == 0:
            outer = c if signed_area(c) > 0 else c[::-1]
            holes = []
            for j, h in enumerate(contours):
                if depth[j] == depth[i] + 1 and point_in_poly(h[0], c):
                    holes.append(h if signed_area(h) < 0 else h[::-1])
            shapes.append((outer, holes))
    return shapes

def extrude_shape(outer, holes, z0, z1, uv, uv_side=None):
    """Prism from a polygon with holes. Returns tris with correct CCW-out winding."""
    uv_side = uv_side or uv
    rings = [outer] + holes
    flat = np.array([p for ring in rings for p in ring], dtype=np.float64)
    ends = np.cumsum([len(r) for r in rings]).astype(np.uint32)
    idx = earcut.triangulate_float64(flat, ends)
    xs, ys = flat[:, 0], flat[:, 1]
    minx, maxx, miny, maxy = xs.min(), xs.max(), ys.min(), ys.max()
    u0, u1, v0, v1 = uv
    def fuv(p):
        return (u0 + (u1 - u0) * (p[0] - minx) / max(maxx - minx, 1e-9), v0 + (v1 - v0) * (p[1] - miny) / max(maxy - miny, 1e-9))
    su = ((uv_side[0] + uv_side[1]) / 2, (uv_side[2] + uv_side[3]) / 2)
    tris = []
    for k in range(0, len(idx), 3):
        a, b, c = (flat[idx[k]], flat[idx[k + 1]], flat[idx[k + 2]])
        ccw = (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0]) > 0
        if not ccw:
            b, c = c, b
        tris.append((((a[0], a[1], z1), fuv(a)), ((b[0], b[1], z1), fuv(b)), ((c[0], c[1], z1), fuv(c))))   # front +z
        tris.append((((a[0], a[1], z0), fuv(a)), ((c[0], c[1], z0), fuv(c)), ((b[0], b[1], z0), fuv(b))))   # back -z
    for ring in rings:   # outer CCW / holes CW: (dy,-dx) points out of the solid in both cases
        m = len(ring)
        for i in range(m):
            a, b = ring[i], ring[(i + 1) % m]
            a0, a1, b0, b1 = (a[0], a[1], z0), (a[0], a[1], z1), (b[0], b[1], z0), (b[0], b[1], z1)
            tris.append(((a0, su), (b0, su), (b1, su)))
            tris.append(((a0, su), (b1, su), (a1, su)))
    return tris

def rounded_rect(w, h, r, cx=0.0, cy=0.0, point=0.0, point_w=0.0, n=7):
    """CCW outline. point > 0 adds a downward chevron in the bottom edge."""
    pts = []
    def arc(cxa, cya, a0, a1):
        for i in range(n + 1):
            a = a0 + (a1 - a0) * i / n
            pts.append((cxa + r * math.cos(a), cya + r * math.sin(a)))
    arc(cx + w / 2 - r, cy - h / 2 + r, -math.pi / 2, 0)
    arc(cx + w / 2 - r, cy + h / 2 - r, 0, math.pi / 2)
    arc(cx - w / 2 + r, cy + h / 2 - r, math.pi / 2, math.pi)
    arc(cx - w / 2 + r, cy - h / 2 + r, math.pi, 1.5 * math.pi)
    if point > 0:
        pts += [(cx - point_w / 2, cy - h / 2), (cx, cy - h / 2 - point), (cx + point_w / 2, cy - h / 2)]
    return dedupe(pts)

def box(cx, cy, cz, sx, sy, sz, uv):
    o = [(cx - sx / 2, cy - sy / 2), (cx + sx / 2, cy - sy / 2), (cx + sx / 2, cy + sy / 2), (cx - sx / 2, cy + sy / 2)]
    return extrude_shape(o, [], cz - sz / 2, cz + sz / 2, uv)

def tube(path, radius, segs, uv, closed=False, cap_samples=5):
    pts = list(path)
    if closed:
        pts = pts + [pts[0], pts[1]]
    n = len(pts)
    tang = [norm(sub(pts[min(i + 1, n - 1)], pts[max(i - 1, 0)])) for i in range(n)]
    specs = []
    if not closed:
        T0 = tang[0]
        for k in range(cap_samples, 0, -1):
            phi = (math.pi / 2) * k / cap_samples
            specs.append((sub(pts[0], mul(T0, radius * math.sin(phi))), T0, math.cos(phi)))
    specs += [(pts[i], tang[i], 1.0) for i in range(n)]
    if not closed:
        T1 = tang[-1]
        for k in range(1, cap_samples + 1):
            phi = (math.pi / 2) * k / cap_samples
            specs.append((add(pts[-1], mul(T1, radius * math.sin(phi))), T1, math.cos(phi)))
    B = (0.0, 0.0, 1.0)
    cu, cv = (uv[0] + uv[1]) / 2, (uv[2] + uv[3]) / 2
    rings = []
    for p, t, sc in specs:
        N = norm(cross(B, t)); r = radius * sc
        ring = [add(p, add(mul(N, r * math.cos(2 * math.pi * j / segs)), mul(B, r * math.sin(2 * math.pi * j / segs)))) for j in range(segs + 1)]
        rings.append((ring, [(cu, cv)] * (segs + 1), sc < 1e-6))
    if closed:
        rings = rings[:-1]
    return lathe(rings)

# ------------------------------------------------------------- font -------
class FlattenPen(BasePen):
    def __init__(self, glyphSet, steps=6):
        super().__init__(glyphSet); self.contours, self.cur, self.steps = [], [], steps
    def _moveTo(self, p): self.cur = [p]
    def _lineTo(self, p): self.cur.append(p)
    def _qCurveToOne(self, p1, p2):
        p0 = self.cur[-1]
        for k in range(1, self.steps + 1):
            t = k / self.steps
            self.cur.append(((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0],
                             (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]))
    def _curveToOne(self, p1, p2, p3):
        p0 = self.cur[-1]
        for k in range(1, self.steps + 1):
            t = k / self.steps
            self.cur.append(((1 - t) ** 3 * p0[0] + 3 * (1 - t) ** 2 * t * p1[0] + 3 * (1 - t) * t * t * p2[0] + t ** 3 * p3[0],
                             (1 - t) ** 3 * p0[1] + 3 * (1 - t) ** 2 * t * p1[1] + 3 * (1 - t) * t * t * p2[1] + t ** 3 * p3[1]))
    def _closePath(self):
        if len(self.cur) >= 3: self.contours.append(self.cur)
        self.cur = []
    def _endPath(self): self._closePath()

def text_shapes(text, font_path, cap_height, corner_r, tracking=0.06):
    """Returns (list of (outer, holes) in studs, total width). Text starts at x=0, baseline y=0."""
    font = TTFont(str(font_path))
    gs, cmap = font.getGlyphSet(), font.getBestCmap()
    upm = font["head"].unitsPerEm
    cap = font["OS/2"].sCapHeight if hasattr(font["OS/2"], "sCapHeight") and font["OS/2"].sCapHeight else upm * 0.7
    s = cap_height / cap
    x, shapes = 0.0, []
    for ch in text:
        g = gs[cmap[ord(ch)]]
        pen = FlattenPen(gs); g.draw(pen)
        contours = [[(x + px * s, py * s) for px, py in c] for c in pen.contours]
        for outer, holes in shapes_from_contours(contours):
            shapes.append((round_corners(outer, corner_r), [round_corners(h, corner_r) for h in holes]))
        x += g.width * s + tracking * cap_height
    return shapes, x - tracking * cap_height

# --------------------------------------------------------------- build ----
UV = {
    "board":  (0.00, 0.70, 0.50, 1.00),
    "panel":  (0.00, 0.70, 0.25, 0.50),
    "metal":  (0.70, 0.85, 0.75, 1.00),
    "post":   (0.85, 1.00, 0.50, 1.00),
    "rust":   (0.70, 0.85, 0.50, 0.75),
    "black":  (0.70, 0.85, 0.25, 0.50),
    "pink":   (0.00, 0.10, 0.00, 0.10),
    "cyan":   (0.10, 0.20, 0.00, 0.10),
    "white":  (0.20, 0.30, 0.00, 0.10),
    "yellow": (0.30, 0.40, 0.00, 0.10),
    "ice":    (0.40, 0.50, 0.00, 0.10),
    "glass":  (0.50, 0.60, 0.00, 0.10),
}
BOARD_W, BOARD_H, BOARD_R, BOARD_T = 10.5, 7.2, 0.9, 0.4
CHEV, CHEV_W = 0.9, 2.6
import sys
POST_H = float(sys.argv[1]) if len(sys.argv) > 1 else 5.8     # post height in studs (5.8 = original)
SIGN_Y = 6.4 + (POST_H - 5.8)
SUFFIX = sys.argv[2] if len(sys.argv) > 2 else ""
PANEL_W, PANEL_H, PANEL_Y = 9.0, 2.9, -1.55
ZF = BOARD_T / 2                     # board front face

def build():
    obj = Obj()
    Y = SIGN_Y

    # metal frame behind/around the board, then the board, then the raised text panel
    frame = rounded_rect(BOARD_W + 0.5, BOARD_H + 0.5, BOARD_R + 0.25, 0, Y, CHEV + 0.25, CHEV_W + 0.5)
    obj.add_flat("Frame", extrude_shape(frame, [], -ZF - 0.12, ZF - 0.06, UV["metal"]))
    board = rounded_rect(BOARD_W, BOARD_H, BOARD_R, 0, Y, CHEV, CHEV_W)
    obj.add_flat("Board", extrude_shape(board, [], -ZF, ZF, UV["board"], UV["metal"]))
    panel = rounded_rect(PANEL_W, PANEL_H, 0.5, 0, Y + PANEL_Y)
    obj.add_flat("Panel", extrude_shape(panel, [], ZF, ZF + 0.12, UV["panel"], UV["metal"]))
    thin = rounded_rect(PANEL_W - 0.3, PANEL_H - 0.3, 0.4, 0, Y + PANEL_Y, n=9)   # thin white neon line around the panel
    v, uv, f = tube([(x, y, ZF + 0.16) for x, y in thin], 0.045, 8, UV["white"], closed=True)
    obj.add_smooth("NeonWhite_PanelLine", v, uv, f, lambda p: (0.0, Y + PANEL_Y, ZF + 0.16))

    # rivets in the board corners
    for i, (rx, ry) in enumerate(((-4.65, 3.05), (4.65, 3.05), (-4.65, -3.05), (4.65, -3.05), (-4.65, 0), (4.65, 0))):
        c = (rx, Y + ry, ZF)
        v, uv, f = blob(c, (0.13, 0.13, 0.07), 10, 5, UV["metal"])
        obj.add_smooth(f"Rivet{i+1}", v, uv, f, lambda p, c=c: c)

    # posts, crossbar, base plates
    zp = -ZF - 0.12 - 0.26
    for i, x in enumerate((-3.3, 3.3)):
        obj.add_flat(f"Post{i+1}", box(x, POST_H / 2, zp, 0.5, POST_H, 0.5, UV["post"]))
        obj.add_flat(f"Base{i+1}", box(x, 0.14, zp, 1.1, 0.28, 1.1, UV["rust"]))
    obj.add_flat("Crossbar", box(0, 1.6, zp, 6.6, 0.32, 0.32, UV["post"]))
    if POST_H > 8:
        board_bottom = SIGN_Y - BOARD_H / 2 - 0.25
        obj.add_flat("Crossbar2", box(0, board_bottom * 0.8, zp, 6.6, 0.32, 0.32, UV["post"]))

    # pink outline: haze slab, dark channel, then the tube
    inset = lambda d, n=9: rounded_rect(BOARD_W - 0.9 - 2 * d, BOARD_H - 0.9 - 2 * d, max(0.65 - d, 0.2), 0, Y,
                                       max(CHEV - 0.2 - d * 0.8, 0.1), max(CHEV_W - 0.5 - 1.6 * d, 0.6), n)
    obj.add_flat("Channel_Outline", extrude_shape(inset(-0.24), [inset(0.24)], ZF + 0.03, ZF + 0.10, UV["black"]))
    zo = ZF + 0.22
    v, uv, f = tube([(x, y, zo) for x, y in inset(0)], 0.15, 10, UV["pink"], closed=True)
    obj.add_smooth("NeonPink_Outline", v, uv, f, lambda p: (0.0, p[1], zo) if abs(p[0]) < 4.4 else (p[0] * 0.8, p[1], zo))

    # UFO: solid dark hull with a neon rim, glass dome with windows and shine, antenna,
    # under-lights and small motion arcs so it reads as a cartoon saucer
    ux, uy = 0.0, Y + 1.85
    zu = zo + 0.36            # in front of the pink outline tube
    ell = lambda rx, ry, n=48: [(rx * math.cos(2 * math.pi * i / n), ry * math.sin(2 * math.pi * i / n)) for i in range(n)]
    hull = [(ux + x, uy + y) for x, y in ell(2.3, 0.62)]
    obj.add_flat("UfoHull", extrude_shape(hull, [], zu - 0.14, zu + 0.02, UV["metal"]))
    under = [(ux + x, uy - 0.12 + y) for x, y in ell(1.5, 0.42)]
    obj.add_flat("UfoUnder", extrude_shape(under, [], zu - 0.18, zu - 0.13, UV["black"]))
    v, uv, f = tube([(ux + x, uy + y, zu + 0.05) for x, y in ell(2.3, 0.62)], 0.12, 10, UV["cyan"], closed=True)
    obj.add_smooth("NeonCyan_SaucerRim", v, uv, f, lambda p: (ux, uy, zu + 0.05))
    v, uv, f = tube([(ux - 1.9, uy + 0.05, zu + 0.08), (ux + 1.9, uy + 0.05, zu + 0.08)], 0.06, 8, UV["pink"])
    obj.add_smooth("NeonPink_SaucerBand", v, uv, f, lambda p: (ux, uy + 0.05, zu + 0.08))
    # glass dome (filled) with white neon outline, three windows, a shine and an antenna
    dome = [(ux + 1.05 * math.cos(math.pi * i / 20), uy + 0.42 + 1.0 * math.sin(math.pi * i / 20)) for i in range(21)]
    obj.add_flat("UfoDome", extrude_shape(dome, [], zu - 0.1, zu + 0.0, UV["glass"]))
    v, uv, f = tube([(x, y, zu + 0.05) for x, y in dome], 0.09, 10, UV["white"])
    obj.add_smooth("NeonWhite_Dome", v, uv, f, lambda p: (ux, uy + 0.42, zu + 0.05))
    for i, ang in enumerate((50, 90, 130)):
        cc = (ux + 0.62 * math.cos(math.radians(ang)), uy + 0.42 + 0.55 * math.sin(math.radians(ang)), zu + 0.05)
        v, uv, f = blob(cc, (0.12, 0.12, 0.12), 8, 5, UV["yellow"])
        obj.add_smooth(f"NeonYellow_Window{i+1}", v, uv, f, lambda p, c=cc: c)
    shine = [(ux - 0.72 + 0.35 * math.cos(math.radians(a)), uy + 0.42 + 0.78 + 0.25 * math.sin(math.radians(a))) for a in range(120, 200, 10)]
    v, uv, f = tube([(x, y, zu + 0.08) for x, y in shine], 0.05, 8, UV["white"])
    obj.add_smooth("NeonWhite_DomeShine", v, uv, f, lambda p: (ux, uy + 0.42, zu + 0.08))
    v, uv, f = tube([(ux, uy + 1.42, zu + 0.05), (ux, uy + 1.85, zu + 0.05)], 0.05, 8, UV["white"])
    obj.add_smooth("NeonWhite_Antenna", v, uv, f, lambda p: (ux, uy + 1.6, zu + 0.05))
    cc = (ux, uy + 1.95, zu + 0.05)
    v, uv, f = blob(cc, (0.13, 0.13, 0.13), 8, 5, UV["pink"])
    obj.add_smooth("NeonPink_AntennaTip", v, uv, f, lambda p, c=cc: c)
    # under-lights and motion arcs
    for i, (lx, col) in enumerate(((-1.25, "pink"), (0.0, "yellow"), (1.25, "pink"))):
        cc = (ux + lx, uy - 0.5, zu + 0.06)
        v, uv, f = blob(cc, (0.16, 0.16, 0.16), 10, 6, UV[col])
        obj.add_smooth(f"Neon{col.capitalize()}_UfoLight{i+1}", v, uv, f, lambda p, c=cc: c)
    for side in (-1, 1):
        for k, rad in enumerate((0.45, 0.8)):
            arc = [(ux + side * (2.35 + rad * math.cos(math.radians(a))), uy + rad * 0.9 * math.sin(math.radians(a))) for a in range(-40, 41, 10)]
            v, uv, f = tube([(x, y, zu + 0.05) for x, y in arc], 0.06, 8, UV["pink"])
            tag = "L" if side < 0 else "R"
            obj.add_smooth(f"NeonPink_Zip{tag}{k+1}", v, uv, f, lambda p, sx=ux + side * 2.35: (sx, uy, zu + 0.05))

    # AREA 51: solid rounded letters from a real font, with a cyan haze slab behind them
    shapes, width = text_shapes(TEXT, FONT, cap_height=1.7, corner_r=0.09)
    scale = min(1.0, (PANEL_W - 0.9) / width)
    ox, oy = -width * scale / 2, Y + PANEL_Y - 1.7 * scale / 2
    place = lambda poly: [(ox + x * scale, oy + y * scale) for x, y in poly]
    for i, (outer, holes) in enumerate(shapes):
        tris = extrude_shape(place(outer), [place(h) for h in holes], ZF + 0.16, ZF + 0.46, UV["ice"])
        obj.add_flat(f"NeonIce_Letter{i+1}", tris)
    return obj

# ------------------------------------------------------------- texture ----
def rbox(r):
    u0, u1, v0, v1 = r
    return int(u0 * TEX), int((1 - v1) * TEX), int(u1 * TEX), int((1 - v0) * TEX)

def paint():
    atlas = Image.new("RGB", (TEX, TEX), (30, 30, 30))
    # board: dark navy, worn, with a soft pink haze where the outline sits
    x0, y0, x1, y1 = rbox(UV["board"]); w, h = x1 - x0, y1 - y0
    b = grain(paint_gradient(w, h, (36, 40, 74), (20, 22, 44)), 0.12, 34).convert("RGBA")
    haze = Image.new("RGBA", (w, h), (0, 0, 0, 0)); d = ImageDraw.Draw(haze)
    sx, sy = w / BOARD_W, h / (BOARD_H + CHEV)
    cyp = (BOARD_H / 2) * sy
    iw, ih = (BOARD_W - 0.9) * sx, (BOARD_H - 0.9) * sy
    d.rounded_rectangle([w / 2 - iw / 2, cyp - ih / 2, w / 2 + iw / 2, cyp + ih / 2], radius=0.65 * sx, outline=(255, 70, 200, 120), width=int(0.6 * sx))
    d.polygon([(w / 2 - (CHEV_W - 0.5) / 2 * sx, cyp + ih / 2), (w / 2, cyp + ih / 2 + (CHEV - 0.2) * sy), (w / 2 + (CHEV_W - 0.5) / 2 * sx, cyp + ih / 2)],
              outline=(255, 70, 200, 120), width=int(0.6 * sx))
    haze = haze.filter(ImageFilter.GaussianBlur(w / 30))
    b.alpha_composite(haze)
    # scratches
    sd = ImageDraw.Draw(b)
    import random; rnd = random.Random(5)
    for _ in range(40):
        x, y = rnd.randint(0, w), rnd.randint(0, h); L = rnd.randint(10, 60); a = rnd.uniform(-0.4, 0.4)
        sd.line([(x, y), (x + L * math.cos(a), y + L * math.sin(a))], fill=(70, 74, 110, 90), width=1)
    atlas.paste(b.convert("RGB"), (x0, y0))

    # panel: deep blue with a cyan glow behind the letters
    x0, y0, x1, y1 = rbox(UV["panel"]); w, h = x1 - x0, y1 - y0
    p = grain(Image.new("RGB", (w, h), (10, 22, 58)), 0.06, 30).convert("RGBA")
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0)); g = ImageDraw.Draw(glow)
    g.rounded_rectangle([w * 0.02, h * 0.06, w * 0.98, h * 0.94], radius=h // 5, outline=(60, 200, 255, 120), width=max(3, w // 60))
    p.alpha_composite(glow.filter(ImageFilter.GaussianBlur(w / 40)))
    atlas.paste(p.convert("RGB"), (x0, y0))

    x0, y0, x1, y1 = rbox(UV["metal"]); atlas.paste(grain(paint_gradient(x1 - x0, y1 - y0, (96, 100, 112), (58, 60, 72)), 0.16, 40), (x0, y0))
    x0, y0, x1, y1 = rbox(UV["post"]); atlas.paste(grain(paint_gradient(x1 - x0, y1 - y0, (66, 58, 66), (38, 34, 42)), 0.2, 40), (x0, y0))
    x0, y0, x1, y1 = rbox(UV["rust"]); atlas.paste(grain(Image.new("RGB", (x1 - x0, y1 - y0), (118, 70, 50)), 0.25, 50), (x0, y0))
    x0, y0, x1, y1 = rbox(UV["black"]); atlas.paste(Image.new("RGB", (x1 - x0, y1 - y0), (14, 14, 18)), (x0, y0))
    for key, col in (("pink", (255, 70, 210)), ("cyan", (80, 235, 255)), ("white", (245, 250, 255)), ("yellow", (255, 220, 80)),
                     ("ice", (215, 250, 255)), ("glass", (120, 190, 225))):
        x0, y0, x1, y1 = rbox(UV[key]); atlas.paste(Image.new("RGB", (x1 - x0, y1 - y0), col), (x0, y0))
    return atlas

# ------------------------------------------------------------ lua + html --
LUA = r'''-- Area 51 sign: run once in Studio's Command Bar with the imported model SELECTED.
-- 1) Neon* pieces become glowing Neon in their color (Haze pieces become a soft transparent glow)
-- 2) everything is anchored and the neon gets pink/cyan PointLights
-- 3) yellow Highlight aura + spotlight; daytime is kept (restored if an old run set dusk)
local model = game.Selection:Get()[1]
assert(model and model:IsA("Model"), "Select the imported sign model first")
local colors = {
	Pink   = Color3.fromRGB(255, 70, 210),
	Cyan   = Color3.fromRGB(80, 235, 255),
	White  = Color3.fromRGB(245, 250, 255),
	Yellow = Color3.fromRGB(255, 220, 80),
	Ice    = Color3.fromRGB(215, 250, 255),
}
local board, panel
for _, p in ipairs(model:GetDescendants()) do
	if p:IsA("BasePart") then
		p.Anchored = true
		local tone = p.Name:match("^Neon(%a+)_")
		if tone and colors[tone] then
			p.Material = Enum.Material.Neon
			p.Color = colors[tone]
			p.TextureID = ""
			p.CanCollide = false
			p.CastShadow = false
		elseif p.Name == "UfoDome" then
			p.Material = Enum.Material.Glass
			p.Color = Color3.fromRGB(120, 190, 225)
			p.TextureID = ""
			p.Transparency = 0.35
		elseif p.Name:find("^Channel") then
			p.Material = Enum.Material.SmoothPlastic
			p.Color = Color3.fromRGB(14, 14, 18)
			p.TextureID = ""
			p.CanCollide = false
		end
		if p.Name == "Board" then board = p end
		if p.Name == "Panel" then panel = p end
	end
end
-- soft glow slabs: transparent Neon just in front of the panel and the board
local function haze(name, parent, size, offset, color, transparency)
	local old = model:FindFirstChild(name); if old then old:Destroy() end
	local h = Instance.new("Part")
	h.Name = name; h.Anchored = true; h.CanCollide = false; h.CastShadow = false
	h.Material = Enum.Material.Neon; h.Color = color; h.Transparency = transparency
	h.Size = size; h.CFrame = parent.CFrame * CFrame.new(offset)
	h.Parent = model
end
if panel then haze("TextGlow", panel, Vector3.new(panel.Size.X - 0.7, panel.Size.Y - 0.6, 0.04), Vector3.new(0, 0, panel.Size.Z / 2 + 0.03), colors.Cyan, 0.86) end
if board then haze("PinkWash", board, Vector3.new(board.Size.X - 1.6, board.Size.Y - 2.2, 0.03), Vector3.new(0, 0.3, board.Size.Z / 2 + 0.015), colors.Pink, 0.94) end
if board then
	local function light(name, color, offset, range, bright)
		local old = board:FindFirstChild(name); if old then old:Destroy() end
		local a = Instance.new("Attachment"); a.Name = name; a.Position = offset; a.Parent = board
		local l = Instance.new("PointLight"); l.Color = color; l.Range = range; l.Brightness = bright; l.Shadows = false; l.Parent = a
	end
	light("PinkGlow", colors.Pink, Vector3.new(0, 0, 3), 16, 1.4)
	light("CyanGlow", colors.Cyan, Vector3.new(0, -1.6, 2), 10, 1.8)
end
-- eerie yellow aura around the whole sign, visible in daylight (same trick as the cactus)
local hl = model:FindFirstChildOfClass("Highlight") or Instance.new("Highlight")
hl.Name = "SignGlow"
hl.FillColor = Color3.fromRGB(255, 236, 140)
hl.FillTransparency = 0.88
hl.OutlineColor = Color3.fromRGB(255, 226, 110)
hl.OutlineTransparency = 0
hl.DepthMode = Enum.HighlightDepthMode.Occluded
hl.Parent = model
-- yellow spotlight shining down onto the sign
if board then
	local old = board:FindFirstChild("Spot"); if old then old:Destroy() end
	local a = Instance.new("Attachment"); a.Name = "Spot"; a.Position = Vector3.new(0, 7, 4); a.Parent = board
	local sp = Instance.new("SpotLight"); sp.Color = Color3.fromRGB(255, 232, 150); sp.Brightness = 3
	sp.Range = 22; sp.Angle = 70; sp.Face = Enum.NormalId.Bottom; sp.Shadows = true; sp.Parent = a
end
-- scene: keep daytime. Put it back if an earlier run of this script set dusk.
local L = game:GetService("Lighting")
if L.ClockTime < 17 and L.ClockTime > 7 then else L.ClockTime = 14 end
L.Brightness = 2
L.EnvironmentDiffuseScale = 1
L.EnvironmentSpecularScale = 1
L.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
pcall(function() L.Technology = Enum.Technology.Future end)
local bloom = L:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", L)
bloom.Enabled = true; bloom.Intensity = 0.6; bloom.Size = 24; bloom.Threshold = 0.95
print("Area 51 sign: neon + lighting applied to", model:GetFullName())
'''

def write_preview(obj_text, png_path, out_name, cam_pos, look_at):
    b64 = base64.b64encode(Path(png_path).read_bytes()).decode()
    html = """<!doctype html><html><head><meta charset="utf-8"><title>sign preview</title>
<style>html,body{margin:0;background:#2b2140;overflow:hidden}canvas{display:block}</style>
<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script></head><body>
<script id="obj" type="text/plain">__OBJ__</script>
<script>
const txt=document.getElementById('obj').textContent;
const V=[],VT=[],VN=[];const mk=()=>({pos:[],uv:[],nrm:[]});const groups={lit:mk(),neon:mk(),haze:mk()};let cur=groups.lit;
for(const line of txt.split('\\n')){const p=line.trim().split(/\\s+/);
 if(p[0]==='v')V.push(p.slice(1,4).map(Number));else if(p[0]==='vt')VT.push(p.slice(1,3).map(Number));
 else if(p[0]==='vn')VN.push(p.slice(1,4).map(Number));
 else if(p[0]==='o')cur=p[1].includes('Haze')?groups.haze:(p[1].startsWith('Neon')?groups.neon:groups.lit);
 else if(p[0]==='f'){for(const t of p.slice(1,4)){const [a,b,c]=t.split('/').map(x=>parseInt(x)-1);
  cur.pos.push(...V[a]);cur.uv.push(...VT[b]);cur.nrm.push(...VN[c]);}}}
const tex=new THREE.TextureLoader().load('data:image/png;base64,__B64__');tex.encoding=THREE.sRGBEncoding;
const scene=new THREE.Scene();scene.background=new THREE.Color(0x2a1f3d);
function mesh(g,mat){const geo=new THREE.BufferGeometry();
 geo.setAttribute('position',new THREE.Float32BufferAttribute(g.pos,3));
 geo.setAttribute('uv',new THREE.Float32BufferAttribute(g.uv,2));
 geo.setAttribute('normal',new THREE.Float32BufferAttribute(g.nrm,3));scene.add(new THREE.Mesh(geo,mat));}
mesh(groups.lit,new THREE.MeshStandardMaterial({map:tex,roughness:0.8,metalness:0.05}));
mesh(groups.neon,new THREE.MeshBasicMaterial({map:tex}));
mesh(groups.haze,new THREE.MeshBasicMaterial({map:tex,transparent:true,opacity:0.22,depthWrite:false}));
scene.add(new THREE.HemisphereLight(0xffd8c0,0x6a3a28,0.6));
const sun=new THREE.DirectionalLight(0xffc090,0.9);sun.position.set(6,9,7);scene.add(sun);
const pink=new THREE.PointLight(0xff50d0,1.6,18);pink.position.set(0,6.4,3);scene.add(pink);
const cyan=new THREE.PointLight(0x50e8ff,1.4,12);cyan.position.set(0,4.8,2);scene.add(cyan);
const ground=new THREE.Mesh(new THREE.PlaneGeometry(40,40),new THREE.MeshStandardMaterial({color:0x8a3f2c,roughness:1}));
ground.rotation.x=-Math.PI/2;scene.add(ground);
const W=960,H=720;const cam=new THREE.PerspectiveCamera(36,W/H,0.1,100);
cam.position.set(__CAM__);cam.lookAt(__LOOK__);
const ren=new THREE.WebGLRenderer({antialias:true,preserveDrawingBuffer:true});ren.setSize(W,H);ren.outputEncoding=THREE.sRGBEncoding;
ren.toneMapping=THREE.ACESFilmicToneMapping;document.body.appendChild(ren.domElement);
(function loop(){ren.render(scene,cam);requestAnimationFrame(loop);})();
</script></body></html>"""
    html = html.replace("__OBJ__", obj_text).replace("__B64__", b64).replace("__CAM__", ",".join(map(str, cam_pos))).replace("__LOOK__", ",".join(map(str, look_at)))
    (OUT / out_name).write_text(html, encoding="utf-8")

if __name__ == "__main__":
    o = build()
    tris = o.write(OUT / f"area51_sign{SUFFIX}.obj", "area51_sign_texture.png")
    paint().save(OUT / "area51_sign_texture.png")
    (OUT / "sign_neon_setup.lua").write_text(LUA, encoding="utf-8")
    write_preview((OUT / f"area51_sign{SUFFIX}.obj").read_text(encoding="utf-8"), OUT / "area51_sign_texture.png",
                  f"preview_sign{SUFFIX}.html", (7, 8 + (POST_H - 5.8) * 0.5, 22 + (POST_H - 5.8) * 1.5), (0, SIGN_Y - 2.5, 0))
    print(f"area51_sign{SUFFIX}.obj: {len(o.v)} verts, {tris} triangles, {len(o.objects)} objects")
