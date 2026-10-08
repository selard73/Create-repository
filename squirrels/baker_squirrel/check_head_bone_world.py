import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')

arm = bpy.data.objects['SquirrelRig']
with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/world_bones.txt', 'w') as out:
    for b in arm.data.bones:
        head_w = arm.matrix_world @ b.head_local
        tail_w = arm.matrix_world @ b.tail_local
        out.write(f'{b.name}: head={head_w}, tail={tail_w}\n')
