"""Draws the world map for 1001 Squirrels as an aged parchment chart: the three areas with their own landmarks, the
river, the lane, a compass rose and a torn border. World coordinates match the boundary walls, so the "you are here"
dot the game draws on top lands in the right place.
Run: python make_map.py   ->  map_parchment.png (1024 x 560)"""
import math, random
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

OUT = Path(__file__).parent / "map_parchment.png"
W, H = 1024, 560
# the world rectangle the game maps onto this image (same numbers as build_hudbar.lua)
WX0, WX1, WZ0, WZ1 = -130, 700, -250, 30
PAPER, PAPER_DK, EDGE = (233, 214, 170), (214, 190, 140), (150, 118, 74)
INK, INK_SOFT = (92, 62, 34), (140, 108, 70)
GRASS, GRASS_DK = (176, 196, 136), (150, 176, 112)
STONE, ROOF = (206, 198, 182), (186, 120, 96)
WATER, LAVENDER = (150, 186, 206), (168, 146, 200)
rnd = random.Random(11)

M = 26                                  # margin: the map area inside the torn border
sc = min((W - 2 * M) / (WX1 - WX0), (H - 2 * M) / (WZ1 - WZ0))
offx = (W - (WX1 - WX0) * sc) / 2
offz = (H - (WZ1 - WZ0) * sc) / 2


def P(x, z):
    """world -> image"""
    return (offx + (x - WX0) * sc, offz + (z - WZ0) * sc)


def river_x(z):
    """the river's centre, the same curve the village builder uses"""
    d = z + 120
    t = min(max((abs(d) - 50) / 120, 0), 1)
    env = t * t * (3 - 2 * t)
    return 156 + 45 * env * math.cos(2 * math.pi / 260 * abs(d))


def paper(img):
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, W, H), fill=PAPER)
    for _ in range(2600):                                   # blotches and grain
        x, y = rnd.randrange(W), rnd.randrange(H)
        r = rnd.randint(2, 26)
        v = rnd.randint(-10, 8)
        d.ellipse((x - r, y - r, x + r, y + r), fill=(PAPER[0] + v, PAPER[1] + v - 2, PAPER[2] + v - 4))
    return img.filter(ImageFilter.GaussianBlur(2.2))


def torn_border(d):
    pts = []
    for i in range(160):                                     # a wobbly rectangle
        t = i / 160
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


def house(d, x, z, s=1.0):
    px, py = P(x, z)
    w, h = 12 * s, 9 * s
    d.rectangle((px - w / 2, py - h / 2, px + w / 2, py + h / 2), fill=STONE, outline=INK_SOFT)
    d.polygon([(px - w / 2 - 2, py - h / 2), (px + w / 2 + 2, py - h / 2), (px, py - h / 2 - 7 * s)], fill=ROOF, outline=INK_SOFT)


def main():
    img = paper(Image.new("RGB", (W, H), PAPER))
    d = ImageDraw.Draw(img)

    # the three areas
    area(d, -130, -215, 142, 25, GRASS, INK_SOFT)            # The Great Acorn Forest
    area(d, 150, -205, 352, 5, (222, 212, 194), INK_SOFT)    # Rue de Noisette
    area(d, 352, -250, 700, 30, (216, 206, 168), INK_SOFT)   # Château de l'Acorn

    # the river, drawn down the middle of the map
    band = []
    for z in range(-250, 31, 6):
        band.append(P(river_x(z), z))
    d.line(band, fill=WATER, width=int(15 * sc), joint="curve")
    d.line(band, fill=(120, 160, 186), width=2, joint="curve")

    # the lane east from the bridge, and the path up to the château
    lane = [P(150, -120), P(300, -120), P(352, -120), P(520, -120), P(560, -116), P(596, -112)]
    for i in range(len(lane) - 1):
        x0, y0 = lane[i]
        x1, y1 = lane[i + 1]
        steps = max(2, int(math.hypot(x1 - x0, y1 - y0) / 14))
        for k in range(steps):
            f0, f1 = k / steps, (k + 0.55) / steps
            d.line((x0 + (x1 - x0) * f0, y0 + (y1 - y0) * f0, x0 + (x1 - x0) * f1, y0 + (y1 - y0) * f1), fill=INK_SOFT, width=3)

    # the bridge over the river
    bx, by = P(156, -120)
    d.line((bx - 14, by - 12, bx + 14, by - 12), fill=INK, width=3)
    d.line((bx - 14, by + 12, bx + 14, by + 12), fill=INK, width=3)
    for k in range(-2, 3):
        d.line((bx + k * 7, by - 12, bx + k * 7, by + 12), fill=INK_SOFT, width=2)

    # forest: a scatter of pines
    for _ in range(58):
        x = rnd.uniform(-125, 120)
        z = rnd.uniform(-210, 20)
        if abs(x - 3) < 26 and abs(z - 1) < 26:              # leave the spawn clearing
            continue
        tree(d, x, z, rnd.uniform(0.75, 1.25))
    cx, cy = P(3, 1)                                          # the spawn dais, drawn as a little acorn medallion
    d.ellipse((cx - 13, cy - 13, cx + 13, cy + 13), fill=(238, 228, 200), outline=INK, width=2)
    d.ellipse((cx - 7, cy - 3, cx + 7, cy + 9), fill=(208, 148, 84), outline=INK_SOFT)
    d.chord((cx - 8, cy - 9, cx + 8, cy + 3), 180, 360, fill=(112, 72, 42), outline=INK_SOFT)

    # village: houses either side of the street, and the square
    for k in range(9):
        house(d, 175 + k * 19, -138, 1.0)
        house(d, 175 + k * 19, -101, 1.0)
    sx, sy = P(260, -95)
    d.ellipse((sx - 9, sy - 9, sx + 9, sy + 9), fill=WATER, outline=INK_SOFT)

    # château: lavender rows, vines, the windmill and the farmhouse
    for k in range(7):
        x0, y0 = P(428, -196 + k * 9)
        x1, y1 = P(488, -196 + k * 9)
        d.line((x0, y0, x1, y1), fill=LAVENDER, width=4)
    for k in range(6):
        x0, y0 = P(536, -230 + k * 18)
        x1, y1 = P(632, -230 + k * 18)
        d.line((x0, y0, x1, y1), fill=(150, 170, 118), width=3)
    house(d, 482, -36, 1.5)
    mx, my = P(588, -62)                                      # windmill
    d.polygon([(mx - 7, my + 10), (mx + 7, my + 10), (mx + 5, my - 10), (mx - 5, my - 10)], fill=(238, 232, 214), outline=INK_SOFT)
    for a in (0.6, 2.2, 3.7, 5.3):
        d.line((mx, my - 8, mx + math.cos(a) * 16, my - 8 + math.sin(a) * 16), fill=INK_SOFT, width=2)

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
    print("wrote", OUT, img.size)


if __name__ == "__main__":
    main()
