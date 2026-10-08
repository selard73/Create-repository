"""Colour + gray 3/4 previews framed to the model's own bounding box, for squirrels whose prop (kite, parachute)
makes them taller or wider than the fixed preview camera in fix_weights.py expects.
Run: blender --background --python preview_tall.py -- <out_dir> <name>"""
import bpy, sys, os, traceback
from mathutils import Vector
argv = sys.argv[sys.argv.index("--") + 1:]
OUTD, NAME = argv[0], argv[1]
LOG = os.path.join(OUTD, "preview_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
try:
    open(LOG, "w").close()
    bpy.ops.wm.open_mainfile(filepath=os.path.join(OUTD, f"{NAME}_rigged.blend"))
    sq = bpy.data.objects["Squirrel"]
    pts = [v.co.copy() for v in sq.data.vertices]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    ctr = (lo + hi) / 2
    span = max(hi.x - lo.x, hi.z - lo.z)
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "TEXTURE"; sh.show_shadows = False
    sh.background_type = "VIEWPORT"; sh.background_color = (0.86, 0.88, 0.92)
    sc.render.resolution_x, sc.render.resolution_y = 700, 700
    sc.render.image_settings.file_format = "PNG"
    sc.view_settings.view_transform = "Standard"
    for o in list(bpy.data.objects):
        if o.type == "CAMERA": bpy.data.objects.remove(o)
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam)
    sc.collection.objects.link(camo); sc.camera = camo
    cam.type = "ORTHO"; cam.ortho_scale = span * 1.18          # ortho: no perspective stretch on a wide canopy
    camo.location = ctr + Vector((-0.55, -1.0, 0.30)).normalized() * (span * 3)
    camo.rotation_euler = (ctr - camo.location).to_track_quat("-Z", "Y").to_euler()
    tex = [n for n in sq.data.materials[0].node_tree.nodes if n.type == "TEX_IMAGE"][0]
    for tag, png in (("color", f"{NAME}_1k.png"), ("gray", f"{NAME}_gray_1k.png")):
        tex.image = bpy.data.images.load(os.path.join(OUTD, png))
        sc.render.filepath = os.path.join(OUTD, f"preview_{tag}.png")
        bpy.ops.render.render(write_still=True)
    log(f"framed {span:.2f} wide about {tuple(round(v, 2) for v in ctr)}")
    log("PREVIEW_DONE")
except Exception:
    log(traceback.format_exc())
