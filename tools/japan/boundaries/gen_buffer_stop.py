"""Buffer stop for the Japan railway (Oct 23 2026) - Shannon: "you need to make this in blender rather than using roblox shapes,
they always come out wrong". One rigid model, every member meeting the next: a steel frame (two posts on a sill, two angled
back-struts from the post tops to the far end of the sill, a tie between the strut feet, a cross-bar between the posts), a red
beam with two white stripes on the posts' track face, two round buffer heads on the beam, and two wooden sleepers under the
frame. Units = studs, x along the track (the track arrives from +x; the heads face +x), y across, z up; FBX -Z forward / Y up
as the church, so Roblox gets x along the track, y up. Studio materials from the installer (names = colour keys).
Rail gauge 5.6 (rails at y +-2.8), rail top 1.65 above the ballast top; the sleeper tops at 0.3 (this file's z 0 = ballast top).
Run: python croc/run_blender.py tools/japan/boundaries/out/stop_log.txt STOP tools/japan/boundaries/gen_buffer_stop.py"""
import bpy, bmesh, math, os, traceback
from mathutils import Vector, Matrix

D = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(D, "out"); os.makedirs(OUT, exist_ok=True)
LOG = os.path.join(OUT, "stop_log.txt")
def log(m): open(LOG, "a").write(str(m) + "\n"); print(m)
COL = {"BS_Steel": (0.17, 0.18, 0.20), "BS_Red": (0.77, 0.16, 0.12), "BS_White": (0.94, 0.93, 0.89), "BS_Head": (0.27, 0.28, 0.30), "BS_Sleeper": (0.40, 0.28, 0.19)}
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
def material(key):
    m = bpy.data.materials.get(key)
    if m: return m
    m = bpy.data.materials.new(key); m.use_nodes = True
    c = COL[key]; b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (lin(c[0]), lin(c[1]), lin(c[2]), 1); b.inputs["Roughness"].default_value = 0.6 if key == "BS_Steel" else 0.75
    return m
BMS = {}
def B(k):
    if k not in BMS: BMS[k] = bmesh.new()
    return BMS[k]
def box(bm, x0, x1, y0, y1, z0, z1):
    b = [bm.verts.new(v) for v in [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0)]]
    t = [bm.verts.new(v) for v in [(x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)]]
    for i in range(4):
        k = (i + 1) % 4; bm.faces.new([b[i], b[k], t[k], t[i]])
    bm.faces.new(list(reversed(b))); bm.faces.new(t)
def bar(bm, a, b_, w, h):
    """a square bar from point a to point b (Vectors), w wide (y), h thick (perpendicular in the xz plane), ends cut square"""
    a, b_ = Vector(a), Vector(b_)
    d = (b_ - a).normalized(); n = Vector((-d.z, 0, d.x)) * (h / 2); s = Vector((0, w / 2, 0))
    q = [a + n + s, a + n - s, a - n - s, a - n + s]
    r = [p + (b_ - a) for p in q]
    va = [bm.verts.new(p) for p in q]; vb = [bm.verts.new(p) for p in r]
    for i in range(4):
        k = (i + 1) % 4; bm.faces.new([va[i], vb[i], vb[k], va[k]])
    bm.faces.new(list(reversed(va))); bm.faces.new(vb)
def cyl_x(bm, x0, x1, cy, cz, r, seg=16):
    a = [bm.verts.new((x0, cy + r * math.cos(2 * math.pi * i / seg), cz + r * math.sin(2 * math.pi * i / seg))) for i in range(seg)]
    b = [bm.verts.new((x1, cy + r * math.cos(2 * math.pi * i / seg), cz + r * math.sin(2 * math.pi * i / seg))) for i in range(seg)]
    for i in range(seg): bm.faces.new([a[i], b[i], b[(i + 1) % seg], a[(i + 1) % seg]])
    bm.faces.new(a); bm.faces.new(list(reversed(b)))

G = 2.8                      # half gauge
SLEEPER_TOP = 0.3
RAIL_TOP = 1.65
POST_X = 0.0                 # the posts' centre line; the track arrives from +x
STRUT_FOOT_X = -2.8          # the back-struts' feet
POST_TOP = RAIL_TOP + 2.6
BEAM_Z = RAIL_TOP + 1.95
st, red, wh, hd, sl = B("BS_Steel"), B("BS_Red"), B("BS_White"), B("BS_Head"), B("BS_Sleeper")
# sleepers under the posts and under the strut feet, full track width
for x in (POST_X, STRUT_FOOT_X): box(sl, x - 0.6, x + 0.6, -5.0, 5.0, 0.0, SLEEPER_TOP)
for s in (-1, 1):
    y = s * G
    # the sill: a flat steel bar from the strut foot to the post, on the sleepers, carrying both
    box(st, STRUT_FOOT_X - 0.55, POST_X + 0.55, y - 0.35, y + 0.35, SLEEPER_TOP, SLEEPER_TOP + 0.22)
    # the post, standing on the sill
    box(st, POST_X - 0.26, POST_X + 0.26, y - 0.26, y + 0.26, SLEEPER_TOP + 0.22, POST_TOP)
    # the back-strut: from the post's top (inside its width, so they join) to the sill's far end
    bar(st, (POST_X - 0.1, y, POST_TOP - 0.3), (STRUT_FOOT_X + 0.15, y, SLEEPER_TOP + 0.22), 0.3, 0.3)
    # a horizontal stiffener from the post to the strut at mid height: its far end lands ON the strut's centre line
    # (the strut runs from (POST_X - 0.1, POST_TOP - 0.3) to (STRUT_FOOT_X + 0.15, SLEEPER_TOP + 0.22): x at a given z by linear interpolation)
    zk = SLEEPER_TOP + 1.5
    t = (zk - (SLEEPER_TOP + 0.22)) / ((POST_TOP - 0.3) - (SLEEPER_TOP + 0.22))
    xk = (STRUT_FOOT_X + 0.15) + t * ((POST_X - 0.1) - (STRUT_FOOT_X + 0.15))
    bar(st, (POST_X - 0.2, y, zk), (xk + 0.08, y, zk), 0.2, 0.2)
# the tie between the strut feet and the cross-bar between the posts
box(st, STRUT_FOOT_X - 0.2, STRUT_FOOT_X + 0.2, -G - 0.2, G + 0.2, SLEEPER_TOP + 0.22, SLEEPER_TOP + 0.62)
box(st, POST_X - 0.2, POST_X + 0.2, -G, G, SLEEPER_TOP + 1.0, SLEEPER_TOP + 1.4)
# the beam on the posts' track face: a steel backing bar, the red face with white stripes
box(st, POST_X + 0.26, POST_X + 0.5, -G - 0.4, G + 0.4, BEAM_Z - 0.6, BEAM_Z + 0.6)
box(red, POST_X + 0.5, POST_X + 0.9, -G - 0.5, G + 0.5, BEAM_Z - 0.62, BEAM_Z + 0.62)
for y in (-1.7, 1.7): box(wh, POST_X + 0.9, POST_X + 0.93, y - 0.33, y + 0.33, BEAM_Z - 0.6, BEAM_Z + 0.6)
# the buffer heads: a short shank from the beam and a round head, on each rail line
for s in (-1, 1):
    y = s * G
    cyl_x(hd, POST_X + 0.9, POST_X + 1.25, y, BEAM_Z, 0.28, 12)
    cyl_x(hd, POST_X + 1.25, POST_X + 1.55, y, BEAM_Z, 0.62, 20)
def finish():
    objs = []
    for key, bm in BMS.items():
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        bmesh.ops.triangulate(bm, faces=bm.faces, quad_method="BEAUTY", ngon_method="EAR_CLIP")
        me = bpy.data.meshes.new(key); bm.normal_update(); bm.to_mesh(me); bm.free()
        o = bpy.data.objects.new(key, me); bpy.context.scene.collection.objects.link(o); me.materials.append(material(key))
        for p in me.polygons: p.use_smooth = key == "BS_Head"
        objs.append(o)
    return objs
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    objs = finish()
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.fbx(filepath=os.path.join(OUT, "japan_buffer_stop.fbx"), use_selection=True, axis_forward="-Z", axis_up="Y",
                             apply_scale_options="FBX_SCALE_ALL", add_leaf_bones=False, bake_space_transform=True)
    log("FBX: " + ", ".join(f"{o.name} {sum(len(p.vertices) - 2 for p in o.data.polygons)} tris" for o in objs)); log("FBX_DONE")
    sc = bpy.context.scene
    bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, -0.01)); g = bpy.context.active_object
    gm = bpy.data.materials.new("Ballast"); gm.use_nodes = True; gm.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (lin(0.41), lin(0.44), lin(0.46), 1); g.data.materials.append(gm)
    # two rails for the render
    rb = bmesh.new()
    for s in (-1, 1): box(rb, 0.6, 14, s * G - 0.125, s * G + 0.125, 1.35, 1.65)
    rm = bpy.data.meshes.new("rails"); rb.to_mesh(rm); rb.free(); ro = bpy.data.objects.new("rails", rm); sc.collection.objects.link(ro); ro.data.materials.append(material("BS_Steel"))
    sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 48; sc.cycles.use_denoising = False
    sc.render.resolution_x, sc.render.resolution_y = 1100, 650
    sc.world = bpy.data.worlds.new("W"); sc.world.use_nodes = True
    bg = sc.world.node_tree.nodes["Background"]; bg.inputs["Color"].default_value = (lin(0.62), lin(0.80), lin(0.95), 1); bg.inputs["Strength"].default_value = 1.0
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")); sc.collection.objects.link(sun)
    sun.rotation_euler = (math.radians(50), math.radians(15), math.radians(-60)); sun.data.energy = 3.5
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam
    def shot(fn, loc, target, lens=40):
        cam.data.lens = lens; cam.location = Vector(loc); d = Vector(target) - cam.location
        cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(OUT, fn); bpy.ops.render.render(write_still=True); log("shot " + fn)
    shot("stop_three_quarter.png", (9, -11, 6), (0, 0, 2.2))
    shot("stop_side.png", (-1, -12, 3.5), (-1, 0, 2.2))
    shot("stop_back.png", (-10, -6, 5), (-0.5, 0, 2.2))
    log("STOP_DONE")
except Exception:
    log(traceback.format_exc()); log("STOP_FAILED")
