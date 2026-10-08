"""Classify every vertex of a rigged squirrel by the texture colour under its UV, and report each class's size,
bbox, centroid and mean Head/Neck, Chest, Root, Tail weights. Finds collars, muzzles, bags and cuffs exactly.
Run: blender --background --python probe_colors.py -- <out_dir> <name>"""
import bpy, sys, os, colorsys, traceback
from mathutils import Vector
argv = sys.argv[sys.argv.index("--") + 1:]
OUTD, NAME = argv[0], argv[1]
LOG = os.path.join(OUTD, "colors_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
try:
    open(LOG, "w").close()
    bpy.ops.wm.open_mainfile(filepath=os.path.join(OUTD, f"{NAME}_rigged.blend"))
    sq = bpy.data.objects["Squirrel"]; me = sq.data; gi = {g.index: g.name for g in sq.vertex_groups}
    img = bpy.data.images.load(os.path.join(OUTD, f"{NAME}_1k.png"))
    W, H = img.size; px = list(img.pixels)
    uvl = me.uv_layers.active.data
    acc = {}
    for loop in me.loops:
        u, v = uvl[loop.index].uv
        x = min(W - 1, max(0, int(u % 1.0 * W))); y = min(H - 1, max(0, int(v % 1.0 * H)))
        i = (y * W + x) * 4
        a = acc.setdefault(loop.vertex_index, [0.0, 0.0, 0.0, 0])
        a[0] += px[i]; a[1] += px[i + 1]; a[2] += px[i + 2]; a[3] += 1
    def cls(r, g, b):
        h, s, v = colorsys.rgb_to_hsv(r, g, b); h *= 360
        if s < 0.18: return "white" if v > 0.62 else ("gray" if v > 0.22 else "dark")
        if 35 <= h < 70 and s > 0.35: return "yellow"
        if 15 <= h < 45: return "brown"
        if 190 <= h < 260: return "blue"
        if h >= 300 or h < 15: return "pink/red"
        return f"other"
    groups = {}
    for vi, a in acc.items():
        c = cls(a[0] / a[3], a[1] / a[3], a[2] / a[3])
        co = me.vertices[vi].co
        if c == "white": c = "white-high(z>0.9)" if co.z > 0.9 else "white-low"
        groups.setdefault(c, []).append(vi)
    def w(vi, names): return sum(g.weight for g in me.vertices[vi].groups if gi[g.group] in names)
    for c, vs in sorted(groups.items(), key=lambda kv: -len(kv[1])):
        cs = [me.vertices[i].co for i in vs]
        lo = Vector((min(p.x for p in cs), min(p.y for p in cs), min(p.z for p in cs)))
        hi = Vector((max(p.x for p in cs), max(p.y for p in cs), max(p.z for p in cs)))
        cen = sum(cs, Vector()) / len(cs)
        n = len(vs)
        log(f"{c:18s} {n:5d}  x {lo.x:5.2f}..{hi.x:5.2f}  y {lo.y:5.2f}..{hi.y:5.2f}  z {lo.z:5.2f}..{hi.z:5.2f}  centre ({cen.x:5.2f},{cen.y:5.2f},{cen.z:5.2f})  "
            f"head {sum(w(i, ('Head', 'Neck')) for i in vs) / n:.2f} chest {sum(w(i, ('Chest',)) for i in vs) / n:.2f} root {sum(w(i, ('Root',)) for i in vs) / n:.2f} tail {sum(w(i, ('Tail1', 'Tail2')) for i in vs) / n:.2f}")
    # the collar: highest yellow vertices across the front half, in x bins
    ys = groups.get("yellow", [])
    if ys:
        log("yellow (coat) top edge by x bin, front half (y < -0.1):")
        for b in range(-7, 7):
            x0 = b * 0.1
            zs = [me.vertices[i].co.z for i in ys if x0 <= me.vertices[i].co.x < x0 + 0.1 and me.vertices[i].co.y < -0.1]
            if zs: log(f"   x {x0:5.2f}..{x0 + 0.1:5.2f}: coat top z {max(zs):.2f}")
    wh = groups.get("white-high(z>0.9)", [])
    if wh:
        log(f"muzzle/face white: lowest z {min(me.vertices[i].co.z for i in wh):.2f}")
    log("COLORS_DONE")
except Exception:
    log(traceback.format_exc())
