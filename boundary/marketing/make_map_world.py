"""Draws the WORLD chart for 1001 Squirrels (Oct 1 2026, Shannon's "one draggable map"): the same aged parchment as
make_map.py, now covering France AND the south - the gorge the river leaves through, the aqueduct, the falls, the plunge
pool that is Porto Nocciola's harbour, the shore with its dais and luggage cart, the sea. World coordinates match the
boundary walls and SpawnReturn: the game draws names, covers and the "you are here" dot on top (HudBarClient).
Run: python make_map_world.py  ->  ../../italy/map/world_chart.png (1024 x 900) + map_carrier.obj/.mtl (Import 3D uploads it)"""
import math, random
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

OUT_DIR = Path(__file__).parent.parent.parent / "italy" / "map"
OUT_DIR.mkdir(parents=True, exist_ok=True)
OUT = OUT_DIR / "world_chart.png"
W, H = 1024, 900
# the world rectangle the game maps onto this image (HudBarClient: WX0, WX1, WZ0, WZ1)
WX0, WX1, WZ0, WZ1 = -130, 700, -700, 30
PAPER, PAPER_DK, EDGE = (233, 214, 170), (214, 190, 140), (150, 118, 74)
INK, INK_SOFT = (92, 62, 34), (140, 108, 70)
GRASS, GRASS_DK = (176, 196, 136), (150, 176, 112)
ITALY, ITALY_DK = (188, 206, 142), (156, 182, 110)
STONE, ROOF = (206, 198, 182), (186, 120, 96)
WATER, WATER_DK, FOAM = (150, 186, 206), (120, 160, 186), (236, 244, 246)
SAND, LAVENDER = (224, 206, 160), (168, 146, 200)
CLIFF, CLIFF_DK = (226, 206, 160), (196, 170, 118)
WOOD, OLIVE = (118, 84, 52), (96, 104, 66)
rnd = random.Random(11)

M = 26                                  # margin: the map area inside the torn border
sc = min((W - 2 * M) / (WX1 - WX0), (H - 2 * M) / (WZ1 - WZ0))
offx = (W - (WX1 - WX0) * sc) / 2
offz = (H - (WZ1 - WZ0) * sc) / 2


def P(x, z):
    """world -> image"""
    return (offx + (x - WX0) * sc, offz + (z - WZ0) * sc)


def river_x(z):
    """the village river's centre (the same curve the village builder uses), valid z -230..30"""
    d = z + 120
    t = min(max((abs(d) - 50) / 120, 0), 1)
    env = t * t * (3 - 2 * t)
    return 156 + 45 * env * math.cos(2 * math.pi / 260 * abs(d))


# the gorge channel, measured Sep 30 (tools/gorge_probe1_out.txt): z -> water x min..max; the river ends at the lip z -547.5
GORGE = [(-220, 164, 180), (-240, 172, 192), (-260, 184, 204), (-280, 176, 200), (-300, 164, 184), (-320, 136, 164), (-340, 120, 144),
         (-360, 104, 128), (-380, 100, 120), (-400, 104, 124), (-420, 120, 136), (-440, 140, 156), (-460, 160, 180), (-480, 176, 196),
         (-500, 188, 208), (-520, 184, 212), (-540, 176, 200), (-548, 170, 196)]
LIP_Z = -547.5


def channel(z):
    """water x min, x max at z in the gorge (linear between the measured rows)"""
    if z >= GORGE[0][0]:
        c = river_x(z); return c - 12, c + 12
    for (z0, a0, b0), (z1, a1, b1) in zip(GORGE, GORGE[1:]):
        if z1 <= z <= z0:
            f = (z - z0) / (z1 - z0)
            return a0 + (a1 - a0) * f, b0 + (b1 - b0) * f
    a, b = GORGE[-1][1], GORGE[-1][2]
    return a, b


def paper(img):
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, W, H), fill=PAPER)
    for _ in range(4200):                                   # blotches and grain
        x, y = rnd.randrange(W), rnd.randrange(H)
        r = rnd.randint(2, 26)
        v = rnd.randint(-10, 8)
        d.ellipse((x - r, y - r, x + r, y + r), fill=(PAPER[0] + v, PAPER[1] + v - 2, PAPER[2] + v - 4))
    return img.filter(ImageFilter.GaussianBlur(2.2))


def torn_border(d):
    pts = []
    for i in range(200):                                     # a wobbly rectangle
        t = i / 200
        if t < 0.25:   x, y = M + (W - 2 * M) * (t / 0.25), M
        elif t < 0.5:  x, y = W - M, M + (H - 2 * M) * ((t - 0.25) / 0.25)
        elif t < 0.75: x, y = W - M - (W - 2 * M) * ((t - 0.5) / 0.25), H - M
        else:          x, y = M, H - M - (H - 2 * M) * ((t - 0.75) / 0.25)
        pts.append((x + rnd.uniform(-4, 4), y + rnd.uniform(-4, 4)))
    d.line(pts + [pts[0]], fill=EDGE, width=5, joint="curve")
    d.line([(p[0], p[1]) for p in pts] + [pts[0]], fill=INK_SOFT, width=2, joint="curve")


def area(d, x0, z0, x1, z1, fill, edge):
    a, b = P(x0, z0), P(x1, z1)
    pts = []
    n = 44
    for i in range(n):                                       # hand-drawn wobble round the region
        t = i / n * 4
        if t < 1:   x, y = a[0] + (b[0] - a[0]) * t, a[1]
        elif t < 2: x, y = b[0], a[1] + (b[1] - a[1]) * (t - 1)
        elif t < 3: x, y = b[0] - (b[0] - a[0]) * (t - 2), b[1]
        else:       x, y = a[0], b[1] - (b[1] - a[1]) * (t - 3)
        pts.append((x + rnd.uniform(-3, 3), y + rnd.uniform(-3, 3)))
    d.polygon(pts, fill=fill)
    d.line(pts + [pts[0]], fill=edge, width=3, joint="curve")


def tree(d, x, z, s=1.0, col=GRASS_DK):
    px, py = P(x, z)
    h = 13 * s
    d.polygon([(px, py - h), (px - h * 0.52, py + h * 0.28), (px + h * 0.52, py + h * 0.28)], fill=col, outline=INK_SOFT)
    d.line((px, py + h * 0.28, px, py + h * 0.55), fill=INK_SOFT, width=2)


def cypress(d, x, z, s=1.0):
    px, py = P(x, z)
    h = 12 * s
    d.ellipse((px - h * 0.22, py - h, px + h * 0.22, py + h * 0.3), fill=(96, 132, 86), outline=INK_SOFT)


def house(d, x, z, s=1.0, roof=ROOF):
    px, py = P(x, z)
    w, h = 12 * s, 9 * s
    d.rectangle((px - w / 2, py - h / 2, px + w / 2, py + h / 2), fill=STONE, outline=INK_SOFT)
    d.polygon([(px - w / 2 - 2, py - h / 2), (px + w / 2 + 2, py - h / 2), (px, py - h / 2 - 7 * s)], fill=roof, outline=INK_SOFT)


def medallion(d, x, z, r=13):
    """a spawn dais: a little acorn medallion"""
    cx, cy = P(x, z)
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(238, 228, 200), outline=INK, width=2)
    k = r / 13
    d.ellipse((cx - 7 * k, cy - 3 * k, cx + 7 * k, cy + 9 * k), fill=(208, 148, 84), outline=INK_SOFT)
    d.chord((cx - 8 * k, cy - 9 * k, cx + 8 * k, cy + 3 * k), 180, 360, fill=(112, 72, 42), outline=INK_SOFT)


def cart(d, x, z):
    """the luggage cart: a trunk on two wheels with a handle"""
    cx, cy = P(x, z)
    d.rectangle((cx - 7, cy - 8, cx + 7, cy), fill=(122, 74, 44), outline=INK)             # the trunk
    d.line((cx - 7, cy - 5, cx + 7, cy - 5), fill=(214, 170, 76), width=2)                   # a brass strap
    d.rectangle((cx - 9, cy, cx + 9, cy + 3), fill=WOOD, outline=INK_SOFT)                   # the bed
    d.ellipse((cx - 8, cy + 1, cx - 2, cy + 7), fill=(104, 72, 42), outline=INK)             # wheels
    d.ellipse((cx + 2, cy + 1, cx + 8, cy + 7), fill=(104, 72, 42), outline=INK)
    d.line((cx + 9, cy + 1, cx + 15, cy - 6), fill=WOOD, width=3)                            # the handle


def main():
    img = paper(Image.new("RGB", (W, H), PAPER))
    d = ImageDraw.Draw(img)

    # ---------------------------------------------------------------- France: the three areas
    area(d, -130, -215, 142, 25, GRASS, INK_SOFT)            # The Great Acorn Forest
    area(d, 150, -205, 352, 5, (222, 212, 194), INK_SOFT)    # Rue de Noisette
    area(d, 352, -250, 700, 30, (216, 206, 168), INK_SOFT)   # Chateau de l'Acorn

    # ---------------------------------------------------------------- the south: ridge, gorge, falls, harbour, shore
    # the ridge the river cuts through: sandstone either side of the channel, from the village wall to the lip
    left, right = [], []
    z = -215.0
    while z >= LIP_Z:
        a, b = channel(z)
        left.append((a, z)); right.append((b, z))
        z -= 4
    a, b = channel(LIP_Z); left.append((a, LIP_Z)); right.append((b, LIP_Z))
    wall_w = 34
    d.polygon([P(x - wall_w, zz) for x, zz in left] + [P(x - 3, zz) for x, zz in reversed(left)], fill=CLIFF, outline=INK_SOFT)
    d.polygon([P(x + 3, zz) for x, zz in right] + [P(x + wall_w, zz) for x, zz in reversed(right)], fill=CLIFF, outline=INK_SOFT)
    for pts, side in ((left, -1), (right, 1)):             # strata: short strokes along the walls
        for i in range(0, len(pts), 3):
            x, zz = pts[i]
            x0, y0 = P(x + side * 8, zz); x1, y1 = P(x + side * (wall_w - 6), zz)
            d.line((x0, y0, x1, y1), fill=CLIFF_DK, width=1)
    # pines on the rims
    for x, zz in left[::6]:
        tree(d, x - wall_w - 6 + rnd.uniform(-4, 4), zz + rnd.uniform(-3, 3), 0.8)
    for x, zz in right[::6]:
        tree(d, x + wall_w + 6 + rnd.uniform(-4, 4), zz + rnd.uniform(-3, 3), 0.8)
    # the cliff face at the end of the gorge (the amphitheatre), both arms, with the notch for the falls
    face = [P(100, -540), P(100, -562), P(channel(LIP_Z)[0] - 3, -562), P(channel(LIP_Z)[0] - 3, LIP_Z), P(channel(LIP_Z)[0] - wall_w, LIP_Z), P(channel(LIP_Z)[0] - wall_w, -540)]
    d.polygon(face, fill=CLIFF, outline=INK_SOFT)
    face = [P(channel(LIP_Z)[1] + wall_w, -540), P(channel(LIP_Z)[1] + wall_w, LIP_Z), P(channel(LIP_Z)[1] + 3, LIP_Z), P(channel(LIP_Z)[1] + 3, -562), P(330, -562), P(330, -540)]
    d.polygon(face, fill=CLIFF, outline=INK_SOFT)
    for xx in range(104, 330, 9):                            # strata on the face
        if channel(LIP_Z)[0] - 6 < xx < channel(LIP_Z)[1] + 6: continue
        x0, y0 = P(xx, -552); x1, y1 = P(xx + 5, -552)
        d.line((x0, y0, x1, y1), fill=CLIFF_DK, width=1)
    # the Italian plain: grass from the cliff foot to the bottom, the shore sand along the water
    d.polygon([P(100, -562), P(330, -562), P(330, -700), P(100, -700)], fill=ITALY)
    # the plunge pool / harbour and the sea, widening south (measured Oct 1: travel_probe1)
    pool = [P(channel(LIP_Z)[0], -556), P(channel(LIP_Z)[1], -556), P(212, -570), P(224, -592), P(230, -620), P(236, -660), P(240, -700),
            P(148, -700), P(150, -640), P(152, -600), P(156, -575)]
    d.polygon(pool, fill=SAND)                               # the sand rim
    inner = [P(channel(LIP_Z)[0] + 2, -556), P(channel(LIP_Z)[1] - 2, -556), P(208, -572), P(220, -593), P(226, -620), P(232, -660), P(236, -700),
             P(152, -700), P(154, -640), P(156, -600), P(160, -576)]
    d.polygon(inner, fill=WATER, outline=WATER_DK)
    for k in range(6):                                       # a few wave marks on the harbour
        wx, wz = rnd.uniform(165, 215), rnd.uniform(-600, -690)
        x0, y0 = P(wx, wz)
        d.arc((x0 - 6, y0 - 3, x0 + 6, y0 + 3), 200, 340, fill=FOAM, width=1)
    # the river water down the gorge, and the falls
    d.polygon([P(x, zz) for x, zz in left] + [P(x, zz) for x, zz in reversed(right)], fill=WATER, outline=WATER_DK)
    centre = [P((channel(zz)[0] + channel(zz)[1]) / 2, zz) for _, zz in left]
    d.line(centre, fill=WATER_DK, width=2, joint="curve")
    for i in range(1, 7):                                    # white water before the brink
        zz = LIP_Z + i * 7
        a, b = channel(zz)
        x0, y0 = P(a + 2, zz); x1, y1 = P(b - 2, zz)
        d.line((x0, y0, x1, y1), fill=FOAM, width=2)
    a, b = channel(LIP_Z)
    x0, y0 = P(a, LIP_Z); x1, y1 = P(b, LIP_Z)
    d.line((x0, y0, x1, y1), fill=FOAM, width=4)
    for k in range(7):                                       # the sheet and the mist fanning into the pool
        fx = a + (b - a) * (k + 0.5) / 7
        p0 = P(fx, LIP_Z); p1 = P(fx + rnd.uniform(-3, 3), -566)
        d.line((p0[0], p0[1], p1[0], p1[1]), fill=FOAM, width=2)
    mx, my = P((a + b) / 2, -568)
    d.ellipse((mx - 16, my - 6, mx + 16, my + 6), fill=(230, 240, 244), outline=None)
    # the aqueduct across the basin
    zq = -388
    a, b = channel(zq)
    x0, y0 = P(a - 30, zq); x1, y1 = P(b + 30, zq)
    d.line((x0, y0, x1, y1), fill=WOOD, width=5)
    for k in range(4):
        ax = a - 20 + (b - a + 40) * (k + 0.5) / 4
        px, py = P(ax, zq)
        d.arc((px - 4, py - 3, px + 4, py + 5), 180, 360, fill=PAPER, width=2)
    # Italian planting: cypresses and a few pines on the plain, clear of the dais and the cart
    for _ in range(14):
        x, zz = rnd.uniform(244, 325), rnd.uniform(-566, -695)
        if abs(x - 236) < 14 and abs(zz + 580) < 14: continue
        (cypress if rnd.random() < 0.6 else tree)(d, x, zz, rnd.uniform(0.7, 1.0))
    for _ in range(4):
        cypress(d, rnd.uniform(106, 140), rnd.uniform(-580, -690), 0.8)
    # Porto Nocciola: the dais on the shore and the luggage cart beside it
    medallion(d, 232, -580, 11)
    cart(d, 256, -582)                                       # the twin cart, drawn a little east so the dais stays readable

    # ---------------------------------------------------------------- France: the river, lane, bridge, jetty
    band = [P(river_x(z), z) for z in range(-230, 31, 6)]
    d.line(band, fill=WATER, width=int(15 * sc), joint="curve")
    d.line(band, fill=WATER_DK, width=2, joint="curve")
    lane = [P(150, -120), P(300, -120), P(352, -120), P(520, -120), P(560, -116), P(596, -112)]
    for i in range(len(lane) - 1):
        x0, y0 = lane[i]; x1, y1 = lane[i + 1]
        steps = max(2, int(math.hypot(x1 - x0, y1 - y0) / 14))
        for k in range(steps):
            f0, f1 = k / steps, (k + 0.55) / steps
            d.line((x0 + (x1 - x0) * f0, y0 + (y1 - y0) * f0, x0 + (x1 - x0) * f1, y0 + (y1 - y0) * f1), fill=INK_SOFT, width=3)
    bx, by = P(156, -120)
    d.line((bx - 14, by - 12, bx + 14, by - 12), fill=INK, width=3)
    d.line((bx - 14, by + 12, bx + 14, by + 12), fill=INK, width=3)
    for k in range(-2, 3):
        d.line((bx + k * 7, by - 12, bx + k * 7, by + 12), fill=INK_SOFT, width=2)
    jx0, jy0 = P(160, -168); jx1, jy1 = P(164, -146)          # the jetty on the east bank
    d.rectangle((jx0, jy0, jx1, jy1), fill=WOOD, outline=INK)
    bx, by = P(153, -157)                                     # the moored boat
    d.ellipse((bx - 4, by - 8, bx + 4, by + 8), fill=OLIVE, outline=INK)

    # forest: pines and the spawn dais
    for _ in range(58):
        x = rnd.uniform(-125, 120)
        z = rnd.uniform(-210, 20)
        if abs(x - 3) < 26 and abs(z - 1) < 26:
            continue
        tree(d, x, z, rnd.uniform(0.75, 1.25))
    medallion(d, 3, 1)

    # village: houses either side of the street, the square, the dais
    for k in range(9):
        house(d, 175 + k * 19, -138, 1.0)
        house(d, 175 + k * 19, -101, 1.0)
    sx, sy = P(260, -95)
    d.ellipse((sx - 9, sy - 9, sx + 9, sy + 9), fill=WATER, outline=INK_SOFT)
    medallion(d, 196, -36, 10)

    # chateau: lavender rows, vines, the windmill, the farmhouse, the hall of fame, the dais and the luggage cart
    for k in range(7):
        x0, y0 = P(428, -196 + k * 9); x1, y1 = P(488, -196 + k * 9)
        d.line((x0, y0, x1, y1), fill=LAVENDER, width=4)
    for k in range(6):
        x0, y0 = P(536, -230 + k * 18); x1, y1 = P(632, -230 + k * 18)
        d.line((x0, y0, x1, y1), fill=(150, 170, 118), width=3)
    house(d, 482, -36, 1.5)
    mx, my = P(588, -62)
    d.polygon([(mx - 7, my + 10), (mx + 7, my + 10), (mx + 5, my - 10), (mx - 5, my - 10)], fill=(238, 232, 214), outline=INK_SOFT)
    for a in (0.6, 2.2, 3.7, 5.3):
        d.line((mx, my - 8, mx + math.cos(a) * 16, my - 8 + math.sin(a) * 16), fill=INK_SOFT, width=2)
    hx, hy = P(404, -33)                                      # the Hall of Fame: a little temple
    d.rectangle((hx - 9, hy - 2, hx + 9, hy + 6), fill=(236, 232, 224), outline=INK_SOFT)
    d.polygon([(hx - 11, hy - 2), (hx + 11, hy - 2), (hx, hy - 9)], fill=ROOF, outline=INK_SOFT)
    for k in (-6, 0, 6):
        d.line((hx + k, hy - 1, hx + k, hy + 6), fill=INK_SOFT, width=2)
    medallion(d, 438, -36, 10)
    cart(d, 427, -47)

    # compass rose, bottom left
    rx, ry = M + 62, H - M - 62
    d.ellipse((rx - 30, ry - 30, rx + 30, ry + 30), outline=INK_SOFT, width=2)
    for a, L in ((0, 30), (math.pi / 2, 30), (math.pi, 30), (3 * math.pi / 2, 30)):
        d.line((rx, ry, rx + math.cos(a) * L, ry + math.sin(a) * L), fill=INK, width=3)
    for a in (math.pi / 4, 3 * math.pi / 4, 5 * math.pi / 4, 7 * math.pi / 4):
        d.line((rx, ry, rx + math.cos(a) * 19, ry + math.sin(a) * 19), fill=INK_SOFT, width=2)
    d.polygon([(rx, ry - 34), (rx - 6, ry - 18), (rx + 6, ry - 18)], fill=INK)

    # a soft vignette so the edges look aged
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).rounded_rectangle((M - 6, M - 6, W - M + 6, H - M + 6), radius=30, fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(26))
    dark = Image.new("RGB", (W, H), (176, 150, 104))
    img = Image.composite(img, Image.blend(img, dark, 0.55), mask)

    d = ImageDraw.Draw(img)
    torn_border(d)
    img.save(OUT)
    # the Import 3D carrier: one textured quad, so Studio uploads the image and hands back its asset id
    (OUT_DIR / "map_carrier.mtl").write_text("newmtl WorldChart\nKd 1 1 1\nmap_Kd world_chart.png\n", encoding="utf-8")
    (OUT_DIR / "map_carrier.obj").write_text("# world chart carrier: one quad so Import 3D uploads the image\nmtllib map_carrier.mtl\no WorldChart\ng WorldChart\nusemtl WorldChart\n"
                                             "v -2 -1.75 0\nv 2 -1.75 0\nv 2 1.75 0\nv -2 1.75 0\nvt 0 0\nvt 1 0\nvt 1 1\nvt 0 1\nvn 0 0 1\nf 1/1/1 2/2/1 3/3/1\nf 1/1/1 3/3/1 4/4/1\n", encoding="utf-8")
    print("wrote", OUT, img.size, "scale px/stud", round(sc, 3), "offsets", round(offx, 1), round(offz, 1))


if __name__ == "__main__":
    main()
