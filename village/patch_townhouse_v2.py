from pathlib import Path
p = Path(__file__).parent / "gen_village.py"
s = p.read_text(encoding="utf-8")
start = s.index("def townhouse(name, seed, width, floors, roof=\"pitched\", awning=True):")
end_ = s.index("def cafe_table(name, seed):")
new = r'''def townhouse(name, seed, width, floors, roof="flat", shop=True):
    """French shop-house after the concept image: shop front with display windows and a sign board, striped
    awning, wrought-iron balcony along the first floor, stone cornices, flat parapet roof (or pitched),
    tall French windows with shutters. Front faces -Z; every prop stands on y = 0."""
    rnd = random.Random(seed); o = Obj()
    depth = 12.0; fh = 4.4; plinth = 0.5; H = plinth + floors * fh
    zf = -depth / 2                       # front wall plane
    box(o, "Wall", (0, H / 2, 0), width, H, depth)
    tt = []                               # stone trim (cornices, surrounds, parapet)
    box(o, "Trim", (0, plinth / 2, zf - 0.08), width + 0.1, plinth, 0.16, tris_out=tt)          # plinth
    for f in range(1, floors):                                                                   # floor cornices
        box(o, "Trim", (0, plinth + f * fh - 0.15, zf - 0.14), width + 0.2, 0.3, 0.28, tris_out=tt)
    # --- windows (all faces) ---
    wt = []; st = []
    def window(face, u, y, tall=True):
        h = 2.9 if tall else 2.2
        if face in ("front", "back"):
            z = zf if face == "front" else -zf
            out = -1 if face == "front" else 1
            box(o, "Window", (u, y, z + out * 0.06), 1.7, h, 0.12, tris_out=wt)
            box(o, "Trim", (u, y + 0.05, z + out * 0.04), 2.2, h + 0.5, 0.08, tris_out=tt)
            for sgn in (-1, 1):
                box(o, "Shutter", (u + sgn * 1.4, y, z + out * 0.12), 0.7, h, 0.16, tris_out=st)
        else:
            x = -width / 2 if face == "left" else width / 2
            out = -1 if face == "left" else 1
            box(o, "Window", (x + out * 0.06, y, u), 0.12, h, 1.7, tris_out=wt)
            box(o, "Trim", (x + out * 0.04, y + 0.05, u), 0.08, h + 0.5, 2.2, tris_out=tt)
            for sgn in (-1, 1):
                box(o, "Shutter", (x + out * 0.12, y, u + sgn * 1.4), 0.16, h, 0.7, tris_out=st)
    nwin = max(2, int(width // 4.5))
    short = floors == 2
    back_door_i = nwin // 2 if nwin % 2 == 1 else nwin // 2 - 1
    for f in range(1, floors):                                # upper floors, front
        y = plinth + f * fh + fh * 0.5
        for i in range(nwin):
            window("front", -width / 2 + width * (i + 0.5) / nwin, y)
    for f in range(floors):                                   # rear and sides
        y = plinth + f * fh + fh * 0.5
        if short:
            window("left", 0.0, y, tall=f > 0); window("right", 0.0, y, tall=f > 0)
            if f == 1:
                window("back", -width / 4, y); window("back", width / 4, y)
        else:
            for i in range(nwin):
                x = -width / 2 + width * (i + 0.5) / nwin
                if f == 0 and i == back_door_i:
                    pass
                elif (i + f) % 2 == 0:
                    window("back", x, y, tall=f > 0)
            if f > 0:
                for zz in (-depth / 4, depth / 4):
                    window("left", zz, y); window("right", zz, y)
    o.add_flat("Window", wt); o.add_flat("Shutter", st)
    # --- shop front on the ground floor ---
    gy0 = plinth; gtop = plinth + fh
    fw = width * 0.94
    sf = []
    box(o, "Shopfront", (0, gy0 + (fh - 0.9) / 2, zf - 0.12), fw, fh - 0.9, 0.24, tris_out=sf)   # dark frame band
    o.add_flat("Shopfront", sf)
    dw = []
    for sgn in (-1, 1):                                                                       # two display windows
        box(o, "Glass", (sgn * fw * 0.27, gy0 + 1.85, zf - 0.30), fw * 0.34, 2.7, 0.12, tris_out=dw)
    o.add_flat("Glass", dw)
    box(o, "Door", (0, gy0 + 1.6, zf - 0.30), 2.0, 3.2, 0.14)                                  # shop door (glass panel + frame)
    box(o, "Trim", (0, gy0 + 1.7, zf - 0.26), 2.5, 3.5, 0.1)
    box(o, "Sign", (0, gtop - 0.55, zf - 0.34), fw * 0.9, 0.95, 0.16)                           # sign board (text added in Studio)
    box(o, "Trim", (0, gtop - 0.05, zf - 0.2), fw + 0.3, 0.22, 0.4)                            # ledge over the shop
    # --- striped awning over the display windows ---
    aw_a, aw_b = [], []
    y0, y1 = gtop - 1.15, gtop - 1.9
    z0, z1 = zf - 0.2, zf - 2.6
    w = fw * 0.96; nstr = max(6, int(w // 1.0))
    sw = w / nstr
    for i in range(nstr):
        xa, xb = -w / 2 + i * sw, -w / 2 + (i + 1) * sw
        tris = aw_a if i % 2 == 0 else aw_b
        A, B, C, D = (xa, y0, z0), (xb, y0, z0), (xb, y1, z1), (xa, y1, z1)
        tris += [(A, C, B), (A, D, C), (A, B, C), (A, C, D)]                                    # both sides visible
        xm = (xa + xb) / 2
        tris += [((xa, y1, z1), (xb, y1, z1), (xm, y1 - 0.45, z1)), ((xb, y1, z1), (xa, y1, z1), (xm, y1 - 0.45, z1))]
    o.add_flat("Awning", aw_a); o.add_flat("AwningStripe", aw_b)
    # --- wrought-iron balcony along the first floor ---
    ir = []
    by = plinth + fh                                                                            # balcony floor
    box(o, "Trim", (0, by + 0.1, zf - 0.55), width * 0.98, 0.22, 1.15, tris_out=tt)             # ledge
    nposts = int(width // 1.1)
    for i in range(nposts + 1):
        x = -width * 0.49 + width * 0.98 * i / nposts
        box(o, "Iron", (x, by + 0.75, zf - 1.05), 0.08, 1.2, 0.08, tris_out=ir)
    for yy in (by + 1.35, by + 0.95, by + 0.45):
        box(o, "Iron", (0, yy, zf - 1.05), width * 0.98, 0.07, 0.07, tris_out=ir)
    for sgn in (-1, 1):                                                                        # side returns
        box(o, "Iron", (sgn * width * 0.49, by + 0.95, zf - 0.55), 0.07, 0.07, 1.0, tris_out=ir)
        box(o, "Iron", (sgn * width * 0.49, by + 1.35, zf - 0.55), 0.07, 0.07, 1.0, tris_out=ir)
    # little scrolls: short diagonal-ish stubs between the middle and lower rails
    for i in range(nposts):
        x = -width * 0.49 + width * 0.98 * (i + 0.5) / nposts
        box(o, "Iron", (x, by + 0.7, zf - 1.05), 0.3, 0.06, 0.06, tris_out=ir)
        box(o, "Iron", (x, by + 0.7, zf - 1.05), 0.06, 0.3, 0.06, tris_out=ir)
    o.add_flat("Iron", ir)
    # --- roof ---
    if roof == "pitched":
        rh = 3.0; ov = 0.6
        A = (-width / 2 - ov, H, zf - ov); B = (width / 2 + ov, H, zf - ov)
        C = (width / 2 + ov, H, -zf + ov); D = (-width / 2 - ov, H, -zf + ov)
        E = (-width / 2 - ov, H + rh, 0); Fp = (width / 2 + ov, H + rh, 0)
        o.add_flat("Roof", [(A, B, Fp), (A, Fp, E), (C, D, E), (C, E, Fp), (A, E, D), (B, C, Fp)], (0, H + rh * 0.3, 0))
        box(o, "Chimney", (width * 0.3, H + rh * 0.9, 2.5), 1.4, 2.6, 1.4)
    else:
        box(o, "Trim", (0, H + 0.15, zf - 0.2), width + 0.5, 0.3, 0.6, tris_out=tt)             # cornice
        box(o, "Roof", (0, H + 0.35, 0), width + 0.3, 0.7, depth + 0.3)                         # parapet slab
        box(o, "Trim", (0, H + 1.0, zf - 0.05), width + 0.3, 0.6, 0.4, tris_out=tt)             # front parapet
        box(o, "Chimney", (-width * 0.3, H + 1.6, 3.0), 1.2, 1.8, 1.2)
    # back door at ground level with a step
    xb = 0.0 if short else -width / 2 + width * (back_door_i + 0.5) / nwin
    box(o, "Door", (xb, 1.5, -zf + 0.08), 1.8, 3.0, 0.16)
    box(o, "Trim", (xb, 1.6, -zf + 0.05), 2.3, 3.3, 0.1, tris_out=tt)
    box(o, "Trim", (xb, 0.2, -zf + 0.7), 2.8, 0.4, 1.3, tris_out=tt)
    o.add_flat("Trim", tt)
    return o.write(OUT / f"{name}.obj")

def pot(name, seed):
    """Terracotta pot with a round clipped shrub, like the ones by the shop doors."""
    rnd = random.Random(seed); o = Obj()
    tube(o, "Planter", [ring((0, 0, 0), 0.55, 0.0, 8), ring((0, 0, 0), 0.72, 1.0, 8), ring((0, 0, 0), 0.8, 1.15, 8), ring((0, 0, 0), 0.8, 1.3, 8)], (0, 0.6, 0), cap_bottom=True, cap_top=True)
    lt = []
    icoblob(o, "Leaf", (0, 2.05, 0), 0.85, rnd, 0.14, (1.0, 1.0, 1.0), tris_out=lt)
    o.add_flat("Leaf", lt)
    return o.write(OUT / f"{name}.obj")

'''
s = s[:start] + new + s[end_:]
s = s.replace('''    counts["townhouse_a"] = townhouse("townhouse_a", 1, 14.0, 3, "pitched", True)
    counts["townhouse_b"] = townhouse("townhouse_b", 2, 12.0, 2, "pitched", True)
    counts["townhouse_c"] = townhouse("townhouse_c", 3, 16.0, 3, "flat", False)''',
'''    counts["townhouse_a"] = townhouse("townhouse_a", 1, 14.0, 3, "flat")
    counts["townhouse_b"] = townhouse("townhouse_b", 2, 12.0, 2, "flat")
    counts["townhouse_c"] = townhouse("townhouse_c", 3, 16.0, 3, "pitched")
    counts["pot"] = pot("pot", 15)''')
s = s.replace('''    "Cobble": (0.66, 0.65, 0.63), "Curb": (0.80, 0.79, 0.76),
})''', '''    "Cobble": (0.66, 0.65, 0.63), "Curb": (0.80, 0.79, 0.76),
    "Shopfront": (0.30, 0.22, 0.18), "Glass": (0.70, 0.82, 0.88), "AwningStripe": (0.96, 0.95, 0.92), "Iron": (0.15, 0.15, 0.17),
})''')
p.write_text(s, encoding="utf-8"); print("townhouse v2 written")
