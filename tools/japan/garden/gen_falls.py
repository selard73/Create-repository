"""Canal falls (job 125, Oct 16 2026): a waterfall that FEEDS the canal over its south end wall. Shannon: "The waterfall feeds it";
after look 3 "the waterfall area has MAJOR issues" (the old freestanding piece sat in or on the wall). This piece is built for the wall:
a faceted rock rise on the lawn BEHIND the end wall, a stream ribbon that comes out between the rocks, cascades down a rock chute to the
wall, runs across the coping and spills over its lip into the water, with foam where it lands.
Mesh objects named for the installer's colours: Fall_Rock (rocks + chute), Fall_Water (the ribbon: Glass 0.25, DoubleSided),
Fall_Foam (the landing foam and the little splash at the wall's back).
Units: 1 Blender unit = 1 stud, Z up. ORIGIN = the end wall's WATER FACE, centred across the canal, at lawn level (y 0 in Roblox).
The canal is in front (Blender -Y = Roblox +Z after the -Z-forward / Y-up export); behind the wall is Blender +Y. The wall (with its
coping) is 4.6 thick (Blender y 0..4.6) and its coping top is at 2.1, overhanging 0.3 into the canal; the water is at 1.3.
Writes out_falls/canal_falls.fbx, out_falls/japan_falls_kit.fbx (one Empty "canal_falls"), out_falls/pieces.json, prev_falls_*.png.
Run: blender -b --python gen_falls.py"""
import bpy, bmesh, math, os, json, random, traceback
from mathutils import Vector
D = os.path.dirname(os.path.abspath(__file__))
OUT = os.environ.get("GARDEN_OUT") or os.path.join(D, "out_falls")
os.makedirs(OUT, exist_ok=True)
LOG = os.path.join(OUT, "gen_log.txt")
def log(m): open(LOG, "a").write(str(m) + "\n"); print(m)
COL = {"Fall_Rock": (0.50, 0.50, 0.50), "Fall_Water": (0.72, 0.88, 0.97), "Fall_Foam": (0.95, 0.98, 1.00)}   # = the installer's COL
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
def material(key):
    m = bpy.data.materials.get(key)
    if m: return m
    m = bpy.data.materials.new(key); m.use_nodes = True
    c = COL[key]; bs = m.node_tree.nodes["Principled BSDF"]
    bs.inputs["Base Color"].default_value = (lin(c[0]), lin(c[1]), lin(c[2]), 1); bs.inputs["Roughness"].default_value = 0.8
    if key == "Fall_Water":
        bs.inputs["Roughness"].default_value = 0.1
        try: bs.inputs["Alpha"].default_value = 0.75
        except Exception: pass
        m.blend_method = "BLEND" if hasattr(m, "blend_method") else None
    m.diffuse_color = (lin(c[0]), lin(c[1]), lin(c[2]), 1)
    return m
def obj_from_bm(name, bm, smooth=False):
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
    me = bpy.data.meshes.new(name); bm.normal_update(); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o)
    me.materials.append(material(name))
    for p in me.polygons: p.use_smooth = smooth
    return o
def tris(o): return sum(len(p.vertices) - 2 for p in o.data.polygons)

WALL_BACK = 4.6            # the wall's lawn-side face (Blender +y)
COPE = 2.1                 # the coping top
LIP = -0.3                 # the coping's front edge (overhang into the canal)
WATER = 1.3
rnd = random.Random(1251)

def blob(bm, c, r, sz=1.0, jitter=0.16, subdiv=2, min_y=WALL_BACK + 0.1, ground=-0.3):
    """a faceted rock: a jittered icosphere squashed by sz; flattened against the wall's back and into the lawn"""
    res = bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=r)
    for v in res["verts"]:
        v.co *= 1.0 + rnd.uniform(-jitter, jitter)
        v.co.z *= sz
        v.co += Vector(c)
        if v.co.y < min_y: v.co.y = min_y
        if v.co.z < ground: v.co.z = ground

# the stream's centreline (y, z) from the notch in the rocks down to the water, and its half width along the way
PATH = [(10.2, 6.1), (9.0, 5.6), (7.9, 4.6), (7.0, 3.6), (6.1, 2.9), (5.3, 2.45), (WALL_BACK, COPE + 0.09),
        (2.4, COPE + 0.08), (0.0, COPE + 0.08), (LIP, COPE + 0.05), (LIP - 0.18, COPE - 0.15), (LIP - 0.34, 1.75), (LIP - 0.46, WATER + 0.02)]
HALF = [1.9, 2.1, 2.3, 2.5, 2.7, 2.8, 2.9, 2.9, 2.9, 2.9, 3.0, 3.1, 3.2]

def build_falls():
    rk, wa, fo = bmesh.new(), bmesh.new(), bmesh.new()
    # 1. the rock rise behind the wall: taller masses either side of the notch, a big rock behind it, framing rocks at the wall's back
    for side in (-1, 1):
        j = rnd.uniform(-0.4, 0.4)
        blob(rk, (side * (7.6 + j), 9.4, 3.6), 3.4, sz=1.15, subdiv=2)
        blob(rk, (side * (5.2 + j), 7.0, 2.2), 2.3, sz=1.05, subdiv=1)
        blob(rk, (side * (9.8 + j), 6.6, 1.7), 2.2, sz=0.95, subdiv=1)
        blob(rk, (side * (4.6 + j), 11.8, 4.6), 3.3, sz=1.2, subdiv=2)
        blob(rk, (side * (8.2 + j), 13.0, 4.9), 3.2, sz=1.25, subdiv=2)
        blob(rk, (side * (11.2 + j), 10.8, 2.3), 2.4, sz=1.0, subdiv=1)
        blob(rk, (side * 4.4, 5.6, 1.1), 1.5, sz=0.95, subdiv=1)                  # the framing rocks at the wall's back
        blob(rk, (side * 3.9, 8.8, 3.4), 1.6, sz=1.0, subdiv=1)                  # beside the chute, mid height
    blob(rk, (0.0, 13.4, 4.4), 3.7, sz=1.15, subdiv=2)                            # the big rock the stream comes out under
    blob(rk, (0.0, 16.0, 3.2), 3.2, sz=1.1, subdiv=1)
    # 2. the rock chute under the stream (a faceted wedge just below the ribbon, from the notch to the wall's back)
    secs = []
    for k, (y, z) in enumerate(PATH):
        if y < WALL_BACK + 0.05: break
        h = HALF[k] + 0.6
        top = z - 0.12
        secs.append([Vector((-h, y, -0.3)), Vector((h, y, -0.3)), Vector((h, y, top - 0.25 + rnd.uniform(-0.1, 0.1))),
                     Vector((h * 0.55, y, top)), Vector((-h * 0.55, y, top)), Vector((-h, y, top - 0.25 + rnd.uniform(-0.1, 0.1)))])
    rings = [[rk.verts.new(p) for p in s] for s in secs]
    for a, b in zip(rings, rings[1:]):
        for i in range(len(a)):
            j = (i + 1) % len(a); rk.faces.new([a[i], a[j], b[j], b[i]])
    rk.faces.new(list(reversed(rings[0]))); rk.faces.new(rings[-1])
    # 3. the stream ribbon: a thin slab along the path, a gentle ripple across it
    top, bot = [], []
    N = 6
    for k, (y, z) in enumerate(PATH):
        h = HALF[k]
        rowt, rowb = [], []
        for i in range(N + 1):
            x = -h + 2 * h * i / N
            dz = 0.05 * math.sin(i * 1.7 + k * 1.3) if 0 < i < N else -0.04
            rowt.append(wa.verts.new((x, y, z + dz)))
            rowb.append(wa.verts.new((x, y, z + dz - 0.1)))
        top.append(rowt); bot.append(rowb)
    for k in range(len(PATH) - 1):
        for i in range(N):
            wa.faces.new([top[k][i], top[k][i + 1], top[k + 1][i + 1], top[k + 1][i]])
            wa.faces.new([bot[k + 1][i], bot[k + 1][i + 1], bot[k][i + 1], bot[k][i]])
        wa.faces.new([top[k][0], top[k + 1][0], bot[k + 1][0], bot[k][0]])
        wa.faces.new([bot[k][N], bot[k + 1][N], top[k + 1][N], top[k][N]])
    wa.faces.new([top[0][i] for i in range(N + 1)] + [bot[0][i] for i in range(N, -1, -1)])
    # 4. foam: where it lands in the canal (a low wavy patch on the water) and a little splash where it meets the wall's back
    res = bmesh.ops.create_circle(fo, cap_ends=True, segments=16, radius=1.0)
    for v in res["verts"]:
        a = math.atan2(v.co.y, v.co.x); w = 1.0 + 0.22 * math.sin(5 * a + 0.7) + 0.1 * math.sin(9 * a)
        v.co = Vector((v.co.x * 3.0 * w, LIP - 1.05 + v.co.y * 1.0 * w, WATER + 0.03))
    ext = bmesh.ops.extrude_face_region(fo, geom=[f for f in fo.faces])
    for v in [e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)]: v.co.z += 0.04
    for (x, y, r) in ((-1.3, LIP - 0.6, 0.42), (1.1, LIP - 0.7, 0.45), (0.0, LIP - 0.5, 0.38)):       # low bubbles where it lands
        res = bmesh.ops.create_icosphere(fo, subdivisions=1, radius=r)
        for v in res["verts"]: v.co.z *= 0.35; v.co += Vector((x, y, WATER + 0.05))
    for (x, y, z, r) in ((-0.9, WALL_BACK + 0.55, 2.5, 0.32), (1.0, WALL_BACK + 0.65, 2.52, 0.3)):  # a little splash where the chute meets the wall
        res = bmesh.ops.create_icosphere(fo, subdivisions=1, radius=r)
        for v in res["verts"]: v.co.z *= 0.4; v.co += Vector((x, y, z))
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
    objs = build_falls()
    export(objs, os.path.join(OUT, "canal_falls.fbx"))
    log(f"canal_falls.fbx: {len(objs)} meshes, {sum(tris(o) for o in objs)} tris; " + ", ".join(f"{o.name} {tris(o)}" for o in objs))
    pts = [o.matrix_world @ v.co for o in objs for v in o.data.vertices]
    rb = [(p.x, p.z, -p.y) for p in pts]
    info = {"canal_falls": {"min": [round(min(q[i] for q in rb), 3) for i in range(3)], "max": [round(max(q[i] for q in rb), 3) for i in range(3)]}}
    for o in objs:
        q = [(p.x, p.z, -p.y) for p in [o.matrix_world @ v.co for v in o.data.vertices]]
        info["canal_falls/" + o.name] = {"min": [round(min(a[i] for a in q), 3) for i in range(3)], "max": [round(max(a[i] for a in q), 3) for i in range(3)]}
    json.dump(info, open(os.path.join(OUT, "pieces.json"), "w"), indent=1)
    log("BBOX " + json.dumps(info))
    emp = bpy.data.objects.new("canal_falls", None); bpy.context.scene.collection.objects.link(emp)
    for o in objs:
        mw = o.matrix_world.copy(); o.parent = emp; o.matrix_world = mw
    export([emp] + objs, os.path.join(OUT, "japan_falls_kit.fbx"))
    log("FBX_DONE")
    # ---------- previews: with a stand-in end wall (coping) and side walls, lawn and canal water ----------
    sc = bpy.context.scene
    def slab(name, c, s, col):
        bpy.ops.mesh.primitive_cube_add(size=1, location=c); o = bpy.context.active_object; o.name = name; o.scale = s
        m = bpy.data.materials.new(name); m.use_nodes = True
        m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (lin(col[0]), lin(col[1]), lin(col[2]), 1)
        o.data.materials.append(m); return o
    slab("Lawn", (0, 30, -0.05), (120, 50, 0.1), (0.36, 0.62, 0.30))
    slab("Water", (0, -25, WATER - 0.01), (25, 50, 0.02), (0.16, 0.41, 0.44))
    slab("EndWall", (0, 2.3, (COPE - 1.2) / 2), (25, 4.6, COPE + 1.2), (0.55, 0.47, 0.40))
    slab("Coping", (0, 2.15, COPE - 0.2), (25.6, 5.2, 0.45), (0.66, 0.65, 0.61))
    for x in (-14.8, 14.8):
        slab("SideWall", (x, -25, (COPE - 1.2) / 2), (4.6, 50, COPE + 1.2), (0.55, 0.47, 0.40))
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
    shot("prev_falls_from_canal.png", (0, -16, 4.5), (0, 4, 2.8))          # from a bridge/boat in the canal
    shot("prev_falls_three_quarter.png", (-12, -12, 7), (0, 5, 2.5))
    shot("prev_falls_from_lawn.png", (16, 18, 8), (0, 6, 2.5))
    log("RENDER_DONE")
except Exception:
    log(traceback.format_exc()); log("FBX_FAILED")
