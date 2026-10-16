"""Japan garden pieces, batch 2b (job 125, Oct 16 2026): the KOI POND. Shannon (via runner 7): the waterway becomes a waterfall at the
south end, a natural stream, and ENDS in a koi pond at the north end before the Walkway at z 130 - not out to the sea (the train
tracks) - "with stepping stones and lanterns around it"; the rail, station and arrival court untouched. The pond is the last stretch
of the channel, closed by a round stone rim. In the France/Italy finish (faceted, flat colours), like batch 2's canal edge.
  pond_rim.fbx   P_Edge_Stone, P_Edge_Moss - a half-round rim (the water face at radius 12.5, i.e. the channel's 25 width) with an
                 8-long straight tail on each side meeting batch 2's edge segments: two stone courses down to -3.2 and a mossy lawn lip
                 (flush with the lawn at its outer edge; it fills the old channel's rectangular footprint behind the arc, corners too)
  stepstone.fbx  Step1..3 (_Stone, _Moss) - flat-topped stepping-stone columns, top at 0, down to -3.2 (buried in the raised bed)
  koi.fbx        Koi_Orange, Koi_White, Koi_Gold - three koi, ~2.4 long, built along +x (the head at +x)
  lilies.fbx     Lily_Pad, Lily_Flower - a cluster of lily pads with one pink lotus
Units, axes, naming as gen_garden1.py (Roblox x = x, y = z, z = -y). Outputs into out2/ beside batch 2 (pieces_2b.json, gen_log_2b.txt).
Run: blender -b --python gen_garden2b.py"""
import bpy, bmesh, math, os, random, traceback, json
from mathutils import Vector
D = os.path.dirname(os.path.abspath(__file__))
OUT = os.environ.get("GARDEN_OUT2") or os.path.join(D, "out2")
os.makedirs(OUT, exist_ok=True)
LOG = os.path.join(OUT, "gen_log_2b.txt")
def log(m): open(LOG, "a").write(str(m) + "\n"); print(m)
COL = {"Edge_Stone": (0.60, 0.59, 0.56), "Edge_Moss": (0.42, 0.58, 0.30), "Step_Stone": (0.55, 0.54, 0.52), "Step_Moss": (0.40, 0.56, 0.28),
       "Koi_Orange": (0.95, 0.42, 0.10), "Koi_White": (0.96, 0.94, 0.90), "Koi_Gold": (0.98, 0.72, 0.22), "Lily_Pad": (0.26, 0.50, 0.24), "Lily_Flower": (0.96, 0.62, 0.78)}
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
def material(key):
    m = bpy.data.materials.get(key)
    if m: return m
    m = bpy.data.materials.new(key); m.use_nodes = True
    c = COL[key]; m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (lin(c[0]), lin(c[1]), lin(c[2]), 1)
    m.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.85
    return m
def colkey(name):
    n = name[2:] if name[:2] in ("P_", "A_", "B_") else name
    if n.startswith("Step"): return "Step_" + n.split("_", 1)[1]
    return n
def obj_from_bm(name, bm):
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
    me = bpy.data.meshes.new(name); bm.normal_update(); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o); me.materials.append(material(colkey(name)))
    for p in me.polygons: p.use_smooth = False
    return o
def tris(o): return sum(len(p.vertices) - 2 for p in o.data.polygons)
def box8(bm, b4, t4):
    """a block from four bottom corners and four top corners, both counter-clockwise seen from above"""
    b = [bm.verts.new(v) for v in b4]; t = [bm.verts.new(v) for v in t4]
    for i in range(4):
        k = (i + 1) % 4; bm.faces.new([b[i], b[k], t[k], t[i]])
    bm.faces.new(list(reversed(b))); bm.faces.new(t)
def ring(bm, c, r, z0, z1, seg, jit=None, rtop=None):
    """a faceted column (a prism with per-vertex radius jitter); returns its top verts"""
    j = jit or (lambda i: 1.0)
    bot = [bm.verts.new((c[0] + r * j(i) * math.cos(2 * math.pi * i / seg), c[1] + r * j(i) * math.sin(2 * math.pi * i / seg), z0)) for i in range(seg)]
    rt = rtop if rtop is not None else r
    top = [bm.verts.new((c[0] + rt * j(i) * math.cos(2 * math.pi * i / seg), c[1] + rt * j(i) * math.sin(2 * math.pi * i / seg), z1)) for i in range(seg)]
    for i in range(seg): bm.faces.new([bot[i], bot[(i + 1) % seg], top[(i + 1) % seg], top[i]])
    bm.faces.new(list(reversed(bot))); bm.faces.new(top)
    return top
def cushion(bm, at, r, rnd, sz=0.35):
    res = bmesh.ops.create_icosphere(bm, subdivisions=1, radius=r)
    for v in res["verts"]: v.co.z *= sz; v.co *= 1.0 + rnd.uniform(-0.15, 0.15); v.co += Vector(at)
# ---------- the pond rim ----------
RF, TAIL = 12.5, 8.0               # the water-face radius (the channel is 25 wide) and the straight tail each side
def build_pond_rim():
    rnd = random.Random(21)
    st, ms = bmesh.new(), bmesh.new()
    def P(r, a, z): return (r * math.cos(a), r * math.sin(a), z)
    HW, BACK = RF + 5.4, 16.5                                             # the old channel's footprint behind the arc: half-width 17.9, 16.5 past the centre line
    def outer(a):
        # the lip runs out to the old channel's rectangular footprint (not a circle), so its corners are covered too: 17.9 at the tails
        return min(HW / max(1e-6, abs(math.cos(a))), BACK / max(1e-6, abs(math.sin(a))))
    # the arc: angles pi .. 2 pi (Blender -y = Roblox +z, the pond's closed end), 18 blocks of 10 degrees
    n = 18
    for i in range(n):
        a0, a1 = math.pi + math.pi * i / n + 0.004, math.pi + math.pi * (i + 1) / n - 0.004
        for (z0, z1, r0, r1) in ((-3.2, -0.9, RF - 0.2, RF + 0.7), (-0.9, 0.3, RF - 0.05, RF + 0.75)):
            dz = rnd.uniform(-0.06, 0.08); dr = rnd.uniform(-0.05, 0.05)
            # (r0 = the water side; the top tilts 0.08 down toward the water, each block a little different)
            box8(st, [P(r0 + dr, a0, z0), P(r1 + dr, a0, z0), P(r1 + dr, a1, z0), P(r0 + dr, a1, z0)],
                 [P(r0 + dr, a0, z1 + dz - 0.08), P(r1 + dr, a0, z1 + dz), P(r1 + dr, a1, z1 + dz), P(r0 + dr, a1, z1 + dz - 0.08)])
        # the lip, 0.06 at its outer edge, -0.06 at the stones (over the upper course's back)
        am = (a0 + a1) / 2
        box8(ms, [P(RF + 0.6, a0, -0.5), P(outer(a0), a0, -0.5), P(outer(a1), a1, -0.5), P(RF + 0.6, a1, -0.5)],
             [P(RF + 0.6, a0, -0.06), P(outer(a0), a0, 0.06), P(outer(a1), a1, 0.06), P(RF + 0.6, a1, -0.06)])
        if i % 3 == 1: cushion(ms, P(RF + 1.3 + rnd.uniform(0, 1.2), am, 0.4), 0.55, rnd)
    # the tails: straight, y 0 .. TAIL, the water at +x for the west tail (x = -RF) and at -x for the east tail (x = +RF)
    for side in (-1, 1):
        y = 0.0
        while y < TAIL - 0.01:
            L = min(TAIL - y, rnd.choice((1.6, 2.0, 2.4)))
            for (z0, z1, w0, w1) in ((-3.2, -0.9, 0.2, -0.7), (-0.9, 0.3, 0.05, -0.75)):
                # w = the offset toward the water (positive) from the face
                xa, xb = side * -(RF - w0 + rnd.uniform(-0.05, 0.05)), side * -(RF - w1 + rnd.uniform(-0.05, 0.05))   # (xa = the water side)
                dz = rnd.uniform(-0.06, 0.08)
                pts = [(xa, y + 0.04), (xb, y + 0.04), (xb, y + L - 0.04), (xa, y + L - 0.04)]
                if side > 0: pts = [pts[1], pts[0], pts[3], pts[2]]
                tz = [z1 + dz - 0.08, z1 + dz, z1 + dz, z1 + dz - 0.08] if side < 0 else [z1 + dz, z1 + dz - 0.08, z1 + dz - 0.08, z1 + dz]
                box8(st, [(p[0], p[1], z0) for p in pts], [(p[0], p[1], tz[k]) for k, p in enumerate(pts)])
            y += L
        xi, xo = side * -(RF + 0.6), side * -(RF + 5.4)
        pts = [(xi, 0.0), (xo, 0.0), (xo, TAIL), (xi, TAIL)]
        tz = [-0.06, 0.06, 0.06, -0.06]
        if side > 0: pts = [pts[1], pts[0], pts[3], pts[2]]; tz = [0.06, -0.06, -0.06, 0.06]
        box8(ms, [(p[0], p[1], -0.5) for p in pts], [(p[0], p[1], tz[k]) for k, p in enumerate(pts)])
        cushion(ms, (side * -(RF + 1.6), 3.5 + rnd.uniform(-1, 1), 0.4), 0.55, rnd)
    return [obj_from_bm("P_Edge_Stone", st), obj_from_bm("P_Edge_Moss", ms)]
# ---------- stepping stones ----------
def build_stepstones():
    out = []
    for k, (r, seg, seed) in enumerate(((1.5, 9, 31), (1.3, 8, 32), (1.7, 10, 33)), start=1):
        rnd = random.Random(seed)
        st, ms = bmesh.new(), bmesh.new()
        jit = [rnd.uniform(0.82, 1.18) for _ in range(seg)]
        ring(st, (0, 0), r * 0.85, -3.2, -1.2, seg, jit=lambda i: jit[i])                     # the buried foot, narrower
        ring(st, (0, 0), r, -1.25, 0.0, seg, jit=lambda i: jit[i], rtop=r * 0.96)             # the stone, its top flat at 0
        cushion(ms, (rnd.uniform(-0.4, 0.4) * r, rnd.uniform(-0.4, 0.4) * r, 0.0), r * 0.42, rnd, sz=0.25)
        out += [obj_from_bm(f"Step{k}_Stone", st), obj_from_bm(f"Step{k}_Moss", ms)]
    return out
# ---------- koi ----------
def build_koi():
    out = []
    for name, seed in (("Koi_Orange", 41), ("Koi_White", 42), ("Koi_Gold", 43)):
        rnd = random.Random(seed)
        bm = bmesh.new()
        prof = [(-0.9, 0.06), (-0.6, 0.13), (-0.3, 0.21), (0.0, 0.25), (0.3, 0.23), (0.6, 0.17), (0.9, 0.07)]
        seg = 8; rings = []
        for (x, r) in prof:
            rings.append([bm.verts.new((x, r * 0.9 * math.cos(2 * math.pi * i / seg), r * math.sin(2 * math.pi * i / seg))) for i in range(seg)])
        for a, b in zip(rings, rings[1:]):
            for i in range(seg): bm.faces.new([a[i], b[i], b[(i + 1) % seg], a[(i + 1) % seg]])
        bm.faces.new(list(reversed(rings[0]))); bm.faces.new(rings[-1])
        # the tail: two fan triangles; the dorsal fin; two pectorals
        tb = bm.verts.new((-0.92, 0, 0)); t1 = bm.verts.new((-1.5, 0.08, 0.34)); t2 = bm.verts.new((-1.45, -0.08, -0.3)); tm = bm.verts.new((-1.25, 0, 0.0))
        bm.faces.new([tb, t1, tm]); bm.faces.new([tb, tm, t2])
        d0 = bm.verts.new((-0.3, 0, 0.18)); d1 = bm.verts.new((0.25, 0, 0.2)); d2 = bm.verts.new((-0.5, 0, 0.42)); bm.faces.new([d0, d1, d2])
        for s in (-1, 1):
            p0 = bm.verts.new((0.35, s * 0.18, -0.05)); p1 = bm.verts.new((0.05, s * 0.45, -0.1)); p2 = bm.verts.new((0.1, s * 0.2, -0.08))
            bm.faces.new([p0, p1, p2] if s > 0 else [p0, p2, p1])
        out.append(obj_from_bm(name, bm))
    return out
# ---------- lily pads ----------
def build_lilies():
    rnd = random.Random(51)
    pd, fl = bmesh.new(), bmesh.new()
    for k in range(6):
        a = rnd.uniform(0, 2 * math.pi); d = rnd.uniform(0.0, 1.4)
        c = (math.cos(a) * d, math.sin(a) * d); r = rnd.uniform(0.45, 0.85)
        jit = [rnd.uniform(0.9, 1.1) for _ in range(8)]
        ring(pd, c, r, 0.0, 0.06, 8, jit=lambda i: jit[i])
    c = Vector((0.3, -0.2, 0.05))
    res = bmesh.ops.create_icosphere(fl, subdivisions=1, radius=0.22)
    for v in res["verts"]: v.co.z *= 0.8; v.co += c + Vector((0, 0, 0.2))
    for i in range(8):
        b = 2 * math.pi * i / 8
        tip = c + Vector((math.cos(b) * 0.45, math.sin(b) * 0.45, 0.5)); s = Vector((-math.sin(b), math.cos(b), 0)) * 0.13
        base = c + Vector((math.cos(b) * 0.1, math.sin(b) * 0.1, 0.05))
        fl.faces.new([fl.verts.new(base - s), fl.verts.new(base + s), fl.verts.new(tip)])
        fl.faces.new([fl.verts.new(base + s), fl.verts.new(base - s), fl.verts.new(tip + Vector((0, 0, 0.001)))])
    return [obj_from_bm("Lily_Pad", pd), obj_from_bm("Lily_Flower", fl)]

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
    pieces = {"pond_rim": build_pond_rim(), "stepstone": build_stepstones(), "koi": build_koi(), "lilies": build_lilies()}
    for n, objs in pieces.items(): export(objs, n)
    def bbox(objs):
        pts = [o.matrix_world @ v.co for o in objs for v in o.data.vertices]
        rb = [(p.x, p.z, -p.y) for p in pts]
        return {"min": [round(min(q[i] for q in rb), 3) for i in range(3)], "max": [round(max(q[i] for q in rb), 3) for i in range(3)]}
    info = {n: bbox(o) for n, o in pieces.items()}
    for k in (1, 2, 3): info[f"stepstone/Step{k}"] = bbox([o for o in pieces["stepstone"] if o.name.startswith(f"Step{k}_")])
    for n in ("Koi_Orange", "Koi_White", "Koi_Gold"): info[f"koi/{n}"] = bbox([o for o in pieces["koi"] if o.name == n])
    json.dump(info, open(os.path.join(OUT, "pieces_2b.json"), "w"), indent=1); log("BBOX " + json.dumps(info)); log("FBX_DONE")
    if os.environ.get("GARDEN_NO_RENDER"): raise SystemExit
    # preview: the pond at the end of a stretch of water, stepping stones across, koi, lilies; Cycles CPU
    sc = bpy.context.scene
    def dup(objs, loc, rot=0.0, scale=1.0):
        for o in objs:
            c = o.copy(); c.data = o.data; c.hide_render = False; sc.collection.objects.link(c); c.location = Vector(loc); c.rotation_euler = (0, 0, rot); c.scale = (scale,) * 3
    for o in pieces["stepstone"] + pieces["koi"] + pieces["lilies"]: o.hide_render = True
    for k in range(7):
        grp = [o for o in pieces["stepstone"] if o.name.startswith(f"Step{k % 3 + 1}_")]
        dup(grp, (-10.5 + 3.5 * k, -4 + (0.8 if k % 2 else -0.8), -0.1), rot=k * 0.9)
    for k, (x, y, r, n) in enumerate(((-4, -8, 0.4, "Koi_Orange"), (3, -9.5, 2.2, "Koi_White"), (6, 3, 3.6, "Koi_Gold"), (-6, 2, 5.0, "Koi_Orange"), (1, -2, 1.3, "Koi_White"))):
        dup([o for o in pieces["koi"] if o.name == n], (x, y, -1.0), rot=r)
    dup(pieces["lilies"], (7.5, -7, -0.6)); dup(pieces["lilies"], (-7, 4, -0.6), rot=1.2, scale=0.9)
    def plane(name, size, loc, rgb, sx=1, sy=1):
        bpy.ops.mesh.primitive_plane_add(size=size, location=loc); p = bpy.context.active_object; p.name = name; p.scale = (sx, sy, 1)
        m = bpy.data.materials.new(name); m.use_nodes = True
        m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (lin(rgb[0]), lin(rgb[1]), lin(rgb[2]), 1)
        p.data.materials.append(m)
    # the lawn is the game's part floor at 0 with the channel cut out of it (x +-18, y -17 .. 40): four planes around that hole
    plane("LawnW", 1, (-54, 11.5, -0.02), (0.36, 0.62, 0.30), 72, 57); plane("LawnE", 1, (54, 11.5, -0.02), (0.36, 0.62, 0.30), 72, 57)
    plane("LawnS", 1, (0, -45.5, -0.02), (0.36, 0.62, 0.30), 36, 57); plane("LawnBed", 1, (0, -7, -6.0), (0.22, 0.30, 0.34), 36, 20)
    plane("Water", 1, (0, 10, -0.6), (0.27, 0.55, 0.70), 25, 50); plane("Bed", 1, (0, 10, -3.0), (0.30, 0.36, 0.30), 26, 52)
    # the stream's own edge continues up +y in the preview: a plain strip each side stands in for batch 2's segments
    plane("StripW", 1, (-15.1, 24, 0.03), (0.42, 0.58, 0.30), 5.2, 32); plane("StripE", 1, (15.1, 24, 0.03), (0.42, 0.58, 0.30), 5.2, 32)
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
    shot("prev_pond.png", (-14, 30, 14), (0, -4, -0.5))
    shot("prev_pond_low.png", (-20, 2, 2.6), (2, -6, -0.4))
    log("RENDER_DONE")
except SystemExit:
    pass
except Exception:
    log(traceback.format_exc())
