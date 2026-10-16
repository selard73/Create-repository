"""Bridge ends r2 (cloud, Oct 16 2026). Shannon circled two slots at a taiko bridge's end: canalfix1 raised every bridge 1.6 and stretched
its landings (x2.6) to meet the higher deck, which turned two thin gaps into full-height slits and the steps into 1.3-tall blocks:
  * landing <-> the bridge's stone footing: the landing starts at the red beam's tip (20.232 from the bridge centre), the footing ends
    at 20.1 - a 0.13 slit, now 2.1 tall (the green shows through)
  * footing <-> canal wall: the footing starts at 17.5, the wall's lawn face is at 16.5 (coping 16.8) - a 0.7..1.0 slot under the beam
One piece per bridge end replaces the stretched landing: a stone ABUTMENT from inside the wall (16.15) to the deck end, with a coping cap
at 2.18 (0.08 over the wall's coping) - the bridge's beams now rest on it - and proper STEPS from the deck end down to the lawn: a top
tread flush with the deck end (2.3) and 3 more risers of 0.575 (was 1.3 + 1.3), the foot where the old one was (23.25), so the
stepping-stone paths still start at it. The old footing (Bridge_Stone) ends up hidden inside (sides 0.05 in from every face).
Meshes (installer keys): Abut_Stone (the wall's flagstone: Pavement + JM_PhotographicPath), Abut_Coping (the wall coping's stone),
Abut_Steps (the landings' stone). Units 1 = 1 stud, Z up. ORIGIN = the DECK END (20 out from the bridge centre) at lawn level, x OUTWARD,
y across the bridge. Writes out_bridge_end/bridge_end.fbx, japan_bridge_end_kit.fbx (one Empty "bridge_end"), pieces.json and
prev_bridge_end_*.png - before (the raised bridge + stretched landing, as in her picture) and after, with the real bridge and wall kit.
Run: blender -b --python gen_bridge_end.py   (or python with the bpy module)"""
import bpy, bmesh, math, os, json, traceback
from mathutils import Vector, Matrix
D = os.path.dirname(os.path.abspath(__file__))
OUT = os.environ.get("GARDEN_OUT") or os.path.join(D, "out_bridge_end")
os.makedirs(OUT, exist_ok=True)
LOG = os.path.join(OUT, "gen_log.txt")
def log(m): open(LOG, "a").write(str(m) + "\n"); print(m)
COL = {"Abut_Stone": (0.56, 0.55, 0.51), "Abut_Coping": (0.66, 0.65, 0.61), "Abut_Steps": (0.63, 0.62, 0.58)}
UV_STUDS = 6.0
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
def material(key, col=None):
    m = bpy.data.materials.get(key)
    if m: return m
    m = bpy.data.materials.new(key); m.use_nodes = True
    c = col or COL[key]; bs = m.node_tree.nodes["Principled BSDF"]
    bs.inputs["Base Color"].default_value = (lin(c[0]), lin(c[1]), lin(c[2]), 1); bs.inputs["Roughness"].default_value = 0.85
    m.diffuse_color = (lin(c[0]), lin(c[1]), lin(c[2]), 1)
    return m
def box_uvs(bm):
    """planar UVs per face on its dominant axis, UV_STUDS studs per tile (as gen_garden3) - the flagstone MaterialVariant tiles"""
    bm.normal_update()
    uv = bm.loops.layers.uv.new("UVMap")
    for f in bm.faces:
        n = f.normal; ax = max(range(3), key=lambda i: abs(n[i]))
        for l in f.loops:
            c = l.vert.co
            u, v = ((c.y, c.z), (c.x, c.z), (c.x, c.y))[ax]
            l[uv].uv = (u / UV_STUDS, v / UV_STUDS)
def obj_from_bm(name, bm, mat=None):
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
    box_uvs(bm)
    me = bpy.data.meshes.new(name); bm.normal_update(); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o)
    me.materials.append(mat or material(name))
    for p in me.polygons: p.use_smooth = False
    return o
def tris(o): return sum(len(p.vertices) - 2 for p in o.data.polygons)
def box(bm, x0, x1, y0, y1, z0, z1):
    b = [bm.verts.new(v) for v in [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0)]]
    t = [bm.verts.new(v) for v in [(x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)]]
    for i in range(4):
        k = (i + 1) % 4; bm.faces.new([b[i], b[k], t[k], t[i]])
    bm.faces.new(list(reversed(b))); bm.faces.new(t)
# the bridge (gen_garden1: L2 20, W2 4; placed at 0.7, raised 1.6 by canalfix1) and the canal (walls' water faces 12.5 out, 4 deep,
# coping 0.3 over each face, top 2.1), measured from the bridge centre; the piece's x = that minus 20
DECK_TOP = 2.3           # the deck end's top (arch 0 + 0.7 + 1.6); its top corner is at 19.86 (2.27), the beam tips at 20.232
GROUND = -0.6
ABUT_X0 = 16.15 - 20.0   # 0.35 into the wall body behind its lawn face (16.5), under its coping (to 16.8)
STEP_X0 = -0.10          # the top tread reaches over the deck end's corner, clear of the end posts (to 19.81)
RISE, TREAD, N_RISE = 0.575, 0.75, 3
TOP_TREAD = 1.10
def build():
    st, cp, sp = bmesh.new(), bmesh.new(), bmesh.new()
    box(st, ABUT_X0, -0.05, -4.60, 4.60, GROUND, 1.80)                     # the abutment body (the wall's flagstone)
    box(cp, ABUT_X0 - 0.05, 0.0, -4.75, 4.75, 1.75, 2.18)                  # its coping, 0.15 proud of the body; 0.08 over the wall's coping
    x = STEP_X0 + TOP_TREAD
    box(sp, STEP_X0, x, -4.45, 4.45, -0.3, DECK_TOP)                       # the top tread, flush with the deck end
    for k in range(N_RISE):                                                # three more steps down to the lawn
        box(sp, x, x + TREAD, -4.45, 4.45, -0.3, DECK_TOP - RISE * (k + 1)); x += TREAD
    log(f"steps: the foot at {x:.2f} from the deck end ({20 + x:.2f} from the bridge centre; the old landing's foot 23.23)")
    return [obj_from_bm("Abut_Stone", st), obj_from_bm("Abut_Coping", cp), obj_from_bm("Abut_Steps", sp)]
def export(objs, path):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, axis_forward="-Z", axis_up="Y", apply_scale_options="FBX_SCALE_ALL",
                             add_leaf_bones=False, bake_space_transform=True, object_types={"EMPTY", "MESH"})
def import_piece(path, M, into):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=path, axis_forward="-Z", axis_up="Y")
    new = [o for o in bpy.data.objects if o not in before]
    for o in new:
        if o.parent is None: o.matrix_world = M @ o.matrix_world
    into += new
    return new
def place(at, rot_deg): return Matrix.Translation(Vector(at)) @ Matrix.Rotation(math.radians(rot_deg), 4, "Z")
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    objs = build()
    export(objs, os.path.join(OUT, "bridge_end.fbx"))
    log(f"bridge_end.fbx: {len(objs)} meshes, {sum(tris(o) for o in objs)} tris; " + ", ".join(f"{o.name} {tris(o)}" for o in objs))
    def rb(p): return [round(p[0], 3), round(p[2], 3), round(-p[1], 3)]
    info = {}
    for o in objs:
        q = [rb(o.matrix_world @ v.co) for v in o.data.vertices]
        info["bridge_end/" + o.name] = {"min": [min(a[i] for a in q) for i in range(3)], "max": [max(a[i] for a in q) for i in range(3)]}
    allq = [rb(o.matrix_world @ v.co) for o in objs for v in o.data.vertices]
    info["bridge_end"] = {"min": [min(a[i] for a in allq) for i in range(3)], "max": [max(a[i] for a in allq) for i in range(3)]}
    json.dump(info, open(os.path.join(OUT, "pieces.json"), "w"), indent=1)
    log("INFO " + json.dumps(info))
    emp = bpy.data.objects.new("bridge_end", None); bpy.context.scene.collection.objects.link(emp)
    for o in objs:
        mw = o.matrix_world.copy(); o.parent = emp; o.matrix_world = mw
    export([emp] + objs, os.path.join(OUT, "japan_bridge_end_kit.fbx"))
    log("FBX_DONE")
    if os.environ.get("GARDEN_NO_RENDER"): raise SystemExit
    # ---- previews: the real bridge (raised) and wall kit; the canal along y, the bridge along x, its centre at the origin ----
    sc = bpy.context.scene
    def slab(name, c, s, col, alpha=1.0):
        bpy.ops.mesh.primitive_cube_add(size=1, location=c); o = bpy.context.active_object; o.name = name; o.scale = s
        m = bpy.data.materials.new(name); m.use_nodes = True; bs = m.node_tree.nodes["Principled BSDF"]
        bs.inputs["Base Color"].default_value = (lin(col[0]), lin(col[1]), lin(col[2]), 1); bs.inputs["Alpha"].default_value = alpha
        o.data.materials.append(m); return o
    stand = []
    import_piece(os.path.join(D, "out1", "bridge.fbx"), place((0, 0, DECK_TOP), 0), stand)
    K3 = os.path.join(D, "out3")
    for k, y in enumerate((-16, -8, 0, 8, 16)):
        import_piece(os.path.join(K3, "canal_wall.fbx" if k % 2 else "canal_wall_b.fbx"), place((-12.5, y, 0), 0), stand)
        import_piece(os.path.join(K3, "canal_wall_b.fbx" if k % 2 else "canal_wall.fbx"), place((12.5, y, 0), 180), stand)
    for sx in (-1, 1): slab("Lawn", (sx * 44.75, 0, -0.05), (63.5, 80, 0.1), (0.36, 0.62, 0.30))
    slab("Bed", (0, 0, -4.05), (25, 80, 0.1), (0.20, 0.22, 0.23))
    slab("Water", (0, 0, 1.29), (25, 80, 0.02), (0.16, 0.45, 0.52), alpha=0.75)
    # her lantern by the landing (garden_look3: 24 out, 6 along) as a dark stand-in post, for scale
    for sy in (-1, 1): slab("Lantern", (24, sy * 6, 1.6), (1.0, 1.0, 3.2), (0.40, 0.40, 0.39))
    sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 24; sc.cycles.use_denoising = False
    sc.render.resolution_x, sc.render.resolution_y = 1000, 640
    sc.world = bpy.data.worlds.new("W"); sc.world.use_nodes = True
    bg = sc.world.node_tree.nodes["Background"]; bg.inputs["Color"].default_value = (lin(0.62), lin(0.80), lin(0.95), 1); bg.inputs["Strength"].default_value = 0.9
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")); sc.collection.objects.link(sun)
    sun.rotation_euler = (math.radians(45), math.radians(10), math.radians(-35)); sun.data.energy = 3.2
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam; cam.data.lens = 30
    def shot(fn, loc, target):
        cam.location = Vector(loc); d = Vector(target) - cam.location
        cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(OUT, fn); bpy.ops.render.render(write_still=True); log(f"shot {fn}")
    VIEWS = [("side", (27.5, -13.0, 2.6), (19.0, 0.0, 1.4)), ("three_quarter", (34, -20, 9), (16, 0, 2))]
    # BEFORE: as in her picture - the stretched landings (canalfix1: 0.5 / 1.0 -> 1.3 / 2.6), the tall part against the beam tips
    old = []
    for sx in (-1, 1):
        bm = bmesh.new()
        box(bm, 20.232, 21.682, -4.4, 4.4, 0.0, 2.6); box(bm, 21.632, 23.232, -4.4, 4.4, 0.0, 1.3)
        if sx < 0: bmesh.ops.scale(bm, vec=(-1, 1, 1), verts=bm.verts); bmesh.ops.reverse_faces(bm, faces=bm.faces)
        old.append(obj_from_bm("OldLanding", bm, material("OldLanding", COL["Abut_Steps"])))
    for o in objs: o.hide_render = True
    emp.hide_render = True
    for n, loc, tgt in VIEWS: shot(f"prev_bridge_end_{n}_BEFORE.png", loc, tgt)
    # AFTER: the new piece at both ends (the west one turned round)
    for o in old: o.hide_render = True
    after = []
    for sx, rot in ((1, 0), (-1, 180)):
        import_piece(os.path.join(OUT, "japan_bridge_end_kit.fbx"), place((sx * 20.0, 0, 0), rot), after)
    for n, loc, tgt in VIEWS: shot(f"prev_bridge_end_{n}_AFTER.png", loc, tgt)
    shot("prev_bridge_end_from_the_bridge_AFTER.png", (14, -1.0, 8.8), (23, 0, 0.3))
    log("RENDER_DONE")
except SystemExit:
    pass
except Exception:
    log(traceback.format_exc()); log("FBX_FAILED")
