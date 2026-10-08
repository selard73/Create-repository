"""All Things Bella (Porto Nocciola, Oct 5 2026, Shannon): window-display props made from sea glass and shells.
Lamp (mosaic shade), Vase (sea glass + dried flowers), Box (shell keepsake box, lid open, pearl inside), Sun (sea-glass
suncatcher), Mirror (shell-framed, on an easel), Candle (mosaic holder), Neck (shell-and-pearl necklace on a velvet bust).
Studs, Z up, each prop centred on the origin with its bottom at z 0, front = -Y. One object per prop + material, named
<Prop>_<Material> (the Studio installer colours them by that name); asymmetric props carry a tiny <Prop>_Front marker on
their -Y side so the installer can turn them to face the street. Writes bella_props.fbx + preview renders.
Run: blender -b --python gen_bella.py"""
import bpy, bmesh, math, os, random, traceback
from mathutils import Vector, Matrix
D = os.path.dirname(os.path.abspath(__file__))
LOG = os.path.join(D, "gen_log.txt")
def log(m): open(LOG, "a").write(str(m) + "\n")
COL = {  # sRGB 0..1; the installer uses the same values in Studio
    "SGAqua": (0.55, 0.86, 0.82), "SGGreen": (0.56, 0.80, 0.56), "SGWhite": (0.90, 0.95, 0.94), "SGCobalt": (0.26, 0.46, 0.86),
    "SGAmber": (0.86, 0.62, 0.30), "ShellCream": (0.97, 0.91, 0.80), "ShellPink": (0.96, 0.75, 0.72), "ShellPeach": (0.98, 0.80, 0.62),
    "Brass": (0.80, 0.65, 0.35), "WoodLight": (0.80, 0.66, 0.48), "WoodWhite": (0.95, 0.94, 0.90), "Grout": (0.38, 0.40, 0.42),
    "Bulb": (1.0, 0.92, 0.70), "Pearl": (0.97, 0.96, 0.93), "Mirror": (0.80, 0.86, 0.90), "Velvet": (0.16, 0.36, 0.38),
    "Candle": (0.97, 0.94, 0.86), "Flame": (1.0, 0.70, 0.25), "String": (0.86, 0.83, 0.76), "Driftwood": (0.70, 0.62, 0.52),
    "Flower": (0.88, 0.80, 0.62), "Stem": (0.60, 0.53, 0.38), "Front": (1.0, 0.0, 1.0),
}
SG = ["SGAqua", "SGGreen", "SGWhite", "SGCobalt", "SGAmber"]
SGW = [0.36, 0.26, 0.24, 0.09, 0.05]
SHELLS = ["ShellCream", "ShellPink", "ShellPeach"]
R = random.Random(7)
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
def material(name):
    m = bpy.data.materials.get(name)
    if m: return m
    m = bpy.data.materials.new(name); m.use_nodes = True
    c = COL[name]; b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (lin(c[0]), lin(c[1]), lin(c[2]), 1)
    b.inputs["Roughness"].default_value = 0.25 if name.startswith("SG") or name in ("Mirror", "Pearl") else 0.6
    if name in ("Bulb", "Flame"):
        b.inputs["Emission Color"].default_value = (lin(c[0]), lin(c[1]), lin(c[2]), 1); b.inputs["Emission Strength"].default_value = 4.0
    m.diffuse_color = (lin(c[0]), lin(c[1]), lin(c[2]), 1)
    return m

class Prop:
    """collects bmeshes per material for one prop"""
    def __init__(self, name): self.name = name; self.bms = {}
    def bm(self, mat):
        if mat not in self.bms: self.bms[mat] = bmesh.new()
        return self.bms[mat]
    def build(self):
        objs = []
        for mat, bm in self.bms.items():
            n = f"{self.name}_{mat}"
            me = bpy.data.meshes.new(n); bm.normal_update(); bm.to_mesh(me); bm.free()
            o = bpy.data.objects.new(n, me); bpy.context.scene.collection.objects.link(o); me.materials.append(material(mat))
            objs.append(o)
        return objs

def frame(z):
    z = Vector(z).normalized(); a = Vector((0, 0, 1)) if abs(z.z) < 0.9 else Vector((1, 0, 0))
    x = a.cross(z).normalized(); return x, z.cross(x), z
def cyl(bm, p1, p2, r, seg=10, r2=None):
    p1, p2 = Vector(p1), Vector(p2); x, y, z = frame(p2 - p1); r2 = r if r2 is None else r2
    a = [bm.verts.new(p1 + (x * math.cos(2 * math.pi * i / seg) + y * math.sin(2 * math.pi * i / seg)) * r) for i in range(seg)]
    b = [bm.verts.new(p2 + (x * math.cos(2 * math.pi * i / seg) + y * math.sin(2 * math.pi * i / seg)) * r2) for i in range(seg)]
    for i in range(seg):
        j = (i + 1) % seg; bm.faces.new([a[i], a[j], b[j], b[i]])
    bm.faces.new(list(reversed(a))); bm.faces.new(b)
def boxc(bm, c, s, rot=None):
    """axis box centred at c with size s, optionally rotated by matrix rot about c"""
    c = Vector(c); vs = []
    for sx, sy, sz in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]:
        v = Vector((sx * s[0] / 2, sy * s[1] / 2, sz * s[2] / 2))
        if rot: v = rot @ v
        vs.append(bm.verts.new(c + v))
    for f in [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]: bm.faces.new([vs[i] for i in f])
def lathe(bm, prof, seg=20):
    rings = []
    for r, z in prof:
        if r < 1e-4: rings.append([bm.verts.new((0, 0, z))])
        else: rings.append([bm.verts.new((r * math.cos(2 * math.pi * i / seg), r * math.sin(2 * math.pi * i / seg), z)) for i in range(seg)])
    for a, b in zip(rings, rings[1:]):
        for i in range(seg):
            j = (i + 1) % seg
            if len(a) == 1 and len(b) == 1: continue
            if len(a) == 1: bm.faces.new([a[0], b[j], b[i]])
            elif len(b) == 1: bm.faces.new([a[i], a[j], b[0]])
            else: bm.faces.new([a[i], a[j], b[j], b[i]])
def sphere(bm, c, r, sq=(1, 1, 1), sub=1):
    m = Matrix.Translation(Vector(c)) @ Matrix.Diagonal((sq[0], sq[1], sq[2], 1))
    bmesh.ops.create_icosphere(bm, subdivisions=sub, radius=r, matrix=m)
def pebble(bm, c, r):
    sq = (R.uniform(0.8, 1.2), R.uniform(0.8, 1.2), R.uniform(0.45, 0.6)); sphere(bm, c, r, sq)
def tiles(prop, rfun, z0, z1, rows, cols, out=0.012, gap=0.18, thick=0.025, phase=0.0):
    """mosaic tiles on a surface of revolution r(z) between z0 and z1: each a small thick quad, random sea-glass colour"""
    for i in range(rows):
        za, zb = z0 + (z1 - z0) * i / rows, z0 + (z1 - z0) * (i + 1) / rows
        for j in range(cols):
            a0 = 2 * math.pi * (j + phase * (i % 2)) / cols; a1 = 2 * math.pi * (j + 1 + phase * (i % 2)) / cols
            g = (a1 - a0) * gap / 2; gz = (zb - za) * gap / 2
            mat = R.choices(SG, SGW)[0]; bm = prop.bm(mat)
            q = []
            for a, z in [(a0 + g, za + gz), (a1 - g, za + gz), (a1 - g, zb - gz), (a0 + g, zb - gz)]:
                r = rfun(z) + out; q.append(Vector((r * math.cos(a), r * math.sin(a), z)))
            n = (q[1] - q[0]).cross(q[3] - q[0]).normalized()
            if n.dot(Vector((q[0].x, q[0].y, 0))) < 0: n = -n
            outer = [bm.verts.new(v + n * thick / 2) for v in q]; inner = [bm.verts.new(v - n * thick / 2) for v in q]
            bm.faces.new(outer); bm.faces.new(list(reversed(inner)))
            for k in range(4):
                l = (k + 1) % 4; bm.faces.new([inner[k], inner[l], outer[l], outer[k]])
def scallop(bm, c, nrm, up, s, ribs=7):
    """flat-ish scallop shell: a fan with wavy rim, thickness s*0.12; hinge at c, opening toward up"""
    c, nrm, up = Vector(c), Vector(nrm).normalized(), Vector(up).normalized(); side = nrm.cross(up).normalized()
    top, bot = [], []
    n = ribs * 2
    for k in range(n + 1):
        a = math.radians(-70 + 140 * k / n); rr = s * (1.0 if k % 2 == 0 else 0.9)
        p = c + (up * math.cos(a) + side * math.sin(a)) * rr + nrm * (0.06 * s * (1 if k % 2 == 0 else 0))
        top.append(bm.verts.new(p + nrm * s * 0.06)); bot.append(bm.verts.new(p - nrm * s * 0.06))
    ct, cb = bm.verts.new(c + nrm * s * 0.18), bm.verts.new(c - nrm * s * 0.06)
    for k in range(n):
        bm.faces.new([ct, top[k], top[k + 1]]); bm.faces.new([cb, bot[k + 1], bot[k]])
        bm.faces.new([top[k], bot[k], bot[k + 1], top[k + 1]])
    bm.faces.new([ct, top[0], bot[0], cb]); bm.faces.new([ct, cb, bot[n], top[n]])
def front(prop, y):
    boxc(prop.bm("Front"), (0, y, 0.02), (0.02, 0.02, 0.02))

def lamp():
    P = Prop("Lamp")
    lathe(P.bm("Brass"), [(0, 0), (0.32, 0), (0.32, 0.05), (0.2, 0.1), (0.09, 0.18), (0.06, 0.24), (0.05, 0.88), (0.08, 0.9), (0, 0.9)])
    sphere(P.bm("Bulb"), (0, 0, 0.98), 0.12, sub=2)
    rf = lambda z: 0.56 + (0.28 - 0.56) * (z - 0.74) / (1.46 - 0.74)
    lathe(P.bm("Grout"), [(rf(0.74) - 0.02, 0.74), (rf(1.46) - 0.02, 1.46), (0.06, 1.47), (0, 1.47)], seg=24)
    tiles(P, rf, 0.75, 1.45, 6, 18, phase=0.5)
    cyl(P.bm("Brass"), (0, 0, 1.47), (0, 0, 1.53), 0.04); sphere(P.bm("Brass"), (0, 0, 1.56), 0.05)
    return P
def vase():
    P = Prop("Vase")
    prof = [(0, 0), (0.2, 0), (0.29, 0.14), (0.33, 0.34), (0.29, 0.58), (0.15, 0.8), (0.12, 0.93), (0.16, 0.98), (0.12, 0.98), (0, 0.9)]
    lathe(P.bm("SGGreen"), prof, seg=22)
    def rf(z):
        for (r0, z0), (r1, z1) in zip(prof[1:], prof[2:]):
            if z0 <= z <= z1: return r0 + (r1 - r0) * (z - z0) / max(1e-6, z1 - z0)
        return 0.3
    tiles(P, rf, 0.26, 0.46, 2, 16, out=0.01, phase=0.5)
    for k in range(5):
        a = 2 * math.pi * k / 5 + 0.3; tip = Vector((0.16 * math.cos(a), 0.16 * math.sin(a), 1.32 + 0.1 * (k % 2)))
        cyl(P.bm("Stem"), (0.03 * math.cos(a), 0.03 * math.sin(a), 0.85), tip, 0.012, seg=5)
        sphere(P.bm("Flower"), tip, 0.055, (1, 1, 0.8))
    return P
def keepsake():
    P = Prop("Box")
    W, Dp, H = 0.78, 0.56, 0.3
    b = P.bm("WoodWhite")
    boxc(b, (0, 0, H / 2), (W, Dp, H))                                     # body
    boxc(b, (0, 0, H + 0.03), (W + 0.04, Dp + 0.04, 0.06))                 # closed lid, slight overhang
    boxc(P.bm("Brass"), (0, -Dp / 2 - 0.02, H - 0.02), (0.08, 0.02, 0.1))  # clasp
    top = Vector((0, 0, H + 0.065))
    scallop(P.bm("ShellPink"), top + Vector((0, 0.1, 0)), (0, 0, 1), (0, -1, 0), 0.19)
    for k, (dx, dy) in enumerate([(-0.27, -0.14), (0.27, -0.14), (-0.27, 0.15), (0.27, 0.15)]):
        scallop(P.bm(["ShellCream", "ShellPeach", "ShellPeach", "ShellCream"][k]), top + Vector((dx, dy, 0)), (0, 0, 1), (0, -1, 0), 0.08)
    for k in range(9):
        pebble(P.bm(R.choices(SG, SGW)[0]), top + Vector((R.uniform(-0.34, 0.34), R.uniform(-0.24, 0.24), 0.005)), 0.03)
    fr = Vector((0, -Dp / 2 - 0.005, 0))                                   # front face: shells + sea glass
    for k, x in enumerate([-0.25, 0.0, 0.25]):
        scallop(P.bm(SHELLS[k]), fr + Vector((x, 0, 0.1)), (0, -1, 0), (0, 0, 1), 0.075)
    for k in range(6):
        pebble(P.bm(R.choices(SG, SGW)[0]), fr + Vector((-0.3 + 0.12 * k, -0.01, 0.22)), 0.026)
    front(P, -Dp / 2 - 0.03)
    return P
def suncatcher():
    P = Prop("Sun")
    cyl(P.bm("Driftwood"), (-0.55, 0, 1.55), (0.55, 0, 1.58), 0.045, seg=7)
    cyl(P.bm("String"), (-0.45, 0, 1.56), (0, 0, 1.85), 0.008, seg=4); cyl(P.bm("String"), (0.45, 0, 1.57), (0, 0, 1.85), 0.008, seg=4)
    for k, x in enumerate([-0.42, -0.21, 0.0, 0.21, 0.42]):
        L = [0.85, 1.1, 1.25, 1.05, 0.8][k]
        cyl(P.bm("String"), (x, 0, 1.55), (x, 0, 1.55 - L), 0.006, seg=4)
        n = 4 + (k % 2);
        for i in range(n):
            z = 1.55 - L * (i + 0.7) / n
            sphere(P.bm(R.choices(SG, SGW)[0]), (x, 0, z), R.uniform(0.045, 0.065), (R.uniform(0.9, 1.2), 0.45, R.uniform(1.0, 1.3)))
    front(P, -0.1)
    return P
def mirror():
    P = Prop("Mirror")
    w = P.bm("WoodLight")
    cyl(w, (-0.28, -0.12, 0), (-0.2, 0.0, 0.95), 0.025, seg=6); cyl(w, (0.28, -0.12, 0), (0.2, 0.0, 0.95), 0.025, seg=6)
    cyl(w, (0, 0.38, 0), (0, 0.04, 0.9), 0.025, seg=6); boxc(w, (0, -0.1, 0.2), (0.62, 0.06, 0.04))
    c = Vector((0, -0.04, 0.62)); tilt = Matrix.Rotation(math.radians(-10), 3, "X")
    nrm = tilt @ Vector((0, -1, 0)); upv = tilt @ Vector((0, 0, 1)); side = nrm.cross(upv)
    cyl(P.bm("Mirror"), c + nrm * 0.005, c - nrm * 0.03, 0.3, seg=24)
    cyl(P.bm("WoodWhite"), c - nrm * 0.03, c - nrm * 0.06, 0.4, seg=24)
    for k in range(12):
        a = 2 * math.pi * k / 12; dirv = upv * math.cos(a) + side * math.sin(a)
        scallop(P.bm(SHELLS[k % 3]), c + dirv * 0.31 + nrm * 0.0, nrm, dirv, 0.09)
        b2 = 2 * math.pi * (k + 0.5) / 12; d2 = upv * math.cos(b2) + side * math.sin(b2)
        pebble(P.bm(R.choices(SG, SGW)[0]), c + d2 * 0.36 + nrm * 0.01, 0.03)
    front(P, -0.25)
    return P
def candle():
    P = Prop("Candle")
    rf = lambda z: 0.18
    lathe(P.bm("Grout"), [(0, 0), (0.17, 0), (0.17, 0.42), (0.15, 0.42), (0.15, 0.05), (0, 0.05)], seg=20)
    tiles(P, rf, 0.02, 0.4, 3, 12, out=0.0, phase=0.5)
    cyl(P.bm("Candle"), (0, 0, 0.05), (0, 0, 0.5), 0.1, seg=12)
    sphere(P.bm("Flame"), (0, 0, 0.57), 0.035, (1, 1, 1.9), sub=2)
    return P
def necklace():
    P = Prop("Neck")
    br = P.bm("Brass")
    lathe(br, [(0, 0), (0.18, 0), (0.18, 0.04), (0.05, 0.08), (0.03, 0.1), (0, 0.1)], seg=16)    # base
    cyl(br, (0, 0, 0.08), (0, 0, 0.86), 0.025, seg=8)                                           # post
    cyl(br, (-0.3, 0, 0.84), (0.3, 0, 0.84), 0.022, seg=8)                                      # crossbar
    for sx in (-1, 1): sphere(br, (sx * 0.31, 0, 0.84), 0.035)
    pts = []
    for k in range(19):
        t = -1 + 2 * k / 18; a = t * math.pi / 2
        pts.append(Vector((0.24 * math.sin(a), -0.045, 0.83 - 0.36 * math.cos(a))))
    for k, p in enumerate(pts):
        if k == 9: continue
        if k % 3 == 1: pebble(P.bm(R.choices(SG[:3], [1, 1, 1])[0]), p, 0.03)
        else: sphere(P.bm("Pearl"), p, 0.026, sub=1)
    scallop(P.bm("ShellPink"), pts[9] + Vector((0, -0.01, 0.02)), (0, -1, 0), (0, 0, -1), 0.1)
    front(P, -0.12)
    return P

def export(objs, path):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, axis_forward="-Z", axis_up="Y",
                             apply_scale_options="FBX_SCALE_ALL", add_leaf_bones=False, bake_space_transform=True)
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    groups = {}
    for fn in (lamp, vase, keepsake, suncatcher, mirror, candle, necklace):
        P = fn(); groups[P.name] = P.build()
    allo = [o for g in groups.values() for o in g]
    for name, objs in groups.items():
        tris = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in objs)
        log(f"{name}: {len(objs)} parts, {tris} tris, parts {[o.name for o in objs]}")
    export(allo, os.path.join(D, "bella_props.fbx")); log("FBX_DONE")
    # ---------- preview: the two windows as planned (shop front faces -Y here)
    LAY = {"Lamp": (-0.9, 0), "Box": (0.25, -0.05), "Vase": (1.15, 0.05),
           "Sun": (-4.4, 0.25), "Mirror": (-3.2, 0.05), "Candle": (-2.25, -0.1), "Neck": (-1.55, 0.05)}
    for name, (x, y) in LAY.items():
        for o in groups[name]: o.location = (x, y, 0)
        for o in groups[name]:
            if o.name.endswith("_Front"): o.hide_render = True
    sc = bpy.context.scene
    def plane(name, size, loc, rgb, rot=(0, 0, 0)):
        bpy.ops.mesh.primitive_plane_add(size=size, location=loc, rotation=rot); p = bpy.context.active_object; p.name = name
        m = bpy.data.materials.new(name); m.use_nodes = True
        m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (lin(rgb[0]), lin(rgb[1]), lin(rgb[2]), 1)
        p.data.materials.append(m)
    plane("Shelf", 14, (0, 0, 0), (0.62, 0.46, 0.30)); plane("Back", 14, (0, 1.2, 3), (0.42, 0.62, 0.78), (math.radians(90), 0, 0))
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")); sc.collection.objects.link(sun)
    sun.rotation_euler = (math.radians(55), math.radians(15), math.radians(-25)); sun.data.energy = 3.0
    sc.world = bpy.data.worlds.new("W"); sc.world.use_nodes = True
    bg = sc.world.node_tree.nodes["Background"]; bg.inputs["Color"].default_value = (lin(0.8), lin(0.86), lin(0.92), 1); bg.inputs["Strength"].default_value = 0.8
    engines = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
    sc.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in engines else "BLENDER_EEVEE"
    sc.render.resolution_x, sc.render.resolution_y = 1200, 800
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam; cam.data.lens = 50
    def shot(name, loc, target):
        cam.location = Vector(loc); d = Vector(target) - cam.location
        cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(D, name); bpy.ops.render.render(write_still=True); log(f"shot {name}")
    shot("prev_left.png", (0.1, -5.2, 1.6), (0.15, 0, 0.62))
    shot("prev_right.png", (-2.9, -5.6, 1.7), (-2.9, 0, 0.72))
    shot("prev_close.png", (-0.5, -2.6, 1.3), (-0.4, 0, 0.6))
    log("RENDER_DONE")
except Exception:
    log(traceback.format_exc())
