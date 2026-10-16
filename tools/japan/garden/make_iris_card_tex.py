"""The iris flower card with its picture INSIDE the FBX (runner 7, Oct 16 2026). Shannon: "why does the flower have to go in differently
than all of the other items?" - it doesn't: Studio's 3D importer uploads an embedded texture and sets the MeshPart's TextureID, as it
did for her Meshy koi. Takes out_iris/flower_card.fbx (two crossed unit quads, 0..1 UVs) + out_iris/iris_card.png (RGBA), gives the
mesh a material with the picture (alpha kept), exports out_iris/iris_card_tex.fbx with the texture embedded, one Empty "iris_card".
Args: <out_iris dir> <log>"""
import bpy, os, sys, traceback
argv = sys.argv[sys.argv.index("--") + 1:]
D, LOG = argv[0], argv[1]
def log(s):
    with open(LOG, "a", encoding="utf-8") as f: f.write(str(s) + "\n")
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=os.path.join(D, "flower_card.fbx"))
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    for o in [o for o in bpy.data.objects if o.type != "MESH"]: bpy.data.objects.remove(o, do_unlink=True)
    o = meshes[0]; o.name = "Iris_Card"; o.parent = None
    img = bpy.data.images.load(os.path.join(D, "iris_card.png")); img.alpha_mode = "STRAIGHT"; img.pack()
    mat = bpy.data.materials.new("IrisCard"); mat.use_nodes = True; nt = mat.node_tree
    bs = nt.nodes["Principled BSDF"]; tex = nt.nodes.new("ShaderNodeTexImage"); tex.image = img
    nt.links.new(tex.outputs["Color"], bs.inputs["Base Color"]); nt.links.new(tex.outputs["Alpha"], bs.inputs["Alpha"])
    try: mat.blend_method = "CLIP"
    except Exception: pass
    o.data.materials.clear(); o.data.materials.append(mat)
    log(f"mesh {o.name}: {len(o.data.vertices)} verts, {len(o.data.polygons)} faces, uv layers {len(o.data.uv_layers)}; image {img.size[0]}x{img.size[1]} channels {img.channels}")
    emp = bpy.data.objects.new("iris_card", None); bpy.context.scene.collection.objects.link(emp)
    mw = o.matrix_world.copy(); o.parent = emp; o.matrix_world = mw
    bpy.ops.object.select_all(action="DESELECT"); emp.select_set(True); o.select_set(True); bpy.context.view_layer.objects.active = emp
    out = os.path.join(D, "iris_card_tex.fbx")
    bpy.ops.export_scene.fbx(filepath=out, use_selection=True, axis_forward="-Z", axis_up="Y", apply_scale_options="FBX_SCALE_ALL",
                             add_leaf_bones=False, bake_space_transform=True, object_types={"EMPTY", "MESH"}, path_mode="COPY", embed_textures=True)
    log(f"IRIS_DONE {out} {os.path.getsize(out)} bytes")
except Exception:
    log(traceback.format_exc()); log("IRIS_FAILED")
