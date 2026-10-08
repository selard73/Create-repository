
import bpy, math
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

arm = [o for o in bpy.context.scene.objects if o.type == 'ARMATURE'][0]
head_bone = arm.pose.bones.get('Head')
if head_bone:
    # Rotate head bone 30 degrees around local Z to simulate turning
    head_bone.rotation_mode = 'XYZ'
    head_bone.rotation_euler = (0, 0, math.radians(30))

# Render front check
cam_data = bpy.data.cameras.new('FrontCam')
cam_obj = bpy.data.objects.new('FrontCam', cam_data)
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
bpy.context.scene.render.filepath = r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/test_turn.png'
bpy.ops.render.render(write_still=True)
