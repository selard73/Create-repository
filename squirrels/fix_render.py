"""Post-fix + preview renders. Opens <name>_rigged.blend; optional head-radius fix (weights of Head/Neck beyond
RADIUS from the head centre go to Chest, so held props like the umbrella don't turn with the head); re-exports
colour + gray FBX when fixed; renders colour and gray 3/4 previews on a light background.
Run: blender --background --python fix_render.py -- <out_dir> <name> <head_radius or 0>"""
import bpy, sys, os, math, json, traceback
from mathutils import Vector
argv = sys.argv[sys.argv.index("--") + 1:]
OUTD, NAME, RADIUS = argv[0], argv[1], float(argv[2])
TAIL_XMAX = float(argv[3]) if len(argv) > 3 else 0.0     # >0: Tail weights on vertices wider than this (capes) go to Root
LOG = os.path.join(OUTD, "fix_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
try:
    open(LOG, "w").close()
    bpy.ops.wm.open_mainfile(filepath=os.path.join(OUTD, f"{NAME}_rigged.blend"))
    sq = bpy.data.objects["Squirrel"]; arm = bpy.data.objects["SquirrelRig"]
    tex = [n for n in sq.data.materials[0].node_tree.nodes if n.type == "TEX_IMAGE"][0]
    def export(tag, png):
        tex.image = bpy.data.images.load(png)
        bpy.ops.object.select_all(action="DESELECT"); sq.select_set(True); arm.select_set(True)
        bpy.context.view_layer.objects.active = arm
        bpy.ops.export_scene.fbx(filepath=os.path.join(OUTD, f"{NAME}_{tag}.fbx"), use_selection=True, add_leaf_bones=False,
                                 bake_anim=False, path_mode="COPY", embed_textures=True, mesh_smooth_type="FACE",
                                 global_scale=0.01, apply_unit_scale=True, apply_scale_options="FBX_SCALE_NONE")
    if TAIL_XMAX > 0:
        gi = {g.index: g.name for g in sq.vertex_groups}
        root = sq.vertex_groups["Root"]; moved = 0
        for v in sq.data.vertices:
            if abs(v.co.x) > TAIL_XMAX:
                w = sum(g.weight for g in v.groups if gi[g.group] in ("Tail1", "Tail2"))
                if w > 0:
                    for nm in ("Tail1", "Tail2"): sq.vertex_groups[nm].remove([v.index])
                    cur = sum(g.weight for g in v.groups if gi[g.group] == "Root")
                    root.add([v.index], min(1.0, cur + w), "REPLACE"); moved += 1
        log(f"cape fix: {moved} vertices moved from Tail to Root")
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUTD, f"{NAME}_rigged.blend"))
        export("color", os.path.join(OUTD, f"{NAME}_1k.png"))
        export("gray", os.path.join(OUTD, f"{NAME}_gray_1k.png"))
    if RADIUS > 0:
        B = json.load(open(os.path.join(OUTD, "bones.json")))
        hc = (Vector(B["Head"][0]) + Vector(B["Head"][1])) / 2
        gi = {g.index: g.name for g in sq.vertex_groups}
        chest = sq.vertex_groups["Chest"]
        moved = 0
        for v in sq.data.vertices:
            if (v.co - hc).length > RADIUS:
                w = 0.0
                for g in v.groups:
                    if gi[g.group] in ("Head", "Neck"): w += g.weight
                if w > 0:
                    for nm in ("Head", "Neck"): sq.vertex_groups[nm].remove([v.index])
                    cur = 0.0
                    for g in v.groups:
                        if gi[g.group] == "Chest": cur = g.weight
                    chest.add([v.index], min(1.0, cur + w), "REPLACE"); moved += 1
        log(f"head-radius fix: {moved} vertices moved to Chest")
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUTD, f"{NAME}_rigged.blend"))
        export("color", os.path.join(OUTD, f"{NAME}_1k.png"))
        export("gray", os.path.join(OUTD, f"{NAME}_gray_1k.png"))
    # previews
    sc = bpy.context.scene; sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "TEXTURE"; sh.show_shadows = False
    sh.background_type = "VIEWPORT"; sh.background_color = (0.86, 0.88, 0.92)
    sc.render.film_transparent = False
    sc.render.resolution_x, sc.render.resolution_y = 700, 700; sc.render.image_settings.file_format = "PNG"
    sc.view_settings.view_transform = "Standard"
    for o in list(bpy.data.objects):
        if o.type == "CAMERA": bpy.data.objects.remove(o)
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(camo); sc.camera = camo
    cam.lens = 60
    ctr = Vector((0, 0, 1.15))
    camo.location = ctr + Vector((-6.0, -7.0, 2.6))
    camo.rotation_euler = (ctr - camo.location).to_track_quat("-Z", "Z").to_euler()
    for tag, png in (("color", f"{NAME}_1k.png"), ("gray", f"{NAME}_gray_1k.png")):
        tex.image = bpy.data.images.load(os.path.join(OUTD, png))
        sc.render.filepath = os.path.join(OUTD, f"preview_{tag}.png"); bpy.ops.render.render(write_still=True)
    log("FIX_DONE")
except Exception:
    log(traceback.format_exc())
