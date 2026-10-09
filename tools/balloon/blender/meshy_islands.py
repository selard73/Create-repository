# Blender: list the loose parts of the Meshy balloon (to find the broken ropes). Run: python meshy_islands.py <fbx>
import bpy, bmesh, sys
import numpy as np
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=sys.argv[1])
o = [o for o in bpy.context.scene.objects if o.type == "MESH"][0]
bm = bmesh.new(); bm.from_mesh(o.data); bm.verts.ensure_lookup_table()
seen = np.zeros(len(bm.verts), bool); islands = []
for v in bm.verts:
    if seen[v.index]: continue
    stack = [v]; seen[v.index] = True; ids = []
    while stack:
        a = stack.pop(); ids.append(a.index)
        for e in a.link_edges:
            b = e.other_vert(a)
            if not seen[b.index]: seen[b.index] = True; stack.append(b)
    islands.append(ids)
co = np.array([v.co[:] for v in bm.verts])
print("ISLANDS", len(islands))
islands.sort(key=len, reverse=True)
for ids in islands[:40]:
    c = co[ids]; lo, hi = c.min(0), c.max(0)
    print("ISL verts %7d  min %s max %s size %s" % (len(ids), lo.round(3), hi.round(3), (hi - lo).round(3)))
