"""Japan boundaries kit (Oct 23 2026) - the fences and gates that close Tea Hills and the Palace until Lantern Street is done.
Her words: "maybe a wooden fence? between the agricultural area and the shops?" Pieces (units = studs; x along the fence, y the
thickness, z up; FBX exported -Z forward / Y up like the church, so Roblox gets x along, y up, z depth):
  JF_WoodSection   itabei: a square post + vertical boards between two back rails + a little capping board, 4 studs per section
  JF_WoodPost      the closing post for a run's far end
  JF_BambooSection kenninji-gaki: a post + packed vertical canes + three binding canes with black rope knots, 4 studs per section
  JF_BambooPost    the closing post
  JF_GateWood      a plank gate leaf 4 x 6 with a diagonal brace, its hinge edge at x = 0
  JF_GateVermilion a vermilion lattice gate leaf 4 x 6 (the taiko bridges, scaled up for the palace gate), hinge edge at x = 0
  JF_SignBoard     a wooden board 5 x 1.6 on two posts (the board's text is a SurfaceGui on a thin part in front of it)
Flat colours; Studio materials come from the installer. Fences are 8 tall: avatars jump ~7.2 (no invisible blockers on them).
Check renders in Cycles (lit - never Workbench grey). Run: python croc/run_blender.py tools/japan/boundaries/out/gen_log.txt KIT tools/japan/boundaries/gen_fence_kit.py"""
import bpy, bmesh, math, os, traceback
from mathutils import Vector

D = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(D, "out"); os.makedirs(OUT, exist_ok=True)
LOG = os.path.join(OUT, "gen_log.txt")
def log(m): open(LOG, "a").write(str(m) + "\n"); print(m)
COL = {"Wood_Dark": (0.30, 0.20, 0.12), "Wood_Mid": (0.52, 0.36, 0.20), "Wood_Cap": (0.24, 0.16, 0.10), "Bamboo": (0.76, 0.64, 0.36),
       "Bamboo_Dark": (0.55, 0.45, 0.24), "Rope": (0.08, 0.07, 0.06), "Vermilion": (0.78, 0.18, 0.10), "Black": (0.10, 0.09, 0.09),
       "Board": (0.62, 0.46, 0.26)}
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
def material(key):
    m = bpy.data.materials.get(key)
    if m: return m
    m = bpy.data.materials.new(key); m.use_nodes = True
    c = COL[key]; b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (lin(c[0]), lin(c[1]), lin(c[2]), 1); b.inputs["Roughness"].default_value = 0.75
    return m
# one bmesh per (piece, colour); a piece with several colours exports as several meshes named <piece>__<colour>
BMS = {}
def B(piece, col):
    k = (piece, col)
    if k not in BMS: BMS[k] = bmesh.new()
    return BMS[k]
def box(bm, x0, x1, y0, y1, z0, z1):
    b = [bm.verts.new(v) for v in [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0)]]
    t = [bm.verts.new(v) for v in [(x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)]]
    for i in range(4):
        k = (i + 1) % 4; bm.faces.new([b[i], b[k], t[k], t[i]])
    bm.faces.new(list(reversed(b))); bm.faces.new(t)
def cyl_z(bm, cx, cy, r, z0, z1, seg=8):
    a = [bm.verts.new((cx + r * math.cos(2 * math.pi * i / seg), cy + r * math.sin(2 * math.pi * i / seg), z0)) for i in range(seg)]
    b = [bm.verts.new((cx + r * math.cos(2 * math.pi * i / seg), cy + r * math.sin(2 * math.pi * i / seg), z1)) for i in range(seg)]
    for i in range(seg): bm.faces.new([a[i], a[(i + 1) % seg], b[(i + 1) % seg], b[i]])
    bm.faces.new(list(reversed(a))); bm.faces.new(b)
def cyl_x(bm, x0, x1, cy, cz, r, seg=8):
    a = [bm.verts.new((x0, cy + r * math.cos(2 * math.pi * i / seg), cz + r * math.sin(2 * math.pi * i / seg))) for i in range(seg)]
    b = [bm.verts.new((x1, cy + r * math.cos(2 * math.pi * i / seg), cz + r * math.sin(2 * math.pi * i / seg))) for i in range(seg)]
    for i in range(seg): bm.faces.new([a[i], b[i], b[(i + 1) % seg], a[(i + 1) % seg]])
    bm.faces.new(a); bm.faces.new(list(reversed(b)))
def slab(bm, p0, p1, w, t):
    """a tilted board from p0 to p1 (x, z), w wide (along the board's normal in the xz plane), t thick in y, centred on y 0"""
    (x0, z0), (x1, z1) = p0, p1
    dx, dz = x1 - x0, z1 - z0; L = math.hypot(dx, dz); nx, nz = -dz / L * w / 2, dx / L * w / 2
    q = [(x0 + nx, z0 + nz), (x1 + nx, z1 + nz), (x1 - nx, z1 - nz), (x0 - nx, z0 - nz)]
    f = [bm.verts.new((x, -t / 2, z)) for (x, z) in q]; g = [bm.verts.new((x, t / 2, z)) for (x, z) in q]
    bm.faces.new(list(reversed(f))); bm.faces.new(g)
    for i in range(4):
        k = (i + 1) % 4; bm.faces.new([f[i], f[k], g[k], g[i]])

H, SEC = 10.0, 4.0        # (jumpfix1, Oct 23: 8 was jumped - avatars rise 7.2 and stand on the 0.3 ledges; placed fences are x1.25 of
                          # the 8 kit, and the installer makes the binding canes / rope / cap boards non-solid - no footholds)
def wood_post(piece, x):
    box(B(piece, "Wood_Dark"), x - 0.28, x + 0.28, -0.28, 0.28, -0.5, H)
    box(B(piece, "Wood_Cap"), x - 0.36, x + 0.36, -0.36, 0.36, H, H + 0.14)             # the post cap
def wood_section():
    p = "JF_WoodSection"
    wood_post(p, 0)
    for z in (1.6, 6.4):                                                                  # two back rails
        box(B(p, "Wood_Dark"), 0.28, SEC - 0.28, 0.14, 0.34, z - 0.18, z + 0.18)
    n, w = 4, 0.74                                                                         # four boards, evenly spaced post to post
    g = (SEC - 0.68 - n * w) / (n - 1)
    for i in range(n):
        x = 0.34 + i * (w + g); box(B(p, "Wood_Mid"), x, x + w, -0.14, -0.06, 0.25, H - 0.55)
    box(B(p, "Wood_Cap"), 0.28, SEC - 0.28, -0.3, 0.3, H - 0.55, H - 0.35)                 # the capping board (kasagi)
def wood_endpost(): wood_post("JF_WoodPost", 0)
def bamboo_post(piece, x):
    box(B(piece, "Wood_Dark"), x - 0.24, x + 0.24, -0.24, 0.24, -0.5, H)
def bamboo_section():
    p = "JF_BambooSection"
    bamboo_post(p, 0)
    x = 0.45
    while x <= SEC - 0.42:                                                                 # vertical canes, packed
        cyl_z(B(p, "Bamboo"), x, 0.0, 0.17, 0.2, H - 0.3, 6); x += 0.38
    for z in (1.5, 4.0, 6.5):                                                              # binding canes, front and back
        cyl_x(B(p, "Bamboo_Dark"), 0.24, SEC - 0.24, -0.26, z, 0.11, 6)
        cyl_x(B(p, "Bamboo_Dark"), 0.24, SEC - 0.24, 0.26, z, 0.11, 6)
        for kx in (1.0, 2.0, 3.0):                                                         # rope knots
            box(B(p, "Rope"), kx - 0.12, kx + 0.12, -0.42, 0.42, z - 0.16, z + 0.16)
def bamboo_endpost(): bamboo_post("JF_BambooPost", 0)
GW, GH = 4.0, 6.0
def gate_wood():
    p = "JF_GateWood"
    for x in (0.0, GW - 0.3): box(B(p, "Wood_Dark"), x, x + 0.3, -0.16, 0.16, 0.0, GH)      # stiles (the hinge stile at x 0)
    for z in (0.0, GH - 0.3, GH / 2 - 0.15): box(B(p, "Wood_Dark"), 0.3, GW - 0.3, -0.16, 0.16, z, z + 0.3)   # rails
    slab(B(p, "Wood_Dark"), (0.35, 0.35), (GW - 0.35, GH - 0.35), 0.3, 0.22)                 # the diagonal brace
    x = 0.36
    while x + 0.56 <= GW - 0.34:                                                           # boards on the front
        box(B(p, "Wood_Mid"), x, x + 0.56, -0.26, -0.16, 0.3, GH - 0.3); x += 0.62
def gate_vermilion():
    p = "JF_GateVermilion"
    for x in (0.0, GW - 0.3): box(B(p, "Vermilion"), x, x + 0.3, -0.18, 0.18, 0.0, GH)
    for z in (0.0, GH - 0.3, 2.0): box(B(p, "Vermilion"), 0.3, GW - 0.3, -0.18, 0.18, z, z + 0.3)
    x = 0.55
    while x <= GW - 0.5:                                                                   # lattice slats
        box(B(p, "Black"), x - 0.08, x + 0.08, -0.08, 0.08, 2.3, GH - 0.3); x += 0.5
    box(B(p, "Black"), 0.3, GW - 0.3, -0.26, 0.26, 0.3, 2.0)                               # a solid black lower panel
def sign_board():
    p = "JF_SignBoard"
    # the posts sit BEHIND the board (+y is the back), never through it - Shannon: "the pole sticking through the sign ...
    # it happens every time" (signfix1, Oct 23). Front face of the board at y -0.08; posts from y +0.06 back.
    for x in (-2.0, 2.0): box(B(p, "Wood_Dark"), x - 0.18, x + 0.18, 0.06, 0.42, -0.4, 3.9)
    box(B(p, "Board"), -2.5, 2.5, -0.08, 0.08, 2.4, 4.0)
    box(B(p, "Wood_Cap"), -2.6, 2.6, -0.2, 0.2, 4.0, 4.18)                                 # a little roof strip
def finish():
    objs = {}
    for (piece, col), bm in BMS.items():
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
        bmesh.ops.triangulate(bm, faces=bm.faces, quad_method="BEAUTY", ngon_method="EAR_CLIP")
        name = piece if len([1 for (pp, _) in BMS if pp == piece]) == 1 else piece + "__" + col
        me = bpy.data.meshes.new(name); bm.normal_update(); bm.to_mesh(me); bm.free()
        o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o); me.materials.append(material(col))
        for pg in me.polygons: pg.use_smooth = False
        objs[name] = o
    return objs
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    wood_section(); wood_endpost(); bamboo_section(); bamboo_endpost(); gate_wood(); gate_vermilion(); sign_board()
    objs = finish()
    # pieces side by side for the export (their positions do not matter: the installer places them) - offset for the renders
    offs = {"JF_WoodSection": (-10, 0), "JF_WoodPost": (-5, 0), "JF_BambooSection": (0, 0), "JF_BambooPost": (5, 0), "JF_GateWood": (7, 0), "JF_GateVermilion": (12, 0), "JF_SignBoard": (20, 0)}
    bpy.ops.object.select_all(action="DESELECT")
    for n, o in objs.items(): o.select_set(True)
    bpy.context.view_layer.objects.active = list(objs.values())[0]
    bpy.ops.export_scene.fbx(filepath=os.path.join(OUT, "japan_fence_kit.fbx"), use_selection=True, axis_forward="-Z", axis_up="Y",
                             apply_scale_options="FBX_SCALE_ALL", add_leaf_bones=False, bake_space_transform=True)
    log("FBX: " + ", ".join(f"{n} {sum(len(p.vertices) - 2 for p in o.data.polygons)} tris" for n, o in objs.items()))
    log("FBX_DONE")
    for n, o in objs.items():
        base = n.split("__")[0]; o.location = Vector((offs[base][0], offs[base][1], 0))
    sc = bpy.context.scene
    bpy.ops.mesh.primitive_plane_add(size=80, location=(5, 0, -0.01)); g = bpy.context.active_object
    gm = bpy.data.materials.new("Lawn"); gm.use_nodes = True; gm.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (lin(0.36), lin(0.62), lin(0.30), 1); g.data.materials.append(gm)
    sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 48; sc.cycles.use_denoising = False
    sc.render.resolution_x, sc.render.resolution_y = 1400, 600
    sc.world = bpy.data.worlds.new("W"); sc.world.use_nodes = True
    bg = sc.world.node_tree.nodes["Background"]; bg.inputs["Color"].default_value = (lin(0.62), lin(0.80), lin(0.95), 1); bg.inputs["Strength"].default_value = 1.0
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")); sc.collection.objects.link(sun)
    sun.rotation_euler = (math.radians(50), math.radians(15), math.radians(-60)); sun.data.energy = 3.5
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam
    def shot(fn, loc, target, lens=35):
        cam.data.lens = lens; cam.location = Vector(loc); d = Vector(target) - cam.location
        cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(OUT, fn); bpy.ops.render.render(write_still=True); log("shot " + fn)
    shot("kit_all.png", (6, -34, 14), (6, 0, 4), 32)
    shot("kit_wood_close.png", (-8, -11, 6), (-8, 0, 4), 40)
    shot("kit_bamboo_close.png", (2, -11, 6), (2, 0, 4), 40)
    shot("kit_gates_close.png", (10.5, -13, 5), (10.5, 0, 3.2), 40)
    log("KIT_DONE")
except Exception:
    log(traceback.format_exc()); log("KIT_FAILED")
