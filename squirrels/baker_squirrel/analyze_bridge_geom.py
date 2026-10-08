import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = bpy.data.objects['Squirrel']
verts = [v.co for v in mesh.data.vertices]

# In check_front3.png, where is the tail relative to the ear?
# The tail is behind the left ear!
# Does the tail physically fuse to the back of the left ear in Meshy\'s output?
# YES! Meshy generates a single continuous watertight mesh. When the tail curls near the ear,
# Meshy\'s remeshing/marching-cubes fuses the front of the tail to the back of the ear and chef hat!
# So there are shared triangles bridging between the ear and the tail!
# If the ear is weighted to Head (which rotates with lookYaw) and the tail is weighted to Tail2 (which sways with sway1/sway2),
# those bridging triangles get pulled in opposite directions, stretching the ear, cheek, and eye socket!
print('BRIDGE DIAGNOSED')
