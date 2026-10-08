import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')

mesh = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]
arm = [o for o in bpy.context.scene.objects if o.type == 'ARMATURE'][0]

vgs = {vg.name: vg.index for vg in mesh.vertex_groups}
print('Vertex groups:', list(vgs.keys()))

# The squirrel faces canonical -Y.
# Viewer looking at his face from the front sees:
# Squirrel\'s left side (viewer\'s right) is +X!
# Wait! In our earlier checks:
# Tail was at +X (0.20 .. 1.09) and +Y!
# Tail1: (0.0, 0.35, 0.95) -> (0.0, 0.8, 1.8)
# Tail2: (0.0, 0.8, 1.8) -> (-0.78, -0.03, 2.22)
# Look at Tail2 tip! Tip is at X=-0.78, Y=-0.03, Z=2.22!
# That curls up over or behind his head on the -X side or +X side!

# Let\'s find all vertices in his head (Z >= 1.45, Y <= 0.0) that have Tail1 or Tail2 weight!
tail_on_head = []
for v in mesh.data.vertices:
    co = v.co
    if co.z >= 1.40 and co.y <= 0.10:
        w_tail1 = 0
        w_tail2 = 0
        w_chest = 0
        w_head = 0
        for g in v.groups:
            if g.group == vgs.get('Tail1'): w_tail1 = g.weight
            if g.group == vgs.get('Tail2'): w_tail2 = g.weight
            if g.group == vgs.get('Chest'): w_chest = g.weight
            if g.group == vgs.get('Head'): w_head = g.weight
        if (w_tail1 + w_tail2) > 0.001 or w_chest > 0.05:
            tail_on_head.append((v.index, co.x, co.y, co.z, w_tail1, w_tail2, w_chest, w_head))

with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/face_weights.txt', 'w') as out:
    out.write(f'Head verts with tail or chest pull: {len(tail_on_head)}\n')
    for row in tail_on_head[:30]:
        out.write(f'idx {row[0]}: X={row[1]:.3f}, Y={row[2]:.3f}, Z={row[3]:.3f} | Tail1={row[4]:.3f}, Tail2={row[5]:.3f}, Chest={row[6]:.3f}, Head={row[7]:.3f}\n')
