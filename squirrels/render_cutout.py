"""Big, clean, see-through cutouts of squirrels for thumbnails and posters: each <name>/<name>_rigged.blend rendered from a
little to the front-right (so the squirrel looks toward the left of the picture), on a transparent background.
Run: blender --background --python render_cutout.py -- <out_dir> <name> [<name> ...]
Writes <out_dir>/cutout_<name>.png (1400 x 1400, RGBA) and <out_dir>/cutout_log.txt."""
import bpy, sys, os, traceback
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
OUTD, NAMES = argv[0], argv[1:]
HERE = os.path.dirname(os.path.abspath(__file__))
LOG = os.path.join(OUTD, "cutout_log.txt")


def log(m):
    with open(LOG, "a") as f:
        f.write(str(m) + "\n")


open(LOG, "w").close()
for name in NAMES:
    try:
        bpy.ops.wm.open_mainfile(filepath=os.path.join(HERE, name, f"{name}_rigged.blend"))
        sq = bpy.data.objects["Squirrel"]
        pts = [sq.matrix_world @ v.co for v in sq.data.vertices]
        lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
        hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
        ctr = (lo + hi) / 2
        span = max(hi.x - lo.x, hi.y - lo.y, hi.z - lo.z)
        sc = bpy.context.scene
        sc.render.engine = "BLENDER_WORKBENCH"
        sh = sc.display.shading
        sh.light = "STUDIO"; sh.color_type = "TEXTURE"; sh.show_shadows = False; sh.show_cavity = False
        sc.display.render_aa = "32"
        sc.render.film_transparent = True
        sc.render.resolution_x = sc.render.resolution_y = 1400
        sc.render.image_settings.file_format = "PNG"; sc.render.image_settings.color_mode = "RGBA"
        sc.view_settings.view_transform = "Standard"
        for o in list(bpy.data.objects):
            if o.type == "CAMERA": bpy.data.objects.remove(o)
        cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam)
        sc.collection.objects.link(camo); sc.camera = camo
        cam.type = "ORTHO"; cam.ortho_scale = span * 1.08
        camo.location = ctr + Vector((0.3, -1.0, 0.16)).normalized() * (span * 3)   # (the squirrels face -Y)
        camo.rotation_euler = (ctr - camo.location).to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(OUTD, f"cutout_{name}.png")
        bpy.ops.render.render(write_still=True)
        log(f"{name}: rendered, span {span:.2f}")
    except Exception:
        log(f"{name}: " + traceback.format_exc())
log("CUTOUT_DONE")
