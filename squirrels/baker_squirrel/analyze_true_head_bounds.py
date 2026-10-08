import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = bpy.data.objects['Squirrel']
verts = [v.co for v in mesh.data.vertices]

# The head is centered around X = -0.10.
# Where does his head end on the +X side?
# Looking at the chef hat and his left cheek:
# Muzzle / nose: X = -0.033, Y = -0.770, Z = 1.594.
# Left eye: X in 0.0 .. 0.15, Y in -0.50 .. -0.30, Z in 1.70 .. 2.00.
# Left cheek: X in 0.05 .. 0.22, Y in -0.60 .. -0.25, Z in 1.55 .. 1.80.
# Left ear / chef hat: X in 0.0 .. 0.25, Y in -0.35 .. -0.05, Z in 1.85 .. 2.35.
# ANYTHING at X > 0.25 and Z < 1.80 is SHOULDER (if Y < 0.05) or TAIL (if Y >= 0.05)!
# It is NEVER HEAD!
# Let\'s see all vertices with X > 0.25 and Z < 1.80:
shoulder_tail = [v for v in verts if v.x > 0.25 and v.z < 1.80]
print('Shoulder/tail verts (X > 0.25, Z < 1.80):', len(shoulder_tail))

with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/true_head.txt', 'w') as out:
    out.write(f'Shoulder/tail count: {len(shoulder_tail)}\n')
