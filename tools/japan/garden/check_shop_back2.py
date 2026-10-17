"""Render the back-of-shop kit against a stand-in back wall (cream plaster 26 wide x 12 tall with a brown eave 2 out at 9.2), all
eight pieces laid out as the installer would: door, window, and the yard things along the wall. out_shopback2/prev_shopback2_*.png"""
import bpy, math, os, traceback
from mathutils import Vector, Matrix
D = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(D, "out_shopback2")
LOG = os.path.join(OUT, "check_log.txt")
def log(m): open(LOG, "a").write(str(m) + "\n"); print(m)
def P(x, y, z): return (x, -z, y)
def mat(name, c):
    m = bpy.data.materials.new(name); m.diffuse_color = (c[0], c[1], c[2], 1); return m
def block(name, c0, c1, m):
    x0, y0, z0 = c0; x1, y1, z1 = c1
    bpy.ops.mesh.primitive_cube_add(size=1, location=P((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2))
    o = bpy.context.active_object; o.name = name; o.scale = (x1 - x0, z1 - z0, y1 - y0); o.data.materials.append(m); return o
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=os.path.join(OUT, "japan_kit20_shop_backs2.fbx"), axis_forward="-Z", axis_up="Y")
    kit = {o.name: o for o in bpy.data.objects if o.type == "EMPTY"}
    log("empties: " + ", ".join(sorted(kit)))
    def place(name, at, yaw=0.0):
        src = kit[name]
        for ch in src.children:
            c = ch.copy(); c.data = ch.data; bpy.context.scene.collection.objects.link(c); c.parent = None
            c.matrix_world = Matrix.Translation(P(*at)) @ Matrix.Rotation(yaw, 4, "Z") @ Matrix.Translation(-src.matrix_world.translation) @ ch.matrix_world
    # the wall along x at z 0, the yard toward +z (the pieces' own +z)
    place("back_door2", (3.5, 0, 0)); place("back_window2", (-5.5, 0, 0))
    place("crate_stack2", (-6.5, 0, 2.0), 0.2); place("sake_barrel2", (-2.8, 0, 2.2)); place("water_tub", (8.5, 0, 1.8))
    place("wood_shed", (-12.0, 0, 0), 0.0); place("broom", (7.0, 0, 0)); place("drainpipe", (12.6, 0, 0))
    for x in (-10.0, -2.0, 10.0): place("lattice_panel", (x, 0, 0))
    for x in (-10.0, -6.0, -2.0, 2.0, 6.0, 10.0): place("awning_section", (x, 0, 0))
    place("chochin", (0.0, 0, 0))
    for e in list(kit.values()):
        for ch in list(e.children): bpy.data.objects.remove(ch, do_unlink=True)
        bpy.data.objects.remove(e, do_unlink=True)
    plaster = mat("plaster", (0.64, 0.58, 0.47)); timber = mat("timber", (0.22, 0.15, 0.10)); lawn = mat("lawn", (0.18, 0.36, 0.12)); eave = mat("eave", (0.25, 0.17, 0.11))
    block("wall", (-13, 0, -1.0), (13, 12, 0.0), plaster)
    for x in (-13.3, 13.0): block("post", (x, 0, -0.2), (x + 0.3, 12, 0.25), timber)
    block("eave", (-14, 9.2, -1.0), (14, 9.8, 2.4), eave)
    block("lawn", (-40, -0.3, -2), (40, 0.0, 40), lawn)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.9, depth=5.2, location=P(15.5, 2.6, 5)); fig = bpy.context.active_object
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.6, location=P(15.5, 5.7, 5)); head = bpy.context.active_object
    mf = mat("figure", (0.75, 0.75, 0.78))
    for o in (fig, head): o.data.materials.append(mf)
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"; sc.display.shading.color_type = "MATERIAL"; sc.display.shading.light = "STUDIO"; sc.display.shading.show_shadows = True; sc.display.shading.show_cavity = True
    sc.render.resolution_x, sc.render.resolution_y = 1100, 560
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam; cam.data.lens = 24
    for fn, loc, target in (("prev_shopback2_yard.png", (6, 5.5, 22), (-1, 4.5, 0)), ("prev_shopback2_door.png", (9, 4.5, 9), (2, 4.2, 0))):
        cam.location = P(*loc)
        cam.rotation_euler = (Vector(P(*target)) - Vector(P(*loc))).to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(OUT, fn); bpy.ops.render.render(write_still=True); log("shot " + fn)
    log("CHECK_DONE")
except Exception:
    log(traceback.format_exc()); log("CHECK_FAILED")
