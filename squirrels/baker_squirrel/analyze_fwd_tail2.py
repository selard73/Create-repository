import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = bpy.data.objects['Squirrel']
verts = [v.co for v in mesh.data.vertices]

# Look at verts around X=0.20..0.55, Y=-0.35..0.05, Z=1.40..2.10.
# What are they? The squirrel\'s left ear and chef toque hat!
# Left ear of the squirrel is at X ~ 0.20..0.45, Z ~ 1.9..2.3, Y ~ -0.1..-0.3!
# Look at check_front3.png! The left ear sticks out sideways at the top!
# In our rebuild_rig.py:
# We used: if co.x > 0.25 and co.y > 0.05: -> Tail!
# But for any Z < 1.55 we didn\'t check if X > 0.25!
# What about for Z in 1.40..1.55?
# If co.z < 1.55, but co.x > 0.25 and co.y in -0.05..0.05, it fell into Neck/Chest!
# And what about the tail? Where does the tail end in the front?
# The tail is purely behind him (Y > 0.15)!
# But our tail rule was:
# if co.x > 0.25 and co.y > 0.05: Tail!
# So vertices on the back of his left ear / chef hat (with Y in 0.05..0.15) were assigned to TAIL2!
# And vertices on the front of his left ear / cheek were assigned to HEAD!
# So half of his left ear and cheek was on Head, and half was on Tail2!
# When Tail2 wagged or swung, it literally tore his left ear and cheek in half!
