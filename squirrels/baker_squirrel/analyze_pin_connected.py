import bpy, bmesh
from mathutils import Vector

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = bpy.data.objects['Squirrel']
bm = bmesh.new()
bm.from_mesh(mesh.data)
bm.verts.ensure_lookup_table()

# Let\'s find all vertices belonging to the rolling pin:
# Pin is held in the squirrel\'s right hand.
# Is the rolling pin topologically connected to the body/hand, or is it a separate mesh island?
# Earlier we found the entire mesh was 1 island after decimation.
# BUT what if we start from the rolling pin handle (seed: X=-0.75, Y=-0.25, Z=0.9) and find the geometric boundary where it meets the paw?
# Let\'s find all vertices with X < -0.50 and check their distances from the pin centerline!
# What is the pin centerline?
# A line from handle bottom Vector((-0.75, -0.25, 0.70)) to pin top Vector((-0.75, -0.25, 1.85)).
# The pin is a cylinder of radius ~ 0.12 studs around this line!

p0 = Vector((-0.75, -0.25, 0.70))
p1 = Vector((-0.75, -0.25, 1.85))
axis = (p1 - p0).normalized()

pin_verts = []
for v in bm.verts:
    diff = v.co - p0
    proj = diff.dot(axis)
    if -0.1 <= proj <= (p1 - p0).length + 0.1:
        perp = (diff - axis * proj).length
        if perp <= 0.22: # cylinder radius ~ 0.22
            pin_verts.append((v.index, v.co, perp, proj))

print(f'Total pin cylinder verts: {len(pin_verts)}')
with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/pin_cylinder.txt', 'w') as out:
    out.write(f'Pin verts: {len(pin_verts)}\n')
    for p in pin_verts[:30]:
        out.write(f'idx {p[0]}: ({p[1].x:.3f}, {p[1].y:.3f}, {p[1].z:.3f}) dist={p[2]:.3f}, proj={p[3]:.3f}\n')
