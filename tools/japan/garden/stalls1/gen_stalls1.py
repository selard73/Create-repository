"""Japan market stall goods kit (Oct 22 2026). Shannon: the Shaved ice stall "looks like dimsum or hotpot or grilled meat" -> real
kakigori goods; and "add another stall on the right of the shaved ice stall" -> a takoyaki stall (octopus balls: savoury, iconic,
and the game has an octopus). Blender meshes only, one mesh per colour (the installer colours them); words go on in Studio.
Local frame: x along the counter, y up, z toward the back; the customer side is -z. Base y 0 = the counter top (y 3.5 in the world).
  kakigori_a   hand-crank block-ice shaver (cream enamel on an iron base, ice cup + crank, catch bowl), an ice block on a steel
               tray, a wooden caddy of four syrup bottles (strawberry red, melon green, Blue Hawaii, lemon yellow)
  kakigori_b   a stack of glass bowls and three served kakigori: tall white mounds in flared glass bowls, syrup on top, a spoon
  kori_flag    the kakigori stall's 氷 flag on a pole (KG_FlagCloth: the 氷 + wave goes on in Studio); stands on the deck
  takoyaki_a   a takoyaki pan (6 x 4 dimples, golden balls, some sauced) on a gas burner, a turning pick, sauce + mayo squeeze
               bottles, a bonito-flake jar, a cup of bamboo picks
  takoyaki_b   three paper boats of six takoyaki each with sauce, mayo zigzag, nori and bonito; a nori shaker
Writes stalls1/out/japan_kit38_stalls1.fbx (Empties kakigori_a, kakigori_b, kori_flag, takoyaki_a, takoyaki_b), pieces.json, gen_log.txt."""
import bpy, bmesh, math, os, json, traceback
D = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(D, "out")
os.makedirs(OUT, exist_ok=True)
LOG = os.path.join(OUT, "gen_log.txt")
def log(m): open(LOG, "a", encoding="utf-8").write(str(m) + "\n"); print(m)
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
COL = {
    "KG_Iron": (0.16, 0.17, 0.18), "KG_Enamel": (0.93, 0.90, 0.82), "KG_Chrome": (0.78, 0.80, 0.82), "KG_Wood": (0.55, 0.40, 0.25),
    "KG_Tray": (0.70, 0.72, 0.74), "KG_Ice": (0.90, 0.96, 1.00), "KG_Glass": (0.85, 0.92, 0.96), "KG_Snow": (0.98, 0.98, 1.00),
    "KG_SyrupRed": (0.86, 0.12, 0.18), "KG_SyrupGreen": (0.30, 0.72, 0.25), "KG_SyrupBlue": (0.18, 0.55, 0.90), "KG_SyrupYellow": (0.98, 0.82, 0.20),
    "KG_Knob": (0.75, 0.15, 0.12), "KG_FlagPole": (0.25, 0.20, 0.16), "KG_FlagCloth": (0.16, 0.38, 0.75), "KG_CupStripe": (0.18, 0.45, 0.80),
    "KG_Cup": (0.96, 0.94, 0.88), "KG_Cookie": (0.78, 0.55, 0.28), "KG_Choco": (0.22, 0.12, 0.08), "KG_Pink": (0.95, 0.55, 0.65),
    "KG_Orange": (0.98, 0.55, 0.15), "KG_MiniStick": (0.85, 0.75, 0.55), "KG_MiniFlag1": (0.97, 0.97, 0.97), "KG_MiniFlag2": (0.97, 0.97, 0.97),
    "TK_IronDark": (0.20, 0.20, 0.21), "TK_Iron": (0.10, 0.10, 0.11), "TK_Ball": (0.86, 0.62, 0.28), "TK_Sauce": (0.30, 0.16, 0.08),
    "TK_Mayo": (0.98, 0.96, 0.88), "TK_Nori": (0.14, 0.28, 0.12), "TK_Bonito": (0.80, 0.62, 0.45), "TK_Paper": (0.95, 0.90, 0.78),
    "TK_Chrome": (0.78, 0.80, 0.82), "TK_SauceBottle": (0.35, 0.20, 0.10), "TK_MayoBottle": (0.96, 0.95, 0.90), "TK_RedCap": (0.80, 0.12, 0.10),
    "TK_YellowCap": (0.95, 0.75, 0.15), "TK_Glass": (0.85, 0.92, 0.96), "TK_Bamboo": (0.80, 0.70, 0.45), "TK_Pick": (0.88, 0.80, 0.60),
}
UV_STUDS = 6.0
def material(key):
    m = bpy.data.materials.get(key)
    if m: return m
    m = bpy.data.materials.new(key); m.use_nodes = True
    c = COL[key]; bs = m.node_tree.nodes["Principled BSDF"]
    bs.inputs["Base Color"].default_value = (lin(c[0]), lin(c[1]), lin(c[2]), 1); bs.inputs["Roughness"].default_value = 0.6
    m.diffuse_color = (lin(c[0]), lin(c[1]), lin(c[2]), 1)
    return m
def P(x, y, z): return (x, -z, y)
BMS = {}
def bm_for(key):
    if key not in BMS: BMS[key] = bmesh.new()
    return BMS[key]
def hull(key, pts):
    bm = bm_for(key)
    vs = [bm.verts.new(P(*p)) for p in pts]
    bmesh.ops.convex_hull(bm, input=vs)
def box(key, x0, x1, y0, y1, z0, z1): hull(key, [(x, y, z) for x in (x0, x1) for y in (y0, y1) for z in (z0, z1)])
def cbox(key, x0, x1, y0, y1, z0, z1, c):
    pts = []
    for (ax, ay, az) in ((c, 0, c), (0, c, c), (c, c, 0)):
        pts += [(x, y, z) for x in (x0 + ax, x1 - ax) for y in (y0 + ay, y1 - ay) for z in (z0 + az, z1 - az)]
    hull(key, pts)
def ring(cx, cz, rx, rz, y, seg): return [(cx + rx * math.cos(2 * math.pi * i / seg), y, cz + rz * math.sin(2 * math.pi * i / seg)) for i in range(seg)]
def frustum(key, cx, cz, r0, y0, r1, y1, seg=16, rz0=None, rz1=None):
    hull(key, ring(cx, cz, r0, rz0 or r0, y0, seg) + ring(cx, cz, r1, rz1 or r1, y1, seg))
def cyl(key, cx, cz, r, y0, y1, seg=16): frustum(key, cx, cz, r, y0, r, y1, seg)
def sphere(key, cx, cy, cz, r, seg=10, rows=6):
    pts = []
    for j in range(1, rows):
        ph = math.pi * j / rows
        pts += ring(cx, cz, r * math.sin(ph), r * math.sin(ph), cy + r * math.cos(ph), seg)
    pts += [(cx, cy + r, cz), (cx, cy - r, cz)]
    hull(key, pts)
def dome(key, cx, cz, r, y0, h, seg=16, steps=5):                # a rounded mound: stacked frustums following a quarter-ellipse
    prev = None
    for k in range(steps + 1):
        t = k / steps
        rr = r * math.cos(t * math.pi / 2); yy = y0 + h * math.sin(t * math.pi / 2)
        if prev is not None: hull(key, ring(cx, cz, prev[0], prev[0], prev[1], seg) + ring(cx, cz, max(rr, 0.02), max(rr, 0.02), yy, seg))
        prev = (rr, yy)
def stick(key, a, b, t):                                          # a thin bar between two points (for picks, spoons, levers)
    pts = []
    for (x, y, z) in (a, b):
        pts += [(x + dx, y + dy, z + dz) for dx in (-t, t) for dy in (-t, t) for dz in (-t, t)]
    hull(key, pts)
def flush():
    objs = []
    for key, bm in BMS.items():
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0003)
        bm.normal_update()
        uv = bm.loops.layers.uv.new("UVMap")
        for f in bm.faces:
            n = f.normal; ax = max(range(3), key=lambda i: abs(n[i]))
            for l in f.loops:
                c = l.vert.co
                u, v = ((c.y, c.z), (c.x, c.z), (c.x, c.y))[ax]
                l[uv].uv = (u / UV_STUDS, v / UV_STUDS)
        me = bpy.data.meshes.new(key); bm.to_mesh(me); bm.free()
        o = bpy.data.objects.new(key, me); bpy.context.scene.collection.objects.link(o)
        me.materials.append(material(key))
        smooth = key in ("KG_Glass", "KG_Snow", "KG_Ice", "TK_Ball", "TK_Sauce", "TK_Glass", "KG_SyrupRed", "KG_SyrupGreen", "KG_SyrupBlue",
                         "KG_SyrupYellow", "KG_Orange", "KG_Cup", "KG_Choco", "KG_Pink", "KG_Cookie")
        for p in me.polygons: p.use_smooth = smooth
        objs.append(o)
    BMS.clear()
    return objs
def tris(o): return sum(len(p.vertices) - 2 for p in o.data.polygons)

# ------------------------------------------------------------ kakigori
def kakigori_a():
    # the shaver, centred x -1.6
    cbox("KG_Iron", -2.35, -0.85, 0.0, 0.14, -0.6, 0.6, 0.03)
    box("KG_Enamel", -1.85, -1.35, 0.14, 1.75, 0.18, 0.52)                 # the column at the back
    cbox("KG_Enamel", -2.25, -0.95, 1.75, 2.0, -0.35, 0.52, 0.04)          # the top arm
    cyl("KG_Chrome", -1.6, -0.05, 0.5, 1.0, 1.06, 18)                      # the blade plate
    cyl("KG_Iron", -1.6, -0.05, 0.42, 1.06, 1.75, 18)                      # the ice cup
    cyl("KG_Chrome", -1.6, -0.05, 0.1, 2.0, 2.12, 10)                      # the crank axle
    stick("KG_Chrome", (-1.6, 2.1, -0.05), (-0.95, 2.1, -0.05), 0.035)     # the crank lever
    cyl("KG_Knob", -0.95, -0.05, 0.075, 2.1, 2.42, 10)                     # its knob
    frustum("KG_Glass", -1.6, -0.05, 0.3, 0.14, 0.48, 0.62, 16)            # the catch bowl under the blade
    dome("KG_Snow", -1.6, -0.05, 0.4, 0.5, 0.35)                           # a little snow in it
    # the ice block on its tray, centred x 0.25
    cbox("KG_Tray", -0.45, 0.95, 0.0, 0.1, -0.55, 0.55, 0.02)
    cbox("KG_Ice", -0.35, 0.85, 0.1, 0.98, -0.42, 0.42, 0.07)
    stick("KG_Chrome", (0.5, 0.12, -0.5), (1.15, 0.12, -0.25), 0.03)      # ice tongs (two arms)
    stick("KG_Chrome", (0.5, 0.12, -0.5), (1.15, 0.12, -0.62), 0.03)
    # the syrup caddy, centred x 2.2
    cbox("KG_Wood", 1.35, 3.05, 0.0, 0.42, -0.42, 0.42, 0.03)
    for i, key in enumerate(("KG_SyrupRed", "KG_SyrupGreen", "KG_SyrupBlue", "KG_SyrupYellow")):
        x = 1.58 + i * 0.41
        cyl(key, x, 0.0, 0.165, 0.42, 1.2, 12)
        frustum(key, x, 0.0, 0.165, 1.2, 0.07, 1.36, 12)
        cyl(key, x, 0.0, 0.09, 1.36, 1.52, 10)                             # the pump head, in the syrup's colour (her photo)
        stick("KG_Chrome", (x, 1.5, 0.0), (x, 1.5, -0.2), 0.03)            # its spout
    cyl("KG_Cup", 1.12, -0.78, 0.16, 0.0, 0.45, 12)                        # a cup of straws and spoons
    for k, skey in enumerate(("KG_Pink", "KG_SyrupBlue", "KG_SyrupYellow", "KG_SyrupGreen", "KG_Pink", "KG_SyrupBlue", "KG_Chrome", "KG_Chrome")):
        a = 2 * math.pi * k / 8
        stick(skey, (1.12 + 0.07 * math.cos(a), 0.3, -0.78 + 0.07 * math.sin(a)), (1.12 + 0.14 * math.cos(a), 1.05, -0.78 + 0.14 * math.sin(a)), 0.016)
    return flush()
def ring_xy(cx, cy, z, r, seg): return [(cx + r * math.cos(2 * math.pi * i / seg), cy + r * math.sin(2 * math.pi * i / seg), z) for i in range(seg)]
def tray_and_cup(x, z):                                                    # Shannon's photo: a paper cup on a wooden tray, a spoon beside it
    cbox("KG_Wood", x - 0.8, x + 0.8, 0.0, 0.08, z - 0.62, z + 0.62, 0.03)
    frustum("KG_Cup", x - 0.15, z, 0.4, 0.08, 0.5, 0.62, 18)               # the cup, slightly left so the spoon fits
    for y0, y1 in ((0.2, 0.27), (0.4, 0.47)):                              # the blue stripes of the paper cup (her photo)
        r0 = 0.4 + 0.1 * (y0 - 0.08) / 0.54 + 0.012; r1 = 0.4 + 0.1 * (y1 - 0.08) / 0.54 + 0.012
        frustum("KG_CupStripe", x - 0.15, z, r0, y0, r1, y1, 18)
    hull("KG_Chrome", ring(x + 0.55, z + 0.3, 0.13, 0.09, 0.09, 10) + ring(x + 0.55, z + 0.3, 0.1, 0.06, 0.13, 10))   # the spoon's bowl
    stick("KG_Chrome", (x + 0.55, 0.11, z + 0.2), (x + 0.62, 0.11, z - 0.5), 0.025)                                   # its handle
    return x - 0.15
def mound(x, z, bands):                                                    # the heap above the cup rim: bands of colour from the bottom up
    y = 0.6
    prof = [(0.52, 0.6), (0.52, 0.85), (0.5, 1.05), (0.46, 1.25), (0.4, 1.42)]
    for k in range(len(prof) - 1):
        key = bands[min(k, len(bands) - 1)]
        hull(key, ring(x, z, prof[k][0], prof[k][0], prof[k][1], 16) + ring(x, z, prof[k + 1][0], prof[k + 1][0], prof[k + 1][1], 16))
    dome(bands[-1], x, z, 0.4, 1.42, 0.42)
def mini_flag(x, z, key):                                                  # the little 氷 card on a stick, stuck in the top
    stick("KG_MiniStick", (x, 1.5, z), (x + 0.06, 2.25, z), 0.018)
    box(key, x + 0.04, x + 0.36, 1.95, 2.27, z - 0.012, z + 0.012)
def served_blue(x, z):
    cx = tray_and_cup(x, z)
    mound(cx, z, ["KG_SyrupBlue"])
    dome("KG_Snow", cx, z, 0.3, 1.5, 0.3)                                   # the white top where the syrup didn't reach
    mini_flag(cx, z, "KG_MiniFlag1")
def served_strawberry(x, z):
    cx = tray_and_cup(x, z)
    mound(cx, z, ["KG_SyrupRed"])
    dome("KG_Snow", cx, z, 0.24, 1.6, 0.26)                                 # a dollop of cream
    frustum("KG_SyrupRed", cx + 0.08, z - 0.06, 0.11, 1.8, 0.03, 2.02, 10)   # a strawberry on it
    mini_flag(cx - 0.14, z + 0.06, "KG_MiniFlag2")
def served_bear(x, z):                                                     # the rainbow bear: coloured bands, cookie ears, a cream face
    cx = tray_and_cup(x, z)
    mound(cx, z, ["KG_SyrupRed", "KG_Orange", "KG_SyrupYellow", "KG_SyrupGreen", "KG_SyrupBlue"])
    for sx in (-0.33, 0.33):
        hull("KG_Cookie", ring_xy(cx + sx, 1.66, z + 0.02, 0.17, 12) + ring_xy(cx + sx, 1.66, z + 0.1, 0.17, 12))
    sphere("KG_Snow", cx, 1.12, z - 0.32, 0.3)                              # the face
    for sx in (-0.12, 0.12): sphere("KG_Choco", cx + sx, 1.24, z - 0.58, 0.045, 8, 4)
    sphere("KG_SyrupRed", cx, 1.1, z - 0.61, 0.065, 8, 4)                   # the nose (a cherry)
    for sx in (-0.21, 0.21): sphere("KG_Pink", cx + sx, 1.06, z - 0.52, 0.04, 8, 4)
def kakigori_b():
    for k in range(5):                                                     # a stack of striped paper cups
        frustum("KG_Cup", -2.45, 0.0, 0.4, 0.1 * k, 0.5, 0.1 * k + 0.54, 18)
        frustum("KG_CupStripe", -2.45, 0.0, 0.472, 0.1 * k + 0.4, 0.485, 0.1 * k + 0.47, 18)
    served_blue(-1.05, -0.25)
    served_bear(0.55, 0.2)
    served_strawberry(2.1, -0.3)
    return flush()
def kori_flag():
    cbox("KG_FlagPole", -0.25, 0.25, 0.0, 0.12, -0.25, 0.25, 0.02)         # a small foot
    cyl("KG_FlagPole", 0.0, 0.0, 0.05, 0.0, 6.6, 10)
    stick("KG_FlagPole", (0.0, 6.42, 0.0), (1.25, 6.42, 0.0), 0.04)         # the crossbar
    box("KG_FlagCloth", 0.08, 1.2, 3.5, 6.35, -0.02, 0.02)
    return flush()

# ------------------------------------------------------------ takoyaki
def ball(x, y, z, r, sauced):
    sphere("TK_Ball", x, y, z, r)
    if sauced: dome("TK_Sauce", x, z, r * 0.75, y + r * 0.55, r * 0.35, 12, 3)
def takoyaki_a():
    cbox("TK_IronDark", -2.95, -0.05, 0.0, 0.32, -0.95, 0.95, 0.04)         # the gas burner
    box("TK_Chrome", -1.65, -1.35, 0.1, 0.24, -1.03, -0.95)                 # its knob
    cbox("TK_Iron", -2.85, -0.15, 0.32, 0.58, -0.85, 0.85, 0.03)            # the pan
    for i in range(6):
        for j in range(4):
            x = -2.62 + i * 0.47; z = -0.62 + j * 0.41
            ball(x, 0.58, z, 0.19, (i + j) % 3 == 0)
    stick("TK_Chrome", (-2.9, 0.62, 0.9), (-1.7, 0.62, 1.0), 0.025)         # the turning pick
    for x, body, cap in ((0.85, "TK_SauceBottle", "TK_RedCap"), (1.45, "TK_MayoBottle", "TK_YellowCap")):
        cyl(body, x, 0.25, 0.17, 0.0, 0.95, 12)
        frustum(cap, x, 0.25, 0.17, 0.95, 0.05, 1.28, 12)
    cyl("TK_Glass", 2.45, 0.3, 0.32, 0.0, 0.72, 16)                          # the bonito jar
    cyl("TK_Bonito", 2.45, 0.3, 0.27, 0.03, 0.6, 12)
    cyl("TK_Chrome", 2.45, 0.3, 0.33, 0.72, 0.82, 16)
    cyl("TK_Bamboo", 2.4, -0.65, 0.16, 0.0, 0.46, 12)                        # the pick cup
    for k in range(7):
        a = 2 * math.pi * k / 7
        stick("TK_Pick", (2.4 + 0.08 * math.cos(a), 0.3, -0.65 + 0.08 * math.sin(a)), (2.4 + 0.13 * math.cos(a), 0.95, -0.65 + 0.13 * math.sin(a)), 0.014)
    return flush()
def boat(x, z):
    hull("TK_Paper", ring(x, z, 0.55, 0.36, 0.0, 12) + ring(x, z, 0.78, 0.52, 0.24, 12))
    for i in range(3):
        for j in range(2):
            bx = x - 0.27 + i * 0.27; bz = z - 0.14 + j * 0.28
            ball(bx, 0.3, bz, 0.16, True)
    for k in range(4):                                                     # the mayo zigzag
        stick("TK_Mayo", (x - 0.42 + k * 0.22, 0.52, z - 0.18 + (k % 2) * 0.3), (x - 0.2 + k * 0.22, 0.52, z + 0.12 - (k % 2) * 0.3), 0.022)
    for k in range(8):                                                     # nori + bonito flakes
        a = 2 * math.pi * k / 8 + 0.3
        key = "TK_Nori" if k % 2 == 0 else "TK_Bonito"
        cx, cz = x + 0.3 * math.cos(a), z + 0.17 * math.sin(a)
        box(key, cx - 0.06, cx + 0.06, 0.54, 0.565, cz - 0.035, cz + 0.035)
def takoyaki_b():
    boat(-2.0, -0.3)
    boat(-0.3, 0.3)
    boat(1.4, -0.25)
    cyl("TK_Glass", 2.55, 0.35, 0.15, 0.0, 0.62, 12)                         # the nori shaker
    cyl("TK_Nori", 2.55, 0.35, 0.12, 0.03, 0.5, 10)
    cyl("TK_Chrome", 2.55, 0.35, 0.155, 0.62, 0.72, 12)
    return flush()

def export(objs, path):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, axis_forward="-Z", axis_up="Y", apply_scale_options="FBX_SCALE_ALL",
                             add_leaf_bones=False, bake_space_transform=True, object_types={"EMPTY", "MESH"})
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    pieces = {"kakigori_a": kakigori_a(), "kakigori_b": kakigori_b(), "kori_flag": kori_flag(), "takoyaki_a": takoyaki_a(), "takoyaki_b": takoyaki_b()}
    def rb(p): return [round(p[0], 3), round(p[2], 3), round(-p[1], 3)]
    info = {}
    for name, objs in pieces.items():
        q = [rb(o.matrix_world @ v.co) for o in objs for v in o.data.vertices]
        info[name] = {"min": [min(a[i] for a in q) for i in range(3)], "max": [max(a[i] for a in q) for i in range(3)], "parts": {o.name: tris(o) for o in objs}}
        big = max(objs, key=tris)
        log(f"{name}: {len(objs)} meshes, {sum(tris(o) for o in objs)} tris (largest {big.name} {tris(big)})")
    json.dump(info, open(os.path.join(OUT, "pieces.json"), "w"), indent=1)
    log("INFO " + json.dumps({k: {"min": v["min"], "max": v["max"]} for k, v in info.items()}))
    allobjs = []
    x = 0.0
    for name, objs in pieces.items():
        emp = bpy.data.objects.new(name, None); bpy.context.scene.collection.objects.link(emp)
        for o in objs:
            mw = o.matrix_world.copy(); o.parent = emp; o.matrix_world = mw
        emp.location.x = x; x += 10.0
        allobjs += [emp] + objs
    export(allobjs, os.path.join(OUT, "japan_kit38_stalls2.fbx"))         # v2: served kakigori remade to Shannon's photo (cups, trays, flags, the bear)
    log("FBX_DONE")
except Exception:
    log(traceback.format_exc()); log("FBX_FAILED")
