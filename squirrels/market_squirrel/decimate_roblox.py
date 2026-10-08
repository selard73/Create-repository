import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/market_squirrel/market_squirrel_prepped.blend')

obj = bpy.data.objects['Squirrel']
mod = obj.modifiers.new("Decimate2", 'DECIMATE')
mod.ratio = 0.50 # 37.6k -> 18.8k tris
bpy.context.view_layer.objects.active = obj
bpy.ops.object.modifier_apply(modifier="Decimate2")

with open(r'C:/Users/slard/roblox-props/squirrels/market_squirrel/prep_stats.txt', 'w') as f:
    f.write(f"Verts: {len(obj.data.vertices)}\n")
    f.write(f"Polys: {len(obj.data.polygons)}\n")

bpy.ops.wm.save_as_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/market_squirrel/market_squirrel_prepped.blend')
print("DECIMATE_TARGET_DONE")
