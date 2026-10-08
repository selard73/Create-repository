"""Check renders of the gorge preview (gorge_sample.obj + the game's kit trees from trees.json). Eevee with a sun and a
sky-coloured world, so colours read about as they do in Roblox (the Workbench renders of the Sandstone Climb came out
much darker and browner than the game shows it). Faces are single-sided, as in Roblox. Views are in game coordinates
(x, y up, z; downstream = -z).
Usage: blender --background --python render_gorge_sample.py -- [prefix] [view ...]
Output: renders/<prefix>_<view>.png; log in renders/render_log.txt"""
import bpy, os, sys, json, math, traceback
from mathutils import Vector, Matrix

D = os.path.dirname(os.path.abspath(__file__))
OUTD = os.path.join(D, "renders")
os.makedirs(OUTD, exist_ok=True)
LOG = os.path.join(OUTD, "render_log.txt")
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
PREFIX = argv[0] if argv else "a"
ONLY = set(argv[1:])
SKY = (0.60, 0.77, 0.95)

VIEWS = {   # name: (eye, at, lens)
    "boat_approach": ((-6.5, 3.2, 62), (0, 15, 0), 16),
    "boat_under": ((-1.0, 3.0, 13), (0, 16, -6), 16),
    "glider_view": ((-8, 72, 78), (0, 18, 0), 22),
    "overview": ((-40, 120, 150), (0, 8, -10), 24),
    "pier_close": ((4, 0.2, 16), (12, 2.5, 6), 24),
    "abutment": ((-6, 24, 18), (-30, 20, 2), 24),
    "downstream_back": ((-7, 3.2, -62), (0, 15, 0), 16),
    "strata_close": ((2, 4, 52), (-14, 9, 36), 24),
    "top_cap": ((30, 44.5, 12), (44, 41, 0), 24),
}


def lin(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def log(*a):
    with open(LOG, "a") as fh:
        fh.write(" ".join(str(x) for x in a) + "\n")


def g2b(p):
    return Vector((p[0], -p[2], p[1]))


def shot(name, eye, at, lens, w=1600, h=900):
    sc = bpy.context.scene
    sc.render.resolution_x, sc.render.resolution_y = w, h
    cam = sc.camera
    cam.data.lens = lens
    e, a = g2b(eye), g2b(at)
    cam.location = e
    cam.rotation_euler = (a - e).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = os.path.join(OUTD, name)
    bpy.ops.render.render(write_still=True)


def imp(path):
    before = set(bpy.data.objects)
    bpy.ops.wm.obj_import(filepath=path, forward_axis="NEGATIVE_Z", up_axis="Y")
    return [o for o in bpy.data.objects if o not in before]


try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    for eng in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE"):
        try:
            sc.render.engine = eng
            break
        except Exception:
            continue
    log("engine", sc.render.engine)
    sc.view_settings.view_transform = "Standard"
    sc.view_settings.look = "None"
    sc.view_settings.exposure = -0.2
    sc.render.image_settings.file_format = "PNG"
    try:
        sc.eevee.taa_render_samples = 32
    except Exception:
        pass
    world = bpy.data.worlds.new("Sky"); sc.world = world
    world.use_nodes = True
    nt = world.node_tree
    bg = nt.nodes.get("Background")
    bg.inputs[0].default_value = (SKY[0], SKY[1], SKY[2], 1); bg.inputs[1].default_value = 0.55
    bg2 = nt.nodes.new("ShaderNodeBackground"); bg2.inputs[0].default_value = (SKY[0], SKY[1], SKY[2], 1); bg2.inputs[1].default_value = 1.0
    lp = nt.nodes.new("ShaderNodeLightPath"); mix = nt.nodes.new("ShaderNodeMixShader")
    out = nt.nodes.get("World Output")
    nt.links.new(lp.outputs["Is Camera Ray"], mix.inputs[0])
    nt.links.new(bg.outputs[0], mix.inputs[1]); nt.links.new(bg2.outputs[0], mix.inputs[2])
    nt.links.new(mix.outputs[0], out.inputs[0])
    sun_d = bpy.data.lights.new("Sun", "SUN"); sun_d.energy = 3.3; sun_d.angle = math.radians(1.5)
    sun = bpy.data.objects.new("Sun", sun_d); sc.collection.objects.link(sun)
    d = g2b((0.35, -0.8, -0.5)).normalized()           # light travelling downstream, from upstream-left and high
    sun.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam)
    sc.collection.objects.link(camo); sc.camera = camo
    cam.clip_start = 0.1; cam.clip_end = 4000

    gorge = imp(os.path.join(D, "gorge_sample.obj"))
    for o in gorge:
        if o.type == "MESH":
            sm = o.name.startswith(("Cliff", "Boulders"))
            for p in o.data.polygons:
                p.use_smooth = sm

    data = json.load(open(os.path.join(D, "trees.json")))
    colours = data["colours"]
    eyes = [g2b(v[0]) for k, v in VIEWS.items() if not ONLY or k in ONLY]
    kits = {}
    placed = 0
    for t in data["trees"]:
        pos = g2b((t["x"], t["y"], t["z"]))
        if eyes and min((pos - e).length for e in eyes) < 9.0:
            continue                                       # nothing right in front of a camera
        f = t["file"]
        if f not in kits:
            objs = imp(os.path.join(data["root"], f))
            for o in objs:
                o.hide_render = True
            kits[f] = objs
        for o in kits[f]:
            c = o.copy()
            c.hide_render = False
            sc.collection.objects.link(c)
            c.matrix_world = Matrix.Translation(pos) @ Matrix.Rotation(math.radians(t["yaw"]), 4, "Z") @ Matrix.Scale(t["scale"], 4) @ o.matrix_world
        placed += 1
    log("trees placed", placed)
    for m in bpy.data.materials:
        m.use_backface_culling = True
        base = None
        for key, rgb in colours.items():
            if m.name.startswith("m_" + key):
                base = (lin(rgb[0] / 255), lin(rgb[1] / 255), lin(rgb[2] / 255), 1)
        if not m.node_tree:
            continue
        for n in m.node_tree.nodes:
            if n.type == "BSDF_PRINCIPLED":
                textured = any(l.to_node == n and l.to_socket.name == "Base Color" for l in m.node_tree.links)
                if base is None and not textured:
                    v = n.inputs["Base Color"].default_value          # the .mtl Kd, written as sRGB
                    base = (lin(v[0]), lin(v[1]), lin(v[2]), 1)
                if base is not None:
                    n.inputs["Base Color"].default_value = base
                n.inputs["Roughness"].default_value = 0.3 if m.name.startswith("Water") else 0.9
                for key in ("Specular IOR Level", "Specular"):
                    if key in n.inputs:
                        n.inputs[key].default_value = 0.15 if m.name.startswith("Water") else 0.05
    log("objects", len([o for o in bpy.data.objects if o.type == "MESH"]))
    for v, (eye, at, lens) in VIEWS.items():
        if ONLY and v not in ONLY:
            continue
        shot("%s_%s.png" % (PREFIX, v), eye, at, lens)
        log("rendered", v)
except Exception:
    log(traceback.format_exc())
