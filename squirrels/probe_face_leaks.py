"""After a colour fix: list vertices in a face box that no longer follow the head (Chest or Root weight above a
threshold), grouped by colour class with bbox and rgb, to find features wrongly moved off the head.
Run: blender --background --python probe_face_leaks.py -- <out_dir> <name> '<box json [x0,x1,y0,y1,z0,z1]>'"""
import bpy, sys, os, json, colorsys, traceback
from mathutils import Vector
argv = sys.argv[sys.argv.index("--") + 1:]
OUTD, NAME, BOX = argv[0], argv[1], json.loads(argv[2])
LOG = os.path.join(OUTD, "leaks_log.txt")


def log(m):
    with open(LOG, "a") as f:
        f.write(str(m) + "\n")


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
    b = BOX
    groups = {}
    for v in me.vertices:
        c = v.co
        if not (b[0] <= c.x <= b[1] and b[2] <= c.y <= b[3] and b[4] <= c.z <= b[5]):
            continue
        head = sum(g.weight for g in v.groups if gi[g.group] in ("Head", "Neck"))
        body = sum(g.weight for g in v.groups if gi[g.group] in ("Chest", "Root"))
        a = acc[v.index]
        r, g_, bl = a[0] / a[3], a[1] / a[3], a[2] / a[3]
        h, s, val = colorsys.rgb_to_hsv(r, g_, bl)
        key = "follows BODY" if body > 0.3 else "follows head"
        groups.setdefault(key, []).append((v.index, c.copy(), head, body, (r, g_, bl), (h * 360, s, val)))
    for key, items in groups.items():
        log(f"{key}: {len(items)} verts")
        if key == "follows BODY":
            items.sort(key=lambda t: -t[1].z)
            for vi, c, head, body, rgb, hsv in items[:40]:
                log(f"   v{vi:5d} ({c.x:5.2f},{c.y:5.2f},{c.z:5.2f}) head {head:.2f} body {body:.2f} rgb ({rgb[0]:.2f},{rgb[1]:.2f},{rgb[2]:.2f}) hsv ({hsv[0]:3.0f},{hsv[1]:.2f},{hsv[2]:.2f})")
    log("LEAKS_DONE")
except Exception:
    log(traceback.format_exc())
