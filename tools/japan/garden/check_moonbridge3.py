"""Render the round-2 bridge end against a stand-in of the real bridge end: the last three deck planks (9 wide, rising 17-18 deg), the
red rails and the bridge's own end posts at x +-4.3, the court plane at 0 and the pond wall's ledge (top 1.0 at z -2.1 and inward).
Workbench, material colours. out_moonbridge3/prev_*.png"""
import bpy, math, os, traceback
from mathutils import Vector, Matrix
D = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(D, "out_moonbridge3")
LOG = os.path.join(OUT, "check_log.txt")
def log(m): open(LOG, "a").write(str(m) + "\n"); print(m)
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
def mat(name, c):
    m = bpy.data.materials.new(name); m.diffuse_color = (lin(c[0]), lin(c[1]), lin(c[2]), 1); return m
def P(x, y, z): return (x, -z, y)
def block(name, c0, c1, m, rot=None, pivot=None):
    x0, y0, z0 = c0; x1, y1, z1 = c1
    bpy.ops.mesh.primitive_cube_add(size=1, location=P((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2))
    o = bpy.context.active_object; o.name = name; o.scale = (x1 - x0, z1 - z0, y1 - y0)
    o.data.materials.append(m)
    if rot is not None:
        o.rotation_euler = (rot, 0, 0)
    return o
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=os.path.join(OUT, "japan_kit17_moonbridge_end3.fbx"), axis_forward="-Z", axis_up="Y")
    wood = mat("deck", (0.40, 0.28, 0.19)); red = mat("red", (0.70, 0.21, 0.12)); court = mat("court", (0.33, 0.27, 0.22)); stone = mat("ledge", (0.85, 0.85, 0.83)); water = mat("water", (0.16, 0.41, 0.44))
    # three deck planks, 4.5 long each, climbing 18 deg from the deck end (top 1.92 at z 0) inward (negative z)
    a = math.radians(17.7)
    for i in range(3):
        zc = -(i + 0.5) * 4.5 * math.cos(a); yc = 1.92 - 0.2 + (i + 0.5) * 4.5 * math.sin(a)
        bpy.ops.mesh.primitive_cube_add(size=1, location=P(0, yc, zc)); o = bpy.context.active_object; o.scale = (9, 4.5, 0.4)
        o.rotation_euler = (a, 0, 0); o.data.materials.append(wood)
        for s in (1, -1):
            for (h, th) in ((4.65, 0.4), (2.85, 0.2)):
                bpy.ops.mesh.primitive_cube_add(size=1, location=P(s * 4.3, yc + 0.2 + h - 1.92 + 0.02, zc)); r = bpy.context.active_object; r.scale = (th, 4.5, th)
                r.rotation_euler = (a, 0, 0); r.data.materials.append(red)
    block("court", (-40, -0.4, -40), (40, 0.0, 6.6), court)                                   # the pond apron, 3.19
    block("court2", (-40, -0.6, 6.6), (40, -0.19, 40), court)                                 # the palace court beyond, 3.00
    for s in (1, -1): block("sidepost", (s * 4.3 - 0.22, 1.7, -0.22), (s * 4.3 + 0.22, 5.1, 0.22), red)
    block("ledge", (-40, 0.0, -40), (40, 1.0, -2.1), stone)
    block("water", (-40, 0.0, -40), (40, 0.8, -8.0), water)
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"; sc.display.shading.color_type = "MATERIAL"; sc.display.shading.light = "STUDIO"; sc.display.shading.show_shadows = True
    sc.render.resolution_x, sc.render.resolution_y = 1000, 560
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam; cam.data.lens = 28
    # cameras in the LOCAL frame (x, y up, z outward): the court side is +z
    for fn, loc, target in (("prev_mb3_three_quarter.png", (-12, 5.5, 13), (0, 1.6, 1.5)), ("prev_mb3_front.png", (0, 4.5, 16), (0, 2.2, 0)), ("prev_mb3_side.png", (-15, 3.4, 1.4), (0, 2.0, 1.5)), ("prev_mb3_from_pond.png", (-9, 4.0, -9), (0, 1.5, 0))):
        cam.location = P(*loc)
        cam.rotation_euler = (Vector(P(*target)) - Vector(P(*loc))).to_track_quat("-Z", "Y").to_euler()
        cam.data.clip_start = 0.3
        dg = bpy.context.evaluated_depsgraph_get()
        hit, pos, nrm, idx, obj, mtx = sc.ray_cast(dg, cam.location, (Vector(P(*target)) - Vector(P(*loc))).normalized())
        log(f"{fn}: first thing in view = {obj.name if hit else 'nothing'} at {((pos - cam.location).length if hit else 0):.1f}; camera at {tuple(round(v, 1) for v in cam.location)}")
        sc.render.filepath = os.path.join(OUT, fn); bpy.ops.render.render(write_still=True); log("shot " + fn)
    log("CHECK_DONE")
except Exception:
    log(traceback.format_exc()); log("CHECK_FAILED")
