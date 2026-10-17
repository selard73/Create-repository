"""Render the greengrocer front kit as the installer lays it out: a stand-in back wall (plaster 30 x 12 at z -1..0) with a dark roof
slab above it, the lane floor, all seven pieces in place. out_shopfront/prev_mikan_*.png"""
import bpy, math, os, traceback
from mathutils import Vector, Matrix
D = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(D, "out_shopfront")
LOG = os.path.join(OUT, "check_log.txt")
def log(m): open(LOG, "a").write(str(m) + "\n"); print(m)
def P(x, y, z): return (x, -z, y)
def mat(name, c):
    m = bpy.data.materials.new(name); m.diffuse_color = (c[0], c[1], c[2], 1); return m
def block(name, c0, c1, m):
    x0, y0, z0 = c0; x1, y1, z1 = c1
    bpy.ops.mesh.primitive_cube_add(size=1, location=P((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2))
    o = bpy.context.active_object; o.name = name; o.scale = (x1 - x0, z1 - z0, y1 - y0); o.data.materials.append(m); return o
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=os.path.join(OUT, "japan_kit21_mikan_front.fbx"), axis_forward="-Z", axis_up="Y")
    kit = {o.name: o for o in bpy.data.objects if o.type == "EMPTY"}
    log("empties: " + ", ".join(sorted(kit)))
    def place(name, at, yaw=0.0):
        src = kit[name]
        for ch in src.children:
            c = ch.copy(); c.data = ch.data; bpy.context.scene.collection.objects.link(c); c.parent = None
            c.matrix_world = Matrix.Translation(P(*at)) @ Matrix.Rotation(yaw, 4, "Z") @ Matrix.Translation(-src.matrix_world.translation) @ ch.matrix_world
    place("front_awning", (0, 0, 0)); place("sign_board", (0, 5.6, 10.5))
    place("jar_shelf", (-11.5, 0, 0.9)); place("jar_shelf", (11.5, 0, 0.9))
    place("basket_bench", (-6, 0, 12.5)); place("basket_bench", (6, 0, 12.5))
    place("potted_bamboo", (-15.2, 0, 10.2)); place("potted_bamboo", (15.2, 0, 10.2))
    place("andon_sign", (-14, 0, 13.2)); place("side_banner", (-14.3, 0, 2.5)); place("side_banner", (14.3, 0, 2.5))
    for e in list(kit.values()):
        for ch in list(e.children): bpy.data.objects.remove(ch, do_unlink=True)
        bpy.data.objects.remove(e, do_unlink=True)
    plaster = mat("plaster", (0.62, 0.56, 0.45)); timber = mat("timber", (0.22, 0.15, 0.10)); roof = mat("roof", (0.2, 0.2, 0.22)); lane = mat("lane", (0.45, 0.47, 0.5))
    block("wall", (-15, 0, -1.0), (15, 12, 0.0), plaster)
    for x in (-15.3, 15.0): block("post", (x, 0, -0.2), (x + 0.3, 12, 0.25), timber)
    block("roof", (-16, 10.8, -1.0), (16, 11.6, 1.2), roof)
    block("lane", (-40, -0.3, -2), (40, 0.0, 40), lane)
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"; sc.display.shading.color_type = "MATERIAL"; sc.display.shading.light = "STUDIO"; sc.display.shading.show_shadows = True; sc.display.shading.show_cavity = True
    sc.render.resolution_x, sc.render.resolution_y = 1100, 560
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam; cam.data.lens = 22
    for fn, loc, target in (("prev_mikan_front.png", (-4, 5.5, 30), (0, 5.0, 4)), ("prev_mikan_quarter.png", (26, 7.0, 26), (0, 5.0, 5))):
        cam.location = P(*loc)
        cam.rotation_euler = (Vector(P(*target)) - Vector(P(*loc))).to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(OUT, fn); bpy.ops.render.render(write_still=True); log("shot " + fn)
    log("CHECK_DONE")
except Exception:
    log(traceback.format_exc()); log("CHECK_FAILED")
