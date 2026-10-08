
import bpy
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=r'C:/Users/slard/roblox-props/squirrels/pizzadelivery_squirrel/pizzadelivery_squirrel_color.fbx')
mesh = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]
root = [o for o in bpy.context.scene.objects if o.type == 'ARMATURE'][0]
print('Armature matrix:', root.matrix_world)
print('Mesh matrix:', mesh.matrix_world)

# Let's find vertex indices of the lowest point on front and rear wheels
verts = [v.co for v in mesh.data.vertices]
front_idx = min([i for i, v in enumerate(verts) if v.y < -0.3], key=lambda i: verts[i].z)
rear_idx = min([i for i, v in enumerate(verts) if v.y > 0.3], key=lambda i: verts[i].z)
print('Front vert idx:', front_idx, verts[front_idx])
print('Rear vert idx:', rear_idx, verts[rear_idx])

# In Blender FBX export to Roblox:
# Default Blender forward is -Y, up is +Z.
# In Roblox MeshPart:
# Roblox Size = (mesh_x, mesh_z, mesh_y) or how?
# Let's check bbox dimensions:
xs = [v.x for v in verts]
ys = [v.y for v in verts]
zs = [v.z for v in verts]
print('Blender bounds:')
print(f'X: {min(xs)} .. {max(xs)} (sz: {max(xs)-min(xs)})')
print(f'Y: {min(ys)} .. {max(ys)} (sz: {max(ys)-min(ys)})')
print(f'Z: {min(zs)} .. {max(zs)} (sz: {max(zs)-min(zs)})')
