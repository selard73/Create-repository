
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

light_data = bpy.data.lights.new('Sun', type='SUN')
light_data.energy = 4.0
light_obj = bpy.data.objects.new('Sun', light_data)
bpy.context.scene.collection.objects.link(light_obj)
light_obj.rotation_euler = (math.radians(30), math.radians(-20), math.radians(10))

bpy.context.scene.render.resolution_x = 800
bpy.context.scene.render.resolution_y = 800
bpy.context.scene.render.filepath = r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_turned_head.png'
bpy.ops.render.render(write_still=True)
