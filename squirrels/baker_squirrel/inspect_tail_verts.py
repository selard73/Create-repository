import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]
verts = [v.co for v in mesh.data.vertices]

# In baker_squirrel.blend (unrigged):
# Let\'s see all vertices with X < -0.4:
neg_x = [v for v in verts if v.x < -0.4]
print(f'Total verts with X < -0.4: {len(neg_x)}')

# Are there ANY tail vertices at X < -0.4?
# Where is the tail physically located in this model?
# Tail starts at base: back of squirrel (Y > 0.1).
# Does the tail curl to +X or -X?
tail_high_y = [v for v in verts if v.y > 0.3]
print(f'Verts with Y > 0.3 (definitely back/tail): {len(tail_high_y)}')
print(f'X range of Y > 0.3 verts: {min(v.x for v in tail_high_y):.3f} .. {max(v.x for v in tail_high_y):.3f}')

# Let\'s check verts near X=-0.78, Y=-0.03, Z=2.22:
near_tip = [v for v in verts if (v.x - (-0.78))**2 + (v.y - (-0.03))**2 + (v.z - 2.22)**2 < 0.2**2]
print(f'Verts near (-0.78, -0.03, 2.22): {len(near_tip)}')
for v in near_tip[:5]:
    print(f'  {v.x:.3f}, {v.y:.3f}, {v.z:.3f}')
