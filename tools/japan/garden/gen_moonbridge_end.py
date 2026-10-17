"""Moon bridge ends at the palace pond (runner 7, Oct 17 2026). Shannon: "you fixed the palace pond but did not fix the entrances of the
bridge going across please fix it and make it look nice and complete". Each end of the Vermilion moon bridge just stopped: its last
plank came down (top 5.02) onto a plain pavement slab (top 4.15) on the court (~3.1), the red end posts stood on nothing.
Pieces (1 = 1 stud; local frame: Roblox x across the bridge, Roblox y up from the court (world 3.10), Roblox z OUTWARD from the deck
end (0 = the deck end, negative = under the bridge toward the pond); Blender X = x, Blender -Y = z, Blender Z = y):
  moon_bridge_end   MB_Stone   the abutment in the pond wall's flagstone (Studio: Pavement + JM_PhotographicPath, white): a block
                               under the landing (z -0.3..2.6, top 1.62) and a wedge up under the deck toward the pond (z -2.5..-0.3,
                               its top following the deck's underside 1.60 -> 2.25) that meets the pond wall's ledge (r 40.5)
                    MB_Cap     the landing slab in the coping's cut stone, top 1.92 = flush with the deck end (5.02), 0.2 proud
                    MB_Steps   two cut-stone steps (risers 0.64: treads 1.28 and 0.64, 1.1 deep) down to the court, x +-4.5
                    MB_Cheek   low side walls flanking the steps (flagstone), sloping 1.92 -> 0.55, with MB_CheekCap (cut stone) on top
  post_finial       MB_Finial  a giboshi (onion finial) for the red end posts: collar, bulb, point; 0.62 across, 1.0 tall
No vertex colours; box UVs, 6 studs per tile (a Studio material tiles over them).
Writes out_moonbridge/japan_kit15_moonbridge_end.fbx (Empties moon_bridge_end, post_finial), pieces.json, gen_log.txt, prev_*.png."""
import bpy, bmesh, math, os, json, traceback
from mathutils import Vector
D = os.path.dirname(os.path.abspath(__file__))
OUT = os.environ.get("GARDEN_OUT") or os.path.join(D, "out_moonbridge")
os.makedirs(OUT, exist_ok=True)
LOG = os.path.join(OUT, "gen_log.txt")
def log(m): open(LOG, "a").write(str(m) + "\n"); print(m)
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
COL = {"MB_Stone": (0.56, 0.55, 0.51), "MB_Cap": (0.66, 0.65, 0.61), "MB_Steps": (0.63, 0.62, 0.58), "MB_Cheek": (0.56, 0.55, 0.51),
       "MB_CheekCap": (0.66, 0.65, 0.61), "MB_Finial": (0.80, 0.63, 0.28)}
UV_STUDS = 6.0
def material(key):
    m = bpy.data.materials.get(key)
    if m: return m
    m = bpy.data.materials.new(key); m.use_nodes = True
    c = COL[key]; bs = m.node_tree.nodes["Principled BSDF"]
    bs.inputs["Base Color"].default_value = (lin(c[0]), lin(c[1]), lin(c[2]), 1); bs.inputs["Roughness"].default_value = 0.8
    m.diffuse_color = (lin(c[0]), lin(c[1]), lin(c[2]), 1)
    return m
def P(x, y, z): return (x, -z, y)                      # local (x, y up, z outward) -> Blender
def hull(bm, pts):
    vs = [bm.verts.new(P(*p)) for p in pts]
    bmesh.ops.convex_hull(bm, input=vs)
def box(bm, x0, x1, y0, y1, z0, z1): hull(bm, [(x, y, z) for x in (x0, x1) for y in (y0, y1) for z in (z0, z1)])
def finish(name, key, bm, smooth=False):
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
    for p in me.polygons: p.use_smooth = smooth
    return o
def tris(o): return sum(len(p.vertices) - 2 for p in o.data.polygons)
LAND = 1.92                                             # the deck end's top above the court
def build_end():
    objs = []
    bm = bmesh.new()
    box(bm, -5.4, 5.4, -0.3, 1.62, -0.3, 2.6)                                                     # under the landing
    hull(bm, [(x, y, z) for x in (-5.4, 5.4) for (y, z) in ((-0.3, -2.5), (-0.3, -0.3), (1.62, -0.3), (2.25, -2.5))])   # the wedge under the deck
    objs.append(finish("MB_Stone", "MB_Stone", bm))
    bm = bmesh.new(); box(bm, -5.6, 5.6, 1.62, LAND, -0.3, 2.8); objs.append(finish("MB_Cap", "MB_Cap", bm))
    bm = bmesh.new()
    box(bm, -4.5, 4.5, -0.3, 1.28, 2.75, 3.85)                                                    # tread 1.28
    box(bm, -4.5, 4.5, -0.3, 0.64, 3.85, 4.95)                                                    # tread 0.64; the court beyond
    objs.append(finish("MB_Steps", "MB_Steps", bm))
    bm = bmesh.new(); cap = bmesh.new()
    for s in (1, -1):
        x0, x1 = sorted((s * 4.5, s * 5.6))
        hull(bm, [(x, y, z) for x in (x0, x1) for (y, z) in ((-0.3, 2.6), (-0.3, 5.1), (0.4, 5.1), (1.62, 2.6))])
        hull(cap, [(x, y, z) for x in (x0 - 0.06, x1 + 0.06) for (y, z) in ((1.62, 2.6), (1.82, 2.6), (0.6, 5.2), (0.4, 5.2))])
    objs.append(finish("MB_Cheek", "MB_Cheek", bm))
    objs.append(finish("MB_CheekCap", "MB_CheekCap", cap))
    return objs
def build_finial():
    """a lathe: (radius, height) from the post top; 12 sides"""
    prof = [(0.0, 0.0), (0.31, 0.0), (0.31, 0.16), (0.24, 0.2), (0.24, 0.26), (0.3, 0.36), (0.33, 0.48), (0.3, 0.6), (0.2, 0.72), (0.08, 0.84), (0.03, 0.94), (0.0, 1.0)]
    bm = bmesh.new()
    S = 12
    rings = []
    for (r, h) in prof:
        if r == 0.0: rings.append([bm.verts.new(P(0, h, 0))])
        else: rings.append([bm.verts.new(P(r * math.cos(2 * math.pi * k / S), h, r * math.sin(2 * math.pi * k / S))) for k in range(S)])
    for a, b in zip(rings, rings[1:]):
        if len(a) == 1:
            for k in range(S): bm.faces.new((a[0], b[(k + 1) % S], b[k]))
        elif len(b) == 1:
            for k in range(S): bm.faces.new((a[k], a[(k + 1) % S], b[0]))
        else:
            for k in range(S): bm.faces.new((a[k], a[(k + 1) % S], b[(k + 1) % S], b[k]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return [finish("MB_Finial", "MB_Finial", bm, smooth=True)]
def export(objs, path):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, axis_forward="-Z", axis_up="Y", apply_scale_options="FBX_SCALE_ALL",
                             add_leaf_bones=False, bake_space_transform=True, object_types={"EMPTY", "MESH"})
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    pieces = {"moon_bridge_end": build_end(), "post_finial": build_finial()}
    def rb(p): return [round(p[0], 3), round(p[2], 3), round(-p[1], 3)]
    info = {}
    bad = []
    for name, objs in pieces.items():
        for o in objs:
            bm = bmesh.new(); bm.from_mesh(o.data)
            nm = sum(1 for e in bm.edges if not e.is_manifold); vol = bm.calc_volume(signed=True); bm.free()
            if nm or vol <= 0: bad.append(f"{o.name}: {nm} open edges, volume {vol:.3f}")
        q = [rb(o.matrix_world @ v.co) for o in objs for v in o.data.vertices]
        info[name] = {"min": [min(a[i] for a in q) for i in range(3)], "max": [max(a[i] for a in q) for i in range(3)],
                      "parts": {o.name: {"tris": tris(o), "min": [min(rb(v.co)[i] for v in o.data.vertices) for i in range(3)],
                                         "max": [max(rb(v.co)[i] for v in o.data.vertices) for i in range(3)]} for o in objs}}
        log(f"{name}: {len(objs)} meshes, {sum(tris(o) for o in objs)} tris; " + ", ".join(f"{o.name} {tris(o)}" for o in objs))
    log(f"closed / outward: {bad if bad else 'all'}")
    json.dump(info, open(os.path.join(OUT, "pieces.json"), "w"), indent=1)
    log("INFO " + json.dumps({k: {"min": v["min"], "max": v["max"]} for k, v in info.items()}))
    allobjs = []
    x = 0.0
    for name, objs in pieces.items():
        emp = bpy.data.objects.new(name, None); bpy.context.scene.collection.objects.link(emp)
        for o in objs:
            mw = o.matrix_world.copy(); o.parent = emp; o.matrix_world = mw
        emp.location.x = x; x += 20.0
        allobjs += [emp] + objs
    export(allobjs, os.path.join(OUT, "japan_kit15_moonbridge_end.fbx"))
    log("FBX_DONE")
except Exception:
    log(traceback.format_exc()); log("FBX_FAILED")
