"""Crown / back-of-head bleed audit for several rigged squirrels in one Blender run.
For each squirrel, looks at vertices above (neck start + 0.2) that do not belong to the tail, and reports
  MIXED: Head+Neck between 0.2 and 0.9 with Chest+Root >= 0.1  (head fur partly stuck to the body: squashes on turns)
  BODY:  Head+Neck below 0.2 with Chest+Root >= 0.5              (fully body-bound: fine for props, wrong for ears/crown)
summarised as 0.25-stud cells with the dominant colour class, so props and head parts can be told apart.
Run: blender --background --python probe_crown_all.py -- <squirrels root> <name1,name2,...>"""
import bpy, sys, os, json, colorsys, traceback
from collections import Counter
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
ROOT, NAMES = argv[0], argv[1].split(",")
LOG = os.path.join(ROOT, "crown_audit_log.txt")


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


open(LOG, "w").close()
for NAME in NAMES:
    try:
        D = os.path.join(ROOT, NAME)
        bpy.ops.wm.open_mainfile(filepath=os.path.join(D, f"{NAME}_rigged.blend"))
        sq = bpy.data.objects["Squirrel"]
        me = sq.data
        gi = {g.index: g.name for g in sq.vertex_groups}
        B = json.load(open(os.path.join(D, "bones.json")))
        neck_z = B["Neck"][1][2]
        hc = (Vector(B["Head"][0]) + Vector(B["Head"][1])) / 2
        img = bpy.data.images.load(os.path.join(D, f"{NAME}_1k.png"))
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

        def w(v, names):
            return sum(g.weight for g in v.groups if gi[g.group] in names)

        def colour(v):
            a = acc.get(v.index)
            return cls(a[0] / a[3], a[1] / a[3], a[2] / a[3], v.co.z) if a else "?"

        zf = neck_z + 0.2
        zone = [v for v in me.vertices if v.co.z >= zf and w(v, ("Tail1", "Tail2")) < 0.05]
        mixed = [v for v in zone if 0.2 <= w(v, ("Head", "Neck")) <= 0.9 and w(v, ("Chest", "Root")) >= 0.1]
        body = [v for v in zone if w(v, ("Head", "Neck")) < 0.2 and w(v, ("Chest", "Root")) >= 0.5]
        log(f"===== {NAME}: neck starts z {neck_z:.2f}, head centre ({hc.x:.2f},{hc.y:.2f},{hc.z:.2f}), zone z >= {zf:.2f}: "
            f"{len(zone)} verts | MIXED {len(mixed)} | BODY {len(body)}")
        for label, vs in (("MIXED", mixed), ("BODY", body)):
            if not vs:
                continue
            mh = sum(w(v, ("Head", "Neck")) for v in vs) / len(vs)
            mc = sum(w(v, ("Chest", "Root")) for v in vs) / len(vs)
            lo = Vector((min(v.co.x for v in vs), min(v.co.y for v in vs), min(v.co.z for v in vs)))
            hi = Vector((max(v.co.x for v in vs), max(v.co.y for v in vs), max(v.co.z for v in vs)))
            log(f"  {label}: mean head {mh:.2f} body {mc:.2f}, bbox x {lo.x:.2f}..{hi.x:.2f} y {lo.y:.2f}..{hi.y:.2f} z {lo.z:.2f}..{hi.z:.2f}")
            cells = {}
            for v in vs:
                k = (round(v.co.x / 0.25), round(v.co.y / 0.25), round(v.co.z / 0.25))
                cells.setdefault(k, []).append(v)
            for k, cvs in sorted(cells.items(), key=lambda kv: -len(kv[1]))[:10]:
                cc = Counter(colour(v) for v in cvs).most_common(2)
                ch = sum(w(v, ("Head", "Neck")) for v in cvs) / len(cvs)
                log(f"     cell ({k[0] * 0.25:5.2f},{k[1] * 0.25:5.2f},{k[2] * 0.25:5.2f}) n{len(cvs):3d} head {ch:.2f} colours {cc}")
    except Exception:
        log(f"===== {NAME}: ERROR\n" + traceback.format_exc())
log("CROWN_DONE")
