"""Close-up ortho renders of a region of a squirrel (default the face) from a prepped .blend OR a raw Meshy .fbx
(raw fbx is normalised like prep_squirrel: height 2.4, feet z=0, centred).
Run: blender -b --python face_zoom.py -- <in.blend|in.fbx> <out_prefix> <cx> <cz> <ortho_scale> [views=front,q34l,q34r]"""
import bpy, sys, os, math, traceback
from mathutils import Vector
argv = sys.argv[sys.argv.index("--") + 1:]
IN, OUT = argv[0], argv[1]; CX, CZ, S = float(argv[2]), float(argv[3]), float(argv[4])
VIEWS = (argv[5] if len(argv) > 5 else "front,q34l,q34r").split(",")
LOG = OUT + "_log.txt"
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
try:
    open(LOG, "w").close()
    if IN.lower().endswith(".fbx"):
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.fbx(filepath=IN)
        ms = [o for o in bpy.data.objects if o.type == "MESH"]
        for o in bpy.data.objects: o.select_set(o.type == "MESH")
        bpy.context.view_layer.objects.active = ms[0]
        if len(ms) > 1: bpy.ops.object.join()
        sq = bpy.context.view_layer.objects.active
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        vs = [v.co for v in sq.data.vertices]
        lo = Vector((min(v.x for v in vs), min(v.y for v in vs), min(v.z for v in vs)))
        hi = Vector((max(v.x for v in vs), max(v.y for v in vs), max(v.z for v in vs)))
        s = 2.4 / (hi.z - lo.z)
        sq.location = (-(lo.x + hi.x) / 2 * s, -(lo.y + hi.y) / 2 * s, -lo.z * s); sq.scale = (s, s, s)
    else:
        bpy.ops.wm.open_mainfile(filepath=IN)
        for o in list(bpy.data.objects):
            if o.type != "MESH" or o.name != "Squirrel": bpy.data.objects.remove(o)
    sc = bpy.context.scene; sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "TEXTURE"; sh.show_shadows = False
    sc.render.resolution_x = sc.render.resolution_y = 700; sc.render.image_settings.file_format = "PNG"
    cam = bpy.data.cameras.new("ZCam"); co = bpy.data.objects.new("ZCam", cam); sc.collection.objects.link(co); sc.camera = co
    cam.type = "ORTHO"; cam.ortho_scale = S
    ctr = Vector((CX, -0.3, CZ))
    dirs = {"front": Vector((0, -1, 0)), "q34l": Vector((-0.7, -0.7, 0)), "q34r": Vector((0.7, -0.7, 0)), "up": Vector((0, -0.8, -0.6))}
    for v in VIEWS:
        co.location = ctr + dirs[v] * 10
        co.rotation_euler = (ctr - co.location).to_track_quat("-Z", "Z").to_euler()
        sc.render.filepath = f"{OUT}_{v}.png"; bpy.ops.render.render(write_still=True)
    log("ZOOM_DONE")
except Exception:
    log(traceback.format_exc())
