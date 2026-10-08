"""3/4 pictures of the hang glider's sail choices, from behind and above (the way the game's camera sees it in flight),
with its tubes and bar, against the sky - one render.png per scheme folder.
Run: blender --background --python render_glider_preview.py -- <log_dir> <scheme_dir> [<scheme_dir> ...]"""
import bpy, sys, os, math, traceback
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
LOGD, DIRS = argv[0], argv[1:]
LOG = os.path.join(LOGD, "glider_preview_log.txt")


def log(m):
    with open(LOG, "a") as f:
        f.write(str(m) + "\n")


def B(p, cy=0.2564, cz=-1.4):
    """a point in the glider's Roblox frame (x right, y up, -z the nose) -> Blender, for the pre-turned, centred OBJ"""
    return Vector((-p[0], p[2] - cz, p[1] - cy))


def tube(a, b, r, mat):
    a, b = B(a), B(b)
    d = b - a
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=r, depth=d.length, location=(a + b) / 2)
    o = bpy.context.active_object
    o.rotation_euler = d.to_track_quat("Z", "Y").to_euler()
    o.data.materials.append(mat)
    return o


try:
    open(LOG, "w").close()
    for d in DIRS:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        sc = bpy.context.scene
        bpy.ops.wm.obj_import(filepath=os.path.join(d, "Glider.obj"), forward_axis="NEGATIVE_Z", up_axis="Y")
        steel = bpy.data.materials.new("Steel"); steel.diffuse_color = (0.74, 0.75, 0.79, 1)
        tube((0, -0.1, -4.9), (0, -0.1, 2.15), 0.11, steel)                        # keel
        for sx in (-1, 1):
            tube((0, -0.05, -4.95), (sx * 6.4, 0.3, 1.4), 0.1, steel)            # leading edges
        hang, barL, barR = (0, -0.12, -1.0), (-1.55, -2.5, -0.7), (1.55, -2.5, -0.7)
        tube(hang, barL, 0.08, steel); tube(hang, barR, 0.08, steel); tube(barL, barR, 0.09, steel)
        sc.render.engine = "BLENDER_WORKBENCH"
        sh = sc.display.shading
        sh.light = "FLAT"; sh.color_type = "TEXTURE"; sh.show_shadows = False; sh.show_cavity = False
        sh.background_type = "VIEWPORT"; sh.background_color = (0.53, 0.74, 0.93)
        sc.render.resolution_x, sc.render.resolution_y = 900, 560
        sc.render.image_settings.file_format = "PNG"
        sc.view_settings.view_transform = "Standard"
        cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam)
        sc.collection.objects.link(camo); sc.camera = camo
        cam.lens = 40
        target = B((0, -0.6, -1.2))
        camo.location = target + Vector((5.5, 12.5, 7.5))                          # behind (+y is aft), to the right, above
        camo.rotation_euler = (target - camo.location).to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(d, "render.png")
        bpy.ops.render.render(write_still=True)
        log("rendered " + d)
    log("PREVIEW_DONE")
except Exception:
    log(traceback.format_exc())
