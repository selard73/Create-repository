import bpy, bmesh
from mathutils import Vector

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = bpy.data.objects['Squirrel']
bm = bmesh.new()
bm.from_mesh(mesh.data)
bm.verts.ensure_lookup_table()

# Let\'s find all vertices with X < -0.65 and Z < 1.9.
# Let\'s fit the exact cylinder axis of the rolling pin!
pin_pts = [v.co for v in bm.verts if v.co.x < -0.60 and 0.5 < v.co.z < 1.9]
# Bottom end of pin:
bot_pts = [p for p in pin_pts if p.z < 0.8]
# Top end of pin:
top_pts = [p for p in pin_pts if p.z > 1.7]

bot_c = sum(bot_pts, Vector()) / len(bot_pts)
top_c = sum(top_pts, Vector()) / len(top_pts)

print(f'Pin bottom center: {bot_c}')
print(f'Pin top center: {top_c}')
axis = (top_c - bot_c).normalized()

# Maximum radius on pin:
radii = [(p - bot_c - axis * ((p - bot_c).dot(axis))).length for p in pin_pts]
print(f'Max radius: {max(radii):.3f}, 95th percentile: {sorted(radii)[int(len(radii)*0.95)]:.3f}')

with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/pin_fit.txt', 'w') as out:
    out.write(f'bot: {bot_c.x:.3f}, {bot_c.y:.3f}, {bot_c.z:.3f}\n')
    out.write(f'top: {top_c.x:.3f}, {top_c.y:.3f}, {top_c.z:.3f}\n')
    out.write(f'max radius: {max(radii):.3f}\n')
