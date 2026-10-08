import bpy, os, math, traceback
from mathutils import Vector
D = os.path.dirname(os.path.abspath(__file__))
LOG = os.path.join(D, "render_cheese_log.txt")
exec(open(os.path.join(D, "render_displays.py")).read().split("try:")[0].split("def tint")[0])  # reuse COL + log
COL.update({"Cheese": (0.94, 0.8, 0.4), "Choc": (0.26, 0.15, 0.1), "Wrap": (0.85, 0.7, 0.35)})
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
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene; sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "MATERIAL"; sh.show_shadows = True; sh.show_cavity = True
    sh.background_type = "VIEWPORT"; sh.background_color = (0.78, 0.84, 0.9)
    sc.view_settings.view_transform = "Standard"
    sc.render.resolution_x, sc.render.resolution_y = 1800, 900; sc.render.image_settings.file_format = "PNG"
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(camo); sc.camera = camo
    cam.lens = 45
    for i, k in enumerate(["disp_cheese", "disp_chocolate", "disp_shelves"]):
        before = set(bpy.data.objects)
        bpy.ops.wm.obj_import(filepath=os.path.join(D, k + ".obj"), forward_axis="NEGATIVE_Z", up_axis="Y")
        new = [o for o in bpy.data.objects if o not in before]
        for o in new: o.location.x += i * 8.0
        tint(new)
    bpy.ops.mesh.primitive_plane_add(size=200, location=(8, 0, -0.01))
    ctr = Vector((8, 0, 2.2)); camo.location = ctr + Vector((0, -22, 9))
    camo.rotation_euler = (ctr - camo.location).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = os.path.join(D, "cheese_preview.png"); bpy.ops.render.render(write_still=True)
    log("RENDER_DONE")
except Exception:
    log(traceback.format_exc())
