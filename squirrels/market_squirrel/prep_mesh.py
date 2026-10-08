import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/market_squirrel/market_squirrel.blend')

obj = bpy.data.objects['Mesh_0']
obj.name = 'Squirrel'

# Check initial stats
print(f"Initial verts: {len(obj.data.vertices)}, polys: {len(obj.data.polygons)}")

# Apply Decimate modifier to target ~18000 polys
mod = obj.modifiers.new("Decimate", 'DECIMATE')
mod.ratio = 0.033 # 570k * 0.033 ≈ 18.8k tris
bpy.context.view_layer.objects.active = obj
bpy.ops.object.modifier_apply(modifier="Decimate")

print(f"Decimated verts: {len(obj.data.vertices)}, polys: {len(obj.data.polygons)}")

# Center XY, place soles at Z = 0, scale to height 2.4
xs = [v.co.x for v in obj.data.vertices]
ys = [v.co.y for v in obj.data.vertices]
zs = [v.co.z for v in obj.data.vertices]

min_x, max_x = min(xs), max(xs)
min_y, max_y = min(ys), max(ys)
min_z, max_z = min(zs), max(zs)

raw_height = max_z - min_z
scale_factor = 2.4 / raw_height

print(f"Raw height: {raw_height:.4f}, scale factor: {scale_factor:.4f}")

# Center and scale
center_x = (min_x + max_x) / 2
center_y = (min_y + max_y) / 2

for v in obj.data.vertices:
    v.co.x = (v.co.x - center_x) * scale_factor
    v.co.y = (v.co.y - center_y) * scale_factor
    v.co.z = (v.co.z - min_z) * scale_factor

xs = [v.co.x for v in obj.data.vertices]
ys = [v.co.y for v in obj.data.vertices]
zs = [v.co.z for v in obj.data.vertices]

with open(r'C:/Users/slard/roblox-props/squirrels/market_squirrel/prep_stats.txt', 'w') as f:
    f.write(f"Verts: {len(obj.data.vertices)}\n")
    f.write(f"Polys: {len(obj.data.polygons)}\n")
    f.write(f"X range: [{min(xs):.4f}, {max(xs):.4f}]\n")
    f.write(f"Y range: [{min(ys):.4f}, {max(ys):.4f}]\n")
    f.write(f"Z range: [{min(zs):.4f}, {max(zs):.4f}]\n")

bpy.ops.wm.save_as_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/market_squirrel/market_squirrel_prepped.blend')
print("PREP_DONE")
