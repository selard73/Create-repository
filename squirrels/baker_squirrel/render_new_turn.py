import bpy, math
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')

arm = bpy.data.objects['SquirrelRig']
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='POSE')

head = arm.pose.bones.get('Head')
head.rotation_mode = 'XYZ'
head.rotation_euler = (0, 0, math.radians(25)) # turn head 25 degrees

tail = arm.pose.bones.get('Tail2')
tail.rotation_mode = 'XYZ'
tail.rotation_euler = (math.radians(20), 0, math.radians(15)) # wag tail

# Camera looking at face
cam_data = bpy.data.cameras.new('FrontCam')
cam_obj = bpy.data.objects.new('FrontCam', cam_data)
bpy.context.scene.collection.objects.link(cam_obj)
bpy.context.scene.camera = cam_obj
cam_obj.location = (0, -3.8, 1.3)
cam_obj.rotation_euler = (math.radians(90), 0, 0)

# Lights
sun = bpy.data.objects.new('Sun', bpy.data.lights.new('Sun', type='SUN'))
sun.data.energy = 4.0
sun.rotation_euler = (math.radians(45), math.radians(-30), 0)
bpy.context.scene.collection.objects.link(sun)

bpy.context.scene.render.resolution_x = 800
bpy.context.scene.render.resolution_y = 800
bpy.context.scene.render.filepath = r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/new_turn_verified.png'
bpy.ops.render.render(write_still=True)
print('RENDERED_NEW_TURN')
