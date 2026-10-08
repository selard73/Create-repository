"""Dump the UV triangles of the faces whose 3D centre lies in a box (prepped squirrel, faces -Y, up Z), so a texture
fix can be limited to exactly those texels (Oct 5 2026: shirt stripes painted onto the octopus catcher's cheek).
Run: blender --background --python face_uvtris.py -- <dir> <name> x0 x1 y0 y1 z0 z1 <out.json>"""
import bpy, sys, os, json
argv = sys.argv[sys.argv.index("--") + 1:]
D, N = argv[0], argv[1]
x0, x1, y0, y1, z0, z1 = map(float, argv[2:8])
OUT = argv[8]
bpy.ops.wm.open_mainfile(filepath=os.path.join(D, N + ".blend"))
me = bpy.data.objects["Squirrel"].data
uv = me.uv_layers.active.data
tris = []
for p in me.polygons:
    c = p.center
    if not (x0 <= c.x <= x1 and y0 <= c.y <= y1 and z0 <= c.z <= z1): continue
    L = list(p.loop_indices)
    for k in range(1, len(L) - 1):
        tris.append([list(uv[L[0]].uv), list(uv[L[k]].uv), list(uv[L[k + 1]].uv)])
json.dump(tris, open(OUT, "w"))
print("UVTRIS", len(tris))
