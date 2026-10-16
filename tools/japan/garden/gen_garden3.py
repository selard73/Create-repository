"""Japan garden pieces, batch 3 (job 125, Oct 16 2026): the CANAL kept as a canal. Shannon: "I like the look as a canal, how can we keep
it as a canal?" -> a proper Japanese town canal (Kyoto's Shirakawa, Tsuwano): the channel straight, the same width, the water at 1.3 as
now; the flat concrete "Canal stone bank" slabs replaced by stone-block WALLS with a coping along the top; stone steps down to the water
by each bridge; the bridge ends meeting the paths. Meshes only, in the France/Italy finish (faceted, flat colours). No moss, reeds,
lilies or pond rim.
  canal_wall.fbx    Wall_Stone, Wall_Coping - one wall segment, 8 long (Roblox z -4..4), the WATER face at x 0, the body to x -4 (the lawn
                    side), from y -1.2 (under the water) to the coping top at 2.1 (the old slabs' height): stacked stone blocks on both
                    faces with shallow joints, a coping of slabs overhanging 0.3 each side. Opt-in for a future re-export (= a re-import):
                    GARDEN_PLAIN_WALLS=1 plain faces (the palace flagstone MaterialVariant goes on in Studio), GARDEN_WALL_Z0=-5.5 stonework
                    down to the deeper bed. Every mesh now has box-projected UVs (one tile per 6 studs) so a MaterialVariant can tile.
  canal_wall_b.fbx  the same with another block pattern (alternate them)
  canal_steps.fbx   Steps_Stone - a stair down into the water from the coping: five treads (1.85, 1.6, 1.35, 1.1, 0.85 - the last two
                    under the 1.3 water), 4 wide, running 4.5 out from the wall face (x 0..4.5), down to the bed at -5.5; by each bridge
  bridge_steps.fbx  Steps_Landing - two landing steps (rise 0.5 and 1.0, 8.8 wide) at a bridge end: x -3..0 rising toward 0 (the deck end)
  skiff.fbx         Skiff_Wood, Skiff_Trim, Skiff_Pole - a flat-bottomed wooden punt (Yanagawa / Tsuwano style; Shannon: "skiff in the
                    water too?"), 14 long along x (the bow at +x), 3.6 wide, its origin at the WATERLINE (hull bottom -0.45, gunwale 0.9,
                    the bow rising to 1.4), two thwarts, a pole leaning off the stern
Units, axes, naming as gen_garden1.py (Roblox x = x, y = z, z = -y). Run: blender -b --python gen_garden3.py"""
import bpy, bmesh, math, os, random, traceback, json
PLAIN_WALL = os.environ.get("GARDEN_PLAIN_WALLS") is not None      # opt-in: plain textured faces instead of the stacked-block skins (a re-export = a re-import for her)
WALL_Z0 = float(os.environ.get("GARDEN_WALL_Z0", "-1.2"))           # opt-in: the stonework's bottom (the kit as imported: -1.2; the deeper bed is handled in Studio with a second, lower copy of each segment)
UV_STUDS = 6.0                                                      # box-projected UVs: one texture tile per 6 studs
from mathutils import Vector
D = os.path.dirname(os.path.abspath(__file__))
OUT = os.environ.get("GARDEN_OUT3") or os.path.join(D, "out3")
os.makedirs(OUT, exist_ok=True)
LOG = os.path.join(OUT, "gen_log.txt")
def log(m): open(LOG, "a").write(str(m) + "\n"); print(m)
COL = {"Wall_Stone": (0.56, 0.55, 0.51), "Wall_Coping": (0.66, 0.65, 0.61), "Steps_Stone": (0.63, 0.62, 0.58), "Steps_Landing": (0.63, 0.62, 0.58),
       "Skiff_Wood": (0.72, 0.50, 0.28), "Skiff_Trim": (0.46, 0.29, 0.15), "Skiff_Pole": (0.55, 0.47, 0.35)}
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
def material(key):
    m = bpy.data.materials.get(key)
    if m: return m
    m = bpy.data.materials.new(key); m.use_nodes = True
    c = COL[key]; m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (lin(c[0]), lin(c[1]), lin(c[2]), 1)
    m.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.85
    return m
def colkey(name): return name[2:] if name[:2] in ("A_", "B_") else name
def box_uvs(bm):
    """planar UVs per face on its dominant axis, UV_STUDS studs per tile - so a MaterialVariant texture tiles over the mesh in Studio"""
    bm.normal_update()
    uv = bm.loops.layers.uv.new("UVMap")
    for f in bm.faces:
        n = f.normal; ax = max(range(3), key=lambda i: abs(n[i]))
        for l in f.loops:
            c = l.vert.co
            u, v = ((c.y, c.z), (c.x, c.z), (c.x, c.y))[ax]
            l[uv].uv = (u / UV_STUDS, v / UV_STUDS)
def obj_from_bm(name, bm):
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
    box_uvs(bm)
    me = bpy.data.meshes.new(name); bm.normal_update(); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o); me.materials.append(material(colkey(name)))
    for p in me.polygons: p.use_smooth = False
    return o
def tris(o): return sum(len(p.vertices) - 2 for p in o.data.polygons)
def box(bm, x0, x1, y0, y1, z0, z1, jit=None):
    """an axis box (Blender: x across, y along, z up); jit(i) nudges the top corners"""
    j = jit or (lambda i: 0.0)
    b = [bm.verts.new(v) for v in [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0)]]
    t = [bm.verts.new((x, y, z1 + j(i))) for i, (x, y) in enumerate([(x0, y0), (x1, y0), (x1, y1), (x0, y1)])]
    for i in range(4):
        k = (i + 1) % 4; bm.faces.new([b[i], b[k], t[k], t[i]])
    bm.faces.new(list(reversed(b))); bm.faces.new(t)
# ---------- the wall segment ----------
Z0, ZTOP, COPE = WALL_Z0, 1.7, 2.1           # under the water .. the top of the stonework .. the coping top (the old slabs' 2.1)
def build_wall(seed, name):
    rnd = random.Random(seed)
    st, cp = bmesh.new(), bmesh.new()
    if PLAIN_WALL:
        box(st, -4.0, 0.0, -4.0, 4.0, Z0, ZTOP - 0.05)                      # one plain block: the flagstone texture does the stonework
    else:
        box(st, -3.92, -0.08, -4.0, 4.0, Z0, ZTOP - 0.05)                   # the core, right behind both block skins: the joints between blocks are 0.08 deep, a fine mortar line (0.5-deep slots read as dark spikes - look 3c)
    courses = [c for c in [(-5.5, -3.0), (-3.0, -1.2), (-1.2, -0.25), (-0.25, 0.72), (0.72, ZTOP)] if c[1] > Z0 + 0.01]
    for face, (xi, xo) in (() if PLAIN_WALL else (("water", (0.0, -0.55)), ("lawn", (-4.0, -3.45)))):
        for ci, (z0, z1) in enumerate(courses):
            y = -4.0 + (0.0 if (ci + (face == "lawn")) % 2 == 0 else rnd.choice((0.6, 0.9)))   # staggered joints
            if y > -4.0: box(st, xi + rnd.uniform(-0.03, 0.03), xo, -4.0, y - 0.03, z0, z1 - 0.03)   # the half block at the start
            while y < 3.99:
                L = min(4.0 - y, rnd.choice((1.2, 1.6, 2.0, 2.4)))
                d = rnd.uniform(-0.04, 0.05)
                box(st, xi + (d if face == "water" else 0.0), xo, y + 0.03, y + L - 0.03, z0 + 0.03, z1 - 0.03)   # (no jitter on the lawn face: no block edge stands proud)
                y += L
    y = -4.0
    while y < 3.99:                                                        # the coping slabs, overhanging 0.3 each side
        L = min(4.0 - y, 2.0)
        box(cp, -4.3 + rnd.uniform(-0.03, 0.03), 0.3 + rnd.uniform(-0.03, 0.03), y + 0.02, y + L - 0.02, ZTOP - 0.05, COPE + rnd.uniform(-0.03, 0.03))
        y += L
    return [obj_from_bm(name + "_Wall_Stone", st), obj_from_bm(name + "_Wall_Coping", cp)]
# ---------- the steps down into the water ----------
def build_canal_steps():
    bm = bmesh.new()
    for k, top in enumerate((1.85, 1.6, 1.35, 1.1, 0.85)):
        box(bm, k * 0.9, k * 0.9 + 0.9, -2.0, 2.0, Z0, top)
    box(bm, 0.0, 4.5, -2.3, -2.0, Z0, 1.9); box(bm, 0.0, 4.5, 2.0, 2.3, Z0, 1.9)   # low side cheeks
    return [obj_from_bm("Steps_Stone", bm)]
# ---------- the skiff ----------
def build_skiff():
    wood, trim, pole = bmesh.new(), bmesh.new(), bmesh.new()
    # stations along x: (x, half-width at the gunwale, half-width at the bottom, bottom z, gunwale z)
    st = [(-7.0, 0.9, 0.5, 0.35, 1.05), (-5.5, 1.5, 1.0, -0.2, 0.9), (-3.0, 1.75, 1.25, -0.45, 0.9), (0.0, 1.8, 1.3, -0.45, 0.9),
          (3.0, 1.75, 1.25, -0.45, 0.9), (5.3, 1.45, 0.95, -0.25, 1.0), (6.6, 0.7, 0.3, 0.5, 1.35), (7.0, 0.25, 0.1, 1.0, 1.4)]
    rings = []
    for (x, wg, wb, zb, zg) in st:
        # six verts a ring: bottom L/R, chine L/R (a little out and up), gunwale L/R - a flat bottom, flared sides
        rings.append([wood.verts.new(v) for v in [(x, -wb, zb), (x, wb, zb), (x, wg, zg), (x, -wg, zg)]])
    for a, b in zip(rings, rings[1:]):
        wood.faces.new([a[0], b[0], b[1], a[1]])          # bottom
        wood.faces.new([a[1], b[1], b[2], a[2]])          # right side
        wood.faces.new([a[3], b[3], b[0], a[0]])          # left side
    wood.faces.new(list(reversed(rings[0]))); wood.faces.new(rings[-1])   # transom and bow caps
    # the inner floor (a thin plank deck 0.1 above the bottom) so the boat reads hollow
    for a, b in zip(st, st[1:]):
        if a[0] > -6 and b[0] < 6.6:
            wood.faces.new([wood.verts.new((a[0], -a[2] * 0.9, a[3] + 0.1)), wood.verts.new((a[0], a[2] * 0.9, a[3] + 0.1)),
                            wood.verts.new((b[0], b[2] * 0.9, b[3] + 0.1)), wood.verts.new((b[0], -b[2] * 0.9, b[3] + 0.1))])
    # gunwale strips (dark trim) along both sides, two thwarts (seats), a stern deck
    for sgn in (-1, 1):                                                   # the gunwale rails: a rectangular strip lofted along each side
        secs = []
        for (x, wg, wb, zb, zg) in st:
            secs.append([trim.verts.new((x, sgn * (wg - 0.1), zg - 0.1)), trim.verts.new((x, sgn * (wg + 0.1), zg - 0.1)),
                         trim.verts.new((x, sgn * (wg + 0.1), zg + 0.08)), trim.verts.new((x, sgn * (wg - 0.1), zg + 0.08))])
        for a, b in zip(secs, secs[1:]):
            for i in range(4):
                q = [a[i], b[i], b[(i + 1) % 4], a[(i + 1) % 4]]
                trim.faces.new(q if sgn > 0 else list(reversed(q)))
        trim.faces.new(list(reversed(secs[0])) if sgn > 0 else secs[0]); trim.faces.new(secs[-1] if sgn > 0 else list(reversed(secs[-1])))
    for x in (-2.2, 2.0): box(trim, x - 0.3, x + 0.3, -1.6, 1.6, 0.25, 0.45)
    box(wood, -6.4, -5.0, -1.3, 1.3, 0.75, 0.9)
    # the pole, leaning off the stern into the water
    p0, p1 = Vector((-6.0, 0.9, 0.9)), Vector((-8.4, 1.6, -0.9)); p2 = Vector((-3.4, 0.2, 4.6))
    for (a, b) in ((p1, p0), (p0, p2)):
        d = (b - a).normalized(); side = d.cross(Vector((0, 0, 1))).normalized() * 0.08; up = side.cross(d).normalized() * 0.08
        vs = [pole.verts.new(a + s * side + u * up) for (s, u) in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
        ws = [pole.verts.new(b + s * side + u * up) for (s, u) in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
        for i in range(4): pole.faces.new([vs[i], vs[(i + 1) % 4], ws[(i + 1) % 4], ws[i]])
        pole.faces.new(list(reversed(vs))); pole.faces.new(ws)
    return [obj_from_bm("Skiff_Wood", wood), obj_from_bm("Skiff_Trim", trim), obj_from_bm("Skiff_Pole", pole)]
# ---------- the landing steps at a bridge end ----------
def build_bridge_steps():
    bm = bmesh.new()
    box(bm, -3.0, -1.5, -4.4, 4.4, 0.0, 0.5); box(bm, -1.55, 0.0, -4.4, 4.4, 0.0, 1.0)
    return [obj_from_bm("Steps_Landing", bm)]

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
    pieces = {"canal_wall": build_wall(61, "A"), "canal_wall_b": build_wall(62, "B"), "canal_steps": build_canal_steps(), "bridge_steps": build_bridge_steps(), "skiff": build_skiff()}
    for n, objs in pieces.items(): export(objs, n)
    def bbox(objs):
        pts = [o.matrix_world @ v.co for o in objs for v in o.data.vertices]
        rb = [(p.x, p.z, -p.y) for p in pts]
        return {"min": [round(min(q[i] for q in rb), 3) for i in range(3)], "max": [round(max(q[i] for q in rb), 3) for i in range(3)]}
    info = {n: bbox(o) for n, o in pieces.items()}
    json.dump(info, open(os.path.join(OUT, "pieces.json"), "w"), indent=1); log("BBOX " + json.dumps(info)); log("FBX_DONE")
    if os.environ.get("GARDEN_NO_RENDER"): raise SystemExit
    # preview: a stretch of canal 25 wide, walls both sides, the water at 1.3, a stair into the water, a lawn at 0; Cycles CPU
    sc = bpy.context.scene
    for o in pieces["canal_wall"] + pieces["canal_wall_b"] + pieces["canal_steps"] + pieces["bridge_steps"] + pieces["skiff"]: o.hide_render = True
    def dup(objs, loc, rot=0.0):
        for o in objs:
            c = o.copy(); c.data = o.data; c.hide_render = False; sc.collection.objects.link(c); c.location = Vector(loc); c.rotation_euler = (0, 0, rot)
    for k in range(5):
        dup(pieces["canal_wall" if k % 2 == 0 else "canal_wall_b"], (-12.5, -16 + 8 * k, 0), 0)
        dup(pieces["canal_wall_b" if k % 2 == 0 else "canal_wall"], (12.5, -16 + 8 * k, 0), math.pi)
    dup(pieces["canal_steps"], (-12.5, 6, 0), 0)
    dup(pieces["skiff"], (-3, -4, 1.3), math.radians(-78))
    def plane(name, size, loc, rgb, sx=1, sy=1):
        bpy.ops.mesh.primitive_plane_add(size=size, location=loc); p = bpy.context.active_object; p.name = name; p.scale = (sx, sy, 1)
        m = bpy.data.materials.new(name); m.use_nodes = True
        m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (lin(rgb[0]), lin(rgb[1]), lin(rgb[2]), 1)
        p.data.materials.append(m)
    plane("LawnW", 1, (-46.5, 0, 0.0), (0.36, 0.62, 0.30), 60, 70); plane("LawnE", 1, (46.5, 0, 0.0), (0.36, 0.62, 0.30), 60, 70)
    plane("Water", 1, (0, 0, 1.3), (0.24, 0.50, 0.66), 25, 70); plane("Bed", 1, (0, 0, -2.8), (0.22, 0.26, 0.24), 26, 70)
    sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 24; sc.cycles.use_denoising = False
    sc.render.resolution_x, sc.render.resolution_y = 1000, 620
    sc.world = bpy.data.worlds.new("W"); sc.world.use_nodes = True
    bg = sc.world.node_tree.nodes["Background"]; bg.inputs["Color"].default_value = (lin(0.62), lin(0.80), lin(0.95), 1); bg.inputs["Strength"].default_value = 0.9
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")); sc.collection.objects.link(sun)
    sun.rotation_euler = (math.radians(48), math.radians(8), math.radians(-30)); sun.data.energy = 3.2
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam; cam.data.lens = 30
    def shot(fn, loc, target):
        cam.location = Vector(loc); d = Vector(target) - cam.location
        cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(OUT, fn); bpy.ops.render.render(write_still=True); log(f"shot {fn}")
    shot("prev_canal_wall.png", (-22, -30, 9), (0, 4, 1.0))
    shot("prev_canal_steps.png", (-4, -8, 4.5), (-12, 7, 0.8))
    shot("prev_skiff.png", (10, -18, 6), (-3, -4, 1.3))
    log("RENDER_DONE")
except SystemExit:
    pass
except Exception:
    log(traceback.format_exc())
