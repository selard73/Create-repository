"""Export the rigged pup as GLB (fallback for Studio's Import 3D). Run: blender --background --python export_glb.py -- <out_dir>"""
import bpy, sys, os, traceback
argv = sys.argv[sys.argv.index("--") + 1:]
OUTD = argv[0]
LOG = os.path.join(OUTD, "glb_log.txt")
try:
    open(LOG, "w").close()
    bpy.ops.wm.open_mainfile(filepath=os.path.join(OUTD, "pup_rigged.blend"))
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUTD, "pup_rigged.glb"), export_format="GLB", use_selection=True,
                              export_yup=True, export_apply=False, export_skins=True, export_animations=False,
                              export_image_format="AUTO", export_texcoords=True, export_normals=True)
    with open(LOG, "a") as f: f.write("GLB_DONE\n")
except Exception:
    with open(LOG, "a") as f: f.write(traceback.format_exc())
