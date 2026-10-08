"""Export front-most faces in a box (final coords) of a prepped squirrel: UV triangle + 3D verts -> <dir>/front_faces.json.
Run: blender -b --python front_faces.py -- <dir> <name> <x0> <x1> <z0> <z1>"""
import bpy, sys, os, json, traceback
from mathutils import Vector
from mathutils.bvhtree import BVHTree
argv = sys.argv[sys.argv.index("--") + 1:]
D, NAME = argv[0], argv[1]; X0, X1, Z0, Z1 = map(float, argv[2:6])
LOG = os.path.join(D, "front_log.txt")
try:
    bpy.ops.wm.open_mainfile(filepath=os.path.join(D, f"{NAME}.blend"))
    sq = bpy.data.objects["Squirrel"]; me = sq.data; uvl = me.uv_layers.active.data
    bvh = BVHTree.FromObject(sq, bpy.context.evaluated_depsgraph_get())
    res = []
    for p in me.polygons:
        vs = [me.vertices[i].co for i in p.vertices]
        if not any(X0 <= v.x <= X1 and Z0 <= v.z <= Z1 for v in vs): continue
        # front-most if any of centre / vertex-pulled samples is the first hit from the front
        ok = False
        for w in (Vector((1/3, 1/3, 1/3)), Vector((0.6, 0.2, 0.2)), Vector((0.2, 0.6, 0.2)), Vector((0.2, 0.2, 0.6))):
            q = vs[0] * w[0] + vs[1] * w[1] + vs[2] * w[2]
            h = bvh.ray_cast(Vector((q.x, -5, q.z)), Vector((0, 1, 0)))
            if h[2] == p.index: ok = True; break
        if ok:
            res.append({"uv": [list(uvl[li].uv) for li in p.loop_indices], "v": [[v.x, v.y, v.z] for v in vs]})
    json.dump(res, open(os.path.join(D, "front_faces.json"), "w"))
    open(LOG, "w").write(f"front faces {len(res)}\nFRONT_DONE\n")
except Exception:
    open(LOG, "w").write(traceback.format_exc())
