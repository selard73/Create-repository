"""Preview renders of the tide pools (tidepools_preview.obj from gen_tidepools.py), Eevee + sun + sky like the gorge renders.
Usage: blender --background --python render_tidepools.py -- [prefix]   -> renders/<prefix>_<view>.png, renders/render_log.txt"""
import bpy, os, sys, math, traceback
from mathutils import Vector

D = os.path.dirname(os.path.abspath(__file__))
OUTD = os.path.join(D, "renders"); os.makedirs(OUTD, exist_ok=True)
LOG = os.path.join(OUTD, "render_log.txt")
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
PREFIX = argv[0] if argv else "a"
SKY = (0.60, 0.77, 0.95)
VIEWS = {   # game coordinates: eye, look-at, lens
    "cove": ((305.5, -45.6, -781.0), (292.0, -52.4, -785.0), 22),      # standing on the sandy cove, looking out over the shelf
    "low": ((286.0, -49.8, -800.5), (295.0, -52.0, -784.0), 20),       # crouched at the sea edge, pools at eye level
    "above": ((279.0, -38.0, -768.0), (296.0, -52.5, -786.0), 22),     # the bird's-eye from the old-pools screenshot side
    "close": ((297.8, -48.6, -790.0), (293.6, -52.2, -794.8), 30),     # one pool close up
}


def log(*a):
    open(LOG, "a").write(" ".join(str(x) for x in a) + "\n")


def g2b(p):
    return Vector((p[0], -p[2], p[1]))


try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    for eng in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE"):
        try:
            sc.render.engine = eng; break
        except Exception:
            continue
    sc.view_settings.view_transform = "Standard"; sc.view_settings.exposure = -0.2
    sc.render.image_settings.file_format = "PNG"
    world = bpy.data.worlds.new("Sky"); sc.world = world; world.use_nodes = True
    bg = world.node_tree.nodes.get("Background"); bg.inputs[0].default_value = (*SKY, 1); bg.inputs[1].default_value = 0.8
    sun_d = bpy.data.lights.new("Sun", "SUN"); sun_d.energy = 3.3; sun_d.angle = math.radians(1.5)
    sun = bpy.data.objects.new("Sun", sun_d); sc.collection.objects.link(sun)
    sun.rotation_euler = g2b((0.35, -0.8, -0.5)).normalized().to_track_quat("-Z", "Y").to_euler()
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(camo); sc.camera = camo
    cam.clip_start = 0.05; cam.clip_end = 2000
    bpy.ops.wm.obj_import(filepath=os.path.join(D, "tidepools_preview.obj"), forward_axis="NEGATIVE_Z", up_axis="Y")
    for o in bpy.data.objects:
        if o.type == "MESH":
            for p in o.data.polygons:
                p.use_smooth = o.name.startswith("TidePoolShelf")
    ALPHA = {"PoolWater": 0.42, "Sea": 0.78}
    for m in bpy.data.materials:
        a = next((v for k, v in ALPHA.items() if m.name.startswith(k)), None)
        if a is None or not m.use_nodes:
            continue
        b = m.node_tree.nodes.get("Principled BSDF")
        if b:
            b.inputs["Alpha"].default_value = a
            b.inputs["Roughness"].default_value = 0.15
        try:
            m.blend_method = "BLEND"
        except Exception:
            pass
        try:
            m.surface_render_method = "BLENDED"
        except Exception:
            pass
    for name, (eye, at, lens) in VIEWS.items():
        sc.render.resolution_x, sc.render.resolution_y = 1400, 800
        cam.lens = lens
        e, a = g2b(eye), g2b(at)
        camo.location = e
        camo.rotation_euler = (a - e).to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(OUTD, f"{PREFIX}_{name}.png")
        bpy.ops.render.render(write_still=True)
        log("rendered", name)
    log("RENDER_DONE")
except Exception:
    log(traceback.format_exc())
