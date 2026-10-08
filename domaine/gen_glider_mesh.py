# gen_glider_mesh.py - the hang glider's sail for 1001 Squirrels: a classic delta sail in bright colours.
# Shannon (Sep 27 2026, after her first flights): "I don't like the look of it; I want it to be colorful". The flying
# squirrel sail it replaces is kept as gen_glider_mesh.flying_squirrel.py (its files in glider/flying_squirrel/).
#
# One double-sided mesh (group GliderSail): the delta sail with a little billow - the same nose, tips and keel as before,
# so the tubes, the bar and the pilot's hang point all still fit - printed in one of the SCHEMES below, the same on both
# sides (a real sail's colours show through; the underside is printed a touch lighter, as it is seen against the sky).
# A white hem runs along the trailing edge, a white keel pocket down the middle, and faint battens across the cloth.
#
# Coordinates are Roblox's for the finished part: +x right, +y up, forward = -z (the nose). The OBJ is written pre-turned
# (x,y,z -> -x,y,-z) because Import 3D turns it back. The mesh is written centred on its bounding box; the builder places
# it from the bounding-box centre, which this script prints and writes to <out>/glider_data.json.
#
# Run: python gen_glider_mesh.py <scheme> [out_dir]      (out_dir defaults to glider/)
import json
import math
import os
import sys

import numpy as np
from PIL import Image

SCHEMES = {
    # rainbow bands from wing tip to wing tip: red along the leading edge to violet at the trailing edge
    "rainbow": {"kind": "bands", "colours": [(232, 52, 56), (248, 142, 36), (252, 216, 52), (66, 186, 92), (44, 128, 222), (138, 78, 204)]},
    # rainbow rays fanning out from the nose: violet beside the keel to red along the leading edges
    "sunburst": {"kind": "rays", "colours": [(138, 78, 204), (44, 128, 222), (66, 186, 92), (252, 216, 52), (248, 142, 36), (232, 52, 56)]},
    # a smooth sunset from the nose back: gold, orange, pink, purple
    "sunset": {"kind": "gradient", "colours": [(255, 206, 64), (250, 136, 48), (238, 82, 128), (128, 62, 176)]},
}
scheme_name = sys.argv[1] if len(sys.argv) > 1 else "rainbow"
SCHEME = SCHEMES[scheme_name]
OUT = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "glider")
os.makedirs(OUT, exist_ok=True)

# ---------------------------------------------------------------- the shape (studs) ----
NOSE = np.array([0.0, 0.05, -5.0])
TIP_R = np.array([6.6, 0.42, 1.55])
KEEL = np.array([0.0, 0.05, 2.2])
BOW = 0.85                        # how far the trailing edge bows forward between a tip and the keel
X0, X1, Z0, Z1 = -7.0, 7.0, -5.4, 2.6   # the UV window (top-down)


def trailing(t, side):
    """a point on the trailing edge, t = 0 at the keel end, 1 at the tip"""
    tip = TIP_R * np.array([side, 1, 1])
    p = KEEL + (tip - KEEL) * t
    return p + np.array([0, 0, -BOW * math.sin(math.pi * t)])


def leading(t, side):
    tip = TIP_R * np.array([side, 1, 1])
    return NOSE + (tip - NOSE) * t


def sail_point(a, b, side):
    """a: 0 at the keel line .. 1 at the tip; b: 0 at the leading edge .. 1 at the trailing edge"""
    le, te = leading(a, side), trailing(a, side)
    p = le + (te - le) * b
    billow = 0.34 * math.sin(math.pi * b) * (1 - a ** 1.6) * min(1.0, a * 6 + 0.25)
    return p + np.array([0, billow, 0])


verts, uvs, faces = [], [], []    # faces: lists of 1-based indices (vertex i uses uv i)


def uv_of(p, half):
    u = (p[0] - X0) / (X1 - X0)
    row = (p[2] - Z0) / (Z1 - Z0) * 0.5 + (0.5 if half == "bottom" else 0.0)   # 0..1 down the image
    return (u, 1.0 - row)


def add_surface(grid_pts, flip_down):
    """grid_pts: rows of 3D points (a quad grid). Writes a top face (normals up) and an underside (normals down), each
    textured from its half of the image."""
    rows, cols = len(grid_pts), len(grid_pts[0])
    for half, lift in (("top", 0.015), ("bottom", -0.015)):
        base = len(verts)
        for r in range(rows):
            for c in range(cols):
                verts.append(grid_pts[r][c] + np.array([0, lift, 0]))
                uvs.append(uv_of(grid_pts[r][c], half))
        for r in range(rows - 1):
            for c in range(cols - 1):
                i00 = base + r * cols + c + 1
                i01, i10, i11 = i00 + 1, i00 + cols, i00 + cols + 1
                tri1, tri2 = [i00, i10, i11], [i00, i11, i01]
                if (half == "top") == flip_down:
                    tri1, tri2 = tri1[::-1], tri2[::-1]
                faces.append(tri1)
                faces.append(tri2)


NA, NB = 18, 12
for side in (-1, 1):
    grid = [[sail_point(i / NA, j / NB, side) for i in range(NA + 1)] for j in range(NB + 1)]
    a, b, c = grid[0][0], grid[1][0], grid[1][1]
    add_surface(grid, flip_down=(np.cross(b - a, c - a)[1] < 0))

V = np.array(verts)
lo, hi = V.min(axis=0), V.max(axis=0)
centre = (lo + hi) / 2
print("bbox", lo.round(3), hi.round(3), "centre", centre.round(3), "tris", len(faces))

# ---------------------------------------------------------------- the print ----
# every pixel of the window gets (a, b): a = how far out along the span (|x| / tip), b = how far from the leading edge
# to the trailing edge at that station; pixels outside the sail take the colour of the nearest edge (clamped), so the
# texture has no dark fringe where the mesh edge samples it
PX = 150                                  # px per stud while drawing (then squeezed into a 1024 x 512 half)
W, H = int((X1 - X0) * PX), int((Z1 - Z0) * PX)
xs = X0 + (np.arange(W) + 0.5) / PX
zs = Z0 + (np.arange(H) + 0.5) / PX
XX, ZZ = np.meshgrid(xs, zs)
A = np.clip(np.abs(XX) / TIP_R[0], 0, 1)
LEZ = NOSE[2] + (TIP_R[2] - NOSE[2]) * A
TEZ = KEEL[2] + (TIP_R[2] - KEEL[2]) * A - BOW * np.sin(np.pi * A)
B = np.clip((ZZ - LEZ) / np.maximum(TEZ - LEZ, 1e-3), 0, 1)


def bands(t, cols, soft=0.012):
    """t in 0..1 split into len(cols) equal bands, with a hair of blending at each border (no jaggies)"""
    n = len(cols)
    cols = np.array(cols, dtype=np.float32)
    f = np.clip(t, 0, 1) * n
    i = np.clip(np.floor(f).astype(int), 0, n - 1)
    out = cols[i]
    frac = f - np.floor(f)
    nxt = cols[np.clip(i + 1, 0, n - 1)]
    prv = cols[np.clip(i - 1, 0, n - 1)]
    k_up = np.clip((frac - (1 - soft * n)) / (soft * n), 0, 1)[..., None] * 0.5
    k_dn = np.clip((soft * n - frac) / (soft * n), 0, 1)[..., None] * 0.5
    return out * (1 - k_up - k_dn) + nxt * k_up + prv * k_dn


def gradient(t, cols):
    cols = np.array(cols, dtype=np.float32)
    f = np.clip(t, 0, 1) * (len(cols) - 1)
    i = np.clip(np.floor(f).astype(int), 0, len(cols) - 2)
    k = (f - i)[..., None]
    return cols[i] * (1 - k) + cols[i + 1] * k


if SCHEME["kind"] == "bands":
    col = bands(B, SCHEME["colours"])
elif SCHEME["kind"] == "rays":
    theta = np.arctan2(np.abs(XX), np.maximum(ZZ - NOSE[2], 1e-3))
    theta_le = math.atan2(TIP_R[0] - NOSE[0], TIP_R[2] - NOSE[2])
    col = bands(theta / theta_le, SCHEME["colours"])
else:
    col = gradient(B, SCHEME["colours"])

WHITE = np.array([252, 250, 244], dtype=np.float32)


def paint(mask, colour, strength=1.0):
    global col
    m = np.clip(mask, 0, 1)[..., None] * strength
    col = col * (1 - m) + np.array(colour, dtype=np.float32) * m


def edge_ramp(d, width):
    """1 inside a stripe of the given half-width (studs), fading over a pixel and a half"""
    return np.clip((width - d) * PX / 1.5 + 0.5, 0, 1)


# faint battens across the cloth (a shade lighter), from mid-chord to the trailing edge
for a_b in (0.14, 0.28, 0.42, 0.56, 0.70, 0.84):
    d = np.abs(A - a_b) * TIP_R[0]
    paint(edge_ramp(d, 0.03) * (B > 0.35), WHITE, 0.22)
# the leading-edge pocket: a deeper shade of whatever colour is there
chord = np.maximum(TEZ - LEZ, 1e-3)
paint(edge_ramp(B * chord, 0.16), (40, 30, 50), 0.28)
# the white hem along the trailing edge, and the keel pocket down the middle
paint(edge_ramp((1 - B) * chord, 0.11), WHITE)
paint(edge_ramp(np.abs(XX), 0.14) * (ZZ > NOSE[2] + 0.3), WHITE)
# a little shading: the cloth darkens a touch toward the tips and the trailing edge, so the big areas are not flat
col = col * (1.0 - 0.07 * A[..., None] - 0.05 * B[..., None])

top = Image.fromarray(col.clip(0, 255).astype(np.uint8)).resize((1024, 512), Image.LANCZOS)
under = col + (255 - col) * 0.1
bot = Image.fromarray(under.clip(0, 255).astype(np.uint8)).resize((1024, 512), Image.LANCZOS)
tex = Image.new("RGB", (1024, 1024))
tex.paste(top, (0, 0))
tex.paste(bot, (0, 512))
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

data = {"scheme": scheme_name, "bboxCentre": centre.round(4).tolist(), "bboxSize": (hi - lo).round(4).tolist(),
        "tris": len(faces), "nose": NOSE.tolist(), "tip": TIP_R.tolist(), "keel": KEEL.tolist()}
with open(os.path.join(OUT, "glider_data.json"), "w") as f:
    json.dump(data, f, indent=1)
print(json.dumps(data))
