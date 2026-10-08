"""Prepares Meshy's carved-plaque GLB for Roblox: joins it, decimates to a few thousand triangles, shrinks the
textures to 1024 and writes a small GLB Studio's 3D importer will accept.
Run: blender --background --python prep_plaque_glb.py -- <in.glb> <out.glb> [target_tris]"""
import bpy, sys, os

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, OUT = argv[0], argv[1]
TARGET = int(argv[2]) if len(argv) > 2 else 9000

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)

meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
print("imported meshes:", len(meshes), [o.name for o in meshes])
for o in meshes:
    o.select_set(True)
bpy.context.view_layer.objects.active = meshes[0]
if len(meshes) > 1:
    bpy.ops.object.join()
obj = bpy.context.view_layer.objects.active

tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
print("triangles before:", tris)
if tris > TARGET:
    mod = obj.modifiers.new("Decimate", "DECIMATE")
    mod.ratio = max(0.01, TARGET / tris)
    bpy.ops.object.modifier_apply(modifier=mod.name)
    tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
print("triangles after:", tris)

# shrink every packed image so the GLB is small enough to upload
for img in bpy.data.images:
    if img.size[0] > 1024 or img.size[1] > 1024:
        print("resizing", img.name, img.size[:])
        img.scale(1024, 1024)

bpy.ops.object.select_all(action="DESELECT")
obj.select_set(True)
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True,
                          export_image_format="JPEG", export_jpeg_quality=85)
print("wrote", OUT, os.path.getsize(OUT), "bytes")
