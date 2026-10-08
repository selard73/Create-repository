"""Blender check renders for the sculpted Sandstone Climb (cliff/cliff_preview.obj, world coordinates, with stand-ins for
the ledges, trellises, summit slab, garden wall, cypresses and start stone). Drawn with backface culling, like Roblox.
Usage: blender --background --python render_cliff.py -- [prefix]
Output: cliff/check_<prefix>_<view>.png; log in cliff/render_log.txt"""
import bpy, os, sys, math, traceback
from mathutils import Vector

D = os.path.join(os.path.dirname(os.path.abspath(__file__)), "cliff")
LOG = os.path.join(D, "render_log.txt")
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
PREFIX = argv[0] if argv else "a"

VIEWS = {
    "vineyard": ((528, 34, -176), (516, 38, -256)),
    "face": ((470, 26, -226), (470, 30, -256)),
    "east": ((606, 42, -204), (512, 36, -258)),
    "west": ((432, 46, -198), (500, 40, -258)),
    "summit": ((505, 88, -228), (496, 73, -262)),
    "route": ((526, 22, -222), (514, 16, -252)),
}


def log(*a):
    with open(LOG, "a") as fh:
        fh.write(" ".join(str(x) for x in a) + "\n")


def shot(name, eye, at, w=1400, h=800, lens=20):
    sc = bpy.context.scene
    sc.render.resolution_x, sc.render.resolution_y = w, h
    cam = sc.camera
    cam.data.lens = lens
    e = Vector((eye[0], -eye[2], eye[1])); a = Vector((at[0], -at[2], at[1]))
    cam.location = e
    cam.rotation_euler = (a - e).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = os.path.join(D, name)
    bpy.ops.render.render(write_still=True)


try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading
    sh.light = "STUDIO"; sh.color_type = "TEXTURE"; sh.show_shadows = True; sh.shadow_intensity = 0.55
    sh.show_cavity = True; sh.cavity_type = "BOTH"; sh.curvature_ridge_factor = 0.6; sh.curvature_valley_factor = 1.0
    sh.show_backface_culling = True
    sh.background_type = "VIEWPORT"; sh.background_color = (0.62, 0.78, 0.95)
    sc.display.light_direction = (0.45, -0.55, 0.7)
    sc.view_settings.view_transform = "Standard"
    sc.render.image_settings.file_format = "PNG"
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam)
    sc.collection.objects.link(camo); sc.camera = camo
    cam.clip_end = 2000
    bpy.ops.wm.obj_import(filepath=os.path.join(D, "cliff_preview.obj"), forward_axis="NEGATIVE_Z", up_axis="Y")
    # grass
    bpy.ops.mesh.primitive_plane_add(size=600, location=(516, 250, 4.0))
    g = bpy.context.active_object
    m = bpy.data.materials.new("grass"); m.diffuse_color = (0.36, 0.52, 0.28, 1); g.data.materials.append(m)
    n = 0
    for o in bpy.data.objects:
        if o.type == "MESH":
            n += 1
            for s in o.data.polygons:
                s.use_smooth = o.name.startswith("SandCliff") or o.name.startswith("SandBoulder")
    log("objects", n)
    for v, (eye, at) in VIEWS.items():
        shot("check_%s_%s.png" % (PREFIX, v), eye, at)
        log("rendered", v)
except Exception:
    log(traceback.format_exc())
