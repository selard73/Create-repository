"""
Village kit for 1001 Squirrels: a small old-town street in the south of France, in the same low-poly flat-shaded
untextured style as the forest kit. Every prop is one .obj; colour-able pieces are separate objects.
Units are studs, Y up, every prop stands on y = 0 and faces -Z (its "front" is toward negative Z).

Props: townhouse_a/b/c (walls, roof, shutters, awning, door, windows), cafe_table, parasol, lamp_post, planter,
       fountain, bollards, shop_sign, bench, bicycle, bridge (arched, with railings), plane_tree
Run:  python gen_village.py
"""
import math, random, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent / "forest"))
import gen_forest as F
from gen_forest import Obj, ring, tube, icoblob, slab, add, mul, sum_pts

OUT = Path(__file__).parent
F.GRAYS.update({
    "Wall": (0.90, 0.88, 0.82), "Roof": (0.62, 0.48, 0.42), "Shutter": (0.55, 0.62, 0.70), "Awning": (0.75, 0.45, 0.42),
    "Door": (0.45, 0.35, 0.30), "Window": (0.55, 0.65, 0.75), "Trim": (0.95, 0.94, 0.90), "Chimney": (0.70, 0.60, 0.55),
    "Table": (0.35, 0.33, 0.32), "Chair": (0.40, 0.38, 0.36), "Pole": (0.40, 0.38, 0.36), "Canopy": (0.92, 0.85, 0.72),
    "Post": (0.25, 0.30, 0.28), "Lantern": (0.98, 0.92, 0.70), "Planter": (0.72, 0.50, 0.40), "Flower": (0.90, 0.45, 0.55),
    "Stone": (0.75, 0.74, 0.70), "Water": (0.55, 0.75, 0.85), "Sign": (0.85, 0.80, 0.70), "Bench": (0.50, 0.42, 0.36),
    "Frame": (0.35, 0.40, 0.55), "Wheel": (0.25, 0.25, 0.25), "Plank": (0.62, 0.50, 0.40), "Rail": (0.55, 0.45, 0.38),
    "Cobble": (0.66, 0.65, 0.63), "Curb": (0.80, 0.79, 0.76),
    "Shopfront": (0.45, 0.32, 0.26), "DoorShop": (0.45, 0.32, 0.26), "AwningStripe": (0.97, 0.96, 0.93), "Iron": (0.18, 0.18, 0.20),
    "Bread": (0.85, 0.62, 0.35), "Glass": (0.78, 0.86, 0.92), "Interior": (0.93, 0.88, 0.80), "Brass": (0.84, 0.70, 0.36),
    "Cake": (0.98, 0.96, 0.92), "Icing": (0.94, 0.66, 0.74), "Dress": (0.90, 0.47, 0.55), "Head": (0.92, 0.84, 0.78),
    "Jar": (0.78, 0.55, 0.35), "Box": (0.60, 0.42, 0.30), "Round": (0.94, 0.82, 0.47), "Book": (0.55, 0.35, 0.35), "Hat": (0.25, 0.22, 0.2),
    "Cheese": (0.94, 0.80, 0.40), "Choc": (0.26, 0.15, 0.10), "Wrap": (0.85, 0.70, 0.35),
    "Band": (0.92, 0.88, 0.80), "Yellow": (0.96, 0.80, 0.16), "Fruit": (0.90, 0.50, 0.20), "Sack": (0.72, 0.60, 0.45), "Bottle": (0.85, 0.88, 0.90), "Pill": (0.95, 0.95, 0.95), "Cross": (0.20, 0.80, 0.40),
})

def box(o, name, c, sx, sy, sz, tris_out=None, yaw=0.0, skip=()):
    """Axis-aligned box centred at c (bottom at c.y - sy/2 ... use c as centre)."""
    x, y, z = c; hx, hy, hz = sx / 2, sy / 2, sz / 2
    P = []
    for dx in (-hx, hx):
        for dy in (-hy, hy):
            for dz in (-hz, hz):
                px, pz = dx * math.cos(yaw) - dz * math.sin(yaw), dx * math.sin(yaw) + dz * math.cos(yaw)
                P.append((x + px, y + dy, z + pz))
    # index: dx(0/1)*4 + dy(0/1)*2 + dz(0/1)
    def q(a, b, c2, d): return [(P[a], P[b], P[c2]), (P[a], P[c2], P[d])]
    faces = []
    for i, f in enumerate((q(0, 1, 3, 2), q(4, 6, 7, 5), q(0, 4, 5, 1), q(2, 3, 7, 6), q(0, 2, 6, 4), q(1, 5, 7, 3))):
        if i not in skip: faces += f
    tris = tris_out if tris_out is not None else []
    tris += faces
    if tris_out is None:
        o.add_flat(name, tris, c)
    return tris

# ---- extrusion helpers -------------------------------------------------------------------------
def extrude(o, name, pts, axis, a0, a1, tris_out=None):
    """Extrude a convex CCW polygon of (u, v) points between axis values a0 < a1.
    axis 'z': polygon in XY (u = x), extruded along Z.  axis 'x': polygon in ZY (u = z), extruded along X."""
    if axis == "x": pts = pts[::-1]            # the (u,v,a)->(a,v,u) map is a reflection; reverse to keep faces outward
    def P(u, v, a): return (u, v, a) if axis == "z" else (a, v, u)
    tris = tris_out if tris_out is not None else []
    n = len(pts)
    A = [P(u, v, a0) for u, v in pts]; B = [P(u, v, a1) for u, v in pts]
    for i in range(1, n - 1):
        tris.append((B[0], B[i], B[i + 1])); tris.append((A[0], A[i + 1], A[i]))
    for i in range(n):
        j = (i + 1) % n
        tris.append((A[i], A[j], B[j])); tris.append((A[i], B[j], B[i]))
    if tris_out is None: o.add_flat(name, tris)
    return tris

def extrude_ring(o, name, outer, inner, axis, a0, a1, tris_out=None):
    """A frame: the band between two same-length CCW polygons, extruded between a0 and a1."""
    if axis == "x": outer = outer[::-1]; inner = inner[::-1]
    def P(u, v, a): return (u, v, a) if axis == "z" else (a, v, u)
    tris = tris_out if tris_out is not None else []
    n = len(outer)
    Ao = [P(u, v, a0) for u, v in outer]; Bo = [P(u, v, a1) for u, v in outer]
    Ai = [P(u, v, a0) for u, v in inner]; Bi = [P(u, v, a1) for u, v in inner]
    for i in range(n):
        j = (i + 1) % n
        tris += [(Bo[i], Bo[j], Bi[j]), (Bo[i], Bi[j], Bi[i])]        # +a face
        tris += [(Ao[i], Ai[j], Ao[j]), (Ao[i], Ai[i], Ai[j])]        # -a face
        tris += [(Ao[i], Ao[j], Bo[j]), (Ao[i], Bo[j], Bo[i])]        # outer side
        tris += [(Ai[i], Bi[j], Ai[j]), (Ai[i], Bi[i], Bi[j])]        # inner side (faces into the opening)
    if tris_out is None: o.add_flat(name, tris)
    return tris

def arch_profile(cu, y0, w, hr, n=8):
    """Rectangle w wide, hr tall, topped by a semicircle. CCW."""
    r = w / 2
    pts = [(cu - r, y0), (cu + r, y0), (cu + r, y0 + hr)]
    for k in range(1, n):
        th = math.pi * k / n
        pts.append((cu + r * math.cos(th), y0 + hr + r * math.sin(th)))
    pts.append((cu - r, y0 + hr))
    return pts

def rect_profile(cu, y0, w, h):
    return [(cu - w / 2, y0), (cu + w / 2, y0), (cu + w / 2, y0 + h), (cu - w / 2, y0 + h)]

def rect_profile_n(cu, y0, w, h, n=8):
    """Rectangle with its top edge subdivided so it has as many points as arch_profile(n): a ring can join them."""
    pts = [(cu - w / 2, y0), (cu + w / 2, y0), (cu + w / 2, y0 + h)]
    for k in range(1, n):
        pts.append((cu + w / 2 - w * k / n, y0 + h))
    pts.append((cu - w / 2, y0 + h))
    return pts

def thick_quad(tris, A, B, C, D, t):
    """A slab of thickness t built on quad ABCD (any orientation): both faces and four edges."""
    n = F.norm(F.cross(F.sub(B, A), F.sub(D, A)))
    off = F.mul(n, t)
    A2, B2, C2, D2 = (F.add(q, off) for q in (A, B, C, D))
    tris += [(A, C, B), (A, D, C), (A2, B2, C2), (A2, C2, D2)]
    for (p, q, p2, q2) in ((A, B, A2, B2), (B, C, B2, C2), (C, D, C2, D2), (D, A, D2, A2)):
        tris += [(p, q, q2), (p, q2, p2)]

# ---- the shop-house ------------------------------------------------------------------------------
GF, UF, DEPTH = 11.0, 9.0, 26.0          # ground (shop) floor, upper floors, building depth, in studs

def townhouse(name, seed, width, floors, roof="flat", door="centre", upper="arch", flowers=False, door_style="arched", shutters=False):
    """Pastel French shop-house at Roblox human scale (doors 7 studs, floors 9-11 studs).
    Front faces -Z, stands on y = 0.  Pieces: Wall, Trim (cream stone), Window (glass), Shopfront (painted
    frame), DoorShop (the shop door, for the builder to find), Sign (board), Awning / AwningStripe, Shutter,
    Iron (railings), Roof, Chimney, Door (back door), Planter / Flower (window boxes)."""
    rnd = random.Random(seed); o = Obj()
    H = GF + (floors - 1) * UF
    zf, zb = -DEPTH / 2, DEPTH / 2
    xl, xr = -width / 2, width / 2
    box(o, "Walls", (0, H / 2, 0), width, H, DEPTH, skip=(4,))     # no front face: see the shop-front panels below
    tt, wt, st, it, pt, ft, sf = [], [], [], [], [], [], []      # trim, window, shutter, iron, planter, flower, shopfront

    def span(base, out, d_in, d_out):
        a, b = base - out * d_in, base + out * d_out
        return (min(a, b), max(a, b))

    def window(face, u, y0, kind, shutters=False, railing=False, flowerbox=False):
        """kind: 'arch' (3.4 x 5.9 arched), 'tall' (3.2 x 5.6 French window), 'rect' (3.0 x 4.0)."""
        axis = "z" if face in ("front", "back") else "x"
        base = {"front": zf, "back": zb, "left": xl, "right": xr}[face]
        out = {"front": -1, "back": 1, "left": -1, "right": 1}[face]
        t = 0.45
        if kind == "arch":
            w, hr = 3.4, 4.2
            inner = arch_profile(u, y0, w, hr)
            outer = arch_profile(u, y0 - t, w + 2 * t, hr)
            top = y0 + hr + w / 2
            h = hr
        else:
            w, h = (3.2, 5.6) if kind == "tall" else (3.0, 4.0)
            hr = h
            inner = rect_profile(u, y0, w, h)
            outer = rect_profile(u, y0 - t, w + 2 * t, h + 2 * t)
            top = y0 + h
        extrude(o, "Window", inner, axis, *span(base, out, 0.10, 0.12), tris_out=wt)
        extrude_ring(o, "Trim", outer, inner, axis, *span(base, out, 0.05, 0.40), tris_out=tt)
        # mullions: one vertical, one horizontal (and the arch spring line)
        mid_a, mid_b = span(base, out, -0.14, 0.26)
        mid = (mid_a + mid_b) / 2; thick = 0.12
        vh = top - y0 - 0.1
        if axis == "z":
            box(o, "Trim", (u, y0 + vh / 2, mid), 0.16, vh, thick, tris_out=tt)
            box(o, "Trim", (u, y0 + (hr if kind == "arch" else h * 0.6), mid), w, 0.16, thick, tris_out=tt)
            if kind == "arch": box(o, "Trim", (u, y0 + hr * 0.5, mid), w, 0.14, thick, tris_out=tt)
            box(o, "Trim", (u, y0 - 0.25, base + out * 0.35), w + 1.2, 0.4, 0.9, tris_out=tt)          # sill
        else:
            box(o, "Trim", (mid, y0 + vh / 2, u), thick, vh, 0.16, tris_out=tt)
            box(o, "Trim", (mid, y0 + (hr if kind == "arch" else h * 0.6), u), thick, 0.16, w, tris_out=tt)
            if kind == "arch": box(o, "Trim", (mid, y0 + hr * 0.5, u), thick, 0.14, w, tris_out=tt)
            box(o, "Trim", (base + out * 0.35, y0 - 0.25, u), 0.9, 0.4, w + 1.2, tris_out=tt)
        if shutters and axis == "z":
            sh = top - y0
            for sgn in (-1, 1):
                box(o, "Shutter", (u + sgn * (w / 2 + t + 0.75), y0 + sh / 2, base + out * 0.14), 1.4, sh, 0.22, tris_out=st)
        if railing and axis == "z":
            zr = base + out * 0.9
            for yy in (y0 + 0.5, y0 + 1.5):
                box(o, "Iron", (u, yy, zr), w + 1.0, 0.1, 0.1, tris_out=it)
            for k in range(6):
                xx = u - (w + 1.0) / 2 + (w + 1.0) * k / 5
                box(o, "Iron", (xx, y0 + 0.8, zr), 0.1, 1.7, 0.1, tris_out=it)
                box(o, "Iron", (xx, y0 + 0.45, base + out * 0.5), 0.1, 0.1, 0.9, tris_out=it)
        if flowerbox and axis == "z":
            zp = base + out * 0.75
            box(o, "Planter", (u, y0 + 0.4, zp), w * 0.9, 0.85, 0.85, tris_out=pt)
            for k in range(3):
                xx = u - w * 0.3 + w * 0.3 * k
                icoblob(o, "Flower", (xx, y0 + 1.05, zp + rnd.uniform(-0.1, 0.1)), 0.42, rnd, 0.12, tris_out=ft)
            for k in range(2):
                icoblob(o, "Leaf", (u - w * 0.15 + w * 0.3 * k, y0 + 0.95, zp - out * 0.15), 0.36, rnd, 0.15, tris_out=ft)

    nwin = max(2, int(round(width / 9.0)))
    short = floors == 2
    back_door_i = nwin // 2 if nwin % 2 == 1 else nwin // 2 - 1
    xs = [xl + width * (i + 0.5) / nwin for i in range(nwin)]
    # upper floors, front
    for f in range(1, floors):
        y0 = GF + (f - 1) * UF + 1.8
        for x in xs:
            window("front", x, y0, upper, shutters=(upper == "tall") or shutters, railing=(upper == "tall"), flowerbox=flowers)
    # sides and rear
    for f in range(floors):
        y0 = (3.0 if f == 0 else GF + (f - 1) * UF + 1.8)
        kind = "rect" if f == 0 else "arch"
        if short:
            window("left", 0.0, y0, kind); window("right", 0.0, y0, kind)
            if f == 1:
                window("back", -width / 4, y0, kind); window("back", width / 4, y0, kind)
        else:
            for i, x in enumerate(xs):
                if f == 0 and i == back_door_i: continue
                if (i + f) % 2 == 0: window("back", x, y0, kind)
            if f > 0:
                for zz in (-DEPTH / 4, DEPTH / 4):
                    window("left", zz, y0, kind); window("right", zz, y0, kind)
    # ---- shop front -------------------------------------------------------------------------------
    fw = width - 1.2; gtop = GF
    fasc = 2.6; riser = 1.4
    bay_top = gtop - fasc; hw = bay_top - riser
    for sgn in (-1, 1):                                                                        # pilasters
        box(o, "Shopfront", (sgn * (fw / 2 - 0.55), gtop / 2, zf - 0.3), 1.1, gtop, 0.6, tris_out=sf)
    box(o, "Shopfront", (0, gtop - fasc / 2, zf - 0.3), fw, fasc, 0.6, tris_out=sf)             # fascia
    box(o, "Sign", (0, gtop - fasc / 2, zf - 0.68), fw * 0.72, 1.7, 0.2)                        # sign board
    box(o, "Trim", (0, gtop + 0.25, zf - 0.3), width + 0.4, 0.5, 0.8, tris_out=tt)             # cornice over the shop
    # bays between the pilasters: door bay 3.6 wide, the rest glass split by mullions
    x0, x1 = -(fw / 2 - 1.1), (fw / 2 - 1.1)
    dwid = 4.6 if door_style == "double" else 3.6
    if door == "left":    dx0 = x0
    elif door == "right": dx0 = x1 - dwid
    else:                 dx0 = -dwid / 2
    door_x = dx0 + dwid / 2
    bays = []
    if dx0 > x0 + 0.5: bays.append((x0, dx0, "glass"))
    bays.append((dx0, dx0 + dwid, "door"))
    if dx0 + dwid < x1 - 0.5: bays.append((dx0 + dwid, x1, "glass"))
    gt, br, ii = [], [], []          # glass, brass, interior
    # the front wall face, with holes where the glass bays and the door are (the glass is see-through in Roblox)
    wl = []
    def wpanel(xa, xb, ya, yb):
        if xb - xa > 0.01 and yb - ya > 0.01:
            box(o, "Walls", ((xa + xb) / 2, (ya + yb) / 2, zf + 0.02), xb - xa, yb - ya, 0.04, tris_out=wl)
    wpanel(xl, xr, gtop, H)
    wpanel(xl, x0, 0.0, gtop); wpanel(x1, xr, 0.0, gtop)
    for (a, b, kind) in bays:
        wpanel(a, b, bay_top, gtop)
        if kind == "glass": wpanel(a, b, 0.0, riser)
    o.add_flat("Walls", wl)
    nglass = 0
    for (a, b, kind) in bays:
        if kind == "glass":
            nglass += 1
            box(o, "Shopfront", ((a + b) / 2, riser / 2, zf - 0.3), b - a, riser, 0.6, tris_out=sf)          # stall riser
            # the pane, its own piece so the builder can find the bay and put a display behind it
            box(o, f"Glass{nglass}", ((a + b) / 2, riser + hw / 2, zf - 0.02), b - a, hw, 0.2)
            nsub = max(1, int(round((b - a) / 5.5)))
            for k in range(1, nsub):
                box(o, "Shopfront", (a + (b - a) * k / nsub, riser + hw / 2, zf - 0.2), 0.3, hw, 0.4, tris_out=sf)
            box(o, "Shopfront", ((a + b) / 2, riser + hw + 0.0, zf - 0.2), b - a, 0.3, 0.4, tris_out=sf)      # head rail
            # a shallow lit room behind the glass: floor, back wall, sides, ceiling (inside the wall's volume)
            zi0, zi1 = zf + 0.25, zf + 5.4; zc = (zi0 + zi1) / 2; dep = zi1 - zi0
            box(o, "Interior", ((a + b) / 2, riser + 0.05, zc), b - a, 0.1, dep, tris_out=ii)
            box(o, "Interior", ((a + b) / 2, riser + hw / 2, zi1 - 0.05), b - a, hw, 0.1, tris_out=ii)
            box(o, "Interior", ((a + b) / 2, bay_top - 0.05, zc), b - a, 0.1, dep, tris_out=ii)
            for xx in (a + 0.05, b - 0.05):
                box(o, "Interior", (xx, riser + hw / 2, zc), 0.1, hw, dep, tris_out=ii)
        else:
            dh = 7.0; cxd = (a + b) / 2
            if door_style == "arched":
                # arched shop door in a brick surround (after Shannon's low-poly bakery references)
                hr = dh - dwid / 2
                opening = arch_profile(cxd, 0.0, dwid, hr)
                brick = []
                extrude_ring(o, "Brick", rect_profile_n(cxd, -0.1, dwid + 1.6, bay_top + 0.1), opening, "z", zf - 0.55, zf + 0.05, tris_out=brick)
                extrude_ring(o, "Brick", arch_profile(cxd, -0.1, dwid + 0.9, hr), opening, "z", zf - 0.85, zf - 0.5, tris_out=brick)
                o.add_flat("Brick", brick)
                lw = dwid - 0.2; leaf = arch_profile(cxd, 0.0, lw, hr - 0.1)
                gw, gy0 = 2.4, 3.0; ghr = (dh - 0.4) - gy0 - gw / 2
                glass = arch_profile(cxd, gy0, gw, ghr)
                extrude_ring(o, "DoorShop", leaf, glass, "z", zf - 0.2, zf + 0.05)
                box(o, "DoorShop", (cxd, 1.5, zf - 0.26), lw - 0.8, 2.0, 0.12)
                box(o, "DoorShop", (cxd, gy0 - 0.15, zf - 0.26), lw - 0.3, 0.3, 0.12)
                extrude(o, "GlassDoor", glass, "z", zf - 0.12, zf - 0.06, tris_out=gt)
                for dx in (-1.0, -0.5, 0.0, 0.5, 1.0):
                    ytop = gy0 + ghr + math.sqrt(max((gw / 2) ** 2 - dx * dx, 0.0)) - 0.12
                    box(o, "Iron", (cxd + dx, (gy0 + ytop) / 2, zf - 0.19), 0.08, ytop - gy0, 0.08, tris_out=it)
                for yy in (gy0 + 1.1, gy0 + 2.2):
                    box(o, "Iron", (cxd, yy, zf - 0.19), gw, 0.08, 0.08, tris_out=it)
                for dx in (-0.75, -0.25, 0.25, 0.75):
                    box(o, "Iron", (cxd + dx, gy0 + 0.5, zf - 0.19), 0.34, 0.34, 0.06, tris_out=it)
                    box(o, "Iron", (cxd + dx, gy0 + 0.5, zf - 0.19), 0.2, 0.2, 0.09, tris_out=it)
                box(o, "Brass", (cxd + lw * 0.36, 3.6, zf - 0.42), 0.14, 1.2, 0.14, tris_out=br)
                box(o, "Brass", (cxd + lw * 0.36, 3.6, zf - 0.3), 0.34, 0.6, 0.1, tris_out=br)
            elif door_style == "panel":
                # panelled wooden door in a stone surround, with a transom light above
                extrude_ring(o, "Trim", rect_profile(cxd, -0.1, dwid + 1.4, bay_top + 0.1), rect_profile(cxd, 0.0, dwid, bay_top - 0.35), "z", zf - 0.55, zf + 0.05, tris_out=tt)
                box(o, "Trim", (cxd, dh + 0.15, zf - 0.45), dwid + 0.2, 0.3, 0.9, tris_out=tt)                       # transom bar
                box(o, "GlassDoor", (cxd, dh + 0.3 + (bay_top - 0.35 - dh - 0.3) / 2, zf - 0.08), dwid, bay_top - 0.35 - dh - 0.3, 0.08, tris_out=gt)
                box(o, "Trim", (cxd, dh + 0.3 + (bay_top - 0.35 - dh - 0.3) / 2, zf - 0.14), 0.1, bay_top - 0.35 - dh - 0.3, 0.06, tris_out=tt)
                lw = dwid - 0.2
                box(o, "DoorShop", (cxd, dh / 2 - 0.05, zf - 0.14), lw, dh - 0.3, 0.28)
                for sgn in (-1, 1):                                                                              # two glazed upper panels
                    box(o, "GlassDoor", (cxd + sgn * lw * 0.24, dh * 0.7, zf - 0.3), lw * 0.34, 2.2, 0.06, tris_out=gt)
                    box(o, "Trim", (cxd + sgn * lw * 0.24, dh * 0.7, zf - 0.32), lw * 0.34 + 0.16, 2.36, 0.02, tris_out=tt)
                    box(o, "DoorShop", (cxd + sgn * lw * 0.24, 1.9, zf - 0.34), lw * 0.34, 2.4, 0.12)                # raised lower panels
                box(o, "Brass", (cxd + lw * 0.38, 3.4, zf - 0.44), 0.16, 0.16, 0.3, tris_out=br)                     # knob
                box(o, "Brass", (cxd + lw * 0.38, 3.4, zf - 0.32), 0.34, 0.5, 0.06, tris_out=br)
                box(o, "Brass", (cxd, 0.4, zf - 0.3), lw - 0.4, 0.5, 0.05, tris_out=br)                            # kick plate
            else:
                # glazed double door with slim painted frames, like the cafe door in the references
                for sgn in (-1, 1):
                    box(o, "Shopfront", (cxd + sgn * (dwid / 2 + 0.2), dh / 2 + 0.6, zf - 0.4), 0.4, dh + 1.2, 0.8, tris_out=sf)
                box(o, "Shopfront", (cxd, bay_top - 0.15, zf - 0.4), dwid + 0.8, 0.3, 0.8, tris_out=sf)
                box(o, "Shopfront", (cxd, dh + 0.15, zf - 0.3), dwid, 0.3, 0.6, tris_out=sf)                     # transom bar
                box(o, "GlassDoor", (cxd, dh + 0.3 + (bay_top - 0.3 - dh - 0.3) / 2, zf - 0.08), dwid, bay_top - 0.3 - dh - 0.3, 0.08, tris_out=gt)
                lw = dwid / 2 - 0.08
                for sgn in (-1, 1):
                    cx2 = cxd + sgn * (lw / 2 + 0.04)
                    leaf = rect_profile(cx2, 0.0, lw, dh - 0.05)
                    pane = rect_profile(cx2, 1.7, lw - 0.5, dh - 2.2)
                    extrude_ring(o, "DoorShop", leaf, pane, "z", zf - 0.2, zf + 0.05)
                    extrude(o, "GlassDoor", pane, "z", zf - 0.12, zf - 0.06, tris_out=gt)
                    box(o, "DoorShop", (cx2, 0.85, zf - 0.26), lw - 0.5, 1.0, 0.12)                                 # lower panel
                    box(o, "Brass", (cxd + sgn * 0.35, 3.6, zf - 0.42), 0.12, 1.4, 0.12, tris_out=br)            # handles by the meeting edge
            box(o, "Trim", (cxd, 0.08, zf - 0.7), dwid + 0.8, 0.16, 1.3, tris_out=tt)                         # threshold
            # a little of the shop behind the door glass
            zi0, zi1 = zf + 0.1, zf + 4.0; zc = (zi0 + zi1) / 2; dep = zi1 - zi0
            box(o, "Interior", (cxd, 0.05, zc), dwid, 0.1, dep, tris_out=ii)
            box(o, "Interior", (cxd, dh / 2, zi1 - 0.05), dwid, dh, 0.1, tris_out=ii)
            box(o, "Interior", (cxd, dh - 0.05, zc), dwid, 0.1, dep, tris_out=ii)
            for xx in (cxd - dwid / 2 + 0.05, cxd + dwid / 2 - 0.05):
                box(o, "Interior", (xx, dh / 2, zc), 0.1, dh, dep, tris_out=ii)
        box(o, "Shopfront", (b, gtop / 2 - fasc / 2, zf - 0.25), 0.5, gtop - fasc, 0.5, tris_out=sf)        # post between bays
    for sgn in (-1, 1):
        box(o, "Shopfront", (sgn * (fw / 2 - 1.1), gtop / 2 - fasc / 2, zf - 0.25), 0.5, gtop - fasc, 0.5, tris_out=sf)
    o.add_flat("Shopfront", sf); o.add_flat("GlassDoor", gt); o.add_flat("Brass", br); o.add_flat("Interior", ii)
    # ---- striped awning under the fascia -----------------------------------------------------------
    aw_a, aw_b = [], []
    ya, yb_ = bay_top - 0.05, bay_top - 1.9
    za, zb2 = zf - 0.62, zf - 4.2
    w = fw - 2.6; nstr = max(6, int(round(w / 1.5)))
    if nstr % 2 == 0: nstr += 1
    sw = w / nstr
    for i in range(nstr):
        xa, xb = -w / 2 + i * sw, -w / 2 + (i + 1) * sw
        tris = aw_a if i % 2 == 0 else aw_b
        thick_quad(tris, (xa, ya, za), (xb, ya, za), (xb, yb_, zb2), (xa, yb_, zb2), 0.14)
        xm = (xa + xb) / 2
        thick_quad(tris, (xa, yb_, zb2), (xb, yb_, zb2), (xm + 0.001, yb_ - 0.55, zb2), (xm - 0.001, yb_ - 0.55, zb2), 0.14)
    o.add_flat("Awning", aw_a); o.add_flat("AwningStripe", aw_b)
    # awning arms
    for sgn in (-1, 1):
        box(o, "Iron", (sgn * (w / 2 - 0.2), (ya + yb_) / 2, (za + zb2) / 2), 0.12, 0.12, 3.2, tris_out=it)
    # ---- floor cornices ----------------------------------------------------------------------------
    for f in range(2, floors):
        y = GF + (f - 1) * UF
        box(o, "Trim", (0, y, zf - 0.15), width + 0.3, 0.4, 0.5, tris_out=tt)
    # ---- roof ---------------------------------------------------------------------------------------
    if roof == "pitched":
        rh, ov = 6.0, 1.0
        A = (xl - ov, H, zf - ov); B = (xr + ov, H, zf - ov); C = (xr + ov, H, zb + ov); D = (xl - ov, H, zb + ov)
        E = (xl - ov, H + rh, 0); Fp = (xr + ov, H + rh, 0)
        rt = []
        thick_quad(rt, A, B, Fp, E, -0.4); thick_quad(rt, C, D, E, Fp, -0.4)
        o.add_flat("Roof", rt)
        gw = []                                                                                     # gable ends
        extrude(o, "Walls", [(zb, H), (zf, H), (0, H + rh)], "x", xl, xr, tris_out=gw)
        o.add_flat("Walls", gw)
        # dormers on the front slope
        for x in (xs[:2] if nwin <= 2 else [xs[0], xs[-1]]):
            dz0 = zf + 1.0
            box(o, "Walls", (x, H + 2.4, dz0 + 2.0), 3.8, 4.4, 4.0)
            dt = []
            thick_quad(dt, (x - 2.3, H + 4.5, dz0 - 0.5), (x, H + 6.6, dz0 - 0.5), (x, H + 6.6, dz0 + 4.5), (x - 2.3, H + 4.5, dz0 + 4.5), 0.3)
            thick_quad(dt, (x, H + 6.6, dz0 - 0.5), (x + 2.3, H + 4.5, dz0 - 0.5), (x + 2.3, H + 4.5, dz0 + 4.5), (x, H + 6.6, dz0 + 4.5), 0.3)
            o.add_flat("Roof", dt)
            extrude(o, "Walls", [(x - 1.9, H + 4.6), (x + 1.9, H + 4.6), (x, H + 6.5)], "z", dz0 - 0.2, dz0 + 3.5)
            inner = rect_profile(x, H + 1.0, 2.2, 3.0); outer = rect_profile(x, H + 0.7, 2.8, 3.6)
            extrude(o, "Window", inner, "z", dz0 - 0.1, dz0 + 0.1, tris_out=wt)
            extrude_ring(o, "Trim", outer, inner, "z", dz0 - 0.3, dz0 + 0.05, tris_out=tt)
        box(o, "Chimney", (xr - 4.0, H + 4.2, 5.0), 1.6, 4.0, 1.6)
    else:
        box(o, "Trim", (0, H + 0.5, 0), width + 0.6, 1.0, DEPTH + 0.6, tris_out=tt)                  # parapet slab
        box(o, "Trim", (0, H + 0.3, zf - 0.55), width + 1.2, 0.6, 1.4, tris_out=tt)                  # front cornice
        box(o, "Roof", (0, H + 1.2, 0), width - 2.0, 0.4, DEPTH - 2.0)
        box(o, "Chimney", (xl + 4.0, H + 2.4, 5.0), 1.6, 3.0, 1.6)
    # ---- back door at ground level ------------------------------------------------------------------
    xb = 0.0 if short else xs[back_door_i]
    box(o, "Door", (xb, 3.4, zb + 0.1), 3.4, 6.8, 0.3)
    extrude_ring(o, "Trim", rect_profile(xb, -0.1, 4.2, 7.3), rect_profile(xb, 0.0, 3.4, 6.8), "z", zb - 0.05, zb + 0.35, tris_out=tt)
    box(o, "Trim", (xb, 0.2, zb + 0.9), 4.4, 0.4, 1.8, tris_out=tt)
    o.add_flat("Trim", tt); o.add_flat("Window", wt); o.add_flat("Shutter", st); o.add_flat("Iron", it)
    o.add_flat("Planter", pt); o.add_flat("Flower", ft)
    n = o.write(OUT / f"{name}.obj")
    print(f"{name}: width {width} floors {floors} H {H} door_x {door_x:+.1f}")
    return n

# ---- window displays (6 wide, stand on y = 0, front toward -Z; the builder puts copies behind each Glass pane) ----
def _shelf_unit(o, pt, w=5.6, d=1.2, z=1.6, levels=(1.3, 2.8, 4.3), top=5.0, name="Plank"):
    box(o, name, (0, top / 2, z + d / 2), w, top, 0.12, tris_out=pt)
    for sgn in (-1, 1): box(o, name, (sgn * (w / 2 - 0.06), top / 2, z), 0.12, top, d, tris_out=pt)
    for y in levels: box(o, name, (0, y, z), w, 0.12, d, tris_out=pt)

def _cake(o, x, z, k, rnd, ct, tt, r=0.7, y=0.0):
    """A cake on a stand, standing on height y."""
    c = (x, y, z)
    box(o, "Trim", (x, y + 0.05, z), 1.8, 0.1, 1.8, tris_out=tt)
    tube(o, "Trim", [ring(c, 0.12, 0.1, 6), ring(c, 0.12, 0.7, 6)], (x, y + 0.4, z), tris_out=tt)
    tube(o, "Trim", [ring(c, r + 0.2, 0.7, 10), ring(c, r + 0.2, 0.8, 10)], (x, y + 0.75, z), cap_top=True, cap_bottom=True, tris_out=tt)
    tube(o, "Cake", [ring(c, r, 0.8, 10), ring(c, r, 1.5, 10)], (x, y + 1.15, z), tris_out=ct)
    ic = []
    tube(o, f"Icing{k}", [ring(c, r + 0.04, 1.45, 10), ring(c, r + 0.04, 1.7, 10)], (x, y + 1.6, z), cap_top=True, tris_out=ic)
    icoblob(o, f"Icing{k}", (x, y + 1.85, z), 0.22, rnd, 0.05, tris_out=ic)
    o.add_flat(f"Icing{k}", ic)

def disp_bakery(name, seed):
    rnd = random.Random(seed); o = Obj(); pt, bt, wt, tt, ct = [], [], [], [], []
    _shelf_unit(o, pt, z=1.5, levels=(1.3, 2.8, 4.3), top=5.0)
    for y in (1.3, 2.8, 4.3):
        for i in range(5):
            icoblob(o, "Bread", (-2.2 + 1.1 * i, y + 0.4, 1.5 + rnd.uniform(-0.15, 0.15)), 0.42, rnd, 0.1, (1.0, 0.75, 1.25), tris_out=bt)
    # basket of baguettes, front left
    box(o, "Bench", (-1.9, 0.6, -0.5), 1.4, 1.2, 1.4, tris_out=wt)
    for i in range(5):
        a = 2 * math.pi * i / 5
        icoblob(o, "Bread", (-1.9 + 0.35 * math.cos(a), 1.6, -0.5 + 0.35 * math.sin(a)), 0.95, rnd, 0.06, (0.2, 1.0, 0.2), tris_out=bt)
    _cake(o, 1.7, -0.4, 1, rnd, ct, tt, r=0.75)
    o.add_flat("Plank", pt); o.add_flat("Bread", bt); o.add_flat("Bench", wt); o.add_flat("Trim", tt); o.add_flat("Cake", ct)
    return o.write(OUT / f"{name}.obj")

def _mannequin(o, x, z, k, rnd, post, head):
    dt = []
    tube(o, "Post", [ring((x, 0, z), 0.6, 0, 8), ring((x, 0, z), 0.6, 0.12, 8)], (x, 0.06, z), cap_top=True, cap_bottom=True, tris_out=post)
    tube(o, "Post", [ring((x, 0, z), 0.08, 0.1, 6), ring((x, 0, z), 0.08, 1.6, 6)], (x, 0.8, z), tris_out=post)
    tube(o, f"Dress{k}", [ring((x, 0, z), 1.0, 1.5, 10), ring((x, 0, z), 0.5, 3.0, 10)], (x, 2.2, z), cap_bottom=True, tris_out=dt)
    tube(o, f"Dress{k}", [ring((x, 0, z), 0.5, 3.0, 10), ring((x, 0, z), 0.42, 3.6, 10), ring((x, 0, z), 0.56, 4.3, 10)], (x, 3.6, z), cap_top=True, tris_out=dt)
    o.add_flat(f"Dress{k}", dt)
    tube(o, "Head", [ring((x, 0, z), 0.15, 4.3, 6), ring((x, 0, z), 0.15, 4.6, 6)], (x, 4.45, z), tris_out=head)
    icoblob(o, "Head", (x, 5.05, z), 0.45, rnd, 0.03, tris_out=head)

def disp_dress(name, seed):
    rnd = random.Random(seed); o = Obj(); post, head = [], []
    _mannequin(o, -1.5, -0.3, 1, rnd, post, head)
    _mannequin(o, 1.5, 0.1, 2, rnd, post, head)
    # clothes rail at the back with hanging dresses
    box(o, "Post", (0, 4.9, 2.0), 5.4, 0.1, 0.1, tris_out=post)
    for sgn in (-1, 1): box(o, "Post", (sgn * 2.6, 2.6, 2.0), 0.1, 4.7, 0.1, tris_out=post)
    for i in range(4):
        x = -2.0 + 1.33 * i
        box(o, "Post", (x, 4.75, 2.0), 0.6, 0.06, 0.06, tris_out=post)
        box(o, f"Dress{3 + i}", (x, 3.5, 2.0), 0.9, 2.4, 0.12)
    o.add_flat("Post", post); o.add_flat("Head", head)
    return o.write(OUT / f"{name}.obj")

def _front_table(o, pt, w=5.2, d=1.5, z=-1.15, h=2.3):
    """Low display table right behind the glass; returns its top height."""
    box(o, "Plank", (0, h - 0.06, z), w, 0.12, d, tris_out=pt)
    box(o, "Plank", (0, h - 0.35, z), w - 0.2, 0.5, d - 0.3, tris_out=pt)
    for sx in (-1, 1):
        for sz in (-1, 1):
            box(o, "Plank", (sx * (w / 2 - 0.15), h / 2, z + sz * (d / 2 - 0.15)), 0.14, h, 0.14, tris_out=pt)
    return h

def _quad_dir(tris, A, B, C, D, want):
    """Quad ABCD with its normal turned toward direction `want`."""
    n = F.cross(F.sub(B, A), F.sub(C, A))
    if F.dot(n, want) < 0: A, B, C, D = A, D, C, B
    tris += [(A, B, C), (A, C, D)]

def _wheel(o, name, cx, y0, cz, r, h, a0=0.0, a1=2 * math.pi, n=14):
    """Cheese wheel (or a wedge of one) standing on y0, spanning angles a0..a1; cut faces where it is not a full circle."""
    tris = []
    full = abs((a1 - a0) - 2 * math.pi) < 1e-6
    segs = max(3, int(round(n * (a1 - a0) / (2 * math.pi))))
    pts0 = [(cx + r * math.cos(a0 + (a1 - a0) * k / segs), y0, cz + r * math.sin(a0 + (a1 - a0) * k / segs)) for k in range(segs + 1)]
    pts1 = [(x, y0 + h, z) for (x, _, z) in pts0]
    cb, ct = (cx, y0, cz), (cx, y0 + h, cz)
    for k in range(segs):
        out = F.sub(F.mul(F.add(pts0[k], pts0[k + 1]), 0.5), cb)
        _quad_dir(tris, pts0[k], pts0[k + 1], pts1[k + 1], pts1[k], out)
        tris.append((ct, pts1[k], pts1[k + 1]) if F.cross(F.sub(pts1[k], ct), F.sub(pts1[k + 1], ct))[1] > 0 else (ct, pts1[k + 1], pts1[k]))
        tris.append((cb, pts0[k + 1], pts0[k]) if F.cross(F.sub(pts0[k + 1], cb), F.sub(pts0[k], cb))[1] < 0 else (cb, pts0[k], pts0[k + 1]))
    if not full:
        for (idx, ang, sgn) in ((0, a0, -1), (segs, a1, 1)):
            want = (sgn * -math.sin(ang), 0, sgn * math.cos(ang))
            _quad_dir(tris, cb, pts0[idx], pts1[idx], ct, want)
    o.add_flat(name, tris)

def disp_shelves(name, seed):
    rnd = random.Random(seed); o = Obj(); pt = []
    _shelf_unit(o, pt, z=1.4, levels=(1.2, 2.6, 4.0), top=5.0)
    k = 0
    def items(y, z, x0=-2.5, x1=2.3):
        nonlocal k
        x = x0
        while x < x1:
            k += 1
            r = rnd.random()
            if r < 0.35:      # jar
                tube(o, f"Jar{k}", [ring((x + 0.3, 0, z), 0.28, y + 0.06, 8), ring((x + 0.3, 0, z), 0.28, y + 0.7, 8), ring((x + 0.3, 0, z), 0.18, y + 0.85, 8)], (x + 0.3, y + 0.4, z), cap_bottom=True, cap_top=True)
                x += 0.7
            elif r < 0.6:     # box
                box(o, f"Box{k}", (x + 0.4, y + 0.5, z), 0.75, 0.85, 0.6)
                x += 0.9
            elif r < 0.8:     # round tin
                tube(o, f"Round{k}", [ring((x + 0.45, 0, z), 0.42, y + 0.06, 10), ring((x + 0.45, 0, z), 0.42, y + 0.4, 10)], (x + 0.45, y + 0.25, z), cap_top=True, cap_bottom=True)
                x += 1.0
            else:             # a run of books
                for j in range(4):
                    k += 1
                    box(o, f"Book{k}", (x + 0.1 + 0.2 * j, y + 0.06 + 0.45, z), 0.16, 0.9 - 0.1 * (j % 2), 0.7)
                x += 0.95
    for y in (1.2, 2.6, 4.0): items(y, 1.4)
    h = _front_table(o, pt)
    items(h, -1.15, -2.2, 2.0)
    o.add_flat("Plank", pt)
    return o.write(OUT / f"{name}.obj")

def disp_cheese(name, seed):
    """Fromagerie: stacked wheels on the shelves, a big cut wheel with its wedge on the front table."""
    rnd = random.Random(seed); o = Obj(); pt = []
    _shelf_unit(o, pt, z=1.4, levels=(1.2, 2.7, 4.2), top=5.0)
    k = 0
    for y in (1.2, 2.7, 4.2):
        x = -2.4
        while x < 2.2:
            k += 1
            r = rnd.uniform(0.45, 0.8); hh = rnd.uniform(0.28, 0.5)
            stack = rnd.randint(1, 3)
            for j in range(stack):
                k += 1
                _wheel(o, f"Cheese{k}", x + r, y + 0.06 + j * hh, 1.4, r * (1 - 0.05 * j), hh)
            x += 2 * r + 0.3
    h = _front_table(o, pt)
    _wheel(o, "Cheese91", -1.4, h, -1.15, 1.05, 0.55, a0=math.radians(60), a1=math.radians(360))       # big wheel, wedge cut out
    _wheel(o, "Cheese92", 0.35, h, -0.75, 1.05, 0.55, a0=math.radians(0), a1=math.radians(52))        # the wedge beside it
    _wheel(o, "Cheese93", 1.7, h, -1.3, 0.6, 0.4)
    _wheel(o, "Cheese94", 1.7, h + 0.4, -1.3, 0.55, 0.35)
    box(o, "Trim", (0.4, h + 0.03, -1.55), 1.4, 0.06, 0.5)                                            # a little board
    o.add_flat("Plank", pt)
    return o.write(OUT / f"{name}.obj")

def _choc_bar(o, k, x, y, z, w=1.4, d=0.8, t=0.14, standing=False, wrap=False):
    """A chocolate bar with its grid of squares; standing=True leans it upright against the shelf back."""
    name = f"Wrap{k}" if wrap else f"Choc{k}"
    if standing:
        box(o, name, (x, y + w / 2, z), d, w, t)
        if not wrap:
            for i in range(2):
                for j in range(4):
                    box(o, f"Choc{k}", (x - d / 2 + d * (i + 0.5) / 2, y + w * (j + 0.5) / 4, z - t / 2 - 0.03), d / 2 - 0.08, w / 4 - 0.08, 0.06)
        else:
            box(o, f"Choc{k}", (x, y + w * 0.5, z - t / 2 - 0.02), d + 0.02, w * 0.28, 0.04)             # dark band on the wrapper
    else:
        box(o, name, (x, y + t / 2, z), w, t, d)
        if not wrap:
            for i in range(4):
                for j in range(2):
                    box(o, f"Choc{k}", (x - w / 2 + w * (i + 0.5) / 4, y + t + 0.03, z - d / 2 + d * (j + 0.5) / 2), w / 4 - 0.08, 0.06, d / 2 - 0.08)
        else:
            box(o, f"Choc{k}", (x, y + t + 0.02, z), w * 0.28, 0.04, d + 0.02)

class _Group:
    """Collects box/blob triangles per piece name so a whole arrangement can be tilted together."""
    def __init__(self): self.lists = {}
    def L(self, name): return self.lists.setdefault(name, [])
    def box(self, name, c, sx, sy, sz): box(None, name, c, sx, sy, sz, tris_out=self.L(name))
    def blob(self, name, c, r, rnd, jitter=0.06, squash=(1, 1, 1)): icoblob(None, name, c, r, rnd, jitter, squash, tris_out=self.L(name))
    def tube(self, name, rings, c, **kw):
        # tube() only orients its faces outward when it adds them itself; do the same here (away from c)
        raw = []
        tube(None, name, rings, c, tris_out=raw, **kw)
        out = self.L(name)
        for (p0, p1, p2) in raw:
            n = F.cross(F.sub(p1, p0), F.sub(p2, p0)); cen = F.mul(F.add(F.add(p0, p1), p2), 1 / 3)
            if F.dot(n, F.sub(cen, c)) < 0: p1, p2 = p2, p1
            out.append((p0, p1, p2))
    def absorb(self, other, pivot, sc):
        """Copy another group's triangles in, scaled by sc about pivot."""
        for name, tris in other.lists.items():
            out = self.L(name)
            for tri in tris:
                out.append(tuple(F.add(pivot, F.mul(F.sub(pt, pivot), sc)) for pt in tri))
    def emit(self, o, pivot, pitch):
        """Rotate everything about the X axis through pivot (positive pitch lifts the back edge) and add to o."""
        for name, tris in self.lists.items():
            out = []
            for tri in tris:
                out.append(tuple(F.add(pivot, F.rot_x(F.sub(pt, pivot), pitch)) for pt in tri))
            o.add_flat(name, out)

def _choc_item(g, k, kind, x, y, z, rnd):
    """One item lying flat on a tray at (x, y, z): a bar with its grid, an open truffle box, or pralines on a doily."""
    if kind == "bar":
        w, d, t = 1.25, 0.75, 0.14
        g.box(f"Wrap{k}" if rnd.random() < 0.4 else f"Choc{k}", (x, y + t / 2, z), w, t, d)
        for i in range(4):
            for j in range(2):
                g.box(f"Choc{k}", (x - w / 2 + w * (i + 0.5) / 4, y + t + 0.03, z - d / 2 + d * (j + 0.5) / 2), w / 4 - 0.08, 0.06, d / 2 - 0.08)
    elif kind == "box":
        w, d = 1.3, 0.95
        g.box(f"Wrap{k}", (x, y + 0.04, z), w, 0.08, d)
        for sgn in (-1, 1):
            g.box(f"Wrap{k}", (x + sgn * (w / 2 - 0.03), y + 0.18, z), 0.06, 0.28, d)
            g.box(f"Wrap{k}", (x, y + 0.18, z + sgn * (d / 2 - 0.03)), w, 0.28, 0.06)
        for i in range(3):
            for j in range(2):
                g.blob(f"Choc{k * 10 + i * 2 + j}", (x - 0.4 + 0.4 * i, y + 0.25, z - 0.22 + 0.44 * j), 0.16, rnd)
    else:
        g.tube("Cake", [ring((x, 0, z), 0.62, y, 10), ring((x, 0, z), 0.62, y + 0.04, 10)], (x, y + 0.02, z), cap_top=True, cap_bottom=True)
        for i in range(5):
            a = 2 * math.pi * i / 5
            g.blob(f"Choc{k * 10 + i}", (x + 0.32 * math.cos(a), y + 0.2, z + 0.32 * math.sin(a)), 0.17, rnd)
        g.blob(f"Choc{k * 10 + 7}", (x, y + 0.24, z), 0.18, rnd)

def disp_chocolate(name, seed):
    """Chocolatier: wrapped bars on the back shelves and a stepped display case at the glass, trays tilted 18 deg."""
    rnd = random.Random(seed); o = Obj(); pt = []
    _shelf_unit(o, pt, z=1.5, levels=(1.4, 2.9, 4.4), top=5.0)
    k = 0
    for y in (1.4, 2.9, 4.4):
        x = -2.3
        while x < 2.3:
            k += 1
            _choc_bar(o, k, x, y + 0.06, 1.65 + rnd.uniform(-0.05, 0.05), w=1.3, d=0.75, standing=True, wrap=(rnd.random() < 0.7))
            x += 0.95
    # the case: three steps rising toward the back, each tray tilted so its top faces the street
    pitch = -math.radians(18)          # negative = back edge up = tray top faces the street
    W, D = 5.4, 1.15
    steps = [(-1.55, 1.9), (-0.45, 2.55), (0.65, 3.2)]           # (z centre, top height) of each step
    box(o, "Plank", (0, 0.95, -0.45), W, 1.9, 3.35, tris_out=pt)  # the plinth under the steps
    kinds = ["bar", "box", "doily", "bar", "box"]
    for si, (zc, top) in enumerate(steps):
        if si > 0: box(o, "Plank", (0, (1.9 + top) / 2, zc), W, top - 1.9, D, tris_out=pt)   # riser under the tray
        g = _Group()
        g.box("Trim", (0, top + 0.05, zc), W, 0.1, D)                  # the tray (cream)
        g.box("Plank", (0, top + 0.13, zc + D / 2 - 0.05), W, 0.16, 0.1)  # back lip
        n = 5 if si < 2 else 4
        for i in range(n):
            k += 1
            x = -W / 2 + W * (i + 0.5) / n
            _choc_item(g, k, kinds[(i + si) % len(kinds)], x, top + 0.1, zc, rnd)
        g.emit(o, (0, top, zc - D / 2), pitch)
    o.add_flat("Plank", pt)
    return o.write(OUT / f"{name}.obj")

def _stock_row(o, g, k0, y, z, rnd, x0=-2.5, x1=2.4, kinds=("jar", "box", "bottle")):
    """A row of jars / boxes / bottles along a shelf; g is a _Group or None (then straight into o)."""
    k = k0; x = x0
    def B(name, c, sx, sy, sz):
        if g: g.box(name, c, sx, sy, sz)
        else: box(o, name, c, sx, sy, sz)
    def T(name, rings, c):
        if g: g.tube(name, rings, c, cap_bottom=True, cap_top=True)
        else: tube(o, name, rings, c, cap_bottom=True, cap_top=True)
    while x < x1:
        k += 1
        kind = kinds[rnd.randrange(len(kinds))]
        if kind == "jar":
            T(f"Jar{k}", [ring((x + 0.3, 0, z), 0.28, y + 0.06, 8), ring((x + 0.3, 0, z), 0.28, y + 0.7, 8), ring((x + 0.3, 0, z), 0.18, y + 0.85, 8)], (x + 0.3, y + 0.4, z))
            x += 0.68
        elif kind == "box":
            B(f"Box{k}", (x + 0.4, y + 0.48, z), 0.7, 0.85, 0.55)
            x += 0.85
        elif kind == "bottle":
            T(f"Bottle{k}", [ring((x + 0.22, 0, z), 0.2, y + 0.06, 8), ring((x + 0.22, 0, z), 0.2, y + 0.8, 8), ring((x + 0.22, 0, z), 0.08, y + 1.0, 8), ring((x + 0.22, 0, z), 0.08, y + 1.2, 8)], (x + 0.22, y + 0.6, z))
            x += 0.5
        else:  # pill box: small, upright, lots of them
            B(f"Pill{k}", (x + 0.24, y + 0.36, z), 0.42, 0.6, 0.3)
            x += 0.5
    return k

def disp_grocery(name, seed):
    """Grand Marche / epicerie: tilted produce crates at the glass, sacks on the floor, stocked shelves behind."""
    rnd = random.Random(seed); o = Obj(); pt = []
    _shelf_unit(o, pt, z=1.5, levels=(1.4, 2.9, 4.4), top=5.0)
    k = 0
    for y in (1.4, 2.9, 4.4):
        k = _stock_row(o, None, k, y + 0.06, 1.5, rnd)
    # two-step produce stand, trays tilted toward the street, each holding crates heaped with one kind of produce
    pitch = -math.radians(16)
    W, D = 5.4, 1.3
    box(o, "Plank", (0, 0.6, -0.95), W, 1.2, 2.7, tris_out=pt)
    for si, (zc, top) in enumerate(((-1.55, 1.2), (-0.35, 1.95))):
        if si > 0: box(o, "Plank", (0, (1.2 + top) / 2, zc), W, top - 1.2, D, tris_out=pt)
        g = _Group()
        g.box("Plank", (0, top + 0.05, zc), W, 0.1, D)
        for i in range(4):
            k += 1
            x = -W / 2 + W * (i + 0.5) / 4
            cw, cd, ch = 1.2, 1.05, 0.45
            g.box("Bench", (x, top + 0.1 + 0.03, zc), cw, 0.06, cd)                      # crate floor (wicker colour)
            for sgn in (-1, 1):
                g.box("Bench", (x + sgn * (cw / 2 - 0.03), top + 0.1 + ch / 2, zc), 0.06, ch, cd)
                g.box("Bench", (x, top + 0.1 + ch / 2, zc + sgn * (cd / 2 - 0.03)), cw, ch, 0.06)
            rr = 0.19 + 0.04 * rnd.random()
            for j in range(9):
                gx = x - 0.35 + 0.35 * (j % 3); gz = zc - 0.3 + 0.3 * (j // 3)
                g.blob(f"Fruit{k * 10 + j}", (gx + rnd.uniform(-0.05, 0.05), top + 0.1 + ch - 0.1 + (0.12 if j == 4 else 0), gz), rr, rnd, 0.08)
        g.emit(o, (0, top, zc - D / 2), pitch)
    # sacks on the floor at the sides
    st = []
    for (x, z) in ((-2.4, -1.6), (2.4, -1.5)):
        icoblob(o, "Sack", (x, 0.55, z), 0.62, rnd, 0.1, (1.0, 0.85, 1.0), tris_out=st)
        icoblob(o, "Sack", (x + 0.1, 1.25, z), 0.42, rnd, 0.1, (1.0, 0.7, 1.0), tris_out=st)
    o.add_flat("Sack", st); o.add_flat("Plank", pt)
    return o.write(OUT / f"{name}.obj")

def disp_pharmacy(name, seed):
    """Pharmacie: white shelves of small medicine boxes and bottles in neat rows, a counter, a green cross."""
    rnd = random.Random(seed); o = Obj(); tt = []
    _shelf_unit(o, tt, z=1.5, levels=(1.3, 2.5, 3.7, 4.9), top=5.5, name="Trim")
    k = 0
    for y in (1.3, 2.5, 3.7, 4.9):
        k = _stock_row(o, None, k, y + 0.06, 1.5, rnd, kinds=("pill", "pill", "pill", "bottle"))
    # green cross plaque on the back board
    cr = []
    box(o, "Cross", (0, 5.15, 1.6 + 0.62), 0.9, 0.28, 0.08, tris_out=cr)
    box(o, "Cross", (0, 5.15, 1.6 + 0.62), 0.28, 0.9, 0.08, tris_out=cr)
    o.add_flat("Cross", cr)
    # white counter at the glass with a few boxes on it
    box(o, "Trim", (0, 1.15, -1.2), 5.2, 2.3, 1.3, tris_out=tt)
    box(o, "Trim", (0, 2.36, -1.2), 5.5, 0.12, 1.55, tris_out=tt)
    k = _stock_row(o, None, k, 2.42, -1.35, rnd, x0=-2.0, x1=0.3, kinds=("pill", "bottle"))
    box(o, "Post", (1.6, 2.7, -1.2), 0.9, 0.55, 0.5)                                     # a small scale
    box(o, "Trim", (1.6, 3.0, -1.2), 0.7, 0.05, 0.4, tris_out=tt)
    o.add_flat("Trim", tt)
    return o.write(OUT / f"{name}.obj")

def disp_flowers(name, seed):
    rnd = random.Random(seed); o = Obj(); st, lt, pl = [], [], []
    k = 0
    for (x, z, h) in ((-1.9, -0.4, 1.4), (0.0, 0.2, 1.1), (1.9, -0.5, 1.5)):
        tube(o, "Stone", [ring((x, 0, z), 0.5, 0, 8), ring((x, 0, z), 0.62, h, 8)], (x, h / 2, z), cap_bottom=True, cap_top=True, tris_out=st)
        for i in range(6):
            k += 1
            a = 2 * math.pi * i / 6
            ft = []
            icoblob(o, f"Flower{k}", (x + 0.38 * math.cos(a), h + 1.2 + rnd.uniform(-0.15, 0.15), z + 0.38 * math.sin(a)), 0.34, rnd, 0.1, tris_out=ft)
            o.add_flat(f"Flower{k}", ft)
        icoblob(o, "Leaf", (x, h + 0.7, z), 0.55, rnd, 0.15, (1.2, 0.6, 1.2), tris_out=lt)
    # tall plant in a pot at the back
    tube(o, "Planter", [ring((0, 0, 1.9), 0.6, 0, 8), ring((0, 0, 1.9), 0.75, 1.2, 8)], (0, 0.6, 1.9), cap_bottom=True, cap_top=True, tris_out=pl)
    tube(o, "Trunk", [ring((0, 0, 1.9), 0.08, 1.1, 6), ring((0, 0, 1.9), 0.08, 3.4, 6)], (0, 2.2, 1.9), tris_out=lt)
    for (dx, dy, dz) in ((0, 3.9, 0), (0.6, 3.4, 0.2), (-0.6, 3.5, -0.2), (0.1, 3.3, 0.6)):
        icoblob(o, "Leaf", (dx, dy, 1.9 + dz), 0.62, rnd, 0.15, tris_out=lt)
    o.add_flat("Stone", st); o.add_flat("Leaf", lt); o.add_flat("Planter", pl)
    return o.write(OUT / f"{name}.obj")

def disp_cafe(name, seed):
    """Parisian cafe interior built once across the whole window (26 wide)."""
    rnd = random.Random(seed); o = Obj()
    W, D = 26.0, 4.5
    zf, zb = -D / 2, D / 2
    tt, po, ch, br, tr, st, ln = [], [], [], [], [], [], []
    # floor: cream slab with dark checker squares
    box(o, "Trim", (0, 0.04, 0), W, 0.08, D, tris_out=tt)
    for i in range(int(W)):
        for j in range(int(D)):
            if (i + j) % 2 == 0: box(o, "Post", (-W / 2 + 0.5 + i, 0.09, zf + 0.5 + j), 0.96, 0.02, 0.96, tris_out=po)
    # marble bistro tables along the glass, a bentwood chair either side
    def table(x, z):
        tube(o, "Trim", [ring((x, 0, z), 0.75, 2.15, 14), ring((x, 0, z), 0.75, 2.3, 14)], (x, 2.22, z), cap_top=True, cap_bottom=True, tris_out=tt)
        tube(o, "Post", [ring((x, 0, z), 0.1, 0.1, 6), ring((x, 0, z), 0.1, 2.15, 6)], (x, 1.1, z), tris_out=po)
        tube(o, "Post", [ring((x, 0, z), 0.5, 0.08, 10), ring((x, 0, z), 0.5, 0.18, 10)], (x, 0.13, z), cap_top=True, cap_bottom=True, tris_out=po)
        for sgn in (-1, 1):
            cx = x + sgn * 1.3
            box(o, "Chair", (cx, 1.3, z), 0.95, 0.1, 0.95, tris_out=ch)
            box(o, "Chair", (cx + sgn * 0.45, 2.05, z), 0.1, 1.5, 0.95, tris_out=ch)
            box(o, "Chair", (cx + sgn * 0.45, 2.6, z), 0.1, 0.1, 0.95, tris_out=ch)
            for dx in (-0.4, 0.4):
                for dz in (-0.4, 0.4): box(o, "Chair", (cx + dx, 0.65, z + dz), 0.08, 1.3, 0.08, tris_out=ch)
        tube(o, "Trim", [ring((x + 0.25, 0, z - 0.15), 0.14, 2.3, 8), ring((x + 0.25, 0, z - 0.15), 0.16, 2.55, 8)], (x + 0.25, 2.42, z - 0.15), cap_top=True, tris_out=tt)
    for x in (-10.0, -5.0, 0.0, 5.0, 10.0): table(x, zf + 1.3)
    # the zinc bar along the back with a brass foot rail and stools
    box(o, "Trunk", (0, 1.4, zb - 0.95), W - 2.0, 2.8, 1.5, tris_out=tr)
    box(o, "Stone", (0, 2.88, zb - 0.95), W - 1.6, 0.16, 1.8, tris_out=st)
    box(o, "Brass", (0, 0.45, zb - 1.9), W - 2.4, 0.08, 0.08, tris_out=br)
    for xx in range(-11, 12, 4): box(o, "Brass", (xx, 1.45, zb - 1.72), 1.6, 1.9, 0.03, tris_out=br)
    for xx in (-7.5, -2.5, 2.5, 7.5):
        tube(o, "Post", [ring((xx, 0, zb - 2.6), 0.06, 0.1, 6), ring((xx, 0, zb - 2.6), 0.06, 2.1, 6)], (xx, 1.1, zb - 2.6), tris_out=po)
        tube(o, "Post", [ring((xx, 0, zb - 2.6), 0.4, 0.05, 10), ring((xx, 0, zb - 2.6), 0.4, 0.12, 10)], (xx, 0.08, zb - 2.6), cap_top=True, cap_bottom=True, tris_out=po)
        tube(o, "Chair", [ring((xx, 0, zb - 2.6), 0.42, 2.1, 10), ring((xx, 0, zb - 2.6), 0.42, 2.3, 10)], (xx, 2.2, zb - 2.6), cap_top=True, cap_bottom=True, tris_out=ch)
    # mirrored back bar with shelves of bottles and glasses
    box(o, "Trunk", (0, 5.3, zb - 0.1), W - 2.0, 4.4, 0.2, tris_out=tr)
    for xx in (-9.0, 0.0, 9.0):
        box(o, "Brass", (xx, 5.5, zb - 0.22), 6.6, 3.6, 0.04, tris_out=br)
        box(o, "Trim", (xx, 5.5, zb - 0.25), 6.3, 3.3, 0.04, tris_out=tt)
    for y in (3.3, 4.6, 5.9): box(o, "Trunk", (0, y, zb - 0.5), W - 2.4, 0.08, 0.7, tris_out=tr)
    k = 0
    for (xx, y) in ((-10.5, 3.3), (-8.5, 3.3), (-6.5, 3.3), (-3.5, 3.3), (-1.5, 3.3), (0.5, 3.3), (3.0, 3.3), (5.0, 3.3), (7.5, 3.3), (9.5, 3.3),
                    (-9.5, 4.6), (-5.0, 4.6), (2.0, 4.6), (8.5, 4.6)):
        k += 1
        tube(o, f"Bottle{k}", [ring((xx, 0, zb - 0.5), 0.2, y + 0.05, 8), ring((xx, 0, zb - 0.5), 0.2, y + 0.85, 8), ring((xx, 0, zb - 0.5), 0.08, y + 1.05, 8), ring((xx, 0, zb - 0.5), 0.08, y + 1.3, 8)], (xx, y + 0.6, zb - 0.5), cap_bottom=True, cap_top=True)
    assert k == 14, k
    for xx in (-7.0, 0.0, 6.0):
        for i in range(4): tube(o, "Trim", [ring((xx + 0.45 * i, 0, zb - 0.5), 0.14, 4.65, 8), ring((xx + 0.45 * i, 0, zb - 0.5), 0.16, 5.0, 8)], (xx + 0.45 * i, 4.8, zb - 0.5), cap_top=True, tris_out=tt)
    # espresso machine (right), cups, cake under a dome (left)
    box(o, "Trim", (6.5, 3.65, zb - 0.9), 2.0, 1.5, 1.1, tris_out=tt)
    box(o, "Post", (6.5, 3.65, zb - 1.47), 2.0, 1.5, 0.06, tris_out=po)
    box(o, "Trim", (6.5, 4.48, zb - 0.9), 2.1, 0.14, 1.2, tris_out=tt)
    for dx in (-0.55, 0.55): box(o, "Brass", (6.5 + dx, 3.15, zb - 1.55), 0.12, 0.5, 0.2, tris_out=br)
    box(o, "Brass", (7.65, 4.0, zb - 1.2), 0.1, 0.8, 0.1, tris_out=br)
    for i in range(5): tube(o, "Trim", [ring((5.8 + 0.35 * i, 0, zb - 0.9), 0.15, 4.56, 8), ring((5.8 + 0.35 * i, 0, zb - 0.9), 0.17, 4.86, 8)], (5.8 + 0.35 * i, 4.7, zb - 0.9), cap_top=True, tris_out=tt)
    ct = []
    tube(o, "Trim", [ring((-6.5, 0, zb - 1.0), 0.8, 2.96, 12), ring((-6.5, 0, zb - 1.0), 0.8, 3.06, 12)], (-6.5, 3.0, zb - 1.0), cap_top=True, cap_bottom=True, tris_out=tt)
    tube(o, "Cake", [ring((-6.5, 0, zb - 1.0), 0.6, 3.06, 12), ring((-6.5, 0, zb - 1.0), 0.6, 3.7, 12)], (-6.5, 3.4, zb - 1.0), cap_top=True, tris_out=ct)
    o.add_flat("Cake", ct)
    dt = []
    icoblob(o, "GlassDoor", (-6.5, 3.75, zb - 1.0), 1.05, rnd, 0.02, (1.0, 0.85, 1.0), tris_out=dt)
    o.add_flat("GlassDoor", dt)
    # coat stand at the left end, chalkboard menu on the right end wall
    tube(o, "Post", [ring((-12.2, 0, zf + 2.0), 0.5, 0, 8), ring((-12.2, 0, zf + 2.0), 0.5, 0.1, 8)], (-12.2, 0.05, zf + 2.0), cap_top=True, cap_bottom=True, tris_out=po)
    tube(o, "Post", [ring((-12.2, 0, zf + 2.0), 0.07, 0.1, 6), ring((-12.2, 0, zf + 2.0), 0.07, 5.6, 6)], (-12.2, 2.8, zf + 2.0), tris_out=po)
    box(o, "Post", (-12.2, 5.35, zf + 2.0), 0.7, 0.08, 0.08, tris_out=po); box(o, "Post", (-12.2, 5.35, zf + 2.0), 0.08, 0.08, 0.7, tris_out=po)
    box(o, "Trim", (12.3, 4.6, zf + 2.2), 0.14, 2.4, 3.4, tris_out=tt)
    box(o, "Sign", (12.2, 4.6, zf + 2.2), 0.08, 2.1, 3.1)
    for i in range(4): box(o, "Trim", (12.15, 5.3 - 0.4 * i, zf + 2.1 - 0.1 * (i % 2)), 0.02, 0.07, 2.0 - 0.5 * (i % 3), tris_out=tt)
    # globe lamps
    for xx in (-9.0, -3.0, 3.0, 9.0):
        box(o, "Post", (xx, 7.2, zf + 2.0), 0.05, 1.6, 0.05, tris_out=po)
        icoblob(o, "Lantern", (xx, 6.0, zf + 2.0), 0.55, rnd, 0.02, tris_out=ln)
    o.add_flat("Trim", tt); o.add_flat("Post", po); o.add_flat("Chair", ch); o.add_flat("Brass", br)
    o.add_flat("Trunk", tr); o.add_flat("Stone", st); o.add_flat("Lantern", ln)
    return o.write(OUT / f"{name}.obj")

def _hat_g(g0, k, x, y, z, style, rnd, N=24, sc=0.72):
    """A hat with its brim at height y, centred on (x, z), written into _Group g0 as Hat<k> / Band<k>.
    Built at design size then scaled by sc about the brim centre. Crowns start 0.2 below the brim and sit a little
    inside its inner edge so the join is sealed."""
    c = (x, 0, z); g = _Group()
    H, B = f"Hat{k}", f"Band{k}"
    def crown(rings): g.tube(H, rings, (x, y + 0.6, z), cap_top=True, cap_bottom=True)   # closed underneath: no see-through
    def flat_brim(r, t=0.07): g.tube(H, [ring(c, r, y, N), ring(c, r, y + t, N)], (x, y + t / 2, z), cap_top=True, cap_bottom=True)
    def cone_brim(r_in, r_out, drop, t=0.07):
        # brim that droops from the crown outward (sun hat, cloche) or curls up (bowler: negative drop);
        # the orientation centres sit below / above the sheet so the top faces up and the underside down
        g.tube(H, [ring(c, r_out, y - drop, N), ring(c, r_in, y, N)], (x, y - 3.0, z))
        g.tube(H, [ring(c, r_in, y + t, N), ring(c, r_out, y - drop + t, N)], (x, y + 3.0, z))
        g.tube(H, [ring(c, r_out, y - drop, N), ring(c, r_out, y - drop + t, N)], (x, y - drop, z))
    def band(r, y0, h=0.24): g.tube(B, [ring(c, r, y0, N), ring(c, r, y0 + h, N)], (x, y0 + h / 2, z))
    if style == "top":
        cone_brim(0.66, 1.1, -0.1)
        crown([ring(c, 0.72, y - 0.2, N), ring(c, 0.68, y + 0.6, N), ring(c, 0.75, y + 1.15, N)])
        band(0.74, y + 0.1)
    elif style == "boater":
        flat_brim(1.3)
        crown([ring(c, 0.85, y - 0.2, N), ring(c, 0.85, y + 0.6, N)])
        band(0.87, y + 0.1, 0.26)
    elif style == "cloche":
        cone_brim(0.74, 1.05, 0.22)
        crown([ring(c, 0.82, y - 0.2, N), ring(c, 0.82, y + 0.45, N), ring(c, 0.66, y + 0.85, N), ring(c, 0.3, y + 1.08, N)])
        band(0.84, y + 0.1, 0.22)
    elif style == "sun":
        cone_brim(0.79, 1.55, 0.28)
        crown([ring(c, 0.87, y - 0.2, N), ring(c, 0.8, y + 0.5, N), ring(c, 0.5, y + 0.78, N)])
        band(0.89, y + 0.1, 0.24)
        g.blob(B, (x + 0.8, y + 0.28, z + 0.45), 0.2, rnd, 0.08)
        g.blob(B, (x + 1.05, y + 0.28, z + 0.15), 0.2, rnd, 0.08)
    elif style == "bowler":
        cone_brim(0.72, 1.12, -0.16)
        crown([ring(c, 0.8, y - 0.2, N), ring(c, 0.78, y + 0.4, N), ring(c, 0.6, y + 0.78, N), ring(c, 0.22, y + 0.95, N)])
        band(0.82, y + 0.1, 0.22)
    elif style == "fedora":
        cone_brim(0.76, 1.35, 0.08)
        crown([ring(c, 0.84, y - 0.2, N), ring(c, 0.78, y + 0.6, N), ring(c, 0.7, y + 1.05, N), ring(c, 0.5, y + 1.15, N)])
        band(0.86, y + 0.1, 0.26)
    else:  # beret
        g.blob(H, (x, y + 0.24, z), 1.0, rnd, 0.04, (1.0, 0.3, 1.0))
        g.box(H, (x, y + 0.62, z), 0.08, 0.22, 0.08)
    g0.absorb(g, (x, y, z), sc)

def _hat_box(o, k, x, y, z, r, h, N=24):
    tube(o, f"Wrap{k}", [ring((x, 0, z), r, y, N), ring((x, 0, z), r, y + h, N)], (x, y + h / 2, z), cap_top=True, cap_bottom=True)
    tube(o, f"Wrap{k + 1}", [ring((x, 0, z), r + 0.05, y + h - 0.18, N), ring((x, 0, z), r + 0.05, y + h + 0.02, N)], (x, y + h, z), cap_top=True)

def chalkboard(name, seed):
    """A-frame chalk menu board for the pavement outside the cafe: two boards hinged at the top, feet apart,
    chalk faces on the OUTSIDE, about 3.6 studs tall."""
    o = Obj(); tt = []
    for sgn in (-1, 1):
        g = _Group()
        g.box("Plank", (0, 1.8, 0), 2.4, 3.6, 0.1)
        g.box("Sign", (0, 1.75, sgn * 0.07), 2.0, 2.8, 0.04)                                     # chalk face on the outer side
        for i in range(5): g.box("Trim", (-0.15 + 0.1 * (i % 2), 2.8 - 0.42 * i, sgn * 0.1), 1.3 - 0.35 * (i % 3), 0.06, 0.02)
        g.emit(o, (0, 3.6, 0), -sgn * math.radians(12))                                        # rotate about the top hinge
    box(o, "Post", (0, 3.62, 0), 2.5, 0.12, 0.3, tris_out=tt)
    o.add_flat("Post", tt)
    return o.write(OUT / f"{name}.obj")

def disp_hats(name, seed):
    """Chapelier: seven hats, each on its own dark stand at a different height, tilted 18 deg toward the glass so
    the crown and the oval of the brim both read; hat boxes on the floor and a shelf of boxes behind."""
    rnd = random.Random(seed); o = Obj(); po, pt = [], []
    pitch = -math.radians(18)
    spots = ((-1.8, -1.5, 1.6, "top"), (0.0, -1.6, 1.3, "fedora"), (1.8, -1.5, 1.5, "cloche"),
             (-0.9, -0.2, 2.6, "boater"), (0.9, -0.2, 2.8, "bowler"), (-1.9, 0.9, 3.8, "sun"), (1.9, 0.9, 3.6, "beret"))
    k = 0
    for (x, z, h, st) in spots:
        k += 1
        tube(o, "Post", [ring((x, 0, z), 0.5, 0, 12), ring((x, 0, z), 0.5, 0.08, 12)], (x, 0.04, z), cap_top=True, cap_bottom=True, tris_out=po)
        tube(o, "Post", [ring((x, 0, z), 0.06, 0.08, 6), ring((x, 0, z), 0.06, h, 6)], (x, h / 2, z), tris_out=po)
        g = _Group()
        g.tube("Post", [ring((x, 0, z), 0.42, h, 12), ring((x, 0, z), 0.42, h + 0.08, 12)], (x, h + 0.04, z), cap_top=True)
        _hat_g(g, k, x, h + 0.08, z, st, rnd)
        g.emit(o, (x, h, z), pitch)
    # floor boxes sit between the stands, clear of every stand base and of the shelf uprights (same three names)
    _hat_box(o, 21, 0.0, 0.0, 1.1, 0.6, 0.66); _hat_box(o, 23, 0.05, 0.66, 1.12, 0.5, 0.56); _hat_box(o, 25, 2.55, 0.0, -0.35, 0.5, 0.55)
    _shelf_unit(o, pt, w=5.6, d=1.1, z=2.05, levels=(5.0,), top=5.6, name="Plank")
    _hat_box(o, 27, -1.6, 5.06, 2.05, 0.55, 0.5); _hat_box(o, 29, 0.0, 5.06, 2.05, 0.5, 0.46); _hat_box(o, 31, 1.6, 5.06, 2.05, 0.55, 0.5)
    o.add_flat("Post", po); o.add_flat("Plank", pt)
    return o.write(OUT / f"{name}.obj")

def disp_post(name, seed):
    """La Poste: wall of brass pigeonholes, a counter with a clerk's window, a scale, parcels tied with string, a
    tray of letters and a yellow letter box. Exactly 32 randomly-coloured parts (Box1..32), like the shelf kit it
    replaces, so the builder's colour sequence for every other shop stays untouched."""
    rnd = random.Random(seed); o = Obj(); pt, tt, br, po, yl = [], [], [], [], []
    # pigeonhole wall
    box(o, "Plank", (0, 3.3, 1.95), 5.6, 3.8, 0.12, tris_out=pt)
    for sgn in (-1, 1): box(o, "Plank", (sgn * 2.77, 3.3, 1.85), 0.08, 3.8, 0.3, tris_out=pt)
    for r in range(4):
        y = 1.65 + r * 0.9
        box(o, "Plank", (0, y - 0.42, 1.85), 5.6, 0.06, 0.3, tris_out=pt)
        for cidx in range(6):
            x = -2.3 + cidx * 0.92
            box(o, "Brass", (x, y, 1.87), 0.8, 0.74, 0.06, tris_out=br)
            box(o, "Post", (x + 0.28, y, 1.82), 0.08, 0.08, 0.06, tris_out=po)          # tiny lock
    box(o, "Plank", (0, 5.25, 1.85), 5.6, 0.1, 0.3, tris_out=pt)
    # counter with a yellow band and a clerk's window on the left
    box(o, "Plank", (0, 1.2, -1.0), 5.2, 2.4, 1.3, tris_out=pt)                           # wooden counter
    box(o, "Trunk", (0, 2.46, -1.0), 5.5, 0.12, 1.55)                                         # darker wood top
    for xx in (-1.75, 0.0, 1.75): box(o, "Trunk", (xx, 1.1, -1.66), 1.5, 1.4, 0.06)              # dark wood panels
    box(o, "Yellow", (0, 2.1, -1.68), 5.2, 0.32, 0.04, tris_out=yl)
    # glass screen the full width of the counter, with the clerk's hatch as an opening in the middle
    for xx in (-2.6, -0.85, 0.85, 2.6): box(o, "Post", (xx, 3.95, -0.8), 0.12, 2.9, 0.12, tris_out=po)
    box(o, "Post", (0, 5.42, -0.8), 5.35, 0.14, 0.16, tris_out=po)                            # top rail
    box(o, "GlassDoor", (-1.72, 3.95, -0.8), 1.65, 2.9, 0.04)                                  # left pane
    box(o, "GlassDoor", (1.72, 3.95, -0.8), 1.65, 2.9, 0.04)                                   # right pane
    box(o, "GlassDoor", (0, 4.75, -0.8), 1.6, 1.3, 0.04)                                       # pane above the hatch
    box(o, "Post", (0, 4.08, -0.8), 1.8, 0.1, 0.12, tris_out=po)                               # hatch head
    box(o, "Trunk", (0, 2.6, -0.8), 1.8, 0.16, 0.7)                                            # hatch ledge
    # scale on the counter
    box(o, "Post", (1.6, 2.7, -1.1), 0.9, 0.36, 0.7, tris_out=po)
    box(o, "Trim", (1.6, 2.95, -1.1), 0.8, 0.14, 0.6, tris_out=tt)
    box(o, "Brass", (1.6, 3.35, -1.35), 0.5, 0.5, 0.08, tris_out=br)
    box(o, "Post", (1.6, 3.05, -1.35), 0.12, 0.3, 0.06, tris_out=po)
    # yellow letter box standing at the right
    box(o, "Yellow", (2.45, 1.3, -0.2), 0.9, 2.6, 0.7, tris_out=yl)
    box(o, "Post", (2.45, 2.2, -0.57), 0.5, 0.08, 0.06, tris_out=po)                       # slot
    box(o, "Post", (2.45, 2.62, -0.2), 0.95, 0.06, 0.75, tris_out=po)
    k = 0
    def parcel(x, y, z, w, h, d, yaw=0.0):
        nonlocal k
        k += 1
        box(o, f"Box{k}", (x, y + h / 2, z), w, h, d, yaw=yaw)
        box(o, "Post", (x, y + h / 2, z), w + 0.03, 0.05, 0.08, yaw=yaw, tris_out=po)      # string across
        box(o, "Post", (x, y + h / 2, z), 0.08, 0.05, d + 0.03, yaw=yaw, tris_out=po)
        box(o, "Post", (x, y + h + 0.01, z), w + 0.03, 0.03, 0.08, yaw=yaw, tris_out=po)
    # parcels: a stack on the counter, a pyramid on the floor, a pile on the left floor (20)
    parcel(-2.0, 2.52, -1.1, 0.9, 0.5, 0.7); parcel(-2.0, 3.02, -1.1, 0.7, 0.4, 0.6, 0.3)
    parcel(0.0, 2.52, -1.15, 0.6, 0.45, 0.5, -0.2)
    for i in range(4): parcel(-2.5 + i * 0.4 * 0 + (-1.0 + i * 0.66), 0.0, 0.9, 0.62, 0.5, 0.55, rnd.uniform(-0.2, 0.2))
    for i in range(3): parcel(-0.67 + i * 0.66, 0.5, 0.9, 0.6, 0.45, 0.5, rnd.uniform(-0.2, 0.2))
    for i in range(2): parcel(-0.33 + i * 0.66, 0.95, 0.9, 0.55, 0.42, 0.5, rnd.uniform(-0.2, 0.2))
    parcel(0.0, 1.37, 0.9, 0.5, 0.4, 0.45, 0.4)
    for i in range(3): parcel(-2.5 + (i % 2) * 0.1, 0.0 + i * 0.5, 0.2, 0.9, 0.5, 0.8, rnd.uniform(-0.15, 0.15))
    for i in range(2): parcel(2.4 + (i % 2) * 0.05, 0.0 + i * 0.55, 1.0, 0.8, 0.55, 0.7, rnd.uniform(-0.15, 0.15))
    for i in range(2): parcel(1.6 + i * 0.05, 0.0 + i * 0.45, 0.2, 0.6, 0.45, 0.5, rnd.uniform(-0.2, 0.2))
    # a tray of letters on the counter (12 thin boxes, leaning)
    box(o, "Plank", (0.9, 2.55, -0.5), 1.5, 0.06, 0.8, tris_out=pt)
    for sgn in (-1, 1): box(o, "Plank", (0.9 + sgn * 0.73, 2.7, -0.5), 0.04, 0.3, 0.8, tris_out=pt)
    for i in range(12):
        k += 1
        box(o, f"Box{k}", (0.28 + i * 0.11, 2.85, -0.5), 0.03, 0.5, 0.7)
    assert k == 32, k
    o.add_flat("Plank", pt); o.add_flat("Trim", tt); o.add_flat("Brass", br); o.add_flat("Post", po); o.add_flat("Yellow", yl)
    return o.write(OUT / f"{name}.obj")

def disp_post_b(name, seed):
    """La Poste, the parcels side (second window): shelving of packages, a loaded trolley, a mail sack, a scale,
    and an internal doorway off to one side. Exactly 32 randomly-coloured parts (Box1..32) like disp_post."""
    rnd = random.Random(seed); o = Obj(); pt, po, yl, sk = [], [], [], []
    k = 0
    def parcel(x, y, z, w, h, d, yaw=0.0):
        nonlocal k
        k += 1
        box(o, f"Box{k}", (x, y + h / 2, z), w, h, d, yaw=yaw)
        box(o, "Post", (x, y + h / 2, z), w + 0.03, 0.05, 0.08, yaw=yaw, tris_out=po)
        box(o, "Post", (x, y + h / 2, z), 0.08, 0.05, d + 0.03, yaw=yaw, tris_out=po)
    # shelving unit on the left two thirds of the back wall, three shelves of parcels (18)
    box(o, "Plank", (-1.1, 2.7, 2.0), 3.6, 5.4, 0.12, tris_out=pt)
    for xx in (-2.85, 0.65): box(o, "Plank", (xx, 2.7, 1.5), 0.1, 5.4, 1.1, tris_out=pt)
    for y in (0.15, 1.85, 3.55):
        box(o, "Plank", (-1.1, y, 1.5), 3.6, 0.1, 1.1, tris_out=pt)
        x = -2.65
        for i in range(6):
            w = 0.42 + 0.14 * ((i * 7 + int(y * 10)) % 3)
            parcel(x + w / 2, y + 0.05, 1.5 + rnd.uniform(-0.1, 0.1), w, 0.36 + 0.12 * ((i + int(y)) % 3), 0.5, rnd.uniform(-0.12, 0.12))
            x += w + 0.14
    box(o, "Plank", (-1.1, 5.3, 1.5), 3.6, 0.1, 1.1, tris_out=pt)
    # internal doorway on the right, door ajar into the back room
    box(o, "Sign", (1.95, 2.3, 2.02), 2.0, 4.6, 0.06)                                          # the dark opening
    for xx in (0.9, 3.0): box(o, "Post", (xx, 2.3, 1.95), 0.12, 4.6, 0.2, tris_out=po)
    box(o, "Post", (1.95, 4.66, 1.95), 2.3, 0.12, 0.2, tris_out=po)
    box(o, "Trunk", (2.55, 2.28, 1.55), 1.0, 4.5, 0.1, yaw=0.9)                                # door leaf, half open
    box(o, "Brass", (2.2, 2.3, 1.25), 0.1, 0.1, 0.25)
    # parcel trolley at the front left, six parcels on it (24 so far)
    box(o, "Plank", (-1.5, 0.55, -1.1), 2.0, 0.1, 1.3, tris_out=pt)
    for (xx, zz) in ((-2.35, -1.6), (-0.65, -1.6), (-2.35, -0.6), (-0.65, -0.6)):
        tube(o, "Wheel", [ring((xx, 0, zz), 0.22, 0.0, 10), ring((xx, 0, zz), 0.22, 0.12, 10)], (xx, 0.06, zz), cap_top=True, cap_bottom=True)
        box(o, "Post", (xx, 0.3, zz), 0.08, 0.5, 0.08, tris_out=po)
    box(o, "Post", (-0.55, 1.6, -1.1), 0.08, 2.2, 0.08, tris_out=po); box(o, "Post", (-0.55, 2.7, -1.1), 0.08, 0.08, 1.3, tris_out=po)
    parcel(-2.0, 0.6, -1.3, 0.8, 0.55, 0.7); parcel(-1.2, 0.6, -1.3, 0.7, 0.45, 0.6, 0.2)
    parcel(-2.0, 0.6, -0.7, 0.75, 0.5, 0.5, -0.15); parcel(-1.25, 0.6, -0.75, 0.6, 0.6, 0.5)
    parcel(-1.8, 1.15, -1.1, 0.7, 0.45, 0.6, 0.3); parcel(-1.1, 1.05, -1.2, 0.5, 0.4, 0.45, -0.3)
    # mail sack and a standing scale at the front right
    icoblob(o, "Sack", (1.2, 0.7, -1.3), 0.7, rnd, 0.1, (1.0, 1.0, 1.0), tris_out=sk)
    icoblob(o, "Sack", (1.3, 1.45, -1.3), 0.42, rnd, 0.1, (1.0, 0.75, 1.0), tris_out=sk)
    box(o, "Post", (2.3, 0.15, -1.2), 1.2, 0.3, 1.0, tris_out=po)
    box(o, "Post", (2.3, 1.4, -1.55), 0.12, 2.5, 0.12, tris_out=po)
    box(o, "Trim", (2.3, 2.75, -1.45), 0.7, 0.7, 0.15)
    box(o, "Post", (2.3, 2.75, -1.36), 0.06, 0.4, 0.04, tris_out=po)
    parcel(2.3, 0.3, -1.1, 0.7, 0.5, 0.55, 0.2)                                              # parcel on the scale (25)
    # a rack of letters on the wall between shelves and door (7 -> 32)
    box(o, "Plank", (1.95, 1.0, 1.9), 1.6, 0.08, 0.35, tris_out=pt)
    for i in range(7):
        k += 1
        box(o, f"Box{k}", (1.35 + i * 0.2, 1.3, 1.85), 0.03, 0.5, 0.3)
    box(o, "Yellow", (-1.1, 5.45, 1.98), 3.6, 0.22, 0.06, tris_out=yl)                        # yellow stripe over the shelves
    assert k == 32, k
    o.add_flat("Plank", pt); o.add_flat("Post", po); o.add_flat("Yellow", yl); o.add_flat("Sack", sk)
    return o.write(OUT / f"{name}.obj")

def disp_bakery_b(name, seed):
    """Boulangerie, second window: a pastry counter. Two tilted trays of croissants and buns, a row of tarts, a
    tiered cake stand (the one Icing1 part, like disp_bakery) and a tall basket of baguettes at the back."""
    rnd = random.Random(seed); o = Obj(); pt, bt, wt, tt, ct = [], [], [], [], []
    # back wall: shelves of loaves lying on their sides
    _shelf_unit(o, pt, z=1.5, levels=(2.0, 3.6), top=4.6)
    for y in (2.0, 3.6):
        for i in range(4):
            icoblob(o, "Bread", (-2.0 + 1.3 * i, y + 0.36, 1.5), 0.5, rnd, 0.08, (1.45, 0.62, 0.7), tris_out=bt)
    # tall wicker basket of baguettes, back left
    tube(o, "Bench", [ring((-2.3, 0, -0.1), 0.55, 0, 10), ring((-2.3, 0, -0.1), 0.7, 1.6, 10)], (-2.3, 0.8, -0.1), cap_bottom=True, tris_out=wt)
    for i in range(6):
        a = 2 * math.pi * i / 6
        icoblob(o, "Bread", (-2.3 + 0.33 * math.cos(a), 2.1, -0.1 + 0.33 * math.sin(a)), 1.05, rnd, 0.06, (0.18, 1.0, 0.18), tris_out=bt)
    # pastry case: two tilted trays toward the glass
    pitch = -math.radians(16)
    W, D = 4.6, 1.15
    box(o, "Trim", (0.4, 0.55, -0.9), W, 1.1, 2.4, tris_out=tt)                              # white base
    for si, (zc, top) in enumerate(((-1.5, 1.1), (-0.35, 1.7))):
        if si > 0: box(o, "Trim", (0.4, (1.1 + top) / 2, zc), W, top - 1.1, D, tris_out=tt)
        g = _Group()
        g.box("Plank", (0.4, top + 0.05, zc), W, 0.1, D)                                      # wooden tray
        for i in range(5):
            x = 0.4 - W / 2 + W * (i + 0.5) / 5
            if si == 0:                                                                       # croissants: three lumps in an arc
                for j, (dx, dz) in enumerate(((-0.28, 0.12), (0.0, -0.08), (0.28, 0.12))):
                    g.blob("Bread", (x + dx, top + 0.28, zc + dz), 0.2 if j == 1 else 0.17, rnd, 0.08, (1.1, 0.8, 1.0))
            else:                                                                             # tarts: cream shell, fruit on top
                g.tube("Cake", [ring((x, 0, zc), 0.36, top + 0.1, 12), ring((x, 0, zc), 0.4, top + 0.28, 12)], (x, top + 0.19, zc), cap_bottom=True, cap_top=True)
                for j in range(4):
                    a = 2 * math.pi * j / 4
                    g.blob("Bread", (x + 0.17 * math.cos(a), top + 0.34, zc + 0.17 * math.sin(a)), 0.09, rnd, 0.06)
        g.emit(o, (0.4, top, zc - D / 2), pitch)
    # tiered cake stand at the right of the case
    _cake(o, 2.35, -1.2, 1, rnd, ct, tt, r=0.55, y=1.7)
    box(o, "Trim", (2.35, 1.25, -1.2), 1.5, 0.3, 1.5, tris_out=tt)
    o.add_flat("Plank", pt); o.add_flat("Bread", bt); o.add_flat("Bench", wt); o.add_flat("Trim", tt); o.add_flat("Cake", ct)
    return o.write(OUT / f"{name}.obj")

def pot(name, seed):
    """Terracotta pot with a clipped round shrub, for beside the shop doors (about 3 studs tall)."""
    rnd = random.Random(seed); o = Obj()
    tube(o, "Planter", [ring((0, 0, 0), 0.6, 0.0, 8), ring((0, 0, 0), 0.8, 1.1, 8), ring((0, 0, 0), 0.9, 1.25, 8), ring((0, 0, 0), 0.9, 1.45, 8)],
         (0, 0.7, 0), cap_bottom=True, cap_top=True)
    lt = []
    icoblob(o, "Leaf", (0, 2.3, 0), 0.95, rnd, 0.14, (1.0, 1.0, 1.0), tris_out=lt)
    o.add_flat("Leaf", lt)
    return o.write(OUT / f"{name}.obj")

def crates(name, seed):
    """A wooden crate of bread loaves (about 2 studs wide) for the boulangerie doorstep."""
    rnd = random.Random(seed); o = Obj()
    pt = []
    W, D, Hc = 2.2, 1.6, 1.3
    box(o, "Plank", (0, 0.08, 0), W, 0.16, D, tris_out=pt)
    for sgn in (-1, 1):
        for yy in (0.4, 1.0):
            box(o, "Plank", (0, yy, sgn * (D / 2 - 0.06)), W, 0.36, 0.12, tris_out=pt)
            box(o, "Plank", (sgn * (W / 2 - 0.06), yy, 0), 0.12, 0.36, D, tris_out=pt)
        for x in (-W / 2 + 0.1, W / 2 - 0.1):
            box(o, "Plank", (x, Hc / 2, sgn * (D / 2 - 0.1)), 0.2, Hc, 0.2, tris_out=pt)
    o.add_flat("Plank", pt)
    bt = []
    for i in range(4):
        cx = -0.6 + 0.4 * i
        icoblob(o, "Bread", (cx, 1.05 + 0.1 * (i % 2), rnd.uniform(-0.15, 0.15)), 0.5, rnd, 0.08, (0.55, 0.55, 1.05), tris_out=bt)
    icoblob(o, "Bread", (0.1, 1.55, 0.0), 0.5, rnd, 0.08, (0.55, 0.5, 1.0), tris_out=bt)
    o.add_flat("Bread", bt)
    return o.write(OUT / f"{name}.obj")

def cafe_table(name, seed):
    rnd = random.Random(seed); o = Obj()
    r = 1.1
    top = ring((0, 0, 0), r, 2.3, 10)
    tube(o, "Table", [ring((0, 0, 0), r, 2.1, 10), top], (0, 2.2, 0), cap_top=True, cap_bottom=True)
    tube(o, "Table", [ring((0, 0, 0), 0.12, 0.0, 6), ring((0, 0, 0), 0.12, 2.1, 6)], (0, 1.0, 0))
    tube(o, "Table", [ring((0, 0, 0), 0.7, 0.0, 8), ring((0, 0, 0), 0.7, 0.12, 8)], (0, 0.06, 0), cap_top=True)
    ct = []
    for a in (0.0, math.pi):
        cx, cz = 2.1 * math.sin(a), 2.1 * math.cos(a)
        box(o, "Chair", (cx, 1.4, cz), 1.5, 0.15, 1.5, tris_out=ct, yaw=a)
        bx, bz = cx + 0.7 * math.sin(a), cz + 0.7 * math.cos(a)
        box(o, "Chair", (bx, 2.4, bz), 1.5, 1.9, 0.15, tris_out=ct, yaw=a)
        for sx in (-0.6, 0.6):
            for sz in (-0.6, 0.6):
                lx = cx + sx * math.cos(a) - sz * math.sin(a); lz = cz + sx * math.sin(a) + sz * math.cos(a)
                box(o, "Chair", (lx, 0.7, lz), 0.14, 1.4, 0.14, tris_out=ct)
    o.add_flat("Chair", ct)
    return o.write(OUT / f"{name}.obj")

def parasol(name, seed):
    rnd = random.Random(seed); o = Obj()
    tube(o, "Pole", [ring((0, 0, 0), 0.12, 0, 6), ring((0, 0, 0), 0.12, 6.4, 6)], (0, 3.2, 0), cap_bottom=True, cap_top=True)
    tube(o, "Pole", [ring((0, 0, 0), 0.9, 0, 8), ring((0, 0, 0), 0.9, 0.2, 8)], (0, 0.1, 0), cap_top=True)
    rim = ring((0, 0, 0), 3.4, 5.2, 8)
    apex = (0, 6.5, 0)
    tris = []
    for i in range(8):
        j = (i + 1) % 8
        tris.append((rim[i], rim[j], apex))
        tris.append((rim[j], rim[i], apex))
        # scallop
        m = mul(add(rim[i], rim[j]), 0.5); m = (m[0] * 1.02, m[1] - 0.45, m[2] * 1.02)
        tris.append((rim[i], m, rim[j])); tris.append((rim[j], m, rim[i]))
    o.add_flat("Canopy", tris)
    return o.write(OUT / f"{name}.obj")

def lamp_post(name, seed):
    o = Obj()
    tube(o, "Post", [ring((0, 0, 0), 0.5, 0, 6), ring((0, 0, 0), 0.5, 0.6, 6), ring((0, 0, 0), 0.18, 0.7, 6), ring((0, 0, 0), 0.16, 8.0, 6)], (0, 4, 0), cap_bottom=True, cap_top=True)
    box(o, "Post", (0, 8.4, 0), 1.2, 0.2, 1.2)
    lt = []
    box(o, "Lantern", (0, 9.2, 0), 0.9, 1.4, 0.9, tris_out=lt)
    o.add_flat("Lantern", lt)
    pt = [((-0.7, 9.9, -0.7), (0.7, 9.9, -0.7), (0, 10.7, 0)), ((0.7, 9.9, -0.7), (0.7, 9.9, 0.7), (0, 10.7, 0)),
          ((0.7, 9.9, 0.7), (-0.7, 9.9, 0.7), (0, 10.7, 0)), ((-0.7, 9.9, 0.7), (-0.7, 9.9, -0.7), (0, 10.7, 0))]
    o.add_flat("Post", pt, (0, 9.8, 0))
    return o.write(OUT / f"{name}.obj")

def planter(name, seed):
    rnd = random.Random(seed); o = Obj()
    box(o, "Planter", (0, 0.9, 0), 3.2, 1.8, 1.6)
    box(o, "Planter", (0, 1.85, 0), 3.5, 0.2, 1.9)
    lt = []
    for i in range(4):
        icoblob(o, "Leaf", (-1.0 + 0.7 * i, 2.3, rnd.uniform(-0.2, 0.2)), 0.7, rnd, 0.2, (1.0, 0.9, 1.0), tris_out=lt)
    o.add_flat("Leaf", lt)
    ft = []
    for i in range(6):
        icoblob(o, "Flower", (rnd.uniform(-1.3, 1.3), 2.85, rnd.uniform(-0.4, 0.4)), 0.24, rnd, 0.1, tris_out=ft)
    o.add_flat("Flower", ft)
    return o.write(OUT / f"{name}.obj")

def fountain(name, seed):
    rnd = random.Random(seed); o = Obj()
    tube(o, "Stone", [ring((0, 0, 0), 5.0, 0, 10), ring((0, 0, 0), 5.0, 1.4, 10), ring((0, 0, 0), 4.3, 1.4, 10), ring((0, 0, 0), 4.3, 0.3, 10)], (0, 0.7, 0), cap_bottom=True)
    inner = ring((0, 0, 0), 4.3, 1.4, 10)
    c = mul(sum_pts(inner), 1 / 10)
    # rim top ring face
    outer = ring((0, 0, 0), 5.0, 1.4, 10)
    rt = []
    for i in range(10):
        j = (i + 1) % 10
        rt += [(outer[i], inner[j], outer[j]), (outer[i], inner[i], inner[j])]
    o.add_flat("Stone", rt, (0, 0, 0))
    wt = []
    wr = ring((0, 0, 0), 4.3, 1.1, 10)
    for i in range(10):
        j = (i + 1) % 10
        wt.append(((0, 1.1, 0), wr[j], wr[i]))
    o.add_flat("Water", wt, (0, 0, 0))
    tube(o, "Stone", [ring((0, 0, 0), 0.8, 1.0, 8), ring((0, 0, 0), 0.5, 4.2, 8)], (0, 2.5, 0), cap_top=True)
    tube(o, "Stone", [ring((0, 0, 0), 2.2, 4.0, 10), ring((0, 0, 0), 2.2, 4.7, 10), ring((0, 0, 0), 1.7, 4.7, 10)], (0, 4.3, 0), cap_bottom=True)
    w2 = ring((0, 0, 0), 1.7, 4.55, 10)
    w2t = []
    for i in range(10):
        j = (i + 1) % 10
        w2t.append(((0, 4.55, 0), w2[j], w2[i]))
    o.add_flat("Water", w2t, (0, 0, 0))
    tube(o, "Stone", [ring((0, 0, 0), 0.35, 4.5, 6), ring((0, 0, 0), 0.25, 6.4, 6)], (0, 5.4, 0), cap_top=True)
    return o.write(OUT / f"{name}.obj")

def bollards(name, seed):
    o = Obj()
    for i in range(3):
        x = -4 + 4 * i
        tube(o, "Post", [ring((x, 0, 0), 0.35, 0, 6), ring((x, 0, 0), 0.3, 2.4, 6), ring((x, 0, 0), 0.42, 2.6, 6), ring((x, 0, 0), 0.0, 3.0, 6)], (x, 1.4, 0), cap_bottom=True)
    return o.write(OUT / f"{name}.obj")

def shop_sign(name, seed):
    o = Obj()
    tube(o, "Post", [ring((0, 0, 0), 0.14, 0, 6), ring((0, 0, 0), 0.14, 6.0, 6)], (0, 3, 0), cap_bottom=True, cap_top=True)
    box(o, "Post", (0.9, 5.9, 0), 1.8, 0.14, 0.14)
    box(o, "Sign", (1.3, 4.9, 0), 2.4, 1.8, 0.12)
    box(o, "Trim", (1.3, 4.9, 0), 2.6, 2.0, 0.08)
    return o.write(OUT / f"{name}.obj")

def bench(name, seed):
    o = Obj()
    bt = []
    box(o, "Bench", (0, 1.5, 0), 5.0, 0.25, 1.6, tris_out=bt)
    box(o, "Bench", (0, 2.6, 0.7), 5.0, 1.6, 0.2, tris_out=bt)
    for x in (-2.1, 2.1):
        box(o, "Bench", (x, 0.7, -0.5), 0.25, 1.4, 0.25, tris_out=bt)
        box(o, "Bench", (x, 0.7, 0.5), 0.25, 1.4, 0.25, tris_out=bt)
    o.add_flat("Bench", bt)
    return o.write(OUT / f"{name}.obj")

def bicycle(name, seed):
    """A proper low-poly bicycle standing along X: two wheels in the frame's plane, diamond frame, fenders,
    saddle, handlebars, pedals and a front basket."""
    rnd = random.Random(seed); o = Obj()
    R = 1.15; hub = (0.0, R, 0.0)
    wheels = {"rear": -1.55, "front": 1.55}
    wt = []; ft = []
    def ring_xy(cx, cy, r, z, n):
        return [(cx + r * math.cos(2 * math.pi * i / n), cy + r * math.sin(2 * math.pi * i / n), z) for i in range(n)]
    for wx in wheels.values():
        n = 14
        oa, ob = ring_xy(wx, R, R, -0.1, n), ring_xy(wx, R, R, 0.1, n)
        ia, ib = ring_xy(wx, R, R - 0.22, -0.1, n), ring_xy(wx, R, R - 0.22, 0.1, n)
        for i in range(n):
            j = (i + 1) % n
            wt += [(oa[i], oa[j], ob[j]), (oa[i], ob[j], ob[i]),          # tread
                   (ia[i], ib[j], ia[j]), (ia[i], ib[i], ib[j]),          # inner
                   (oa[i], ia[j], oa[j]), (oa[i], ia[i], ia[j]),          # side a
                   (ob[i], ob[j], ib[j]), (ob[i], ib[j], ib[i])]          # side b
        # hub (spokes are added below once bar() exists)
        box(o, "Frame", (wx, R, 0), 0.3, 0.3, 0.3, tris_out=ft)
        # fender: a curved strip following the top of the wheel
        r1, r2, w = R + 0.08, R + 0.2, 0.19
        segs = 9
        def P(r, a, z): return (wx + r * math.cos(a), R + r * math.sin(a), z)
        for k in range(segs):
            a0 = math.pi * (0.12 + 0.76 * k / segs); a1 = math.pi * (0.12 + 0.76 * (k + 1) / segs)
            A, B, C, D = P(r1, a0, -w), P(r2, a0, -w), P(r2, a1, -w), P(r1, a1, -w)
            E, Fq, G, H = P(r1, a0, w), P(r2, a0, w), P(r2, a1, w), P(r1, a1, w)
            ft += [(A, B, C), (A, C, D), (E, G, Fq), (E, H, G),        # sides
                   (B, Fq, G), (B, G, C)]                              # outer surface
            if k == 0: ft += [(A, E, Fq), (A, Fq, B)]
            if k == segs - 1: ft += [(D, C, G), (D, G, H)]
    o.add_flat("Wheel", wt)
    def bar(p0, p1, r=0.09):
        d = (p1[0] - p0[0], p1[1] - p0[1], p1[2] - p0[2])
        rings_ = [F.ring_dir(p0, d, r, 6, rnd), F.ring_dir(p1, d, r, 6, rnd)]
        tube(o, "Frame", rings_, p0, tris_out=ft, cap_bottom=True, cap_top=True)
    rear, front = wheels["rear"], wheels["front"]
    for wx in wheels.values():                                # spokes: three bars through the hub
        for k in range(3):
            a = math.pi * k / 3
            bar((wx - (R - 0.25) * math.cos(a), R - (R - 0.25) * math.sin(a), 0), (wx + (R - 0.25) * math.cos(a), R + (R - 0.25) * math.sin(a), 0), 0.05)
    bb = (-0.35, 0.95, 0)          # bottom bracket (pedals)
    seat = (-0.75, 2.75, 0)        # seat post top
    head = (0.95, 2.55, 0)         # head tube top
    fork = (front, R, 0)
    bar((rear, R, 0), bb); bar((rear, R, 0), seat)          # chain stay, seat stay
    bar(bb, seat); bar(bb, head)                              # seat tube, down tube
    bar(seat, head)                                           # top tube
    bar(head, fork)                                           # fork
    bar(head, (1.05, 3.1, 0))                                 # stem
    box(o, "Frame", (1.05, 3.12, 0), 0.12, 0.12, 1.7, tris_out=ft)          # handlebar
    box(o, "Frame", (1.05, 3.12, 0.85), 0.12, 0.14, 0.3, tris_out=ft)       # grips
    box(o, "Frame", (1.05, 3.12, -0.85), 0.12, 0.14, 0.3, tris_out=ft)
    box(o, "Frame", (bb[0], bb[1], 0), 0.34, 0.34, 0.2, tris_out=ft)          # crank housing
    box(o, "Frame", (bb[0] + 0.35, bb[1] - 0.25, 0.42), 0.5, 0.08, 0.32, tris_out=ft)   # pedals
    box(o, "Frame", (bb[0] - 0.35, bb[1] + 0.25, -0.42), 0.5, 0.08, 0.32, tris_out=ft)
    box(o, "Frame", (-0.75, 2.85, 0), 0.9, 0.18, 0.5, tris_out=ft)           # saddle
    o.add_flat("Frame", ft)
    # basket on the front
    bt = []
    box(o, "Bench", (1.75, 2.95, 0), 0.9, 0.1, 1.0, tris_out=bt)              # basket floor (wicker colour = Bench)
    box(o, "Bench", (1.3, 3.3, 0), 0.08, 0.6, 1.0, tris_out=bt)
    box(o, "Bench", (2.2, 3.3, 0), 0.08, 0.6, 1.0, tris_out=bt)
    box(o, "Bench", (1.75, 3.3, 0.5), 0.9, 0.6, 0.08, tris_out=bt)
    box(o, "Bench", (1.75, 3.3, -0.5), 0.9, 0.6, 0.08, tris_out=bt)
    o.add_flat("Bench", bt)
    return o.write(OUT / f"{name}.obj")

def bridge(name, seed, L=30.0, W=8.0):
    """Arched wooden footbridge along X, deck rises to +2.2 in the middle, railings both sides. Ends at y = 0."""
    rnd = random.Random(seed); o = Obj()
    n = 12
    def y_at(t): return 2.2 * math.sin(math.pi * t)
    pt = []
    for i in range(n):
        t0, t1 = i / n, (i + 1) / n
        x0, x1 = -L / 2 + L * t0, -L / 2 + L * t1
        y0, y1 = y_at(t0), y_at(t1)
        for zz in (-W / 2, W / 2):
            pass
        A = (x0, y0, -W / 2); B = (x1, y1, -W / 2); C = (x1, y1, W / 2); D = (x0, y0, W / 2)
        A2 = (x0, y0 - 0.5, -W / 2); B2 = (x1, y1 - 0.5, -W / 2); C2 = (x1, y1 - 0.5, W / 2); D2 = (x0, y0 - 0.5, W / 2)
        pt += [(A, C, B), (A, D, C), (A2, B2, C2), (A2, C2, D2), (A, B, B2), (A, B2, A2), (D, C2, C), (D, D2, C2)]
    o.add_flat("Plank", pt)
    rt = []
    for zz in (-W / 2 + 0.3, W / 2 - 0.3):
        for i in range(n + 1):
            t = i / n; x = -L / 2 + L * t; y = y_at(t)
            box(o, "Rail", (x, y + 1.6, zz), 0.25, 3.2, 0.25, tris_out=rt)
        for i in range(n):
            t0, t1 = i / n, (i + 1) / n
            x0, x1 = -L / 2 + L * t0, -L / 2 + L * t1
            y0, y1 = y_at(t0) + 3.1, y_at(t1) + 3.1
            a, b = (x0, y0, zz), (x1, y1, zz)
            rt += [((a[0], a[1] + 0.15, a[2] - 0.2), (b[0], b[1] + 0.15, b[2] - 0.2), (b[0], b[1] + 0.15, b[2] + 0.2)),
                   ((a[0], a[1] + 0.15, a[2] - 0.2), (b[0], b[1] + 0.15, b[2] + 0.2), (a[0], a[1] + 0.15, a[2] + 0.2)),
                   ((a[0], a[1] - 0.15, a[2] - 0.2), (b[0], b[1] - 0.15, b[2] + 0.2), (b[0], b[1] - 0.15, b[2] - 0.2)),
                   ((a[0], a[1] - 0.15, a[2] - 0.2), (a[0], a[1] - 0.15, a[2] + 0.2), (b[0], b[1] - 0.15, b[2] + 0.2))]
    o.add_flat("Rail", rt)
    return o.write(OUT / f"{name}.obj")

def plane_tree(name, seed):
    """Tall trunk with a broad, slightly flat canopy, like the plane trees on a French square."""
    rnd = random.Random(seed); o = Obj()
    F.trunk(o, "Trunk", (0, 0, 0), 0.7, 0.45, 8.0, 7, rnd)
    tris = []
    for c, r in (((0, 10.0, 0), 4.2), ((2.6, 9.4, 1.0), 3.0), ((-2.4, 9.6, -1.4), 2.9), ((0.4, 11.4, -2.4), 2.6), ((-0.8, 11.0, 2.4), 2.5)):
        icoblob(o, "Canopy", c, r, rnd, 0.12, (1.2, 0.75, 1.2), tris_out=tris)
    o.add_flat("Canopy", tris)
    return o.write(OUT / f"{name}.obj")

def river(name, seed, L=1600.0, step=8.0):
    """A meandering river ribbon with sandy banks, flat, lying along Z with its straight part at z = 0 (the bridge).
    The shape is an EVEN function of z so it survives the importer's front/back mirror unchanged.
    Same constants as the Lua in make_village_scripts.py (riverAt)."""
    rnd = random.Random(seed); o = Obj()
    K = 2 * math.pi / 260.0
    def env(d):
        t = min(max((abs(d) - 50.0) / 120.0, 0.0), 1.0)
        return t * t * (3 - 2 * t)
    def centre(d):  return 45.0 * env(d) * math.cos(K * abs(d))
    def half(d):    return 9.0 + 3.5 * env(d) * math.cos(K * abs(d) + 1.7) + 1.5 * env(d)
    def bank(d, side): return 3.0 + 2.0 * abs(math.sin(0.031 * abs(d) + (0.0 if side < 0 else 1.3)))
    n = int(L / step)
    zs = [-L / 2 + i * step for i in range(n + 1)]
    W, BL, BR = [], [], []
    def quad(tris, a, b, c, d2):
        tris += [(a, b, c), (a, c, d2)]
    for i in range(n):
        z0, z1 = zs[i], zs[i + 1]
        c0, c1 = centre(z0), centre(z1); h0, h1 = half(z0), half(z1)
        y = 0.15
        quad(W, (c0 - h0, y, z0), (c0 + h0, y, z0), (c1 + h1, y, z1), (c1 - h1, y, z1))
        bl0, bl1 = bank(z0, -1), bank(z1, -1); br0, br1 = bank(z0, 1), bank(z1, 1)
        yb = 0.25
        quad(BL, (c0 - h0 - bl0, yb, z0), (c0 - h0 + 0.6, yb, z0), (c1 - h1 + 0.6, yb, z1), (c1 - h1 - bl1, yb, z1))
        quad(BR, (c0 + h0 - 0.6, yb, z0), (c0 + h0 + br0, yb, z0), (c1 + h1 + br1, yb, z1), (c1 + h1 - 0.6, yb, z1))
    # Roblox scales a mesh by its bounding box, so a zero-thickness sheet gets a broken vertical scale and loses
    # triangles. Give each layer a hidden underside well below the ground so every piece has real height.
    def with_bottom(tris, drop):
        out = list(tris)
        for a, b, c in tris:
            out.append(((a[0], a[1] - drop, a[2]), (c[0], c[1] - drop, c[2]), (b[0], b[1] - drop, b[2])))
        return out
    above, below = (0, 50, 0), (0, -50, 0)
    def add_layer(name_, tris, drop):
        tops = [(a, b, c) for a, b, c in tris]
        bots = [(a, c, b) for a, b, c in [((x[0], x[1] - drop, x[2]) for x in t) for t in tris]]
        o.add_flat(name_, tops, below)                       # tops face up
        o.add_flat(name_, [tuple(t) for t in bots], above)   # bottoms face down (hidden under the ground)
    add_layer("river__Water", W, 0.6)
    add_layer("river__BankL", BL, 0.7)
    add_layer("river__BankR", BR, 0.7)
    return o.write(OUT / f"{name}.obj")

if __name__ == "__main__":
    print("river", river("river", 21), "tris")
    counts = {}
    counts["townhouse_a"] = townhouse("townhouse_a", 1, 28.0, 3, "flat", "right", "arch", door_style="arched")
    counts["townhouse_b"] = townhouse("townhouse_b", 2, 22.0, 2, "pitched", "centre", "arch", flowers=True, door_style="double")
    counts["townhouse_c"] = townhouse("townhouse_c", 3, 34.0, 3, "flat", "left", "tall", door_style="panel")
    counts["townhouse_d"] = townhouse("townhouse_d", 4, 18.0, 3, "pitched", "left", "arch", door_style="arched", shutters=True)
    counts["townhouse_e"] = townhouse("townhouse_e", 5, 26.0, 2, "flat", "right", "tall", door_style="double")
    counts["pot"] = pot("pot", 15)
    counts["crates"] = crates("crates", 16)
    counts["disp_bakery"] = disp_bakery("disp_bakery", 21)
    counts["disp_dress"] = disp_dress("disp_dress", 22)
    counts["disp_shelves"] = disp_shelves("disp_shelves", 23)
    counts["disp_flowers"] = disp_flowers("disp_flowers", 24)
    counts["disp_cafe"] = disp_cafe("disp_cafe", 25)
    counts["disp_hats"] = disp_hats("disp_hats", 26)
    counts["disp_cheese"] = disp_cheese("disp_cheese", 27)
    counts["disp_chocolate"] = disp_chocolate("disp_chocolate", 28)
    counts["disp_grocery"] = disp_grocery("disp_grocery", 29)
    counts["disp_pharmacy"] = disp_pharmacy("disp_pharmacy", 30)
    counts["disp_post"] = disp_post("disp_post", 31)
    counts["disp_post_b"] = disp_post_b("disp_post_b", 32)
    counts["disp_bakery_b"] = disp_bakery_b("disp_bakery_b", 33)
    counts["chalkboard"] = chalkboard("chalkboard", 34)
    counts["cafe_table"] = cafe_table("cafe_table", 4)
    counts["parasol"] = parasol("parasol", 5)
    counts["lamp_post"] = lamp_post("lamp_post", 6)
    counts["planter"] = planter("planter", 7)
    counts["fountain"] = fountain("fountain", 8)
    counts["bollards"] = bollards("bollards", 9)
    counts["shop_sign"] = shop_sign("shop_sign", 10)
    counts["bench"] = bench("bench", 11)
    counts["bicycle"] = bicycle("bicycle", 12)
    counts["bridge"] = bridge("bridge", 13)
    counts["plane_tree"] = plane_tree("plane_tree", 14)
    for k, v in counts.items():
        print(f"{k:14s} {v:5d} tris")
