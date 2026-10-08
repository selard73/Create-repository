import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')

arm = bpy.data.objects['SquirrelRig']
for b in arm.data.bones:
    print(f'{b.name}: head={b.head_local}, tail={b.tail_local}, roll={b.roll}')
