"""Japan garden pieces, batch 4 (job 125, Oct 16 2026): PLANTING for the railway strip. Shannon: "these little blue flowers everywhere look
terrible, can you make something better while still keeping with the region and scenery?" - the 85 "Blue iris" clusters (three flat
blue discs on black stalks) along the embankment, x 5421..6569, z 140..146 (runner 7's survey tools/japan/iris_survey_2026-10-16).
Replacements in the France/Italy finish (faceted, flat colours; no photographic textures, nothing realistic):
  azalea.fbx     Azalea_Leaf + Azalea_Pink / Azalea_White / Azalea_Magenta - a clipped azalea mound (satsuki / karikomi), the rounded trimmed
                 shrub of Japanese temple lawns and canal banks: ~3.2 wide, ~1.5 tall, a dome of overlapping faceted blobs, small faceted blossom
                 clusters sunk into its surface; three blossom colours as separate meshes (the installer keeps ONE per clump: Pink / White /
                 Magenta variants)
  hydrangea.fbx  Hydrangea_Leaf + Hydrangea_Bloom - a hydrangea clump (ajisai), the blue-violet mophead heads on a leafy mound, ~2.8 wide,
                 ~2 tall (keeps a touch of blue on the strip, a better one)
Units, axes, naming as gen_garden1.py (Roblox x = x, y = z, z = -y; the origin on the ground at the clump's centre). Run: blender -b --python gen_garden4.py"""
import bpy, bmesh, math, os, random, traceback, json
from mathutils import Vector
D = os.path.dirname(os.path.abspath(__file__))
OUT = os.environ.get("GARDEN_OUT4") or os.path.join(D, "out4")
os.makedirs(OUT, exist_ok=True)
LOG = os.path.join(OUT, "gen_log.txt")
def log(m): open(LOG, "a").write(str(m) + "\n"); print(m)
COL = {"Azalea_Leaf": (0.22, 0.42, 0.20), "Azalea_Pink": (0.93, 0.45, 0.62), "Azalea_White": (0.96, 0.95, 0.90), "Azalea_Magenta": (0.80, 0.22, 0.48),
       "Hydrangea_Leaf": (0.26, 0.48, 0.24), "Hydrangea_Bloom": (0.52, 0.56, 0.84)}
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
def material(key):
    m = bpy.data.materials.get(key)
    if m: return m
    m = bpy.data.materials.new(key); m.use_nodes = True
    c = COL[key]; m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (lin(c[0]), lin(c[1]), lin(c[2]), 1)
    m.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.9
    return m
def obj_from_bm(name, bm):
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
    me = bpy.data.meshes.new(name); bm.normal_update(); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o); me.materials.append(material(name))
    for p in me.polygons: p.use_smooth = False
    return o
def tris(o): return sum(len(p.vertices) - 2 for p in o.data.polygons)
def blob(bm, at, r, rnd, sz=1.0, jitter=0.12, subdiv=2):
    res = bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=r)
    for v in res["verts"]:
        v.co.z *= sz; v.co *= 1.0 + rnd.uniform(-jitter, jitter); v.co += Vector(at)
    return res["verts"]
def blossom(bm, at, n, rnd, r=0.17):
    """a blossom cluster on the shrub's surface: a small squashed faceted ball, slightly sunk into the leaves (reads as a flower
    cluster from a stride away; flat five-point stars read as stickers)"""
    n = Vector(n).normalized()
    c = Vector(at) - n * 0.03
    res = bmesh.ops.create_icosphere(bm, subdivisions=1, radius=r)
    for v in res["verts"]:
        v.co *= 1.0 + rnd.uniform(-0.12, 0.12)
        v.co = v.co - n * (v.co.dot(n) * 0.45)                                  # squashed along the surface normal
        v.co += c
# ---------- the clipped azalea mound ----------
def build_azalea(seed):
    rnd = random.Random(seed)
    lf = bmesh.new()
    cores = [((0, 0, 0.55), 1.35, 0.85), ((0.75, 0.3, 0.45), 1.0, 0.8), ((-0.7, -0.25, 0.5), 1.05, 0.8), ((0.1, -0.8, 0.4), 0.9, 0.8), ((-0.2, 0.75, 0.42), 0.9, 0.8),
             ((0.35, 0.1, 0.95), 0.8, 0.7)]
    for (c, r, sz) in cores: blob(lf, c, r, rnd, sz=sz, jitter=0.07)
    # blossoms: points on the dome's upper surface, found by casting out from the mound's centre
    heads = {k: bmesh.new() for k in ("Azalea_Pink", "Azalea_White", "Azalea_Magenta")}
    def surface(dirn):
        # the farthest blob surface along dirn from the mound's centre (0, 0, 0.5)
        best = None
        for (c, r, sz) in cores:
            # ray p = o + t d, sphere scaled in z: solve on the unscaled sphere
            o = Vector((0, 0, 0.5)) - Vector(c); d = Vector(dirn)
            os_, ds = Vector((o.x, o.y, o.z / sz)), Vector((d.x, d.y, d.z / sz))
            bq = 2 * os_.dot(ds); cq = os_.dot(os_) - r * r; aq = ds.dot(ds)
            disc = bq * bq - 4 * aq * cq
            if disc < 0: continue
            t = (-bq + math.sqrt(disc)) / (2 * aq)
            if t > 0 and (best is None or t > best[0]): best = (t, Vector(c) + Vector((o.x + t * d.x, o.y + t * d.y, (os_.z + t * ds.z) * sz)))
        return best[1] if best else None
    placed = []
    for k in range(120):                                                         # ~26 clusters spread over the upper surface, none closer than 0.5
        th = rnd.uniform(0, 2 * math.pi); ph = math.asin(rnd.uniform(0.12, 0.97))   # uniform over the upper dome
        d = (math.cos(th) * math.cos(ph), math.sin(th) * math.cos(ph), math.sin(ph))
        p = surface(d)
        if p is None or p.z < 0.3 or any((p - q).length < 0.5 for q in placed): continue
        placed.append(p)
        for key in heads: blossom(heads[key], p, d, rnd, r=rnd.uniform(0.16, 0.22))
        if len(placed) >= 26: break
    return [obj_from_bm("Azalea_Leaf", lf)] + [obj_from_bm(k, bm) for k, bm in heads.items()]
# ---------- the hydrangea clump ----------
def build_hydrangea(seed):
    rnd = random.Random(seed)
    lf, bl = bmesh.new(), bmesh.new()
    for (c, r) in [((0, 0, 0.6), 1.15), ((0.6, 0.4, 0.5), 0.85), ((-0.65, -0.3, 0.55), 0.9), ((0.1, -0.7, 0.5), 0.8), ((-0.1, 0.7, 0.5), 0.8)]:
        blob(lf, c, r, rnd, sz=0.75, jitter=0.1)
    for k in range(9):                                                        # mophead heads, faceted balls sitting on and above the leaves
        th = rnd.uniform(0, 2 * math.pi); rr = rnd.uniform(0.0, 1.05)
        c = (math.cos(th) * rr, math.sin(th) * rr, rnd.uniform(1.15, 1.6) - 0.25 * rr)
        blob(bl, c, rnd.uniform(0.36, 0.5), rnd, sz=0.9, jitter=0.1, subdiv=1)
    return [obj_from_bm("Hydrangea_Leaf", lf), obj_from_bm("Hydrangea_Bloom", bl)]

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
    pieces = {"azalea": build_azalea(71), "hydrangea": build_hydrangea(72)}
    for n, objs in pieces.items(): export(objs, n)
    def bbox(objs):
        pts = [o.matrix_world @ v.co for o in objs for v in o.data.vertices]
        rb = [(p.x, p.z, -p.y) for p in pts]
        return {"min": [round(min(q[i] for q in rb), 3) for i in range(3)], "max": [round(max(q[i] for q in rb), 3) for i in range(3)]}
    info = {n: bbox(o) for n, o in pieces.items()}
    json.dump(info, open(os.path.join(OUT, "pieces.json"), "w"), indent=1); log("BBOX " + json.dumps(info)); log("FBX_DONE")
    if os.environ.get("GARDEN_NO_RENDER"): raise SystemExit
    # preview: a row along a lawn strip with a stone kerb (the embankment), azaleas in the three colours and a hydrangea; Cycles CPU
    sc = bpy.context.scene
    for o in pieces["azalea"] + pieces["hydrangea"]: o.hide_render = True
    def dup(objs, loc, rot=0.0, scale=1.0, keep=None):
        for o in objs:
            if keep and o.name.startswith("Azalea_") and o.name != "Azalea_Leaf" and o.name != keep: continue
            c = o.copy(); c.data = o.data; c.hide_render = False; sc.collection.objects.link(c); c.location = Vector(loc); c.rotation_euler = (0, 0, rot); c.scale = (scale,) * 3
    dup(pieces["azalea"], (-9, 0, 0), 0.4, 1.0, "Azalea_Pink"); dup(pieces["azalea"], (-4.5, 1.2, 0), 2.1, 0.9, "Azalea_White")
    dup(pieces["hydrangea"], (0.5, 0.3, 0), 1.0, 1.0); dup(pieces["azalea"], (5, -0.6, 0), 3.5, 1.15, "Azalea_Magenta"); dup(pieces["azalea"], (9.5, 1.0, 0), 5.0, 0.95, "Azalea_Pink")
    def plane(name, size, loc, rgb, sx=1, sy=1):
        bpy.ops.mesh.primitive_plane_add(size=size, location=loc); p = bpy.context.active_object; p.name = name; p.scale = (sx, sy, 1)
        m = bpy.data.materials.new(name); m.use_nodes = True
        m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (lin(rgb[0]), lin(rgb[1]), lin(rgb[2]), 1)
        p.data.materials.append(m)
    plane("Lawn", 1, (0, 0, 0.0), (0.36, 0.62, 0.30), 80, 40)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 6.5, 0.6)); kerb = bpy.context.active_object; kerb.scale = (80, 3, 1.2)
    km = bpy.data.materials.new("Kerb"); km.use_nodes = True; km.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (lin(0.62), lin(0.61), lin(0.58), 1); kerb.data.materials.append(km)
    sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 24; sc.cycles.use_denoising = False
    sc.render.resolution_x, sc.render.resolution_y = 1000, 620
    sc.world = bpy.data.worlds.new("W"); sc.world.use_nodes = True
    bg = sc.world.node_tree.nodes["Background"]; bg.inputs["Color"].default_value = (lin(0.62), lin(0.80), lin(0.95), 1); bg.inputs["Strength"].default_value = 0.9
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")); sc.collection.objects.link(sun)
    sun.rotation_euler = (math.radians(48), math.radians(8), math.radians(-30)); sun.data.energy = 3.2
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam; cam.data.lens = 32
    def shot(fn, loc, target):
        cam.location = Vector(loc); d = Vector(target) - cam.location
        cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(OUT, fn); bpy.ops.render.render(write_still=True); log(f"shot {fn}")
    shot("prev_planting.png", (-6, -16, 6), (0, 0, 0.8))
    shot("prev_planting_close.png", (-12, -5, 2.4), (-8, 0.5, 0.7))
    log("RENDER_DONE")
except SystemExit:
    pass
except Exception:
    log(traceback.format_exc())
