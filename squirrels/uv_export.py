"""Export UV triangles of faces inside a box. Run: blender -b --python uv_export.py -- <blend> <out.json> x0 x1 y0 y1 z0 z1"""
import bpy, sys, json, traceback
argv = sys.argv[sys.argv.index("--") + 1:]; BL, OUT = argv[0], argv[1]; x0, x1, y0, y1, z0, z1 = map(float, argv[2:8])
try:
    bpy.ops.wm.open_mainfile(filepath=BL)
    me = bpy.data.objects["Squirrel"].data; uv = me.uv_layers.active.data
    tris = []
    for p in me.polygons:
        c = p.center
        if x0 < c.x < x1 and y0 < c.y < y1 and z0 < c.z < z1:
            tris.append([[uv[l].uv[0], uv[l].uv[1]] for l in p.loop_indices])
    json.dump(tris, open(OUT, "w"))
except Exception:
    open(OUT + ".err", "w").write(traceback.format_exc())
