"""Headless Blender render of an FBX to a PNG (three-quarter view). Writes render_log.txt beside the output.
Run: blender --background --python render_pup.py -- <in.fbx> <out.png>"""
import bpy, sys, os, traceback
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
IN, OUT = argv[0], argv[1]
LOG = os.path.join(os.path.dirname(os.path.abspath(OUT)), "render_log.txt")

def log(msg):
    with open(LOG, "a") as f:
        f.write(str(msg) + "\n")

try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=IN)
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    log(f"imported {len(meshes)} meshes")
    xs, ys, zs = [], [], []
    for o in meshes:
        for v in o.bound_box:
            p = o.matrix_world @ Vector(v)
            xs.append(p.x); ys.append(p.y); zs.append(p.z)
    cx, cy, cz = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2, (min(zs) + max(zs)) / 2
    size = max(max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs))
    log(f"centre {cx:.2f},{cy:.2f},{cz:.2f} size {size:.2f}")
    # ground plane
    bpy.ops.mesh.primitive_plane_add(size=size * 8, location=(cx, cy, min(zs)))
    g = bpy.context.object
    gm = bpy.data.materials.new("Ground"); gm.diffuse_color = (0.72, 0.42, 0.28, 1)
    g.data.materials.append(gm)
    # camera
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam)
    bpy.context.scene.collection.objects.link(camo)
    camo.location = (cx + size * 1.7, cy - size * 2.0, cz + size * 0.9)
    camo.rotation_euler = (Vector((cx, cy, cz)) - camo.location).to_track_quat("-Z", "Y").to_euler()
    cam.lens = 50
    sc = bpy.context.scene
    sc.camera = camo
    # workbench: reliable headless, shows textures with studio lighting
    sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading
    sh.light = "STUDIO"
    sh.color_type = "TEXTURE"
    sh.show_shadows = True
    sh.show_cavity = False
    sc.render.resolution_x, sc.render.resolution_y = 1000, 750
    sc.render.image_settings.file_format = "PNG"
    sc.render.filepath = OUT
    bpy.ops.render.render(write_still=True)
    log("RENDER_DONE " + OUT)
except Exception:
    log(traceback.format_exc())
