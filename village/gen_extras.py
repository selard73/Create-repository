"""Company for the village squirrels: a painter's easel (with a little painting of the lavender field on it) and two
pigeons (one standing, one pecking). Kit coordinates: y up, front -Z, y = 0 is the ground.
Run: python gen_extras.py  -> easel.obj, pigeon.obj, pigeon_b.obj"""
import math, random, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from gen_village import box, OUT
from gen_forest import Obj, ring, tube, icoblob, add, mul


def prism(o, name, p0, p1, r, tris_out=None):
    """A slim square prism between two points (a leg, a brush handle)."""
    r0 = ring((p0[0], 0, p0[2]), r, p0[1], 4, yaw=math.pi / 4)
    r1 = ring((p1[0], 0, p1[2]), r, p1[1], 4, yaw=math.pi / 4)
    return tube(o, name, [r0, r1], mul(add(p0, p1), 0.5), cap_bottom=True, cap_top=True, tris_out=tris_out)


def easel(name):
    o = Obj()
    wood = []
    prism(o, "Easel", (-0.95, 0.0, -0.25), (-0.10, 4.75, 0.05), 0.07, wood)      # front legs, splayed
    prism(o, "Easel", (0.95, 0.0, -0.25), (0.10, 4.75, 0.05), 0.07, wood)
    prism(o, "Easel", (0.0, 0.0, 1.05), (0.0, 4.60, 0.14), 0.07, wood)           # the back leg
    box(None, "Easel", (0, 4.70, 0.03), 0.55, 0.16, 0.18, tris_out=wood)          # top block joining the legs
    box(None, "Easel", (0, 1.85, -0.30), 2.05, 0.10, 0.24, tris_out=wood)         # ledge the canvas sits on
    box(None, "Easel", (0, 1.83, -0.44), 2.05, 0.16, 0.05, tris_out=wood)         # its front lip
    o.add_flat("Easel", wood, (0, 2.4, 0.2))
    box(o, "Canvas", (0, 3.02, -0.37), 2.3, 2.0, 0.08)                             # the canvas
    # the painting: a Provençal view, block by block (each its own piece for its own colour)
    z = -0.425
    box(o, "Paint1", (0.0, 3.55, z), 2.14, 0.84, 0.02)                             # sky
    box(o, "Paint2", (0.0, 2.72, z), 2.14, 0.84, 0.02)                             # green field
    box(o, "Paint7", (0.0, 2.36, z - 0.004), 2.14, 0.30, 0.02)                     # lavender rows along the bottom
    box(o, "Paint3", (-0.42, 2.92, z - 0.008), 0.78, 0.50, 0.02)                   # a farmhouse wall
    box(o, "Paint4", (-0.42, 3.24, z - 0.008), 0.92, 0.16, 0.02)                   # its terracotta roof
    box(o, "Paint6", (0.62, 3.0, z - 0.008), 0.34, 0.62, 0.02)                     # a cypress
    box(o, "Paint5", (0.80, 3.72, z - 0.008), 0.24, 0.24, 0.02)                    # the sun
    # brush pot on the ledge with two brushes
    pot = []
    r0 = ring((0.85, 0, -0.30), 0.10, 1.90, 8); r1 = ring((0.85, 0, -0.30), 0.10, 2.32, 8)
    tube(o, "Pot", [r0, r1], (0.85, 2.1, -0.30), cap_bottom=True, cap_top=True, tris_out=pot)
    o.add_flat("Pot", pot, (0.85, 2.1, -0.30))
    brush = []
    prism(o, "Brush", (0.80, 2.2, -0.30), (0.72, 2.95, -0.36), 0.025, brush)
    prism(o, "Brush", (0.90, 2.2, -0.28), (1.02, 2.90, -0.22), 0.025, brush)
    o.add_flat("Brush", brush, (0.85, 2.5, -0.3))
    return o.write(OUT / f"{name}.obj")


def pigeon(name, seed, pecking=False):
    rnd = random.Random(seed); o = Obj()
    body = []
    icoblob(o, "Pigeon", (0, 0.34, 0.02), 0.30, rnd, 0.05, (0.86, 0.78, 1.30), tris_out=body)
    if pecking:
        head = (0.0, 0.38, -0.44); beak0, beak1 = (0, 0.30, -0.56), (0, 0.24, -0.66)
        icoblob(o, "Pigeon", (0.0, 0.42, -0.30), 0.14, rnd, 0.04, (0.9, 0.9, 1.1), tris_out=body)   # stretched neck
    else:
        head = (0.0, 0.61, -0.30); beak0, beak1 = (0, 0.59, -0.46), (0, 0.57, -0.55)
    icoblob(o, "Pigeon", head, 0.15, rnd, 0.04, (0.9, 0.9, 1.0), tris_out=body)
    box(None, "Pigeon", (0, 0.40, 0.44), 0.28, 0.05, 0.34, tris_out=body)          # tail
    o.add_flat("Pigeon", body, (0, 0.35, 0))
    box(o, "Beak", mul(add(beak0, beak1), 0.5), 0.06, 0.05, abs(beak1[2] - beak0[2]) + 0.02)
    sheen = []
    icoblob(o, "Sheen", (0, 0.50 if not pecking else 0.42, -0.20 if not pecking else -0.22), 0.13, rnd, 0.03, (1.0, 0.7, 0.8), tris_out=sheen)
    o.add_flat("Sheen", sheen, (0, 0.5, -0.2))
    wing = []
    for sx in (-1, 1):
        box(None, "Wing", (sx * 0.23, 0.40, 0.06), 0.07, 0.17, 0.52, tris_out=wing)
    o.add_flat("Wing", wing, (0, 0.4, 0.06))
    legs = []
    for sx in (-1, 1):
        box(None, "Leg", (sx * 0.07, 0.10, 0.0), 0.035, 0.20, 0.035, tris_out=legs)
        box(None, "Leg", (sx * 0.07, 0.015, -0.04), 0.12, 0.03, 0.17, tris_out=legs)
    o.add_flat("Leg", legs, (0, 0.1, 0))
    return o.write(OUT / f"{name}.obj")


if __name__ == "__main__":
    print("easel", easel("easel"))
    print("pigeon", pigeon("pigeon", 11))
    print("pigeon_b", pigeon("pigeon_b", 12, pecking=True))
