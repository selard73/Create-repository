"""Moon bridge ends, round 3 (runner 7, Oct 17 2026). Round 2 (a straight wooden stair with its own posts) - Shannon, watching:
"that is better but its still got issues ... look at how other japanese bridges are designed, be smart please".
How a taiko-bashi ends: the ARCH ITSELF runs on down to the ground (no separate stair), the curved red rails run with it, the heavy
end posts (oyabashira) stand at the foot and are the only posts with gold giboshi, and a dark fitted-stone abutment (kyodai) fills
under the end of the arch. So this piece CONTINUES the bridge's own deck (9 wide, 0.4 thick, WoodPlanks; the end segment slopes 18.1
deg and stops 1.92 above the court) on the same curve down to the court:
  MB3_Deck   two more deck segments: 4.5 long at 18.6 deg (the arc steepening as it does), then 1.73 long at 16.4 deg easing onto the
             court (top 0.02 at z 5.93); a 0.5-deep end beam under the foot
  MB3_Red    the handrail (0.4 square, 2.95 above the deck) and lower rail (0.2, 1.2 above) along both segments each side at x +-4.3;
             a plain post at the joint (0.44 sq) and one at the old deck end (0.54 sq: encloses the bridge's own end post where there
             is one, no shared face); the heavy end posts at the foot (0.6 sq, z 5.3..5.9, up to 3.55)
  MB3_Stone  the abutment: dark fitted stone filling under the extension (x +-4.4, from the footing behind the old deck end out to
             the foot, its top 0.05 under the deck's underside), and a sill at the foot (z 5.5..7.0, -0.35..0.1) that sits into the
             pond apron's edge bevel. Studio: Slate, 58 / 56 / 54.
  (gold giboshi = kit15's post_finial, on the two end posts per end only)
Local frame: x across, y up from the court (3.19 = the pond apron), z OUTWARD from the old deck end (top 1.92 at z 0).
Writes out_moonbridge3/japan_kit17_moonbridge_end3.fbx (Empty moon_bridge_end3), pieces.json, gen_log.txt."""
import bpy, bmesh, math, os, json, traceback
from mathutils import Vector
D = os.path.dirname(os.path.abspath(__file__))
OUT = os.environ.get("GARDEN_OUT") or os.path.join(D, "out_moonbridge3")
os.makedirs(OUT, exist_ok=True)
LOG = os.path.join(OUT, "gen_log.txt")
def log(m): open(LOG, "a").write(str(m) + "\n"); print(m)
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
COL = {"MB3_Deck": (0.40, 0.28, 0.19), "MB3_Red": (0.70, 0.21, 0.12), "MB3_Stone": (0.23, 0.22, 0.21)}
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
def slab(bm, x0, x1, y_at_z0, z0, y_at_z1, z1, thick):
    """a sloped slab (deck segment / rail bar) with vertical ends; its top runs from (z0, y_at_z0) to (z1, y_at_z1)"""
    hull(bm, [(x, y, z) for x in (x0, x1) for (y, z) in ((y_at_z0, z0), (y_at_z0 - thick, z0), (y_at_z1, z1), (y_at_z1 - thick, z1))])
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
# the deck line: (z, top) at the old deck end, the joint, the foot
A1, L1 = math.radians(18.6), 4.5
Z0, Y0 = 0.0, 1.92
Z1, Y1 = L1 * math.cos(A1), Y0 - L1 * math.sin(A1)
Z2, Y2 = 5.93, 0.02
DECK_T = 0.4
RAIL_X, HAND_H, LOW_H = 4.3, 2.95, 1.2
END_Z, END_TOP = 5.6, 3.55
def deck_top(z):
    if z <= Z1: return Y0 + (Y1 - Y0) * (z - Z0) / (Z1 - Z0)
    return Y1 + (Y2 - Y1) * (z - Z1) / (Z2 - Z1)
def build():
    objs = []
    bm = bmesh.new()
    slab(bm, -4.5, 4.5, Y0, Z0 - 0.02, Y1, Z1, DECK_T)
    slab(bm, -4.5, 4.5, Y1, Z1 - 0.02, Y2, Z2, DECK_T)
    box(bm, -4.5, 4.5, -0.3, Y2 - DECK_T + 0.02, Z2 - 0.5, Z2)                                   # the end beam under the foot
    objs.append(finish("MB3_Deck", "MB3_Deck", bm))
    bm = bmesh.new()
    for s in (1, -1):
        x = s * RAIL_X
        for (h, t) in ((HAND_H, 0.4), (LOW_H, 0.2)):
            slab(bm, x - t / 2, x + t / 2, Y0 + h + t / 2, Z0, Y1 + h + t / 2, Z1 + 0.1, t)
            slab(bm, x - t / 2, x + t / 2, Y1 + h + t / 2, Z1 - 0.1, deck_top(END_Z) + h + t / 2, END_Z, t)
        box(bm, x - 0.27, x + 0.27, 1.6, Y0 + HAND_H + 0.25, -0.2, 0.3)                              # at the old deck end (encloses the bridge's own)
        box(bm, x - 0.22, x + 0.22, Y1 - 0.15, Y1 + HAND_H + 0.22, Z1 - 0.22, Z1 + 0.22)             # at the joint
        box(bm, x - 0.3, x + 0.3, -0.35, END_TOP, END_Z - 0.3, END_Z + 0.3)                           # the heavy end post
    objs.append(finish("MB3_Red", "MB3_Red", bm))
    bm = bmesh.new()
    # the abutment under the extension: its top 0.05 under the deck's underside, from the footing behind the old end to the foot
    us = lambda z: deck_top(z) - DECK_T - 0.05
    hull(bm, [(x, y, z) for x in (-4.4, 4.4) for (y, z) in ((-0.3, -2.1), (2.0, -2.1), (us(0.0), 0.0), (-0.3, 0.0))])
    hull(bm, [(x, y, z) for x in (-4.4, 4.4) for (y, z) in ((-0.3, 0.0), (us(0.0), 0.0), (us(Z1), Z1), (-0.3, Z1))])
    hull(bm, [(x, y, z) for x in (-4.4, 4.4) for (y, z) in ((-0.3, Z1), (us(Z1), Z1), (max(us(Z2 - 0.5), -0.2), Z2 - 0.5), (-0.3, Z2 - 0.5))])
    box(bm, -4.9, 4.9, -0.35, 0.1, 5.5, 7.0)                                                           # the sill at the foot
    objs.append(finish("MB3_Stone", "MB3_Stone", bm))
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
    info = {"moon_bridge_end3": {"min": [min(a[i] for a in q) for i in range(3)], "max": [max(a[i] for a in q) for i in range(3)],
            "deck_line": {"joint": [round(Z1, 3), round(Y1, 3)], "foot": [Z2, Y2]}, "end_posts": [[RAIL_X, END_TOP, END_Z], [-RAIL_X, END_TOP, END_Z]],
            "parts": {o.name: {"tris": tris(o), "min": [min(rb(v.co)[i] for v in o.data.vertices) for i in range(3)],
                               "max": [max(rb(v.co)[i] for v in o.data.vertices) for i in range(3)]} for o in objs}}}
    log(f"moon_bridge_end3: {len(objs)} meshes, {sum(tris(o) for o in objs)} tris; " + ", ".join(f"{o.name} {tris(o)}" for o in objs))
    log(f"deck line: joint z {Z1:.2f} top {Y1:.2f}; foot z {Z2} top {Y2}")
    json.dump(info, open(os.path.join(OUT, "pieces.json"), "w"), indent=1)
    log("INFO " + json.dumps({"min": info["moon_bridge_end3"]["min"], "max": info["moon_bridge_end3"]["max"]}))
    emp = bpy.data.objects.new("moon_bridge_end3", None); bpy.context.scene.collection.objects.link(emp)
    for o in objs:
        mw = o.matrix_world.copy(); o.parent = emp; o.matrix_world = mw
    export([emp] + objs, os.path.join(OUT, "japan_kit17_moonbridge_end3.fbx"))
    log("FBX_DONE")
except Exception:
    log(traceback.format_exc()); log("FBX_FAILED")
