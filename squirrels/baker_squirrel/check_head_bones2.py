import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')

arm = bpy.data.objects['SquirrelRig']
with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/bones_dump.txt', 'w') as out:
    for b in arm.data.bones:
        out.write(f'{b.name}: head={b.head}, tail={b.tail}\n')
