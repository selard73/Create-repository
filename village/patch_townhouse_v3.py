"""Rebuild townhouse() at human scale (Roblox character = 5 studs) in the look of Shannon's low-poly
reference: pastel shop-houses, arched windows with cream surrounds, shop fronts with display windows,
a sign board and a striped awning, cornices and a flat parapet roof (one pitched with dormers)."""
from pathlib import Path
p = Path(__file__).parent / "gen_village.py"
s = p.read_text(encoding="utf-8")
start = s.index("def townhouse(")
end_ = s.index("def cafe_table(name, seed):")
new = r'''# ---- extrusion helpers -------------------------------------------------------------------------
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

def townhouse(name, seed, width, floors, roof="flat", door="centre", upper="arch", flowers=False):
    """Pastel French shop-house at Roblox human scale (doors 7 studs, floors 9-11 studs).
    Front faces -Z, stands on y = 0.  Pieces: Wall, Trim (cream stone), Window (glass), Shopfront (painted
    frame), DoorShop (the shop door, for the builder to find), Sign (board), Awning / AwningStripe, Shutter,
    Iron (railings), Roof, Chimney, Door (back door), Planter / Flower (window boxes)."""
    rnd = random.Random(seed); o = Obj()
    H = GF + (floors - 1) * UF
    zf, zb = -DEPTH / 2, DEPTH / 2
    xl, xr = -width / 2, width / 2
    box(o, "Wall", (0, H / 2, 0), width, H, DEPTH)
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
            window("front", x, y0, upper, shutters=(upper == "tall"), railing=(upper == "tall"), flowerbox=flowers)
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
    dwid = 3.6
    if door == "left":    dx0 = x0
    elif door == "right": dx0 = x1 - dwid
    else:                 dx0 = -dwid / 2
    door_x = dx0 + dwid / 2
    bays = []
    if dx0 > x0 + 0.5: bays.append((x0, dx0, "glass"))
    bays.append((dx0, dx0 + dwid, "door"))
    if dx0 + dwid < x1 - 0.5: bays.append((dx0 + dwid, x1, "glass"))
    for (a, b, kind) in bays:
        if kind == "glass":
            box(o, "Shopfront", ((a + b) / 2, riser / 2, zf - 0.3), b - a, riser, 0.6, tris_out=sf)          # stall riser
            box(o, "Window", ((a + b) / 2, riser + hw / 2, zf - 0.02), b - a, hw, 0.2, tris_out=wt)
            nsub = max(1, int(round((b - a) / 5.5)))
            for k in range(1, nsub):
                box(o, "Shopfront", (a + (b - a) * k / nsub, riser + hw / 2, zf - 0.2), 0.3, hw, 0.4, tris_out=sf)
            box(o, "Shopfront", ((a + b) / 2, riser + hw + 0.0, zf - 0.2), b - a, 0.3, 0.4, tris_out=sf)      # head rail
        else:
            dh = 7.0
            box(o, "DoorShop", ((a + b) / 2, dh / 2, zf - 0.22), dwid, dh, 0.44)                              # door leaf
            box(o, "Window", ((a + b) / 2, dh * 0.62, zf - 0.5), dwid - 1.2, dh * 0.5, 0.12, tris_out=wt)   # door glass
            box(o, "Trim", ((a + b) / 2 + dwid * 0.34, dh * 0.45, zf - 0.55), 0.3, 0.3, 0.3, tris_out=tt)  # knob
            box(o, "Window", ((a + b) / 2, dh + (bay_top - dh) / 2, zf - 0.02), dwid, bay_top - dh, 0.2, tris_out=wt)   # transom
            box(o, "Shopfront", ((a + b) / 2, dh + 0.1, zf - 0.2), dwid, 0.3, 0.4, tris_out=sf)
        box(o, "Shopfront", (b, gtop / 2 - fasc / 2, zf - 0.25), 0.5, gtop - fasc, 0.5, tris_out=sf)        # post between bays
    for sgn in (-1, 1):
        box(o, "Shopfront", (sgn * (fw / 2 - 1.1), gtop / 2 - fasc / 2, zf - 0.25), 0.5, gtop - fasc, 0.5, tris_out=sf)
    o.add_flat("Shopfront", sf)
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
        extrude(o, "Wall", [(zb, H), (zf, H), (0, H + rh)], "x", xl, xr, tris_out=gw)
        o.add_flat("Wall", gw)
        # dormers on the front slope
        for x in (xs[:2] if nwin <= 2 else [xs[0], xs[-1]]):
            dz0 = zf + 1.0
            box(o, "Wall", (x, H + 2.4, dz0 + 2.0), 3.8, 4.4, 4.0)
            dt = []
            thick_quad(dt, (x - 2.3, H + 4.5, dz0 - 0.5), (x, H + 6.6, dz0 - 0.5), (x, H + 6.6, dz0 + 4.5), (x - 2.3, H + 4.5, dz0 + 4.5), 0.3)
            thick_quad(dt, (x, H + 6.6, dz0 - 0.5), (x + 2.3, H + 4.5, dz0 - 0.5), (x + 2.3, H + 4.5, dz0 + 4.5), (x, H + 6.6, dz0 + 4.5), 0.3)
            o.add_flat("Roof", dt)
            extrude(o, "Wall", [(x - 1.9, H + 4.6), (x + 1.9, H + 4.6), (x, H + 6.5)], "z", dz0 - 0.2, dz0 + 3.5)
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

'''
s = s[:start] + new + s[end_:]
old_main = '''    counts["townhouse_a"] = townhouse("townhouse_a", 1, 14.0, 3, "pitched", True)
    counts["townhouse_b"] = townhouse("townhouse_b", 2, 12.0, 2, "pitched", True)
    counts["townhouse_c"] = townhouse("townhouse_c", 3, 16.0, 3, "flat", False)'''
assert old_main in s
s = s.replace(old_main, '''    counts["townhouse_a"] = townhouse("townhouse_a", 1, 28.0, 3, "flat", "right", "arch")
    counts["townhouse_b"] = townhouse("townhouse_b", 2, 22.0, 2, "pitched", "centre", "arch", flowers=True)
    counts["townhouse_c"] = townhouse("townhouse_c", 3, 34.0, 3, "flat", "left", "tall")
    counts["pot"] = pot("pot", 15)
    counts["crates"] = crates("crates", 16)''')
old_k = '''    "Cobble": (0.66, 0.65, 0.63), "Curb": (0.80, 0.79, 0.76),
})'''
assert old_k in s
s = s.replace(old_k, '''    "Cobble": (0.66, 0.65, 0.63), "Curb": (0.80, 0.79, 0.76),
    "Shopfront": (0.45, 0.32, 0.26), "DoorShop": (0.45, 0.32, 0.26), "AwningStripe": (0.97, 0.96, 0.93), "Iron": (0.18, 0.18, 0.20),
    "Bread": (0.85, 0.62, 0.35),
})''')
# bistro-sized table top
s = s.replace("    r = 1.3\n    top = ring((0, 0, 0), r, 2.3, 10)", "    r = 1.1\n    top = ring((0, 0, 0), r, 2.3, 10)")
p.write_text(s, encoding="utf-8"); print("townhouse v3 written")
