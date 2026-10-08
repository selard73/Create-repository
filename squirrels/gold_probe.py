"""Gold-coloured faces near the glasses (texture sampled at face UV centre). Run: blender -b --python gold_probe.py -- <blend> <png>"""
import bpy, sys, traceback, bmesh
from collections import defaultdict
argv = sys.argv[sys.argv.index("--") + 1:]; BL, PNG = argv[0], argv[1]; LOG = BL + ".gold.txt"
try:
    bpy.ops.wm.open_mainfile(filepath=BL)
    sq = bpy.data.objects["Squirrel"]; me = sq.data
    img = bpy.data.images.load(PNG); W, H = img.size; px = list(img.pixels)
    def col(u, v):
        x = min(W - 1, max(0, int(u * W))); y = min(H - 1, max(0, int(v * H))); i = (y * W + x) * 4
        return px[i], px[i + 1], px[i + 2]
    uv = me.uv_layers.active.data
    gold = []
    for p in me.polygons:
        c = p.center
        if not (1.45 < c.z < 2.05 and c.y < -0.15): continue
        u = sum(uv[l].uv[0] for l in p.loop_indices) / p.loop_total; v = sum(uv[l].uv[1] for l in p.loop_indices) / p.loop_total
        r, g, b = col(u, v)
        if r > 0.35 and g > 0.25 and b < 0.6 * g and r > b * 1.6 and abs(r - g) < 0.35: gold.append(p)
    out = ["gold faces near the face: %d" % len(gold)]
    by = defaultdict(list)
    for p in gold: by[round(p.center.x * 20) / 20].append(p)
    for k in sorted(by):
        ps = by[k]; out.append("x~%+.2f n %3d  y %.2f..%.2f  z %.2f..%.2f" % (k, len(ps), min(p.center.y for p in ps), max(p.center.y for p in ps), min(p.center.z for p in ps), max(p.center.z for p in ps)))
    open(LOG, "w").write("\n".join(out) + "\n")
except Exception:
    open(LOG, "w").write(traceback.format_exc())
