"""Preview: the new arched shop door (townhouse_a front, close) and the six window-display kits in a row.
Run: blender --background --python render_displays.py  ->  displays_preview.png, door_preview.png"""
import bpy, os, math, traceback
from mathutils import Vector
D = os.path.dirname(os.path.abspath(__file__))
LOG = os.path.join(D, "render_displays_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
COL = {"Wall": (0.96, 0.90, 0.78), "Shopfront": (0.43, 0.55, 0.43), "DoorShop": (0.46, 0.31, 0.2), "Brick": (0.59, 0.36, 0.3),
       "Trim": (0.98, 0.97, 0.93), "Window": (0.55, 0.63, 0.75), "Glass": (0.72, 0.82, 0.9), "Sign": (0.24, 0.19, 0.17),
       "Awning": (0.43, 0.67, 0.47), "AwningStripe": (0.98, 0.97, 0.94), "Roof": (0.78, 0.47, 0.37), "Chimney": (0.67, 0.59, 0.55),
       "Door": (0.43, 0.33, 0.24), "Iron": (0.15, 0.15, 0.17), "Brass": (0.85, 0.7, 0.35), "Interior": (0.93, 0.8, 0.62),
       "Shutter": (0.43, 0.55, 0.43), "Planter": (0.71, 0.43, 0.33), "Flower": (0.9, 0.35, 0.47), "Leaf": (0.39, 0.63, 0.35),
       "Plank": (0.63, 0.47, 0.33), "Bread": (0.89, 0.67, 0.36), "Bench": (0.55, 0.43, 0.33), "Cake": (0.98, 0.96, 0.92),
       "Icing": (0.94, 0.66, 0.74), "Dress": (0.9, 0.47, 0.55), "Head": (0.92, 0.84, 0.78), "Post": (0.18, 0.2, 0.2),
       "Jar": (0.78, 0.55, 0.35), "Box": (0.6, 0.42, 0.3), "Round": (0.94, 0.82, 0.47), "Book": (0.55, 0.35, 0.35),
       "Hat": (0.25, 0.22, 0.2), "Stone": (0.7, 0.7, 0.68), "Trunk": (0.43, 0.33, 0.24), "Lantern": (1.0, 0.94, 0.75)}
def tint(objs):
    for o in objs:
        for slot in o.material_slots:
            m = slot.material
            if not m: continue
            piece = m.name.replace("m_", "").split(".")[0]
            key = None
            for k in COL:
                if piece.startswith(k) and (key is None or len(k) > len(key)): key = k
            if key: m.diffuse_color = (*COL[key], 1)
def load(n, px=0.0, py=0.0):
    before = set(bpy.data.objects)
    bpy.ops.wm.obj_import(filepath=os.path.join(D, n + ".obj"), forward_axis="NEGATIVE_Z", up_axis="Y")
    new = [o for o in bpy.data.objects if o not in before]
    for o in new:
        o.location.x += px; o.location.y += py
    tint(new)
    return new
def shoot(sc, camo, ctr, offset, path):
    camo.location = ctr + offset
    camo.rotation_euler = (ctr - camo.location).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = path; bpy.ops.render.render(write_still=True)
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene; sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "MATERIAL"; sh.show_shadows = True; sh.show_cavity = True
    sh.background_type = "VIEWPORT"; sh.background_color = (0.78, 0.84, 0.9)
    sc.view_settings.view_transform = "Standard"
    sc.render.resolution_x, sc.render.resolution_y = 1800, 1000; sc.render.image_settings.file_format = "PNG"
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(camo); sc.camera = camo
    cam.lens = 45
    # 1. the display kits in a row
    kits = ["disp_bakery", "disp_dress", "disp_shelves", "disp_flowers", "disp_cafe", "disp_hats"]
    for i, k in enumerate(kits): load(k, px=i * 8.0)
    bpy.ops.mesh.primitive_plane_add(size=200, location=(20, 0, -0.01))
    shoot(sc, camo, Vector((20, 0, 2.5)), Vector((0, -30, 12)), os.path.join(D, "displays_preview.png"))
    # 2. the shop door on townhouse_a (front faces +Y in Blender after this import)
    for o in list(bpy.data.objects):
        if o.type == "MESH": bpy.data.objects.remove(o, do_unlink=True)
    load("townhouse_a")
    bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 0, -0.01))
    # displays behind the glass bay of townhouse_a (bay from -12.3 to 8.7 -> 3 copies), mirrored x since the front is +Y here
    for i in range(3):
        px = -(-12.3 + 21 * (i + 0.5) / 3)
        objs = load("disp_bakery", px=px, py=13 - 2.9)
        for o in objs:
            o.location.z += 1.5; o.rotation_euler.z += math.pi
    shoot(sc, camo, Vector((-10.5, 13, 4.5)), Vector((-4, 20, 4)), os.path.join(D, "door_preview.png"))
    shoot(sc, camo, Vector((0, 13, 6)), Vector((6, 34, 6)), os.path.join(D, "front_preview.png"))
    log("RENDER_DONE")
except Exception:
    log(traceback.format_exc())
