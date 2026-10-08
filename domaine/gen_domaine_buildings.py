"""
Domaine kit, batch 2: the buildings. Same conventions as gen_domaine.py (studs, Y up, front -Z, stands on y = 0).
mas (farmhouse), barn, chapel, windmill (+ separate 'Sails' piece the builder turns), cellar_front (walk-in),
hut (distiller), coop (with its wire run), hen.
Run:  python gen_domaine_buildings.py
"""
import math, random, sys
from pathlib import Path
HERE = Path(__file__).parent
sys.path.insert(0, str(HERE))
import gen_domaine as G
from gen_domaine import Kit, blob, cyl, beam, tube_out, ring_n, stem, add, sub, mul, norm, cross, dot
import gen_forest as F
from gen_forest import ring
from gen_village import box, extrude, extrude_ring, arch_profile, rect_profile, thick_quad

OUT = HERE
F.GRAYS.update({
    "Walls": (0.84, 0.78, 0.68), "Quoin": (0.90, 0.86, 0.78), "Roof": (0.72, 0.46, 0.36), "Tile": (0.66, 0.40, 0.32),
    "Slate": (0.36, 0.38, 0.42), "Trim": (0.92, 0.90, 0.84), "Window": (0.55, 0.65, 0.75), "Shutter": (0.38, 0.55, 0.70),
    "ShutterB": (0.30, 0.44, 0.58), "Door": (0.45, 0.32, 0.24), "Wood": (0.55, 0.42, 0.30), "Plank": (0.62, 0.50, 0.38),
    "Dark": (0.10, 0.09, 0.09), "Iron": (0.18, 0.18, 0.20), "Brass": (0.84, 0.70, 0.36), "Glass": (0.85, 0.90, 0.94),
    "Chimney": (0.80, 0.74, 0.66), "Hay": (0.90, 0.78, 0.40), "Stone": (0.75, 0.72, 0.66), "Vault": (0.45, 0.42, 0.38),
    "Water": (0.55, 0.75, 0.85), "Bell": (0.80, 0.66, 0.30), "Cross": (0.30, 0.30, 0.32), "Hen": (0.92, 0.88, 0.80),
    "Comb": (0.85, 0.20, 0.20), "Beak": (0.90, 0.70, 0.25), "HenLeg": (0.85, 0.65, 0.30), "Wire": (0.30, 0.30, 0.32),
    "Sails": (0.88, 0.86, 0.80), "Hub": (0.40, 0.30, 0.22),
})


# ------------------------------------------------------------- shared building parts ----
def tile_roof(k, xl, xr, zf, zb, H, rh, ov=1.3, along="x", walls="Walls", tile_rows=True, thick=0.5):
    """Gable roof with the ridge along `along` ('x' or 'z'): two thick planes with diamond-profile tile rows and a
    ridge cap, eaves overhanging by ov, and solid gable prisms filling the ends (so the roof meets the walls)."""
    def M(u, y, v):                       # local (u along ridge, v across) -> world
        return (u, y, v) if along == "x" else (v, y, u)
    ul, ur, vf, vb = (xl, xr, zf, zb) if along == "x" else (zf, zb, xl, xr)
    half = (vb - vf) / 2; vc = (vf + vb) / 2
    drop = rh * ov / half                 # the eave sits this much below the wall top, on the same slope
    # gable prisms (solid, part of the walls) so nothing is open between wall top and roof
    prof = [(vf + 0.06, H), (vb - 0.06, H), (vc, H + rh - 0.03)]
    if along == "x":
        extrude(None, walls, prof, "x", ul, ur, tris_out=k.t(walls))
    else:
        extrude(None, walls, prof, "z", ul, ur, tris_out=k.t(walls))
    for sgn, ve in ((-1, vf), (1, vb)):
        eave_v = ve + sgn * ov; ye = H - drop
        A, B = M(ul - ov, ye, eave_v), M(ur + ov, ye, eave_v)
        C, D = M(ur + ov, H + rh, vc), M(ul - ov, H + rh, vc)
        n = cross(sub(B, A), sub(D, A))
        if n[1] > 0: A, B, C, D = A, D, C, B          # keep the slab's thickness under the plane
        thick_quad(k.t("Roof"), A, B, C, D, thick)
        if tile_rows:
            n_rows = int((half + ov) / 1.05)
            for i in range(n_rows):
                f = (i + 0.5) / n_rows
                y = ye + f * (H + rh - ye); v = eave_v + f * (vc - eave_v)
                up = norm(sub(M(0, H + rh, vc), M(0, ye, eave_v)))
                p0 = add(M(ul - ov + 0.1, y, v), mul(up, 0.16)); p1 = add(M(ur + ov - 0.1, y, v), mul(up, 0.16))
                beam(k.t("Tile"), p0, p1, 0.42, 0.42, roll=math.pi / 4)
    beam(k.t("Tile"), M(ul - ov, H + rh + 0.12, vc), M(ur + ov, H + rh + 0.12, vc), 0.7, 0.55, roll=math.pi / 4)
    # eave boards
    for sgn, ve in ((-1, vf), (1, vb)):
        eave_v = ve + sgn * ov; ye = H - drop
        beam(k.t("Wood"), M(ul - ov, ye - 0.15, eave_v + sgn * 0.05), M(ur + ov, ye - 0.15, eave_v + sgn * 0.05), 0.35, 0.5)


def quoins(k, corners, H, size=0.62, out=0.14):
    """Corner stones: alternating long/short blocks up each corner, proud of both faces."""
    for (x, z, sx, sz) in corners:                # sx, sz = which way the building extends from this corner
        n = int(H / size)
        for i in range(n):
            y = size * (i + 0.5)
            long_x = (i % 2 == 0)
            lx = 1.5 if long_x else 0.95; lz = 0.95 if long_x else 1.5
            box(None, "Quoin", (x + sx * (lx / 2 - out), y, z + sz * (lz / 2 - out)), lx, size - 0.06, lz, tris_out=k.t("Quoin"))


def face_frame(face, xl, xr, zf, zb):
    """axis, base coordinate and outward sign for a wall face."""
    axis = "z" if face in ("front", "back") else "x"
    base = {"front": zf, "back": zb, "left": xl, "right": xr}[face]
    out = {"front": -1, "back": 1, "left": -1, "right": 1}[face]
    return axis, base, out


def span(base, out, d_in, d_out):
    a, b = base - out * d_in, base + out * d_out
    return (min(a, b), max(a, b))


def window(k, face, xl, xr, zf, zb, u, y0, w, h, shutters=True, lintel=True, sill=True, glass="Window"):
    """A rectangular window standing proud of the wall: glass, a stone frame, mullions, sill, wooden lintel and a pair
    of open plank shutters (blue) hinged beside it."""
    axis, base, out = face_frame(face, xl, xr, zf, zb)
    t = 0.35
    inner = rect_profile(u, y0, w, h); outer = rect_profile(u, y0 - t, w + 2 * t, h + 2 * t)
    extrude(None, glass, inner, axis, *span(base, out, 0.10, 0.13), tris_out=k.t(glass))
    extrude_ring(None, "Trim", outer, inner, axis, *span(base, out, 0.05, 0.32), tris_out=k.t("Trim"))
    mid = sum(span(base, out, -0.12, 0.24)) / 2
    def P(a, y, c): return (a, y, c) if axis == "z" else (c, y, a)
    box(None, "Trim", P(u, y0 + h / 2, mid), *((0.14, h, 0.12) if axis == "z" else (0.12, h, 0.14)), tris_out=k.t("Trim"))
    box(None, "Trim", P(u, y0 + h * 0.55, mid), *((w, 0.14, 0.12) if axis == "z" else (0.12, 0.14, w)), tris_out=k.t("Trim"))
    if sill:
        box(None, "Trim", P(u, y0 - t - 0.2, base + out * 0.35), *((w + 1.0, 0.4, 0.9) if axis == "z" else (0.9, 0.4, w + 1.0)), tris_out=k.t("Trim"))
    if lintel:
        box(None, "Wood", P(u, y0 + h + t + 0.25, base + out * 0.2), *((w + 1.2, 0.5, 0.6) if axis == "z" else (0.6, 0.5, w + 1.2)), tris_out=k.t("Wood"))
    if shutters:
        sw = w / 2 + 0.1
        for sgn in (-1, 1):
            cu = u + sgn * (w / 2 + t + 0.12 + sw / 2)
            box(None, "Shutter", P(cu, y0 + h / 2, base + out * 0.16), *((sw, h + 0.3, 0.2) if axis == "z" else (0.2, h + 0.3, sw)), tris_out=k.t("Shutter"))
            for yy in (y0 + 0.4, y0 + h - 0.4):       # cross braces
                box(None, "ShutterB", P(cu, yy, base + out * 0.3), *((sw - 0.2, 0.28, 0.1) if axis == "z" else (0.1, 0.28, sw - 0.2)), tris_out=k.t("ShutterB"))
            # the diagonal of the Z-brace
            p0 = P(cu - sw * 0.4, y0 + 0.5, base + out * 0.31); p1 = P(cu + sw * 0.4, y0 + h - 0.5, base + out * 0.31)
            beam(k.t("ShutterB"), p0, p1, 0.26, 0.08)


def door_arch(k, face, xl, xr, zf, zb, u, w, hr, step=True, leaf="Door", keystone=True):
    """Arched doorway: recessed door leaf, stone arch ring, keystone, a stone step."""
    axis, base, out = face_frame(face, xl, xr, zf, zb)
    t = 0.45
    inner = arch_profile(u, 0.0, w, hr); outer = arch_profile(u, -0.001, w + 2 * t, hr)
    extrude(None, leaf, inner, axis, *span(base, out, 0.05, 0.12), tris_out=k.t(leaf))
    extrude_ring(None, "Trim", outer, inner, axis, *span(base, out, 0.02, 0.4), tris_out=k.t("Trim"))
    def P(a, y, c): return (a, y, c) if axis == "z" else (c, y, a)
    # plank lines on the door: thin dark strips
    for i in range(1, 4):
        cu = u - w / 2 + w * i / 4
        box(None, "Dark", P(cu, hr / 2, base + out * 0.13), *((0.06, hr, 0.04) if axis == "z" else (0.04, hr, 0.06)), tris_out=k.t("Dark"))
    # handle
    box(None, "Iron", P(u + w * 0.3, hr * 0.45, base + out * 0.2), *((0.3, 0.3, 0.2) if axis == "z" else (0.2, 0.3, 0.3)), tris_out=k.t("Iron"))
    if keystone:
        box(None, "Quoin", P(u, hr + w / 2 + t / 2, base + out * 0.25), *((0.9, 1.0, 0.6) if axis == "z" else (0.6, 1.0, 0.9)), tris_out=k.t("Quoin"))
    if step:
        box(None, "Stone", P(u, 0.18, base + out * 0.8), *((w + 1.4, 0.36, 1.6) if axis == "z" else (1.6, 0.36, w + 1.4)), tris_out=k.t("Stone"))


def lantern(k, face, xl, xr, zf, zb, u, y):
    axis, base, out = face_frame(face, xl, xr, zf, zb)
    def P(a, yy, c): return (a, yy, c) if axis == "z" else (c, yy, a)
    box(None, "Iron", P(u, y + 0.5, base + out * 0.35), *((0.12, 0.12, 0.7) if axis == "z" else (0.7, 0.12, 0.12)), tris_out=k.t("Iron"))
    box(None, "Iron", P(u, y, base + out * 0.75), 0.55, 0.9, 0.55, tris_out=k.t("Iron"))
    box(None, "Glass", P(u, y, base + out * 0.75), 0.42, 0.7, 0.42, tris_out=k.t("Glass"))
    box(None, "Iron", P(u, y + 0.55, base + out * 0.75), 0.7, 0.15, 0.7, tris_out=k.t("Iron"))


def chimney(k, x, z, y_base, h, w=1.6, d=1.6):
    box(None, "Chimney", (x, y_base + h / 2, z), w, h, d, tris_out=k.t("Chimney"))
    box(None, "Chimney", (x, y_base + h + 0.2, z), w + 0.5, 0.4, d + 0.5, tris_out=k.t("Chimney"))
    box(None, "Dark", (x, y_base + h + 0.45, z), w * 0.55, 0.2, d * 0.55, tris_out=k.t("Dark"))


# ------------------------------------------------------------- the mas ----
def mas(name, seed):
    """Provençal stone farmhouse: 32 x 20, two floors, tile roof along x, blue shutters, quoins, chimney, dovecote."""
    k = Kit(); rnd = random.Random(seed)
    W, D, H1, H2, RH = 32.0, 20.0, 10.0, 9.0, 6.2
    H = H1 + H2
    xl, xr, zf, zb = -W / 2, W / 2, -D / 2, D / 2
    box(None, "Walls", (0, H / 2, 0), W, H, D, tris_out=k.t("Walls"))
    tile_roof(k, xl, xr, zf, zb, H, RH, ov=1.4)
    quoins(k, ((xl, zf, 1, 1), (xr, zf, -1, 1), (xl, zb, 1, -1), (xr, zb, -1, -1)), H)
    # a string course between the floors
    box(None, "Trim", (0, H1 + 0.3, zf - 0.1), W + 0.3, 0.35, 0.3, tris_out=k.t("Trim"))
    # front: door with two windows each side; upper: four windows
    door_arch(k, "front", xl, xr, zf, zb, 0.0, 4.4, 5.4)
    lantern(k, "front", xl, xr, zf, zb, 3.6, 7.6)
    for u in (-11.0, -6.0, 6.0, 11.0):
        window(k, "front", xl, xr, zf, zb, u, 2.6, 3.0, 4.6)
    for u in (-11.0, -4.0, 4.0, 11.0):
        window(k, "front", xl, xr, zf, zb, u, H1 + 2.2, 3.0, 4.4)
    # sides and back
    # (Sep 27 2026, Shannon: at the back "the window to the right of the door has a shutter overlapping the door and the
    # windows on the left are missing their left shutter ... since its the back of the house, simply remove the door
    # and respace the windows so they all fit with shutters". A window with its shutters is 7.14 wide; the dovecote
    # takes the back-left corner to x -11.8 and the quoins the right one from 14.6, so three fit at -6.8 / 1.4 / 9.6
    # with a stud between them. On the left side the upper window's right shutter ran into the dovecote too: 1.2, not 3.)
    for face in ("left", "right"):
        window(k, face, xl, xr, zf, zb, -3.0, 2.6, 3.0, 4.6)
        window(k, face, xl, xr, zf, zb, 1.2 if face == "left" else 3.0, H1 + 2.2, 3.0, 4.4)
    for u in (-6.8, 1.4, 9.6):
        window(k, "back", xl, xr, zf, zb, u, 2.6, 3.0, 4.6)
        window(k, "back", xl, xr, zf, zb, u, H1 + 2.2, 3.0, 4.4)
    chimney(k, xr - 3.5, 0.0, H + RH - 1.2, 4.0)
    # dovecote: a square tower on the back-left corner rising above the roof, with a little tile roof and pigeon holes
    tx, tz, tw = xl + 1.6, zb - 1.6, 5.2                # proud of the back-left corner so it reads as a tower
    TH = H + RH + 5.0
    box(None, "Walls", (tx, TH / 2, tz), tw, TH, tw, tris_out=k.t("Walls"))
    quoins(k, ((tx - tw / 2, tz - tw / 2, 1, 1), (tx + tw / 2, tz - tw / 2, -1, 1), (tx - tw / 2, tz + tw / 2, 1, -1), (tx + tw / 2, tz + tw / 2, -1, -1)), TH, size=0.5, out=0.1)
    tile_roof(k, tx - tw / 2, tx + tw / 2, tz - tw / 2, tz + tw / 2, TH, 1.6, ov=0.7, thick=0.35)
    for i in range(3):
        for face, ff in (("front", tz - tw / 2), ("left", tx - tw / 2)):
            if face == "front":
                box(None, "Dark", (tx - 1.4 + 1.4 * i, TH - 2.4, ff - 0.1), 0.7, 0.9, 0.2, tris_out=k.t("Dark"))
                box(None, "Trim", (tx - 1.4 + 1.4 * i, TH - 3.0, ff - 0.25), 0.9, 0.2, 0.5, tris_out=k.t("Trim"))
            else:
                box(None, "Dark", (ff - 0.1, TH - 2.4, tz - 1.4 + 1.4 * i), 0.2, 0.9, 0.7, tris_out=k.t("Dark"))
                box(None, "Trim", (ff - 0.25, TH - 3.0, tz - 1.4 + 1.4 * i), 0.5, 0.2, 0.9, tris_out=k.t("Trim"))
    return k.write(name)


# ------------------------------------------------------------- the barn ----
def barn(name, seed):
    k = Kit()
    W, D, H, RH = 30.0, 22.0, 13.0, 7.0
    xl, xr, zf, zb = -W / 2, W / 2, -D / 2, D / 2
    box(None, "Walls", (0, 2.6, 0), W, 5.2, D, tris_out=k.t("Walls"))                 # stone plinth
    box(None, "Plank", (0, 5.2 + (H - 5.2) / 2, 0), W - 0.2, H - 5.2, D - 0.2, tris_out=k.t("Plank"))
    # board lines on the timber walls
    for face, base, out, axis in (("front", zf - 0.1, -1, "z"), ("back", zb + 0.1, 1, "z"), ("left", xl - 0.1, -1, "x"), ("right", xr + 0.1, 1, "x")):
        L = W if axis == "z" else D
        for i in range(7):
            y = 5.6 + i * 1.05
            if axis == "z": box(None, "Wood", (0, y, base + out * 0.06), L - 0.6, 0.14, 0.12, tris_out=k.t("Wood"))
            else: box(None, "Wood", (base + out * 0.06, y, 0), 0.12, 0.14, L - 0.6, tris_out=k.t("Wood"))
    tile_roof(k, xl, xr, zf, zb, H, RH, ov=1.6, walls="Plank")
    quoins(k, ((xl, zf, 1, 1), (xr, zf, -1, 1), (xl, zb, 1, -1), (xr, zb, -1, -1)), 5.2, size=0.6, out=0.12)
    # big double doors, one leaf ajar
    dw, dh = 10.0, 10.0
    box(None, "Dark", (0, dh / 2, zf - 0.05), dw, dh, 0.2, tris_out=k.t("Dark"))
    box(None, "Door", (-dw / 4, dh / 2, zf - 0.25), dw / 2 - 0.1, dh - 0.2, 0.3, tris_out=k.t("Door"))
    beam(k.t("Wood"), (-dw / 2 + 0.3, 0.6, zf - 0.45), (-0.4, dh - 0.6, zf - 0.45), 0.5, 0.15)
    beam(k.t("Wood"), (-dw / 2 + 0.3, dh - 0.6, zf - 0.45), (-0.4, 0.6, zf - 0.45), 0.5, 0.15)
    # right leaf swung open ~70 degrees, hinged at the right jamb
    ang = math.radians(70)
    hx, hz = dw / 2, zf
    cx = hx - (dw / 4) * math.cos(ang); cz = hz - (dw / 4) * math.sin(ang)
    box(None, "Door", (cx, dh / 2, cz), dw / 2 - 0.1, dh - 0.2, 0.3, tris_out=k.t("Door"), yaw=-ang)
    box(None, "Wood", (0, dh + 0.5, zf - 0.3), dw + 1.6, 0.8, 0.6, tris_out=k.t("Wood"))      # header beam
    # hayloft: a dark opening in the front gable, a small door swung open, hay spilling, a hoist beam and pulley
    ly = H + 2.0
    box(None, "Dark", (0, ly, zf - 0.02), 4.2, 4.0, 0.3, tris_out=k.t("Dark"))
    box(None, "Door", (2.1 + 0.15, ly, zf - 1.1), 0.3, 3.9, 2.1, tris_out=k.t("Door"))
    box(None, "Wood", (0, ly - 2.15, zf - 0.35), 4.8, 0.35, 0.8, tris_out=k.t("Wood"))
    blob(k.t("Hay"), (-0.6, ly - 1.4, zf - 0.3), 1.2, random.Random(seed), 0.2, (1.3, 0.6, 0.9))
    beam(k.t("Wood"), (0, ly + 2.8, zf + 0.5), (0, ly + 2.8, zf - 3.2), 0.5, 0.5)
    cyl(k.t("Iron"), (0, ly + 2.2, zf - 3.0), 0.45, 0.45, 0.25, 10)
    box(None, "Iron", (0, ly + 0.6, zf - 3.0), 0.08, 3.4, 0.08, tris_out=k.t("Iron"))         # the rope
    return k.write(name)


# ------------------------------------------------------------- the chapel ----
def chapel(name, seed):
    """Small stone chapel: nave 14 x 22 (ridge along z, gable to the front), bell tower with an open belfry and bell,
    a rose window, arched windows, cross on top."""
    k = Kit()
    W, D, H, RH = 14.0, 22.0, 12.0, 5.5
    xl, xr, zf, zb = -W / 2, W / 2, -D / 2, D / 2
    box(None, "Walls", (0, H / 2, 0), W, H, D, tris_out=k.t("Walls"))
    tile_roof(k, xl, xr, zf, zb, H, RH, ov=1.2, along="z")
    quoins(k, ((xl, zf, 1, 1), (xr, zf, -1, 1), (xl, zb, 1, -1), (xr, zb, -1, -1)), H)
    door_arch(k, "front", xl, xr, zf, zb, 0.0, 4.2, 5.6)
    box(None, "Stone", (0, 0.45, zf - 1.9), 7.0, 0.36, 1.2, tris_out=k.t("Stone"))          # second step
    # rose window in the front gable
    tri = k.t("Trim"); gl = k.t("Glass")
    ry = H + RH * 0.45
    ring_o = ring_n((0, ry, zf - 0.3), (0, 0, -1), 2.0, 12); ring_i = ring_n((0, ry, zf - 0.3), (0, 0, -1), 1.45, 12)
    ring_o2 = ring_n((0, ry, zf + 0.1), (0, 0, -1), 2.0, 12); ring_i2 = ring_n((0, ry, zf + 0.1), (0, 0, -1), 1.45, 12)
    for i in range(12):
        j = (i + 1) % 12
        tri += [(ring_o[i], ring_i[j], ring_o[j]), (ring_o[i], ring_i[i], ring_i[j])]        # front annulus, faces -z
        tri += [(ring_o[i], ring_o[j], ring_o2[j]), (ring_o[i], ring_o2[j], ring_o2[i])]    # outer band
    gl += []
    G.disc(gl, (0, ry, zf - 0.05), (0, 0, -1), 1.5, 0.12, 12)
    for i in range(6):                                                                     # spokes
        a = math.pi * i / 6
        beam(tri, (1.45 * math.cos(a), ry + 1.45 * math.sin(a), zf - 0.2), (-1.45 * math.cos(a), ry - 1.45 * math.sin(a), zf - 0.2), 0.16, 0.16)
    # arched side windows
    for face in ("left", "right"):
        for u in (-6.0, 0.0, 6.0):
            axis, base, out = face_frame(face, xl, xr, zf, zb)
            inner = arch_profile(u, 3.0, 2.2, 3.4); outer = arch_profile(u, 2.65, 2.9, 3.4)
            extrude(None, "Glass", inner, axis, *span(base, out, 0.1, 0.13), tris_out=k.t("Glass"))
            extrude_ring(None, "Trim", outer, inner, axis, *span(base, out, 0.05, 0.3), tris_out=k.t("Trim"))
    # bell tower on the front-right corner
    tx, tz, tw, TH = xr - 3.5, zf + 3.5, 6.0, 26.0
    box(None, "Walls", (tx, TH / 2, tz), tw, TH, tw, tris_out=k.t("Walls"))
    quoins(k, ((tx - tw / 2, tz - tw / 2, 1, 1), (tx + tw / 2, tz - tw / 2, -1, 1), (tx - tw / 2, tz + tw / 2, 1, -1), (tx + tw / 2, tz + tw / 2, -1, -1)), TH, size=0.55, out=0.1)
    # belfry openings (dark arches) on all four sides, a bell hanging inside the front one
    by = TH - 6.0
    for face in ("front", "back", "left", "right"):
        axis, base, out = face_frame(face, tx - tw / 2, tx + tw / 2, tz - tw / 2, tz + tw / 2)
        u = tx if axis == "z" else tz
        inner = arch_profile(u, by, 2.4, 3.0); outer = arch_profile(u, by - 0.35, 3.1, 3.0)
        extrude(None, "Dark", inner, axis, *span(base, out, -0.4, 0.05), tris_out=k.t("Dark"))
        extrude_ring(None, "Trim", outer, inner, axis, *span(base, out, 0.02, 0.3), tris_out=k.t("Trim"))
    bell = k.t("Bell")
    rings = [ring((tx, 0, tz - tw / 2 + 0.6), r, by + y, 10) for r, y in ((0.5, 3.6), (0.7, 2.6), (0.95, 1.6), (1.1, 1.25), (1.0, 1.1))]
    tube_out(bell, rings, (tx, by + 1.0, tz - tw / 2 + 0.6), (tx, by + 4.0, tz - tw / 2 + 0.6), True, True)
    box(None, "Wood", (tx, by + 3.9, tz - tw / 2 + 0.6), 3.0, 0.3, 0.3, tris_out=k.t("Wood"))
    # pyramid roof (slate) and a cross
    apex = (tx, TH + 5.0, tz)
    corners = [(tx - tw / 2 - 0.5, TH, tz - tw / 2 - 0.5), (tx + tw / 2 + 0.5, TH, tz - tw / 2 - 0.5), (tx + tw / 2 + 0.5, TH, tz + tw / 2 + 0.5), (tx - tw / 2 - 0.5, TH, tz + tw / 2 + 0.5)]
    sl = k.t("Slate")
    for i in range(4):
        a, b = corners[i], corners[(i + 1) % 4]
        fn = cross(sub(b, a), sub(apex, a)); cen = mul(add(add(a, b), apex), 1 / 3)
        if dot(fn, sub(cen, (tx, TH + 1.5, tz))) < 0: a, b = b, a
        sl.append((a, b, apex))
    box(None, "Slate", (tx, TH - 0.2, tz), tw + 1.0, 0.4, tw + 1.0, tris_out=sl)
    box(None, "Cross", (tx, TH + 6.4, tz), 0.22, 2.8, 0.22, tris_out=k.t("Cross"))
    box(None, "Cross", (tx, TH + 6.9, tz), 1.5, 0.22, 0.22, tris_out=k.t("Cross"))
    return k.write(name)


# ------------------------------------------------------------- the windmill ----
def windmill(name, seed):
    """Stone tower with a slate cap, a spiral stone stair to a side platform, an arched door; the four lattice sails
    are one separate piece 'Sails' (pivot at the hub) that the builder turns."""
    k = Kit(); rnd = random.Random(seed)
    R0, R1, TH = 5.6, 4.6, 20.0
    cyl(k.t("Stone"), (0, 0, 0), R0, R1, TH, 14, rnd=rnd, jitter=0.02)
    # a stone band at the top and the slate cap
    cyl(k.t("Trim"), (0, TH - 0.5, 0), R1 + 0.35, R1 + 0.35, 0.6, 14)
    cyl(k.t("Slate"), (0, TH, 0), R1 + 0.6, 0.35, 5.6, 14)
    blob(k.t("Brass"), (0, TH + 5.9, 0), 0.5, rnd, 0.05)
    # door at the front, small windows
    zf = -R0
    door_arch(k, "front", -R0, R0, zf + 0.3, R0, 0.0, 3.6, 4.6)
    for y, r in ((9.0, R0 - (R0 - R1) * 9 / TH), (14.5, R0 - (R0 - R1) * 14.5 / TH)):
        window(k, "front", -r, r, -r + 0.25, r, 0.0, y, 1.8, 2.6, shutters=False, lintel=False)
    # spiral stair up the right side to a platform with a railing and a door
    steps = 20
    a0, a1 = math.radians(-70), math.radians(110)
    for i in range(steps):
        a = a0 + (a1 - a0) * i / steps
        r_wall = R0 - (R0 - R1) * (0.4 * i / steps)
        rc = r_wall + 1.0
        y = 0.22 + 0.42 * i
        c = (rc * math.cos(a), y, rc * math.sin(a))
        box(None, "Stone", c, 2.6, 0.44, 1.5, tris_out=k.t("Stone"), yaw=-a)
        if i % 2 == 1:
            px, pz = (rc + 1.05) * math.cos(a), (rc + 1.05) * math.sin(a)
            box(None, "Iron", (px, y + 1.0, pz), 0.12, 2.0, 0.12, tris_out=k.t("Iron"))
            if i >= 3:
                a_prev = a0 + (a1 - a0) * (i - 2) / steps; yp = 0.22 + 0.42 * (i - 2)
                beam(k.t("Iron"), ((rc + 1.05) * math.cos(a_prev), yp + 2.0, (rc + 1.05) * math.sin(a_prev)), (px, y + 2.0, pz), 0.1, 0.1)
    ap = a1; rp = R0 - (R0 - R1) * 0.42
    yp = 0.22 + 0.42 * steps
    pc = ((rp + 1.6) * math.cos(ap), yp, (rp + 1.6) * math.sin(ap))
    box(None, "Stone", pc, 3.6, 0.44, 3.2, tris_out=k.t("Stone"), yaw=-ap)
    for sgn in (-1, 1):
        px = pc[0] + 1.75 * math.cos(ap) + sgn * 1.5 * math.sin(ap); pz = pc[2] + 1.75 * math.sin(ap) - sgn * 1.5 * math.cos(ap)
        box(None, "Iron", (px, yp + 1.0, pz), 0.12, 2.0, 0.12, tris_out=k.t("Iron"))
    beam(k.t("Iron"), (pc[0] + 1.75 * math.cos(ap) - 1.5 * math.sin(ap), yp + 2.0, pc[2] + 1.75 * math.sin(ap) + 1.5 * math.cos(ap)),
         (pc[0] + 1.75 * math.cos(ap) + 1.5 * math.sin(ap), yp + 2.0, pc[2] + 1.75 * math.sin(ap) - 1.5 * math.cos(ap)), 0.1, 0.1)
    # the upper door behind the platform (a dark recess with a leaf)
    dx, dz = (rp - 0.05) * math.cos(ap), (rp - 0.05) * math.sin(ap)
    box(None, "Door", (dx, yp + 2.6, dz), 2.2, 4.6, 0.3, tris_out=k.t("Door"), yaw=-ap + math.pi / 2)
    # sails: separate piece. Hub on the front face at height 15.5, sails in an X.
    hub = (0.0, 15.5, zf - 1.4)
    box(None, "Wood", (0, 15.5, zf + 0.2), 2.0, 2.0, 2.4, tris_out=k.t("Wood"))             # the axle housing (part of the tower)
    S = k.t("Sails")
    hr = ring_n(hub, (0, 0, -1), 1.0, 10); hr2 = ring_n(add(hub, (0, 0, -1.2)), (0, 0, -1), 1.0, 10)
    tube_out(S, [hr, hr2], hub, add(hub, (0, 0, -1.2)), True, True)
    for q in range(4):
        a = math.radians(45 + 90 * q)
        dirv = (math.cos(a), math.sin(a), 0.0); side = (-math.sin(a), math.cos(a), 0.0)
        tip = add(hub, mul(dirv, 13.0))
        beam(S, add(hub, mul(dirv, 0.6)), tip, 0.42, 0.42)
        for s in (-1.0, 1.0):
            beam(S, add(add(hub, mul(dirv, 3.5)), add(mul(side, s * 1.05), (0, 0, -0.35))), add(add(hub, mul(dirv, 12.6)), add(mul(side, s * 1.05), (0, 0, -0.35))), 0.16, 0.16)
        for i in range(10):
            d = 3.5 + i * 1.0
            beam(S, add(add(hub, mul(dirv, d)), add(mul(side, -1.15), (0, 0, -0.35))), add(add(hub, mul(dirv, d)), add(mul(side, 1.15), (0, 0, -0.35))), 0.14, 0.14)
    return k.write(name)


# ------------------------------------------------------------- the cellar ----
def cellar_front(name, seed):
    """A stone facade with a real arched doorway and a stone room behind it (the hill hides the outside of the room).
    Facade 16 x 9, opening 5 wide x 7.5 tall, room 5 x 8 deep. Barrels etc. are separate kits placed inside."""
    k = Kit()
    W, H, T = 16.0, 9.0, 3.0
    ow, ohr = 5.0, 5.0                        # opening width, rectangular height (arch adds ow/2)
    zf = -T / 2
    for sgn in (-1, 1):                      # piers
        cx = sgn * (ow / 2 + (W / 2 - ow / 2) / 2)
        box(None, "Walls", (cx, H / 2, 0), W / 2 - ow / 2, H, T, tris_out=k.t("Walls"))
    top_arch = ohr + ow / 2
    box(None, "Walls", (0, (H + top_arch) / 2, 0), ow + 0.2, H - top_arch, T, tris_out=k.t("Walls"))   # header over the arch
    t = 0.5
    inner = arch_profile(0.0, 0.0, ow, ohr); outer = arch_profile(0.0, -0.001, ow + 2 * t, ohr)
    extrude_ring(None, "Trim", outer, inner, "z", zf - 0.4, zf, tris_out=k.t("Trim"))            # proud arch ring
    extrude_ring(None, "Vault", inner, arch_profile(0.0, 0.0, ow - 0.02, ohr), "z", zf, T / 2 + 8.0, tris_out=k.t("Vault"))   # the passage lining (hairline band)
    box(None, "Quoin", (0, top_arch + 0.25, zf - 0.3), 1.0, 1.1, 0.7, tris_out=k.t("Quoin"))
    quoins(k, ((-W / 2, zf, 1, 1), (W / 2, zf, -1, 1)), H)
    box(None, "Trim", (0, H + 0.25, 0), W + 0.6, 0.5, T + 0.6, tris_out=k.t("Trim"))              # coping
    # the room: a shell of boxes whose inner faces show (floor, walls, ceiling)
    D = 8.0; zb = T / 2 + D
    box(None, "Vault", (0, -0.25, (T / 2 + zb) / 2), ow + 2.0, 0.5, D + 0.4, tris_out=k.t("Vault"))         # floor slab (top at 0)
    box(None, "Vault", (0, (ohr + ow / 2) / 2 + 0.25, zb + 0.5), ow + 2.0, ohr + ow / 2 + 0.5, 1.0, tris_out=k.t("Vault"))   # back wall
    for sgn in (-1, 1):
        box(None, "Vault", (sgn * (ow / 2 + 0.5), (top_arch) / 2, (T / 2 + zb) / 2), 1.0, top_arch, D + 0.4, tris_out=k.t("Vault"))
    box(None, "Vault", (0, top_arch + 0.5, (T / 2 + zb) / 2), ow + 2.0, 1.0, D + 0.4, tris_out=k.t("Vault"))        # ceiling
    # the outside of the room: a stone block the hill is heaped over, and a flat stone roof slab
    box(None, "Walls", (0, (top_arch + 1.2) / 2, (T / 2 + zb + 0.8) / 2), ow + 4.6, top_arch + 1.2, zb + 0.8 - T / 2, tris_out=k.t("Walls"))
    box(None, "Stone", (0, top_arch + 1.5, (T / 2 + zb + 0.8) / 2), ow + 5.2, 0.6, zb + 1.4 - T / 2, tris_out=k.t("Stone"))
    # a lantern by the door
    lantern(k, "front", -W / 2, W / 2, zf, T / 2, -4.2, 6.0)
    return k.write(name)


# ------------------------------------------------------------- the distiller's hut ----
def hut(name, seed):
    k = Kit()
    W, D, H, RH = 10.0, 8.0, 7.0, 3.2
    xl, xr, zf, zb = -W / 2, W / 2, -D / 2, D / 2
    box(None, "Walls", (0, H / 2, 0), W, H, D, tris_out=k.t("Walls"))
    tile_roof(k, xl, xr, zf, zb, H, RH, ov=1.0, thick=0.4)
    quoins(k, ((xl, zf, 1, 1), (xr, zf, -1, 1), (xl, zb, 1, -1), (xr, zb, -1, -1)), H, size=0.55, out=0.1)
    door_arch(k, "front", xl, xr, zf, zb, -2.2, 3.0, 4.2, keystone=False)
    window(k, "front", xl, xr, zf, zb, 2.4, 2.4, 2.2, 2.6)
    chimney(k, xr - 1.5, 0.0, H + RH - 0.8, 2.6, 1.2, 1.2)
    # lean-to on the right: two posts and a sloped plank roof sheltering the still (placed by the builder)
    for z in (zf, zb):
        box(None, "Wood", (xr + 7.0, 2.8, z), 0.4, 5.6, 0.4, tris_out=k.t("Wood"))
    A, B = (xr - 0.2, H - 0.3, zf - 0.6), (xr - 0.2, H - 0.3, zb + 0.6)
    C, Dd = (xr + 7.6, 5.7, zb + 0.6), (xr + 7.6, 5.7, zf - 0.6)
    n = cross(sub(B, A), sub(Dd, A))
    if n[1] > 0: A, B, C, Dd = A, Dd, C, B
    thick_quad(k.t("Plank"), A, B, C, Dd, 0.3)
    beam(k.t("Wood"), (xr + 7.0, 5.5, zf - 0.4), (xr + 7.0, 5.5, zb + 0.4), 0.35, 0.35)
    return k.write(name)


# ------------------------------------------------------------- the coop ----
def coop(name, seed):
    """Plank hen house on legs with a ramp, nesting box, and a wire run in front of it (12 x 9)."""
    k = Kit()
    W, D, H, LEG = 8.0, 6.0, 5.0, 1.5
    xl, xr, zf, zb = -W / 2, W / 2, -D / 2, D / 2
    for x in (xl + 0.4, xr - 0.4):
        for z in (zf + 0.4, zb - 0.4):
            box(None, "Wood", (x, LEG / 2, z), 0.5, LEG, 0.5, tris_out=k.t("Wood"))
    box(None, "Plank", (0, LEG + H / 2, 0), W, H, D, tris_out=k.t("Plank"))
    for i in range(4):
        y = LEG + 0.8 + i * 1.1
        box(None, "Wood", (0, y, zf - 0.06), W - 0.4, 0.12, 0.12, tris_out=k.t("Wood"))
        box(None, "Wood", (0, y, zb + 0.06), W - 0.4, 0.12, 0.12, tris_out=k.t("Wood"))
    tile_roof(k, xl, xr, zf, zb, LEG + H, 2.4, ov=0.9, walls="Plank", tile_rows=False, thick=0.3)
    # the pop door and ramp with cleats
    box(None, "Dark", (-1.8, LEG + 1.5, zf - 0.03), 1.8, 2.6, 0.2, tris_out=k.t("Dark"))
    p0, p1 = (-1.8, LEG + 0.2, zf - 0.2), (-1.8, 0.1, zf - 4.0)
    beam(k.t("Plank"), p0, p1, 1.6, 0.15)
    for i in range(6):
        f = (i + 0.5) / 6
        c = add(p0, mul(sub(p1, p0), f))
        beam(k.t("Wood"), add(c, (-0.8, 0.12, 0)), add(c, (0.8, 0.12, 0)), 0.18, 0.14)
    # nesting box on the back
    box(None, "Plank", (2.0, LEG + 2.0, zb + 1.0), 3.0, 2.2, 2.0, tris_out=k.t("Plank"))
    box(None, "Wood", (2.0, LEG + 3.25, zb + 1.1), 3.4, 0.25, 2.5, tris_out=k.t("Wood"))
    # window with a wire mesh
    box(None, "Dark", (2.4, LEG + 3.0, zf - 0.03), 2.0, 1.4, 0.2, tris_out=k.t("Dark"))
    for i in range(5):
        box(None, "Wire", (1.6 + i * 0.4, LEG + 3.0, zf - 0.15), 0.05, 1.4, 0.05, tris_out=k.t("Wire"))
    # the run: posts, rails and vertical wires, open where it meets the coop front
    RW, RD = 12.0, 9.0
    rx0, rx1, rz0, rz1 = -RW / 2, RW / 2, zf - RD, zf
    # a 2.4-wide gateway in the right-hand side (its leaf stands open) lets the hens out to follow whoever feeds them
    gz0, gz1 = (rz0 + rz1) / 2 - 1.2, (rz0 + rz1) / 2 + 1.2
    posts = [(rx0, rz0), (rx1, rz0), (rx0, rz1), (rx1, rz1), (0, rz0), (rx0, (rz0 + rz1) / 2), (rx1, gz0), (rx1, gz1)]
    for (x, z) in posts:
        box(None, "Wood", (x, 1.4, z), 0.3, 2.8, 0.3, tris_out=k.t("Wood"))
    segs = [((rx0, rz0), (rx1, rz0)), ((rx0, rz0), (rx0, rz1)), ((rx1, rz0), (rx1, gz0)), ((rx1, gz1), (rx1, rz1)), ((rx0, rz1), (xl, rz1)), ((xr, rz1), (rx1, rz1))]
    # the gate leaf: a wired frame hinged on the post at gz0, swung 110 degrees outward
    ga = math.radians(110)
    gd = (math.sin(ga), 0, math.cos(ga))
    hinge = (rx1 + 0.15, 0, gz0 + 0.15)
    tip = add(hinge, mul(gd, 2.1))
    for y in (0.45, 2.55):
        beam(k.t("Wood"), (hinge[0], y, hinge[2]), (tip[0], y, tip[2]), 0.1, 0.1)
    box(None, "Wood", (tip[0], 1.5, tip[2]), 0.12, 2.3, 0.12, tris_out=k.t("Wood"))
    for i in range(1, 5):
        c = add(hinge, mul(gd, 2.1 * i / 5))
        box(None, "Wire", (c[0], 1.5, c[2]), 0.05, 2.1, 0.05, tris_out=k.t("Wire"))
    for (a, b) in segs:
        for y in (0.4, 2.7):
            beam(k.t("Wood"), (a[0], y, a[1]), (b[0], y, b[1]), 0.12, 0.12)
        L = math.hypot(b[0] - a[0], b[1] - a[1]); n = int(L / 0.6)
        for i in range(1, n):
            f = i / n
            x, z = a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f
            box(None, "Wire", (x, 1.55, z), 0.05, 2.3, 0.05, tris_out=k.t("Wire"))
    return k.write(name)


def hen(name, seed):
    k = Kit(); rnd = random.Random(seed)
    blob(k.t("Hen"), (0, 0.95, 0), 0.62, rnd, 0.1, (0.9, 0.85, 1.25))
    blob(k.t("Hen"), (0, 1.55, -0.55), 0.32, rnd, 0.08)
    for i in range(3):
        a = math.radians(35 + i * 25)
        beam(k.t("Hen"), (0, 1.15, 0.5), (0, 1.15 + 0.7 * math.sin(a), 0.5 + 0.55 * math.cos(a)), 0.32 - i * 0.06, 0.08)
    box(None, "Comb", (0, 1.9, -0.55), 0.12, 0.3, 0.35, tris_out=k.t("Comb"))
    stem(k.t("Beak"), (0, 1.5, -0.8), (0, 1.45, -1.1), 0.09, 0.02, 4)
    for sgn in (-1, 1):
        stem(k.t("HenLeg"), (sgn * 0.18, 0.55, 0.0), (sgn * 0.2, 0.0, 0.05), 0.05, 0.05, 4)
        box(None, "HenLeg", (sgn * 0.2, 0.03, -0.05), 0.2, 0.06, 0.45, tris_out=k.t("HenLeg"))
    return k.write(name)


if __name__ == "__main__":
    counts = {}
    counts["mas"] = mas("mas", 201)
    counts["barn"] = barn("barn", 202)
    counts["chapel"] = chapel("chapel", 203)
    counts["windmill"] = windmill("windmill", 204)
    counts["cellar_front"] = cellar_front("cellar_front", 205)
    counts["hut"] = hut("hut", 206)
    counts["coop"] = coop("coop", 207)
    counts["hen"] = hen("hen", 208)
    for k_, v in counts.items():
        print(f"{k_:14s} {v:6d} tris")
