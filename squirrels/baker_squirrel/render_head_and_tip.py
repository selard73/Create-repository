import bpy, math

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

# Render views from:
# 1. Left side of squirrel (looking from -X towards +X)
# 2. Right side of squirrel (looking from +X towards -X)
# 3. Back view (looking from +Y towards -Y)

cam_data = bpy.data.cameras.new('SideCam')
cam_obj = bpy.data.objects.new('SideCam', cam_data)
bpy.context.scene.collection.objects.link(cam_obj)
bpy.context.scene.camera = cam_obj

# Sun light
sun = bpy.data.objects.new('Sun', bpy.data.lights.new('Sun', type='SUN'))
sun.data.energy = 4.0
bpy.context.scene.collection.objects.link(sun)

bpy.context.scene.render.resolution_x = 800
bpy.context.scene.render.resolution_y = 800

# View 1: Left side of squirrel (camera at -X=-3.5, Y=0, Z=1.3 looking at 0, 0, 1.3)
cam_obj.location = (-3.5, 0, 1.3)
cam_obj.rotation_euler = (math.radians(90), 0, math.radians(-90))
sun.rotation_euler = (math.radians(45), math.radians(-45), 0)
bpy.context.scene.render.filepath = r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/view_left_side.png'
bpy.ops.render.render(write_still=True)

# View 2: Back of squirrel (camera at X=0, Y=3.5, Z=1.3 looking at 0, 0, 1.3)
cam_obj.location = (0, 3.5, 1.3)
cam_obj.rotation_euler = (math.radians(90), 0, math.radians(180))
sun.rotation_euler = (math.radians(45), math.radians(45), 0)
bpy.context.scene.render.filepath = r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/view_back.png'
bpy.ops.render.render(write_still=True)

print('RENDERED_VIEWS')
