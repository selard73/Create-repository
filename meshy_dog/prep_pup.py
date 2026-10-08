"""
Blender (headless) prep for a Meshy FBX so it imports cleanly into Roblox Studio:
  - reports the mesh stats
  - joins meshes, applies transforms, scales to a target height in studs
  - decimates to a Roblox-safe triangle count
  - points the material at the 1024px colour texture
  - exports pup_roblox.fbx next to this script, and writes report.json

Run:  blender --background --python prep_pup.py -- <in.fbx> <out.fbx> <colour_png> <target_tris> <height_studs>
"""
import bpy, json, sys, os

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
IN, OUT_FBX, COLOR_PNG = argv[0], argv[1], argv[2]
TARGET = int(argv[3]) if len(argv) > 3 else 9500
HEIGHT = float(argv[4]) if len(argv) > 4 else 5.0
here = os.path.dirname(os.path.abspath(IN))
report = {"input": IN}

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=IN)
meshes = [o for o in bpy.data.objects if o.type == "MESH"]
report["meshes_in"] = [{"name": o.name, "polys": len(o.data.polygons), "tris": sum(len(p.vertices) - 2 for p in o.data.polygons)} for o in meshes]

# join into one, apply transforms
for o in bpy.data.objects:
    o.select_set(o.type == "MESH")
bpy.context.view_layer.objects.active = meshes[0]
if len(meshes) > 1:
    bpy.ops.object.join()
dog = bpy.context.view_layer.objects.active
dog.name = "Hound"
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

# scale to target height and stand on the ground
dims = dog.dimensions
report["dims_in"] = [round(d, 3) for d in dims]
s = HEIGHT / dims.z if dims.z > 1e-6 else 1.0
dog.scale = (s, s, s)
bpy.ops.object.transform_apply(scale=True)
mn = min(v.co.z for v in dog.data.vertices)
for v in dog.data.vertices:
    v.co.z -= mn
report["dims_out"] = [round(d, 3) for d in dog.dimensions]

# decimate
tris = sum(len(p.vertices) - 2 for p in dog.data.polygons)
report["tris_before"] = tris
if tris > TARGET:
    mod = dog.modifiers.new("Decimate", "DECIMATE")
    mod.ratio = TARGET / tris
    mod.use_collapse_triangulate = True
    bpy.ops.object.modifier_apply(modifier=mod.name)
bpy.ops.object.shade_smooth()
report["tris_after"] = sum(len(p.vertices) - 2 for p in dog.data.polygons)

# one simple material: base colour texture only
for slot in list(dog.material_slots):
    pass
mat = bpy.data.materials.new("HoundMat")
mat.use_nodes = True
nt = mat.node_tree
for n in list(nt.nodes):
    nt.nodes.remove(n)
out = nt.nodes.new("ShaderNodeOutputMaterial")
bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
tex = nt.nodes.new("ShaderNodeTexImage")
tex.image = bpy.data.images.load(COLOR_PNG)
nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
dog.data.materials.clear()
dog.data.materials.append(mat)

bpy.ops.object.select_all(action="DESELECT")
dog.select_set(True)
bpy.ops.export_scene.fbx(filepath=OUT_FBX, use_selection=True, path_mode="COPY", embed_textures=False,
                         mesh_smooth_type="FACE", axis_forward="-Z", axis_up="Y", apply_unit_scale=True, bake_space_transform=True)
# also an OBJ (Roblox reads these reliably); MTL points at the 1k texture
obj_path = os.path.splitext(OUT_FBX)[0] + ".obj"
bpy.ops.wm.obj_export(filepath=obj_path, export_selected_objects=True, export_materials=True, export_normals=True, export_uv=True,
                      forward_axis="NEGATIVE_Z", up_axis="Y", path_mode="COPY")
report["output"] = OUT_FBX
report["output_obj"] = obj_path
with open(os.path.join(here, "report.json"), "w") as f:
    json.dump(report, f, indent=2)
print("PREP_DONE", json.dumps(report))
