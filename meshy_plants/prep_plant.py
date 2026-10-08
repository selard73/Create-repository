"""Blender (headless) prep for a Meshy plant FBX so it imports cleanly into Roblox Studio and can be judged first:
  - joins meshes, applies transforms, scales to a target height in studs, stands it on the ground (z = 0)
  - decimates to a Roblox-safe triangle count, smooth shading
  - one material: the 1024px colour texture
  - exports <name>.fbx and <name>.obj (+ .mtl pointing at the texture) into the model's folder
  - renders <name>_preview.png (Workbench, textured, three-quarter view)
  - writes report.json (stats) so the caller can poll for completion
Run: blender --background --python prep_plant.py -- <in.fbx> <out_dir> <name> <colour_1k.png> <target_tris> <height_studs>
"""
import bpy, json, sys, os, traceback
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
IN, OUT_DIR, NAME, COLOR_PNG = argv[0], argv[1], argv[2], argv[3]
TARGET = int(argv[4]) if len(argv) > 4 else 8000
HEIGHT = float(argv[5]) if len(argv) > 5 else 4.0
report = {"input": IN, "name": NAME}
LOG = os.path.join(OUT_DIR, "prep_log.txt")


def log(msg):
    with open(LOG, "a") as f:
        f.write(str(msg) + "\n")


try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=IN)
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    report["meshes_in"] = len(meshes)
    for o in bpy.data.objects:
        o.select_set(o.type == "MESH")
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    plant = bpy.context.view_layer.objects.active
    plant.name = NAME
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    dims = plant.dimensions
    report["dims_in"] = [round(d, 3) for d in dims]
    s = HEIGHT / dims.z if dims.z > 1e-6 else 1.0
    plant.scale = (s, s, s)
    bpy.ops.object.transform_apply(scale=True)
    mn = min(v.co.z for v in plant.data.vertices)
    cx = sum(v.co.x for v in plant.data.vertices) / len(plant.data.vertices)
    cy = sum(v.co.y for v in plant.data.vertices) / len(plant.data.vertices)
    for v in plant.data.vertices:
        v.co.z -= mn
        v.co.x -= cx
        v.co.y -= cy
    report["dims_out"] = [round(d, 3) for d in plant.dimensions]
    tris = sum(len(p.vertices) - 2 for p in plant.data.polygons)
    report["tris_before"] = tris
    if tris > TARGET:
        mod = plant.modifiers.new("Decimate", "DECIMATE")
        mod.ratio = TARGET / tris
        mod.use_collapse_triangulate = True
        bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.ops.object.shade_smooth()
    report["tris_after"] = sum(len(p.vertices) - 2 for p in plant.data.polygons)
    # one material, colour texture only
    mat = bpy.data.materials.new(NAME + "Mat")
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
    plant.data.materials.clear()
    plant.data.materials.append(mat)
    # export
    bpy.ops.object.select_all(action="DESELECT")
    plant.select_set(True)
    fbx_path = os.path.join(OUT_DIR, NAME + ".fbx")
    obj_path = os.path.join(OUT_DIR, NAME + ".obj")
    bpy.ops.export_scene.fbx(filepath=fbx_path, use_selection=True, path_mode="COPY", embed_textures=False,
                             mesh_smooth_type="FACE", axis_forward="-Z", axis_up="Y", apply_unit_scale=True, bake_space_transform=True)
    bpy.ops.wm.obj_export(filepath=obj_path, export_selected_objects=True, export_materials=True, export_normals=True, export_uv=True,
                          forward_axis="NEGATIVE_Z", up_axis="Y", path_mode="COPY")
    report["fbx"] = fbx_path
    report["obj"] = obj_path
    # preview render: Workbench, textured, three-quarter view
    size = max(plant.dimensions)
    c = Vector((0, 0, plant.dimensions.z / 2))
    bpy.ops.mesh.primitive_plane_add(size=size * 6, location=(0, 0, 0))
    g = bpy.context.object
    gm = bpy.data.materials.new("Ground"); gm.diffuse_color = (0.45, 0.62, 0.35, 1); g.data.materials.append(gm)
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam)
    bpy.context.scene.collection.objects.link(camo)
    camo.location = c + Vector((size * 1.5, -size * 2.1, size * 0.9))
    camo.rotation_euler = (c - camo.location).to_track_quat("-Z", "Y").to_euler()
    cam.lens = 50
    sc = bpy.context.scene
    sc.camera = camo
    sc.render.engine = "BLENDER_WORKBENCH"
    sc.display.shading.light = "STUDIO"
    sc.display.shading.color_type = "TEXTURE"
    sc.display.shading.show_shadows = True
    sc.render.resolution_x, sc.render.resolution_y = 900, 900
    sc.render.film_transparent = False
    sc.world = bpy.data.worlds.new("W"); sc.world.color = (0.86, 0.92, 0.98)
    prev = os.path.join(OUT_DIR, NAME + "_preview.png")
    sc.render.filepath = prev
    bpy.ops.render.render(write_still=True)
    report["preview"] = prev
    report["ok"] = True
except Exception as e:
    report["ok"] = False
    report["error"] = traceback.format_exc()
    log(report["error"])
with open(os.path.join(OUT_DIR, "report.json"), "w") as f:
    json.dump(report, f, indent=2)
log("PREP_DONE " + json.dumps(report))
