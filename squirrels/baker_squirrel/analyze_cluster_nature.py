import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = bpy.data.objects['Squirrel']
verts = [v.co for v in mesh.data.vertices]

# Look at the cluster at X in [0.35, 0.70], Y in [0.00, 0.15], Z in [1.35, 1.75].
# In baker_ref_front.png or check_front3.png:
# Looking at the front of the squirrel:
# What is on the right side of his body at chest/shoulder level?
# His left shoulder and left paw resting on his hip!
# Look at baker_ref_front.png!
# His left paw is resting on his hip / apron at X ~ 0.40, Y ~ -0.10, Z ~ 1.0..1.3.
# His left shoulder is at X ~ 0.35..0.55, Z ~ 1.35..1.60!
# And what is right behind his shoulder?
# THE FRONT FLUFF OF HIS TAIL!
# The tail is enormous and curves around behind his left shoulder!
# In our previous rebuild_rig.py:
# We used: if co.z >= 1.55: Head!
# So any vertex on the top of his shoulder or front of the tail above 1.55 got Head:1.0!
# While the rest of the shoulder got Chest:1.0!
# And the tail right behind it got Tail2:1.0!
# So his left shoulder / cheek fluff was torn 3 ways between Head, Chest, and Tail2!
