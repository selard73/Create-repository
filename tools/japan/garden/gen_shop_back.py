"""Back-of-shop kit (runner 7, Oct 17 2026). Shannon: "the back sides of the shops are just plain walls, they need to be finished to look
like the back of the shops would actually look like". The ten market shops have flat cream plaster back walls under a brown eave, on
the lawn. These are the things a shop's back has (Blender meshes, France / Porto finish, colours set in Studio by part name):
  back_door      a plank door 4 x 7.5 in a frame with a lintel, a 0.3 reveal, a stone step and a small pitched plank hood above
                 (Door_Wood, Door_Frame, Door_Step, Door_Hood). Its BACK is the wall plane (z = 0); it stands out toward +z.
  back_window    a 3 x 3 lattice window with a sill and five bars at y 6..9 (Win_Frame, Win_Bars, Win_Paper = the pane, Win_Sill)
  crate_stack    three wooden crates: two stacked, one beside (Crate_Wood, Crate_Band)
  sake_barrel    a straw-wrapped barrel 2.4 across, 3 tall, two rope bands (Barrel_Straw, Barrel_Rope, Barrel_Lid)
  water_butt     a dark wooden tub 2 across, 2.6 tall, two hoops, a dipper handle (Butt_Wood, Butt_Hoop)
  firewood       split logs stacked 4 long x 1.8 tall x 1.4 deep (Wood_Log, Wood_End)
  laundry_pole   two posts 5 tall, 4.6 apart, a bamboo pole at 4.5 with three cloths hanging (Pole_Post, Pole_Bamboo, Cloth_A/B/C)
  bin            a wooden rubbish bin 1.6 x 1.8 with a lid (Bin_Wood, Bin_Lid)
All stand on y 0 at their local origin; +z is "away from the wall". Box UVs, 6 studs a tile. No vertex colours.
Writes out_shopback/japan_kit19_shop_backs.fbx (one Empty per piece), pieces.json, gen_log.txt."""
import bpy, bmesh, math, os, json, random, traceback
from mathutils import Vector
D = os.path.dirname(os.path.abspath(__file__))
OUT = os.environ.get("GARDEN_OUT") or os.path.join(D, "out_shopback")
os.makedirs(OUT, exist_ok=True)
LOG = os.path.join(OUT, "gen_log.txt")
def log(m): open(LOG, "a").write(str(m) + "\n"); print(m)
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
COL = {"Door_Wood": (0.45, 0.30, 0.18), "Door_Frame": (0.30, 0.21, 0.14), "Door_Step": (0.50, 0.49, 0.46), "Door_Hood": (0.33, 0.24, 0.16),
       "Win_Frame": (0.30, 0.21, 0.14), "Win_Bars": (0.25, 0.18, 0.12), "Win_Paper": (0.93, 0.89, 0.78), "Win_Sill": (0.36, 0.26, 0.17),
       "Crate_Wood": (0.62, 0.47, 0.30), "Crate_Band": (0.40, 0.30, 0.19), "Barrel_Straw": (0.78, 0.66, 0.38), "Barrel_Rope": (0.55, 0.45, 0.28), "Barrel_Lid": (0.55, 0.42, 0.26),
       "Butt_Wood": (0.28, 0.20, 0.14), "Butt_Hoop": (0.22, 0.21, 0.20), "Wood_Log": (0.40, 0.28, 0.18), "Wood_End": (0.76, 0.62, 0.42),
       "Pole_Post": (0.36, 0.27, 0.18), "Pole_Bamboo": (0.70, 0.66, 0.38), "Cloth_A": (0.30, 0.38, 0.62), "Cloth_B": (0.92, 0.90, 0.84), "Cloth_C": (0.62, 0.28, 0.26),
       "Bin_Wood": (0.34, 0.25, 0.17), "Bin_Lid": (0.28, 0.21, 0.15)}
UV_STUDS = 6.0
def material(key):
    m = bpy.data.materials.get(key)
    if m: return m
    m = bpy.data.materials.new(key); m.use_nodes = True
    c = COL[key]; bs = m.node_tree.nodes["Principled BSDF"]
    bs.inputs["Base Color"].default_value = (lin(c[0]), lin(c[1]), lin(c[2]), 1); bs.inputs["Roughness"].default_value = 0.85
    m.diffuse_color = (lin(c[0]), lin(c[1]), lin(c[2]), 1)
    return m
def P(x, y, z): return (x, -z, y)                                    # local (x, y up, z out) -> Blender
def hull(bm, pts):
    vs = [bm.verts.new(P(*p)) for p in pts]
    bmesh.ops.convex_hull(bm, input=vs)
def box(bm, x0, x1, y0, y1, z0, z1): hull(bm, [(x, y, z) for x in (x0, x1) for y in (y0, y1) for z in (z0, z1)])
def cyl(bm, cx, cz, r, y0, y1, n=10, r1=None):
    r1 = r if r1 is None else r1
    pts = []
    for k in range(n):
        a = 2 * math.pi * k / n
        pts.append((cx + r * math.cos(a), y0, cz + r * math.sin(a))); pts.append((cx + r1 * math.cos(a), y1, cz + r1 * math.sin(a)))
    hull(bm, pts)
def logx(bm, x0, x1, cy, cz, r, n=8):                               # a log lying along x
    pts = []
    for k in range(n):
        a = 2 * math.pi * k / n
        pts.append((x0, cy + r * math.cos(a), cz + r * math.sin(a))); pts.append((x1, cy + r * math.cos(a), cz + r * math.sin(a)))
    hull(bm, pts)
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
def build_door():
    objs = []
    bm = bmesh.new()
    for i in range(5): box(bm, -1.9 + i * 0.78, -1.9 + i * 0.78 + 0.72, 0.3, 7.5, 0.06, 0.22)        # planks
    box(bm, -1.9, 1.9, 2.4, 2.7, 0.22, 0.34); box(bm, -1.9, 1.9, 5.4, 5.7, 0.22, 0.34)                 # ledges
    objs.append(finish("Door_Wood", "Door_Wood", bm))
    bm = bmesh.new()
    box(bm, -2.35, -1.95, 0.0, 8.0, 0.0, 0.45); box(bm, 1.95, 2.35, 0.0, 8.0, 0.0, 0.45); box(bm, -2.6, 2.6, 7.9, 8.45, 0.0, 0.5)   # jambs + lintel
    objs.append(finish("Door_Frame", "Door_Frame", bm))
    bm = bmesh.new(); hull(bm, [(x, y, z) for x in (-2.8, 2.8) for (y, z) in ((0.0, 0.0), (0.0, 1.9), (0.42, 1.7), (0.42, 0.0))]); objs.append(finish("Door_Step", "Door_Step", bm))
    bm = bmesh.new()
    hull(bm, [(x, y, z) for x in (-3.3, 3.3) for (y, z) in ((9.9, 0.0), (10.1, 0.0), (9.2, 1.8), (9.0, 1.8))])                      # the hood's plank roof
    for x in (-2.9, 2.9): hull(bm, [(x - 0.12, 8.45, 0.0), (x + 0.12, 8.45, 0.0), (x - 0.12, 8.45, 0.25), (x + 0.12, 8.45, 0.25), (x - 0.12, 9.1, 1.5), (x + 0.12, 9.1, 1.5), (x - 0.12, 9.25, 1.5), (x + 0.12, 9.25, 1.5)])   # brackets
    objs.append(finish("Door_Hood", "Door_Hood", bm))
    return objs
def build_window():
    objs = []
    bm = bmesh.new()
    box(bm, -1.7, -1.45, 6.0, 9.0, 0.0, 0.3); box(bm, 1.45, 1.7, 6.0, 9.0, 0.0, 0.3); box(bm, -1.7, 1.7, 8.75, 9.0, 0.0, 0.3); box(bm, -1.7, 1.7, 6.0, 6.25, 0.0, 0.3)
    objs.append(finish("Win_Frame", "Win_Frame", bm))
    bm = bmesh.new()
    for i in range(5): x = -1.2 + i * 0.6; box(bm, x - 0.06, x + 0.06, 6.25, 8.75, 0.3, 0.42)
    box(bm, -1.45, 1.45, 7.45, 7.55, 0.3, 0.4)
    objs.append(finish("Win_Bars", "Win_Bars", bm))
    bm = bmesh.new(); box(bm, -1.45, 1.45, 6.25, 8.75, 0.08, 0.14); objs.append(finish("Win_Paper", "Win_Paper", bm))
    bm = bmesh.new(); box(bm, -2.0, 2.0, 5.75, 6.0, 0.0, 0.6); objs.append(finish("Win_Sill", "Win_Sill", bm))
    return objs
def build_crates():
    objs = []
    bm = bmesh.new(); band = bmesh.new()
    for (cx, cy, cz) in ((0, 0, 0), (0, 2.25, 0.05), (2.6, 0, 0.4)):
        box(bm, cx - 1.1, cx + 1.1, cy, cy + 2.2, cz - 1.1, cz + 1.1)
        for y in (cy + 0.35, cy + 1.85): box(band, cx - 1.14, cx + 1.14, y - 0.12, y + 0.12, cz - 1.14, cz + 1.14)
    objs.append(finish("Crate_Wood", "Crate_Wood", bm)); objs.append(finish("Crate_Band", "Crate_Band", band))
    return objs
def build_barrel():
    objs = []
    bm = bmesh.new(); cyl(bm, 0, 0, 1.2, 0.0, 3.0, 12, 1.2); objs.append(finish("Barrel_Straw", "Barrel_Straw", bm, True))
    bm = bmesh.new()
    for y in (0.7, 2.3): cyl(bm, 0, 0, 1.27, y - 0.1, y + 0.1, 12)
    objs.append(finish("Barrel_Rope", "Barrel_Rope", bm, True))
    bm = bmesh.new(); cyl(bm, 0, 0, 1.0, 3.0, 3.2, 12); objs.append(finish("Barrel_Lid", "Barrel_Lid", bm, True))
    return objs
def build_butt():
    objs = []
    bm = bmesh.new(); cyl(bm, 0, 0, 0.95, 0.0, 2.6, 12, 1.05); box(bm, -0.08, 0.08, 2.6, 3.9, 0.3, 0.46); objs.append(finish("Butt_Wood", "Butt_Wood", bm, True))
    bm = bmesh.new()
    for y in (0.5, 2.2): cyl(bm, 0, 0, 1.0 + (y / 2.6) * 0.1 + 0.05, y - 0.08, y + 0.08, 12)
    objs.append(finish("Butt_Hoop", "Butt_Hoop", bm, True))
    return objs
def build_firewood():
    objs = []
    rnd = random.Random(5)
    bm = bmesh.new(); ends = bmesh.new()
    rows = ((0.3, 3), (0.9, 2), (1.5, 1))
    for (cy, n) in rows:
        for k in range(n):
            cz = -0.45 * (n - 1) + 0.9 * k
            r = 0.28 + rnd.uniform(0, 0.05)
            logx(bm, -2.0 + rnd.uniform(0, 0.2), 2.0 - rnd.uniform(0, 0.2), cy, cz, r)
            for x in (-2.0, 2.0): cyl_end = [(x, cy + r * math.cos(a), cz + r * math.sin(a)) for a in [2 * math.pi * i / 8 for i in range(8)]]; hull(ends, cyl_end + [(x + (0.06 if x < 0 else -0.06), cy, cz)])
    objs.append(finish("Wood_Log", "Wood_Log", bm, True)); objs.append(finish("Wood_End", "Wood_End", ends))
    return objs
def build_laundry():
    objs = []
    bm = bmesh.new()
    for x in (-2.3, 2.3): box(bm, x - 0.14, x + 0.14, 0.0, 5.0, -0.14, 0.14)
    objs.append(finish("Pole_Post", "Pole_Post", bm))
    bm = bmesh.new(); logx(bm, -2.6, 2.6, 4.6, 0.0, 0.1); objs.append(finish("Pole_Bamboo", "Pole_Bamboo", bm, True))
    for i, (key, x0, x1, drop) in enumerate((("Cloth_A", -2.1, -0.5, 3.2), ("Cloth_B", -0.3, 0.9, 2.4), ("Cloth_C", 1.1, 2.1, 2.9))):
        bm = bmesh.new()
        hull(bm, [(x, y, z) for x in (x0, x1) for (y, z) in ((4.55, -0.04), (4.55, 0.04), (4.55 - drop, 0.12 + 0.1 * i), (4.55 - drop, 0.2 + 0.1 * i))])
        objs.append(finish(key, key, bm))
    return objs
def build_bin():
    objs = []
    bm = bmesh.new(); hull(bm, [(x, y, z) for x in (-0.75, 0.75) for y in (0.0,) for z in (-0.75, 0.75)] + [(x, 1.8, z) for x in (-0.85, 0.85) for z in (-0.85, 0.85)]); objs.append(finish("Bin_Wood", "Bin_Wood", bm))
    bm = bmesh.new(); hull(bm, [(x, 1.8, z) for x in (-0.95, 0.95) for z in (-0.95, 0.95)] + [(x, 2.15, z) for x in (-0.5, 0.5) for z in (-0.5, 0.5)]); objs.append(finish("Bin_Lid", "Bin_Lid", bm))
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
    pieces = {"back_door": build_door(), "back_window": build_window(), "crate_stack": build_crates(), "sake_barrel": build_barrel(),
              "water_butt": build_butt(), "firewood": build_firewood(), "laundry_pole": build_laundry(), "bin": build_bin()}
    def rb(p): return [round(p[0], 3), round(p[2], 3), round(-p[1], 3)]
    info = {}
    for name, objs in pieces.items():
        q = [rb(o.matrix_world @ v.co) for o in objs for v in o.data.vertices]
        info[name] = {"min": [min(a[i] for a in q) for i in range(3)], "max": [max(a[i] for a in q) for i in range(3)]}
        log(f"{name}: {len(objs)} meshes, {sum(tris(o) for o in objs)} tris; " + ", ".join(f"{o.name} {tris(o)}" for o in objs))
    json.dump(info, open(os.path.join(OUT, "pieces.json"), "w"), indent=1)
    log("INFO " + json.dumps(info))
    allobjs = []
    x = 0.0
    for name, objs in pieces.items():
        emp = bpy.data.objects.new(name, None); bpy.context.scene.collection.objects.link(emp)
        for o in objs:
            mw = o.matrix_world.copy(); o.parent = emp; o.matrix_world = mw
        emp.location.x = x; x += 12.0
        allobjs += [emp] + objs
    export(allobjs, os.path.join(OUT, "japan_kit19_shop_backs.fbx"))
    log("FBX_DONE")
except Exception:
    log(traceback.format_exc()); log("FBX_FAILED")
