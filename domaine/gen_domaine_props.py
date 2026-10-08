"""
Domaine kit, batch 3: the props. Same conventions (studs, Y up, front -Z, stands on y = 0).
well, beehive, lavender_cart, barrel, barrel_rack, wine_press, crate_grapes, tasting_table, long_table, tractor,
trailer, hay_round, hay_stack, scarecrow, trough, stone_wall, stone_pillar, farm_gate, picket_fence, picket_gate,
sign_post, still, garden
Run:  python gen_domaine_props.py
"""
import math, random, sys
from pathlib import Path
HERE = Path(__file__).parent
sys.path.insert(0, str(HERE))
import gen_domaine as G
from gen_domaine import Kit, blob, cyl, beam, tube_out, ring_n, stem, disc, add, sub, mul, norm, cross, dot
import gen_forest as F
from gen_forest import ring, slab, tube
from gen_village import box, extrude, extrude_ring, arch_profile, rect_profile, thick_quad
from gen_domaine_buildings import tile_roof

OUT = HERE
F.GRAYS.update({
    "Hive": (0.94, 0.92, 0.86), "Wicker": (0.72, 0.58, 0.40), "Barrel": (0.55, 0.40, 0.28), "Copper": (0.80, 0.50, 0.30),
    "Brick": (0.65, 0.35, 0.28), "Bottle": (0.35, 0.50, 0.35), "Plate": (0.96, 0.95, 0.92), "Cheese": (0.94, 0.80, 0.40),
    "Body": (0.80, 0.18, 0.15), "Tread": (0.16, 0.16, 0.17), "Hub": (0.92, 0.72, 0.16), "Twine": (0.62, 0.52, 0.34),
    "Shirt": (0.75, 0.25, 0.20), "Patch": (0.30, 0.45, 0.70), "Pants": (0.30, 0.35, 0.50), "Straw": (0.90, 0.78, 0.40),
    "Sack": (0.80, 0.70, 0.50), "Hat": (0.85, 0.70, 0.40), "Crow": (0.10, 0.10, 0.12), "Picket": (0.95, 0.95, 0.92),
    "Sign": (0.85, 0.80, 0.70), "Lettuce": (0.55, 0.75, 0.35), "Tomato": (0.85, 0.20, 0.20), "Pumpkin": (0.92, 0.55, 0.15),
    "Gravel": (0.75, 0.70, 0.60), "Flower": (0.90, 0.45, 0.55), "Leaf": (0.45, 0.62, 0.30), "Crate": (0.70, 0.56, 0.40),
})


def annulus_tube(tris, center, axis, r_out, r_in, length, sides, phase=0.0):
    """A ring-shaped band (a hoop, a wheel rim): outer and inner tubes and two annular ends."""
    n = norm(axis); c0 = sub(center, mul(n, length / 2)); c1 = add(center, mul(n, length / 2))
    o0, o1 = ring_n(c0, n, r_out, sides, phase), ring_n(c1, n, r_out, sides, phase)
    i0, i1 = ring_n(c0, n, r_in, sides, phase), ring_n(c1, n, r_in, sides, phase)
    body = []
    for i in range(sides):
        j = (i + 1) % sides
        body += [(o0[i], o0[j], o1[j]), (o0[i], o1[j], o1[i])]          # outer
        body += [(i0[i], i1[j], i0[j]), (i0[i], i1[i], i1[j])]          # inner (reversed: faces toward the axis)
        body += [(o0[i], i0[j], o0[j]), (o0[i], i0[i], i0[j])]          # end at c0
        body += [(o1[i], o1[j], i1[j]), (o1[i], i1[j], i1[i])]          # end at c1
    # orient: outer faces away from the axis, inner toward it, ends along the axis
    for a, b, c in body:
        cen = mul(add(add(a, b), c), 1 / 3)
        k = dot(sub(cen, c0), n); foot = add(c0, mul(n, k))
        rad = sub(cen, foot); rr = math.sqrt(dot(rad, rad))
        if k < 0.02 * length: ref = mul(n, -1)
        elif k > 0.98 * length: ref = n
        elif rr < (r_out + r_in) / 2: ref = mul(rad, -1)
        else: ref = rad
        fn = cross(sub(b, a), sub(c, a))
        tris.append((a, c, b) if dot(fn, ref) < 0 else (a, b, c))


def wheel(k, center, r, width, spokes=8, rim="Wood", hub="Hub"):
    """A spoked cart wheel with its axle along x."""
    annulus_tube(k.t(rim), center, (1, 0, 0), r, r * 0.82, width, 14)
    cyl_c = sub(center, (width * 0.6, 0, 0))
    hr0 = ring_n(cyl_c, (1, 0, 0), r * 0.18, 8); hr1 = ring_n(add(cyl_c, (width * 1.2, 0, 0)), (1, 0, 0), r * 0.18, 8)
    tube_out(k.t(hub), [hr0, hr1], cyl_c, add(cyl_c, (width * 1.2, 0, 0)), True, True)
    for i in range(spokes):
        a = 2 * math.pi * i / spokes
        beam(k.t(rim), add(center, (0, r * 0.18 * math.cos(a), r * 0.18 * math.sin(a))), add(center, (0, r * 0.85 * math.cos(a), r * 0.85 * math.sin(a))), 0.14, 0.18)


def tyre(k, center, r, width, treads=16, suffix=""):
    """A tyre with tread blocks and a yellow hub. `suffix` (RL, RR, FL, FR) makes each wheel its own piece so it can spin."""
    annulus_tube(k.t("Tread" + suffix), center, (1, 0, 0), r, r * 0.55, width, 16)
    for i in range(treads):
        a = 2 * math.pi * i / treads
        c = add(center, (0, (r + 0.08) * math.cos(a), (r + 0.08) * math.sin(a)))
        beam(k.t("Tread" + suffix), sub(c, (width / 2, 0, 0)), add(c, (width / 2, 0, 0)), 0.5, 0.2, roll=a)
    hr0 = ring_n(sub(center, (width / 2 + 0.05, 0, 0)), (1, 0, 0), r * 0.5, 10); hr1 = ring_n(add(center, (width / 2 + 0.05, 0, 0)), (1, 0, 0), r * 0.5, 10)
    tube_out(k.t("Hub" + suffix), [hr0, hr1], sub(center, (width / 2 + 0.05, 0, 0)), add(center, (width / 2 + 0.05, 0, 0)), True, True)


# ------------------------------------------------------------- well ----
def well(name, seed):
    k = Kit(); rnd = random.Random(seed)
    annulus_tube(k.t("Stone"), (0, 1.1, 0), (0, 1, 0), 2.3, 1.75, 2.2, 12, phase=0.1)
    annulus_tube(k.t("Trim"), (0, 2.3, 0), (0, 1, 0), 2.5, 1.7, 0.25, 12, phase=0.1)
    disc(k.t("Water"), (0, 0.9, 0), (0, 1, 0), 1.72, 0.05, 12)
    for x in (-2.55, 2.55):
        box(None, "Wood", (x, 2.3, 0), 0.4, 4.6, 0.4, tris_out=k.t("Wood"))
    beam(k.t("Wood"), (-2.6, 4.75, 0), (2.6, 4.75, 0), 0.35, 0.35)
    # the winch drum with a crank
    hr0 = ring_n((-2.0, 4.3, 0), (1, 0, 0), 0.32, 8); hr1 = ring_n((2.0, 4.3, 0), (1, 0, 0), 0.32, 8)
    tube_out(k.t("Wood"), [hr0, hr1], (-2.0, 4.3, 0), (2.0, 4.3, 0), True, True)
    beam(k.t("Iron"), (2.55, 4.3, 0), (3.2, 4.3, 0), 0.1, 0.1); beam(k.t("Iron"), (3.2, 4.3, 0), (3.2, 3.5, 0), 0.1, 0.1)
    beam(k.t("Wood"), (3.2, 3.5, 0), (3.9, 3.5, 0), 0.22, 0.22)
    box(None, "Iron", (0, 3.3, 0), 0.06, 2.0, 0.06, tris_out=k.t("Iron"))                    # rope
    cyl(k.t("Wood"), (0, 1.75, 0), 0.42, 0.5, 0.65, 8)
    beam(k.t("Iron"), (-0.45, 2.4, 0), (0.45, 2.4, 0), 0.06, 0.06)
    tile_roof(k, -2.9, 2.9, -2.3, 2.3, 4.9, 1.5, ov=0.6, walls="Wood", thick=0.3)
    return k.write(name)


# ------------------------------------------------------------- beehive ----
def beehive(name, seed):
    k = Kit()
    for x in (-0.8, 0.8):
        for z in (-0.8, 0.8):
            box(None, "Wood", (x, 0.3, z), 0.3, 0.6, 0.3, tris_out=k.t("Wood"))
    for i in range(3):
        box(None, "Hive", (0, 0.6 + 0.45 + i * 0.95, 0), 2.2, 0.9, 2.2, tris_out=k.t("Hive"))
        box(None, "Dark", (0, 0.6 + 0.95 + i * 0.95, 0), 2.25, 0.05, 2.25, tris_out=k.t("Dark"))
    box(None, "Slate", (0, 3.6, 0), 2.6, 0.25, 2.6, tris_out=k.t("Slate"))
    box(None, "Slate", (0, 3.85, 0), 2.0, 0.25, 2.0, tris_out=k.t("Slate"))
    box(None, "Wood", (0, 0.75, -1.35), 1.6, 0.12, 0.6, tris_out=k.t("Wood"))
    box(None, "Dark", (0, 0.95, -1.12), 1.0, 0.18, 0.1, tris_out=k.t("Dark"))
    return k.write(name)


# ------------------------------------------------------------- lavender cart ----
def bundle(k, c, rnd, lay=(1, 0, 0)):
    """A tied bundle of lavender lying on its side."""
    blob(k.t("Lav"), add(c, mul(lay, 0.55)), 0.62, rnd, 0.14, (1.6, 0.7, 0.7) if lay[0] else (0.7, 0.7, 1.6))
    blob(k.t("Sage"), sub(c, mul(lay, 0.5)), 0.45, rnd, 0.12, (1.4, 0.6, 0.6) if lay[0] else (0.6, 0.6, 1.4))
    annulus_tube(k.t("Trim"), sub(c, mul(lay, 0.2)), lay, 0.4, 0.3, 0.25, 8)


def lavender_cart(name, seed):
    k = Kit(); rnd = random.Random(seed)
    for x in (-2.2, 2.2):
        wheel(k, (x, 2.0, 0.6), 2.0, 0.35)
    beam(k.t("Wood"), (-2.4, 2.0, 0.6), (2.4, 2.0, 0.6), 0.25, 0.25)                        # axle
    box(None, "Plank", (0, 2.5, 0), 4.0, 0.3, 4.6, tris_out=k.t("Plank"))                    # bed
    for x in (-1.9, 1.9):
        for z in (-2.1, 0, 2.1):
            box(None, "Wood", (x, 3.4, z), 0.2, 1.6, 0.2, tris_out=k.t("Wood"))
        for y in (3.1, 3.9):
            beam(k.t("Wood"), (x, y, -2.2), (x, y, 2.2), 0.12, 0.25)
    for sgn in (-1, 1):                                                                       # shafts down to the ground
        beam(k.t("Wood"), (sgn * 1.3, 2.4, -2.2), (sgn * 1.3, 0.6, -7.0), 0.25, 0.25)
    for c in ((-1.0, 3.2, -1.2), (0.2, 3.3, -0.2), (1.0, 3.1, 1.2), (-0.7, 3.2, 1.4), (0.0, 4.0, 0.5)):
        bundle(k, c, rnd, lay=(1, 0, 0) if c[1] < 3.9 else (0, 0, 1))
    return k.write(name)


# ------------------------------------------------------------- barrels and the cellar ----
def barrel_shape(k, base, up, h=2.4, r=1.0, sides=12, hoops=("Iron",)):
    up = norm(up)
    prof = ((0.0, 0.86), (0.25, 1.0), (0.5, 1.06), (0.75, 1.0), (1.0, 0.86))
    rings = [ring_n(add(base, mul(up, h * f)), up, r * s, sides) for f, s in prof]
    tube_out(k.t("Barrel"), rings, base, add(base, mul(up, h)), True, True)
    for f, s in ((0.14, 0.95), (0.5, 1.06), (0.86, 0.95)):
        annulus_tube(k.t("Iron"), add(base, mul(up, h * f)), up, r * s + 0.06, r * s - 0.02, 0.2, sides)


def barrel(name, seed):
    k = Kit()
    barrel_shape(k, (0, 0, 0), (0, 1, 0))
    return k.write(name)


def barrel_open(name, seed):
    """A standing barrel with no lid: hollow, dark inside, so a squirrel can stand in it and peek out."""
    k = Kit()
    prof = ((0.0, 0.86), (0.25, 1.0), (0.5, 1.06), (0.75, 1.0), (1.0, 0.86))
    h, r, sides = 2.4, 1.0, 12
    outer = [ring((0, 0, 0), r * s, h * f, sides) for f, s in prof]
    tube_out(k.t("Barrel"), outer, (0, 0, 0), (0, h, 0), True, False)
    inner = [ring((0, 0, 0), r * s - 0.12, h * f, sides) for f, s in prof]
    body = []
    tube(None, "", inner, (0, 0, 0), cap_bottom=False, cap_top=False, tris_out=body)
    for a, b, c in body:                                            # inner faces point toward the axis
        cen = mul(add(add(a, b), c), 1 / 3)
        fn = cross(sub(b, a), sub(c, a))
        k.t("Dark").append((a, c, b) if dot(fn, (-cen[0], 0, -cen[2])) < 0 else (a, b, c))
    top_o, top_i = outer[-1], inner[-1]
    for i in range(sides):                                          # the rim between the two walls
        j = (i + 1) % sides
        k.t("Barrel").extend([(top_o[i], top_i[j], top_o[j]), (top_o[i], top_i[i], top_i[j])])
    disc(k.t("Dark"), (0, 0.25, 0), (0, 1, 0), r * 0.86 - 0.12, 0.1, sides)
    for f, s in ((0.14, 0.95), (0.5, 1.06), (0.86, 0.95)):
        annulus_tube(k.t("Iron"), (0, h * f, 0), (0, 1, 0), r * s + 0.06, r * s - 0.02, 0.2, sides)
    return k.write(name)


def barrel_rack(name, seed):
    """Three barrels on their sides on a wooden rack (axis along x)."""
    k = Kit()
    for z in (-1.3, 1.3):
        beam(k.t("Wood"), (-4.2, 0.6, z), (4.2, 0.6, z), 0.35, 0.35)
        for x in (-3.9, 0, 3.9):
            box(None, "Wood", (x, 0.3, z), 0.35, 0.6, 0.35, tris_out=k.t("Wood"))
    for x in (-2.6, 0, 2.6):
        barrel_shape(k, (x - 1.2, 1.55, 0), (1, 0, 0), h=2.4, r=1.0)
    return k.write(name)


def wine_press(name, seed):
    k = Kit()
    box(None, "Stone", (0, 0.2, 0), 4.6, 0.4, 4.6, tris_out=k.t("Stone"))
    rings = [ring((0, 0.4, 0), r, y, 12) for r, y in ((1.6, 0.0), (1.7, 1.2), (1.6, 2.2))]
    tube_out(k.t("Barrel"), rings, (0, 0.4, 0), (0, 2.6, 0), True, True)
    for y in (0.7, 2.3):
        annulus_tube(k.t("Iron"), (0, y, 0), (0, 1, 0), 1.75, 1.6, 0.2, 12)
    for i in range(14):                                                                        # the cage of slats
        a = 2 * math.pi * i / 14
        box(None, "Wood", (1.45 * math.cos(a), 3.6, 1.45 * math.sin(a)), 0.5, 2.0, 0.2, tris_out=k.t("Wood"), yaw=-a)
    for y in (3.0, 4.4):
        annulus_tube(k.t("Iron"), (0, y, 0), (0, 1, 0), 1.6, 1.45, 0.15, 14)
    disc(k.t("Wood"), (0, 4.75, 0), (0, 1, 0), 1.35, 0.3, 12)
    cyl(k.t("Iron"), (0, 2.4, 0), 0.16, 0.16, 4.4, 8)
    beam(k.t("Wood"), (-2.0, 6.5, 0), (2.0, 6.5, 0), 0.3, 0.3)
    return k.write(name)


def crate_grapes(name, seed):
    k = Kit(); rnd = random.Random(seed)
    box(None, "Crate", (0, 0.5, 0), 2.6, 1.0, 1.8, tris_out=k.t("Crate"))
    for y in (0.3, 0.75):
        box(None, "Dark", (0, y, -0.91), 2.5, 0.08, 0.03, tris_out=k.t("Dark"))
        box(None, "Dark", (0, y, 0.91), 2.5, 0.08, 0.03, tris_out=k.t("Dark"))
        box(None, "Dark", (-1.31, y, 0), 0.03, 0.08, 1.7, tris_out=k.t("Dark"))
        box(None, "Dark", (1.31, y, 0), 0.03, 0.08, 1.7, tris_out=k.t("Dark"))
    for i in range(7):
        c = (rnd.uniform(-0.9, 0.9), 1.15 + rnd.uniform(0, 0.25), rnd.uniform(-0.5, 0.5))
        blob(k.t("Grape") if i % 3 else k.t("GrapeG"), c, rnd.uniform(0.3, 0.42), rnd, 0.25, (1.0, 0.8, 1.0))
    blob(k.t("VLeaf"), (0.9, 1.1, -0.5), 0.35, rnd, 0.2, (1.4, 0.4, 1.2))
    return k.write(name)


def glass_(k, c):
    cyl(k.t("Glass"), c, 0.3, 0.3, 0.06, 8)
    cyl(k.t("Glass"), add(c, (0, 0.06, 0)), 0.06, 0.06, 0.45, 6)
    rings = [ring(add(c, (0, 0.5, 0)), r, y, 8) for r, y in ((0.14, 0.0), (0.26, 0.3), (0.24, 0.65))]
    tube_out(k.t("Glass"), rings, add(c, (0, 0.5, 0)), add(c, (0, 1.15, 0)), True, False)


def bottle_(k, c, h=1.25):
    cyl(k.t("Bottle"), c, 0.24, 0.24, h * 0.62, 8)
    rings = [ring(add(c, (0, h * 0.62, 0)), r, y, 8) for r, y in ((0.24, 0.0), (0.11, h * 0.16), (0.11, h * 0.38))]
    tube_out(k.t("Bottle"), rings, add(c, (0, h * 0.62, 0)), add(c, (0, h, 0)), False, True)


def tasting_table(name, seed):
    k = Kit(); rnd = random.Random(seed)
    box(None, "Plank", (0, 2.75, 0), 6.0, 0.25, 2.6, tris_out=k.t("Plank"))
    for x in (-2.6, 2.6):
        for z in (-1.0, 1.0):
            box(None, "Wood", (x, 1.32, z), 0.3, 2.64, 0.3, tris_out=k.t("Wood"))
    bottle_(k, (-1.8, 2.88, 0.3)); bottle_(k, (-1.2, 2.88, -0.5), 1.1)
    for c in ((0.2, 2.88, 0.5), (1.0, 2.88, -0.4), (2.0, 2.88, 0.4)):
        glass_(k, c)
    disc(k.t("Wood"), (1.4, 2.95, -0.9), (0, 1, 0), 0.8, 0.1, 10)
    box(None, "Cheese", (1.4, 3.15, -0.9), 0.9, 0.3, 0.6, tris_out=k.t("Cheese"))
    return k.write(name)


def long_table(name, seed):
    """Courtyard table for a crowd: plank top on trestles, two benches, plates, glasses and bottles."""
    k = Kit(); rnd = random.Random(seed)
    L = 14.0
    box(None, "Plank", (0, 2.9, 0), L, 0.25, 3.6, tris_out=k.t("Plank"))
    for x in (-5.5, 0, 5.5):
        for z in (-1.4, 1.4):
            beam(k.t("Wood"), (x, 0.0, z * 1.15), (x, 2.75, z * 0.55), 0.3, 0.3)
        beam(k.t("Wood"), (x, 0.9, -1.6), (x, 0.9, 1.6), 0.25, 0.25)
    for z in (-3.0, 3.0):
        box(None, "Bench", (0, 1.65, z), L - 1.0, 0.22, 1.2, tris_out=k.t("Bench"))
        for x in (-5.5, 0, 5.5):
            box(None, "Wood", (x, 0.77, z), 0.3, 1.54, 0.9, tris_out=k.t("Wood"))
    for i in range(6):
        x = -5.0 + i * 2.0
        for z in (-1.1, 1.1):
            disc(k.t("Plate"), (x, 3.07, z), (0, 1, 0), 0.7, 0.08, 10)
            glass_(k, (x + 0.9, 3.03, z * 0.65))
    bottle_(k, (-2.0, 3.03, 0.0)); bottle_(k, (2.4, 3.03, 0.1)); bottle_(k, (0.3, 3.03, -0.15), 1.1)
    return k.write(name)


# ------------------------------------------------------------- tractor and trailer ----
def tractor(name, seed):
    k = Kit()
    B = k.t("Body")
    box(None, "Body", (0, 3.3, 0.8), 3.6, 2.2, 3.2, tris_out=B)                                # rear body
    box(None, "Body", (0, 3.5, -2.6), 2.6, 1.9, 4.0, tris_out=B)                               # hood
    box(None, "Dark", (0, 3.4, -4.62), 2.2, 1.5, 0.1, tris_out=k.t("Dark"))                    # grille
    box(None, "Iron", (0, 4.5, -4.7), 2.4, 0.15, 0.2, tris_out=k.t("Iron"))
    for x in (-1.0, 1.0):
        cyl(k.t("Glass"), (x, 3.6, -4.66), 0.3, 0.3, 0.0 + 0.12, 8) if False else None
        disc(k.t("Glass"), (x, 3.7, -4.7), (0, 0, -1), 0.32, 0.12, 8)                          # headlights
    cyl(k.t("Iron"), (1.0, 4.4, -1.6), 0.18, 0.18, 3.4, 8)                                     # exhaust
    box(None, "Dark", (0, 4.65, 1.3), 1.6, 0.5, 1.4, tris_out=k.t("Dark"))                     # seat
    box(None, "Dark", (0, 5.4, 2.0), 1.6, 1.2, 0.3, tris_out=k.t("Dark"))                      # seat back
    annulus_tube(k.t("Iron"), (0, 5.1, -0.4), norm((0, 0.6, -1)), 0.65, 0.5, 0.12, 12)         # steering wheel
    beam(k.t("Iron"), (0, 4.4, -0.2), (0, 5.05, -0.45), 0.12, 0.12)
    for x in (-1.7, 1.7):
        for z in (-0.6, 2.3):
            box(None, "Body", (x, 6.5, z), 0.22, 4.4, 0.22, tris_out=B)
    box(None, "Body", (0, 8.75, 0.85), 4.2, 0.2, 4.2, tris_out=B)                              # canopy
    box(None, "Body", (0, 2.2, -2.6), 2.8, 0.4, 4.2, tris_out=B)                               # chassis
    tyre(k, (-2.7, 2.5, 1.2), 2.5, 1.4, 16, "RL"); tyre(k, (2.7, 2.5, 1.2), 2.5, 1.4, 16, "RR")     # rear pair
    tyre(k, (-1.9, 1.3, -3.4), 1.3, 0.8, 12, "FL"); tyre(k, (1.9, 1.3, -3.4), 1.3, 0.8, 12, "FR")     # front pair (they steer)
    beam(k.t("Iron"), (-2.0, 1.3, -3.4), (2.0, 1.3, -3.4), 0.25, 0.25)
    box(None, "Iron", (0, 1.6, 3.0), 0.4, 0.4, 1.6, tris_out=k.t("Iron"))                      # hitch
    return k.write(name)


def trailer(name, seed):
    k = Kit(); rnd = random.Random(seed)
    box(None, "Plank", (0, 2.2, 0), 8.0, 0.3, 5.0, tris_out=k.t("Plank"))
    for x in (-3.8, 0, 3.8):
        for z in (-2.4, 2.4):
            box(None, "Wood", (x, 3.2, z), 0.25, 1.8, 0.25, tris_out=k.t("Wood"))
        for y in (2.8, 3.5, 4.1):
            pass
    for z in (-2.4, 2.4):
        for y in (2.8, 3.5, 4.05):
            beam(k.t("Wood"), (-4.0, y, z), (4.0, y, z), 0.12, 0.3)
    for x in (-3.8, 3.8):
        for y in (2.8, 3.5, 4.05):
            beam(k.t("Wood"), (x, y, -2.5), (x, y, 2.5), 0.3, 0.12)
    beam(k.t("Iron"), (-4.0, 1.9, 0), (4.0, 1.9, 0), 0.4, 0.3)
    for x in (-4.3, 4.3):
        tyre(k, (x, 1.6, 0.5), 1.6, 0.8, 14)
    beam(k.t("Iron"), (-4.4, 1.6, 0.5), (4.4, 1.6, 0.5), 0.25, 0.25)
    beam(k.t("Iron"), (0, 1.9, -2.2), (0, 1.9, -7.0), 0.35, 0.3)                        # tow bar, from under the bed to the hitch
    for sx in (-1.6, 1.6):                                                               # A-frame braces tie it to the bed
        beam(k.t("Iron"), (sx, 1.9, -1.9), (0, 1.9, -4.3), 0.2, 0.22)
    annulus_tube(k.t("Iron"), (0, 1.9, -7.2), (0, 1, 0), 0.5, 0.25, 0.25, 8)             # hitch eye
    for i in range(7):
        blob(k.t("Hay"), (rnd.uniform(-2.8, 2.8), 3.2 + rnd.uniform(0, 1.2), rnd.uniform(-1.5, 1.5)), rnd.uniform(1.1, 1.5), rnd, 0.2, (1.2, 0.8, 1.1))
    return k.write(name)


# ------------------------------------------------------------- hay ----
def hay_round(name, seed):
    k = Kit(); rnd = random.Random(seed)
    R, L = 2.4, 3.2
    rings = [ring_n((x, R, 0), (1, 0, 0), R, 14, 0.0) for x in (-L / 2, L / 2)]
    rings = [[(p[0], p[1] + rnd.uniform(-0.05, 0.05), p[2]) for p in r] for r in rings]
    tube_out(k.t("Hay"), rings, (-L / 2, R, 0), (L / 2, R, 0), True, True)
    for x in (-L / 4, L / 4):
        annulus_tube(k.t("Twine"), (x, R, 0), (1, 0, 0), R + 0.05, R - 0.1, 0.2, 14)
    return k.write(name)


def hay_stack(name, seed):
    """Three square bales, two below and one on top."""
    k = Kit()
    def bale(c, yaw=0.0):
        box(None, "Hay", c, 4.0, 2.2, 3.0, tris_out=k.t("Hay"), yaw=yaw)
        for dx in (-1.1, 1.1):
            box(None, "Twine", (c[0] + dx, c[1], c[2]), 0.2, 2.3, 3.1, tris_out=k.t("Twine"), yaw=yaw)
    bale((-2.1, 1.1, 0)); bale((2.1, 1.1, 0.2)); bale((0, 3.3, 0.1), 0.12)
    return k.write(name)


# ------------------------------------------------------------- scarecrow ----
def scarecrow(name, seed):
    k = Kit(); rnd = random.Random(seed)
    box(None, "Wood", (0, 3.4, 0), 0.32, 6.8, 0.32, tris_out=k.t("Wood"))
    beam(k.t("Wood"), (-2.4, 5.5, 0), (2.4, 5.5, 0), 0.26, 0.26)
    box(None, "Shirt", (0, 4.9, 0), 2.0, 2.6, 1.0, tris_out=k.t("Shirt"))
    box(None, "Patch", (0.5, 4.5, -0.53), 0.55, 0.55, 0.06, tris_out=k.t("Patch"))
    box(None, "Patch", (-0.6, 5.3, -0.53), 0.45, 0.45, 0.06, tris_out=k.t("Patch"))
    for sgn in (-1, 1):
        beam(k.t("Shirt"), (sgn * 1.0, 5.5, 0), (sgn * 2.3, 5.4, 0), 0.75, 0.75)
        for i in range(6):
            a = rnd.uniform(-0.5, 0.5); b = rnd.uniform(-0.5, 0.5)
            beam(k.t("Straw"), (sgn * 2.3, 5.4, 0), (sgn * 3.1, 5.4 + a, b), 0.08, 0.08)
    box(None, "Pants", (0, 2.9, 0), 1.6, 1.6, 0.9, tris_out=k.t("Pants"))
    for sgn in (-1, 1):
        for i in range(5):
            beam(k.t("Straw"), (sgn * 0.45, 2.1, 0), (sgn * 0.45 + rnd.uniform(-0.4, 0.4), 1.3, rnd.uniform(-0.4, 0.4)), 0.08, 0.08)
    for i in range(8):
        beam(k.t("Straw"), (0, 6.2, 0), (rnd.uniform(-0.7, 0.7), 6.3 + rnd.uniform(-0.2, 0.3), rnd.uniform(-0.7, 0.7)), 0.08, 0.08)
    blob(k.t("Sack"), (0, 7.0, 0), 0.8, rnd, 0.06, (1.0, 1.1, 1.0))
    for sgn in (-1, 1):
        box(None, "Dark", (sgn * 0.3, 7.15, -0.72), 0.2, 0.2, 0.12, tris_out=k.t("Dark"))
    box(None, "Dark", (0, 6.75, -0.74), 0.6, 0.12, 0.1, tris_out=k.t("Dark"))
    disc(k.t("Hat"), (0, 7.75, 0), (0, 1, 0), 1.45, 0.1, 12)
    cyl(k.t("Hat"), (0, 7.8, 0), 0.95, 0.35, 0.95, 10)
    # the crow on the left arm
    blob(k.t("Crow"), (-2.1, 6.1, 0), 0.4, rnd, 0.08, (0.9, 0.9, 1.35))
    blob(k.t("Crow"), (-2.1, 6.55, -0.4), 0.24, rnd, 0.05)
    stem(k.t("Beak"), (-2.1, 6.5, -0.6), (-2.1, 6.45, -0.9), 0.07, 0.02, 4)
    return k.write(name)


# ------------------------------------------------------------- trough ----
def trough(name, seed):
    k = Kit()
    W, H, D, t = 6.0, 2.0, 2.4, 0.35
    box(None, "Stone", (0, 0.2, 0), W, 0.4, D, tris_out=k.t("Stone"))
    for sgn in (-1, 1):
        box(None, "Stone", (sgn * (W / 2 - t / 2), H / 2, 0), t, H, D, tris_out=k.t("Stone"))
        box(None, "Stone", (0, H / 2, sgn * (D / 2 - t / 2)), W - 2 * t, H, t, tris_out=k.t("Stone"))
    box(None, "Water", (0, 1.55, 0), W - 2 * t - 0.02, 0.1, D - 2 * t - 0.02, tris_out=k.t("Water"))
    # the pump: post, spout over the trough, and a separate 'Handle' piece (hinged at the post) the game can work
    cyl(k.t("Iron"), (W / 2 + 0.6, 0, 0), 0.22, 0.22, 3.4, 8)
    beam(k.t("Iron"), (W / 2 + 0.6, 3.1, 0), (W / 2 - 0.4, 3.1, 0), 0.2, 0.2)
    beam(k.t("Iron"), (W / 2 - 0.4, 3.1, 0), (W / 2 - 0.4, 2.7, 0), 0.2, 0.2)
    beam(k.t("Handle"), (W / 2 + 0.6, 3.3, 0.1), (W / 2 + 1.9, 4.3, 0.1), 0.12, 0.12)
    cyl(k.t("Handle"), (W / 2 + 1.9, 4.1, 0.1), 0.12, 0.12, 0.5, 6)
    return k.write(name)


# ------------------------------------------------------------- walls, gates, fences, sign ----
def stone_wall(name, seed, L=12.0, H=2.2, T=1.2):
    """Dry-stone wall: three staggered courses of irregular stones and a course of flat cap stones."""
    k = Kit(); rnd = random.Random(seed)
    st = k.t("Stone")
    box(None, "Stone", (0, H / 2 - 0.05, 0), L - 0.3, H - 0.1, T * 0.8, tris_out=st)       # solid core: no daylight between stones
    st2 = k.t("StoneB")                                                                  # every other stone a second tone
    courses = 4
    ch = (H - 0.3) / courses                                                             # four finer courses of stone
    n = 0
    for c in range(courses):
        y0 = c * ch
        x = -L / 2 + (0.45 if c % 2 else 0.0)
        while x < L / 2 - 0.3:
            w = rnd.uniform(0.8, 1.5)
            if x + w > L / 2: w = L / 2 - x
            tris, _ = slab((x + w / 2, y0, 0), w / 2, ch, 6, rnd, taper=0.9, sx=1.0, sz=T / w)
            (st if (n + rnd.randint(0, 1)) % 3 else st2).extend(tris)
            n += 1
            x += w - 0.1
    x = -L / 2
    while x < L / 2 - 0.3:
        w = rnd.uniform(0.7, 1.1)
        if x + w > L / 2: w = L / 2 - x
        tris, _ = slab((x + w / 2, H - 0.3, 0), w / 2, 0.3, 6, rnd, taper=0.95, sx=1.0, sz=(T + 0.2) / w)
        st += tris
        x += w + 0.03
    return k.write(name)


def stone_pillar(name, seed):
    k = Kit()
    box(None, "Stone", (0, 1.7, 0), 1.5, 3.4, 1.5, tris_out=k.t("Stone"))
    box(None, "Quoin", (0, 3.55, 0), 1.8, 0.3, 1.8, tris_out=k.t("Quoin"))
    cyl(k.t("Quoin"), (0, 3.7, 0), 0.9, 0.15, 0.7, 4, phase=math.pi / 4)
    return k.write(name)


def farm_gate(name, seed, W=6.0, H=3.2):
    k = Kit()
    for x in (-W / 2, W / 2):
        box(None, "Wood", (x, H / 2, 0), 0.3, H, 0.3, tris_out=k.t("Wood"))
    for i in range(5):
        y = 0.35 + i * (H - 0.7) / 4
        beam(k.t("Wood"), (-W / 2, y, 0), (W / 2, y, 0), 0.15, 0.3)
    beam(k.t("Wood"), (-W / 2 + 0.2, 0.4, 0.2), (W / 2 - 0.2, H - 0.4, 0.2), 0.15, 0.3)
    for y in (0.6, H - 0.6):
        box(None, "Iron", (-W / 2, y, 0), 0.5, 0.2, 0.5, tris_out=k.t("Iron"))
    return k.write(name)


def picket_fence(name, seed, L=8.0, gate=False):
    k = Kit()
    pk = k.t("Picket")
    prof = [(-0.25, 0.0), (0.25, 0.0), (0.25, 2.3), (0.0, 2.72), (-0.25, 2.3)]
    n = int(L / 0.8)
    for i in range(n):
        x = -L / 2 + 0.4 + i * (L - 0.8) / (n - 1)
        pts = [(x + u, v + 0.15) for u, v in prof]
        extrude(None, "Picket", pts, "z", -0.08, 0.08, tris_out=pk)
    for y in (0.8, 2.0):
        beam(pk, (-L / 2, y, 0.2), (L / 2, y, 0.2), 0.12, 0.35)
    for x in (-L / 2 - 0.05, L / 2 + 0.05):
        box(None, "Picket", (x, 1.45, 0.25), 0.4, 2.9, 0.4, tris_out=pk)
        cyl(pk, (x, 2.9, 0.25), 0.28, 0.02, 0.35, 4, phase=math.pi / 4)
    if gate:
        beam(pk, (-L / 2 + 0.3, 0.5, 0.3), (L / 2 - 0.3, 2.3, 0.3), 0.12, 0.3)
        for y in (0.7, 2.1):
            box(None, "Iron", (-L / 2 + 0.05, y, 0.3), 0.5, 0.18, 0.35, tris_out=k.t("Iron"))
    return k.write(name)


def sign_post(name, seed):
    k = Kit()
    box(None, "Wood", (0, 3.2, 0), 0.35, 6.4, 0.35, tris_out=k.t("Wood"))
    arrow = [(-2.4, -0.6), (1.6, -0.6), (2.4, 0.0), (1.6, 0.6), (-2.4, 0.6)]
    extrude(None, "Sign", [(u + 0.6, v + 5.2) for u, v in arrow], "z", -0.32, -0.1, tris_out=k.t("Sign"))
    arrow2 = [(-1.6, -0.5), (1.9, -0.5), (1.9, 0.5), (-1.6, 0.5), (-2.3, 0.0)]
    extrude(None, "Sign", [(u - 0.5, v + 3.9) for u, v in arrow2], "z", -0.32, -0.1, tris_out=k.t("Sign"))
    return k.write(name)


# ------------------------------------------------------------- the still ----
def still(name, seed):
    k = Kit(); rnd = random.Random(seed)
    box(None, "Brick", (0, 1.0, 0), 2.6, 2.0, 2.6, tris_out=k.t("Brick"))
    box(None, "Dark", (0, 0.7, -1.31), 1.2, 0.9, 0.1, tris_out=k.t("Dark"))
    for y in (0.5, 1.0, 1.5):
        for face in (-1.31, 1.31):
            box(None, "Dark", (0, y, face), 2.55, 0.05, 0.03, tris_out=k.t("Dark"))
    rings = [ring((0, 2.0, 0), r, y, 12) for r, y in ((0.9, 0.0), (1.2, 0.7), (1.15, 1.5), (0.7, 2.2), (0.42, 2.6))]
    tube_out(k.t("Copper"), rings, (0, 2.0, 0), (0, 4.6, 0), True, True)
    blob(k.t("Copper"), (0, 4.95, 0), 0.62, rnd, 0.04)
    p = [(0, 5.4, 0), (0.4, 6.0, 0), (1.3, 6.1, 0), (2.2, 5.5, 0), (2.6, 4.4, 0)]
    for a, b in zip(p, p[1:]):
        stem(k.t("Copper"), a, b, 0.16, 0.16, 8)
    barrel_shape(k, (2.9, 0, 0), (0, 1, 0), h=2.6, r=0.85, sides=10)
    cyl(k.t("Copper"), (2.9, 2.6, 0), 0.7, 0.7, 0.15, 10)
    stem(k.t("Copper"), (2.9, 4.4, 0), (2.9, 2.75, 0), 0.16, 0.16, 8)
    stem(k.t("Copper"), (3.6, 0.9, 0), (4.3, 0.7, 0), 0.1, 0.1, 6)
    bottle_(k, (4.5, 0, 0), 1.2)
    return k.write(name)


# ------------------------------------------------------------- the garden ----
def garden(name, seed):
    """Four raised beds (lettuce, tomatoes on stakes, pumpkins, carrots) and two flower beds round a gravel path."""
    k = Kit(); rnd = random.Random(seed)
    box(None, "Gravel", (0, 0.06, 0), 18.0, 0.12, 14.0, tris_out=k.t("Gravel"))
    def bed(cx, cz, w, d):
        for sgn in (-1, 1):
            box(None, "Wood", (cx, 0.4, cz + sgn * (d / 2 - 0.15)), w, 0.8, 0.3, tris_out=k.t("Wood"))
            box(None, "Wood", (cx + sgn * (w / 2 - 0.15), 0.4, cz), 0.3, 0.8, d - 0.6, tris_out=k.t("Wood"))
        box(None, "Soil", (cx, 0.35, cz), w - 0.6, 0.7, d - 0.6, tris_out=k.t("Soil"))
    beds = [(-5.5, -4.0), (5.5, -4.0), (-5.5, 4.0), (5.5, 4.0)]
    for (cx, cz) in beds: bed(cx, cz, 6.0, 4.0)
    # lettuces
    for i in range(3):
        for j in range(2):
            blob(k.t("Lettuce"), (-7.3 + i * 1.8, 0.95, -4.8 + j * 1.6), 0.55, rnd, 0.16, (1.0, 0.65, 1.0))
    # tomatoes on stakes
    for i in range(4):
        x = 3.5 + i * 1.35
        box(None, "Wood", (x, 2.0, -4.0), 0.14, 3.6, 0.14, tris_out=k.t("Wood"))
        blob(k.t("Leaf"), (x, 1.9, -4.0), 0.62, rnd, 0.2, (1.0, 1.6, 1.0))
        for m in range(3):
            blob(k.t("Tomato"), (x + rnd.uniform(-0.45, 0.45), 1.3 + m * 0.65, -4.0 + rnd.uniform(-0.4, 0.4)), 0.22, rnd, 0.06)
    # pumpkins
    for (dx, dz, r) in ((-1.5, -0.6, 0.8), (0.4, 0.5, 0.7), (1.7, -0.7, 0.6)):
        blob(k.t("Pumpkin"), (-5.5 + dx, 0.75 + r * 0.6, 4.0 + dz), r, rnd, 0.08, (1.0, 0.72, 1.0))
        stem(k.t("Leaf"), (-5.5 + dx, 0.75 + r * 1.15, 4.0 + dz), (-5.5 + dx + 0.3, 0.75 + r * 1.15 + 0.35, 4.0 + dz), 0.08, 0.06, 4)
        blob(k.t("Leaf"), (-5.5 + dx + 0.9, 0.85, 4.0 + dz + 0.6), 0.4, rnd, 0.2, (1.4, 0.35, 1.2))
    # carrots: tufts
    for i in range(5):
        for j in range(2):
            x, z = 3.3 + i * 1.1, 3.2 + j * 1.6
            for m in range(4):
                beam(k.t("Leaf"), (x, 0.7, z), (x + rnd.uniform(-0.35, 0.35), 1.5 + rnd.uniform(0, 0.3), z + rnd.uniform(-0.35, 0.35)), 0.07, 0.07)
    # flower beds along the front edge, plus a watering can
    for x in (-3.0, 3.0):
        box(None, "Wood", (x, 0.3, -6.4), 4.0, 0.6, 1.6, tris_out=k.t("Wood"))
        box(None, "Soil", (x, 0.5, -6.4), 3.6, 0.3, 1.2, tris_out=k.t("Soil"))
        for i in range(5):
            fx = x - 1.5 + i * 0.75
            stem(k.t("Leaf"), (fx, 0.6, -6.4), (fx, 1.35, -6.4), 0.05, 0.04, 4)
            blob(k.t(f"Flower{i % 4 + 1}"), (fx, 1.45, -6.4 + rnd.uniform(-0.2, 0.2)), 0.28, rnd, 0.1)
        blob(k.t("Leaf"), (x, 0.85, -6.4), 0.9, rnd, 0.18, (1.9, 0.35, 0.7))
    cyl(k.t("Iron"), (0.4, 0.12, 0.2), 0.55, 0.5, 0.9, 8)
    stem(k.t("Iron"), (0.9, 0.5, 0.2), (1.7, 1.2, 0.2), 0.08, 0.06, 5)
    return k.write(name)


if __name__ == "__main__":
    counts = {}
    for fn, nm, sd in ((well, "well", 301), (beehive, "beehive", 302), (lavender_cart, "lavender_cart", 303), (barrel, "barrel", 304), (barrel_open, "barrel_open", 325),
                       (barrel_rack, "barrel_rack", 305), (wine_press, "wine_press", 306), (crate_grapes, "crate_grapes", 307),
                       (tasting_table, "tasting_table", 308), (long_table, "long_table", 309), (tractor, "tractor", 310),
                       (trailer, "trailer", 311), (hay_round, "hay_round", 312), (hay_stack, "hay_stack", 313),
                       (scarecrow, "scarecrow", 314), (trough, "trough", 315), (stone_wall, "stone_wall", 316),
                       (stone_pillar, "stone_pillar", 317), (farm_gate, "farm_gate", 318), (picket_fence, "picket_fence", 319),
                       (sign_post, "sign_post", 321), (still, "still", 322), (garden, "garden", 323)):
        counts[nm] = fn(nm, sd)
    counts["picket_gate"] = picket_fence("picket_gate", 320, L=4.0, gate=True)
    counts["stone_wall_b"] = stone_wall("stone_wall_b", 324)
    for k_, v in counts.items():
        print(f"{k_:14s} {v:6d} tris")
