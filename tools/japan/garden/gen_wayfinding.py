"""Japan wayfinding kit (runner 7, Oct 17 2026). Shannon chose option 3 for "the map feels too big": make the train obvious, fill the
lawns, trim the margins. These are the signs (Blender meshes only, stylised like France / Porto; the words go on in Studio as
SurfaceGuis, so nothing is uploaded):
  sign_post       a wooden fingerpost: 0.5-square post 9 tall with a chamfered cap, on a small stone footing (Post_Wood, Post_Stone)
  sign_finger     ONE finger board for it: 4.3 long x 0.8 tall x 0.12, from x 0.3 (beside the post) to the arrow tip at x 4.8, y 0..0.8;
                  a thin marker mesh Finger_Tip at the tip (the installer finds the pointing direction by it); a dark bracket strap
                  (Finger_Strap) at the post end. The installer clones it per destination, turns it, writes the words on both faces.
  nobori_banner   a tall station banner: a 12-tall pole with a top crossbar (Nobori_Pole), the cloth 1.6 wide x 7.2 tall hanging from
                  x 0.1..1.7, y 4.4..11.6 (Nobori_Cloth; indigo in Studio, white words), a stone base (Nobori_Base)
  map_board       a roofed notice board (kosatsu): two posts, a board 6.4 wide x 3.6 tall (Board_Face: the map is drawn on it as a
                  SurfaceGui), a frame (Board_Wood), a small tiled roof (Board_Roof)
All with the base at y 0. Box UVs, 6 studs a tile. No vertex colours.
Writes out_wayfinding/japan_kit18_wayfinding.fbx (Empties sign_post, sign_finger, nobori_banner, map_board), pieces.json, gen_log.txt."""
import bpy, bmesh, math, os, json, traceback
from mathutils import Vector
D = os.path.dirname(os.path.abspath(__file__))
OUT = os.environ.get("GARDEN_OUT") or os.path.join(D, "out_wayfinding")
os.makedirs(OUT, exist_ok=True)
LOG = os.path.join(OUT, "gen_log.txt")
def log(m): open(LOG, "a").write(str(m) + "\n"); print(m)
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
COL = {"Post_Wood": (0.30, 0.21, 0.14), "Post_Stone": (0.45, 0.44, 0.42), "Finger_Board": (0.60, 0.44, 0.27), "Finger_Tip": (0.60, 0.44, 0.27),
       "Finger_Strap": (0.18, 0.17, 0.16), "Nobori_Pole": (0.52, 0.56, 0.34), "Nobori_Cloth": (0.16, 0.20, 0.45), "Nobori_Base": (0.40, 0.39, 0.37),
       "Board_Wood": (0.30, 0.21, 0.14), "Board_Face": (0.88, 0.82, 0.68), "Board_Roof": (0.24, 0.24, 0.27)}
UV_STUDS = 6.0
def material(key):
    m = bpy.data.materials.get(key)
    if m: return m
    m = bpy.data.materials.new(key); m.use_nodes = True
    c = COL[key]; bs = m.node_tree.nodes["Principled BSDF"]
    bs.inputs["Base Color"].default_value = (lin(c[0]), lin(c[1]), lin(c[2]), 1); bs.inputs["Roughness"].default_value = 0.8
    m.diffuse_color = (lin(c[0]), lin(c[1]), lin(c[2]), 1)
    return m
def P(x, y, z): return (x, -z, y)                                   # local (x, y up, z) -> Blender
def hull(bm, pts):
    vs = [bm.verts.new(P(*p)) for p in pts]
    bmesh.ops.convex_hull(bm, input=vs)
def box(bm, x0, x1, y0, y1, z0, z1): hull(bm, [(x, y, z) for x in (x0, x1) for y in (y0, y1) for z in (z0, z1)])
def finish(name, key, bm):
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
    bm.normal_update()
    uv = bm.loops.layers.uv.new("UVMap")
    for f in bm.faces:
        n = f.normal; ax = max(range(3), key=lambda i: abs(n[i]))
        for l in f.loops:
            c = l.vert.co
            u, v = ((c.y, c.z), (c.x, c.z), (c.x, c.y))[ax]
            l[uv].uv = (u / UV_STUDS, v / UV_STUDS)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o)
    me.materials.append(material(key))
    for p in me.polygons: p.use_smooth = False
    return o
def tris(o): return sum(len(p.vertices) - 2 for p in o.data.polygons)
def build_post():
    objs = []
    bm = bmesh.new()
    box(bm, -0.25, 0.25, 0.0, 9.0, -0.25, 0.25)
    hull(bm, [(x, 9.0, z) for x in (-0.3, 0.3) for z in (-0.3, 0.3)] + [(x, 9.35, z) for x in (-0.12, 0.12) for z in (-0.12, 0.12)])   # the cap
    objs.append(finish("Post_Wood", "Post_Wood", bm))
    bm = bmesh.new(); hull(bm, [(x, -0.3, z) for x in (-0.6, 0.6) for z in (-0.6, 0.6)] + [(x, 0.35, z) for x in (-0.45, 0.45) for z in (-0.45, 0.45)])
    objs.append(finish("Post_Stone", "Post_Stone", bm))
    return objs
def build_finger():
    objs = []
    bm = bmesh.new()
    hull(bm, [(x, y, z) for x in (0.3, 4.3) for y in (0.0, 0.8) for z in (-0.06, 0.06)] + [(4.8, 0.4, z) for z in (-0.06, 0.06)])   # the board with its arrow tip
    objs.append(finish("Finger_Board", "Finger_Board", bm))
    bm = bmesh.new(); box(bm, 4.6, 4.8, 0.3, 0.5, -0.07, 0.07); objs.append(finish("Finger_Tip", "Finger_Tip", bm))
    bm = bmesh.new(); box(bm, 0.0, 0.42, 0.1, 0.7, -0.09, 0.09); objs.append(finish("Finger_Strap", "Finger_Strap", bm))
    return objs
def build_nobori():
    objs = []
    bm = bmesh.new()
    box(bm, -0.13, 0.13, 0.0, 12.0, -0.13, 0.13)
    box(bm, -0.1, 1.9, 11.6, 11.78, -0.09, 0.09)                     # the top crossbar the cloth hangs from
    hull(bm, [(x, 12.0, z) for x in (-0.2, 0.2) for z in (-0.2, 0.2)] + [(0, 12.5, 0)])   # the pole's point
    objs.append(finish("Nobori_Pole", "Nobori_Pole", bm))
    bm = bmesh.new(); box(bm, 0.1, 1.7, 4.4, 11.6, -0.03, 0.03); objs.append(finish("Nobori_Cloth", "Nobori_Cloth", bm))
    bm = bmesh.new(); hull(bm, [(x, -0.3, z) for x in (-0.55, 0.55) for z in (-0.55, 0.55)] + [(x, 0.5, z) for x in (-0.35, 0.35) for z in (-0.35, 0.35)])
    objs.append(finish("Nobori_Base", "Nobori_Base", bm))
    return objs
def build_board():
    objs = []
    bm = bmesh.new()
    for x in (-3.0, 3.0): box(bm, x - 0.22, x + 0.22, -0.3, 7.6, -0.22, 0.22)                       # the posts
    box(bm, -3.4, 3.4, 3.2, 3.5, -0.3, 0.3); box(bm, -3.4, 3.4, 7.1, 7.4, -0.3, 0.3)              # rails under and over the board
    box(bm, -3.4, -3.15, 3.2, 7.4, -0.3, 0.3); box(bm, 3.15, 3.4, 3.2, 7.4, -0.3, 0.3)           # the frame's sides
    objs.append(finish("Board_Wood", "Board_Wood", bm))
    bm = bmesh.new(); box(bm, -3.2, 3.2, 3.5, 7.1, -0.12, 0.12); objs.append(finish("Board_Face", "Board_Face", bm))
    bm = bmesh.new()
    hull(bm, [(x, 7.4, z) for x in (-3.9, 3.9) for z in (-1.3, 1.3)] + [(x, 8.4, z) for x in (-3.9, 3.9) for z in (-0.12, 0.12)])   # the little roof, a ridge along x
    objs.append(finish("Board_Roof", "Board_Roof", bm))
    return objs
def export(objs, path):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, axis_forward="-Z", axis_up="Y", apply_scale_options="FBX_SCALE_ALL",
                             add_leaf_bones=False, bake_space_transform=True, object_types={"EMPTY", "MESH"})
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    pieces = {"sign_post": build_post(), "sign_finger": build_finger(), "nobori_banner": build_nobori(), "map_board": build_board()}
    def rb(p): return [round(p[0], 3), round(p[2], 3), round(-p[1], 3)]
    info = {}
    for name, objs in pieces.items():
        q = [rb(o.matrix_world @ v.co) for o in objs for v in o.data.vertices]
        info[name] = {"min": [min(a[i] for a in q) for i in range(3)], "max": [max(a[i] for a in q) for i in range(3)],
                      "parts": {o.name: {"tris": tris(o), "min": [min(rb(v.co)[i] for v in o.data.vertices) for i in range(3)],
                                         "max": [max(rb(v.co)[i] for v in o.data.vertices) for i in range(3)]} for o in objs}}
        log(f"{name}: {len(objs)} meshes, {sum(tris(o) for o in objs)} tris; " + ", ".join(f"{o.name} {tris(o)}" for o in objs))
    json.dump(info, open(os.path.join(OUT, "pieces.json"), "w"), indent=1)
    log("INFO " + json.dumps({k: {"min": v["min"], "max": v["max"]} for k, v in info.items()}))
    allobjs = []
    x = 0.0
    for name, objs in pieces.items():
        emp = bpy.data.objects.new(name, None); bpy.context.scene.collection.objects.link(emp)
        for o in objs:
            mw = o.matrix_world.copy(); o.parent = emp; o.matrix_world = mw
        emp.location.x = x; x += 16.0
        allobjs += [emp] + objs
    export(allobjs, os.path.join(OUT, "japan_kit18_wayfinding.fbx"))
    log("FBX_DONE")
except Exception:
    log(traceback.format_exc()); log("FBX_FAILED")
