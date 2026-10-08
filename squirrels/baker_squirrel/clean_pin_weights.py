import bpy, bmesh
from mathutils import Vector

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')

mesh = bpy.data.objects['Squirrel']
arm = bpy.data.objects['SquirrelRig']

# Let\'s reset ALL pose bone rotations to 0 (rest pose) before assigning/testing!
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='POSE')
for pb in arm.pose.bones:
    pb.rotation_euler = (0, 0, 0)
bpy.ops.object.mode_set(mode='OBJECT')

vgs = {vg.name: vg for vg in mesh.vertex_groups}

# Let\'s find all vertices belonging to the rolling pin:
# Pin is held in right hand.
# Its bottom handle is at Z=0.6..1.0, X < -0.65, Y in -0.4..0.1.
# Its barrel goes up to Z=1.85, X in -0.65..-1.09, Y in -0.55..-0.05.
# Let\'s check the connection between pin and paw:
# The squirrel paw wraps around the pin at Z=1.0..1.2.
# Any vertex with Z >= 1.40 that belongs to the HEAD/FACE:
# Face is around X >= -0.45, Y in -0.75..0.15, Z in 1.45..2.40.
# Left cheek (viewer left, squirrel right) has whiskers reaching X = -0.60..-0.70 at Y < -0.30!
# Look at the whiskers in check_front3.png!
# Whiskers stick forward and sideways at Y < -0.35!
# Rolling pin is behind the whiskers, at Y in -0.35..-0.05!

pin_verts = set()
head_verts = set()

for v in mesh.data.vertices:
    co = v.co
    # Is it rolling pin?
    # Pin barrel / handle:
    # 1. Lower pin: Z < 1.35 and X < -0.55 and Y < 0.10
    # 2. Upper pin barrel: 1.35 <= Z <= 1.88 and X < -0.65 and Y >= -0.32
    if (co.z < 1.35 and co.x < -0.55 and co.y < 0.10) or        (1.35 <= co.z <= 1.88 and co.x < -0.65 and co.y >= -0.32):
        pin_verts.add(v.index)

print(f'Identified {len(pin_verts)} rolling pin vertices.')

# Re-assign weights:
# 1. Rolling pin -> 100% Chest
# 2. Everything else at Z >= 1.50 -> 100% Head
# 3. Whiskers & cheeks (Y < -0.30, Z >= 1.35, X < -0.40, not pin) -> 100% Head!

for v in mesh.data.vertices:
    co = v.co
    if v.index in pin_verts:
        # 100% Chest
        for name in ['Head', 'Neck', 'Tail1', 'Tail2', 'Root']:
            if name in vgs: vgs[name].remove([v.index])
        vgs['Chest'].add([v.index], 1.0, 'REPLACE')
    elif (co.z >= 1.50 and not (co.x > 0.25 and co.y > 0.05)) or          (1.35 <= co.z < 1.50 and co.y < -0.30 and co.x < -0.40):
        # 100% Head (including all whiskers, snout, cheeks, hat)
        for name in ['Chest', 'Neck', 'Tail1', 'Tail2', 'Root']:
            if name in vgs: vgs[name].remove([v.index])
        vgs['Head'].add([v.index], 1.0, 'REPLACE')

# Normalize
for v in mesh.data.vertices:
    tot = sum(g.weight for g in v.groups)
    if tot > 0:
        for g in v.groups:
            mesh.vertex_groups[g.group].add([v.index], g.weight / tot, 'REPLACE')

# Save blend
bpy.ops.wm.save_as_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')

# Render pose turn to visually prove the face stays 100% rigid and undisturbed!
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='POSE')
head = arm.pose.bones.get('Head')
head.rotation_mode = 'XYZ'
head.rotation_euler = (0, 0, 0.40) # 23 degrees head turn

tail = arm.pose.bones.get('Tail2')
tail.rotation_mode = 'XYZ'
tail.rotation_euler = (0.35, 0, 0.25) # vigorous tail wag

cam = bpy.data.objects.get('FrontCam')
if not cam:
    cam = bpy.data.objects.new('FrontCam', bpy.data.cameras.new('FrontCam'))
    bpy.context.scene.collection.objects.link(cam)
bpy.context.scene.camera = cam
cam.location = (0, -3.8, 1.3)
cam.rotation_euler = (1.5708, 0, 0)

bpy.context.scene.render.resolution_x = 800
bpy.context.scene.render.resolution_y = 800
bpy.context.scene.render.filepath = r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_turn_clean.png'
bpy.ops.render.render(write_still=True)
print('RENDERED_CLEAN_TURN')
