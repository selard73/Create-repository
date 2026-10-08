"""
Cartoon flying saucer with alien pilot, tractor beam and landing pad. Roblox Import 3D mesh.
Same matte cartoon metal and blinking round lamps as the satellite dish.

Outputs: ufo.obj / ufo.mtl / ufo_texture.png / ufo_setup.lua / preview_ufo.html
Run:  python gen_ufo.py
Studio: Home > Import > ufo.obj (tick Anchored), select the model, paste ufo_setup.lua into the
command bar, Enter. Press Run to see the lamps blink, the saucer hover, and the beam lift things.
"""
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from gen_mesh import add, sub, mul, dot, cross, length, norm, lathe, blob, grain, paint_gradient
from gen_sign import Obj, tube, extrude_shape, box, rounded_rect
from gen_dish import revolve, rot_x, rot_y, rust, write_preview

OUT = Path(__file__).parent
TEX = 1024
random.seed(11)

UV = {
    "hull":   (0.00, 0.50, 0.50, 1.00),   # saucer skin, u = angle, v = bottom->top
    "pad":    (0.50, 1.00, 0.50, 1.00),   # landing pad top, u = angle, v = centre->edge
    "steel":  (0.00, 0.25, 0.25, 0.50),
    "dark":   (0.25, 0.50, 0.25, 0.50),
    "under":  (0.50, 0.75, 0.25, 0.50),   # saucer underside, darker metal
    "alien":  (0.75, 1.00, 0.25, 0.50),
    "pink":   (0.00, 0.10, 0.00, 0.10),
    "cyan":   (0.10, 0.20, 0.00, 0.10),
    "orange": (0.20, 0.30, 0.00, 0.10),
    "yellow": (0.30, 0.40, 0.00, 0.10),
    "green":  (0.40, 0.50, 0.00, 0.10),
    "lime":   (0.50, 0.60, 0.00, 0.10),
    "red":    (0.60, 0.70, 0.00, 0.10),
    "glass":  (0.70, 0.80, 0.00, 0.10),
    "black":  (0.80, 0.90, 0.00, 0.10),
    "white":  (0.90, 1.00, 0.00, 0.10),
    "blue":   (0.00, 0.10, 0.10, 0.20),
}

H = 17.0            # saucer centre height above the pad
HULL_R = 6.2
PAD_R = 6.9

def lamp(o, name, pos, col, axis="out", angle=0.0, size=1.0, tilt=0.0):
    """Round lamp in a dark bezel. axis: 'out' (horizontal, facing `angle`), 'up' or 'down'."""
    bez = revolve([(0.0, 0.0), (0.36 * size, 0.0), (0.36 * size, 0.1), (0.27 * size, 0.13)], 14, UV["dark"])
    dome = revolve([(0.0, 0.06), (0.25 * size, 0.06), (0.25 * size, 0.18), (0.17 * size, 0.3), (0.0, 0.36)], 14, UV[col])
    for nm, (v, uv, f) in ((f"Bezel_{name}", bez), (f"Neon{col.capitalize()}_{name}", dome)):
        if axis == "out":
            v = [add(rot_y(rot_x(p, math.pi / 2), angle), pos) for p in v]
        elif axis == "down":
            v = [add(rot_x(p, math.pi), pos) for p in v]
        elif axis == "slope":
            v = [add(rot_y(rot_x(p, tilt), angle), pos) for p in v]
        else:
            v = [add(p, pos) for p in v]
        o.add_smooth(nm, v, uv, f, lambda p, c=pos: c if axis != "out" else (0.0, c[1], 0.0))

def build_cockpit(o, floor_y):
    """Floor plate, pedestal seat with cushion and backrest, curved dashboard with buttons."""
    v, uv, f = revolve([(0.0, floor_y), (2.3, floor_y), (2.3, floor_y + 0.08), (0.0, floor_y + 0.08)], 40, UV["dark"])
    o.add_smooth("CockpitFloor", v, uv, f, lambda p: (0.0, floor_y - 1.0, 0.0))
    # seat: pedestal, cushion, backrest, headrest
    v, uv, f = revolve([(0.0, floor_y + 0.08), (0.22, floor_y + 0.08), (0.22, floor_y + 0.32), (0.0, floor_y + 0.32)], 12, UV["steel"])
    o.add_smooth("SeatPost", v, uv, f, lambda p: (0.0, floor_y + 0.2, 0.0))
    o.add_flat("SeatCushion", box(0.0, floor_y + 0.38, 0.0, 1.5, 0.14, 1.1, UV["dark"]), (0.0, floor_y + 0.2, 0.0))
    o.add_flat("SeatFrame", box(0.0, floor_y + 0.31, 0.0, 1.6, 0.06, 1.2, UV["steel"]), (0.0, floor_y + 0.2, 0.0))
    # high back with side wings, plus armrests, so the chair shows around the pilot
    back = box(0.0, 0.0, 0.0, 1.5, 0.95, 0.18, UV["dark"])
    bc = (0.0, floor_y + 0.85, -0.6)
    back = [tuple((add(rot_x(p, math.radians(-8)), bc), t) for p, t in tri) for tri in back]
    o.add_flat("SeatBack", back, (0.0, floor_y + 1.3, 0.0))
    trim = box(0.0, 0.0, 0.0, 1.7, 0.12, 0.26, UV["steel"])
    tc = (0.0, floor_y + 1.33, -0.68)
    trim = [tuple((add(rot_x(p, math.radians(-8)), tc), t) for p, t in tri) for tri in trim]
    o.add_flat("SeatBackTrim", trim, (0.0, floor_y + 2.0, 0.0))
    for i, side in enumerate((-1, 1)):
        wing = box(0.0, 0.0, 0.0, 0.2, 0.8, 0.5, UV["dark"])
        wc = (side * 0.75, floor_y + 0.85, -0.4)
        wing = [tuple((add(rot_x(p, math.radians(-8)), wc), t) for p, t in tri) for tri in wing]
        o.add_flat(f"SeatWing{i}", wing, (0.0, floor_y + 1.3, 0.0))
        o.add_flat(f"SeatArm{i}", box(side * 0.82, floor_y + 0.8, 0.12, 0.2, 0.12, 0.95, UV["steel"]), (0.0, floor_y + 0.6, 0.0))
        o.add_flat(f"SeatArmPost{i}", box(side * 0.82, floor_y + 0.58, 0.35, 0.12, 0.34, 0.12, UV["steel"]), (0.0, floor_y + 0.5, 0.0))
    # dashboard: three angled panels forming a curve in front of the seat
    for i, ang in enumerate((-32, 0, 32)):
        a = math.radians(ang)
        c = (1.15 * math.sin(a), floor_y + 0.62, 1.15 * math.cos(a))
        pnl = box(0.0, 0.0, 0.0, 0.85, 0.5, 0.4, UV["steel"])
        pnl = [tuple((add(rot_y(rot_x(p, math.radians(-15)), a), c), t) for p, t in tri) for tri in pnl]
        o.add_flat(f"Dash{i}", pnl, (0.0, floor_y + 0.5, 0.0))
        for k, col in enumerate(("red", "green", "blue")):
            bpos = add(rot_y(rot_x((-0.25 + 0.25 * k, 0.27, 0.0), math.radians(-15)), a), c)
            v, uv, f = blob(bpos, (0.07, 0.05, 0.07), 8, 4, UV[col])
            o.add_smooth(f"Neon{col.capitalize()}_Button{i}{k}", v, uv, f, lambda p, b=bpos: (b[0], b[1] - 0.2, b[2]))
    # a small lever
    v, uv, f = tube([(0.45, floor_y + 0.85, 0.75), (0.55, floor_y + 1.15, 0.6)], 0.035, 6, UV["steel"])
    o.add_smooth("DashLever", v, uv, f, lambda p: (0.45, floor_y + 0.9, 0.75))
    kb = (0.55, floor_y + 1.18, 0.59)
    v, uv, f = blob(kb, (0.07, 0.07, 0.07), 8, 4, UV["red"])
    o.add_smooth("LeverKnob", v, uv, f, lambda p: kb)

def build_alien(o, base, sc=1.0):
    """Cartoon grey-style alien in green: teardrop head, big almond eyes, smile, slim neck,
    egg body, arms with three-fingered hands, tucked legs. `base` = point under the body."""
    bx, by, bz = base
    def P(x, y, z):
        return (bx + x * sc, by + y * sc, bz + z * sc)
    def zsquash(verts, f=0.92):
        return [(v[0], v[1], bz + (v[2] - bz) * f) for v in verts]
    # head: revolve a teardrop, slightly squashed front-to-back
    head_c = P(0, 2.05, 0)
    prof = [(0.0, -0.85), (0.42, -0.8), (0.74, -0.52), (0.95, -0.1), (1.05, 0.35), (0.98, 0.75), (0.72, 1.02), (0.4, 1.16), (0.0, 1.2)]
    v, uv, f = revolve([(r * sc, head_c[1] + y * sc) for r, y in prof], 28, UV["alien"])
    v = zsquash([(x + bx, y, z + bz) for x, y, z in v])
    o.add_smooth("AlienHead", v, uv, f, lambda p: head_c)
    # eyes: big almonds tilted outward, wrapped onto the face
    for i, side in enumerate((-1, 1)):
        ang = side * math.radians(26)
        tilt = -side * math.radians(18)
        ec = (0.0, 0.08, 0.0)
        ev, euv, ef = blob((0.0, 0.0, 0.0), (0.4, 0.54, 0.13), 16, 8, UV["black"])
        ev = [rot_y(rot_z(p, tilt), ang) for p in ev]
        ev = [add(rot_y((0.0, 0.0, 0.95), ang), p) for p in ev]
        ev = [P(p[0], 2.13 + p[1], p[2]) for p in ev]
        cen = P(*add(rot_y((0.0, 0.0, 0.95), ang), (0.0, 2.13, 0.0)))
        o.add_smooth(f"AlienEye{i}", ev, euv, ef, lambda p, c=cen: c)
        hv, huv, hf = blob((0.0, 0.0, 0.0), (0.1, 0.13, 0.05), 8, 4, UV["white"])
        hv = [add(rot_y((side * -0.1, 0.16, 1.06), ang), p) for p in hv]
        hv = [P(p[0], 2.13 + p[1], p[2]) for p in hv]
        hc = P(*add(rot_y((side * -0.1, 0.16, 1.06), ang), (0.0, 2.13, 0.0)))
        o.add_smooth(f"AlienEyeShine{i}", hv, huv, hf, lambda p, c=hc: c)
    # smile: small arc on the chin area
    smile = [P(x, 1.55 - 0.12 * (1 - (x / 0.24) ** 2), 0.8 - (x / 0.24) ** 2 * 0.1) for x in (-0.24, -0.12, 0.0, 0.12, 0.24)]
    v, uv, f = tube(smile, 0.035 * sc, 6, UV["black"])
    o.add_smooth("AlienSmile", v, uv, f, lambda p: head_c)
    # neck and body
    v, uv, f = tube([P(0, 0.9, 0), P(0, 1.22, 0)], 0.2 * sc, 10, UV["alien"])
    o.add_smooth("AlienNeck", v, uv, f, lambda p: P(0, 1.0, 0))
    body_c = P(0, 0.5, 0)
    v, uv, f = blob(body_c, (0.56 * sc, 0.55 * sc, 0.5 * sc), 16, 8, UV["alien"])
    o.add_smooth("AlienBody", v, uv, f, lambda p: body_c)
    # arms reaching forward to the console, with three-fingered hands
    for i, side in enumerate((-1, 1)):
        arm = [P(side * 0.45, 0.72, 0.05), P(side * 0.72, 0.5, 0.35), P(side * 0.62, 0.42, 0.95)]
        v, uv, f = tube(arm, 0.12 * sc, 8, UV["alien"])
        o.add_smooth(f"AlienArm{i}", v, uv, f, lambda p: body_c)
        hand = P(side * 0.6, 0.42, 1.08)
        v, uv, f = blob(hand, (0.18 * sc, 0.11 * sc, 0.2 * sc), 10, 5, UV["alien"])
        o.add_smooth(f"AlienHand{i}", v, uv, f, lambda p, c=hand: c)
        for k, fx in enumerate((-0.09, 0.0, 0.09)):
            fg = [add(hand, (fx * sc, 0.0, 0.1 * sc)), add(hand, (fx * 1.6 * sc, -0.02 * sc, 0.3 * sc))]
            v, uv, f = tube(fg, 0.045 * sc, 6, UV["alien"])
            o.add_smooth(f"AlienFinger{i}{k}", v, uv, f, lambda p, c=hand: c)
    # tucked legs: thighs forward, small feet
    for i, side in enumerate((-1, 1)):
        leg = [P(side * 0.26, 0.18, 0.15), P(side * 0.34, 0.14, 0.62)]
        v, uv, f = tube(leg, 0.15 * sc, 8, UV["alien"])
        o.add_smooth(f"AlienLeg{i}", v, uv, f, lambda p: body_c)
        foot = P(side * 0.36, 0.08, 0.78)
        v, uv, f = blob(foot, (0.16 * sc, 0.1 * sc, 0.2 * sc), 8, 4, UV["alien"])
        o.add_smooth(f"AlienFoot{i}", v, uv, f, lambda p, c=foot: c)

def rot_z(p, a):
    c, s = math.cos(a), math.sin(a)
    return (p[0] * c - p[1] * s, p[0] * s + p[1] * c, p[2])

def build():
    o = Obj()

    # ------------------------------------------------------------ landing pad
    TOP = 1.7
    v, uv, f = revolve([(0.0, 0.0), (PAD_R + 0.7, 0.0), (PAD_R + 0.7, 0.5), (PAD_R + 0.15, 0.6), (PAD_R + 0.15, 1.35),
                        (PAD_R - 0.4, 1.5), (PAD_R - 0.4, TOP), (0.0, TOP)], 64, UV["pad"])
    o.add_smooth("PadBase", v, uv, f, lambda p: (0.0, -1.0, 0.0))
    ring = [((PAD_R - 0.35) * math.cos(2 * math.pi * i / 64), TOP + 0.03, (PAD_R - 0.35) * math.sin(2 * math.pi * i / 64)) for i in range(64)]
    v, uv, f = tube(ring, 0.16, 8, UV["dark"], closed=True)
    o.add_smooth("PadRimRing", v, uv, f, lambda p: (0.0, TOP, 0.0))
    for i in range(28):
        a = 2 * math.pi * i / 28
        c = ((PAD_R + 0.72) * math.cos(a), 0.28, (PAD_R + 0.72) * math.sin(a))
        v, uv, f = blob(c, (0.14, 0.14, 0.14), 8, 4, UV["steel"])
        o.add_smooth(f"PadRivet{i}", v, uv, f, lambda p, c=c: (0.0, c[1], 0.0))
    cols = ["red", "cyan", "green", "orange", "yellow"]
    # light strips around the upper tier's edge (they blink too)
    for i in range(16):
        a = 2 * math.pi * i / 16
        c = ((PAD_R + 0.2) * math.sin(a), 0.98, (PAD_R + 0.2) * math.cos(a))
        strip = box(0.0, 0.0, 0.0, 1.3, 0.4, 0.16, UV[cols[i % 5]])
        strip = [tuple((add(rot_y(p, a), c), t) for p, t in tri) for tri in strip]
        o.add_flat(f"Neon{cols[i % 5].capitalize()}_PadLamp{40 + i}", strip, (0.0, 0.98, 0.0))
    for i in range(12):
        a = 2 * math.pi * i / 12 + 0.13
        lamp(o, f"PadLamp{i}", ((PAD_R - 1.0) * math.cos(a), TOP, (PAD_R - 1.0) * math.sin(a)), cols[i % 5], axis="up", size=0.9)
    # green landing ring + inner disc where the beam lands
    ring = [(3.2 * math.cos(2 * math.pi * i / 48), TOP + 0.05, 3.2 * math.sin(2 * math.pi * i / 48)) for i in range(48)]
    v, uv, f = tube(ring, 0.17, 8, UV["green"], closed=True)
    o.add_smooth("NeonGreen_PadRing", v, uv, f, lambda p: (0.0, TOP, 0.0))
    v, uv, f = revolve([(0.0, TOP), (2.85, TOP), (2.85, TOP + 0.07), (0.0, TOP + 0.07)], 48, UV["lime"])
    o.add_smooth("NeonLime_PadDisc", v, uv, f, lambda p: (0.0, TOP - 0.5, 0.0))
    # four small consoles on the pad edge
    for i in range(4):
        a = 2 * math.pi * i / 4 + math.pi / 4
        c = ((PAD_R - 0.9) * math.sin(a), TOP + 0.35, (PAD_R - 0.9) * math.cos(a))
        b = box(0.0, 0.0, 0.0, 1.4, 0.7, 0.8, UV["dark"])
        b = [tuple((add(rot_y(p, a), c), t) for p, t in tri) for tri in b]
        o.add_flat(f"PadConsole{i}", b, (c[0], 0.5, c[2]))
        lamp(o, f"PadLamp{20 + i}", add(c, (0.0, 0.35, 0.0)), cols[(i + 1) % 5], axis="up", size=0.6)

    # ------------------------------------------------------------ saucer
    hull = [(0.0, -2.0), (1.8, -1.85), (3.6, -1.25), (5.2, -0.4), (HULL_R, 0.0), (HULL_R, 0.5), (5.6, 0.85),
            (4.4, 1.25), (3.2, 1.5), (2.4, 1.6), (0.0, 1.6)]
    v, uv, f = revolve([(r, y + H) for r, y in hull], 64, UV["hull"])
    o.add_smooth("UfoHull", v, uv, f, lambda p: (0.0, H, 0.0))
    band = [((HULL_R + 0.05) * math.cos(2 * math.pi * i / 64), H + 0.25, (HULL_R + 0.05) * math.sin(2 * math.pi * i / 64)) for i in range(64)]
    v, uv, f = tube(band, 0.2, 8, UV["steel"], closed=True)
    o.add_smooth("UfoRimBand", v, uv, f, lambda p: (0.0, H + 0.25, 0.0))
    for i in range(16):
        a = 2 * math.pi * i / 16
        c = ((HULL_R - 0.4) * math.cos(a), H + 0.85, (HULL_R - 0.4) * math.sin(a))
        v, uv, f = blob(c, (0.13, 0.13, 0.13), 8, 4, UV["dark"])
        o.add_smooth(f"UfoBolt{i}", v, uv, f, lambda p, c=c: (0.0, c[1], 0.0))
    # six big lamps on the top slope of the hull, tilted outward
    SL_R, SL_Y, SL_T = 4.05, H + 1.3, math.radians(34)
    for i in range(6):
        a = 2 * math.pi * i / 6
        lamp(o, f"UfoLamp{i}", (SL_R * math.sin(a), SL_Y, SL_R * math.cos(a)), cols[i % 5], axis="slope", angle=a, size=1.6, tilt=SL_T)
    # underside lamps facing down
    for i in range(4):
        a = 2 * math.pi * i / 4 + 0.4
        lamp(o, f"UfoLamp{20 + i}", (3.6 * math.cos(a), H - 1.25, 3.6 * math.sin(a)), cols[(i + 2) % 5], axis="down", size=1.2)
    # emitter disc on the belly
    v, uv, f = revolve([(0.0, H - 2.15), (1.6, H - 2.15), (1.6, H - 1.95), (0.0, H - 1.95)], 32, UV["green"])
    o.add_smooth("NeonGreen_Emitter", v, uv, f, lambda p: (0.0, H - 1.0, 0.0))
    # dome, dome ring, antenna
    dome = [(2.45 * math.cos(math.pi / 2 * i / 16), H + 1.58 + 3.1 * math.sin(math.pi / 2 * i / 16)) for i in range(17)]
    v, uv, f = revolve(dome, 40, UV["glass"])
    o.add_smooth("Dome", v, uv, f, lambda p: (0.0, H + 1.58, 0.0))
    dring = [(2.45 * math.cos(2 * math.pi * i / 40), H + 1.6, 2.45 * math.sin(2 * math.pi * i / 40)) for i in range(40)]
    v, uv, f = tube(dring, 0.14, 8, UV["steel"], closed=True)
    o.add_smooth("UfoDomeRing", v, uv, f, lambda p: (0.0, H + 1.6, 0.0))
    v, uv, f = tube([(0.0, H + 4.65, 0.0), (0.0, H + 5.4, 0.0)], 0.07, 6, UV["steel"])
    o.add_smooth("UfoAntenna", v, uv, f, lambda p: (0.0, H + 5.0, 0.0))
    tip = (0.0, H + 5.52, 0.0)
    v, uv, f = blob(tip, (0.18, 0.18, 0.18), 10, 5, UV["red"])
    o.add_smooth("NeonRed_UfoLamp30", v, uv, f, lambda p: tip)

    # alien pilot inside the dome, facing +Z
    build_cockpit(o, H + 1.6)
    build_alien(o, (0.0, H + 1.6 + 0.44, 0.05), 0.7)

    # tractor beam: translucent cone from the emitter down to the pad
    v, uv, f = revolve([(0.0, H - 0.9), (1.45, H - 0.9), (3.0, 1.8), (0.0, 1.8)], 40, UV["green"])
    o.add_smooth("Beam", v, uv, f, lambda p: (0.0, (H + 1.0) / 2, 0.0))
    return o

# ------------------------------------------------------------- texture ----
def rbox(r):
    u0, u1, v0, v1 = r
    return int(u0 * TEX), int((1 - v1) * TEX), int(u1 * TEX), int((1 - v0) * TEX)

def paint():
    atlas = Image.new("RGB", (TEX, TEX), (30, 30, 30))
    # hull: matte metal, radial seams, a darker band around the rim
    x0, y0, x1, y1 = rbox(UV["hull"]); w, h = x1 - x0, y1 - y0
    hull = rust(w, h, base=(148, 148, 156), seed=4, rust_amount=0.25); d = ImageDraw.Draw(hull)
    for k in range(16):
        x = int(w * k / 16); d.line([(x, 0), (x, h)], fill=(58, 58, 66, 235), width=5)
        d.line([(x + 5, 0), (x + 5, h)], fill=(205, 205, 214, 55), width=3)
    # v runs bottom->top of the profile; the rim is roughly 45-55% along it
    d.rectangle([0, int(h * 0.44), w, int(h * 0.54)], fill=(96, 96, 106, 255))
    atlas.paste(hull.convert("RGB"), (x0, y0))
    # pad: concentric rings, radial seams, a yellow/black hazard band near the edge
    x0, y0, x1, y1 = rbox(UV["pad"]); w, h = x1 - x0, y1 - y0
    pad = rust(w, h, base=(126, 126, 134), seed=8, rust_amount=0.4); d = ImageDraw.Draw(pad)
    for k in range(12):
        x = int(w * k / 12); d.line([(x, 0), (x, h)], fill=(58, 58, 66, 235), width=5)
    # v: 0 = centre of the pad (bottom of image) ... 1 = outer edge/side (top of image)
    for fy in (0.55, 0.72, 0.86):
        d.line([(0, int(h * (1 - fy))), (w, int(h * (1 - fy)))], fill=(58, 58, 66, 235), width=5)
    yb0, yb1 = int(h * (1 - 0.86)), int(h * (1 - 0.80))
    for k in range(24):
        x = int(w * k / 24); col = (232, 196, 60, 255) if k % 2 == 0 else (40, 40, 44, 255)
        d.polygon([(x, yb1), (x + w // 24, yb1), (x + w // 24 + 14, yb0), (x + 14, yb0)], fill=col)
    atlas.paste(pad.convert("RGB"), (x0, y0))
    x0, y0, x1, y1 = rbox(UV["steel"]); atlas.paste(grain(paint_gradient(x1 - x0, y1 - y0, (150, 152, 160), (104, 106, 114)), 0.06, 30), (x0, y0))
    x0, y0, x1, y1 = rbox(UV["dark"]); atlas.paste(grain(Image.new("RGB", (x1 - x0, y1 - y0), (44, 44, 50)), 0.06, 30), (x0, y0))
    x0, y0, x1, y1 = rbox(UV["under"]); atlas.paste(rust(x1 - x0, y1 - y0, base=(100, 100, 108), seed=6, rust_amount=0.5).convert("RGB"), (x0, y0))
    x0, y0, x1, y1 = rbox(UV["alien"]); atlas.paste(grain(paint_gradient(x1 - x0, y1 - y0, (92, 176, 62), (58, 130, 44)), 0.04, 30), (x0, y0))
    for key, col in (("pink", (255, 40, 160)), ("cyan", (0, 170, 255)), ("orange", (255, 120, 0)), ("yellow", (255, 215, 0)),
                     ("green", (30, 210, 60)), ("lime", (150, 255, 60)), ("red", (235, 30, 30)), ("blue", (40, 90, 255)),
                     ("glass", (150, 215, 235)), ("black", (20, 22, 26)), ("white", (250, 250, 250))):
        x0, y0, x1, y1 = rbox(UV[key]); atlas.paste(Image.new("RGB", (x1 - x0, y1 - y0), col), (x0, y0))
    return atlas

LUA = r'''-- UFO + landing pad: run in the Command Bar with the imported model SELECTED (or it finds "ufo" in Workspace).
-- Matte metal body, blinking round lamps that cast light, glass dome, glowing green beam that lifts things,
-- gentle hover + spin. Blinking, hovering and lifting only run while the game runs (press Run or Play).
local model = workspace:FindFirstChild("UFO") or workspace:FindFirstChild("ufo") or game.Selection:Get()[1]
assert(model and model:IsA("Model"), "Select the imported ufo model first")
local colors = { Pink = Color3.fromRGB(255, 40, 160), Cyan = Color3.fromRGB(0, 170, 255), Orange = Color3.fromRGB(255, 120, 0), Yellow = Color3.fromRGB(255, 215, 0), Green = Color3.fromRGB(30, 210, 60), Lime = Color3.fromRGB(150, 255, 60), Red = Color3.fromRGB(235, 30, 30), Blue = Color3.fromRGB(40, 90, 255) }
for _, p in ipairs(model:GetDescendants()) do
	if p:IsA("BasePart") then
		p.Anchored = true
		for _, c in ipairs(p:GetChildren()) do if c:IsA("Light") then c:Destroy() end end
		local tone = p.Name:match("^Neon(%a+)_")
		if tone and colors[tone] then
			p.Material = Enum.Material.Neon; p.Color = colors[tone]; p.TextureID = ""; p.CanCollide = false; p.CastShadow = false
			if p.Name:find("Lamp") then
				local l = Instance.new("PointLight"); l.Color = colors[tone]; l.Range = 3; l.Brightness = 0.5; l.Shadows = false; l.Parent = p
			end
		elseif p.Name == "Dome" then
			p.Material = Enum.Material.SmoothPlastic; p.Color = Color3.fromRGB(215, 238, 245); p.TextureID = ""; p.Transparency = 0.74; p.CanCollide = false; p.CastShadow = false; p.Reflectance = 0
		elseif p.Name == "Beam" then
			p.Material = Enum.Material.Neon; p.Color = Color3.fromRGB(200, 225, 105); p.TextureID = ""; p.Transparency = 0.72; p.CanCollide = false; p.CastShadow = false
			local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(225, 240, 140); l.Range = 12; l.Brightness = 0.9; l.Shadows = false; l.Parent = p
		elseif p.Name:match("^Alien") then
			p.Material = Enum.Material.SmoothPlastic
		else
			p.Material = Enum.Material.SmoothPlastic
		end
	end
end
-- sounds (built-in Roblox clips, no upload needed): machinery click + wind-up, generator rumble loop,
-- electronic beeping, wind-down. Swap any SoundId for a Toolbox audio id if you want a fancier clip.
do
	local beam = model:FindFirstChild("Beam")
	if beam then
		for _, n in ipairs({"BeamHum", "BeamStart", "BeamStop", "BeamBeep", "BeamClick"}) do local o = beam:FindFirstChild(n); if o then o:Destroy() end end
		local function snd(name, id, vol, speed, looped)
			local x = Instance.new("Sound"); x.Name = name; x.SoundId = id; x.Volume = vol; x.PlaybackSpeed = speed
			x.Looped = looped or false; x.RollOffMaxDistance = 110; x.Parent = beam; return x
		end
		snd("BeamClick", "rbxasset://sounds/switch3.wav", 0.8, 0.7)
		snd("BeamStart", "rbxasset://sounds/Launching rocket.wav", 0.6, 0.55)
		snd("BeamHum",   "rbxasset://sounds/Launching rocket.wav", 0.3, 0.4, true)
		snd("BeamBeep",  "rbxasset://sounds/electronicpingshort.wav", 0.45, 0.9)
		snd("BeamStop",  "rbxasset://sounds/Rocket whoosh 01.wav", 0.5, 0.5)
	end
end
-- sparkles drifting up inside the beam: an invisible cylinder volume with two particle emitters
do
	local beam = model:FindFirstChild("Beam")
	local old = model:FindFirstChild("BeamSparkles"); if old then old:Destroy() end
	if beam then
		local vol = Instance.new("Part"); vol.Name = "BeamSparkles"; vol.Anchored = true; vol.CanCollide = false; vol.CanQuery = false
		vol.Transparency = 1; vol.CastShadow = false
		vol.Size = Vector3.new(2.6, beam.Size.Y * 0.5, 2.6)
		vol.CFrame = beam.CFrame * CFrame.new(0, -beam.Size.Y * 0.22, 0)
		vol.Parent = model
		local function emitter(name, rate, size0, size1, life0, life1, speed0, speed1, bright)
			local e = Instance.new("ParticleEmitter"); e.Name = name
			e.Shape = Enum.ParticleEmitterShape.Cylinder; e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
			e.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward; e.ShapePartial = 1
			e.EmissionDirection = Enum.NormalId.Top
			e.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 110)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(230, 245, 140)), ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 255, 130)) })
			e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.15, size0), NumberSequenceKeypoint.new(0.8, size1), NumberSequenceKeypoint.new(1, 0) })
			e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0.1), NumberSequenceKeypoint.new(0.8, 0.3), NumberSequenceKeypoint.new(1, 1) })
			e.Lifetime = NumberRange.new(life0, life1); e.Rate = rate; e.Speed = NumberRange.new(speed0, speed1)
			e.SpreadAngle = Vector2.new(0, 0); e.Drag = 0; e.Acceleration = Vector3.new(0, 0.9, 0)
			e.RotSpeed = NumberRange.new(0, 0); e.Rotation = NumberRange.new(0, 0)
			e.LightEmission = 1; e.LightInfluence = 0; e.Brightness = bright; e.ZOffset = 0.2
			e.Parent = vol
			return e
		end
		emitter("Motes", 70, 0.07, 0.05, 4.0, 6.0, 0.35, 0.6, 3)
		emitter("Molecules", 14, 0.14, 0.1, 4.0, 6.0, 0.25, 0.45, 2)
	end
end
-- remember where every piece belongs relative to the pad, so the model can snap itself back together
do
	local padBase = model:FindFirstChild("PadBase")
	if padBase then
		for _, p in ipairs(model:GetDescendants()) do
			if p:IsA("BasePart") and p ~= padBase then p:SetAttribute("HomeOffset", padBase.CFrame:ToObjectSpace(p.CFrame)) end
		end
		model.PrimaryPart = padBase
	end
end
for _, n in ipairs({"LampBlinker", "UfoHover", "TractorBeam"}) do local s = model:FindFirstChild(n); if s then s:Destroy() end end
local blinker = Instance.new("Script"); blinker.Name = "LampBlinker"
blinker.Source = [[
local model = script.Parent
local rng = Random.new()
for _, lamp in ipairs(model:GetDescendants()) do
	if lamp:IsA("BasePart") and lamp.Name:find("Lamp") then
		task.spawn(function()
			local onColor = lamp.Color
			local offColor = onColor:Lerp(Color3.new(0, 0, 0), 0.7)
			local light = lamp:FindFirstChildOfClass("PointLight")
			local period = rng:NextNumber(0.5, 2.0)
			task.wait(rng:NextNumber(0, 2))
			while lamp.Parent do
				lamp.Material = Enum.Material.SmoothPlastic; lamp.Color = offColor
				if light then light.Enabled = false end
				task.wait(period * rng:NextNumber(0.3, 0.7))
				lamp.Material = Enum.Material.Neon; lamp.Color = onColor
				if light then light.Enabled = true end
				task.wait(period * rng:NextNumber(0.6, 1.4))
			end
		end)
	end
end
]]
blinker.Parent = model
local hover = Instance.new("Script"); hover.Name = "UfoHover"
hover.Source = [[
-- Hover + slow spin, positioned RELATIVE TO THE PAD every frame, so the saucer follows the pad
-- wherever the model is moved (including worlds that reposition the model after inserting it).
-- Dips while the beam works. When a player wiggles free (Escaped attribute) the ship spins up,
-- shoots away and fades out, then returns after RETURN_DELAY seconds.
local model = script.Parent
local RunService = game:GetService("RunService")
local hull = model:FindFirstChild("UfoHull")
local padBase = model:FindFirstChild("PadBase")
if not (hull and padBase) then return end
local DIP, RETURN_DELAY = 2.2, 14
local parts, baseT = {}, {}
for _, p in ipairs(model:GetDescendants()) do
	if p:IsA("BasePart") and p ~= padBase and not p.Name:find("Pad") then
		local off = p:GetAttribute("HomeOffset") or padBase.CFrame:ToObjectSpace(p.CFrame)
		table.insert(parts, {p, off, p.Name:find("Beam") ~= nil})
		baseT[p] = p.Transparency
	end
end
local hullOff = hull:GetAttribute("HomeOffset") or padBase.CFrame:ToObjectSpace(hull.CFrame)
local centre = hullOff.Position
local function setHidden(alpha)   -- 0 = normal, 1 = invisible
	for _, e in ipairs(parts) do if not e[3] then local p = e[1]; p.Transparency = baseT[p] + (1 - baseT[p]) * alpha end end
end
local t, dip, ang = 0, 0, 0
local state, st = "home", 0
model:SetAttribute("ShipAway", false)
RunService.Heartbeat:Connect(function(dt)
	t += dt
	local target = (model:GetAttribute("BeamActive") and state == "home") and -DIP or 0
	dip += (target - dip) * math.min(1, dt * 1.6)
	local offset = Vector3.new(0, math.sin(t * 1.4) * 0.35 + dip, 0)
	local spinRate = 0.3
	if state == "home" and model:GetAttribute("Escaped") then
		state, st = "leaving", 0
		model:SetAttribute("ShipAway", true)
	elseif state == "leaving" then
		st += dt
		local k = math.min(1, st / 2.6)
		offset += Vector3.new(34 * k * k, 48 * k * k, 18 * k * k)
		spinRate = 0.3 + 4 * k
		setHidden(math.clamp((k - 0.45) / 0.55, 0, 1))
		if st >= 2.6 then state, st = "gone", 0; setHidden(1) end
	elseif state == "gone" then
		st += dt
		offset += Vector3.new(0, 80, 0)
		if st >= RETURN_DELAY then state, st = "returning", 0 end
	elseif state == "returning" then
		st += dt
		local k = 1 - math.min(1, st / 3.2)
		offset += Vector3.new(0, 55 * k * k, 0)
		spinRate = 0.3 + 2 * k
		setHidden(math.clamp(k * 1.4 - 0.2, 0, 1))
		if st >= 3.2 then
			state, st = "home", 0; setHidden(0)
			model:SetAttribute("Escaped", false); model:SetAttribute("ShipAway", false)
		end
	end
	ang += spinRate * dt
	local base = padBase.CFrame
	local spin = CFrame.new(centre) * CFrame.Angles(0, ang, 0) * CFrame.new(-centre)
	local lift = CFrame.new(offset)
	for _, e in ipairs(parts) do
		if e[3] then
			e[1].CFrame = base * e[2]                    -- beam + sparkles: fixed to the pad
		else
			e[1].CFrame = base * (lift * spin * e[2])    -- saucer: spin about its centre, then bob/dip/fly
		end
	end
end)
]]
hover.Parent = model
local tractor = Instance.new("Script"); tractor.Name = "TractorBeam"
tractor.Source = [[
-- The beam stays off until a player or an unanchored object is on the pad's green circle.
-- Then it powers up (sound + fade in + sparkles), lifts what is there, and powers down when empty.
local model = script.Parent
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local beam = model:FindFirstChild("Beam")
local hull = model:FindFirstChild("UfoHull")
local pad = model:FindFirstChild("NeonLime_PadDisc")
local sparkles = model:FindFirstChild("BeamSparkles")
if not (beam and hull and pad) then return end
local ON_T = beam.Transparency
local ZONE_R = 2.9
local light = beam:FindFirstChildOfClass("PointLight")
local emitters = {}
if sparkles then for _, e in ipairs(sparkles:GetChildren()) do if e:IsA("ParticleEmitter") then table.insert(emitters, e) end end end
local hum = beam:FindFirstChild("BeamHum")
local start = beam:FindFirstChild("BeamStart")
local stop = beam:FindFirstChild("BeamStop")
local beep = beam:FindFirstChild("BeamBeep")
local click = beam:FindFirstChild("BeamClick")
local params = OverlapParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = {model}
local active = false
local function setActive(on)
	if on == active then return end
	active = on
	activeSince = on and os.clock() or nil
	model:SetAttribute("BeamActive", on)
	for _, e in ipairs(emitters) do e.Enabled = on end
	if light then light.Enabled = on end
	if on then
		if click then click:Play() end
		if start then start:Play() end
		task.delay(0.8, function() if active and hum then hum:Play() end end)
		task.spawn(function()
			while active do
				if beep then beep:Play() end
				task.wait(0.85)
			end
		end)
		TweenService:Create(beam, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = ON_T}):Play()
	else
		if click then click:Play() end
		if stop then stop:Play() end
		if hum then hum:Stop() end
		if start then start:Stop() end
		TweenService:Create(beam, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 1}):Play()
	end
end
-- start hidden
beam.Transparency = 1
for _, e in ipairs(emitters) do e.Enabled = false end
if light then light.Enabled = false end
local held = {}      -- humanoids currently floating: humanoid -> struggle seconds
local immune = {}    -- humanoids recently released: humanoid -> time they can be grabbed again
local HOLD_TIME = 8          -- seconds the beam holds its catch before letting go
local COOLDOWN = 7           -- seconds the beam stays off afterwards
local WIGGLE_ENABLED = false -- true = mashing movement keys also breaks a player free
local WIGGLE_TIME = 0.8
local activeSince, cooldownUntil = nil, 0
RunService.Heartbeat:Connect(function(dt)
	local belly = hull.Position.Y - hull.Size.Y / 2
	local topChar, top = belly - 2.6, belly - 1.0
	local now = os.clock()
	if model:GetAttribute("ShipAway") then setActive(false); return end
	if now < cooldownUntil then
		if active then setActive(false) end
		return
	end
	if active and activeSince and now - activeSince > HOLD_TIME then
		-- time's up: drop everything, rest, and if a player was aboard the ship takes off
		local hadPlayer = false
		for humanoid in pairs(held) do hadPlayer = true; if humanoid.Parent then humanoid.PlatformStand = false end; immune[humanoid] = now + COOLDOWN + 2 end
		held = {}
		for _, m in ipairs(workspace:GetChildren()) do
			if m:IsA("Model") and m:GetAttribute("Lifted") then m:SetAttribute("Lifted", false); m:SetAttribute("BeamIgnoreUntil", now + COOLDOWN + 4) end
		end
		cooldownUntil = now + COOLDOWN
		setActive(false)
		if hadPlayer then model:SetAttribute("Escaped", true) end
		return
	end
	local cx, cz = pad.Position.X, pad.Position.Z
	local zoneCF = CFrame.new(cx, (pad.Position.Y + belly) / 2, cz)
	local zoneSize = Vector3.new(ZONE_R * 2, math.max(1, belly - pad.Position.Y), ZONE_R * 2)
	local found = false
	local seen = {}
	for _, part in ipairs(workspace:GetPartBoundsInBox(zoneCF, zoneSize, params)) do
		local dx, dz = part.Position.X - cx, part.Position.Z - cz
		if math.sqrt(dx * dx + dz * dz) < ZONE_R then
			local humanoid = part.Parent and part.Parent:FindFirstChildOfClass("Humanoid")
			if humanoid then
				local root = humanoid.RootPart
				if immune[humanoid] and immune[humanoid] > now then
					-- just escaped: let them walk out without re-grabbing
				elseif root and not seen[humanoid] then
					found = true
					seen[humanoid] = true
					if active then
						if held[humanoid] == nil then held[humanoid] = 0; humanoid.PlatformStand = true end
						-- struggle: pushing movement keys builds up, letting go bleeds off
						if humanoid.MoveDirection.Magnitude > 0.1 then held[humanoid] += dt else held[humanoid] = math.max(0, held[humanoid] - dt * 0.5) end
						local rdx, rdz = root.Position.X - cx, root.Position.Z - cz
						if WIGGLE_ENABLED and held[humanoid] >= WIGGLE_TIME then
							-- break free: fling outward and away, then ignore them for a moment
							held[humanoid] = nil; humanoid.PlatformStand = false
							local out = Vector3.new(rdx, 0, rdz)
							out = (out.Magnitude > 0.1) and out.Unit or Vector3.new(1, 0, 0)
							root.AssemblyLinearVelocity = out * 28 + Vector3.new(0, 14, 0)
							immune[humanoid] = now + 2.5
							seen[humanoid] = nil
							model:SetAttribute("Escaped", true)
						else
							local up = math.clamp((topChar - root.Position.Y) * 1.2, -1.5, 9)
							root.AssemblyLinearVelocity = Vector3.new(-rdx * 0.6, up, -rdz * 0.6)
							root.AssemblyAngularVelocity = Vector3.new(0, 1.2, 0)
						end
					end
				end
			elseif not part.Anchored then
				found = true
				if active then
					local up = math.clamp((top - part.Position.Y) * 1.2, -1.5, 9)
					part.AssemblyLinearVelocity = Vector3.new(-dx * 0.6, up, -dz * 0.6)
					part.AssemblyAngularVelocity = Vector3.new(0, 1.2, 0)
				end
			end
		end
	end
	for humanoid in pairs(held) do
		if not seen[humanoid] then held[humanoid] = nil; if humanoid.Parent then humanoid.PlatformStand = false end end
	end
	-- anchored critters that opted in (attribute TractorTarget), e.g. the hound: lift by moving the model,
	-- hold for a few seconds, then let go and ignore him for a while so he can wander off
	for _, m in ipairs(workspace:GetChildren()) do
		if m:IsA("Model") and m:GetAttribute("TractorTarget") then
			local pv = m:GetPivot()
			local dx, dz = pv.Position.X - cx, pv.Position.Z - cz
			local inZone = math.sqrt(dx * dx + dz * dz) < ZONE_R and pv.Position.Y < top + 2 and pv.Position.Y > pad.Position.Y - 3
			local until_ = m:GetAttribute("BeamIgnoreUntil") or 0
			if inZone and now >= until_ then
				found = true
				if active then
					if not m:GetAttribute("Lifted") then m:SetAttribute("Lifted", true); m:SetAttribute("LiftStart", now) end
					local up = math.clamp((top - 2.5 - pv.Position.Y) * 1.2, -1.5, 6)
					local newPos = pv.Position + Vector3.new(-dx * 0.6, up, -dz * 0.6) * dt
					m:PivotTo(CFrame.new(newPos) * CFrame.Angles(0, math.rad(60) * dt, 0) * pv.Rotation)
				end
			elseif m:GetAttribute("Lifted") then
				m:SetAttribute("Lifted", false)
			end
		end
	end
	for humanoid, t in pairs(immune) do if t <= now then immune[humanoid] = nil end end
	setActive(found)
end)
]]
tractor.Parent = model
model:SetAttribute("BeamActive", false); model:SetAttribute("Escaped", false); model:SetAttribute("ShipAway", false)
model.Name = "UFO"
print("UFO: neon, lights, hover, blink and tractor beam applied")
'''

def write_preview_ufo(obj_text, png_path, out_name, cam, look):
    write_preview(obj_text, png_path, out_name, cam, look)
    p = OUT / out_name; h = p.read_text(encoding="utf-8")
    h = h.replace("p[1].includes('Haze')", "(p[1].includes('Haze')||p[1]==='Dome'||p[1]==='Beam')")
    h = h.replace("opacity:0.22", "opacity:0.35")
    h = h.replace("const groups={lit:mk(),neon:mk(),haze:mk()};", "const groups={lit:mk(),neon:mk(),haze:mk(),matte:mk()};")
    h = h.replace("cur=(p[1].includes('Haze')||p[1]==='Dome'||p[1]==='Beam')?groups.haze:(p[1].startsWith('Neon')?groups.neon:groups.lit);",
                  "cur=(p[1].includes('Haze')||p[1]==='Dome'||p[1]==='Beam')?groups.haze:(p[1].startsWith('Neon')?groups.neon:(p[1].startsWith('Alien')?groups.matte:groups.lit));")
    h = h.replace("mesh(groups.neon,new THREE.MeshBasicMaterial({map:tex}));", "mesh(groups.neon,new THREE.MeshBasicMaterial({map:tex}));mesh(groups.matte,new THREE.MeshStandardMaterial({map:tex,roughness:0.95,metalness:0}));")
    p.write_text(h, encoding="utf-8")

if __name__ == "__main__":
    o = build()
    tris = o.write(OUT / "ufo.obj", "ufo_texture.png")
    paint().save(OUT / "ufo_texture.png")
    (OUT / "ufo_setup.lua").write_text(LUA, encoding="utf-8")
    write_preview_ufo((OUT / "ufo.obj").read_text(encoding="utf-8"), OUT / "ufo_texture.png", "preview_ufo.html", (24, 18, 34), (0, 9.5, 0))
    print(f"ufo.obj: {len(o.v)} verts, {tris} triangles, {len(o.objects)} objects")
