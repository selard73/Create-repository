"""The palace koi pond done the canal's way (runner 7, Oct 17 2026). Shannon: "fix the pond by the royal palace the same way we
fixed this waterway". The canal got cut-stone walls in the palace flagstone with a cut-stone coping, a flat dark bed, clear teal
water and koi swimming under the surface. The pond had a rounded rock rim (JP_Koi_Pond_Shore, ~6-8 wide, out to r ~48.7) over a
ragged hole in the court mesh, a sand bowl down to -12, and part koi floating ON the water.
This builds ONE ring, centred on the origin (the installer puts the origin at the pond's centre (6322, 0, 21.5); heights are world
heights: Blender z = Roblox y; the water surface stays at 3.9):
  Wall_Stone_k   (k = 0..7, one per 45 deg) the pond wall: water face at r 32.0 from y -0.6 (in the bed) to 4.3, an 8.5-thick body to
                 r 40.5, its outer top a flagstone ledge at 4.1 (0.9 over the paving) - Studio: Pavement + JM_PhotographicPath, white (as
                 the canal walls). Why so thick: terrain water rounds off over its outermost 4-stud cell, so it is flat only where a point
                 sits inside a square of four water-cell centres. pondfix1 keeps the cells that make it flat to r 33.5 (round 1 put the
                 face at 35 and the water stopped short of it in a jagged line); they reach r 40.3 - all inside the wall.
  Wall_Coping_k  cut-stone coping slabs r 31.6..36.2 (0.4 over the water; 4.6 wide as the canal's), y 4.3..4.7, 64 slabs round, 0.06
                 joints - Studio: the canal coping's SmoothPlastic 0.66 / 0.65 / 0.61
  Apron_Stone_k  the paving that closes the court's hole: r 40.4..49.2, top 3.19 (between the palace pebble apron 3.13 and the
                 walkway 3.25), a bevel down to 2.95 at the outer edge - Studio: Pavement + JM_PhotographicPath, white (the court's own)
UVs: vertical faces cylindrical (round the ring), horizontal faces planar, 6 studs per tile (as the canal kit), so a Studio material
tiles without seams at the octant joins. No vertex colours.
Writes out_pond/pond_ring.fbx, pieces.json, gen_log.txt.  Run: blender -b --python gen_pond.py"""
import bpy, bmesh, math, os, json, traceback
from mathutils import Vector, geometry
D =os.path.dirname(os.path.abspath(__file__))
OUT = os.environ.get("GARDEN_OUT") or os.path.join(D, "out_pond")
os.makedirs(OUT, exist_ok=True)
LOG = os.path.join(OUT, "gen_log.txt")
def log(m): open(LOG, "a").write(str(m) + "\n"); print(m)
COL = {"Wall_Stone": (0.56, 0.55, 0.51), "Wall_Coping": (0.66, 0.65, 0.61), "Apron_Stone": (0.60, 0.58, 0.54)}
UV_STUDS = 6.0
R_FACE, R_BACK, R_COPE_IN, R_COPE_OUT = 32.0, 40.5, 31.6, 36.2
Y_BOT, Y_WALL_TOP, Y_LEDGE, Y_COPE = -0.6, 4.3, 4.1, 4.7
R_APRON_IN, R_APRON_FLAT, R_APRON_OUT = 40.4, 48.6, 49.2
Y_APRON_BOT, Y_APRON, Y_APRON_EDGE = 2.8, 3.19, 2.95
OCT = 8                 # pieces round the ring
SEG = 18                # facets per piece (2.5 deg: a 1.5-stud chord at the water face)
SLABS = 64              # coping slabs round the ring (8 per piece)
SLAB_SEG = 3
JOINT = 0.06            # the coping joints
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
def material(key):
    m = bpy.data.materials.get(key)
    if m: return m
    m = bpy.data.materials.new(key); m.use_nodes = True
    c = COL[key]; bs = m.node_tree.nodes["Principled BSDF"]
    bs.inputs["Base Color"].default_value = (lin(c[0]), lin(c[1]), lin(c[2]), 1); bs.inputs["Roughness"].default_value = 0.85
    m.diffuse_color = (lin(c[0]), lin(c[1]), lin(c[2]), 1)
    return m
def ring_uvs(bm):
    """horizontal faces: planar (x, y); vertical / sloped faces: u = arc length at the face's radius, v = height; radial end caps:
    u = radius, v = height - all in UV_STUDS studs per tile"""
    bm.normal_update()
    uv = bm.loops.layers.uv.new("UVMap")
    for f in bm.faces:
        n = f.normal
        c = f.calc_center_median()
        if abs(n.z) > 0.7:
            for l in f.loops: l[uv].uv = (l.vert.co.x / UV_STUDS, l.vert.co.y / UV_STUDS)
            continue
        radial = Vector((c.x, c.y, 0)).normalized() if c.xy.length > 1e-6 else Vector((1, 0, 0))
        if abs(Vector((n.x, n.y, 0)).normalized().dot(radial)) > 0.5:          # a face round the ring (water face, back, ledge riser, bevel)
            rf = c.xy.length
            t0 = math.atan2(c.y, c.x)
            for l in f.loops:
                t = math.atan2(l.vert.co.y, l.vert.co.x)
                t = t0 + ((t - t0 + math.pi) % (2 * math.pi) - math.pi)          # unwrapped next to the face's own angle
                l[uv].uv = (t * rf / UV_STUDS, l.vert.co.z / UV_STUDS)
        else:                                                                   # a radial end cap
            for l in f.loops: l[uv].uv = (l.vert.co.xy.length / UV_STUDS, l.vert.co.z / UV_STUDS)
def obj_from_bm(name, key, bm):
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    ring_uvs(bm)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o)
    me.materials.append(material(key))
    for p in me.polygons: p.use_smooth = False
    return o
def tris(o): return sum(len(p.vertices) - 2 for p in o.data.polygons)
def sweep(bm, profile, t0, t1, nseg):
    """sweep a closed (r, z) profile round the z axis from angle t0 to t1 in nseg facets; quads between rings, n-gon caps at both ends
    (caps from tessellate_polygon, see below)"""
    rings = []
    for i in range(nseg + 1):
        t = t0 + (t1 - t0) * i / nseg
        ct, st = math.cos(t), math.sin(t)
        rings.append([bm.verts.new((r * ct, r * st, z)) for r, z in profile])
    n = len(profile)
    for i in range(nseg):
        a, b = rings[i], rings[i + 1]
        for j in range(n):
            k = (j + 1) % n
            bm.faces.new((a[j], a[k], b[k], b[j]))
    # the end caps: the wall's profile is concave (the ledge step) - bmesh triangulate fills concave caps, so tessellate_polygon
    tri = geometry.tessellate_polygon([[Vector((r, z, 0)) for r, z in profile]])
    for (a, b, c) in tri:
        for ring, flip in ((rings[0], True), (rings[-1], False)):
            vs = (ring[a], ring[b], ring[c])
            try: bm.faces.new(tuple(reversed(vs)) if flip else vs)
            except ValueError: pass
def build():
    objs = []
    wall_profile = [(R_FACE, Y_BOT), (R_BACK, Y_BOT), (R_BACK, Y_LEDGE), (R_COPE_OUT, Y_LEDGE), (R_COPE_OUT, Y_WALL_TOP), (R_FACE, Y_WALL_TOP)]
    apron_profile = [(R_APRON_IN, Y_APRON_BOT), (R_APRON_OUT, Y_APRON_BOT), (R_APRON_OUT, Y_APRON_EDGE), (R_APRON_FLAT, Y_APRON), (R_APRON_IN, Y_APRON)]
    slab_profile = [(R_COPE_IN, Y_WALL_TOP), (R_COPE_OUT, Y_WALL_TOP), (R_COPE_OUT, Y_COPE), (R_COPE_IN, Y_COPE)]
    rmid = (R_COPE_IN + R_COPE_OUT) / 2
    g = (JOINT / 2) / rmid
    for k in range(OCT):
        t0, t1 = 2 * math.pi * k / OCT, 2 * math.pi * (k + 1) / OCT
        bm = bmesh.new(); sweep(bm, wall_profile, t0, t1, SEG); objs.append(obj_from_bm(f"Wall_Stone_{k}", "Wall_Stone", bm))
        bm = bmesh.new()
        per = SLABS // OCT
        for s in range(per):
            a0 = t0 + (t1 - t0) * s / per + g; a1 = t0 + (t1 - t0) * (s + 1) / per - g
            sweep(bm, slab_profile, a0, a1, SLAB_SEG)
        objs.append(obj_from_bm(f"Wall_Coping_{k}", "Wall_Coping", bm))
        bm = bmesh.new(); sweep(bm, apron_profile, t0, t1, SEG); objs.append(obj_from_bm(f"Apron_Stone_{k}", "Apron_Stone", bm))
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
    export(objs, os.path.join(OUT, "pond_ring.fbx"))
    by = {}
    for o in objs:
        key = o.name.rsplit("_", 1)[0]; by[key] = by.get(key, 0) + tris(o)
    log(f"pond_ring.fbx: {len(objs)} meshes, {sum(tris(o) for o in objs)} tris; " + ", ".join(f"{k} {v}" for k, v in by.items()))
    def rb(p): return [round(p[0], 3), round(p[2], 3), round(-p[1], 3)]   # Blender (x, y, z) -> Roblox (x, y up, z)
    allq = [rb(o.matrix_world @ v.co) for o in objs for v in o.data.vertices]
    info = {"pond_ring": {"min": [min(a[i] for a in allq) for i in range(3)], "max": [max(a[i] for a in allq) for i in range(3)]},
            "radii": {"face": R_FACE, "back": R_BACK, "coping": [R_COPE_IN, R_COPE_OUT], "apron": [R_APRON_IN, R_APRON_OUT]},
            "heights": {"bottom": Y_BOT, "wall_top": Y_WALL_TOP, "ledge": Y_LEDGE, "coping": Y_COPE, "apron": Y_APRON}}
    json.dump(info, open(os.path.join(OUT, "pieces.json"), "w"), indent=1)
    log("INFO " + json.dumps(info))
    log("FBX_DONE")
except Exception:
    log(traceback.format_exc()); log("FBX_FAILED")
