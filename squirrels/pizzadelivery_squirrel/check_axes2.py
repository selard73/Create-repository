
import bpy
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=r'C:/Users/slard/roblox-props/squirrels/pizzadelivery_squirrel/pizzadelivery_squirrel_color.fbx')
mesh = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]
verts = [v.co for v in mesh.data.vertices]
xs = [v.x for v in verts]
ys = [v.y for v in verts]
zs = [v.z for v in verts]
front_idx = min([i for i, v in enumerate(verts) if v.y < -0.3], key=lambda i: verts[i].z)
rear_idx = min([i for i, v in enumerate(verts) if v.y > 0.3], key=lambda i: verts[i].z)
with open(r'C:/Users/slard/roblox-props/squirrels/pizzadelivery_squirrel/bounds.txt', 'w') as out:
    out.write(f'X: {min(xs)} .. {max(xs)} sz={max(xs)-min(xs)}\n')
    out.write(f'Y: {min(ys)} .. {max(ys)} sz={max(ys)-min(ys)}\n')
    out.write(f'Z: {min(zs)} .. {max(zs)} sz={max(zs)-min(zs)}\n')
    out.write(f'Front: {verts[front_idx]}\n')
    out.write(f'Rear: {verts[rear_idx]}\n')
