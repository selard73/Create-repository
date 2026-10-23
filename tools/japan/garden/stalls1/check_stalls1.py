"""Render the stall goods kit on a stand-in counter (15.5 x 4, top at y 0), customer side -z. stalls1/out/prev_*.png"""
import bpy, os, traceback
from mathutils import Vector, Matrix
D = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(D, "out")
LOG = os.path.join(OUT, "check_log.txt")
def log(m): open(LOG, "a").write(str(m) + "\n"); print(m)
def P(x, y, z): return (x, -z, y)
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=os.path.join(OUT, "japan_kit38_stalls2.fbx"), axis_forward="-Z", axis_up="Y")
    kit = {o.name: o for o in bpy.data.objects if o.type == "EMPTY"}
    log("empties: " + ", ".join(sorted(kit)))
    def place(name, at):
        src = kit[name]
        for ch in src.children:
            c = ch.copy(); c.data = ch.data; bpy.context.scene.collection.objects.link(c); c.parent = None
            c.matrix_world = Matrix.Translation(P(*at)) @ Matrix.Translation(-src.matrix_world.translation) @ ch.matrix_world
    # two counters side by side: kakigori on the left one, takoyaki on the right one
    place("kakigori_a", (-11.5, 0, 0.3)); place("kakigori_b", (-4.5, 0, 0.3)); place("kori_flag", (-15.5, -3.0, -2.5))
    place("takoyaki_a", (4.5, 0, 0.3)); place("takoyaki_b", (11.5, 0, 0.3))
    for e in list(kit.values()):
        for ch in list(e.children): bpy.data.objects.remove(ch, do_unlink=True)
        bpy.data.objects.remove(e, do_unlink=True)
    mw = bpy.data.materials.new("counter"); mw.diffuse_color = (0.62, 0.52, 0.38, 1)
    for cx in (-8.0, 8.0):
        bpy.ops.mesh.primitive_cube_add(size=1, location=P(cx, -0.175, 0.0)); c = bpy.context.active_object
        c.scale = (7.75, 2.0, 0.175); c.data.materials.append(mw)
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"; sc.display.shading.color_type = "MATERIAL"; sc.display.shading.light = "STUDIO"; sc.display.shading.show_shadows = True
    sc.display.shading.show_cavity = True
    sc.render.resolution_x, sc.render.resolution_y = 1000, 640
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam
    for fn, loc, target, lens in (("prev_kakigori.png", (-8.0, 3.2, -7.5), (-8.0, 0.8, 0.0), 32),
                                  ("prev_kakigori_close.png", (-11.0, 2.4, -4.2), (-11.3, 0.9, 0.0), 36),
                                  ("prev_served.png", (-4.3, 2.6, -4.6), (-4.4, 1.0, 0.1), 40),
                                  ("prev_takoyaki.png", (8.0, 3.2, -7.5), (8.0, 0.6, 0.0), 32),
                                  ("prev_takoyaki_close.png", (5.5, 2.2, -4.0), (5.0, 0.4, 0.0), 36),
                                  ("prev_flag.png", (-13.0, 4.0, -9.0), (-15.0, 2.5, -2.5), 30)):
        cam.data.lens = lens
        cam.location = P(*loc)
        cam.rotation_euler = (Vector(P(*target)) - Vector(P(*loc))).to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(OUT, fn); bpy.ops.render.render(write_still=True); log("shot " + fn)
    log("CHECK_DONE")
except Exception:
    log(traceback.format_exc()); log("CHECK_FAILED")
