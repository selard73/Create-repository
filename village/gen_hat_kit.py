# gen_hat_kit.py - the WEARABLE hats for the Chapelier (Sep 27 2026): the seven styles in the shop window (patch_hats_v3.py -
# top hat, boater, cloche, sun hat, bowler, fedora, beret), with the same shapes, made smoother (32 sides) and upright, each
# its own pair of pieces - Hat_<style> (crown and brim) and Band_<style> (the ribbon, and the sun hat's flowers; the
# beret's stalk) - so the store can colour them freely (no texture; MeshPart.Color).
# Units: studs, for a head 1.2 wide. y = 0 is where the crown meets the brim; the hat sits on a head with that line a
# little below the head's top (build_hatshop.lua fits it to each head). Written pre-turned for Import 3D (x,y,z ->
# -x,y,-z) and each piece centred on its own bounding box; the centres go to hats/hat_kit.json for the builder.
import json
import math
import os
import random

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "hats")
os.makedirs(OUT, exist_ok=True)
N = 32


def ring(r, y, n=N):
    return [(r * math.cos(2 * math.pi * i / n), y, r * math.sin(2 * math.pi * i / n)) for i in range(n)]


class Group:
    def __init__(self, name):
        self.name, self.v, self.f = name, [], []

    def add(self, pts):
        base = len(self.v)
        self.v.extend(pts)
        return base

    def strip(self, a, b):
        """quads between two rings (same count), both sides so they can be seen from in and out"""
        ia, ib = self.add(a), self.add(b)
        n = len(a)
        for i in range(n):
            j = (i + 1) % n
            self.f.append((ia + i, ib + i, ib + j))
            self.f.append((ia + i, ib + j, ia + j))
            self.f.append((ia + i, ib + j, ib + i))            # the back faces
            self.f.append((ia + i, ia + j, ib + j))

    def tube(self, rings):
        for a, b in zip(rings, rings[1:]):
            self.strip(a, b)

    def cap(self, rng_pts, y, up=True):
        c = self.add([(0, y, 0)])
        ia = self.add(rng_pts)
        n = len(rng_pts)
        for i in range(n):
            j = (i + 1) % n
            self.f.append((c, ia + i, ia + j))
            self.f.append((c, ia + j, ia + i))

    def blob(self, centre, r, scale=(1, 1, 1), rnd=None, wob=0.0, rows=10, cols=24):
        cx, cy, cz = centre
        rows_pts = []
        for i in range(rows + 1):
            th = math.pi * i / rows
            row = []
            for k in range(cols):
                ph = 2 * math.pi * k / cols
                rr = r * (1 + (rnd.uniform(-wob, wob) if rnd and 0 < i < rows else 0))
                row.append((cx + rr * math.sin(th) * math.cos(ph) * scale[0], cy + rr * math.cos(th) * scale[1], cz + rr * math.sin(th) * math.sin(ph) * scale[2]))
            rows_pts.append(row)
        for a, b in zip(rows_pts, rows_pts[1:]):
            ia, ib = self.add(a), self.add(b)
            for k in range(cols):
                j = (k + 1) % cols
                self.f.append((ia + k, ib + k, ib + j))
                self.f.append((ia + k, ib + j, ia + j))
                self.f.append((ia + k, ib + j, ib + k))            # and the other side (whichever way is out)
                self.f.append((ia + k, ia + j, ib + j))


def hat(style, rnd):
    H, B = Group("Hat_" + style), Group("Band_" + style)
    y = 0.0

    def crown(rings):
        H.tube(rings)
        H.cap(rings[-1], rings[-1][0][1])

    def flat_brim(r, t=0.07, r_in=0.5):
        H.tube([ring(r_in, y), ring(r, y), ring(r, y + t), ring(r_in, y + t)])

    def cone_brim(r_in, r_out, drop, t=0.07):
        H.tube([ring(r_in, y), ring(r_out, y - drop), ring(r_out, y - drop + t), ring(r_in, y + t)])

    def band(r, y0, h=0.24):
        B.tube([ring(r, y0), ring(r, y0 + h)])

    if style == "top":
        cone_brim(0.72, 1.15, -0.1)
        crown([ring(0.7, y + 0.02), ring(0.66, y + 0.8), ring(0.74, y + 1.55)])
        band(0.72, y + 0.1)
    elif style == "boater":
        flat_brim(1.45, r_in=0.85)
        crown([ring(0.85, y + 0.05), ring(0.85, y + 0.62)])
        band(0.87, y + 0.1, 0.26)
    elif style == "cloche":
        cone_brim(0.8, 1.05, 0.22)
        crown([ring(0.8, y + 0.02), ring(0.82, y + 0.45), ring(0.66, y + 0.85), ring(0.3, y + 1.08)])
        band(0.83, y + 0.1, 0.22)
    elif style == "sun":
        cone_brim(0.85, 1.95, 0.3)
        crown([ring(0.85, y + 0.02), ring(0.8, y + 0.5), ring(0.5, y + 0.78)])
        band(0.87, y + 0.1, 0.24)
        B.blob((0.62, y + 0.24, 0.62), 0.2, rnd=rnd, wob=0.08)
        B.blob((0.86, y + 0.24, 0.3), 0.2, rnd=rnd, wob=0.08)
    elif style == "bowler":
        cone_brim(0.78, 1.12, -0.16)
        crown([ring(0.78, y + 0.02), ring(0.78, y + 0.4), ring(0.6, y + 0.78), ring(0.22, y + 0.95)])
        band(0.8, y + 0.1, 0.22)
    elif style == "fedora":
        cone_brim(0.82, 1.35, 0.08)
        crown([ring(0.82, y + 0.02), ring(0.78, y + 0.6), ring(0.7, y + 1.05), ring(0.5, y + 1.15)])
        band(0.84, y + 0.1, 0.26)
    else:  # beret: a soft flat blob with a little stalk
        H.blob((0, y + 0.24, 0), 1.0, scale=(1.0, 0.3, 1.0), rnd=rnd, wob=0.04)
        B.blob((0, y + 0.58, 0), 0.08, scale=(1.0, 2.2, 1.0))
    return H, B


STYLES = ["top", "boater", "cloche", "sun", "bowler", "fedora", "beret"]
rnd = random.Random(2709)
groups = []
for st in STYLES:
    groups.extend(hat(st, rnd))

data = {}
with open(os.path.join(OUT, "Hats.obj"), "w") as f:
    f.write("# wearable hats for 1001 Squirrels\n")
    vi = 1
    for g in groups:
        xs = [p[0] for p in g.v]; ys = [p[1] for p in g.v]; zs = [p[2] for p in g.v]
        c = ((max(xs) + min(xs)) / 2, (max(ys) + min(ys)) / 2, (max(zs) + min(zs)) / 2)
        size = (max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs))
        data[g.name] = {"centre": [round(v, 4) for v in c], "size": [round(v, 4) for v in size], "tris": len(g.f)}
        f.write("g %s\n" % g.name)
        for (x, y, z) in g.v:
            f.write("v %.4f %.4f %.4f\n" % (-(x - c[0]), y - c[1], -(z - c[2])))
        for (a, b, c3) in g.f:
            f.write("f %d %d %d\n" % (a + vi, b + vi, c3 + vi))
        vi += len(g.v)
with open(os.path.join(OUT, "hat_kit.json"), "w") as f:
    json.dump(data, f, indent=1)
for k, v in data.items():
    print(k, v)
