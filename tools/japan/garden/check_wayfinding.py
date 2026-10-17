"""Render the wayfinding kit: a fingerpost with four fingers turned different ways, the map board, a nobori banner, on a lawn, with a
6.3-tall stand-in figure for scale. Cameras in the local frame (x, y up, z). out_wayfinding/prev_wayfinding_*.png"""
import bpy, math, os, traceback
from mathutils import Vector, Matrix
D = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(D, "out_wayfinding")
LOG = os.path.join(OUT, "check_log.txt")
def log(m): open(LOG, "a").write(str(m) + "\n"); print(m)
def P(x, y, z): return (x, -z, y)
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=os.path.join(OUT, "japan_kit18_wayfinding.fbx"), axis_forward="-Z", axis_up="Y")
    kit = {o.name: o for o in bpy.data.objects if o.type == "EMPTY"}
    log("empties: " + ", ".join(sorted(kit)))
    def place(name, at, yaw):
        src = kit[name]
        for ch in src.children:
            c = ch.copy(); c.data = ch.data; bpy.context.scene.collection.objects.link(c); c.parent = None
            c.matrix_world = Matrix.Translation(P(*at)) @ Matrix.Rotation(yaw, 4, "Z") @ Matrix.Translation(-src.matrix_world.translation) @ ch.matrix_world
    place("sign_post", (0, 0, 0), 0)
    for i, yaw in enumerate((0.3, 2.2, -1.4, 3.6)): place("sign_finger", (0, 7.6 - 0.9 * i, 0), yaw)
    place("map_board", (-9, 0, -2), 0.3)
    place("nobori_banner", (8, 0, -3), 0)
    for e in list(kit.values()):
        for ch in list(e.children): bpy.data.objects.remove(ch, do_unlink=True)
        bpy.data.objects.remove(e, do_unlink=True)
    bpy.ops.mesh.primitive_plane_add(size=80, location=(0, 0, 0)); g = bpy.context.active_object
    m = bpy.data.materials.new("lawn"); m.diffuse_color = (0.2, 0.38, 0.14, 1); g.data.materials.append(m)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.9, depth=5.2, location=P(4, 2.6, 4)); fig = bpy.context.active_object
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.6, location=P(4, 5.7, 4)); head = bpy.context.active_object
    mf = bpy.data.materials.new("figure"); mf.diffuse_color = (0.75, 0.75, 0.78, 1)
    for o in (fig, head): o.data.materials.append(mf)
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"; sc.display.shading.color_type = "MATERIAL"; sc.display.shading.light = "STUDIO"; sc.display.shading.show_shadows = True
    sc.render.resolution_x, sc.render.resolution_y = 1000, 560
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam; cam.data.lens = 24
    for fn, loc, target in (("prev_wayfinding_all.png", (6, 6.5, 22), (-1, 4.5, 0)), ("prev_wayfinding_post.png", (5, 5.5, 9), (0, 5.5, 0))):
        cam.location = P(*loc)
        cam.rotation_euler = (Vector(P(*target)) - Vector(P(*loc))).to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(OUT, fn); bpy.ops.render.render(write_still=True); log("shot " + fn)
    log("CHECK_DONE")
except Exception:
    log(traceback.format_exc()); log("CHECK_FAILED")
