import bpy, math

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

cam_data = bpy.data.cameras.new('RightCam')
cam_obj = bpy.data.objects.new('RightCam', cam_data)
bpy.context.scene.collection.objects.link(cam_obj)
bpy.context.scene.camera = cam_obj

sun = bpy.data.objects.new('Sun', bpy.data.lights.new('Sun', type='SUN'))
sun.data.energy = 4.0
bpy.context.scene.collection.objects.link(sun)

bpy.context.scene.render.resolution_x = 800
bpy.context.scene.render.resolution_y = 800

# Squirrel\'s left side (viewer\'s right, which is +X!):
cam_obj.location = (3.5, 0, 1.3)
cam_obj.rotation_euler = (math.radians(90), 0, math.radians(90))
sun.rotation_euler = (math.radians(45), math.radians(45), 0)
bpy.context.scene.render.filepath = r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/view_squirrel_left_side.png'
bpy.ops.render.render(write_still=True)
print('RENDERED_SQUIRREL_LEFT')
