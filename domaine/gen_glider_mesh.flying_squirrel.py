# gen_glider_mesh.py - the hang glider's sail for 1001 Squirrels: a FLYING SQUIRREL whose spread membrane is the wing.
# Shannon (Sep 27 2026) said yes to "a flying-squirrel glider, with a squirrel on the sail".
#
# One double-sided mesh (group GliderSail): the delta sail with a little billow, the squirrel's flat round head out in
# front of the nose and its fluffy tail out behind the keel. One 1024x1024 texture: the top half is the squirrel's back
# (chestnut fur, darker spine, cream membrane edge, paws at the wing tips), the bottom half its pale belly (seen from the
# ground). Both sides use the same planar top-down UV, so the underside (which is seen mirrored) is drawn symmetric.
#
# Coordinates are Roblox's for the finished part: +x right, +y up, forward = -z (the nose). The OBJ is written pre-turned
# (x,y,z -> -x,y,-z) because Import 3D turns it back. The mesh is written centred on its bounding box; the builder places
# it from GLIDER_BBOX_CENTRE, which this script prints and also writes to glider/glider_data.json.
import json
import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "glider")
os.makedirs(OUT, exist_ok=True)

# ---------------------------------------------------------------- the shape (studs) ----
NOSE = np.array([0.0, 0.05, -5.0])
TIP_R = np.array([6.6, 0.42, 1.55])
KEEL = np.array([0.0, 0.05, 2.2])
BOW = 0.85                        # how far the trailing edge bows forward between a tip and the keel
HEAD_C, HEAD_RX, HEAD_RZ = np.array([0.0, 0.14, -5.55]), 1.25, 1.12
TAIL_Z0, TAIL_Z1 = 1.5, 6.2
X0, X1, Z0, Z1 = -7.0, 7.0, -7.4, 6.6   # the UV window (top-down)


def trailing(t, side):
    """a point on the trailing edge, t = 0 at the keel end, 1 at the tip"""
    tip = TIP_R * np.array([side, 1, 1])
    p = KEEL + (tip - KEEL) * t
    p = p + np.array([0, 0, -BOW * math.sin(math.pi * t)])
    return p


def leading(t, side):
    tip = TIP_R * np.array([side, 1, 1])
    return NOSE + (tip - NOSE) * t


def sail_point(a, b, side):
    """a: 0 at the keel line .. 1 at the tip; b: 0 at the leading edge .. 1 at the trailing edge"""
    le, te = leading(a, side), trailing(a, side)
    p = le + (te - le) * b
    billow = 0.34 * math.sin(math.pi * b) * (1 - a ** 1.6) * min(1.0, a * 6 + 0.25)
    return p + np.array([0, billow, 0])


verts, uvs, faces = [], [], []    # faces: lists of (vi, ti) 1-based


def uv_of(p, half):
    u = (p[0] - X0) / (X1 - X0)
    row = (p[2] - Z0) / (Z1 - Z0) * 0.5 + (0.5 if half == "bottom" else 0.0)   # 0..1 down the image
    return (u, 1.0 - row)


def add_surface(grid_pts, flip_down):
    """grid_pts: rows of 3D points (a quad grid). Writes a top face (normals up) and a belly face (normals down), each
    textured from its half of the image."""
    rows, cols = len(grid_pts), len(grid_pts[0])
    for half, lift in (("top", 0.015), ("bottom", -0.015)):
        base = len(verts)
        for r in range(rows):
            for c in range(cols):
                p = grid_pts[r][c] + np.array([0, lift, 0])
                verts.append(p)
                uvs.append(uv_of(grid_pts[r][c], half))
        for r in range(rows - 1):
            for c in range(cols - 1):
                i00 = base + r * cols + c + 1
                i01, i10, i11 = i00 + 1, i00 + cols, i00 + cols + 1
                tri1, tri2 = [i00, i10, i11], [i00, i11, i01]
                up = (half == "top") != flip_down
                if not up:
                    tri1, tri2 = tri1[::-1], tri2[::-1]
                faces.append(tri1)
                faces.append(tri2)


def check_up(tri_pts):
    a, b, c = tri_pts
    return np.cross(b - a, c - a)[1]


# the two halves of the sail (a quad grid each)
NA, NB = 18, 12
for side in (-1, 1):
    grid = [[sail_point(i / NA, j / NB, side) for i in range(NA + 1)] for j in range(NB + 1)]
    # winding: for the right half (side 1) rows run leading->trailing (+z) and columns keel->tip (+x)
    p = grid
    n = check_up([p[0][0], p[1][0], p[1][1]])
    add_surface(grid, flip_down=(n < 0))

# the head: a flat, slightly domed oval with two ears, out in front of the nose
def head_grid():
    pts = []
    NR, NT = 8, 40
    for r in range(NR + 1):
        row = []
        rr = r / NR
        for k in range(NT + 1):
            ang = 2 * math.pi * k / NT
            ex, ez = math.sin(ang), -math.cos(ang)        # ang 0 = straight ahead (-z)
            # ears: two bumps at +-38 degrees from ahead
            ear = 0.0
            for e in (-1, 1):
                d = (ang - (e * math.radians(38)) + math.pi) % (2 * math.pi) - math.pi
                ear = max(ear, 0.62 * math.exp(-(d / math.radians(11)) ** 2))
            x = HEAD_C[0] + ex * (HEAD_RX + ear) * rr
            z = HEAD_C[2] + ez * (HEAD_RZ + ear) * rr
            y = HEAD_C[1] + 0.22 * (1 - rr * rr)
            row.append(np.array([x, y, z]))
        pts.append(row)
    return pts


hg = head_grid()
n = check_up([hg[1][0], hg[1][1], hg[2][1]])
add_surface(hg, flip_down=(n < 0))


# the tail: a fluffy teardrop behind the keel, turning up a little at the end
def tail_grid():
    NL, NW = 16, 6
    pts = []
    for i in range(NL + 1):
        t = i / NL
        z = TAIL_Z0 + (TAIL_Z1 - TAIL_Z0) * t
        half = 0.42 + 0.95 * math.sin(math.pi * min(1.0, t * 1.08)) ** 0.75
        if t > 0.9:
            half *= math.sqrt(max(0.0, 1 - ((t - 0.9) / 0.1) ** 2)) * 0.9 + 0.1
        y = 0.1 + 0.55 * t ** 2.2
        row = []
        for j in range(NW + 1):
            s = -1 + 2 * j / NW
            row.append(np.array([s * half, y + 0.06 * (1 - s * s), z]))
        pts.append(row)
    return pts


tg = tail_grid()
n = check_up([tg[0][0], tg[1][0], tg[1][1]])
add_surface(tg, flip_down=(n < 0))

V = np.array(verts)
lo, hi = V.min(axis=0), V.max(axis=0)
centre = (lo + hi) / 2
print("bbox", lo.round(3), hi.round(3), "centre", centre.round(3), "tris", len(faces))

# ---------------------------------------------------------------- the texture ----
S = 100          # px per stud while drawing (then squeezed into its half)
W, H = int((X1 - X0) * S), int((Z1 - Z0) * S)
SS = 2           # supersample


def P(x, z):
    return ((x - X0) * S * SS, (z - Z0) * S * SS)


def poly(draw, pts, fill):
    draw.polygon([P(x, z) for (x, z) in pts], fill=fill)


def ellipse(draw, cx, cz, rx, rz, fill):
    x0, y0 = P(cx - rx, cz - rz)
    x1, y1 = P(cx + rx, cz + rz)
    draw.ellipse([x0, y0, x1, y1], fill=fill)


def outline_pts():
    pts = []
    for i in range(0, 41):
        p = leading(i / 40, -1)
        pts.append((p[0], p[2]))
    pts = pts[::-1]
    for i in range(0, 41):
        p = trailing(1 - i / 40, -1)
        pts.append((p[0], p[2]))
    for i in range(1, 41):
        p = trailing(i / 40, 1)
        pts.append((p[0], p[2]))
    for i in range(40, -1, -1):
        p = leading(i / 40, 1)
        pts.append((p[0], p[2]))
    return pts


SAIL = outline_pts()


def head_pts(scale=1.0):
    pts = []
    for k in range(120):
        ang = 2 * math.pi * k / 120
        ex, ez = math.sin(ang), -math.cos(ang)
        ear = 0.0
        for e in (-1, 1):
            d = (ang - (e * math.radians(38)) + math.pi) % (2 * math.pi) - math.pi
            ear = max(ear, 0.62 * math.exp(-(d / math.radians(11)) ** 2))
        pts.append((HEAD_C[0] + ex * (HEAD_RX + ear) * scale, HEAD_C[2] + ez * (HEAD_RZ + ear) * scale))
    return pts


def tail_pts(shrink=0.0):
    left, right = [], []
    for i in range(0, 61):
        t = i / 60
        z = TAIL_Z0 + (TAIL_Z1 - TAIL_Z0) * t
        half = 0.42 + 0.95 * math.sin(math.pi * min(1.0, t * 1.08)) ** 0.75
        if t > 0.9:
            half *= math.sqrt(max(0.0, 1 - ((t - 0.9) / 0.1) ** 2)) * 0.9 + 0.1
        half = max(0.0, half - shrink)
        left.append((-half, z))
        right.append((half, z))
    return left + right[::-1]


def canvas(bg=(0, 0, 0, 0)):
    return Image.new("RGBA", (W * SS, H * SS), bg)


def fur_gradient(img, mask, c_in, c_out, spine=None):
    """colour the masked area from c_in near the keel to c_out at the tips (by |x|), multiplied into img"""
    a = np.array(img).astype(np.float32)
    m = np.array(mask).astype(np.float32) / 255.0
    xs = (np.arange(W * SS) / (S * SS) + X0)[None, :]
    zs = (np.arange(H * SS) / (S * SS) + Z0)[:, None]
    t = np.clip(np.abs(xs) / 6.6, 0, 1) ** 0.8
    t = np.broadcast_to(t, (H * SS, W * SS))
    col = np.array(c_in)[None, None, :] * (1 - t[..., None]) + np.array(c_out)[None, None, :] * t[..., None]
    # a soft fur mottling so the big areas are not flat
    rng = np.random.default_rng(7)
    noise = rng.normal(0, 1, (H * SS // 8 + 1, W * SS // 8 + 1)).astype(np.float32)
    noise = np.array(Image.fromarray(((noise * 18) + 128).clip(0, 255).astype(np.uint8)).resize((W * SS, H * SS), Image.BICUBIC)).astype(np.float32) - 128
    col = col + noise[..., None] * 0.18
    for ch in range(3):
        a[..., ch] = a[..., ch] * (1 - m) + col[..., ch] * m
    a[..., 3] = np.maximum(a[..., 3], m * 255)
    return Image.fromarray(a.clip(0, 255).astype(np.uint8))


def mask_of(fn):
    m = Image.new("L", (W * SS, H * SS), 0)
    fn(ImageDraw.Draw(m))
    return m


def draw_top():
    img = canvas((150, 100, 60, 255))
    sail = mask_of(lambda d: d.polygon([P(x, z) for x, z in SAIL], fill=255))
    img = fur_gradient(img, sail, (138, 88, 50), (190, 136, 86))
    d = ImageDraw.Draw(img)
    # the membrane's pale edge along the trailing edge and round the tips, then a thin dark line outside it
    edge = []
    for side in (-1, 1):
        for i in range(0, 41):
            p = trailing(i / 40, side)
            edge.append((p[0], p[2]))
    for side in (-1, 1):
        pts = [trailing(i / 40, side) for i in range(41)]
        line = [P(p[0], p[2]) for p in pts]
        d.line(line, fill=(236, 214, 176, 255), width=int(0.34 * S * SS), joint="curve")
        d.line(line, fill=(92, 58, 32, 255), width=int(0.07 * S * SS), joint="curve")
    # the forelegs along the leading edges, from the shoulders out to the wrists at the tips
    for side in (-1, 1):
        a0, a1 = leading(0.28, side), leading(0.97, side)
        d.line([P(a0[0], a0[2] + 0.18), P(a1[0], a1[2] + 0.12)], fill=(112, 70, 38, 255), width=int(0.42 * S * SS))
        d.line([P(a0[0], a0[2] + 0.02), P(a1[0], a1[2] - 0.02)], fill=(84, 52, 28, 255), width=int(0.1 * S * SS))
    # paws at the tips (a pad and three toes)
    for side in (-1, 1):
        t = TIP_R * np.array([side, 1, 1])
        ellipse(d, t[0] - side * 0.35, t[2] - 0.25, 0.38, 0.3, (98, 60, 32, 255))
        for k in (-1, 0, 1):
            ellipse(d, t[0] - side * 0.1 + side * 0.05 * k, t[2] - 0.28 + 0.2 * k, 0.12, 0.1, (232, 168, 150, 255))
    # hind paws on the trailing edge near the body
    for side in (-1, 1):
        p = trailing(0.3, side)
        ellipse(d, p[0], p[2] - 0.2, 0.3, 0.26, (98, 60, 32, 255))
        for k in (-1, 0, 1):
            ellipse(d, p[0] + 0.14 * k, p[2] + 0.02, 0.09, 0.08, (232, 168, 150, 255))
    # the body along the keel, darker, with a spine stripe
    body = [(x * 1.0, z) for x, z in [(0, -4.4), (0.95, -3.9), (1.35, -2.6), (1.3, -0.8), (1.05, 0.9), (0.7, 2.0), (0, 2.35),
                                      (-0.7, 2.0), (-1.05, 0.9), (-1.3, -0.8), (-1.35, -2.6), (-0.95, -3.9)]]
    bm = mask_of(lambda dd: dd.polygon([P(x, z) for x, z in body], fill=255)).filter(ImageFilter.GaussianBlur(6))
    img = fur_gradient(img, bm, (118, 74, 40), (118, 74, 40))
    d = ImageDraw.Draw(img)
    d.line([P(0, -3.9), P(0, 2.0)], fill=(90, 56, 30, 255), width=int(0.28 * S * SS))
    # the tail: fluffy, lighter fringe, darker tip
    tm = mask_of(lambda dd: dd.polygon([P(x, z) for x, z in tail_pts()], fill=255))
    img = fur_gradient(img, tm, (206, 160, 112), (206, 160, 112))
    tin = mask_of(lambda dd: dd.polygon([P(x, z) for x, z in tail_pts(0.28)], fill=255)).filter(ImageFilter.GaussianBlur(5))
    img = fur_gradient(img, tin, (138, 90, 52), (138, 90, 52))
    d = ImageDraw.Draw(img)
    for k in range(9):                                   # fur strokes down the tail
        zz = TAIL_Z0 + 0.6 + k * 0.45
        d.line([P(-0.25, zz), P(0, zz + 0.3), P(0.25, zz)], fill=(116, 74, 42, 255), width=int(0.05 * S * SS))
    # the head: fur, a pale muzzle, pink inner ears, big eyes, a pink nose
    hm = mask_of(lambda dd: dd.polygon([P(x, z) for x, z in head_pts()], fill=255))
    img = fur_gradient(img, hm, (150, 98, 58), (150, 98, 58))
    d = ImageDraw.Draw(img)
    for side in (-1, 1):
        ang = side * math.radians(38)
        ex, ez = math.sin(ang), -math.cos(ang)
        cx, cz = HEAD_C[0] + ex * (HEAD_RX + 0.3), HEAD_C[2] + ez * (HEAD_RZ + 0.3)
        ellipse(d, cx, cz, 0.2, 0.26, (228, 150, 140, 255))
    ellipse(d, 0, -6.05, 0.72, 0.52, (232, 206, 164, 255))          # the muzzle
    for side in (-1, 1):
        ellipse(d, side * 0.55, -5.72, 0.3, 0.34, (26, 18, 14, 255))  # eyes
        ellipse(d, side * 0.55 - 0.08, -5.84, 0.1, 0.1, (255, 255, 255, 255))
        ellipse(d, side * 0.55 + 0.09, -5.62, 0.05, 0.05, (255, 255, 255, 255))
    ellipse(d, 0, -6.5, 0.2, 0.14, (224, 120, 128, 255))               # nose
    d.line([P(0, -6.38), P(0, -6.2)], fill=(120, 70, 50, 255), width=int(0.05 * S * SS))
    for side in (-1, 1):                                                # whiskers
        for k in (-1, 1):
            d.line([P(side * 0.35, -6.2), P(side * 1.35, -6.35 + 0.18 * k)], fill=(70, 44, 26, 255), width=int(0.035 * S * SS))
    return img


def draw_bottom():
    img = canvas((236, 220, 188, 255))
    sail = mask_of(lambda d: d.polygon([P(x, z) for x, z in SAIL], fill=255))
    img = fur_gradient(img, sail, (244, 234, 212), (214, 176, 128))
    d = ImageDraw.Draw(img)
    for side in (-1, 1):
        pts = [trailing(i / 40, side) for i in range(41)]
        line = [P(p[0], p[2]) for p in pts]
        d.line(line, fill=(186, 140, 92, 255), width=int(0.3 * S * SS), joint="curve")
    for side in (-1, 1):
        a0, a1 = leading(0.28, side), leading(0.97, side)
        d.line([P(a0[0], a0[2] + 0.18), P(a1[0], a1[2] + 0.12)], fill=(200, 160, 118, 255), width=int(0.4 * S * SS))
        t = TIP_R * np.array([side, 1, 1])
        ellipse(d, t[0] - side * 0.35, t[2] - 0.25, 0.34, 0.28, (232, 168, 150, 255))
    body = [(0, -4.3), (0.85, -3.8), (1.2, -2.5), (1.15, -0.8), (0.9, 0.9), (0.6, 1.9), (0, 2.2), (-0.6, 1.9), (-0.9, 0.9), (-1.15, -0.8), (-1.2, -2.5), (-0.85, -3.8)]
    bm = mask_of(lambda dd: dd.polygon([P(x, z) for x, z in body], fill=255)).filter(ImageFilter.GaussianBlur(8))
    img = fur_gradient(img, bm, (252, 248, 236), (252, 248, 236))
    tm = mask_of(lambda dd: dd.polygon([P(x, z) for x, z in tail_pts()], fill=255))
    img = fur_gradient(img, tm, (196, 150, 104), (196, 150, 104))
    hm = mask_of(lambda dd: dd.polygon([P(x, z) for x, z in head_pts()], fill=255))
    img = fur_gradient(img, hm, (232, 214, 182), (232, 214, 182))
    d = ImageDraw.Draw(img)
    ellipse(d, 0, -6.1, 0.62, 0.45, (246, 236, 214, 255))
    return img


top = draw_top().resize((1024, 512), Image.LANCZOS)
bot = draw_bottom().resize((1024, 512), Image.LANCZOS)
tex = Image.new("RGBA", (1024, 1024))
tex.paste(top, (0, 0))
tex.paste(bot, (0, 512))
tex = tex.convert("RGB")
tex.save(os.path.join(OUT, "glider_sail.png"))

# ---------------------------------------------------------------- the OBJ ----
with open(os.path.join(OUT, "Glider.mtl"), "w") as f:
    f.write("newmtl GliderSail\nKd 1 1 1\nmap_Kd glider_sail.png\n")
with open(os.path.join(OUT, "Glider.obj"), "w") as f:
    f.write("mtllib Glider.mtl\ng GliderSail\nusemtl GliderSail\n")
    for p in V:
        q = p - centre
        f.write("v %.4f %.4f %.4f\n" % (-q[0], q[1], -q[2]))       # pre-turned for Import 3D
    for (u, v) in uvs:
        f.write("vt %.5f %.5f\n" % (u, v))
    for tri in faces:
        f.write("f " + " ".join("%d/%d" % (i, i) for i in tri) + "\n")

data = {"bboxCentre": centre.round(4).tolist(), "bboxSize": (hi - lo).round(4).tolist(), "tris": len(faces),
        "nose": NOSE.tolist(), "tip": TIP_R.tolist(), "keel": KEEL.tolist(), "head": HEAD_C.tolist(), "tailEnd": TAIL_Z1}
with open(os.path.join(OUT, "glider_data.json"), "w") as f:
    json.dump(data, f, indent=1)
print(json.dumps(data))

# a quick look at the texture and the planform (for checking by eye)
prev = Image.new("RGB", (1024 + 40, 1024 + 40), (40, 40, 48))
prev.paste(tex, (20, 20))
prev.save(os.path.join(OUT, "glider_texture_preview.png"))
