import bpy, os, sys, traceback
D = os.path.dirname(os.path.abspath(__file__))
LOG = os.path.join(D, "obj2fbx_log.txt")
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.wm.obj_import(filepath=os.path.join(D, "tidepools_roblox.obj"), forward_axis="NEGATIVE_Z", up_axis="Y")
    for o in bpy.data.objects:
        if o.type == "MESH":
            for p in o.data.polygons: p.use_smooth = o.name.startswith("TidePoolShelf")
            o.select_set(True)
            open(LOG, "a").write(f"{o.name} verts {len(o.data.vertices)} dims {tuple(round(v,3) for v in o.dimensions)}\n")
    bpy.ops.export_scene.fbx(filepath=os.path.join(D, "tidepools_roblox.fbx"), use_selection=True, axis_forward="-Z", axis_up="Y",
                             apply_scale_options="FBX_SCALE_ALL", path_mode="COPY", embed_textures=True, add_leaf_bones=False, bake_space_transform=True)
    open(LOG, "a").write("FBX_DONE\n")
except Exception:
    open(LOG, "a").write(traceback.format_exc())
