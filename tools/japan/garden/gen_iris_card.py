"""The flower CARD picture (job 125): a Japanese iris clump (hanashobu, blue-violet) rendered in Cycles on a transparent background, for
the crossed-card flower clumps that replace the 85 "Blue iris" part clusters along the railway strip. Shannon: "no, I want some flowers".
A card = two crossed flat panels wearing this picture; from any angle it reads as a clump of blossoms (the standard Roblox garden trick).
Output: out_iris/iris_card.png (1024 x 1024, RGBA, the clump centred, its base at the bottom edge) and a 512 version; the aspect is
square so the in-game card is as tall as it is wide (the clump is ~2.6 studs). Smooth-shaded, high-poly, soft daylight - a rendered
sprite, nothing faceted. Run: blender -b --python gen_iris_card.py"""
import bpy, bmesh, math, os, random, traceback
from mathutils import Vector, Matrix
D = os.path.dirname(os.path.abspath(__file__))
OUT = os.environ.get("IRIS_OUT") or os.path.join(D, "out_iris")
os.makedirs(OUT, exist_ok=True)
LOG = os.path.join(OUT, "gen_log.txt")
def log(m): open(LOG, "a").write(str(m) + "\n"); print(m)
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
def material(name, rgb, rough=0.6, sss=0.0, sss_rgb=None, emit=0.0):
    m = bpy.data.materials.get(name)
    if m: return m
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (lin(rgb[0]), lin(rgb[1]), lin(rgb[2]), 1)
    b.inputs["Roughness"].default_value = rough
    if sss > 0:
        try:
            b.inputs["Subsurface Weight"].default_value = sss
            if sss_rgb: b.inputs["Subsurface Radius"].default_value = sss_rgb
        except Exception: pass
    if emit > 0:
        try: b.inputs["Emission Color"].default_value = (lin(rgb[0]), lin(rgb[1]), lin(rgb[2]), 1); b.inputs["Emission Strength"].default_value = emit
        except Exception: pass
    return m
def obj_from_bm(name, bm, mat, smooth=True):
    me = bpy.data.meshes.new(name); bm.normal_update(); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o); me.materials.append(mat)
    for p in me.polygons: p.use_smooth = smooth
    return o
# ---------- petals: a bezier-ish curved blade (fall petals droop, standards rise), built as a grid ----------
def petal(bm, base, dirn, length, width, droop, up_curl, rnd, segs=10, wsegs=5, twist=0.0):
    d = Vector(dirn).normalized(); side = d.cross(Vector((0, 0, 1))).normalized()
    rows = []
    for i in range(segs + 1):
        t = i / segs
        # the spine: out along d, dipping by droop (falls) or rising (standards), a little curl at the tip
        z = -droop * t * t + up_curl * (t ** 1.6)
        p = Vector(base) + d * (length * t) + Vector((0, 0, z))
        w = width * math.sin(math.pi * min(1.0, 0.15 + 0.85 * t)) * (1.0 if t < 0.9 else 1.0 - (t - 0.9) * 6)
        w = max(0.02, w)
        row = []
        for j in range(wsegs + 1):
            u = j / wsegs - 0.5
            cup = 0.35 * width * (u * u * 4) * (0.3 + 0.7 * t)                          # the edges rise: a cupped blade
            tw = twist * u * t
            q = p + side * (u * 2 * w) + Vector((0, 0, cup + tw)) + Vector((rnd.uniform(-0.01, 0.01), rnd.uniform(-0.01, 0.01), 0))
            row.append(bm.verts.new(q))
        rows.append(row)
    for a, b in zip(rows, rows[1:]):
        for j in range(wsegs):
            bm.faces.new([a[j], b[j], b[j + 1], a[j + 1]])
def iris_flower(at, heading, rnd, scale=1.0):
    """three falls (drooping, with a yellow signal), three standards (rising), a small centre"""
    falls, stds, sig = bmesh.new(), bmesh.new(), bmesh.new()
    for k in range(3):
        a = heading + 2 * math.pi * k / 3 + rnd.uniform(-0.15, 0.15)
        d = (math.cos(a), math.sin(a), 0)
        petal(falls, at, d, 0.62 * scale, 0.26 * scale, 0.42 * scale, 0.0, rnd, twist=rnd.uniform(-0.03, 0.03))
        petal(sig, (at[0] + d[0] * 0.06, at[1] + d[1] * 0.06, at[2] + 0.015), d, 0.22 * scale, 0.05 * scale, 0.12 * scale, 0.0, rnd, segs=5, wsegs=2)
    for k in range(3):
        a = heading + 2 * math.pi * (k + 0.5) / 3 + rnd.uniform(-0.15, 0.15)
        d = (math.cos(a) * 0.55, math.sin(a) * 0.55, 0.85)
        petal(stds, at, d, 0.5 * scale, 0.2 * scale, -0.05, 0.15 * scale, rnd, twist=rnd.uniform(-0.04, 0.04))
    return falls, stds, sig
def leaf(bm, base, heading, length, rnd):
    d = (math.cos(heading) * 0.22, math.sin(heading) * 0.22, 1.0)
    petal(bm, base, d, length, 0.055, -0.0, -0.35 * length * rnd.uniform(0.6, 1.2), rnd, segs=14, wsegs=2, twist=rnd.uniform(-0.1, 0.1))
def stem(bm, base, top, r=0.025, seg=8):
    a, b = Vector(base), Vector(top); d = (b - a).normalized()
    side = d.cross(Vector((0, 1, 0))).normalized() if abs(d.y) < 0.9 else d.cross(Vector((1, 0, 0))).normalized(); up = side.cross(d)
    ra = [bm.verts.new(a + (side * math.cos(2 * math.pi * i / seg) + up * math.sin(2 * math.pi * i / seg)) * r) for i in range(seg)]
    rb = [bm.verts.new(b + (side * math.cos(2 * math.pi * i / seg) + up * math.sin(2 * math.pi * i / seg)) * r * 0.8) for i in range(seg)]
    for i in range(seg): bm.faces.new([ra[i], ra[(i + 1) % seg], rb[(i + 1) % seg], rb[i]])
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    rnd = random.Random(5)
    PET = material("Petal", (0.40, 0.30, 0.78), rough=0.55, sss=0.25, sss_rgb=(0.4, 0.3, 0.8))
    PET2 = material("PetalDeep", (0.30, 0.18, 0.66), rough=0.55, sss=0.25, sss_rgb=(0.4, 0.3, 0.8))
    SIG = material("Signal", (0.98, 0.84, 0.25), rough=0.5, emit=0.3)
    LEAF = material("Leaf", (0.28, 0.55, 0.22), rough=0.65, sss=0.15, sss_rgb=(0.3, 0.6, 0.2))
    STEM = material("Stem", (0.33, 0.56, 0.26), rough=0.7)
    leaves, stems = bmesh.new(), bmesh.new()
    # leaves: a fan of sword leaves from a base clump
    for k in range(22):
        a = rnd.uniform(0, 2 * math.pi); r = rnd.uniform(0.0, 0.28)
        leaf(leaves, (math.cos(a) * r, math.sin(a) * r, 0.0), a + rnd.uniform(-0.3, 0.3), rnd.uniform(1.0, 1.9), rnd)
    # flowers on stems, the tallest in the middle
    heads = [((0.0, 0.05), 2.05, 1.0), ((-0.42, -0.18), 1.65, 0.9), ((0.45, -0.1), 1.75, 0.92), ((0.12, -0.45), 1.35, 0.8), ((-0.2, 0.4), 1.5, 0.85)]
    objs = []
    for i, ((x, y), h, sc) in enumerate(heads):
        stem(stems, (x * 0.5, y * 0.5, 0.0), (x, y, h - 0.05 * sc))
        f, s, g = iris_flower((x, y, h), rnd.uniform(0, 6.28), rnd, scale=sc)
        objs += [obj_from_bm(f"Falls{i}", f, PET2 if i % 2 else PET), obj_from_bm(f"Stds{i}", s, PET), obj_from_bm(f"Sig{i}", g, SIG)]
        # a bud or two
    for (x, y, h) in [((0.3, 0.3, 1.2)), ((-0.5, 0.15, 1.05))]:
        stem(stems, (x * 0.5, y * 0.5, 0.0), (x, y, h))
        bud = bmesh.new(); res = bmesh.ops.create_icosphere(bud, subdivisions=3, radius=0.07)
        for v in res["verts"]: v.co.z *= 2.2; v.co += Vector((x, y, h + 0.1))
        objs.append(obj_from_bm("Bud", bud, PET2))
    objs += [obj_from_bm("Leaves", leaves, LEAF), obj_from_bm("Stems", stems, STEM)]
    for o in objs:
        for p in o.data.polygons: p.use_smooth = True
    for o in objs:                                                             # both sides render (thin blades)
        for m in o.data.materials: m.use_backface_culling = False
    # ---------- the render: transparent film, soft sun + sky, the camera straight on at flower height ----------
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 96; sc.cycles.use_denoising = False
    sc.render.film_transparent = True
    sc.render.image_settings.file_format = "PNG"; sc.render.image_settings.color_mode = "RGBA"
    sc.world = bpy.data.worlds.new("W"); sc.world.use_nodes = True
    bg = sc.world.node_tree.nodes["Background"]; bg.inputs["Color"].default_value = (lin(0.75), lin(0.85), lin(0.98), 1); bg.inputs["Strength"].default_value = 1.0
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")); sc.collection.objects.link(sun)
    sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(-35)); sun.data.energy = 2.6; sun.data.angle = math.radians(8)
    fill = bpy.data.objects.new("Fill", bpy.data.lights.new("Fill", "SUN")); sc.collection.objects.link(fill)
    fill.rotation_euler = (math.radians(60), 0, math.radians(140)); fill.data.energy = 0.9; fill.data.angle = math.radians(20)
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam
    cam.data.type = "ORTHO"; cam.data.ortho_scale = 3.0
    cam.location = Vector((0, -12, 1.45)); cam.rotation_euler = (math.radians(90), 0, 0)
    for res_px, fn in ((1024, "iris_card.png"), (512, "iris_card_512.png")):
        sc.render.resolution_x, sc.render.resolution_y = res_px, res_px
        sc.render.filepath = os.path.join(OUT, fn); bpy.ops.render.render(write_still=True); log(f"shot {fn}")
    # a second view from 40 degrees round, to check the clump reads from an angle (for the crossed card)
    cam.location = Vector((-7.7, -9.2, 1.45)); cam.rotation_euler = (math.radians(90), 0, math.radians(-40))
    sc.render.resolution_x, sc.render.resolution_y = 512, 512
    sc.render.filepath = os.path.join(OUT, "iris_card_side_check.png"); bpy.ops.render.render(write_still=True); log("shot side check")
    log("RENDER_DONE")
except Exception:
    log(traceback.format_exc())
