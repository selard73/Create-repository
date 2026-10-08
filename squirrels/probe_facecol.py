"""Per-face colour probe: sample the texture at each face's UV centre (prepped squirrel) and bin the faces of a colour
class by 3D position, to tell a stray patch (shirt stripes on a cheek) from a real part (the beanie).
Run: blender --background --python probe_facecol.py -- <dir> <name> <texture.png> x0 x1 y0 y1 z0 z1"""
import bpy, sys, os
from collections import defaultdict
argv = sys.argv[sys.argv.index("--") + 1:]
D, N, TEX = argv[0], argv[1], argv[2]
x0, x1, y0, y1, z0, z1 = map(float, argv[3:9])
bpy.ops.wm.open_mainfile(filepath=os.path.join(D, N + ".blend"))
me = bpy.data.objects["Squirrel"].data
uv = me.uv_layers.active.data
img = bpy.data.images.load(TEX); W, H = img.size; px = img.pixels[:]
def col(u, v):
    i = (min(H - 1, max(0, int(v * H))) * W + min(W - 1, max(0, int(u * W)))) * 4
    return (255 * px[i], 255 * px[i + 1], 255 * px[i + 2])
def cls(c):
    r, g, b = c
    if b > r + 35 and b > g + 10: return "navy" if r + g + b < 150 else "blue"
    if r > 185 and g > 185 and b > 185: return "white"
    return "other"
bins = defaultdict(lambda: defaultdict(int))
for p in me.polygons:
    c = p.center
    if not (x0 <= c.x <= x1 and y0 <= c.y <= y1 and z0 <= c.z <= z1): continue
    L = list(p.loop_indices)
    u = sum(uv[l].uv[0] for l in L) / len(L); v = sum(uv[l].uv[1] for l in L) / len(L)
    k = (round(c.x / 0.1) * 0.1, round(c.y / 0.1) * 0.1, round(c.z / 0.1) * 0.1)
    bins[k][cls(col(u, v))] += 1
with open(os.path.join(D, "facecol_probe.txt"), "w") as f:
    for k in sorted(bins, key=lambda k: (k[2], k[0], k[1])):
        d = bins[k]
        if d["navy"] + d["blue"] + d["white"] == 0: continue
        f.write(f"x {k[0]:+.1f} y {k[1]:+.1f} z {k[2]:.1f}  " + " ".join(f"{n} {d[n]}" for n in ("navy", "blue", "white", "other")) + "\n")
    f.write("PROBE_DONE\n")
