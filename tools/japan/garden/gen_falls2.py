"""Canal falls r2 (runner 7, Oct 16 2026). Shannon on r1 (the stream lying across the end wall's flat coping): "the fountain again has
like lots of issues. Water would not really flow like that. You need to put the rocks where the waterfall is closer to the edge of the
embankment, and there needs to be some entryway for the water". So: the rocks STAND IN the canal's end - they replace the middle 16
studs of the end wall (WallS2 + WallS3) - and the water comes out of a cleft between them, runs down a short rock chute and pours
straight down into the canal, with foam where it lands. The rock rise continues behind on the lawn.
Meshes (the installer's colour keys): Fall_Rock, Fall_Water (Glass, faint; moving water is drawn by Beams the installer adds), Fall_Foam.
Units: 1 = 1 stud, Z up. ORIGIN = the end wall's WATER FACE (Blender y 0), the canal's centre line (x 0), lawn level (z 0); the canal
is at Blender -y (Roblox +z after the -Z-forward / Y-up export). Water 1.3, canal bed -4.0, the gap to fill x -8..8, the wall 4.6 deep
(y 0..4.6), its coping top 2.1. Writes out_falls2/canal_falls2.fbx, japan_falls2_kit.fbx (one Empty "canal_falls2"), pieces.json
(incl. the beam points in Roblox axes from the origin), prev_falls2_*.png.  Run: blender -b --python gen_falls2.py"""
import bpy, bmesh, math, os, json, random, traceback
from mathutils import Vector
D = os.path.dirname(os.path.abspath(__file__))
OUT = os.environ.get("GARDEN_OUT") or os.path.join(D, "out_falls2")
os.makedirs(OUT, exist_ok=True)
LOG = os.path.join(OUT, "gen_log.txt")
def log(m): open(LOG, "a").write(str(m) + "\n"); print(m)
COL = {"Fall_Rock": (0.50, 0.50, 0.50), "Fall_Water": (0.72, 0.88, 0.97), "Fall_Foam": (0.95, 0.98, 1.00)}
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
def material(key):
    m = bpy.data.materials.get(key)
    if m: return m
    m = bpy.data.materials.new(key); m.use_nodes = True
    c = COL[key]; bs = m.node_tree.nodes["Principled BSDF"]
    bs.inputs["Base Color"].default_value = (lin(c[0]), lin(c[1]), lin(c[2]), 1); bs.inputs["Roughness"].default_value = 0.8 if key != "Fall_Water" else 0.1
    m.diffuse_color = (lin(c[0]), lin(c[1]), lin(c[2]), 1)
    return m
def obj_from_bm(name, bm):
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
    me = bpy.data.meshes.new(name); bm.normal_update(); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o)
    me.materials.append(material(name))
    for p in me.polygons: p.use_smooth = False
    return o
def tris(o): return sum(len(p.vertices) - 2 for p in o.data.polygons)
WATER, BED = 1.3, -4.0
rnd = random.Random(1260)
def blob(bm, c, r, sz=1.0, sy=1.0, jitter=0.16, subdiv=2, floor=BED - 0.6, keep_out=None):
    """a faceted rock: a jittered icosphere scaled (1, sy, sz); flattened at `floor`; keep_out(v) may push a vertex out of the chute"""
    res = bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=r)
    for v in res["verts"]:
        v.co *= 1.0 + rnd.uniform(-jitter, jitter)
        v.co.z *= sz; v.co.y *= sy
        v.co += Vector(c)
        if v.co.z < floor: v.co.z = floor
        if keep_out: keep_out(v)
CH = 1.7          # the cleft's half width at the lip (the water ~1.4 each side)
def keep_out(v):
    """keep rock out of the cleft: the channel x -CH..CH above the chute floor, from the back of the cleft to the canal"""
    if abs(v.co.x) < CH + 0.15 and v.co.z > chute_floor(v.co.y) - 0.1 and -3.0 < v.co.y < 10.5:
        v.co.x = math.copysign(CH + 0.15, v.co.x if v.co.x != 0 else 1)
# the water's path (Blender y back, z up): out of the cleft at the back, down the chute, over the lip at the canal's edge, straight down
PATH = [(10.0, 6.6), (8.0, 6.0), (6.0, 5.2), (4.0, 4.4), (2.0, 3.8), (0.4, 3.45), (-0.5, 3.3), (-0.9, 2.7), (-1.15, 2.0), (-1.3, WATER + 0.02)]
HALF = [1.3, 1.35, 1.4, 1.45, 1.5, 1.55, 1.6, 1.65, 1.7, 1.8]
def chute_floor(y):
    """the rock chute's floor under the water, by y"""
    if y >= PATH[0][0]: return PATH[0][1] - 0.15
    for (ya, za), (yb, zb) in zip(PATH, PATH[1:]):
        if yb <= y <= ya:
            t = (ya - y) / (ya - yb); return za + (zb - za) * t - 0.15
    return -10.0                                                               # in front of the lip: open (the water falls)
def build():
    rk, wa, fo = bmesh.new(), bmesh.new(), bmesh.new()
    # 1. the canal-end rocks: big boulders standing IN the water, their feet on the bed, the front a little into the canal (y -0.5..-2.8)
    for side in (-1, 1):
        for (x, y, z, r, sz) in ((3.4, -1.0, 0.2, 2.4, 1.6), (6.0, -0.6, -0.2, 2.6, 1.5), (8.7, 0.2, 0.0, 2.3, 1.3),
                                 (4.2, 0.8, 3.3, 2.0, 1.05), (7.2, 1.2, 2.8, 2.0, 1.0), (9.8, 1.8, 2.3, 1.6, 0.9),
                                 (2.9, 2.6, 4.9, 1.7, 1.0), (5.6, 3.0, 4.6, 1.9, 1.0)):
            blob(rk, (side * (x + rnd.uniform(-0.2, 0.2)), y, z), r, sz=sz, subdiv=2, keep_out=keep_out)
    # 2. the rise behind: masses either side of the cleft and a big rock at its head that the water comes out from under
    for side in (-1, 1):
        for (x, y, z, r, sz) in ((3.6, 6.0, 4.8, 2.6, 1.2), (6.8, 6.6, 4.0, 2.9, 1.1), (10.0, 5.2, 2.6, 2.6, 1.0),
                                 (4.4, 9.6, 6.2, 3.0, 1.2), (8.2, 10.6, 5.6, 3.2, 1.2), (11.4, 9.0, 3.4, 2.8, 1.0),
                                 (6.0, 13.6, 5.2, 3.2, 1.1), (10.6, 13.8, 3.6, 3.0, 1.0)):
            blob(rk, (side * (x + rnd.uniform(-0.3, 0.3)), y, z), r, sz=sz, subdiv=2, floor=-0.3, keep_out=keep_out)
    blob(rk, (0.0, 12.6, 7.0), 3.4, sz=1.15, subdiv=2, floor=-0.3)          # the head rock over the spring
    blob(rk, (0.0, 15.6, 5.0), 3.2, sz=1.05, subdiv=2, floor=-0.3)
    # 3. the chute: a faceted rock trough under the water, from the spring to the lip
    secs = []
    ys = [p[0] for p in PATH if p[0] >= -0.5]
    for y in ys:
        f = chute_floor(y); h = CH + 0.5
        secs.append([Vector((-h, y, f - 1.6)), Vector((h, y, f - 1.6)), Vector((h, y, f + 0.6)), Vector((CH * 0.8, y, f)), Vector((-CH * 0.8, y, f)), Vector((-h, y, f + 0.6))])
    rings = [[rk.verts.new(p) for p in s] for s in secs]
    for a, b in zip(rings, rings[1:]):
        for i in range(len(a)):
            j = (i + 1) % len(a); rk.faces.new([a[i], a[j], b[j], b[i]])
    rk.faces.new(list(reversed(rings[0]))); rk.faces.new(rings[-1])
    # 4. the water: a thin ribbon along the path, a gentle ripple across
    N = 6; top, bot = [], []
    for k, (y, z) in enumerate(PATH):
        h = HALF[k]; rt, rb = [], []
        for i in range(N + 1):
            x = -h + 2 * h * i / N
            dz = 0.06 * math.sin(i * 1.7 + k * 1.3) if 0 < i < N else -0.04
            if z < 3.3:                                                       # the falling sheet: the ripple goes into y, not z
                rt.append(wa.verts.new((x, y + dz, z))); rb.append(wa.verts.new((x, y + dz + 0.1, z)))
            else:
                rt.append(wa.verts.new((x, y, z + dz))); rb.append(wa.verts.new((x, y, z + dz - 0.1)))
        top.append(rt); bot.append(rb)
    for k in range(len(PATH) - 1):
        for i in range(N):
            wa.faces.new([top[k][i], top[k][i + 1], top[k + 1][i + 1], top[k + 1][i]])
            wa.faces.new([bot[k + 1][i], bot[k + 1][i + 1], bot[k][i + 1], bot[k][i]])
        wa.faces.new([top[k][0], top[k + 1][0], bot[k + 1][0], bot[k][0]])
        wa.faces.new([bot[k][N], bot[k + 1][N], top[k + 1][N], top[k][N]])
    # 5. foam where it lands (a low wavy patch on the water in front of the rocks) and a few bubbles
    res = bmesh.ops.create_circle(fo, cap_ends=True, segments=16, radius=1.0)
    for v in res["verts"]:
        a = math.atan2(v.co.y, v.co.x); w = 1.0 + 0.2 * math.sin(5 * a + 0.7) + 0.1 * math.sin(9 * a)
        v.co = Vector((v.co.x * 2.6 * w, -2.6 + v.co.y * 1.3 * w, WATER + 0.03))
    ext = bmesh.ops.extrude_face_region(fo, geom=[f for f in fo.faces])
    for v in [e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)]: v.co.z += 0.04
    for (x, y, r) in ((-1.0, -1.9, 0.42), (1.0, -2.0, 0.45), (0.0, -1.7, 0.4), (-1.9, -2.8, 0.3), (1.8, -3.0, 0.32)):
        r2 = bmesh.ops.create_icosphere(fo, subdivisions=1, radius=r)
        for v in r2["verts"]: v.co.z *= 0.35; v.co += Vector((x, y, WATER + 0.05))
    return [obj_from_bm("Fall_Rock", rk), obj_from_bm("Fall_Water", wa), obj_from_bm("Fall_Foam", fo)]
def export(objs, path):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, axis_forward="-Z", axis_up="Y", apply_scale_options="FBX_SCALE_ALL",
                             add_leaf_bones=False, bake_space_transform=True, object_types={"EMPTY", "MESH"})
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    objs = build()
    export(objs, os.path.join(OUT, "canal_falls2.fbx"))
    log(f"canal_falls2.fbx: {len(objs)} meshes, {sum(tris(o) for o in objs)} tris; " + ", ".join(f"{o.name} {tris(o)}" for o in objs))
    def rb(p): return [round(p[0], 3), round(p[2], 3), round(-p[1], 3)]   # Blender (x, y, z) -> Roblox (x, y up, z)
    info = {}
    for o in objs:
        q = [rb(o.matrix_world @ v.co) for v in o.data.vertices]
        info["canal_falls2/" + o.name] = {"min": [min(a[i] for a in q) for i in range(3)], "max": [max(a[i] for a in q) for i in range(3)]}
    allq = [rb(o.matrix_world @ v.co) for o in objs for v in o.data.vertices]
    info["canal_falls2"] = {"min": [min(a[i] for a in allq) for i in range(3)], "max": [max(a[i] for a in allq) for i in range(3)]}
    info["beams"] = {"chute_top": rb((0, PATH[0][0], PATH[0][1] + 0.12)), "lip": rb((0, PATH[6][0], PATH[6][1] + 0.12)),
                     "foot": rb((0, PATH[-1][0] - 0.1, WATER + 0.05)), "mist": rb((0, -2.2, WATER + 0.3))}
    json.dump(info, open(os.path.join(OUT, "pieces.json"), "w"), indent=1)
    log("INFO " + json.dumps(info))
    emp = bpy.data.objects.new("canal_falls2", None); bpy.context.scene.collection.objects.link(emp)
    for o in objs:
        mw = o.matrix_world.copy(); o.parent = emp; o.matrix_world = mw
    export([emp] + objs, os.path.join(OUT, "japan_falls2_kit.fbx"))
    log("FBX_DONE")
    # previews: stand-in canal (side walls, the two remaining end-wall pieces, coping), water, lawn
    sc = bpy.context.scene
    def slab(name, c, s, col):
        bpy.ops.mesh.primitive_cube_add(size=1, location=c); o = bpy.context.active_object; o.name = name; o.scale = s
        m = bpy.data.materials.new(name); m.use_nodes = True
        m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (lin(col[0]), lin(col[1]), lin(col[2]), 1)
        o.data.materials.append(m); return o
    slab("Lawn", (0, 30, -0.05), (140, 52, 0.1), (0.36, 0.62, 0.30))
    slab("LawnSides", (0, -30, -0.05), (140, 60, 0.1), (0.36, 0.62, 0.30))
    slab("Water", (0, -25, WATER - 0.01), (25, 50, 0.02), (0.16, 0.41, 0.44))
    for x0, x1 in ((-12.5, -8.0), (8.0, 12.5)):
        slab("EndWall", ((x0 + x1) / 2, 2.3, (2.1 - 1.2) / 2), (x1 - x0, 4.6, 3.3), (0.55, 0.47, 0.40))
    for x in (-14.75, 14.75):
        slab("SideWall", (x, -25, 0.45), (4.6, 50, 3.3), (0.55, 0.47, 0.40))
    sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 32; sc.cycles.use_denoising = False
    sc.render.resolution_x, sc.render.resolution_y = 1000, 640
    sc.world = bpy.data.worlds.new("W"); sc.world.use_nodes = True
    bg = sc.world.node_tree.nodes["Background"]; bg.inputs["Color"].default_value = (lin(0.62), lin(0.80), lin(0.95), 1); bg.inputs["Strength"].default_value = 0.9
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")); sc.collection.objects.link(sun)
    sun.rotation_euler = (math.radians(45), math.radians(10), math.radians(-35)); sun.data.energy = 3.2
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam; cam.data.lens = 32
    def shot(fn, loc, target):
        cam.location = Vector(loc); d = Vector(target) - cam.location
        cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(OUT, fn); bpy.ops.render.render(write_still=True); log(f"shot {fn}")
    shot("prev_falls2_from_canal.png", (0, -18, 5.0), (0, 4, 3.0))
    shot("prev_falls2_three_quarter.png", (-13, -14, 8), (0, 3, 2.5))
    shot("prev_falls2_from_lawn.png", (16, 22, 10), (0, 4, 3))
    log("RENDER_DONE")
except Exception:
    log(traceback.format_exc()); log("FBX_FAILED")
