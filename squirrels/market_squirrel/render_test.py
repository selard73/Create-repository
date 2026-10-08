import bpy
import math

bpy.ops.wm.open_mainfile(filepath=rC:\Users\slard\roblox-props\squirrels\market_squirrel\market_squirrel_rigged.blend)

# Set up test camera & lights
cam = bpy.data.objects.get(Camera)
if not cam:
    cam_data = bpy.data.cameras.new(Camera)
    cam = bpy.data.objects.new(Camera, cam_data)
    bpy.context.scene.collection.objects.link(cam)
bpy.context.scene.camera = cam

cam.location = (1.8, -2.5, 1.8)
cam.rotation_euler = (math.radians(65), 0, math.radians(35))

# Render neutral
scene = bpy.context.scene
scene.render.resolution_x = 800
scene.render.resolution_y = 800
scene.render.filepath = rC:\Users\slard\roblox-props\squirrels\market_squirrel\test_neutral.png
bpy.ops.render.render(write_still=True)

# Pose test: turn head and wag tail
arm = bpy.data.objects.get(MarketRig)
if arm:
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode='POSE')
    
    # Head turn 25 deg
    head_bone = arm.pose.bones.get(Head)
    if head_bone:
        head_bone.rotation_mode = 'XYZ'
        head_bone.rotation_euler = (0, 0, math.radians(25))
        
    tail_bone = arm.pose.bones.get(Tail2)
    if tail_bone:
        tail_bone.rotation_mode = 'XYZ'
        tail_bone.rotation_euler = (0, 0, math.radians(20))
        
    scene.render.filepath = rC:\Users\slard\roblox-props\squirrels\market_squirrel\test_turned.png
    bpy.ops.render.render(write_still=True)
    print(TEST_RENDERS_DONE)
