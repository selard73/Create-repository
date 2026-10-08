"""Check renders of the REAL gorge (preview_world.obj from gen_gorge_real.py, the Sandstone Climb for context + the game's kit trees from trees.json). Eevee with a sun and a
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

VIEWS = {   # name: (eye, at, lens) in game coordinates
    "falls_boat_far": ((186.8, 2.6, -480.0), (190.0, 0.0, -560.0), 16),       # in the boat: the walls end ahead
    "falls_boat": ((199.1, 2.6, -500.0), (183.8, -6.0, -610.0), 18),          # in the boat, 48 short of the lip (the river swings east here)
    "falls_lip": ((183.8, 4.5, -540.0), (183.8, -20.0, -680.0), 18),          # at the lip, boat height: the edge and the harbour beyond
    "falls_sill": ((186.8, -30.0, -592.5), (183.8, -8.0, -547.5), 40),        # the sill and the foot of the notch, close
    "falls_lip_above": ((190.0, 14.0, -523.5), (183.8, -40.0, -637.5), 20),   # just above and behind the lip
    "falls_harbour": ((218.8, -44.0, -707.5), (183.8, -4.0, -547.5), 22),     # looking up from the plain
    "falls_harbour_wide": ((323.8, -38.0, -847.5), (183.8, 0.0, -587.5), 24),
    "falls_above": ((253.8, 120.0, -477.5), (183.8, -25.0, -607.5), 22),
    "falls_side": ((358.8, -15.0, -657.5), (183.8, -20.0, -567.5), 28),
    "falls_notch": ((195.8, -44.0, -622.5), (183.8, 15.0, -547.5), 35),       # the corners where the walls meet the cliff
    "falls_geo": ((183.8, 420.0, -1150.0), (183.8, -10.0, -480.0), 26),       # the geography: the plain, the cove, the ridge, the village beyond
    "falls_glider": ((263.5, 150.0, -400.0), (183.8, -20.0, -600.0), 20),     # hang-glider height from the French side: the ridge and the drop
    "end_above": ((195.5, 78, -500.0), (183.5, 8, -556.0), 24),
    "end_shannon": ((205.5, 62, -534.0), (179.5, 12, -558.0), 30),
    "end_boat": ((199.8, 3.4, -516), (183.5, 8, -560.0), 18),
    "end_arch": ((188.5, 3.0, -549.0), (183.5, 2.0, -564.0), 26),
    "end_glider": ((243.5, 130, -420), (183.5, 10, -554.0), 22),
    "mouth_west_close": ((194.2, 14, -236), (172.2, 15, -252), 28),
    "mouth_east_close": ((182.2, 14, -236), (204.2, 15, -252), 28),
    "mouth_boat": ((173.6, 3.4, -226), (192.6, 9, -262), 20),
    "jetty_south": ((158, 6.5, -150), (185, 12, -300), 20),
    "village_edge": ((170, 8, -200), (182, 14, -330), 18),
    "climb_summit": ((497, 79, -262), (160, 15, -440), 22),
    "glider": ((470, 100, -235), (170, 5, -430), 20),
    "boat_mouth": ((162.1, 3.2, -210), (191.1, 8, -275), 16),
    "boat_approach": ((136.8, 3.2, -334), (110, 16, -384), 16),
    "boat_under": ((110.2, 3.0, -373), (110, 16, -392), 16),
    "boat_fade": ((167.7, 3.2, -458), (200.2, 10, -505), 16),
    "overview": ((560, 300, -40), (330, 0, -560), 22),
    "slot_end": ((250, 80, -480), (170, 0, -560), 24),
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
    d = g2b(tuple(float(v) for v in os.environ.get("GORGE_SUN", "0.35,-0.8,-0.5").split(","))).normalized()   # light direction (game axes); default: downstream, from upstream-left and high. GORGE_SUN=-0.3,-0.75,0.55 lights the falls' south face from over the sea
    sun.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam)
    sc.collection.objects.link(camo); sc.camera = camo
    cam.clip_start = 0.1; cam.clip_end = 4000

    gorge = imp(os.path.join(D, os.environ.get("GORGE_OBJ", "preview_world.obj")))
    hide = tuple(h for h in os.environ.get("GORGE_HIDE", "").split(",") if h)        # e.g. GORGE_HIDE=Falls,Mist,Foam
    for o in gorge:
        if o.type == "MESH" and hide and o.name.startswith(hide):
            o.hide_render = True
        if o.type == "MESH":
            sm = o.name.startswith(("SouthRock", "SouthCliff", "Hills", "Plain", "Bed", "Sand", "Slope", "Falls"))
            for p in o.data.polygons:
                p.use_smooth = sm
    climb = imp(os.path.join(os.path.dirname(os.path.dirname(D)), "domaine", "cliff", "cliff_preview.obj"))
    for o in climb:
        if o.type == "MESH":
            if o.name.startswith(("Cypress", "GardenWall", "StartStone")):
                o.hide_render = True
            for p in o.data.polygons:
                p.use_smooth = o.name.startswith(("SandCliff", "SandBoulder"))

    data = json.load(open(os.path.join(D, "gorge_data.json")))
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
    ALPHA = {"Falls": 0.72, "Foam": 0.85, "Mist": 0.30}
    for m in bpy.data.materials:
        m.use_backface_culling = True
        base = None
        akey = next((k for k in ALPHA if m.name.startswith(k)), None)
        if akey:
            m.use_backface_culling = False
            try:
                m.blend_method = "BLEND"
            except Exception:
                pass
            try:
                m.surface_render_method = "BLENDED"
            except Exception:
                pass
            if m.node_tree:
                for n in m.node_tree.nodes:
                    if n.type == "BSDF_PRINCIPLED" and "Alpha" in n.inputs:
                        n.inputs["Alpha"].default_value = ALPHA[akey]
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
