"""Japan garden pieces, batch 2 (job 125, Oct 16 2026): the WATERWAY. Shannon on the look test: "the waterway where the bridge is need
SERIOUS fixing" (the straight concrete trough, the black boulder strips JP_Canal_Rocks_84/118, raised banks holding the water 1.3 above
the lawn, floating ramps). The fix sinks the canal into the lawn as a garden stream: the water lowered to about -0.6, the concrete
banks replaced by a low stone edge with moss, rocks and reed clumps along it. In the France/Italy finish (faceted, flat colours).
  canal_edge.fbx   Edge_Stone, Edge_Moss - one bank segment, 8 long (Roblox z), x -5.4..0.2 (the WATER face at +0.2): a mossy lawn lip
                   flush with the lawn (0.06 at its outer edge), then two courses of dressed stone to the water, down to y -3.2
  canal_edge_b.fbx the same, a different block pattern (alternate them so the edge does not repeat)
  reeds.fbx        Reed_Leaf, Reed_Flower - a clump of tall leaves with purple iris heads, ~2.6 high
Units, axes, naming and previews as gen_garden1.py. Run: blender -b --python gen_garden2.py"""
import bpy, bmesh, math, os, random, traceback, json, sys
from mathutils import Vector
D = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, D)
OUT = os.environ.get("GARDEN_OUT2") or os.path.join(D, "out2")
os.makedirs(OUT, exist_ok=True)
LOG = os.path.join(OUT, "gen_log.txt")
def log(m): open(LOG, "a").write(str(m) + "\n"); print(m)
COL = {"Edge_Stone": (0.60, 0.59, 0.56), "Edge_Moss": (0.42, 0.58, 0.30), "Reed_Leaf": (0.33, 0.56, 0.28), "Reed_Flower": (0.55, 0.38, 0.78)}
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
def material(key):
    m = bpy.data.materials.get(key)
    if m: return m
    m = bpy.data.materials.new(key); m.use_nodes = True
    c = COL[key]; m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (lin(c[0]), lin(c[1]), lin(c[2]), 1)
    m.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.85
    return m
def obj_from_bm(name, bm, key):
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
    me = bpy.data.meshes.new(name); bm.normal_update(); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o); me.materials.append(material(key))
    for p in me.polygons: p.use_smooth = False
    return o
def tris(o): return sum(len(p.vertices) - 2 for p in o.data.polygons)
def quadbox(bm, x0, x1, y0, y1, z0, z1, top_tilt=0.0, jit=None):
    """an axis box in BLENDER coords (x across, y along, z up); the top can tilt down toward +x by top_tilt; jit moves top corners"""
    j = jit or (lambda i: 0.0)
    b = [bm.verts.new(v) for v in [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0)]]
    t = [bm.verts.new((x, y, z1 - top_tilt * ((x - x0) / max(0.01, x1 - x0)) + j(i))) for i, (x, y) in enumerate([(x0, y0), (x1, y0), (x1, y1), (x0, y1)])]
    for a, c in [((0, 1), (1, 2)), ((1, 2), (2, 3)), ((2, 3), (3, 0)), ((3, 0), (0, 1))]:
        pass
    for i in range(4):
        k = (i + 1) % 4; bm.faces.new([b[i], b[k], t[k], t[i]])
    bm.faces.new(list(reversed(b))); bm.faces.new(t)
    return t
# ---------- the bank segment ----------
# Blender axes: x across the bank (the water at +x), y ALONG the canal (-4..4 = Roblox z -4..4 after the -y flip, symmetric), z up.
def build_edge(seed, name):
    rnd = random.Random(seed)
    st, ms = bmesh.new(), bmesh.new()
    # the lawn lip: a mossy strip from the lawn (x -2.8) to the stones, at the lawn's height
    quadbox(ms, -5.4, -0.6, -4.0, 4.0, -0.5, 0.06, top_tilt=0.12)          # (covers the old 5-wide bank's footprint; flush with the lawn at its outer edge)
    # the stone face: dressed blocks in two courses, each block a little different
    y = -4.0
    while y < 3.99:
        L = min(4.0 - y, rnd.choice((1.6, 2.0, 2.4)))
        for (z0, z1, x0, x1) in ((-3.2, -0.9, -0.7, 0.2), (-0.9, 0.3, -0.75, 0.05)):
            jit = lambda i, r=rnd: r.uniform(-0.08, 0.08)
            quadbox(st, x0 + rnd.uniform(-0.05, 0.05), x1 + rnd.uniform(-0.08, 0.06), y + 0.04, y + L - 0.04, z0, z1 + rnd.uniform(-0.06, 0.08), top_tilt=0.08, jit=jit)
        y += L
    # a few moss cushions on the top course
    for k in range(3):
        cy = -3.0 + k * 3.0 + rnd.uniform(-0.6, 0.6)
        res = bmesh.ops.create_icosphere(ms, subdivisions=1, radius=0.55)
        for v in res["verts"]:
            v.co.z *= 0.35; v.co *= 1.0 + rnd.uniform(-0.15, 0.15); v.co += Vector((-0.3, cy, 0.4))
    return [obj_from_bm(name + "_Edge_Stone", st, "Edge_Stone"), obj_from_bm(name + "_Edge_Moss", ms, "Edge_Moss")]
# ---------- reeds and irises ----------
def build_reeds():
    rnd = random.Random(9)
    lf, fl = bmesh.new(), bmesh.new()
    for k in range(11):                                                   # tall sword leaves, each a thin bent blade
        a = rnd.uniform(0, 2 * math.pi); r = rnd.uniform(0.0, 0.5)
        base = Vector((math.cos(a) * r, math.sin(a) * r, 0))
        h = rnd.uniform(1.6, 2.6); lean = Vector((math.cos(a), math.sin(a), 0)) * rnd.uniform(0.3, 0.7)
        w = 0.16
        side = Vector((-math.sin(a), math.cos(a), 0)) * w
        p0, p1, p2 = base, base + lean * 0.4 + Vector((0, 0, h * 0.55)), base + lean + Vector((0, 0, h))
        v = [lf.verts.new(p0 - side), lf.verts.new(p0 + side), lf.verts.new(p1 + side * 0.7), lf.verts.new(p1 - side * 0.7), lf.verts.new(p2)]
        lf.faces.new([v[0], v[1], v[2], v[3]]); lf.faces.new([v[3], v[2], v[4]])
    for k in range(4):                                                    # iris heads on short stalks
        a = rnd.uniform(0, 2 * math.pi); c = Vector((math.cos(a) * 0.3, math.sin(a) * 0.3, rnd.uniform(1.7, 2.2)))
        res = bmesh.ops.create_icosphere(fl, subdivisions=1, radius=0.28)
        for v in res["verts"]: v.co.z *= 0.7; v.co += c
        for i in range(3):                                                # three falling petals
            b = 2 * math.pi * i / 3 + a
            tip = c + Vector((math.cos(b) * 0.45, math.sin(b) * 0.45, -0.25))
            s = Vector((-math.sin(b), math.cos(b), 0)) * 0.12
            fl.faces.new([fl.verts.new(c - s), fl.verts.new(c + s), fl.verts.new(tip)])
    return [obj_from_bm("Reed_Leaf", lf, "Reed_Leaf"), obj_from_bm("Reed_Flower", fl, "Reed_Flower")]

def export(objs, name):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.fbx(filepath=os.path.join(OUT, name + ".fbx"), use_selection=True, axis_forward="-Z", axis_up="Y",
                             apply_scale_options="FBX_SCALE_ALL", add_leaf_bones=False, bake_space_transform=True)
    log(f"{name}.fbx: {len(objs)} meshes, {sum(tris(o) for o in objs)} tris; " + ", ".join(f"{o.name} {tris(o)}" for o in objs))
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    pieces = {"canal_edge": build_edge(11, "A"), "canal_edge_b": build_edge(12, "B"), "reeds": build_reeds()}
    for n, objs in pieces.items(): export(objs, n)
    def bbox(objs):
        pts = [o.matrix_world @ v.co for o in objs for v in o.data.vertices]
        rb = [(p.x, p.z, -p.y) for p in pts]
        return {"min": [round(min(q[i] for q in rb), 3) for i in range(3)], "max": [round(max(q[i] for q in rb), 3) for i in range(3)]}
    info = {n: bbox(o) for n, o in pieces.items()}
    json.dump(info, open(os.path.join(OUT, "pieces.json"), "w"), indent=1); log("BBOX " + json.dumps(info)); log("FBX_DONE")
    if os.environ.get("GARDEN_NO_RENDER"): raise SystemExit
    # preview: a stretch of canal - two edge rows facing a strip of water, reeds, Cycles CPU
    sc = bpy.context.scene
    rows = []
    for side in (-1, 1):
        for k in range(5):
            src = pieces["canal_edge" if k % 2 == 0 else "canal_edge_b"]
            for o in src:
                c = o.copy(); c.data = o.data; sc.collection.objects.link(c)
                c.location = Vector((side * -9.0, -16 + k * 8, 0)); c.rotation_euler = (0, 0, 0 if side < 0 else math.pi)
    for o in pieces["canal_edge"] + pieces["canal_edge_b"]: o.hide_render = True
    for o in pieces["reeds"]: o.location = Vector((-8.6, 2, -0.6))
    def plane(name, size, loc, rgb, sx=1, sy=1):
        bpy.ops.mesh.primitive_plane_add(size=size, location=loc); p = bpy.context.active_object; p.name = name; p.scale = (sx, sy, 1)
        m = bpy.data.materials.new(name); m.use_nodes = True
        m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (lin(rgb[0]), lin(rgb[1]), lin(rgb[2]), 1)
        p.data.materials.append(m)
    plane("LawnL", 1, (-30, 0, 0.0), (0.36, 0.62, 0.30), 42, 60); plane("LawnR", 1, (30, 0, 0.0), (0.36, 0.62, 0.30), 42, 60)
    plane("Water", 1, (0, 0, -0.6), (0.27, 0.55, 0.70), 19, 60); plane("Bed", 1, (0, 0, -3.0), (0.30, 0.36, 0.30), 20, 60)
    sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 24; sc.cycles.use_denoising = False
    sc.render.resolution_x, sc.render.resolution_y = 1000, 620
    sc.world = bpy.data.worlds.new("W"); sc.world.use_nodes = True
    bg = sc.world.node_tree.nodes["Background"]; bg.inputs["Color"].default_value = (lin(0.62), lin(0.80), lin(0.95), 1); bg.inputs["Strength"].default_value = 0.9
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")); sc.collection.objects.link(sun)
    sun.rotation_euler = (math.radians(48), math.radians(8), math.radians(-30)); sun.data.energy = 3.2
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam; cam.data.lens = 30
    def shot(fn, loc, target):
        cam.location = Vector(loc); d = Vector(target) - cam.location
        cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(OUT, fn); bpy.ops.render.render(write_still=True); log(f"shot {fn}")
    shot("prev_canal.png", (-16, -30, 9), (0, 0, -0.5))
    shot("prev_canal_low.png", (-12, -14, 2.2), (-8, 4, 0.2))
    log("RENDER_DONE")
except SystemExit:
    pass
except Exception:
    log(traceback.format_exc())
