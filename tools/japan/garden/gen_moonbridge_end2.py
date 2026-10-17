"""Moon bridge ends, round 2 (runner 7, Oct 17 2026). Round 1 (gen_moonbridge_end.py: a white cut-stone landing, white steps and capped
cheek walls, lanterns in front) - Shannon: "that looks really bad", "really really bad". Round 2 keeps to the bridge's OWN look: the deck
carries on down to the court as wooden steps in the deck's planks, red side boards (stringers) and the red handrails run down to a pair
of red posts at the foot, and the only stone is dark grey and low: a footing under the deck end (meeting the pond wall's ledge) and a
sill where the steps meet the court. No white, no lanterns.
Local frame (as round 1): Roblox x across the bridge, y up from the court (world 3.10), z OUTWARD from the deck end (0 = the deck end,
top 1.92); Blender X = x, Blender -Y = z, Blender Z = y. The bridge's rails and posts stand at x +-4.3; its deck is 9 wide.
  moon_bridge_end2  MB2_Wood    three solid steps (risers 0.48, treads 1.4 deep: tops 1.44 / 0.96 / 0.48), x +-4.5 - Studio: WoodPlanks
                                in the deck's colour (103, 72, 48)
                    MB2_Red     the side boards along the steps, two posts each side (one at the deck end, 0.44 square around the
                                bridge's own end post where there is one; one at the foot), handrail + lower rail between them - Studio:
                                Wood (179, 54, 31), the bridge's red
                    MB2_Stone   the footing under the deck end (z -2.1..0, its top under the deck's underside) and the sill at the foot
                                (z 4.2..5.4) - Studio: Slate, dark grey (0.34, 0.33, 0.32)
  (the gold giboshi on the posts is kit15's post_finial)
Writes out_moonbridge2/japan_kit16_moonbridge_end2.fbx (Empty moon_bridge_end2), pieces.json, gen_log.txt."""
import bpy, bmesh, math, os, json, traceback
from mathutils import Vector
D = os.path.dirname(os.path.abspath(__file__))
OUT = os.environ.get("GARDEN_OUT") or os.path.join(D, "out_moonbridge2")
os.makedirs(OUT, exist_ok=True)
LOG = os.path.join(OUT, "gen_log.txt")
def log(m): open(LOG, "a").write(str(m) + "\n"); print(m)
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
COL = {"MB2_Wood": (0.40, 0.28, 0.19), "MB2_Red": (0.70, 0.21, 0.12), "MB2_Stone": (0.34, 0.33, 0.32)}
UV_STUDS = 6.0
def material(key):
    m = bpy.data.materials.get(key)
    if m: return m
    m = bpy.data.materials.new(key); m.use_nodes = True
    c = COL[key]; bs = m.node_tree.nodes["Principled BSDF"]
    bs.inputs["Base Color"].default_value = (lin(c[0]), lin(c[1]), lin(c[2]), 1); bs.inputs["Roughness"].default_value = 0.8
    m.diffuse_color = (lin(c[0]), lin(c[1]), lin(c[2]), 1)
    return m
def P(x, y, z): return (x, -z, y)
def hull(bm, pts):
    vs = [bm.verts.new(P(*p)) for p in pts]
    bmesh.ops.convex_hull(bm, input=vs)
def box(bm, x0, x1, y0, y1, z0, z1): hull(bm, [(x, y, z) for x in (x0, x1) for y in (y0, y1) for z in (z0, z1)])
def bar(bm, a, b, w, h):
    """a bar of w (across, x) by h (up) from point a to point b (local x, y, z), its cross-section kept upright"""
    x = a[0]
    pts = []
    for (yy, zz) in ((a[1], a[2]), (b[1], b[2])):
        for dx in (-w / 2, w / 2):
            for dy in (-h / 2, h / 2): pts.append((x + dx, yy + dy, zz))
    hull(bm, pts)
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
POST_X, POST_W = 4.3, 0.44
UP_Z, UP_Y0, UP_Y1 = 0.0, 1.6, 5.15          # the post at the deck end: 0.54 square, z -0.27..0.27, so it fully encloses the bridge's own end post
                                               # (world 4.8..8.2 -> 1.7..5.1, x 4.1..4.5, z -0.15..0.25) with no shared face
FOOT_Z, FOOT_Y1 = 4.45, 3.3                    # the post at the foot
def build():
    objs = []
    bm = bmesh.new()
    for i, top in enumerate((1.44, 0.96, 0.48)):
        box(bm, -4.5, 4.5, -0.3, top, i * 1.4, (i + 1) * 1.4)
    objs.append(finish("MB2_Wood", "MB2_Wood", bm))
    bm = bmesh.new()
    for s in (1, -1):
        xo0, xo1 = sorted((s * 4.5, s * 4.78))
        hull(bm, [(x, y, z) for x in (xo0, xo1) for (y, z) in ((2.2, -0.15), (0.2, 4.35), (-0.25, 4.35), (1.25, -0.15))])   # the side board
        x = s * POST_X
        box(bm, x - 0.27, x + 0.27, UP_Y0, UP_Y1, UP_Z - 0.27, UP_Z + 0.27)                                                   # post at the deck end
        box(bm, x - POST_W / 2, x + POST_W / 2, -0.25, FOOT_Y1, FOOT_Z - POST_W / 2, FOOT_Z + POST_W / 2)                  # post at the foot
        bar(bm, (x, 4.85, UP_Z), (x, FOOT_Y1 - 0.25, FOOT_Z), 0.32, 0.36)                                                   # handrail
        bar(bm, (x, 2.85, UP_Z), (x, 1.35, FOOT_Z), 0.18, 0.26)                                                             # lower rail
    objs.append(finish("MB2_Red", "MB2_Red", bm))
    bm = bmesh.new()
    hull(bm, [(x, y, z) for x in (-5.0, 5.0) for (y, z) in ((-0.3, -2.1), (-0.3, 0.05), (1.5, 0.05), (2.0, -2.1))])      # footing under the deck end (the deck's underside: 1.63 at z -0.5, +0.33 a stud inward)
    box(bm, -5.0, 5.0, -0.3, 0.12, 4.2, 5.4)                                                                                 # sill at the foot
    objs.append(finish("MB2_Stone", "MB2_Stone", bm))
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
    objs = build()
    def rb(p): return [round(p[0], 3), round(p[2], 3), round(-p[1], 3)]
    q = [rb(o.matrix_world @ v.co) for o in objs for v in o.data.vertices]
    info = {"moon_bridge_end2": {"min": [min(a[i] for a in q) for i in range(3)], "max": [max(a[i] for a in q) for i in range(3)],
            "posts": {"deck_end": [POST_X, UP_Y1, UP_Z], "foot": [POST_X, FOOT_Y1, FOOT_Z]},
            "parts": {o.name: {"tris": tris(o), "min": [min(rb(v.co)[i] for v in o.data.vertices) for i in range(3)],
                               "max": [max(rb(v.co)[i] for v in o.data.vertices) for i in range(3)]} for o in objs}}}
    log(f"moon_bridge_end2: {len(objs)} meshes, {sum(tris(o) for o in objs)} tris; " + ", ".join(f"{o.name} {tris(o)}" for o in objs))
    json.dump(info, open(os.path.join(OUT, "pieces.json"), "w"), indent=1)
    log("INFO " + json.dumps({"min": info["moon_bridge_end2"]["min"], "max": info["moon_bridge_end2"]["max"]}))
    emp = bpy.data.objects.new("moon_bridge_end2", None); bpy.context.scene.collection.objects.link(emp)
    for o in objs:
        mw = o.matrix_world.copy(); o.parent = emp; o.matrix_world = mw
    export([emp] + objs, os.path.join(OUT, "japan_kit16_moonbridge_end2.fbx"))
    log("FBX_DONE")
except Exception:
    log(traceback.format_exc()); log("FBX_FAILED")
