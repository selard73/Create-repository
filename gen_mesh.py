"""
Cartoon cactus as a textured mesh for Roblox Studio (Import 3D).

Outputs, next to this script:
  cactus.obj           smooth mesh: Trunk, ArmL, ArmR, Ground, Rock1-3, flowers
  cactus.mtl           material file pointing at the texture
  cactus_texture.png   1024x1024 painted texture atlas. Repaint it in any image editor.
  preview3d.html       standalone 3D preview (open in a browser)

Run:  python gen_mesh.py
Import in Studio:  Home (or Avatar) tab > Import 3D > cactus.obj

Texture atlas layout (u right, v up, as in the OBJ):
  Trunk      u 0.00-0.50  v 0.50-1.00    top of trunk = top of region
  ArmL       u 0.00-0.50  v 0.25-0.50    tip = top of region
  ArmR       u 0.50-1.00  v 0.25-0.50
  Ground     u 0.50-1.00  v 0.50-1.00
  FlowerW    u 0.00-0.25  v 0.00-0.25    white petals (top flower)
  FlowerP    u 0.25-0.50  v 0.00-0.25    white/pink/yellow petals (arm flowers)
  Red        u 0.50-0.625 v 0.00-0.125   flower centers
  Rock       u 0.625-1.00 v 0.00-0.25
"""
import base64
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageChops

OUT = Path(__file__).parent
TEX = 1024
random.seed(7)

# ----------------------------------------------------------------- vec ----
def add(a, b): return (a[0] + b[0], a[1] + b[1], a[2] + b[2])
def sub(a, b): return (a[0] - b[0], a[1] - b[1], a[2] - b[2])
def mul(a, s): return (a[0] * s, a[1] * s, a[2] * s)
def dot(a, b): return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
def cross(a, b): return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
def length(a): return math.sqrt(dot(a, a))
def norm(a):
    l = length(a)
    return (a[0] / l, a[1] / l, a[2] / l) if l > 1e-9 else (0.0, 1.0, 0.0)

# ----------------------------------------------------------------- obj ----
class Obj:
    def __init__(self):
        self.v, self.vt, self.vn, self.objects = [], [], [], []

    def add_object(self, name, verts, uvs, faces, center_fn):
        """faces: local 0-based triangles. center_fn(point) -> an 'inside' point, used to make
        every triangle face outward. Normals are smoothed across seams by position."""
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
        base = len(self.v)
        self.v += verts; self.vt += uvs; self.vn += normals
        self.objects.append((name, [(a + base, b + base, c + base) for a, b, c in faces]))

    def write(self, path, mtl_name, texture_name):
        lines = [f"mtllib {mtl_name}"]
        lines += [f"v {x:.4f} {y:.4f} {z:.4f}" for x, y, z in self.v]
        lines += [f"vt {u:.5f} {v:.5f}" for u, v in self.vt]
        lines += [f"vn {x:.4f} {y:.4f} {z:.4f}" for x, y, z in self.vn]
        for name, faces in self.objects:
            lines.append(f"o {name}")
            lines.append(f"g {name}")
            lines.append(f"usemtl m_{name}")
            lines.append("s 1")
            for a, b, c in faces:
                lines.append(f"f {a+1}/{a+1}/{a+1} {b+1}/{b+1}/{b+1} {c+1}/{c+1}/{c+1}")
        Path(path).write_text("\n".join(lines) + "\n", encoding="utf-8")
        nl = chr(10)
        mtl = "".join(f"newmtl m_{name}{nl}Kd 1 1 1{nl}Ka 1 1 1{nl}Ks 0 0 0{nl}d 1{nl}illum 1{nl}map_Kd {texture_name}{nl}{nl}" for name, _ in self.objects)
        Path(path).with_suffix(".mtl").write_text(mtl, encoding="utf-8")
        return sum(len(f) for _, f in self.objects)

def lathe(rings):
    """rings: list of (points, uvs, degenerate). Consecutive rings are stitched with quads;
    a degenerate ring (all points equal, e.g. an apex) gets single triangles."""
    verts, uvs, faces = [], [], []
    starts = []
    for pts, uv, _ in rings:
        starts.append(len(verts)); verts += pts; uvs += uv
    for i in range(len(rings) - 1):
        n = len(rings[i][0])
        s0, s1 = starts[i], starts[i + 1]
        d0, d1 = rings[i][2], rings[i + 1][2]
        for j in range(n - 1):
            a, b, c, d = s0 + j, s0 + j + 1, s1 + j + 1, s1 + j
            if d1:
                faces.append((a, b, c))
            elif d0:
                faces.append((a, c, d))
            else:
                faces.append((a, b, c)); faces.append((a, c, d))
    return verts, uvs, faces

def sweep(path, radius_fn, segs, uv, cap_len, cap_samples):
    """Tube along `path` (list of points), radius_fn(s, theta) -> radius, closed with a rounded
    cap along the final tangent. uv = (u0, u1, v0, v1); v runs along the length, tip at v1."""
    n = len(path)
    tangents = [norm(sub(path[min(i + 1, n - 1)], path[max(i - 1, 0)])) for i in range(n)]
    specs = [(path[i], tangents[i], 1.0, i / (n - 1)) for i in range(n)]
    T = tangents[-1]
    for k in range(1, cap_samples + 1):
        phi = (math.pi / 2) * k / cap_samples
        specs.append((add(path[-1], mul(T, cap_len * math.sin(phi))), T, math.cos(phi), 1.0))
    # arc length for v
    cum = [0.0]
    for i in range(1, len(specs)):
        cum.append(cum[-1] + length(sub(specs[i][0], specs[i - 1][0])))
    total = cum[-1]
    B = (0.0, 0.0, 1.0)
    u0, u1, v0, v1 = uv
    rings = []
    for i, (p, t, scale, s) in enumerate(specs):
        N = norm(cross(B, t))
        pts, uvs = [], []
        v = v0 + (v1 - v0) * cum[i] / total
        for j in range(segs + 1):
            th = 2 * math.pi * j / segs
            r = radius_fn(s, th) * scale
            pts.append(add(p, add(mul(N, r * math.cos(th)), mul(B, r * math.sin(th)))))
            uvs.append((u0 + (u1 - u0) * j / segs, v))
        rings.append((pts, uvs, scale < 1e-6))
    return lathe(rings)

def surface_line(path, radius_fn, cap_len, cap_samples, th, s_min, lift=0.04):
    """Points lying on the surface of the tube that sweep() would make from `path`, at angle `th`,
    ordered from the tip downward and stopping at parameter s_min. Used for glowing ridge lines."""
    n = len(path)
    tangents = [norm(sub(path[min(i + 1, n - 1)], path[max(i - 1, 0)])) for i in range(n)]
    specs = [(path[i], tangents[i], 1.0, i / (n - 1)) for i in range(n)]
    T = tangents[-1]
    for k in range(1, cap_samples):
        phi = (math.pi / 2) * k / cap_samples
        specs.append((add(path[-1], mul(T, cap_len * math.sin(phi))), T, math.cos(phi), 1.0))
    B = (0.0, 0.0, 1.0)
    pts = []
    for p, t, scale, s_ in reversed(specs):
        if s_ < s_min:
            break
        N = norm(cross(B, t))
        r = radius_fn(s_, th) * scale + lift
        pts.append(add(p, add(mul(N, r * math.cos(th)), mul(B, r * math.sin(th)))))
    return pts

def blob(center, scale, segs, lats, uv, noise=0.0, seed=0):
    """Ellipsoid, top pole first. noise jitters the radius per vertex for rocks."""
    rnd = random.Random(seed)
    jit = [[1 + rnd.uniform(-noise, noise) for _ in range(segs)] for _ in range(lats + 1)]
    u0, u1, v0, v1 = uv
    rings = []
    for i in range(lats + 1):
        lat = math.pi * i / lats           # 0 top, pi bottom
        pts, uvs = [], []
        for j in range(segs + 1):
            th = 2 * math.pi * j / segs
            f = jit[i][j % segs]
            x = math.sin(lat) * math.cos(th) * scale[0] * f
            y = math.cos(lat) * scale[1] * f
            z = math.sin(lat) * math.sin(th) * scale[2] * f
            pts.append(add(center, (x, y, z)))
            uvs.append((u0 + (u1 - u0) * j / segs, v1 - (v1 - v0) * i / lats))
        rings.append((pts, uvs, i == 0 or i == lats))
    return lathe(rings)

def mound(radius, height, segs, steps, uv):
    """Low irregular clay mound, centre high, edge on the ground."""
    u0, u1, v0, v1 = uv
    rings = []
    for k in range(steps + 1):
        t = k / steps
        pts, uvs = [], []
        for j in range(segs + 1):
            th = 2 * math.pi * j / segs
            wob = 1 + 0.10 * math.sin(3 * th + 1.0) + 0.06 * math.sin(7 * th + 2.5) + 0.04 * math.sin(11 * th)
            r = radius * t * (wob if k else 1)
            y = height * (1 - t * t) * (1 + 0.15 * math.sin(5 * th + t * 3)) if k else height
            pts.append((r * math.cos(th), y, r * math.sin(th)))
            uvs.append((u0 + (u1 - u0) * (0.5 + 0.5 * t * math.cos(th)), v0 + (v1 - v0) * (0.5 + 0.5 * t * math.sin(th))))
        rings.append((pts, uvs, k == 0))
    return lathe(rings)

# ------------------------------------------------------------ geometry ----
UV = {
    "trunk":   (0.00, 0.50, 0.50, 1.00),
    "armL":    (0.00, 0.50, 0.25, 0.50),
    "armR":    (0.50, 1.00, 0.25, 0.50),
    "ground":  (0.50, 1.00, 0.50, 1.00),
    "flowerW": (0.00, 0.25, 0.00, 0.25),
    "flowerP": (0.25, 0.50, 0.00, 0.25),
    "red":     (0.50, 0.625, 0.00, 0.125),
    "rock":    (0.625, 1.00, 0.00, 0.25),
    "ridge":   (0.50, 0.625, 0.125, 0.25),
}
TRUNK_LOBES, ARM_LOBES = 8, 6
TRUNK_H, TRUNK_CAP = 8.3, 1.35
ARM_R = 0.62

def trunk_radius(s, th):
    base = 1.02 + 0.22 * math.sin(math.pi * s) + 0.08 * (1 - s) ** 3
    return base * (1 + 0.085 * math.cos(TRUNK_LOBES * th))

def arm_radius(s, th):
    base = ARM_R + 0.07 * math.sin(math.pi * s)
    return base * (1 + 0.09 * math.cos(ARM_LOBES * th))

def arm_path(side, y0, ytop, xe=1.55, rb=0.9):
    pts = []
    for i in range(5):
        t = i / 4
        pts.append((side * (0.4 + (xe - 0.4) * t), y0, 0.0))
    for i in range(1, 11):
        a = -math.pi / 2 + (math.pi / 2) * i / 10
        pts.append((side * (xe + rb * math.cos(a)), y0 + rb + rb * math.sin(a), 0.0))
    x = side * (xe + rb)
    for i in range(1, 13):
        t = i / 12
        pts.append((x, (y0 + rb) + (ytop - (y0 + rb)) * t, 0.0))
    return pts, (x, ytop)

def tube_line(pts, radius, segs=8):
    """Round-capped tube along pts, textured with the solid ridge colour."""
    if len(pts) < 2:
        pts = pts + [add(pts[0], (0.0, -0.1, 0.0))]
    n = len(pts)
    tang = [norm(sub(pts[min(i + 1, n - 1)], pts[max(i - 1, 0)])) for i in range(n)]
    specs = []
    for k in range(4, 0, -1):
        phi = (math.pi / 2) * k / 4
        specs.append((sub(pts[0], mul(tang[0], radius * math.sin(phi))), tang[0], math.cos(phi)))
    specs += [(pts[i], tang[i], 1.0) for i in range(n)]
    for k in range(1, 5):
        phi = (math.pi / 2) * k / 4
        specs.append((add(pts[-1], mul(tang[-1], radius * math.sin(phi))), tang[-1], math.cos(phi)))
    B = (0.0, 0.0, 1.0)
    u0, u1, v0, v1 = UV["ridge"]
    cu, cv = (u0 + u1) / 2, (v0 + v1) / 2
    rings = []
    for p, t, sc in specs:
        N = norm(cross(B, t)); r = radius * sc
        ring = [add(p, add(mul(N, r * math.cos(2 * math.pi * j / segs)), mul(B, r * math.sin(2 * math.pi * j / segs)))) for j in range(segs + 1)]
        rings.append((ring, [(cu, cv)] * (segs + 1), sc < 1e-6))
    return lathe(rings)

SCALE = 1.4   # overall size multiplier; 1.0 was about 10 studs tall

def build_mesh():
    obj = Obj()

    # trunk with a slight lean so it is not a perfect column
    path = [(0.10 * (i / 24), -0.3 + (TRUNK_H + 0.3) * (i / 24), 0.0) for i in range(25)]
    v, uv, f = sweep(path, trunk_radius, 40, UV["trunk"], TRUNK_CAP, 9)
    obj.add_object("Trunk", v, uv, f, lambda c: (0.0, min(c[1], TRUNK_H), 0.0))
    top_tip = (0.10, TRUNK_H + TRUNK_CAP)
    for k in range(TRUNK_LOBES):
        th = 2 * math.pi * k / TRUNK_LOBES
        pts = surface_line(path, trunk_radius, TRUNK_CAP, 9, th, 0.3)
        cut = max(2, int(len(pts) * 0.6))
        v, uv, f = tube_line(pts[:cut], 0.075)
        obj.add_object(f"NeonLime_TrunkRib{k}", v, uv, f, lambda p: (0.0, min(p[1], TRUNK_H), 0.0))
        v, uv, f = tube_line(pts[cut - 1:], 0.06)
        obj.add_object(f"NeonLime_TrunkRibTail{k}", v, uv, f, lambda p: (0.0, min(p[1], TRUNK_H), 0.0))

    tips = [top_tip]
    for name, side, y0, ytop in (("armL", -1, 3.6, 7.6), ("armR", 1, 4.7, 8.3)):
        path, tip = arm_path(side, y0, ytop)
        v, uv, f = sweep(path, arm_radius, 28, UV[name], 0.75, 7)
        obj.add_object(name.replace("arm", "Arm"), v, uv, f, lambda c, P=path: min(P, key=lambda q: length(sub(q, c))))
        for k in range(ARM_LOBES):
            th = 2 * math.pi * k / ARM_LOBES
            pts = surface_line(path, arm_radius, 0.75, 7, th, 0.45)
            cut = max(2, int(len(pts) * 0.6))
            v, uv, f = tube_line(pts[:cut], 0.06)
            obj.add_object(f"NeonLime_{name.replace('arm', 'Arm')}Rib{k}", v, uv, f, lambda c, P=path: min(P, key=lambda q: length(sub(q, c))))
            v, uv, f = tube_line(pts[cut - 1:], 0.05)
            obj.add_object(f"NeonLime_{name.replace('arm', 'Arm')}RibTail{k}", v, uv, f, lambda c, P=path: min(P, key=lambda q: length(sub(q, c))))
        tips.append((tip[0], tip[1] + 0.75))

    # ground and rocks
    v, uv, f = mound(4.2, 0.6, 56, 10, UV["ground"])
    obj.add_object("Ground", v, uv, f, lambda c: (0.0, -2.0, 0.0))
    for i, (rx, rz, s) in enumerate(((3.1, 1.4, 0.55), (-2.6, 2.4, 0.42), (1.2, -3.3, 0.48))):
        c = (rx, s * 0.55, rz)
        v, uv, f = blob(c, (s * 1.3, s * 0.8, s), 14, 8, UV["rock"], noise=0.14, seed=i + 3)
        obj.add_object(f"Rock{i+1}", v, uv, f, lambda p, c=c: c)

    # flowers: barrel-cactus style crown at every tip: ring of pink petal buds around a yellow centre
    for i, (tx, ty) in enumerate(tips):
        sc = 1.25 if i == 0 else 1.0
        for k in range(7):
            a = 2 * math.pi * k / 7
            pc = (tx + 0.45 * sc * math.cos(a), ty + 0.02, 0.45 * sc * math.sin(a))
            v, uv, f = blob(pc, (0.3 * sc, 0.16 * sc, 0.3 * sc), 10, 5, UV["flowerP"])
            obj.add_object(f"Petal{i}_{k}", v, uv, f, lambda p, c=pc: c)
        cc = (tx, ty + 0.16 * sc, 0.0)
        v, uv, f = blob(cc, (0.28 * sc, 0.2 * sc, 0.28 * sc), 10, 5, UV["red"])
        obj.add_object(f"FlowerCore{i}", v, uv, f, lambda p, c=cc: c)
    obj.v = [(x * SCALE, y * SCALE, z * SCALE) for x, y, z in obj.v]
    return obj

# ------------------------------------------------------------- texture ----
def box(region):
    u0, u1, v0, v1 = region
    return int(u0 * TEX), int((1 - v1) * TEX), int(u1 * TEX), int((1 - v0) * TEX)

def noise_layer(w, h, sigma=40):
    return Image.effect_noise((w, h), sigma).convert("RGB")

def paint_gradient(w, h, top, bottom):
    img = Image.new("RGB", (w, h))
    px = img.load()
    for y in range(h):
        t = y / (h - 1)
        col = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        for x in range(w):
            px[x, y] = col
    return img

def grain(img, amount=0.08, sigma=40):
    n = noise_layer(img.width, img.height, sigma)
    return Image.blend(img, ImageChops.multiply(img, ImageChops.add(n, Image.new("RGB", img.size, (128, 128, 128)))), amount)

def ridge_lines(img, lobes, frac, line_col, glow_col, tip_glow=True):
    """Bright ridge lines that start at the top edge and fade out `frac` of the way down.
    Drawn at the u positions of the geometric ridge crests so they sit on the bumps."""
    w, h = img.size
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    end = int(h * frac)
    for k in range(lobes + 1):
        x = int(w * k / lobes)
        for y in range(0, end, 2):
            a = int(255 * (1 - y / end) ** 1.4)
            d.line([(x, y), (x, y + 2)], fill=line_col + (a,), width=max(4, w // 64))
    layer = layer.filter(ImageFilter.GaussianBlur(1.2))
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    g = ImageDraw.Draw(glow)
    for k in range(lobes + 1):
        x = int(w * k / lobes)
        for y in range(0, end, 3):
            a = int(170 * (1 - y / end) ** 1.5)
            g.line([(x, y), (x, y + 3)], fill=glow_col + (a,), width=max(10, w // 30))
    glow = glow.filter(ImageFilter.GaussianBlur(w / 80))
    out = img.convert("RGBA")
    out.alpha_composite(glow)
    out.alpha_composite(layer)
    if tip_glow:  # general brightening near the top so the tip looks lit from within
        top = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        td = ImageDraw.Draw(top)
        for y in range(0, h // 4):
            a = int(90 * (1 - y / (h / 4)) ** 2)
            td.line([(0, y), (w, y)], fill=glow_col + (a,))
        out.alpha_composite(top)
    return out.convert("RGB")

def spines(img, lobes, pts):
    d = ImageDraw.Draw(img)
    w, h = img.size
    r = max(2, w // 170)
    for k, fy in pts:
        x = int(w * (k / lobes)); y = int(h * fy)
        d.ellipse([x - r, y - r, x + r, y + r], fill=(255, 255, 230))
        d.ellipse([x - r // 2, y - r // 2 + 1, x + r // 2, y + r // 2 + 1], fill=(255, 255, 255))
    return img

def paint_texture():
    atlas = Image.new("RGB", (TEX, TEX), (40, 40, 40))
    GREEN_TOP, GREEN_BOT = (122, 160, 66), (84, 116, 50)
    LINE, GLOW = (250, 255, 190), (215, 250, 130)

    # trunk
    x0, y0, x1, y1 = box(UV["trunk"]); w, h = x1 - x0, y1 - y0
    t = grain(paint_gradient(w, h, GREEN_TOP, GREEN_BOT), 0.10)
    t = ridge_lines(t, TRUNK_LOBES, 0.70, LINE, GLOW)
    t = spines(t, TRUNK_LOBES, [(0, 0.12), (1, 0.30), (2, 0.20), (3, 0.42), (4, 0.15), (5, 0.36), (6, 0.25), (7, 0.48),
                                (1, 0.62), (3, 0.70), (5, 0.58), (7, 0.80), (0, 0.72), (4, 0.88), (2, 0.66), (6, 0.90)])
    atlas.paste(t, (x0, y0))

    # arms
    for name in ("armL", "armR"):
        x0, y0, x1, y1 = box(UV[name]); w, h = x1 - x0, y1 - y0
        a = grain(paint_gradient(w, h, GREEN_TOP, GREEN_BOT), 0.10)
        a = ridge_lines(a, ARM_LOBES, 0.62, LINE, GLOW)
        a = spines(a, ARM_LOBES, [(0, 0.18), (2, 0.30), (4, 0.22), (1, 0.45), (3, 0.55), (5, 0.40), (2, 0.72), (4, 0.80)])
        atlas.paste(a, (x0, y0))

    # ground: red desert clay with darker patches, cracks and light specks
    x0, y0, x1, y1 = box(UV["ground"]); w, h = x1 - x0, y1 - y0
    g = grain(Image.new("RGB", (w, h), (176, 82, 52)), 0.16, 50)
    spl = Image.new("RGBA", (w, h), (0, 0, 0, 0)); sd = ImageDraw.Draw(spl)
    rnd = random.Random(11)
    for _ in range(60):
        cx, cy, rr = rnd.randint(0, w), rnd.randint(0, h), rnd.randint(20, 70)
        sd.ellipse([cx - rr, cy - rr * 0.6, cx + rr, cy + rr * 0.6], fill=(120, 52, 34, rnd.randint(50, 110)))
    for _ in range(40):
        cx, cy, rr = rnd.randint(0, w), rnd.randint(0, h), rnd.randint(8, 25)
        sd.ellipse([cx - rr, cy - rr * 0.5, cx + rr, cy + rr * 0.5], fill=(215, 130, 90, rnd.randint(40, 90)))
    spl = spl.filter(ImageFilter.GaussianBlur(6))
    g = g.convert("RGBA"); g.alpha_composite(spl)
    cd = ImageDraw.Draw(g)
    for _ in range(14):
        x, y = rnd.randint(0, w), rnd.randint(0, h)
        for _ in range(rnd.randint(3, 7)):
            nx, ny = x + rnd.randint(-40, 40), y + rnd.randint(-40, 40)
            cd.line([(x, y), (nx, ny)], fill=(96, 40, 28, 170), width=2)
            x, y = nx, ny
    atlas.paste(g.convert("RGB"), (x0, y0))

    # rocks
    x0, y0, x1, y1 = box(UV["rock"]); w, h = x1 - x0, y1 - y0
    r = grain(paint_gradient(w, h, (168, 98, 72), (118, 64, 46)), 0.2, 60)
    atlas.paste(r, (x0, y0))

    x0, y0, x1, y1 = box(UV["ridge"]); atlas.paste(Image.new("RGB", (x1 - x0, y1 - y0), (170, 245, 120)), (x0, y0))
    # flower buds: solid pink like the barrel cactus
    for key in ("flowerW", "flowerP"):
        x0, y0, x1, y1 = box(UV[key]); atlas.paste(Image.new("RGB", (x1 - x0, y1 - y0), (255, 96, 170)), (x0, y0))
    # flower centres: yellow like the barrel cactus
    x0, y0, x1, y1 = box(UV["red"]); atlas.paste(Image.new("RGB", (x1 - x0, y1 - y0), (255, 214, 70)), (x0, y0))
    return atlas

# ------------------------------------------------------------- preview ----
def write_preview(obj_text, png_path):
    b64 = base64.b64encode(Path(png_path).read_bytes()).decode()
    html = f"""<!doctype html><html><head><meta charset="utf-8"><title>cactus preview</title>
<style>html,body{{margin:0;background:#2b2140;overflow:hidden}}canvas{{display:block}}</style>
<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script></head><body>
<script id="obj" type="text/plain">{obj_text}</script>
<script>
const txt=document.getElementById('obj').textContent;
const V=[],VT=[],VN=[],pos=[],uv=[],nrm=[];
for(const line of txt.split('\\n')){{const p=line.trim().split(/\\s+/);
 if(p[0]==='v')V.push(p.slice(1,4).map(Number));else if(p[0]==='vt')VT.push(p.slice(1,3).map(Number));
 else if(p[0]==='vn')VN.push(p.slice(1,4).map(Number));
 else if(p[0]==='f'){{for(const t of p.slice(1,4)){{const [a,b,c]=t.split('/').map(x=>parseInt(x)-1);
  pos.push(...V[a]);uv.push(...VT[b]);nrm.push(...VN[c]);}}}}}}
const geo=new THREE.BufferGeometry();
geo.setAttribute('position',new THREE.Float32BufferAttribute(pos,3));
geo.setAttribute('uv',new THREE.Float32BufferAttribute(uv,2));
geo.setAttribute('normal',new THREE.Float32BufferAttribute(nrm,3));
const tex=new THREE.TextureLoader().load('data:image/png;base64,{b64}');tex.encoding=THREE.sRGBEncoding;tex.flipY=true;
const mat=new THREE.MeshStandardMaterial({{map:tex,roughness:0.85,metalness:0}});
const scene=new THREE.Scene();scene.background=new THREE.Color(0x3a2a4a);
scene.add(new THREE.Mesh(geo,mat));
scene.add(new THREE.HemisphereLight(0xffe2c0,0x7a3a28,0.9));
const sun=new THREE.DirectionalLight(0xffc890,1.3);sun.position.set(6,9,7);scene.add(sun);
const rim=new THREE.DirectionalLight(0x8fd0ff,0.7);rim.position.set(-6,6,-8);scene.add(rim);
const W=960,H=720;const cam=new THREE.PerspectiveCamera(38,W/H,0.1,100);
cam.position.set(12,11,23);cam.lookAt(0,7,0);
const ren=new THREE.WebGLRenderer({{antialias:true,preserveDrawingBuffer:true}});ren.setSize(W,H);ren.outputEncoding=THREE.sRGBEncoding;
ren.toneMapping=THREE.ACESFilmicToneMapping;document.body.appendChild(ren.domElement);
(function loop(){{ren.render(scene,cam);requestAnimationFrame(loop);}})();window.__ready=true;
</script></body></html>"""
    (OUT / "preview3d.html").write_text(html, encoding="utf-8")

CACTUS_LUA = r'''-- Cactus: run once in the Command Bar with the imported model SELECTED (or it finds "cactus" in Workspace).
-- Ridge lines become glowing Neon that fades out toward the bottom, a soft green light sits in the trunk,
-- and the whole cactus gets the faint green daytime aura.
local model = workspace:FindFirstChild("Cactus") or workspace:FindFirstChild("cactus") or game.Selection:Get()[1]
assert(model and model:IsA("Model"), "Select the imported cactus model first")
local LIME = Color3.fromRGB(170, 245, 120)
local trunk
for _, p in ipairs(model:GetDescendants()) do
	if p:IsA("BasePart") then
		p.Anchored = true
		if p.Name:match("^NeonLime_") then
			p.Material = Enum.Material.Neon; p.Color = LIME; p.TextureID = ""; p.CanCollide = false; p.CastShadow = false
			p.Transparency = p.Name:find("Tail") and 0.55 or 0
		elseif p.Name:match("^Petal") then
			p.Material = Enum.Material.SmoothPlastic
		elseif p.Name:match("^FlowerCore") then
			p.Material = Enum.Material.Neon; p.Color = Color3.fromRGB(255, 214, 70); p.TextureID = ""
		else
			p.Material = Enum.Material.SmoothPlastic
		end
		if p.Name == "Trunk" then trunk = p end
	end
end
if trunk then
	local old = trunk:FindFirstChildOfClass("PointLight"); if old then old:Destroy() end
	local l = Instance.new("PointLight"); l.Color = LIME; l.Range = 16; l.Brightness = 0.8; l.Shadows = false; l.Parent = trunk
end
local hl = model:FindFirstChildOfClass("Highlight") or Instance.new("Highlight")
hl.Name = "CactusGlow"; hl.FillColor = LIME; hl.FillTransparency = 0.92
hl.OutlineColor = LIME; hl.OutlineTransparency = 0.35; hl.DepthMode = Enum.HighlightDepthMode.Occluded; hl.Parent = model
model.Name = "Cactus"
print("Cactus: glowing ridges, trunk light and aura applied")
'''

if __name__ == "__main__":
    mesh = build_mesh()
    tris = mesh.write(OUT / "cactus.obj", "cactus.mtl", "cactus_texture.png")
    paint_texture().save(OUT / "cactus_texture.png")
    (OUT / "cactus_setup.lua").write_text(CACTUS_LUA, encoding="utf-8")
    write_preview((OUT / "cactus.obj").read_text(encoding="utf-8"), OUT / "cactus_texture.png")
    print(f"cactus.obj: {len(mesh.v)} verts, {tris} triangles, {len(mesh.objects)} objects")
    print("cactus_texture.png, cactus.mtl, preview3d.html written")
