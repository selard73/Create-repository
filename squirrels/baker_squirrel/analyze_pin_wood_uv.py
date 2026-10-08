import bpy, bmesh

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = bpy.data.objects['Squirrel']
bm = bmesh.new()
bm.from_mesh(mesh.data)
bm.faces.ensure_lookup_table()
uv_layer = bm.loops.layers.uv.active

# Let\'s check UV coordinates of the wooden rolling pin vs the squirrel whiskers:
# In Meshy texture maps:
# The rolling pin has distinct UV region from the squirrel head!
# Let\'s sample the UVs of known rolling pin handle vertices (Z < 1.0, X < -0.7):
pin_loops = []
for f in bm.faces:
    for l in f.loops:
        v = l.vert
        if v.co.x < -0.70 and v.co.z < 1.0:
            pin_loops.append(l[uv_layer].uv)

u_pin = [uv.x for uv in pin_loops]
v_pin = [uv.y for uv in pin_loops]
print(f'Rolling Pin UV bounds: U={min(u_pin):.3f}..{max(u_pin):.3f}, V={min(v_pin):.3f}..{max(v_pin):.3f}')

# Now what about the whisker spike vertices? (X in [-0.85, -0.65], Y < -0.40, Z in [1.60, 1.80]):
spike_loops = []
for f in bm.faces:
    for l in f.loops:
        v = l.vert
        if -0.85 <= v.co.x <= -0.65 and v.co.y < -0.40 and 1.60 <= v.co.z <= 1.80:
            spike_loops.append(l[uv_layer].uv)

u_spike = [uv.x for uv in spike_loops]
v_spike = [uv.y for uv in spike_loops]
print(f'Spike UV bounds: U={min(u_spike):.3f}..{max(u_spike):.3f}, V={min(v_spike):.3f}..{max(v_spike):.3f}')

with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/uv_compare.txt', 'w') as out:
    out.write(f'Pin UV: U={min(u_pin):.3f}..{max(u_pin):.3f}, V={min(v_pin):.3f}..{max(v_pin):.3f}\n')
    out.write(f'Spike UV: U={min(u_spike):.3f}..{max(u_spike):.3f}, V={min(v_spike):.3f}..{max(v_spike):.3f}\n')
