import bpy
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')
with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/obj_list.txt', 'w') as out:
    for o in bpy.data.objects:
        out.write(f'{o.name} ({o.type})\n')
