
import bpy
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')
mesh = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]
verts = [v.co for v in mesh.data.vertices]

# Pin is held in paw around X=-0.7, Y=-0.4, Z=1.1..1.9
pin_top = [v for v in verts if v.x < -0.4 and v.z > 1.4 and v.y < -0.1]
print(f'Pin top count: {len(pin_top)}')
print(f'Pin top X: {min(v.x for v in pin_top):.2f} .. {max(v.x for v in pin_top):.2f}')
print(f'Pin top Y: {min(v.y for v in pin_top):.2f} .. {max(v.y for v in pin_top):.2f}')
print(f'Pin top Z: {min(v.z for v in pin_top):.2f} .. {max(v.z for v in pin_top):.2f}')

# Head without pin:
# Head is centered around X=-0.15..0.2, Y=-0.5..0.2, Z >= 1.45
head_center = [v for v in verts if v.z >= 1.45 and v.x > -0.45 and not (v.x > 0.25 and v.y > 0.15)]
print(f'Head center count: {len(head_center)}')
print(f'Head center X: {min(v.x for v in head_center):.2f} .. {max(v.x for v in head_center):.2f}')
print(f'Head center Y: {min(v.y for v in head_center):.2f} .. {max(v.y for v in head_center):.2f}')
print(f'Head center Z: {min(v.z for v in head_center):.2f} .. {max(v.z for v in head_center):.2f}')
with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/pin_data.txt', 'w') as f_out:
    f_out.write(f'Pin top: {len(pin_top)} verts, X: {min(v.x for v in pin_top):.2f}..{max(v.x for v in pin_top):.2f}\n')
    f_out.write(f'Head center: {len(head_center)} verts, X: {min(v.x for v in head_center):.2f}..{max(v.x for v in head_center):.2f}\n')
