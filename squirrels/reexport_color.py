"""Oct 5 2026: re-export ONLY the colour FBX of a rigged squirrel with a new colour texture (weights untouched).
Run: blender --background --python reexport_color.py -- <out_dir> <name> <png>"""
import bpy, sys, os, traceback
argv = sys.argv[sys.argv.index("--") + 1:]
OUTD, NAME, PNG = argv[0], argv[1], argv[2]
LOG = os.path.join(OUTD, "reexport_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
try:
    open(LOG, "w").close()
    bpy.ops.wm.open_mainfile(filepath=os.path.join(OUTD, f"{NAME}_rigged.blend"))
    sq = bpy.data.objects["Squirrel"]
    arm = [o for o in bpy.data.objects if o.type == "ARMATURE"][0]
    tex = [n for n in sq.data.materials[0].node_tree.nodes if n.type == "TEX_IMAGE"][0]
    tex.image = bpy.data.images.load(PNG)
    bpy.ops.object.select_all(action="DESELECT"); sq.select_set(True); arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.export_scene.fbx(filepath=os.path.join(OUTD, f"{NAME}_color.fbx"), use_selection=True, add_leaf_bones=False,
                             bake_anim=False, path_mode="COPY", embed_textures=True, mesh_smooth_type="FACE",
                             global_scale=0.01, apply_unit_scale=True, apply_scale_options="FBX_SCALE_NONE")
    log("REEXPORT_DONE " + PNG)
except Exception:
    log(traceback.format_exc())
