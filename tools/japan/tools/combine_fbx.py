"""Blender headless: combine several FBX files into ONE FBX for a single Import 3D, one Empty per piece (named after the piece),
meshes parented, pieces 40 apart on X. Args: <out_fbx> <log> name=path [name=path ...]"""
import bpy, os, sys, traceback
argv = sys.argv[sys.argv.index("--") + 1:]
OUT, LOG, pairs = argv[0], argv[1], [a.split("=", 1) for a in argv[2:]]
def log(s):
    with open(LOG, "a", encoding="utf-8") as f: f.write(s + "\n")
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    x = 0.0
    for n, path in pairs:
        before = set(bpy.data.objects)
        bpy.ops.import_scene.fbx(filepath=path, use_image_search=False)
        new = [o for o in bpy.data.objects if o not in before]
        meshes = [o for o in new if o.type == "MESH"]
        emp = bpy.data.objects.new(n, None); bpy.context.scene.collection.objects.link(emp)
        for m in meshes:
            mw = m.matrix_world.copy(); m.parent = emp; m.matrix_world = mw
        for o in new:
            if o.type != "MESH" and not o.children: bpy.data.objects.remove(o, do_unlink=True)
        emp.location.x = x; x += 40.0
        log(f"{n}: {len(meshes)} meshes: " + ", ".join(m.name for m in meshes))
    bpy.ops.object.select_all(action="DESELECT")
    for o in bpy.data.objects: o.select_set(True)
    bpy.context.view_layer.objects.active = bpy.data.objects[0]
    bpy.ops.export_scene.fbx(filepath=OUT, use_selection=True, axis_forward="-Z", axis_up="Y", apply_scale_options="FBX_SCALE_ALL",
                             add_leaf_bones=False, bake_space_transform=True, object_types={"EMPTY", "MESH"})
    log("objects: " + ", ".join(sorted(o.name for o in bpy.data.objects)))
    log(f"COMBINE_DONE {OUT} {os.path.getsize(OUT)} bytes")
except Exception:
    log(traceback.format_exc()); log("COMBINE_FAILED")
