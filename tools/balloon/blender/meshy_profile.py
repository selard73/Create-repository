# Blender: radius-vs-height profile of the Meshy balloon, to find the ropes dangling clear of the envelope.
import bpy, sys
import numpy as np
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=sys.argv[1])
o = [o for o in bpy.context.scene.objects if o.type == "MESH"][0]
n = len(o.data.vertices); co = np.empty(n * 3); o.data.vertices.foreach_get("co", co); co = co.reshape(-1, 3)
r = np.hypot(co[:, 0], co[:, 1]); z = co[:, 2]
edges = np.linspace(z.min(), z.max(), 41)
print("BIN   z0     z1    count   r50    r75    r90    r98    rmax  n(r>r90+.04)")
for i in range(40):
    m = (z >= edges[i]) & (z < edges[i + 1] + (1e-9 if i == 39 else 0))
    if m.sum() == 0: continue
    rr = r[m]; p = np.percentile(rr, [50, 75, 90, 98])
    print("%3d %6.3f %6.3f %8d %6.3f %6.3f %6.3f %6.3f %6.3f %8d" % (i, edges[i], edges[i + 1], m.sum(), p[0], p[1], p[2], p[3], rr.max(), (rr > p[2] + 0.04).sum()))
