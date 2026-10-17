"""Back-of-shop kit, round 2 (runner 7, Oct 17 2026). Round 1 - Shannon: "the doors are not connected to the wall", "what are those red
white and blue hanging things?", "that looks terrible". Round 2:
  back_door2    a doorway SET INTO the wall: a dark recess 0.5 deep behind the wall plane (Door_Reveal, z -0.5..0.05), the plank door
                inside it (Door_Wood, z 0.0..0.16) with two ledges, a frame of jambs + lintel standing 0.3 proud (Door_Frame), a stone
                threshold step (Door_Step) and a pitched TILE hood 6.4 wide x 2.0 deep on two brackets (Door_Tile = dark roof tile with
                ridge and ribs, Door_Hood = the brackets)
  back_window2  a vertical wooden lattice (koshi) window 3.2 x 3.0 at y 5.6..8.6: dark recess into the wall (Win_Reveal), paper behind
                (Win_Paper), 8 vertical bars + 2 rails proud of the wall (Win_Bars), a frame (Win_Frame), a sill, a small tile hood (Win_Tile)
  crate_stack   three wooden crates (Crate_Wood, Crate_Band) - as before
  sake_barrel   a straw-wrapped barrel 2.6 across, 3.1 tall, rope bands, a lid (Barrel_Straw, Barrel_Rope, Barrel_Lid)
  water_tub     a wide wooden tub 2.8 across, 2.0 tall, three hoops, a bamboo ladle resting across (Tub_Wood, Tub_Hoop, Tub_Ladle)
  wood_shed     a lean-to: two posts and a tile roof 5.6 x 2.4 sloping down away from the wall, the log stack under it (Shed_Post,
                Shed_Tile, Wood_Log, Wood_End)
  broom         a bamboo broom leaning on the wall: handle + a fanned head (Broom_Handle, Broom_Head)
  drainpipe     a hopper at the eave and a pipe 0.32 across down to a stone shoe (Pipe_Metal, Pipe_Shoe); 9.2 tall (the shops' eave)
The pieces' local +z points away from the wall; the wall plane is z = 0 (the recesses go to -z). Base at y 0. Box UVs, 6 studs a tile.
Writes out_shopback2/japan_kit20_shop_backs2.fbx, pieces.json, gen_log.txt."""
import bpy, bmesh, math, os, json, random, traceback
from mathutils import Vector
D = os.path.dirname(os.path.abspath(__file__))
OUT = os.environ.get("GARDEN_OUT") or os.path.join(D, "out_shopback2")
os.makedirs(OUT, exist_ok=True)
LOG = os.path.join(OUT, "gen_log.txt")
def log(m): open(LOG, "a").write(str(m) + "\n"); print(m)
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
COL = {"Door_Reveal": (0.12, 0.10, 0.08), "Door_Wood": (0.45, 0.30, 0.18), "Door_Frame": (0.30, 0.21, 0.14), "Door_Step": (0.50, 0.49, 0.46), "Door_Hood": (0.30, 0.21, 0.14), "Door_Tile": (0.24, 0.24, 0.27),
       "Win_Reveal": (0.12, 0.10, 0.08), "Win_Paper": (0.90, 0.86, 0.74), "Win_Bars": (0.30, 0.21, 0.14), "Win_Frame": (0.30, 0.21, 0.14), "Win_Sill": (0.36, 0.26, 0.17), "Win_Tile": (0.24, 0.24, 0.27),
       "Crate_Wood": (0.62, 0.47, 0.30), "Crate_Band": (0.40, 0.30, 0.19), "Barrel_Straw": (0.78, 0.66, 0.38), "Barrel_Rope": (0.55, 0.45, 0.28), "Barrel_Lid": (0.55, 0.42, 0.26),
       "Tub_Wood": (0.52, 0.38, 0.24), "Tub_Hoop": (0.22, 0.21, 0.20), "Tub_Ladle": (0.70, 0.66, 0.38), "Shed_Post": (0.36, 0.27, 0.18), "Shed_Tile": (0.24, 0.24, 0.27),
       "Wood_Log": (0.40, 0.28, 0.18), "Wood_End": (0.76, 0.62, 0.42), "Broom_Handle": (0.70, 0.66, 0.38), "Broom_Head": (0.60, 0.50, 0.28), "Pipe_Metal": (0.30, 0.30, 0.32), "Pipe_Shoe": (0.50, 0.49, 0.46),
       "Lattice_Wood": (0.22, 0.15, 0.10), "Lattice_Plinth": (0.30, 0.29, 0.28), "Lattice_Back": (0.16, 0.12, 0.09), "Chochin_Paper": (0.96, 0.93, 0.84), "Chochin_Band": (0.72, 0.16, 0.12)}
UV_STUDS = 6.0
def material(key):
    m = bpy.data.materials.get(key)
    if m: return m
    m = bpy.data.materials.new(key); m.use_nodes = True
    c = COL[key]; bs = m.node_tree.nodes["Principled BSDF"]
    bs.inputs["Base Color"].default_value = (lin(c[0]), lin(c[1]), lin(c[2]), 1); bs.inputs["Roughness"].default_value = 0.85
    m.diffuse_color = (lin(c[0]), lin(c[1]), lin(c[2]), 1)
    return m
def P(x, y, z): return (x, -z, y)
def hull(bm, pts):
    vs = [bm.verts.new(P(*p)) for p in pts]
    bmesh.ops.convex_hull(bm, input=vs)
def box(bm, x0, x1, y0, y1, z0, z1): hull(bm, [(x, y, z) for x in (x0, x1) for y in (y0, y1) for z in (z0, z1)])
def cyl(bm, cx, cz, r, y0, y1, n=12, r1=None):
    r1 = r if r1 is None else r1
    pts = []
    for k in range(n):
        a = 2 * math.pi * k / n
        pts.append((cx + r * math.cos(a), y0, cz + r * math.sin(a))); pts.append((cx + r1 * math.cos(a), y1, cz + r1 * math.sin(a)))
    hull(bm, pts)
def logx(bm, x0, x1, cy, cz, r, n=8):
    pts = []
    for k in range(n):
        a = 2 * math.pi * k / n
        pts.append((x0, cy + r * math.cos(a), cz + r * math.sin(a))); pts.append((x1, cy + r * math.cos(a), cz + r * math.sin(a)))
    hull(bm, pts)
def tile_hood(bm, x0, x1, y_wall, z_out, ribs=True):
    """a pitched tile hood: its top edge against the wall at y_wall, sloping down to y_wall - 0.55 at z_out; a ridge roll along the wall and tile ribs"""
    hull(bm, [(x, y, z) for x in (x0, x1) for (y, z) in ((y_wall, -0.05), (y_wall + 0.22, -0.05), (y_wall - 0.55 + 0.22, z_out), (y_wall - 0.55, z_out))])
    box(bm, x0 - 0.1, x1 + 0.1, y_wall + 0.18, y_wall + 0.42, -0.05, 0.35)
    if ribs:
        n = int((x1 - x0) / 0.7)
        for i in range(n + 1):
            x = x0 + (x1 - x0) * i / max(n, 1)
            hull(bm, [(x - 0.07, y_wall + 0.2, 0.0), (x + 0.07, y_wall + 0.2, 0.0), (x - 0.07, y_wall + 0.32, 0.0), (x + 0.07, y_wall + 0.32, 0.0),
                      (x - 0.07, y_wall - 0.35, z_out), (x + 0.07, y_wall - 0.35, z_out), (x - 0.07, y_wall - 0.23, z_out), (x + 0.07, y_wall - 0.23, z_out)])
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
    bm = bmesh.new(); box(bm, -2.3, 2.3, 0.0, 8.0, -0.5, 0.05); objs.append(finish("Door_Reveal", "Door_Reveal", bm))
    bm = bmesh.new()                                                                      # a lattice door (as her reference): a plank panel below, a lattice over paper above
    for i in range(5): box(bm, -1.95 + i * 0.8, -1.95 + i * 0.8 + 0.74, 0.25, 3.1, 0.0, 0.16)
    box(bm, -1.95, 1.95, 3.1, 3.4, 0.0, 0.24); box(bm, -1.95, 1.95, 7.35, 7.6, 0.0, 0.24)
    for i in range(6): x = -1.75 + i * 0.7; box(bm, x - 0.06, x + 0.06, 3.4, 7.35, 0.08, 0.22)
    for y in (4.7, 6.0): box(bm, -1.95, 1.95, y - 0.05, y + 0.05, 0.08, 0.2)
    objs.append(finish("Door_Wood", "Door_Wood", bm))
    bm = bmesh.new(); box(bm, -1.95, 1.95, 3.4, 7.35, -0.02, 0.04); objs.append(finish("Door_Paper", "Win_Paper", bm))
    bm = bmesh.new()
    box(bm, -2.75, -2.3, 0.0, 8.0, -0.2, 0.3); box(bm, 2.3, 2.75, 0.0, 8.0, -0.2, 0.3); box(bm, -2.95, 2.95, 8.0, 8.5, -0.2, 0.35)
    objs.append(finish("Door_Frame", "Door_Frame", bm))
    bm = bmesh.new(); hull(bm, [(x, y, z) for x in (-3.0, 3.0) for (y, z) in ((0.0, -0.1), (0.0, 1.7), (0.35, 1.5), (0.35, -0.1))]); objs.append(finish("Door_Step", "Door_Step", bm))
    return objs                                                                           # (no hood: the continuous awning runs over the door)
def build_lattice():
    """a koshi lattice panel 4.0 wide x 4.4 tall standing 0.3 proud of the wall: rails top and bottom, 9 vertical slats, a plinth"""
    objs = []
    bm = bmesh.new()
    box(bm, -2.0, 2.0, 0.3, 0.6, -0.05, 0.3); box(bm, -2.0, 2.0, 4.1, 4.4, -0.05, 0.3)
    for i in range(9): x = -1.8 + i * 0.45; box(bm, x - 0.08, x + 0.08, 0.6, 4.1, 0.05, 0.3)
    objs.append(finish("Lattice_Wood", "Lattice_Wood", bm))
    bm = bmesh.new(); box(bm, -2.0, 2.0, 0.0, 0.3, -0.05, 0.38); objs.append(finish("Lattice_Plinth", "Lattice_Plinth", bm))
    bm = bmesh.new(); box(bm, -2.0, 2.0, 0.6, 4.1, -0.06, 0.0); objs.append(finish("Lattice_Back", "Lattice_Back", bm))
    return objs
def build_awning():
    """one 4.0-wide section of the continuous tile awning: top edge against the wall at 9.1, down to 8.5 at 2.0 out, a bracket under"""
    objs = []
    bm = bmesh.new(); tile_hood(bm, -2.0, 2.0, 9.1, 2.0); objs.append(finish("Awning_Tile", "Door_Tile", bm))
    bm = bmesh.new()
    hull(bm, [(-0.12, 7.9, -0.1), (0.12, 7.9, -0.1), (-0.12, 7.9, 0.3), (0.12, 7.9, 0.3), (-0.12, 8.45, 1.75), (0.12, 8.45, 1.75), (-0.12, 8.65, 1.75), (0.12, 8.65, 1.75), (-0.12, 8.9, -0.1), (0.12, 8.9, -0.1)])
    box(bm, -2.0, 2.0, 8.75, 9.05, -0.1, 0.3)
    objs.append(finish("Awning_Wood", "Door_Hood", bm))
    return objs
def build_chochin():
    """a paper lantern on a bracket arm beside the door: the arm out from the wall at 7.9, the lantern 1.4 across x 2.1 tall hanging under it"""
    objs = []
    bm = bmesh.new(); box(bm, -0.1, 0.1, 7.8, 8.0, -0.1, 1.5); box(bm, -0.1, 0.1, 7.0, 7.8, -0.1, 0.1); objs.append(finish("Chochin_Arm", "Door_Frame", bm))
    bm = bmesh.new()
    pts = []
    for k in range(12):
        a = 2 * math.pi * k / 12
        for (y, r) in ((5.5, 0.35), (5.75, 0.62), (6.4, 0.72), (7.05, 0.62), (7.3, 0.35)): pts.append((r * math.cos(a), y, 1.2 + r * math.sin(a)))
    hull(bm, pts)
    objs.append(finish("Chochin_Paper", "Chochin_Paper", bm, True))
    bm = bmesh.new(); cyl(bm, 0, 1.2, 0.74, 6.25, 6.55, 12); cyl(bm, 0, 1.2, 0.3, 7.3, 7.8, 8); cyl(bm, 0, 1.2, 0.3, 5.3, 5.5, 8); objs.append(finish("Chochin_Band", "Chochin_Band", bm, True))
    return objs
def build_window():
    objs = []
    bm = bmesh.new(); box(bm, -1.6, 1.6, 5.6, 8.6, -0.5, 0.05); objs.append(finish("Win_Reveal", "Win_Reveal", bm))
    bm = bmesh.new(); box(bm, -1.5, 1.5, 5.7, 8.5, -0.3, -0.22); objs.append(finish("Win_Paper", "Win_Paper", bm))
    bm = bmesh.new()
    for i in range(8): x = -1.4 + i * 0.4; box(bm, x - 0.07, x + 0.07, 5.7, 8.5, 0.0, 0.28)
    for y in (6.5, 7.7): box(bm, -1.5, 1.5, y - 0.06, y + 0.06, 0.05, 0.2)
    objs.append(finish("Win_Bars", "Win_Bars", bm))
    bm = bmesh.new()
    box(bm, -1.9, -1.6, 5.5, 8.9, -0.2, 0.35); box(bm, 1.6, 1.9, 5.5, 8.9, -0.2, 0.35); box(bm, -1.9, 1.9, 8.6, 8.9, -0.2, 0.35)
    objs.append(finish("Win_Frame", "Win_Frame", bm))
    bm = bmesh.new(); box(bm, -2.1, 2.1, 5.3, 5.6, -0.2, 0.6); objs.append(finish("Win_Sill", "Win_Sill", bm))
    return objs                                                                           # (no hood: it sits under the awning)
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
    bm = bmesh.new(); cyl(bm, 0, 0, 1.3, 0.0, 3.1, 14); objs.append(finish("Barrel_Straw", "Barrel_Straw", bm, True))
    bm = bmesh.new()
    for y in (0.75, 2.4): cyl(bm, 0, 0, 1.38, y - 0.11, y + 0.11, 14)
    objs.append(finish("Barrel_Rope", "Barrel_Rope", bm, True))
    bm = bmesh.new(); cyl(bm, 0, 0, 1.1, 3.1, 3.3, 14); objs.append(finish("Barrel_Lid", "Barrel_Lid", bm, True))
    return objs
def build_tub():
    objs = []
    bm = bmesh.new(); cyl(bm, 0, 0, 1.3, 0.0, 2.0, 14, 1.4); objs.append(finish("Tub_Wood", "Tub_Wood", bm, True))
    bm = bmesh.new()
    for y in (0.35, 1.1, 1.8): cyl(bm, 0, 0, 1.3 + (y / 2.0) * 0.1 + 0.06, y - 0.07, y + 0.07, 14)
    objs.append(finish("Tub_Hoop", "Tub_Hoop", bm, True))
    bm = bmesh.new(); logx(bm, -2.0, 1.6, 2.1, 0.2, 0.08); cyl(bm, 1.5, 0.2, 0.4, 1.9, 2.3, 10); objs.append(finish("Tub_Ladle", "Tub_Ladle", bm, True))
    return objs
def build_shed():
    objs = []
    rnd = random.Random(5)
    bm = bmesh.new()
    for x in (-2.6, 2.6): box(bm, x - 0.16, x + 0.16, 0.0, 3.6, 2.1, 2.42)
    objs.append(finish("Shed_Post", "Shed_Post", bm))
    bm = bmesh.new(); tile_hood(bm, -2.9, 2.9, 4.6, 2.5); objs.append(finish("Shed_Tile", "Shed_Tile", bm))
    bm = bmesh.new(); ends = bmesh.new()
    for (cy, n) in ((0.3, 3), (0.9, 3), (1.5, 2), (2.1, 1)):
        for k in range(n):
            cz = 0.45 + (0.9 * k if n > 1 else 0.9) - (0.45 if n == 2 else 0)
            r = 0.28 + rnd.uniform(0, 0.04)
            x0, x1 = -2.3 + rnd.uniform(0, 0.2), 2.3 - rnd.uniform(0, 0.2)
            logx(bm, x0, x1, cy, cz, r)
            for x, dx in ((x0, 0.05), (x1, -0.05)): hull(ends, [(x, cy + r * math.cos(a), cz + r * math.sin(a)) for a in [2 * math.pi * i / 8 for i in range(8)]] + [(x + dx, cy, cz)])
    objs.append(finish("Wood_Log", "Wood_Log", bm, True)); objs.append(finish("Wood_End", "Wood_End", ends))
    return objs
def build_broom():
    objs = []
    bm = bmesh.new(); hull(bm, [(x, y, z) for x in (-0.07, 0.07) for (y, z) in ((1.3, 0.55), (1.3, 0.7), (5.6, -0.05), (5.6, 0.1))]); objs.append(finish("Broom_Handle", "Broom_Handle", bm))
    bm = bmesh.new(); hull(bm, [(-0.2, 1.35, 0.5), (0.2, 1.35, 0.5), (-0.2, 1.35, 0.75), (0.2, 1.35, 0.75), (-0.75, 0.0, 0.7), (0.75, 0.0, 0.7), (-0.75, 0.0, 1.1), (0.75, 0.0, 1.1)]); objs.append(finish("Broom_Head", "Broom_Head", bm))
    return objs
def build_pipe():
    objs = []
    bm = bmesh.new(); cyl(bm, 0, 0.32, 0.16, 0.5, 8.6, 10); hull(bm, [(x, y, z) for x in (-0.35, 0.35) for (y, z) in ((8.6, 0.0), (8.6, 0.65), (9.2, -0.05), (9.2, 0.75))]); objs.append(finish("Pipe_Metal", "Pipe_Metal", bm, True))
    bm = bmesh.new(); box(bm, -0.45, 0.45, 0.0, 0.5, 0.0, 0.75); objs.append(finish("Pipe_Shoe", "Pipe_Shoe", bm))
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
    pieces = {"back_door2": build_door(), "back_window2": build_window(), "lattice_panel": build_lattice(), "awning_section": build_awning(),
              "chochin": build_chochin(), "crate_stack2": build_crates(), "sake_barrel2": build_barrel(),
              "water_tub": build_tub(), "wood_shed": build_shed(), "broom": build_broom(), "drainpipe": build_pipe()}
    def rb(p): return [round(p[0], 3), round(p[2], 3), round(-p[1], 3)]
    info = {}
    for name, objs in pieces.items():
        q = [rb(o.matrix_world @ v.co) for o in objs for v in o.data.vertices]
        info[name] = {"min": [min(a[i] for a in q) for i in range(3)], "max": [max(a[i] for a in q) for i in range(3)]}
        log(f"{name}: {len(objs)} meshes, {sum(tris(o) for o in objs)} tris")
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
    export(allobjs, os.path.join(OUT, "japan_kit20_shop_backs2.fbx"))
    log("FBX_DONE")
except Exception:
    log(traceback.format_exc()); log("FBX_FAILED")
