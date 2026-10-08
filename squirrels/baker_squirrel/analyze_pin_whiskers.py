import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = bpy.data.objects['Squirrel']
verts = [v.co for v in mesh.data.vertices]

# Nose is at X=-0.033, Y=-0.770, Z=1.594.
# Head is centered around X ~ -0.15..-0.05.
# So:
# Squirrel\'s LEFT cheek is at X > -0.03 (towards +X)!
# Squirrel\'s RIGHT cheek is at X < -0.03 (towards -X)!
# The rolling pin is at X < -0.55!
# Why did head_front have X from -1.071 to +0.212?
# Because the rolling pin and whiskers reach out to X = -1.071!
# What reaches out to +X?
# Only X = 0.212!
# Why does the head stop at X = 0.212? Because his left cheek touches his tail or his head is turned slightly to the right!
# Let\'s check verts with X > 0.10 and Z >= 1.40:
pos_x_head = [v for v in verts if v.x > 0.10 and v.z >= 1.40]
print(f'Verts with X > 0.10 and Z >= 1.40: {len(pos_x_head)}')
with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/pos_x_head.txt', 'w') as out:
    for v in pos_x_head[:30]:
        out.write(f'idx {v.index}: ({v.x:.3f}, {v.y:.3f}, {v.z:.3f})\n')
