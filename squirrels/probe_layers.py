"""For chosen colour classes, walk depth bins (y, 0.1 wide) and split each bin's vertices into height clusters
(gap > GAP in z). Prints each cluster's z range, x range, count and mean Head+Neck weight. Separates a coat collar
from a helmet brim of the same colour, or a chin from a collar.
Run: blender --background --python probe_layers.py -- <out_dir> <name> '<json {"classes": [...], "ymin":..,"ymax":..,"zmin":..,"zmax":.., "gap": 0.1}>'"""
import bpy, sys, os, json, colorsys, traceback
argv = sys.argv[sys.argv.index("--") + 1:]
OUTD, NAME, CFG = argv[0], argv[1], json.loads(argv[2])
LOG = os.path.join(OUTD, "layers_log.txt")


def log(m):
    with open(LOG, "a") as f:
        f.write(str(m) + "\n")


def cls(r, g, b, z):
    h, s, v = colorsys.rgb_to_hsv(r, g, b)
    h *= 360
    if s < 0.18:
        if v > 0.62:
            return "white-high" if z > 0.9 else "white-low"
        return "gray" if v > 0.22 else "dark"
    if 35 <= h < 70 and s > 0.35:
        return "yellow"
    if 15 <= h < 45:
        return "brown"
    if 190 <= h < 260:
        return "blue"
    if h >= 300 or h < 15:
        return "pink/red"
    return "other"


try:
    open(LOG, "w").close()
    bpy.ops.wm.open_mainfile(filepath=os.path.join(OUTD, f"{NAME}_rigged.blend"))
    sq = bpy.data.objects["Squirrel"]
    me = sq.data
    gi = {g.index: g.name for g in sq.vertex_groups}
    img = bpy.data.images.load(os.path.join(OUTD, f"{NAME}_1k.png"))
    W, H = img.size
    px = list(img.pixels)
    uvl = me.uv_layers.active.data
    acc = {}
    for loop in me.loops:
        u, v = uvl[loop.index].uv
        x = min(W - 1, max(0, int(u % 1.0 * W)))
        y = min(H - 1, max(0, int(v % 1.0 * H)))
        i = (y * W + x) * 4
        a = acc.setdefault(loop.vertex_index, [0.0, 0.0, 0.0, 0])
        a[0] += px[i]; a[1] += px[i + 1]; a[2] += px[i + 2]; a[3] += 1
    gap = CFG.get("gap", 0.1)
    for want in CFG["classes"]:
        log(f"== class {want}  (y {CFG['ymin']}..{CFG['ymax']}, z {CFG['zmin']}..{CFG['zmax']})")
        yb = CFG["ymin"]
        while yb < CFG["ymax"] - 1e-6:
            pts = []
            for v in me.vertices:
                c = v.co
                if not (yb <= c.y < yb + 0.1 and CFG["zmin"] <= c.z <= CFG["zmax"]):
                    continue
                a = acc.get(v.index)
                if not a or cls(a[0] / a[3], a[1] / a[3], a[2] / a[3], c.z) != want:
                    continue
                head = sum(g.weight for g in v.groups if gi[g.group] in ("Head", "Neck"))
                pts.append((c.z, c.x, head))
            if pts:
                pts.sort()
                clusters = [[pts[0]]]
                for p in pts[1:]:
                    if p[0] - clusters[-1][-1][0] > gap:
                        clusters.append([p])
                    else:
                        clusters[-1].append(p)
                desc = []
                for cl in clusters:
                    zs = [p[0] for p in cl]; xs = [p[1] for p in cl]; hw = sum(p[2] for p in cl) / len(cl)
                    desc.append(f"z {min(zs):.2f}..{max(zs):.2f} x {min(xs):.2f}..{max(xs):.2f} n{len(cl)} head {hw:.2f}")
                log(f"  y {yb:5.2f}..{yb + 0.1:5.2f}: " + "  |  ".join(desc))
            yb += 0.1
    log("LAYERS_DONE")
except Exception:
    log(traceback.format_exc())
