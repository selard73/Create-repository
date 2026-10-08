
import bpy, math
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')
mesh = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]

verts = [v.co for v in mesh.data.vertices]
xs = [v.x for v in verts]
ys = [v.y for v in verts]
zs = [v.z for v in verts]
print(f'X: {min(xs):.3f} .. {max(xs):.3f}')
print(f'Y: {min(ys):.3f} .. {max(ys):.3f}')
print(f'Z: {min(zs):.3f} .. {max(zs):.3f}')

# Set up camera looking from front (canonical front is -Y looking towards +Y)
cam_data = bpy.data.cameras.new('FrontCam')
cam_obj = bpy.data.objects.new('FrontCam', cam_data)
bpy.context.scene.collection.objects.link(cam_obj)
bpy.context.scene.camera = cam_obj

cam_obj.location = (0, -4.0, 1.2)
cam_obj.rotation_euler = (math.radians(90), 0, 0)

# Add sun light
light_data = bpy.data.lights.new('Sun', type='SUN')
light_data.energy = 3.0
light_obj = bpy.data.objects.new('Sun', light_data)
bpy.context.scene.collection.objects.link(light_obj)
light_obj.rotation_euler = (math.radians(45), math.radians(30), math.radians(45))

bpy.context.scene.render.resolution_x = 800
bpy.context.scene.render.resolution_y = 800
bpy.context.scene.render.filepath = r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/check_front.png'
bpy.ops.render.render(write_still=True)
