
import bpy, math
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')
mesh = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]

bpy.context.view_layer.objects.active = mesh
mesh.select_set(True)
bpy.ops.transform.rotate(value=math.radians(180), orient_axis='Z')
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

# Render front check
cam_data = bpy.data.cameras.new('FrontCam')
cam_obj = bpy.data.objects.new('FrontCam', cam_data)
bpy.context.scene.collection.objects.link(cam_obj)
bpy.context.scene.camera = cam_obj
cam_obj.location = (0, -4.0, 1.2)
cam_obj.rotation_euler = (math.radians(90), 0, 0)

light_data = bpy.data.lights.new('Sun', type='SUN')
light_data.energy = 4.0
light_obj = bpy.data.objects.new('Sun', light_data)
bpy.context.scene.collection.objects.link(light_obj)
light_obj.rotation_euler = (math.radians(30), math.radians(-20), math.radians(10))

bpy.context.scene.render.resolution_x = 800
bpy.context.scene.render.resolution_y = 800
bpy.context.scene.render.filepath = r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/check_front3.png'
bpy.ops.render.render(write_still=True)

bpy.ops.wm.save_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')
print('ROTATED_180_AND_SAVED')
