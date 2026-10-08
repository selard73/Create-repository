
import bpy
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')
mesh = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]
verts = [v.co for v in mesh.data.vertices]

# Tail verts: positive X and Y? Tail is at +X (0.3..1.1) and +Y
tail_candidates = [v for v in verts if v.x > 0.2 and v.y > 0.0]
out = []
out.append(f'Tail candidate count: {len(tail_candidates)}')
out.append(f'Tail X range: {min(v.x for v in tail_candidates):.2f} .. {max(v.x for v in tail_candidates):.2f}')
out.append(f'Tail Y range: {min(v.y for v in tail_candidates):.2f} .. {max(v.y for v in tail_candidates):.2f}')
out.append(f'Tail Z range: {min(v.z for v in tail_candidates):.2f} .. {max(v.z for v in tail_candidates):.2f}')

# Head verts: Z >= 1.45, what is X and Y?
head_candidates = [v for v in verts if v.z >= 1.45 and not (v.x > 0.25 and v.y > 0.15)]
out.append(f'Head candidate count: {len(head_candidates)}')
out.append(f'Head X range: {min(v.x for v in head_candidates):.2f} .. {max(v.x for v in head_candidates):.2f}')
out.append(f'Head Y range: {min(v.y for v in head_candidates):.2f} .. {max(v.y for v in head_candidates):.2f}')
out.append(f'Head Z range: {min(v.z for v in head_candidates):.2f} .. {max(v.z for v in head_candidates):.2f}')

# Rolling pin: held in right paw (which is -X side!). What is rolling pin verts?
pin_candidates = [v for v in verts if v.x < -0.4 and v.y < -0.1]
out.append(f'Pin candidate count: {len(pin_candidates)}')
out.append(f'Pin X range: {min(v.x for v in pin_candidates):.2f} .. {max(v.x for v in pin_candidates):.2f}')
out.append(f'Pin Y range: {min(v.y for v in pin_candidates):.2f} .. {max(v.y for v in pin_candidates):.2f}')
out.append(f'Pin Z range: {min(v.z for v in pin_candidates):.2f} .. {max(v.z for v in pin_candidates):.2f}')

with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/parts.txt', 'w') as f_out:
    f_out.write('\n'.join(out))
