import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]
verts = [v.co for v in mesh.data.vertices]

# The tail is on +X side!
tail_verts = [v for v in verts if v.x > 0.25 and v.y > 0.0]
# Find tail base (lowest Z on tail), tail mid, and tail tip (highest Z or curly end on tail):
tail_sorted_z = sorted(tail_verts, key=lambda v: v.z)
base = tail_sorted_z[0]
top = tail_sorted_z[-1]
# Curly tip of tail:
tip_candidates = [v for v in tail_verts if v.z > 1.8]

with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/tail_bones_plan.txt', 'w') as out:
    out.write(f'Tail verts: {len(tail_verts)}\n')
    out.write(f'Tail base: {base.x:.3f}, {base.y:.3f}, {base.z:.3f}\n')
    out.write(f'Tail top: {top.x:.3f}, {top.y:.3f}, {top.z:.3f}\n')
    out.write(f'Tail tip candidates count: {len(tip_candidates)}\n')
    if tip_candidates:
        mean_x = sum(v.x for v in tip_candidates) / len(tip_candidates)
        mean_y = sum(v.y for v in tip_candidates) / len(tip_candidates)
        mean_z = sum(v.z for v in tip_candidates) / len(tip_candidates)
        out.write(f'Tail tip mean: {mean_x:.3f}, {mean_y:.3f}, {mean_z:.3f}\n')
