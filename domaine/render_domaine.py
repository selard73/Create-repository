"""Blender check renders for the domaine kits, drawn the way Roblox draws them (single-sided faces, flat shading).
Every kit is shot from ground level and from a three-quarter view. Usage:
  blender --background --python render_domaine.py -- <batch>
batch: veg (batch 1) ...  Output: check_<batch>_*.png next to this file, log in render_log.txt"""
import bpy, os, sys, traceback
from mathutils import Vector

D = os.path.dirname(os.path.abspath(__file__))
LOG = os.path.join(D, "render_log.txt")
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
BATCH = argv[0] if argv else "veg"


def imp(path, offset=(0, 0, 0)):
    before = set(bpy.data.objects)
    bpy.ops.wm.obj_import(filepath=path, forward_axis="NEGATIVE_Z", up_axis="Y")
    new = [o for o in bpy.data.objects if o not in before]
    for o in new:
        o.location = o.location + Vector(offset)
    return new


def clear():
    for o in list(bpy.data.objects):
        if o.type == "MESH": bpy.data.objects.remove(o)


def shot(name, eye, at, w=1200, h=700, lens=40):
    """eye / at in KIT coordinates (x, y up, z); converted to Blender (x, -z, y)."""
    sc = bpy.context.scene
    sc.render.resolution_x, sc.render.resolution_y = w, h
    cam = sc.camera
    cam.data.lens = lens
    e = Vector((eye[0], -eye[2], eye[1])); a = Vector((at[0], -at[2], at[1]))
    cam.location = e
    cam.rotation_euler = (a - e).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = os.path.join(D, name)
    bpy.ops.render.render(write_still=True)


def ground(size=400):
    bpy.ops.mesh.primitive_plane_add(size=size, location=(0, 0, -0.01))
    g = bpy.context.active_object
    m = bpy.data.materials.new("ground"); m.diffuse_color = (0.42, 0.55, 0.30, 1)
    g.data.materials.append(m)
    return g


try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading
    sh.light = "STUDIO"; sh.color_type = "MATERIAL"; sh.show_shadows = True; sh.show_cavity = True
    sh.show_backface_culling = True
    sh.background_type = "VIEWPORT"; sh.background_color = (0.80, 0.85, 0.92)
    sc.view_settings.view_transform = "Standard"
    sc.render.image_settings.file_format = "PNG"
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam)
    sc.collection.objects.link(camo); sc.camera = camo
    ground()

    if BATCH == "veg":
        # a strip of three lavender rows, 6 studs apart, seen from a kneeling height at the row end and from the side
        imp(os.path.join(D, "lavender_row_a.obj"), (0, 0, 0))
        imp(os.path.join(D, "lavender_row_b.obj"), (0, 0, -6))
        imp(os.path.join(D, "lavender_row_a.obj"), (0, 0, -12))
        shot("check_veg_lavender_end.png", (-19, 2.2, 4), (-6, 1.2, -6), lens=32)
        shot("check_veg_lavender_side.png", (-4, 2.0, 9), (0, 1.3, -4), lens=32)
        shot("check_veg_lavender_close.png", (-9, 1.6, 2.5), (-7.5, 1.4, 0), lens=45)
        shot("check_veg_lavender_high.png", (10, 14, 14), (0, 0.5, -6), lens=35)
        clear(); ground()
        imp(os.path.join(D, "vine_row_a.obj"), (0, 0, 0))
        imp(os.path.join(D, "vine_row_b.obj"), (0, 0, -8))
        shot("check_veg_vines_end.png", (-20, 2.4, 3), (-4, 2.5, -4), lens=32)
        shot("check_veg_vines_side.png", (-3, 2.2, 9), (0, 2.6, -1), lens=30)
        shot("check_veg_vines_close.png", (-6, 2.0, 4), (-4.5, 2.6, 0), lens=45)
        clear(); ground()
        imp(os.path.join(D, "cypress.obj"), (-12, 0, 0))
        imp(os.path.join(D, "olive_tree.obj"), (0, 0, 0))
        imp(os.path.join(D, "sunflower_patch.obj"), (12, 0, 0))
        imp(os.path.join(D, "boxwood.obj"), (20, 0, 0))
        imp(os.path.join(D, "oleander.obj"), (27, 0, 0))
        shot("check_veg_trees.png", (6, 3.0, 34), (6, 6, 0), lens=30)
        shot("check_veg_trees_low.png", (-4, 1.4, 22), (4, 4, 0), lens=32)
        shot("check_veg_sunflowers.png", (12, 2.2, 12), (12, 4, 0), lens=40)
        shot("check_veg_shrubs.png", (24, 2.0, 12), (23.5, 1.8, 0), lens=40)

    if BATCH == "bld":
        imp(os.path.join(D, "mas.obj"))
        shot("check_bld_mas_front.png", (-30, 2.0, -42), (0, 9, 0), lens=32)
        shot("check_bld_mas_low.png", (-14, 1.6, -22), (-2, 10, 0), lens=28)
        shot("check_bld_mas_back.png", (34, 3.0, 40), (0, 10, 0), lens=32)
        shot("check_bld_mas_gable.png", (-52, 4.0, 6), (0, 12, 0), lens=35)
        clear(); ground()
        imp(os.path.join(D, "barn.obj"))
        shot("check_bld_barn_front.png", (-26, 2.0, -40), (0, 8, 0), lens=32)
        shot("check_bld_barn_loft.png", (-8, 1.7, -20), (0, 15, -11), lens=35)
        shot("check_bld_barn_side.png", (44, 3.0, 20), (0, 8, 0), lens=35)
        clear(); ground()
        imp(os.path.join(D, "chapel.obj"))
        shot("check_bld_chapel_front.png", (-22, 2.0, -40), (0, 10, 0), lens=30)
        shot("check_bld_chapel_side.png", (40, 3.0, -14), (0, 12, 0), lens=32)
        shot("check_bld_chapel_belfry.png", (-8, 4.0, -30), (3.5, 24, -7.5), lens=50)
        clear(); ground()
        imp(os.path.join(D, "windmill.obj"))
        shot("check_bld_windmill_front.png", (-22, 2.0, -46), (0, 14, 0), lens=30)
        shot("check_bld_windmill_stair.png", (24, 2.0, -24), (0, 8, 0), lens=32)
        shot("check_bld_windmill_platform.png", (18, 6.0, 14), (2, 8, 4), lens=35)
        clear(); ground()
        imp(os.path.join(D, "cellar_front.obj"))
        shot("check_bld_cellar_front.png", (-14, 2.0, -24), (0, 5, 0), lens=32)
        shot("check_bld_cellar_inside.png", (0.5, 3.0, -3), (0, 3.5, 10), lens=28)
        clear(); ground()
        imp(os.path.join(D, "hut.obj"), (-16, 0, 0))
        imp(os.path.join(D, "coop.obj"), (8, 0, 0))
        imp(os.path.join(D, "hen.obj"), (8, 0, -10))
        imp(os.path.join(D, "hen.obj"), (10, 0, -8))
        shot("check_bld_hut_coop.png", (-4, 2.2, -34), (-4, 5, 0), lens=30)
        shot("check_bld_coop_close.png", (18, 1.8, -20), (8, 4, -4), lens=35)
        shot("check_bld_hut_leanto.png", (-2, 2.0, -16), (-9, 5, 0), lens=35)

    if BATCH == "props":
        row = ["well", "beehive", "lavender_cart", "barrel", "barrel_rack", "wine_press", "crate_grapes", "tasting_table"]
        x = 0
        for nm in row:
            imp(os.path.join(D, nm + ".obj"), (x, 0, 0)); x += 10
        shot("check_props_row1.png", (34, 4.0, 30), (34, 2.5, 0), lens=24)
        shot("check_props_row1_low.png", (4, 1.4, 14), (12, 2.0, 0), lens=30)
        shot("check_props_row1_low2.png", (44, 1.4, 14), (52, 2.0, 0), lens=30)
        clear(); ground()
        row = ["long_table", "tractor", "trailer", "hay_round", "hay_stack", "scarecrow", "trough"]
        x = 0
        for nm in row:
            imp(os.path.join(D, nm + ".obj"), (x, 0, 0)); x += 14
        shot("check_props_row2.png", (42, 5.0, 40), (42, 3, 0), lens=24)
        shot("check_props_row2_low.png", (6, 1.6, 16), (16, 3, 0), lens=30)
        shot("check_props_row2_low2.png", (52, 1.6, 16), (62, 3, 0), lens=30)
        clear(); ground()
        row = ["stone_wall", "stone_pillar", "farm_gate", "picket_fence", "picket_gate", "sign_post", "still"]
        x = 0
        for nm in row:
            imp(os.path.join(D, nm + ".obj"), (x, 0, 0)); x += 14
        shot("check_props_row3.png", (42, 4.0, 36), (42, 2.5, 0), lens=24)
        shot("check_props_row3_low.png", (2, 1.5, 12), (10, 2.0, 0), lens=30)
        shot("check_props_row3_low2.png", (56, 1.5, 12), (66, 2.5, 0), lens=30)
        clear(); ground()
        imp(os.path.join(D, "garden.obj"))
        shot("check_props_garden.png", (-12, 5.0, -18), (0, 1, 0), lens=30)
        shot("check_props_garden_low.png", (-8, 1.6, -9), (0, 1, 2), lens=30)

    with open(LOG, "a") as f:
        f.write("RENDER_DONE\n")
except Exception:
    with open(LOG, "a") as f:
        f.write(traceback.format_exc())
