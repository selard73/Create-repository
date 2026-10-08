import bpy, math

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')

arm_obj = bpy.data.objects['SquirrelRig']
bpy.context.view_layer.objects.active = arm_obj
bpy.ops.object.mode_set(mode='POSE')

# Apply full SquirrelAnim pose
arm_obj.pose.bones['Neck'].rotation_mode = 'XYZ'
arm_obj.pose.bones['Neck'].rotation_euler = (0, 0, math.radians(22 * 0.35))
arm_obj.pose.bones['Head'].rotation_mode = 'XYZ'
arm_obj.pose.bones['Head'].rotation_euler = (math.radians(1.5), math.radians(5), math.radians(22 * 0.65))
arm_obj.pose.bones['Tail1'].rotation_mode = 'XYZ'
arm_obj.pose.bones['Tail1'].rotation_euler = (math.radians(7), 0, math.radians(8))
arm_obj.pose.bones['Tail2'].rotation_mode = 'XYZ'
arm_obj.pose.bones['Tail2'].rotation_euler = (math.radians(15), 0, math.radians(12))

cam = bpy.data.objects.get('Cam')
if not cam:
    cam = bpy.data.objects.new('Cam', bpy.data.cameras.new('Cam'))
    bpy.context.scene.collection.objects.link(cam)
bpy.context.scene.camera = cam

# 1. Left side (pin side)
cam.location = (-3.5, 0, 1.4)
cam.rotation_euler = (1.5708, 0, -1.5708)
bpy.context.scene.render.filepath = r'C:/Users/slard/.gemini/antigravity/brain/4f96fdcb-94d3-476a-a289-803dced405eb/baker_pin_side_verify.png'
bpy.ops.render.render(write_still=True)

# 2. Right side (tail side)
cam.location = (3.5, 0, 1.4)
cam.rotation_euler = (1.5708, 0, 1.5708)
bpy.context.scene.render.filepath = r'C:/Users/slard/.gemini/antigravity/brain/4f96fdcb-94d3-476a-a289-803dced405eb/baker_tail_side_verify.png'
bpy.ops.render.render(write_still=True)

print("VERIFY_RENDERS_DONE")
