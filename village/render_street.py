"""Preview the new shop-houses with the small props and a 5-stud character box for scale.
Run: blender --background --python render_street.py   (writes street_preview.png + render_street_log.txt)"""
import bpy, os, math, traceback
from mathutils import Vector
D = os.path.dirname(os.path.abspath(__file__))
LOG = os.path.join(D, "render_street_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
PASTEL = {"townhouse_a": (0.96, 0.90, 0.78), "townhouse_b": (0.94, 0.78, 0.78), "townhouse_c": (0.78, 0.84, 0.92)}
SHOP = {"townhouse_a": (0.47, 0.33, 0.24), "townhouse_b": (0.53, 0.51, 0.75), "townhouse_c": (0.43, 0.55, 0.43)}
AWN = {"townhouse_a": (0.84, 0.35, 0.33), "townhouse_b": (0.47, 0.55, 0.82), "townhouse_c": (0.43, 0.67, 0.47)}
COL = {"Trim": (0.98, 0.97, 0.93), "Window": (0.55, 0.63, 0.75), "Sign": (0.24, 0.19, 0.17), "AwningStripe": (0.98, 0.97, 0.94),
       "Roof": (0.78, 0.47, 0.37), "Chimney": (0.67, 0.59, 0.55), "Door": (0.43, 0.33, 0.24), "Iron": (0.18, 0.18, 0.2),
       "Shutter": (0.43, 0.55, 0.43), "Planter": (0.71, 0.43, 0.33), "Flower": (0.9, 0.35, 0.47), "Leaf": (0.39, 0.63, 0.35),
       "Plank": (0.63, 0.47, 0.33), "Bread": (0.89, 0.67, 0.36), "Table": (0.27, 0.24, 0.22), "Chair": (0.55, 0.42, 0.3),
       "Post": (0.18, 0.27, 0.24), "Lantern": (1.0, 0.94, 0.75), "Frame": (0.27, 0.35, 0.55), "Wheel": (0.2, 0.2, 0.2), "Bench": (0.55, 0.43, 0.33)}
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    row = [("townhouse_c", 0), ("townhouse_a", 0), ("townhouse_b", 0)]
    x = 0.0
    fronts = []
    for n, _ in row:
        before = set(bpy.data.objects)
        bpy.ops.wm.obj_import(filepath=os.path.join(D, n + ".obj"), forward_axis="NEGATIVE_Z", up_axis="Y")
        new = [o for o in bpy.data.objects if o not in before]
        xs0 = min(o.bound_box[0][0] + o.location.x for o in new); xs1 = max(o.bound_box[4][0] + o.location.x for o in new)
        w = max(o.dimensions.x for o in new)
        for o in new:
            o.location.x += x + w / 2
            for slot in o.material_slots:
                m = slot.material
                if not m: continue
                piece = m.name.replace("m_", "").split(".")[0]
                key = None
                for k in list(COL) + ["Wall", "Shopfront", "DoorShop", "Awning"]:
                    if piece.startswith(k) and (key is None or len(k) > len(key)): key = k
                if key == "Wall": m.diffuse_color = (*PASTEL[n], 1)
                elif key in ("Shopfront", "DoorShop"): m.diffuse_color = (*SHOP[n], 1)
                elif key == "Awning": m.diffuse_color = (*AWN[n], 1)
                elif key in COL: m.diffuse_color = (*COL[key], 1)
        x += w + 0.6
    # small props on the pavement in front (Blender: Y forward = -Z of obj => front is -Y)
    def prop(n, px, py, scale=1.0, rotz=0.0):
        before = set(bpy.data.objects)
        bpy.ops.wm.obj_import(filepath=os.path.join(D, n + ".obj"), forward_axis="NEGATIVE_Z", up_axis="Y")
        new = [o for o in bpy.data.objects if o not in before]
        for o in new:
            o.location = (px, py, 0); o.scale = (scale, scale, scale); o.rotation_euler = (0, 0, rotz)
            for slot in o.material_slots:
                m = slot.material
                if not m: continue
                piece = m.name.replace("m_", "").split(".")[0]
                for k in COL:
                    if piece.startswith(k): m.diffuse_color = (*COL[k], 1)
    front = 13.0
    prop("cafe_table", 6.0, front + 3.6, 1.0, math.pi / 2); prop("cafe_table", 14.0, front + 3.6, 1.0, math.pi / 2)
    prop("crates", 34.6 + 10.5 - 3.4, front + 1.4); prop("crates", 34.6 + 10.5 + 3.4, front + 1.4)
    prop("pot", 34.6 + 28.6 + 3.2, front + 1.5); prop("pot", 34.6 + 28.6 - 3.2, front + 1.5)
    prop("lamp_post", 30.0, front + 8.5, 1.1)
    prop("bicycle", 34.6 + 8, front + 1.6, 0.85)
    # a 5-stud "character" for scale
    bpy.ops.mesh.primitive_cube_add(size=1, location=(24.0, front + 6.0, 2.5)); c = bpy.context.object; c.scale = (2.0, 1.0, 5.0)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.9, location=(24.0, front + 6.0, 5.9))
    # ground
    bpy.ops.mesh.primitive_plane_add(size=400, location=(40, 0, -0.01))
    sc = bpy.context.scene; sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "MATERIAL"; sh.show_shadows = True; sh.show_cavity = True
    sh.background_type = "VIEWPORT"; sh.background_color = (0.78, 0.84, 0.9)
    sc.view_settings.view_transform = "Standard"
    sc.render.resolution_x, sc.render.resolution_y = 2000, 1100; sc.render.image_settings.file_format = "PNG"
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(camo); sc.camera = camo
    cam.lens = 40
    ctr = Vector((x / 2, front, 11))
    camo.location = ctr + Vector((-10, 100, 30))
    camo.rotation_euler = (ctr - camo.location).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = os.path.join(D, "street_preview.png"); bpy.ops.render.render(write_still=True)
    # a second, closer shot of the boulangerie front
    ctr2 = Vector((34.6 + 14, front, 8))
    camo.location = ctr2 + Vector((-8, 44, 10)); camo.rotation_euler = (ctr2 - camo.location).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = os.path.join(D, "street_preview_close.png"); bpy.ops.render.render(write_still=True)
    log("RENDER_DONE")
except Exception:
    log(traceback.format_exc())
