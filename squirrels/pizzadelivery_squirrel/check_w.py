
import bpy
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=r'C:/Users/slard/roblox-props/squirrels/pizzadelivery_squirrel/pizzadelivery_squirrel_color.fbx')
mesh = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]
verts = [v.co for v in mesh.data.vertices]
front_verts = [v for v in verts if v.y < -0.3]
rear_verts = [v for v in verts if v.y > 0.3]
min_front = min(front_verts, key=lambda v: v.z)
min_rear = min(rear_verts, key=lambda v: v.z)
min_all = min(verts, key=lambda v: v.z)
with open(r'C:/Users/slard/roblox-props/squirrels/pizzadelivery_squirrel/wheels.txt', 'w') as f:
    f.write(f'ALL: {min_all.x} {min_all.y} {min_all.z}\n')
    f.write(f'FRONT: {min_front.x} {min_front.y} {min_front.z}\n')
    f.write(f'REAR: {min_rear.x} {min_rear.y} {min_rear.z}\n')
