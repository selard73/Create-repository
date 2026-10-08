import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')

mesh = bpy.data.objects['Squirrel']
vgs = {vg.name: vg.index for vg in mesh.vertex_groups}

# Look at the spike behind the rolling pin in perfect_turn_test.png:
# It stays stationary while the head turns!
# That means those vertices are currently weighted to Chest!
# But visually they are long whiskers protruding behind the rolling pin!
# Where are they?
# Near X in [-0.90, -0.60], Y in [-0.50, -0.15], Z in [1.50, 1.85].
whiskers_behind_pin = []
for v in mesh.data.vertices:
    co = v.co
    if -0.90 <= co.x <= -0.60 and -0.55 <= co.y <= -0.15 and 1.50 <= co.z <= 1.85:
        w_chest = 0
        w_head = 0
        for g in v.groups:
            if g.group == vgs['Chest']: w_chest = g.weight
            if g.group == vgs['Head']: w_head = g.weight
        whiskers_behind_pin.append((v.index, co.x, co.y, co.z, w_chest, w_head))

with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/spike_info.txt', 'w') as out:
    for w in whiskers_behind_pin:
        out.write(f'idx {w[0]}: ({w[1]:.3f}, {w[2]:.3f}, {w[3]:.3f}) -> Chest={w[4]:.2f}, Head={w[5]:.2f}\n')
