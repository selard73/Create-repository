import bpy, math
from mathutils import Vector

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=r"C:/Users/slard/roblox-props/squirrels/police_squirrel/police_squirrel_raw.fbx")

mesh = [o for o in bpy.data.objects if o.type == 'MESH'][0]
mesh.name = "Squirrel"

# Make single user & apply transform
bpy.context.view_layer.objects.active = mesh
bpy.ops.object.select_all(action='DESELECT')
mesh.select_set(True)

# Remove existing animation data, modifiers, vertex groups
mesh.animation_data_clear()
mesh.modifiers.clear()
mesh.vertex_groups.clear()

# Find bounds before scaling
bpy.context.view_layer.update()
bbox = [mesh.matrix_world @ Vector(corner) for corner in mesh.bound_box]
min_z = min(v.z for v in bbox)
max_z = max(v.z for v in bbox)
height = max_z - min_z

print(f"Initial height: {height:.4f}")

# Target height = 2.4 Blender units (Roblox studs)
scale_factor = 2.40 / height
mesh.scale = Vector((scale_factor, scale_factor, scale_factor))
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)

# Place bottom at Z = 0.0 and center X, Y at 0
bpy.context.view_layer.update()
bbox = [mesh.matrix_world @ Vector(corner) for corner in mesh.bound_box]
min_z = min(v.z for v in bbox)
min_x = min(v.x for v in bbox)
max_x = max(v.x for v in bbox)
min_y = min(v.y for v in bbox)
max_y = max(v.y for v in bbox)

center_x = (min_x + max_x) / 2.0
center_y = (min_y + max_y) / 2.0

mesh.location.x -= center_x
mesh.location.y -= center_y
mesh.location.z -= min_z
bpy.ops.object.transform_apply(location=True, rotation=False, scale=False)

# Decimate to target ~18,500 polygons (< 21,000 for Roblox)
target_polys = 18500
current_polys = len(mesh.data.polygons)
ratio = target_polys / current_polys

print(f"Decimating from {current_polys} with ratio {ratio:.5f}")
mod = mesh.modifiers.new("Decimate", 'DECIMATE')
mod.ratio = ratio
bpy.ops.object.modifier_apply(modifier="Decimate")

print(f"Final Polygons: {len(mesh.data.polygons)}, Vertices: {len(mesh.data.vertices)}")

# Save prepped blend
bpy.ops.wm.save_as_mainfile(filepath=r"C:/Users/slard/roblox-props/squirrels/police_squirrel/police_squirrel_prepped.blend")

with open(r"C:/Users/slard/roblox-props/squirrels/police_squirrel/prep_stats.txt", "w") as f:
    f.write(f"Polys: {len(mesh.data.polygons)}\nVerts: {len(mesh.data.vertices)}\n")

print("PREP_DONE")
