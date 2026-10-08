
import bpy, math

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')

arm = [o for o in bpy.context.scene.objects if o.type == 'ARMATURE'][0]
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='POSE')

head_pbone = arm.pose.bones.get('Head')
if head_pbone:
    head_pbone.rotation_mode = 'XYZ'
    head_pbone.rotation_euler = (0, 0, math.radians(25)) # yaw turn

cam_data = bpy.data.cameras.new('TurnCam')
cam_obj = bpy.data.objects.new('TurnCam', cam_data)
bpy.context.scene.collection.objects.link(cam_obj)
bpy.context.scene.camera = cam_obj
cam_obj.location = (0, -3.8, 1.3)
cam_obj.rotation_euler = (math.radians(90), 0, 0)

# Add multiple lights
sun1 = bpy.data.objects.new('Sun1', bpy.data.lights.new('Sun1', type='SUN'))
sun1.data.energy = 3.0
sun1.rotation_euler = (math.radians(45), math.radians(-30), 0)
bpy.context.scene.collection.objects.link(sun1)

sun2 = bpy.data.objects.new('Sun2', bpy.data.lights.new('Sun2', type='SUN'))
sun2.data.energy = 2.0
sun2.rotation_euler = (math.radians(10), math.radians(30), 0)
bpy.context.scene.collection.objects.link(sun2)

bpy.context.scene.render.resolution_x = 800
bpy.context.scene.render.resolution_y = 800
bpy.context.scene.render.filepath = r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_turned_lit.png'
bpy.ops.render.render(write_still=True)
