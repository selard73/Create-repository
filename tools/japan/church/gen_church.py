"""The CHURCH (Oct 16 2026). Shannon: "we need a church building somewhere on the map, because we will have one on every map, it needs to
blend in, but it will be a church ... please build what you describe" - the Goto-islands / Nagasaki style: white plaster walls with dark
timber framing on a grey stone plinth, a steep JAPANESE TILED roof with up-turned eaves, six arched windows with coloured glass, a
wooden double door up three stone steps, and a square bell tower at the front corner with louvred openings, a bronze bell and a cross.
Inside: a timber floor, ten pews, a chancel step, an altar with a cross, a lectern, candles, and the bell rope in the tower base.
In the France/Italy finish (faceted, flat colours; Studio gives the materials: plaster SmoothPlastic, timber Wood, roof Slate, glass
Glass + a soft light). Two FBX, one Model each: church_shell.fbx (everything structural), church_interior.fbx (the furnishings).
Blender axes: x across the nave (width 16), y along it (length 30; the FRONT with the door at -y = Roblox +z), z up. The floor inside
is at 0.9 (three steps up); the ground at 0. Mesh names = colour keys. pieces.json has the bboxes (Roblox axes) and the seat spots.
Run: blender -b --python gen_church.py"""
import bpy, bmesh, math, os, random, traceback, json
from mathutils import Vector
D = os.path.dirname(os.path.abspath(__file__))
OUT = os.environ.get("CHURCH_OUT") or os.path.join(D, "out")
os.makedirs(OUT, exist_ok=True)
LOG = os.path.join(OUT, "gen_log.txt")
def log(m): open(LOG, "a").write(str(m) + "\n"); print(m)
COL = {"Church_Plaster": (0.93, 0.91, 0.85), "Church_Timber": (0.24, 0.17, 0.12), "Church_Stone": (0.58, 0.57, 0.54), "Church_Roof": (0.30, 0.33, 0.38),
       "Church_Ridge": (0.24, 0.26, 0.30), "Church_Door_L": (0.40, 0.26, 0.15), "Church_Door_R": (0.40, 0.26, 0.15), "Church_Door_L_Trim": (0.24, 0.17, 0.12), "Church_Door_R_Trim": (0.24, 0.17, 0.12), "Church_Glass_Blue": (0.55, 0.72, 0.92), "Church_Glass_Gold": (0.95, 0.72, 0.30),
       "Church_Glass_Red": (0.80, 0.22, 0.24), "Church_Cross": (0.55, 0.42, 0.22), "Church_Bell": (0.62, 0.48, 0.24), "Church_Louvre": (0.30, 0.22, 0.15),
       "Church_Floor": (0.45, 0.31, 0.19), "Church_Pew": (0.46, 0.30, 0.17), "Church_Altar": (0.92, 0.90, 0.86), "Church_Cloth": (0.75, 0.16, 0.18),
       "Church_Candle": (0.97, 0.95, 0.88), "Church_Flame": (1.0, 0.80, 0.35), "Church_Rope": (0.72, 0.62, 0.45)}
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
def material(key):
    m = bpy.data.materials.get(key)
    if m: return m
    m = bpy.data.materials.new(key); m.use_nodes = True
    c = COL[key]; b = m.node_tree.nodes["Principled BSDF"]; b.inputs["Base Color"].default_value = (lin(c[0]), lin(c[1]), lin(c[2]), 1); b.inputs["Roughness"].default_value = 0.8
    if "Glass" in key: b.inputs["Roughness"].default_value = 0.2; m.blend_method = "BLEND" if hasattr(m, "blend_method") else m.blend_method; b.inputs["Alpha"].default_value = 0.55
    if key == "Church_Flame":
        try: b.inputs["Emission Color"].default_value = (1, 0.7, 0.3, 1); b.inputs["Emission Strength"].default_value = 6
        except Exception: pass
    return m
BMS = {}
def B(key):
    if key not in BMS: BMS[key] = bmesh.new()
    return BMS[key]
def box(bm, x0, x1, y0, y1, z0, z1):
    b = [bm.verts.new(v) for v in [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0)]]
    t = [bm.verts.new(v) for v in [(x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)]]
    for i in range(4):
        k = (i + 1) % 4; bm.faces.new([b[i], b[k], t[k], t[i]])
    bm.faces.new(list(reversed(b))); bm.faces.new(t)
def prism_x(bm, outline, x0, x1):
    """a polygon in the (y, z) plane extruded along x from x0 to x1 (outline counter-clockwise seen from +x)"""
    a = [bm.verts.new((x0, y, z)) for (y, z) in outline]; b = [bm.verts.new((x1, y, z)) for (y, z) in outline]
    n = len(outline)
    for i in range(n):
        k = (i + 1) % n; bm.faces.new([a[i], b[i], b[k], a[k]])
    fa = bm.faces.new(list(reversed(a))); fb = bm.faces.new(b)
    bmesh.ops.triangulate(bm, faces=[fa, fb])
def prism_y(bm, outline, y0, y1):
    """a polygon in the (x, z) plane extruded along y"""
    a = [bm.verts.new((x, y0, z)) for (x, z) in outline]; b = [bm.verts.new((x, y1, z)) for (x, z) in outline]
    n = len(outline)
    for i in range(n):
        k = (i + 1) % n; bm.faces.new([a[i], b[i], b[k], a[k]])
    fa = bm.faces.new(a); fb = bm.faces.new(list(reversed(b)))
    bmesh.ops.triangulate(bm, faces=[fa, fb])
def arch_outline(c, w, z_sill, z_spring, seg=10):
    """the window / door shape: a rectangle with a semicircular top; (y or x centre c, width w) -> counter-clockwise outline"""
    r = w / 2; pts = [(c - r, z_sill), (c + r, z_sill), (c + r, z_spring)]
    for i in range(1, seg):
        t = math.pi * i / seg; pts.append((c + r * math.cos(t), z_spring + r * math.sin(t)))
    pts.append((c - r, z_spring)); return pts
def header_outline(c, w, z_spring, z_top, margin, seg=10):
    """the wall piece above an arch: a rectangle (wider by margin each side) minus the semicircle"""
    r = w / 2; pts = [(c - r - margin, z_top), (c - r - margin, z_spring), (c - r, z_spring)]
    for i in range(1, seg):
        t = math.pi - math.pi * i / seg; pts.append((c + r * math.cos(t), z_spring + r * math.sin(t)))
    pts += [(c + r, z_spring), (c + r + margin, z_spring), (c + r + margin, z_top)]
    return list(reversed(pts))
# ---------- dimensions ----------
W, L = 16.0, 30.0            # the nave's outer width (x) and length (y); the front at y = -L/2
T = 0.6                      # wall thickness
FLOOR, EAVE, RIDGE = 0.9, 8.0, 12.2
PLINTH = 1.0
WIN_W, WIN_SILL, WIN_SPRING = 1.7, 2.6, 5.4   # arched windows: sill, the arch springs at 5.4, top at 6.25
WIN_Y = [-9.0, -3.0, 3.0]                       # three a side (the fourth bay at the back holds the chancel)
TOWER = 4.4                  # the bell tower's square, at the front-left corner, its outer corner at (-W/2, -L/2)
TOWER_H, TOWER_ROOF = 19.0, 22.6
def build_shell():
    pl, tb, st, rf, rg, dr, gb, gg, gr, cx, bl, lv = (B(k) for k in ("Church_Plaster", "Church_Timber", "Church_Stone", "Church_Roof", "Church_Ridge", "Church_Door_L",
                                                            "Church_Glass_Blue", "Church_Glass_Gold", "Church_Glass_Red", "Church_Cross", "Church_Bell", "Church_Louvre"))
    hw, hl = W / 2, L / 2
    # the stone plinth all round, and the floor slab inside
    box(st, -hw - 0.15, hw + 0.15, -hl - 0.15, hl + 0.15, 0.0, PLINTH)
    # SIDE WALLS (x = +-hw): piers between the windows, sills below, headers above (so the windows are real openings)
    for sx in (-1, 1):
        xo, xi = sx * hw, sx * (hw - T)
        x0, x1 = min(xo, xi), max(xo, xi)
        edges = [-hl] + [y for wy in WIN_Y for y in (wy - WIN_W / 2, wy + WIN_W / 2)] + [hl]
        for i in range(0, len(edges), 2):                                       # the piers
            box(pl, x0, x1, edges[i], edges[i + 1], PLINTH, EAVE)
        for wy in WIN_Y:
            box(pl, x0, x1, wy - WIN_W / 2, wy + WIN_W / 2, PLINTH, WIN_SILL)    # under the sill
            prism_x(pl, header_outline(wy, WIN_W, WIN_SPRING, EAVE, 0.0), x0, x1)   # the arched header
            box(st, x0 - 0.1 * sx if sx > 0 else x0, x1 + 0.1 if sx > 0 else x1 + 0.0, wy - WIN_W / 2 - 0.15, wy + WIN_W / 2 + 0.15, WIN_SILL - 0.18, WIN_SILL + 0.02)   # a stone sill
            # the glass: a blue field with a gold border and a red centre, in the wall's middle plane, 0.06 thick
            xm = sx * (hw - T / 2)
            prism_x(gg, arch_outline(wy, WIN_W - 0.1, WIN_SILL + 0.05, WIN_SPRING), xm - 0.03, xm + 0.03)
            prism_x(gb, arch_outline(wy, WIN_W - 0.5, WIN_SILL + 0.25, WIN_SPRING - 0.2), xm - 0.04, xm + 0.04)
            box(gr, xm - 0.05, xm + 0.05, wy - 0.22, wy + 0.22, WIN_SILL + 1.2, WIN_SILL + 1.9)
            box(tb, xm - 0.07, xm + 0.07, wy - 0.05, wy + 0.05, WIN_SILL, WIN_SPRING + WIN_W / 2)        # the mullion
            box(tb, xm - 0.07, xm + 0.07, wy - WIN_W / 2, wy + WIN_W / 2, WIN_SILL + 1.9, WIN_SILL + 2.0)  # the transom
        # timber framing on the outside face: corner posts, posts between bays, two rails
        for py in [-hl + 0.2, hl - 0.2] + [wy + s * (WIN_W / 2 + 0.35) for wy in WIN_Y for s in (-1, 1)]:
            box(tb, min(xo, xo + sx * 0.22), max(xo, xo + sx * 0.22), py - 0.17, py + 0.17, PLINTH, EAVE + 0.1)
        for z in (PLINTH + 1.3, EAVE - 0.5):
            box(tb, min(xo, xo + sx * 0.2), max(xo, xo + sx * 0.2), -hl, hl, z - 0.14, z + 0.14)
    # END WALLS (y = +-hl): gables up to the ridge; the front has the door, the back is plain
    for sy in (-1, 1):
        yo, yi = sy * hl, sy * (hl - T)
        y0, y1 = min(yo, yi), max(yo, yi)
        gable = [(-hw, PLINTH), (hw, PLINTH), (hw, EAVE), (0, RIDGE), (-hw, EAVE)]
        if sy < 0:
            # the front: the gable with the door opening (arched, 2.6 wide, springing at 3.6) - built as two piers + a header + the gable top
            dw, dspring = 2.6, FLOOR + 2.7
            box(pl, -hw, -dw / 2, y0, y1, PLINTH, EAVE); box(pl, dw / 2, hw, y0, y1, PLINTH, EAVE)
            prism_y(pl, header_outline(0, dw, dspring, EAVE, 0.0), y0, y1)
            prism_y(pl, [(-hw, EAVE), (hw, EAVE), (0, RIDGE)], y0, y1)
            # the double door, set 0.25 in, with plank grooves and a centre split; a rose window above the door
            # two leaves, each half the arch (the left leaf's outline is the arch's left half), 0.2 thick, set 0.25 into the opening
            r = (dw - 0.1) / 2
            left = [(-r, FLOOR), (0, FLOOR), (0, dspring + r)] + [(r * math.cos(math.pi / 2 + (math.pi / 2) * i / 6), dspring + r * math.sin(math.pi / 2 + (math.pi / 2) * i / 6)) for i in range(1, 7)]
            right = [(0, FLOOR), (r, FLOOR)] + [(r * math.cos((math.pi / 2) * i / 6), dspring + r * math.sin((math.pi / 2) * i / 6)) for i in range(0, 7)]
            prism_y(dr, left, yo + 0.25, yo + 0.45); prism_y(B("Church_Door_R"), right, yo + 0.25, yo + 0.45)
            for gx in (-0.9, -0.45, 0.45, 0.9):                                   # plank grooves on each leaf (dark strips)
                leaf = dr if gx < 0 else B("Church_Door_R")
                box(B("Church_Door_L_Trim") if gx < 0 else B("Church_Door_R_Trim"), gx - 0.02, gx + 0.02, yo + 0.22, yo + 0.26, FLOOR + 0.1, dspring + r * math.sqrt(max(0.0, 1 - (gx / r) ** 2)) - 0.1)
            box(tb, -dw / 2 - 0.2, -dw / 2, yo - 0.05, yo + 0.5, FLOOR, dspring); box(tb, dw / 2, dw / 2 + 0.2, yo - 0.05, yo + 0.5, FLOOR, dspring)
            # the rose window: a round opening above the door - glass disc with a gold rim and a red centre, and a timber cross
            cz = EAVE + 1.6
            ring = [(0.9 * math.cos(2 * math.pi * i / 16), cz + 0.9 * math.sin(2 * math.pi * i / 16)) for i in range(16)]
            prism_y(gg, ring, yo + 0.25, yo + 0.31)
            prism_y(gb, [(0.68 * math.cos(2 * math.pi * i / 16), cz + 0.68 * math.sin(2 * math.pi * i / 16)) for i in range(16)], yo + 0.24, yo + 0.32)
            prism_y(gr, [(0.25 * math.cos(2 * math.pi * i / 10), cz + 0.25 * math.sin(2 * math.pi * i / 10)) for i in range(10)], yo + 0.23, yo + 0.33)
            box(tb, -0.05, 0.05, yo + 0.2, yo + 0.36, cz - 0.9, cz + 0.9); box(tb, -0.9, 0.9, yo + 0.2, yo + 0.36, cz - 0.05, cz + 0.05)
            # three stone steps up to the door, 4.4 wide
            for i, (zt, depth) in enumerate(((0.3, 2.4), (0.6, 1.6), (0.9, 0.8))):
                box(st, -2.2, 2.2, yo - depth, yo + 0.1, 0.0, zt)
        else:
            prism_y(pl, gable, y0, y1)
        # timber: the gable's bargeboard line and corner posts
        for px in (-hw + 0.2, hw - 0.2):
            box(tb, px - 0.17, px + 0.17, min(yo, yo + sy * 0.22), max(yo, yo + sy * 0.22), PLINTH, EAVE + 0.1)
        box(tb, -hw, hw, min(yo, yo + sy * 0.2), max(yo, yo + sy * 0.2), PLINTH + 1.3 - 0.14, PLINTH + 1.3 + 0.14)
    # THE ROOF: two slopes from the ridge to the eaves, overhanging 1.3 at the sides and 1.0 at the ends, the lower part curving up
    # (the Japanese eave): built as 8 bands along the slope, each a thin slab; tile courses as small steps on each band
    ov_side, ov_end = 1.3, 1.0
    n = 8
    for sx in (-1, 1):
        # the slope profile from the ridge (x 0, z RIDGE + 0.25) to the eave edge (x +-(hw + ov_side), z EAVE - 0.35 + the up-turn)
        pts = []
        for i in range(n + 1):
            t = i / n
            x = sx * t * (hw + ov_side)
            z = RIDGE + 0.25 - t * (RIDGE + 0.25 - (EAVE - 0.35)) + 0.55 * max(0.0, t - 0.7) ** 2 / 0.09   # the eave turns up over the last 30 %
            pts.append((x, z))
        for (xa, za), (xb, zb) in zip(pts, pts[1:]):
            # a slab 0.35 thick between the two profile points, spanning the roof's length with the end overhang
            d = Vector((xb - xa, zb - za)).normalized(); nrm = Vector((-d.y, d.x)) * (0.35 if sx > 0 else -0.35)
            quad = [(xa, za), (xb, zb), (xb + nrm.x, zb + nrm.y), (xa + nrm.x, za + nrm.y)]
            if sx < 0: quad = list(reversed(quad))
            prism_y(rf, quad, -hl - ov_end, hl + ov_end)
            # tile courses: three thin rows per band on the upper face
            for k in range(3):
                tt = (k + 0.5) / 3
                cx_, cz_ = xa + (xb - xa) * tt, za + (zb - za) * tt
                up = Vector((-d.y, d.x)) * (-0.08 if sx > 0 else 0.08)
                quad2 = [(cx_ - d.x * 0.08, cz_ - d.y * 0.08), (cx_ + d.x * 0.08, cz_ + d.y * 0.08), (cx_ + d.x * 0.08 + up.x, cz_ + d.y * 0.08 + up.y), (cx_ - d.x * 0.08 + up.x, cz_ - d.y * 0.08 + up.y)]
                if sx < 0: quad2 = list(reversed(quad2))
                prism_y(rg, quad2, -hl - ov_end + 0.1, hl + ov_end - 0.1)
    box(rg, -0.55, 0.55, -hl - ov_end - 0.1, hl + ov_end + 0.1, RIDGE - 0.05, RIDGE + 0.75)             # the ridge cap
    for sy in (-1, 1):                                                                                  # ridge-end ornaments (onigawara-lite)
        box(rg, -0.7, 0.7, sy * (hl + ov_end) - 0.3, sy * (hl + ov_end) + 0.3, RIDGE - 0.1, RIDGE + 1.3)
    # THE BELL TOWER at the front-left corner: its outer corner at (-hw, -hl); a square shaft, louvred openings near the top, a
    # pyramidal tiled roof, a cross
    tx0, tx1 = -hw - 0.3, -hw - 0.3 + TOWER; ty0, ty1 = -hl - 0.3, -hl - 0.3 + TOWER   # 0.3 proud of the nave: no face shares a plane with the nave's walls
    box(st, tx0 - 0.15, tx1 + 0.15, ty0 - 0.15, ty1 + 0.15, 0.0, PLINTH)
    # the shaft: four walls (the inside is the bell chamber above 12, the rope room below)
    for (x0, x1, y0, y1) in ((tx0, tx0 + T, ty0, ty1), (tx1 - T, tx1, ty0, ty1), (tx0, tx1, ty0, ty0 + T), (tx0, tx1, ty1 - T, ty1)):
        box(pl, x0, x1, y0, y1, PLINTH, TOWER_H)
    # the louvred openings: cut as four openings 1.4 wide x 2.2 tall at 15.2..17.4 - simplified: louvre slats ON each face over a dark recess
    for face in ("w", "e", "s", "n"):
        for k in range(5):
            z = 15.3 + k * 0.45
            if face == "w": box(lv, tx0 - 0.08, tx0 + 0.12, ty0 + TOWER / 2 - 0.75, ty0 + TOWER / 2 + 0.75, z, z + 0.14)
            if face == "e": box(lv, tx1 - 0.12, tx1 + 0.08, ty0 + TOWER / 2 - 0.75, ty0 + TOWER / 2 + 0.75, z, z + 0.14)
            if face == "s": box(lv, tx0 + TOWER / 2 - 0.75, tx0 + TOWER / 2 + 0.75, ty0 - 0.08, ty0 + 0.12, z, z + 0.14)
            if face == "n": box(lv, tx0 + TOWER / 2 - 0.75, tx0 + TOWER / 2 + 0.75, ty1 - 0.12, ty1 + 0.08, z, z + 0.14)
        # the dark recess behind the slats (a timber-coloured panel set into the wall face)
        cxm, cym = tx0 + TOWER / 2, ty0 + TOWER / 2
        if face == "w": box(tb, tx0 + 0.05, tx0 + 0.15, cym - 0.8, cym + 0.8, 15.1, 17.7)
        if face == "e": box(tb, tx1 - 0.15, tx1 - 0.05, cym - 0.8, cym + 0.8, 15.1, 17.7)
        if face == "s": box(tb, cxm - 0.8, cxm + 0.8, ty0 + 0.05, ty0 + 0.15, 15.1, 17.7)
        if face == "n": box(tb, cxm - 0.8, cxm + 0.8, ty1 - 0.15, ty1 - 0.05, 15.1, 17.7)
    # timber corner posts and a rail band on the tower
    for (px, py) in ((tx0, ty0), (tx1, ty0), (tx0, ty1), (tx1, ty1)):
        box(tb, px - 0.2, px + 0.2, py - 0.2, py + 0.2, PLINTH, TOWER_H + 0.1)
    for z in (PLINTH + 1.3, 9.0, 14.6):
        for (x0, x1, y0, y1) in ((tx0 - 0.1, tx0 + 0.1, ty0 - 0.1, ty1 + 0.1), (tx1 - 0.1, tx1 + 0.1, ty0 - 0.1, ty1 + 0.1), (tx0, tx1, ty0 - 0.1, ty0 + 0.1), (tx0, tx1, ty1 - 0.1, ty1 + 0.1)):
            box(tb, x0, x1, y0, y1, z - 0.14, z + 0.14)
    # the tower roof: a pyramid of four slabs with up-turned eaves, overhanging 0.9, a ridge finial and the cross
    cxm, cym = tx0 + TOWER / 2, ty0 + TOWER / 2; half = TOWER / 2 + 0.9
    apex = (cxm, cym, TOWER_ROOF)
    corners = [(cxm - half, cym - half), (cxm + half, cym - half), (cxm + half, cym + half), (cxm - half, cym + half)]
    for i in range(4):
        a, b = corners[i], corners[(i + 1) % 4]
        va = rf.verts.new((a[0], a[1], TOWER_H - 0.3)); vb = rf.verts.new((b[0], b[1], TOWER_H - 0.3)); vt = rf.verts.new(apex)
        # a thick slab: the outer face and an inner face 0.3 lower
        va2 = rf.verts.new((a[0] * 0.98 + cxm * 0.02, a[1] * 0.98 + cym * 0.02, TOWER_H - 0.6)); vb2 = rf.verts.new((b[0] * 0.98 + cxm * 0.02, b[1] * 0.98 + cym * 0.02, TOWER_H - 0.6)); vt2 = rf.verts.new((cxm, cym, TOWER_ROOF - 0.3))
        rf.faces.new([va, vb, vt]); rf.faces.new([vb2, va2, vt2]); rf.faces.new([va, va2, vb2, vb])
        # the hip ridges
    box(rg, cxm - 0.4, cxm + 0.4, cym - 0.4, cym + 0.4, TOWER_ROOF - 0.5, TOWER_ROOF + 0.4)                    # the finial base
    # the cross: 2.2 tall, arms 1.3, on the finial
    box(cx, cxm - 0.12, cxm + 0.12, cym - 0.12, cym + 0.12, TOWER_ROOF + 0.3, TOWER_ROOF + 2.5)
    box(cx, cxm - 0.65, cxm + 0.65, cym - 0.12, cym + 0.12, TOWER_ROOF + 1.75, TOWER_ROOF + 1.99)
    # the bell inside the chamber (a profile of revolution), hung from a timber beam
    prof = [(0.12, 1.5), (0.35, 1.45), (0.5, 1.2), (0.62, 0.8), (0.72, 0.35), (0.86, 0.12), (0.9, 0.0), (0.84, -0.04), (0.6, 0.05), (0.5, 0.3), (0.42, 0.7), (0.3, 1.1), (0.1, 1.3)]
    seg = 14; rings = [[bl.verts.new((cxm + r * math.cos(2 * math.pi * i / seg), cym + r * math.sin(2 * math.pi * i / seg), 15.0 + z)) for i in range(seg)] for (r, z) in prof]
    for ra, rb in zip(rings, rings[1:]):
        for i in range(seg): bl.faces.new([ra[i], ra[(i + 1) % seg], rb[(i + 1) % seg], rb[i]])
    bl.faces.new(list(reversed(rings[0]))); bl.faces.new(rings[-1])
    box(tb, tx0 + T, tx1 - T, cym - 0.2, cym + 0.2, 16.6, 17.0)                                               # the beam
    box(bl, cxm - 0.08, cxm + 0.08, cym - 0.08, cym + 0.08, 16.45, 16.65)                                     # the hanger
    # the tower's doorway into the nave (an opening in the shared wall) is implied: the nave's front-left pier is there; a small arched
    # door on the tower's inner face toward the nave is drawn as a dark recess
    prism_x(tb, arch_outline(ty0 + TOWER / 2 + 0.6, 1.4, FLOOR, FLOOR + 2.0), tx1 - 0.15, tx1 - 0.05)
    names = ["Church_Plaster", "Church_Timber", "Church_Stone", "Church_Roof", "Church_Ridge", "Church_Door_L", "Church_Door_R", "Church_Door_L_Trim", "Church_Door_R_Trim", "Church_Glass_Blue", "Church_Glass_Gold", "Church_Glass_Red", "Church_Cross", "Church_Bell", "Church_Louvre"]
    return names
def build_interior():
    fl, pw, al, cl, cd, fm, rp, cx = (B(k) for k in ("Church_Floor", "Church_Pew", "Church_Altar", "Church_Cloth", "Church_Candle", "Church_Flame", "Church_Rope", "Church_Cross"))
    hw, hl = W / 2 - T, L / 2 - T
    box(fl, -hw, hw, -hl, hl, FLOOR - 0.12, FLOOR)                                 # the timber floor
    for gx in [x for x in range(-7, 8)]:                                            # plank joints as thin grooves
        box(fl, gx * 1.0 - 0.015, gx * 1.0 + 0.015, -hl, hl, FLOOR, FLOOR + 0.012)
    # the chancel: a step across the back 6.5 deep
    CH = hl - 6.5
    box(fl, -hw, hw, CH, hl, FLOOR, FLOOR + 0.3)
    # pews: two columns of five, a 2.4 aisle, each 5.2 wide, 2.0 deep (seat, back, two ends)
    seats = []
    for col in (-1, 1):
        cxp = col * (1.2 + 2.6)
        for row in range(5):
            y = -hl + 4.0 + row * 3.1
            box(pw, cxp - 2.6, cxp + 2.6, y - 0.25, y + 0.25, FLOOR, FLOOR + 0.9)              # the seat slab (0.5 deep) on the bench front
            box(pw, cxp - 2.6, cxp + 2.6, y - 0.2, y + 0.75, FLOOR + 0.42, FLOOR + 0.5)         # the seat
            box(pw, cxp - 2.6, cxp + 2.6, y + 0.72, y + 0.84, FLOOR + 0.5, FLOOR + 1.45)        # the back
            for ex in (cxp - 2.6, cxp + 2.5):
                box(pw, ex, ex + 0.1, y - 0.25, y + 0.86, FLOOR, FLOOR + 1.05)                  # the ends
            seats.append({"x": cxp, "y": FLOOR + 0.5, "z": -(y + 0.28), "w": 5.0})               # Roblox axes (z = -y): where a Seat part goes
    # the altar on the chancel: a stone table with a red runner, a standing cross, two candles
    ay = hl - 3.2
    box(al, -1.6, 1.6, ay - 0.6, ay + 0.6, FLOOR + 0.3, FLOOR + 1.5)
    box(cl, -0.45, 0.45, ay - 0.66, ay + 0.66, FLOOR + 1.5, FLOOR + 1.56)
    box(cx, -0.06, 0.06, ay - 0.06, ay + 0.06, FLOOR + 1.56, FLOOR + 2.7); box(cx, -0.4, 0.4, ay - 0.06, ay + 0.06, FLOOR + 2.25, FLOOR + 2.37)
    box(cx, -0.25, 0.25, ay - 0.25, ay + 0.25, FLOOR + 1.56, FLOOR + 1.64)
    for sx in (-1, 1):
        box(cd, sx * 1.1 - 0.07, sx * 1.1 + 0.07, ay - 0.07, ay + 0.07, FLOOR + 1.56, FLOOR + 2.1)
        f = bmesh.ops.create_icosphere(fm, subdivisions=1, radius=0.08)
        for v in f["verts"]: v.co.z *= 1.6; v.co += Vector((sx * 1.1, ay, FLOOR + 2.2))
    # the lectern at the chancel's front right, a tall candle stand each side of the chancel step
    lx, ly = 2.6, CH + 1.2
    box(pw, lx - 0.35, lx + 0.35, ly - 0.35, ly + 0.35, FLOOR + 0.3, FLOOR + 0.42); box(pw, lx - 0.12, lx + 0.12, ly - 0.12, ly + 0.12, FLOOR + 0.42, FLOOR + 1.45)
    prism_x(pw, [(ly - 0.45, FLOOR + 1.45), (ly + 0.25, FLOOR + 1.45), (ly + 0.25, FLOOR + 1.75), (ly - 0.45, FLOOR + 1.55)], lx - 0.5, lx + 0.5)
    for sx in (-1, 1):
        sxp = sx * 5.0
        box(cd, sxp - 0.08, sxp + 0.08, CH + 0.5 - 0.08, CH + 0.5 + 0.08, FLOOR + 0.3, FLOOR + 1.7)
        box(pw, sxp - 0.3, sxp + 0.3, CH + 0.2, CH + 0.8, FLOOR + 0.3, FLOOR + 0.4)
        f = bmesh.ops.create_icosphere(fm, subdivisions=1, radius=0.08)
        for v in f["verts"]: v.co.z *= 1.6; v.co += Vector((sxp, CH + 0.5, FLOOR + 1.8))
    # the bell rope in the tower's base (hangs from the chamber to 1.1 above the floor), with a knot
    cxm, cym = -W / 2 + TOWER / 2, -L / 2 + TOWER / 2
    seg = 6
    ra = [rp.verts.new((cxm + 0.05 * math.cos(2 * math.pi * i / seg), cym + 0.05 * math.sin(2 * math.pi * i / seg), FLOOR + 1.1)) for i in range(seg)]
    rb = [rp.verts.new((cxm + 0.05 * math.cos(2 * math.pi * i / seg), cym + 0.05 * math.sin(2 * math.pi * i / seg), 14.9)) for i in range(seg)]
    for i in range(seg): rp.faces.new([ra[i], ra[(i + 1) % seg], rb[(i + 1) % seg], rb[i]])
    rp.faces.new(list(reversed(ra))); rp.faces.new(rb)
    k = bmesh.ops.create_icosphere(rp, subdivisions=1, radius=0.14)
    for v in k["verts"]: v.co.z *= 1.4; v.co += Vector((cxm, cym, FLOOR + 1.2))
    return ["Church_Floor", "Church_Pew", "Church_Altar", "Church_Cloth", "Church_Candle", "Church_Flame", "Church_Rope", "Church_Cross"], seats, {"x": cxm, "y": FLOOR + 1.2, "z": -cym}
def finish(names, suffix):
    objs = []
    for n in names:
        bm = BMS.pop(n, None)
        if bm is None or len(bm.verts) == 0: continue
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
        me = bpy.data.meshes.new(n + suffix); bm.normal_update(); bm.to_mesh(me); bm.free()
        o = bpy.data.objects.new(n + suffix, me); bpy.context.scene.collection.objects.link(o); me.materials.append(material(n))
        for p in me.polygons: p.use_smooth = False
        objs.append(o)
    return objs
def tris(o): return sum(len(p.vertices) - 2 for p in o.data.polygons)
def export(objs, name):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.fbx(filepath=os.path.join(OUT, name + ".fbx"), use_selection=True, axis_forward="-Z", axis_up="Y",
                             apply_scale_options="FBX_SCALE_ALL", add_leaf_bones=False, bake_space_transform=True)
    log(f"{name}.fbx: {len(objs)} meshes, {sum(tris(o) for o in objs)} tris; " + ", ".join(f"{o.name} {tris(o)}" for o in objs))
def bbox(objs):
    pts = [o.matrix_world @ v.co for o in objs for v in o.data.vertices]
    rb = [(p.x, p.z, -p.y) for p in pts]
    return {"min": [round(min(q[i] for q in rb), 3) for i in range(3)], "max": [round(max(q[i] for q in rb), 3) for i in range(3)]}
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    shell = finish(build_shell(), "")
    inames, seats, rope = build_interior()
    # the interior's cross would clash with the shell's cross mesh name: suffix the interior meshes that share a key
    interior = finish(inames, "_In")
    for o in interior: o.name = o.name.replace("_In", "") if not o.name.startswith("Church_Cross") else "Church_Cross_Altar"
    export(shell, "church_shell"); export(interior, "church_interior")
    info = {"church_shell": bbox(shell), "church_interior": bbox(interior), "seats": seats, "bell_rope": rope,
            "door": {"x": 0, "y": FLOOR, "z": L / 2, "faces": "+z", "width": 2.5, "height": 3.6 + 1.25, "hinge_left_x": -1.25, "hinge_right_x": 1.25, "leaf_z": -(-L / 2 + 0.35)}, "tower_centre": {"x": -W / 2 + TOWER / 2, "z": L / 2 - TOWER / 2}, "floor_y": FLOOR}
    json.dump(info, open(os.path.join(OUT, "pieces.json"), "w"), indent=1); log("BBOX " + json.dumps({k: info[k] for k in ("church_shell", "church_interior")})); log("FBX_DONE")
    if os.environ.get("CHURCH_NO_RENDER"): raise SystemExit
    # previews: Cycles CPU - a three-quarter front view, the front, the interior toward the altar
    sc = bpy.context.scene
    def plane(name, size, loc, rgb, sx=1, sy=1):
        bpy.ops.mesh.primitive_plane_add(size=size, location=loc); p = bpy.context.active_object; p.name = name; p.scale = (sx, sy, 1)
        m = bpy.data.materials.new(name); m.use_nodes = True
        m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (lin(rgb[0]), lin(rgb[1]), lin(rgb[2]), 1)
        p.data.materials.append(m)
    plane("Lawn", 1, (0, 0, -0.01), (0.36, 0.62, 0.30), 120, 120)
    sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 32; sc.cycles.use_denoising = False
    sc.render.resolution_x, sc.render.resolution_y = 1100, 700
    sc.world = bpy.data.worlds.new("W"); sc.world.use_nodes = True
    bg = sc.world.node_tree.nodes["Background"]; bg.inputs["Color"].default_value = (lin(0.62), lin(0.80), lin(0.95), 1); bg.inputs["Strength"].default_value = 1.0
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")); sc.collection.objects.link(sun)
    sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(-120)); sun.data.energy = 3.0
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam; cam.data.lens = 30
    def shot(fn, loc, target, lens=30):
        cam.data.lens = lens; cam.location = Vector(loc); d = Vector(target) - cam.location
        cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(OUT, fn); bpy.ops.render.render(write_still=True); log(f"shot {fn}")
    shot("prev_church_front_quarter.png", (-34, -44, 12), (0, 0, 8))
    shot("prev_church_front.png", (4, -48, 7), (0, 0, 8))
    shot("prev_church_side.png", (46, 8, 10), (0, 0, 7))
    for o in shell:                                                            # the interior: hide the roof and the front wall side for the shot
        if o.name in ("Church_Roof", "Church_Ridge"): o.hide_render = True
    shot("prev_church_interior.png", (0, -13.5, 5.5), (0, 12, 3.2), 24)
    log("RENDER_DONE")
except SystemExit:
    pass
except Exception:
    log(traceback.format_exc())
