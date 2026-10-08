import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]
verts = [v.co for v in mesh.data.vertices]

# Squirrel is holding rolling pin in hand:
# Which hand is holding the pin?
# Let\'s check verts with X > 0 vs X < 0:
# In check_front3.png:
# Rolling pin was on the LEFT side of the image (viewer\'s left, which is X < 0)!
# And squirrel\'s huge bushy tail was on the RIGHT side of the image (viewer\'s right, which is X > 0)!
pos_x = [v for v in verts if v.x > 0.3]
neg_x = [v for v in verts if v.x < -0.3]

with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/sides.txt', 'w') as out:
    out.write(f'X > 0.3 (viewer right, squirrel left): {len(pos_x)} verts, Y={min(v.y for v in pos_x):.2f}..{max(v.y for v in pos_x):.2f}, Z={min(v.z for v in pos_x):.2f}..{max(v.z for v in pos_x):.2f}\n')
    out.write(f'X < -0.3 (viewer left, squirrel right): {len(neg_x)} verts, Y={min(v.y for v in neg_x):.2f}..{max(v.y for v in neg_x):.2f}, Z={min(v.z for v in neg_x):.2f}..{max(v.z for v in neg_x):.2f}\n')
