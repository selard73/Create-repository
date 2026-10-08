"""Draws the WORLD chart v2 for 1001 Squirrels (Oct 7 2026): make_map_world.py extended south so the chart shows ALL of
Porto Nocciola - the harbour, the hillside town (Via della Piazza) and the Groves headland with the lighthouse at its tip.
France, the gorge and the falls are drawn exactly as in make_map_world.py (same functions, colours and random sequence).
Everything south of the falls lip comes from a read-only Studio survey: italy/map/survey/porto_survey.txt (a 4-stud raycast
grid of the ground: water, sand, grass, rock, limestone, paving, buildings + terrain heights) and the positions probed from
workspace.PortoNocciola (survey/porto_landmarks.txt: houses, trees, boats, landmarks; porto_landmarks2.txt: the street parts).
World coordinates: WX0..WX1, WZ0..WZ1 below; the game draws names, covers and the "you are here" dot on top (HudBarClient),
so this image carries no text at all.
Run: python make_map_world2.py  ->  ../../italy/map/world_chart2.png (1024 x H), world_chart2_top.png + world_chart2_bottom.png
(the same image split at row ceil(H/2) so each tile fits Roblox's 1024 px limit), world_chart2_preview.jpg (half size) and
world_chart2_debug.png (a copy with check marks on known points; never upload that one)."""
import math, random
from pathlib import Path
import numpy as np
from scipy import ndimage
from skimage.morphology import skeletonize
from PIL import Image, ImageDraw, ImageFilter

OUT_DIR = Path(__file__).parent.parent.parent / "italy" / "map"
OUT_DIR.mkdir(parents=True, exist_ok=True)
SURVEY_DIR = OUT_DIR / "survey"
OUT = OUT_DIR / "world_chart2.png"
# the world rectangle the game maps onto this image (HudBarClient: WX0, WX1, WZ0, WZ1)
WX0, WX1, WZ0, WZ1 = -130, 820, -1310, 30
M = 26                                  # margin: the map area inside the torn border
W = 1024
sc = (W - 2 * M) / (WX1 - WX0)          # px per stud, the same both ways
H = round((WZ1 - WZ0) * sc + 2 * M)
offx = (W - (WX1 - WX0) * sc) / 2
offz = (H - (WZ1 - WZ0) * sc) / 2
PAPER, PAPER_DK, EDGE = (233, 214, 170), (214, 190, 140), (150, 118, 74)
INK, INK_SOFT = (92, 62, 34), (140, 108, 70)
GRASS, GRASS_DK = (176, 196, 136), (150, 176, 112)
ITALY, ITALY_DK = (188, 206, 142), (156, 182, 110)
STONE, ROOF = (206, 198, 182), (186, 120, 96)
WATER, WATER_DK, FOAM = (150, 186, 206), (120, 160, 186), (236, 244, 246)
SAND, LAVENDER = (224, 206, 160), (168, 146, 200)
CLIFF, CLIFF_DK = (226, 206, 160), (196, 170, 118)
WOOD, OLIVE = (118, 84, 52), (96, 104, 66)
# Porto's own tints, mixed from the same palette
SHALLOW = (174, 204, 212)               # the sea over sand and shelf; deeper water fades to WATER
ROCKY = (198, 200, 160)                 # rocky scrub on the steep hillsides (half ITALY, half STONE)
TOWN = (222, 212, 194)                  # paving and built-up ground (Rue de Noisette's fill)
PATH = (236, 228, 206)                  # streets, steps and the coastal paths
LEMON = (244, 212, 70)
PINE = (120, 148, 94)
rnd = random.Random(11)                 # France: exactly the sequence make_map_world.py used
prnd = random.Random(1011)              # the paper blotches for the taller sheet
srnd = random.Random(2026)              # Porto, drawn from the survey


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
    for _ in range(round(4200 * H / 900)):                  # blotches and grain, as dense as on the first sheet
        x, y = prnd.randrange(W), prnd.randrange(H)
        r = prnd.randint(2, 26)
        v = prnd.randint(-10, 8)
        d.ellipse((x - r, y - r, x + r, y + r), fill=(PAPER[0] + v, PAPER[1] + v - 2, PAPER[2] + v - 4))
    for _ in range(4200):                                    # keep France's generator in step with the 1024 x 900 sheet
        rnd.randrange(1024); rnd.randrange(900); rnd.randint(2, 26); rnd.randint(-10, 8)
    return img.filter(ImageFilter.GaussianBlur(2.2))


def torn_border(d):
    pts = []
    n = 260                                                  # a wobbly rectangle, points spread evenly round the taller sheet
    per = 2 * (W - 2 * M) + 2 * (H - 2 * M)
    for i in range(n):
        s = per * i / n
        if s < W - 2 * M:                    x, y = M + s, M
        elif s < (W - 2 * M) + (H - 2 * M): x, y = W - M, M + s - (W - 2 * M)
        elif s < 2 * (W - 2 * M) + (H - 2 * M): x, y = W - M - (s - (W - 2 * M) - (H - 2 * M)), H - M
        else:                                x, y = M, H - M - (s - 2 * (W - 2 * M) - (H - 2 * M))
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


def house(d, x, z, s=1.0, roof=ROOF, wall=STONE):
    """(wall is new for Porto's painted houses; France's calls keep the stone wall)"""
    px, py = P(x, z)
    w, h = 12 * s, 9 * s
    d.rectangle((px - w / 2, py - h / 2, px + w / 2, py + h / 2), fill=wall, outline=INK_SOFT)
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


# ==================================================================================================== Porto Nocciola
def mix(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def umbrella_pine(d, x, z, s=1.0):
    """an Italian stone pine: a bare trunk under a flat crown"""
    px, py = P(x, z)
    d.line((px, py + 3 * s, px, py - 5 * s), fill=WOOD, width=2)
    w, h = 8 * s, 3.8 * s
    d.ellipse((px - w, py - 5 * s - 2 * h, px + w, py - 5 * s), fill=PINE, outline=INK_SOFT)


def lemon_tree(d, x, z, s=1.0):
    """a round little tree with three lemons"""
    px, py = P(x, z)
    d.line((px, py + 4 * s, px, py + 1 * s), fill=INK_SOFT, width=2)
    r = 4.4 * s
    d.ellipse((px - r, py - r, px + r, py + r), fill=(124, 160, 86), outline=INK_SOFT)
    for dx, dy in ((-1.8, -1.4), (2.0, -0.2), (-0.3, 2.0)):
        q = 1.35 * s
        d.ellipse((px + dx * s - q, py + dy * s - q, px + dx * s + q, py + dy * s + q), fill=LEMON)


def boat(d, x, z, s=1.0, hull=WOOD, sail=True, flip=False):
    """a little boat seen from the side, with a lateen-ish sail"""
    px, py = P(x, z)
    w, h = 9 * s, 3.4 * s
    f = -1 if flip else 1
    d.polygon([(px - w * f, py - h * 0.3), (px + w * f, py - h * 0.6), (px + w * 0.55 * f, py + h), (px - w * 0.7 * f, py + h)], fill=hull, outline=INK)
    if sail:
        d.line((px, py - h * 0.4, px, py - 14 * s), fill=INK, width=1)
        d.polygon([(px + 1 * f, py - 13 * s), (px + 1 * f, py - 2.5 * s), (px + 8 * s * f, py - 2.5 * s)], fill=(242, 236, 220), outline=INK_SOFT)


def lighthouse(d, x, z, s=1.0):
    """Faro di Porto Nocciola: a red-and-white banded tower with its lamp lit"""
    px, py = P(x, z)
    h, wb, wt = 30 * s, 6 * s, 4 * s
    d.ellipse((px - 11 * s, py - 3.5 * s, px + 11 * s, py + 4 * s), fill=(186, 178, 160), outline=INK_SOFT)   # the rock it stands on
    bands = 5
    for i in range(bands):
        y0, y1 = py - h * i / bands, py - h * (i + 1) / bands
        w0, w1 = wb + (wt - wb) * i / bands, wb + (wt - wb) * (i + 1) / bands
        d.polygon([(px - w0, y0), (px + w0, y0), (px + w1, y1), (px - w1, y1)], fill=(196, 72, 58) if i % 2 == 0 else (246, 240, 228))
    d.line([(px - wb, py), (px - wt, py - h), (px + wt, py - h), (px + wb, py), (px - wb, py)], fill=INK, width=1)
    cx, cy = px, py - h - 4.5 * s                                                   # the light: soft rays both ways
    for sgn in (-1, 1):
        for a in (-0.42, 0.0, 0.42):
            d.line((cx + sgn * (wt + 3 * s), cy + a * 4 * s, cx + sgn * (wt + 15 * s), cy + a * 15 * s), fill=(244, 210, 100), width=2)
    d.rectangle((px - wt - 2 * s, py - h - 1.5 * s, px + wt + 2 * s, py - h + 0.8 * s), fill=(70, 58, 46))   # the gallery
    d.rectangle((px - wt + 0.6, py - h - 7 * s, px + wt - 0.6, py - h - 1.5 * s), fill=(252, 226, 128), outline=INK)
    d.polygon([(px - wt - 1.2 * s, py - h - 7 * s), (px + wt + 1.2 * s, py - h - 7 * s), (px, py - h - 12 * s)], fill=(196, 72, 58), outline=INK)
    d.rectangle((px - 1.4 * s, py - 4.5 * s, px + 1.4 * s, py), fill=(92, 70, 52))                          # the door


def watchtower(d, x, z, s=1.0):
    """Torre di Guardia: a square stone tower with battlements"""
    px, py = P(x, z)
    w, h = 6.5 * s, 19 * s
    stone = (204, 194, 172)
    d.rectangle((px - w, py - h, px + w, py), fill=stone, outline=INK_SOFT)
    d.rectangle((px - w - 1.5 * s, py - h - 2 * s, px + w + 1.5 * s, py - h + 1.5 * s), fill=stone, outline=INK_SOFT)
    for k in range(3):                                                              # merlons
        mx = px - w - 1.5 * s + k * (2 * w + 3 * s - 3.4 * s) / 2
        d.rectangle((mx, py - h - 5.5 * s, mx + 3.4 * s, py - h - 2 * s), fill=stone, outline=INK_SOFT)
    for yy in (py - h * 0.66, py - h * 0.33):
        d.line((px - w + 1, yy, px + w - 1, yy), fill=CLIFF_DK, width=1)
    d.rectangle((px - 0.8 * s, py - h + 4 * s, px + 0.8 * s, py - h + 8 * s), fill=(70, 58, 46))           # an arrow slit
    d.chord((px - 2.4 * s, py - 6 * s, px + 2.4 * s, py - 1.2 * s), 180, 360, fill=(80, 64, 50))
    d.rectangle((px - 2.4 * s, py - 3.6 * s, px + 2.4 * s, py), fill=(80, 64, 50))                         # the door


def church(d, x, z, s=1.0):
    """Chiesa di Santa Marina: a nave with a bell tower and a cross"""
    px, py = P(x, z)
    w, h = 10 * s, 8 * s
    wall = (232, 222, 200)
    d.rectangle((px - w, py - h, px + 3 * s, py + 1 * s), fill=wall, outline=INK_SOFT)                      # the nave
    d.polygon([(px - w - 2, py - h), (px + 3 * s + 2, py - h), (px - w / 2 + 1.5 * s, py - h - 7 * s)], fill=ROOF, outline=INK_SOFT)
    d.chord((px - w / 2 - 0.5 * s, py - 5 * s, px - w / 2 + 3.5 * s, py - 1 * s), 180, 360, fill=(92, 70, 52))
    d.rectangle((px - w / 2 - 0.5 * s, py - 3 * s, px - w / 2 + 3.5 * s, py + 1 * s), fill=(92, 70, 52))     # the door
    tx0, tx1 = px + 3 * s, px + 10 * s                                              # the campanile
    ty = py - h - 12 * s
    d.rectangle((tx0, ty, tx1, py + 1 * s), fill=wall, outline=INK_SOFT)
    d.chord((tx0 + 1.8 * s, ty + 2 * s, tx1 - 1.8 * s, ty + 7 * s), 180, 360, fill=(80, 64, 50))
    d.rectangle((tx0 + 1.8 * s, ty + 4.5 * s, tx1 - 1.8 * s, ty + 6.5 * s), fill=(80, 64, 50))               # the belfry
    d.polygon([(tx0 - 1, ty), (tx1 + 1, ty), ((tx0 + tx1) / 2, ty - 7 * s)], fill=ROOF, outline=INK_SOFT)
    cx = (tx0 + tx1) / 2
    d.line((cx, ty - 7 * s, cx, ty - 12 * s), fill=INK, width=1)                     # the cross
    d.line((cx - 2 * s, ty - 10 * s, cx + 2 * s, ty - 10 * s), fill=INK, width=1)


def clocktower(d, x, z, s=1.0):
    """Torre dell'Orologio: a slim tower with a clock face"""
    px, py = P(x, z)
    w, h = 4.6 * s, 25 * s
    d.rectangle((px - w, py - h, px + w, py), fill=(230, 210, 172), outline=INK_SOFT)
    cy = py - h + 6.5 * s
    r = 3.3 * s
    d.ellipse((px - r, cy - r, px + r, cy + r), fill=(250, 246, 232), outline=INK)
    d.line((px, cy, px, cy - r * 0.75), fill=INK, width=1)
    d.line((px, cy, px + r * 0.6, cy), fill=INK, width=1)
    d.polygon([(px - w - 1.5 * s, py - h), (px + w + 1.5 * s, py - h), (px, py - h - 7 * s)], fill=ROOF, outline=INK_SOFT)
    d.chord((px - 2 * s, py - 6 * s, px + 2 * s, py - 2 * s), 180, 360, fill=(92, 70, 52))
    d.rectangle((px - 2 * s, py - 4 * s, px + 2 * s, py), fill=(92, 70, 52))


def grotto(d, x, z, s=1.0):
    """Grotta Azzurra: a dark cave mouth in the cliff with the blue glow spilling out into the sea (mouth faces west)"""
    px, py = P(x, z)
    d.ellipse((px - 26 * s, py - 8 * s, px + 2 * s, py + 8 * s), fill=(132, 204, 222))
    d.ellipse((px - 17 * s, py - 5 * s, px - 1 * s, py + 5 * s), fill=(92, 184, 218))
    d.pieslice((px - 6 * s, py - 7 * s, px + 8 * s, py + 7 * s), 90, 270, fill=(58, 48, 40), outline=INK)
    d.arc((px - 9 * s, py - 9 * s, px + 9 * s, py + 9 * s), 100, 260, fill=CLIFF_DK, width=2)


def rocks(d, x, z, n=3, s=1.0):
    """a few sea-worn boulders"""
    for _ in range(n):
        px, py = P(x + srnd.uniform(-6, 6), z + srnd.uniform(-5, 5))
        r = srnd.uniform(2.2, 4.0) * s
        d.ellipse((px - r * 1.25, py - r, px + r * 1.25, py + r * 0.8), fill=(178, 172, 156), outline=INK_SOFT)


def read_lines(name):
    return (SURVEY_DIR / name).read_text(encoding="utf-8").split("\n")


def load_survey():
    lines = read_lines("porto_survey.txt")
    meta = {}
    for l in lines:
        p = l.split()
        if len(p) == 2 and p[0] in ("x0", "z0", "step", "nx", "nz"):
            meta[p[0]] = int(p[1])
    i, k = lines.index("CLASS"), lines.index("HEIGHT")
    cls = lines[i + 1:i + 1 + meta["nz"]]
    hgt = np.array([[(ord(ch) - 33) * 3 - 150 for ch in row] for row in lines[k + 1:k + 1 + meta["nz"]]], float)
    return meta, cls, hgt


def load_landmarks():
    houses, objs = [], []
    for l in read_lines("porto_landmarks.txt"):
        f = l.split("|")
        if f[0] == "HOUSE":
            body = next((p for p in f if p.startswith("body ")), None)
            col = STONE
            bw = 16
            if body:
                b = body.split()
                bw = max(float(v) for v in b[2].split("x"))
                col = tuple(int(v) for v in b[b.index("col") + 1].split(","))
            houses.append((f[1], float(f[2]), float(f[3]), bw, col))
        elif f[0] == "OBJ":
            objs.append((f[1], float(f[2]), float(f[3]), float(f[4]), float(f[5]), f[7] if len(f) > 7 else ""))
    terr, routes = [], []
    for l in read_lines("porto_landmarks2.txt"):
        f = l.split("|")
        if f[0] == "TERR":
            terr.append((f[1], float(f[2]), float(f[3])))
        elif f[0] == "ROUTE" and len(f) > 3 and f[3]:
            segs = []
            for s in f[3].split(";"):
                x, z, y, ux, uz, L, wd = (float(v) for v in s.split(","))
                segs.append((x, z, ux, uz, L, wd))
            routes.append((f[1], segs))
    return houses, objs, terr, routes


# categories of ground, cell by cell
NONE, SEA, GRASS_C, ROCK_C, ESC, SAND_C, TOWN_C, PIER_C, CCLIFF = range(9)
ROCK_BOXES = [(354, 370, -1034, -1022), (286, 314, -806, -766)]   # "Layered coastal rock" / the tide pools' rocks (probed Oct 7)
PEBBLE_BOXES = [(400, 416, -1084, -1064)]                          # Spiaggia dei Ciottoli's pebble foundation
KEEP_BOXES = [(508, 528, -1192, -1168), (548, 564, -1156, -1136)]                         # the lighthouse and the keeper's cottage


def classify(meta, cls, hgt):
    """one ground category per survey cell (row 0 = z -530, rows run south)"""
    nz, nx, x0, z0, st = meta["nz"], meta["nx"], meta["x0"], meta["z0"], meta["step"]
    cat = np.zeros((nz, nx), np.uint8)
    for r in range(nz):
        z = z0 - r * st
        row = cls[r]
        for c in range(nx):
            x = x0 + c * st
            ch, h = row[c], hgt[r, c]
            low = h < -56                                    # the terrain under this cell is sea bed
            harbour = x < 352 and z > -770
            esc = z > -598 and x < 345                       # the amphitheatre's rock parts round the falls
            town = x >= 340 and z >= -1000 and not (x > 617 and -949 > z > -756)
            if z > -546:                    k = NONE
            elif ch in "~o?":               k = SEA
            elif ch in "sSv":               k = SAND_C
            elif ch in "k":                 k = ESC
            elif ch in "raen":              k = ROCK_C
            elif ch in "XKR":               k = ESC if z > -600 else ROCK_C
            elif ch in "gGldt":             k = GRASS_C
            elif ch == "b":
                if any(a <= x <= b and c0 <= z <= c1 for a, b, c0, c1 in ROCK_BOXES): k = ROCK_C
                elif any(a <= x <= b and c0 <= z <= c1 for a, b, c0, c1 in PEBBLE_BOXES): k = SAND_C
                elif low:                   k = SEA
                elif esc and z > -592:      k = ESC
                elif harbour:               k = TOWN_C
                elif z < -1150 and not any(a <= x <= b and c0 <= z <= c1 for a, b, c0, c1 in KEEP_BOXES): k = ROCK_C
                elif town:                  k = TOWN_C
                else:                       k = GRASS_C
            elif ch in "pwcx":
                # low paving is the coves' steps and the quay edges (the harbour's timber piers are drawn from the model)
                if low:                     k = (TOWN_C if harbour else SAND_C) if ch in "pwc" else SEA
                elif ch == "x" and esc:     k = ESC
                elif harbour or town:       k = TOWN_C
                else:                       k = GRASS_C
            else:                           k = GRASS_C
            cat[r, c] = k
    # the plateau above the escarpment stays blank paper, as on the first chart: flood from the northern rows through high grass
    plateau = np.zeros_like(cat, bool)
    stack = [(r, c) for r in range(0, 6) for c in range(nx) if cls[r][c] in "gGldt" and hgt[r, c] >= 20]
    for r, c in stack: plateau[r, c] = True
    while stack:
        r, c = stack.pop()
        for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            a, b = r + dr, c + dc
            if 0 <= a < nz and 0 <= b < nx and not plateau[a, b] and cls[a][b] in "gGldt" and hgt[a, b] >= 20 and z0 - a * st > -620:
                plateau[a, b] = True; stack.append((a, b))
    cat[plateau] = NONE
    # steep coasts: land within two cells of the sea that stands well above it becomes a cliff band
    sea = cat == SEA
    near = ndimage.binary_dilation(sea, structure=np.ones((3, 3), bool), iterations=2)
    landish = np.isin(cat, (GRASS_C, ROCK_C))
    hmax = ndimage.maximum_filter(np.where(sea, -200, hgt), size=5)
    cat[near & landish & (hmax > -34)] = CCLIFF
    return cat


def to_image_grid(meta):
    """for every image pixel: the survey cell coordinates (fractional row, col)"""
    px = np.arange(W) + 0.5
    py = np.arange(H) + 0.5
    wx = WX0 + (px - offx) / sc
    wz = WZ0 + (py - offz) / sc
    col = (wx - meta["x0"]) / meta["step"]
    row = (meta["z0"] - wz) / meta["step"]
    return row, col


def draw_porto(img):
    meta, cls, hgt = load_survey()
    houses, objs, terr, routes = load_landmarks()
    cat = classify(meta, cls, hgt)
    nz, nx = cat.shape
    row, col = to_image_grid(meta)
    ri = np.rint(row).astype(int); ci = np.rint(col).astype(int)
    inside_r = (ri >= 0) & (ri < nz); inside_c = (ci >= 0) & (ci < nx)
    big = np.zeros((H, W), np.uint8)
    rr, cc = np.clip(ri, 0, nz - 1), np.clip(ci, 0, nx - 1)
    big[:, :] = cat[rr[:, None], cc[None, :]]
    big[~inside_r, :] = NONE; big[:, ~inside_c] = NONE
    big[:M, :] = NONE; big[H - M:, :] = NONE; big[:, :M] = NONE; big[:, W - M:] = NONE
    # smooth the 4-stud blocks into hand-drawn shapes (a categorical mode filter keeps every class crisp)
    im = Image.fromarray(big, "L").filter(ImageFilter.ModeFilter(5)).filter(ImageFilter.ModeFilter(5))
    big = np.array(im)
    big[:M, :] = NONE; big[H - M:, :] = NONE; big[:, :M] = NONE; big[:, W - M:] = NONE

    # terrain height (sea bed under water) and a soft hill shade, both interpolated from the survey grid
    rows2 = np.repeat(row[:, None], W, 1); cols2 = np.repeat(col[None, :], H, 0)
    hs = ndimage.gaussian_filter(hgt, 1.0)
    himg = ndimage.map_coordinates(hs, [rows2, cols2], order=1, mode="nearest")
    gr, gc = np.gradient(hs)                                 # per 4 studs; rows run south (image up)
    lit = (-gr + gc) / meta["step"]                          # light from the upper left of the sheet
    shade = 1 + 0.10 * np.tanh(lit * 0.9)
    shimg = ndimage.map_coordinates(shade, [rows2, cols2], order=1, mode="nearest")

    base = np.array(img).astype(float)
    tex = base.mean(axis=2) / np.mean(PAPER)                 # carry the paper's blotches into the paint
    tex = np.clip(tex, 0.86, 1.08) ** 0.8
    out = base.copy()
    sea = big == SEA
    land = np.isin(big, (GRASS_C, ROCK_C, ESC, SAND_C, TOWN_C, CCLIFF))

    def paint(mask, colr):
        out[mask] = np.array(colr, float)
    # the sea: pale over the shelf, WATER over the deep
    depth = np.clip((-58 - himg) / 48, 0, 1)
    for i in range(3):
        out[..., i] = np.where(sea, SHALLOW[i] + (WATER[i] - SHALLOW[i]) * depth, out[..., i])
    paint(big == GRASS_C, ITALY)
    paint(big == ROCK_C, ROCKY)
    paint(big == ESC, CLIFF)
    paint(big == CCLIFF, CLIFF)
    paint(big == SAND_C, SAND)
    paint(big == TOWN_C, TOWN)
    paint(big == PIER_C, WOOD)
    # the Groves (the headland south of the town and the lemon/olive terraces) in a deeper green
    gm = Image.new("L", (W, H), 0)
    gd = ImageDraw.Draw(gm)
    for x0, x1, z0, z1 in ((300, 800, -1300, -1000), (617, 800.5, -949, -756)):
        a, b = P(x0, z0), P(x1, z1)
        gd.rectangle((a[0], a[1], b[0], b[1]), fill=255)
    gmask = np.array(gm.filter(ImageFilter.GaussianBlur(7))).astype(float) / 255 * 0.62
    green = np.isin(big, (GRASS_C, ROCK_C))
    for i in range(3):
        out[..., i] = np.where(green, out[..., i] + (ITALY_DK[i] - out[..., i]) * gmask, out[..., i])
    # relief on the land, and the paper's grain over everything painted
    relief = np.isin(big, (GRASS_C, ROCK_C, ESC, CCLIFF, SAND_C))
    for i in range(3):
        out[..., i] = np.where(relief, out[..., i] * shimg, out[..., i])
    painted = big != NONE
    for i in range(3):
        out[..., i] = np.where(painted, out[..., i] * tex, out[..., i])
    # ripple lines following the coast out at sea, like an old chart's soundings
    land_any = np.isin(big, (GRASS_C, ROCK_C, ESC, SAND_C, TOWN_C, CCLIFF, PIER_C))
    dist = ndimage.distance_transform_edt(~land_any)
    for dd, a in ((6, 0.42), (12.5, 0.24)):
        ring = sea & (np.abs(dist - dd) < 0.65)
        for i in range(3):
            out[..., i] = np.where(ring, out[..., i] + (WATER_DK[i] - out[..., i]) * a, out[..., i])
    # outlines: the shore, and the cliff top where the paint meets the blank plateau
    k3 = np.ones((3, 3), bool)
    shore = land_any & ndimage.binary_dilation(sea, k3, iterations=2)
    blank = (big == NONE)
    blank[:M + 1, :] = False; blank[H - M - 1:, :] = False; blank[:, :M + 1] = False; blank[:, W - M - 1:] = False
    top = painted & ndimage.binary_dilation(blank, k3, iterations=2)
    for msk, a in ((shore, 0.85), (top, 0.85)):
        for i in range(3):
            out[..., i] = np.where(msk, out[..., i] + (INK_SOFT[i] - out[..., i]) * a, out[..., i])
    town_edge = (big == TOWN_C) & ndimage.binary_dilation(np.isin(big, (GRASS_C, ROCK_C, CCLIFF)), k3)
    for i in range(3):
        out[..., i] = np.where(town_edge, out[..., i] + (INK_SOFT[i] - out[..., i]) * 0.45, out[..., i])
    img = Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), "RGB")
    d = ImageDraw.Draw(img)

    def cell_xy(r, c):
        return meta["x0"] + c * meta["step"], meta["z0"] - r * meta["step"]

    # cliff hachures on the steep coasts: short strokes running down toward the water
    _, (ir, ic) = ndimage.distance_transform_edt(cat != SEA, return_indices=True)
    for r in range(nz):
        for c in range(nx):
            if cat[r, c] != CCLIFF or (r + c) % 2: continue
            x, z = cell_xy(r, c)
            wx, wz = cell_xy(ir[r, c], ic[r, c])
            v = math.hypot(wx - x, wz - z)
            if v < 1: continue
            ux, uz = (wx - x) / v, (wz - z) / v
            p0, p1 = P(x - ux * 1.5, z - uz * 1.5), P(x + ux * 3.5, z + uz * 3.5)
            if big[int(p0[1]) % H, int(p0[0]) % W] not in (CCLIFF, ESC, GRASS_C, ROCK_C): continue
            d.line((p0[0], p0[1], p1[0], p1[1]), fill=CLIFF_DK, width=1)
    # strata on the limestone escarpment, like the strokes on the falls' cliff face
    for r in range(0, nz):
        for c in range(0, nx, 3):
            if cat[r, c] != ESC or (r % 3) or srnd.random() < 0.45: continue
            x, z = cell_xy(r, c)
            x += srnd.uniform(-3, 3); z += srnd.uniform(-1.5, 1.5)
            a, b = P(x - 2.5, z), P(x + 2.5, z)
            if big[int(a[1]), int(a[0])] == ESC and big[int(b[1]), int(min(b[0], W - 1))] == ESC:
                d.line((a[0], a[1], b[0], b[1]), fill=CLIFF_DK, width=1)
    # stipple on the rocky scrub
    ys, xs = np.nonzero(big == ROCK_C)
    for k in srnd.sample(range(len(xs)), min(len(xs), len(xs) // 110)):
        x, y = xs[k], ys[k]
        d.ellipse((x - 0.9, y - 0.9, x + 0.9, y + 0.9), fill=(150, 146, 116))
    # wave marks out at sea, clear of the coasts
    ys, xs = np.nonzero(sea & (dist > 22))
    placed = []
    order = srnd.sample(range(len(xs)), len(xs))
    for k in order:
        x, y = xs[k], ys[k]
        if all((x - a) ** 2 + (y - b) ** 2 > 46 ** 2 for a, b in placed):
            placed.append((x, y))
            d.arc((x - 6, y - 3, x + 6, y + 3), 200, 340, fill=FOAM, width=1)
            if srnd.random() < 0.5:
                d.arc((x + 3, y + 2, x + 13, y + 6), 200, 340, fill=FOAM, width=1)
        if len(placed) >= 70: break

    # streets, steps and the coastal paths: every part's footprint (mostly stair treads) merged, then thinned to a centre
    # line and drawn as a slim lane with inked edges; Piazza del Limone keeps its true shape
    pm = Image.new("L", (W, H), 0)
    pd = ImageDraw.Draw(pm)
    for name, segs in routes:
        for x, z, ux, uz, L, wd in segs:
            wd = min(max(wd, 2.5), 9)
            vx, vz = -uz, ux
            pts = [P(x + ux * L / 2 * a + vx * wd / 2 * b, z + uz * L / 2 * a + vz * wd / 2 * b) for a, b in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
            pd.polygon(pts, fill=255)
    foot = ndimage.binary_closing(np.array(pm) > 127, k3, iterations=2)
    lane = ndimage.binary_dilation(skeletonize(foot), np.ones((3, 3), bool))
    pq = Image.new("L", (W, H), 0)
    a, b = P(428, -828), P(501, -762)                        # Piazza del Limone
    ImageDraw.Draw(pq).rectangle((a[0], a[1], b[0], b[1]), fill=255)
    pmask = lane | (np.array(pq) > 127)
    pmask &= (big != NONE) & (big != SEA)
    pedge = ndimage.binary_dilation(pmask, k3) & ~pmask & (big != NONE) & (big != SEA)
    arr = np.array(img).astype(float)
    for i in range(3):
        arr[..., i] = np.where(pedge, arr[..., i] + (INK_SOFT[i] - arr[..., i]) * 0.75, arr[..., i])
        arr[..., i] = np.where(pmask, PATH[i] * tex, arr[..., i])
    img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGB")
    d = ImageDraw.Draw(img)

    # the fountain in Piazza del Limone
    fx, fy = P(464, -794)
    d.ellipse((fx - 6, fy - 6, fx + 6, fy + 6), fill=WATER, outline=INK_SOFT, width=2)
    d.ellipse((fx - 1.5, fy - 1.5, fx + 1.5, fy + 1.5), fill=FOAM)
    # the lemon and olive terraces: three levels with their retaining walls and irrigation channels
    for xw in (646, 690):
        a, b = P(xw, -952), P(xw, -758)
        d.line((a[0], a[1], b[0], b[1]), fill=CLIFF_DK, width=3)
        for zz in range(-948, -760, 9):
            p = P(xw, zz)
            d.line((p[0] - 2, p[1], p[0] + 1, p[1]), fill=INK_SOFT, width=1)
    for xc in (618, 658, 707):
        a, b = P(xc, -946), P(xc, -800)
        d.line((a[0], a[1], b[0], b[1]), fill=WATER_DK, width=1)
    # tide pools in Cala della Sabbia and pebbles on Spiaggia dei Ciottoli
    for x, z, r in ((296, -770, 3.2), (306, -778, 2.4), (290, -796, 2.8), (318, -790, 2.2), (300, -804, 2.0)):
        px, py = P(x, z)
        d.ellipse((px - r * 1.4, py - r, px + r * 1.4, py + r), fill=SHALLOW, outline=INK_SOFT)
    for _ in range(80):
        x, z = srnd.uniform(390, 442), srnd.uniform(-1086, -1050)
        px, py = P(x, z)
        if big[int(py), int(px)] == SAND_C:
            q = srnd.uniform(0.8, 1.5)
            d.ellipse((px - q, py - q * 0.8, px + q, py + q * 0.8), fill=(168, 160, 146))
    # Prato dei Fiori: the meadow in flower
    for _ in range(170):
        x, z = srnd.uniform(444, 598), srnd.uniform(-1138, -1022)
        px, py = P(x, z)
        if big[int(py), int(px)] in (GRASS_C, ROCK_C) and not pmask[int(py), int(px)]:
            colr = srnd.choice(((246, 242, 232), (244, 214, 92), (226, 140, 150), LAVENDER, (238, 120, 96)))
            d.ellipse((px - 1.1, py - 1.1, px + 1.1, py + 1.1), fill=colr)
    # the harbour: the pontoon, the two jetties and the gangways
    for x0, x1, z0, z1 in ((204, 207, -695, -629), (205, 231.5, -638.5, -635.5), (197, 227, -686.5, -683.5)):
        a, b = P(x0, z0), P(x1, z1)
        d.rectangle((a[0], a[1], b[0], b[1]), fill=(176, 138, 96), outline=INK_SOFT)
    for x, z in ((205.5, -629), (205.5, -695), (205, -637), (197, -685)):                  # mooring posts
        px, py = P(x, z)
        d.ellipse((px - 1.6, py - 1.6, px + 1.6, py + 1.6), fill=WOOD)
    # the funicular from the harbour (stazione bassa) up to the belvedere (stazione alta)
    a, b = P(345, -604), P(700, -659)
    L = math.hypot(b[0] - a[0], b[1] - a[1]); ux, uy = (b[0] - a[0]) / L, (b[1] - a[1]) / L
    for k in range(0, int(L), 6):
        cx, cy = a[0] + ux * k, a[1] + uy * k
        d.line((cx + uy * 3.5, cy - ux * 3.5, cx - uy * 3.5, cy + ux * 3.5), fill=INK_SOFT, width=1)
    for off in (-2, 2):
        d.line((a[0] + uy * off, a[1] - ux * off, b[0] + uy * off, b[1] - ux * off), fill=(96, 74, 54), width=1)
    cx, cy = a[0] + ux * L * 0.42, a[1] + uy * L * 0.42                  # one of the cars on its way up
    q = [(cx - ux * 6 + uy * 3.5, cy - uy * 6 - ux * 3.5), (cx + ux * 6 + uy * 3.5, cy + uy * 6 - ux * 3.5),
         (cx + ux * 6 - uy * 3.5, cy + uy * 6 + ux * 3.5), (cx - ux * 6 - uy * 3.5, cy - uy * 6 + ux * 3.5)]
    d.polygon(q, fill=(196, 72, 58), outline=INK)
    d.line((cx - ux * 3, cy - uy * 3, cx + ux * 3, cy + uy * 3), fill=(246, 236, 210), width=2)

    # ---------------------------------------------------------------- everything that stands up, drawn back to front
    icons = []                                               # (z, fn)
    PASTEL = ((230, 183, 166), (220, 191, 128), (158, 186, 185), (221, 132, 101), (181, 196, 172), (220, 159, 79))
    for name, x, z, bw, colr in houses:
        s = min(max(bw / 19, 0.78), 1.12)
        icons.append((z, lambda x=x, z=z, s=s, c=colr: house(d, x, z, s, wall=mix(c, STONE, 0.38))))
    for k, (x, z) in enumerate(((304, -604), (262, -606), (304, -627), (272, -627), (302, -651), (276, -652), (308, -675), (270, -678))):
        icons.append((z, lambda x=x, z=z, k=k: house(d, x, z, 0.9, wall=mix(PASTEL[k % len(PASTEL)], STONE, 0.38))))
    icons.append((-605, lambda: house(d, 343, -605, 0.75, wall=(232, 222, 200))))           # stazione bassa
    icons.append((-660, lambda: house(d, 698, -660, 0.8, wall=(232, 222, 200))))            # stazione alta
    icons.append((-1147, lambda: house(d, 555, -1147, 0.85, wall=(240, 234, 222))))         # the keeper's cottage
    icons.append((-950, lambda: house(d, 437, -950, 0.85, wall=(214, 228, 232))))           # the sailing club
    icons.append((-968, lambda: boat(d, 438, -969, 0.42, hull=(236, 232, 222), sail=False)))
    icons.append((-962, lambda: church(d, 406, -962, 1.0)))
    icons.append((-817, lambda: clocktower(d, 493, -817, 1.0)))
    icons.append((-1006, lambda: watchtower(d, 585, -1006, 1.0)))
    icons.append((-1178, lambda: lighthouse(d, 520, -1178, 1.0)))
    icons.append((-1108, lambda: grotto(d, 430, -1108, 1.0)))
    for x, z, n in ((539, -1203, 4), (481, -1201, 4), (454, -1166, 3), (363, -1028, 3), (301, -786, 3)):   # layered coastal rock
        icons.append((z, lambda x=x, z=z, n=n: rocks(d, x, z, n, 1.0)))
    for name, x, z, w_, d_, par in objs:
        n = name.lower()
        if "olive tree" in n:
            icons.append((z, lambda x=x, z=z: tree(d, x, z, 0.62, OLIVE)))
        elif "stone pine" in n or "umbrella pine" in n:
            icons.append((z, lambda x=x, z=z, s=min(max(w_ / 22, 0.8), 1.1): umbrella_pine(d, x, z, s)))
        elif "cypress" in n:
            icons.append((z, lambda x=x, z=z: cypress(d, x, z, 0.8)))
        elif n == "lemon tree" or "corner lemon tree" in n:
            icons.append((z, lambda x=x, z=z: lemon_tree(d, x, z, 0.72)))
    for name, x, z in terr:
        if name == "Silver olive tree":
            icons.append((z, lambda x=x, z=z: tree(d, x, z, 0.66, OLIVE)))
        elif name == "Lemon tree":
            icons.append((z, lambda x=x, z=z: lemon_tree(d, x, z, 1.0)))
    # boats: three of the fishing boats at the jetties, the lifeguard's, and a sail out in the harbour sea
    icons.append((-646, lambda: boat(d, 218, -647, 0.55, hull=(104, 132, 168))))
    icons.append((-669, lambda: boat(d, 190, -669, 0.55, hull=(186, 98, 80), flip=True)))
    icons.append((-694, lambda: boat(d, 214, -694, 0.55, hull=(224, 196, 104))))
    icons.append((-713, lambda: boat(d, 253, -714, 0.4, hull=(196, 72, 58), sail=False)))
    icons.append((-930, lambda: boat(d, 226, -930, 0.85, hull=WOOD)))
    icons.append((-1190, lambda: boat(d, 330, -1190, 0.7, hull=(104, 132, 168), flip=True)))
    for z, fn in sorted(icons, key=lambda t: t[0]):
        fn()
    return img


def draw_south_and_france(img):
    """make_map_world.py's drawing from the ridge onward, unchanged except that the first harbour sketch (the plain, the pool,
    its wave marks and the plain's planting) is gone: the survey drawing replaces it. Its random draws are still made so
    France's generator stays in step."""
    d = ImageDraw.Draw(img)
    # ---------------------------------------------------------------- the south: ridge, gorge, falls
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
    for x, zz in left[::6]:                                  # pines on the rims
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
    for k in range(6):                                       # (the first sketch's harbour wave marks: draws kept, nothing drawn)
        rnd.uniform(165, 215), rnd.uniform(-600, -690)
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
    for _ in range(14):                                      # (the first sketch's planting on the plain: draws kept, nothing drawn)
        x, zz = rnd.uniform(244, 325), rnd.uniform(-566, -695)
        if abs(x - 236) < 14 and abs(zz + 580) < 14: continue
        rnd.random(); rnd.uniform(0.7, 1.0)
    for _ in range(4):
        rnd.uniform(106, 140); rnd.uniform(-580, -690)
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
    return img


def debug_copy(img):
    """a separate copy with crosshairs on known points, to check the mapping (never upload this one)"""
    dbg = img.copy()
    d = ImageDraw.Draw(dbg)
    for x, z, colr in ((520, -1178, (220, 0, 0)), (407, -962, (0, 90, 220)), (698, -661, (0, 150, 0)), (185, -547, (200, 0, 200))):
        px, py = P(x, z)
        d.ellipse((px - 9, py - 9, px + 9, py + 9), outline=colr, width=2)
        d.line((px - 14, py, px + 14, py), fill=colr, width=1)
        d.line((px, py - 14, px, py + 14), fill=colr, width=1)
    return dbg


def main():
    img = paper(Image.new("RGB", (W, H), PAPER))
    d = ImageDraw.Draw(img)

    # ---------------------------------------------------------------- France: the three areas
    area(d, -130, -215, 142, 25, GRASS, INK_SOFT)            # The Great Acorn Forest
    area(d, 150, -205, 352, 5, (222, 212, 194), INK_SOFT)    # Rue de Noisette
    area(d, 352, -250, 700, 30, (216, 206, 168), INK_SOFT)   # Chateau de l'Acorn

    # ---------------------------------------------------------------- Porto Nocciola, from the survey (under the gorge and falls)
    img = draw_porto(img)
    img = draw_south_and_france(img)

    # a soft vignette so the edges look aged
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).rounded_rectangle((M - 6, M - 6, W - M + 6, H - M + 6), radius=30, fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(26))
    dark = Image.new("RGB", (W, H), (176, 150, 104))
    img = Image.composite(img, Image.blend(img, dark, 0.55), mask)

    d = ImageDraw.Draw(img)
    torn_border(d)
    img.save(OUT)
    split = math.ceil(H / 2)
    img.crop((0, 0, W, split)).save(OUT_DIR / "world_chart2_top.png")
    img.crop((0, split, W, H)).save(OUT_DIR / "world_chart2_bottom.png")
    img.resize((W // 2, round(H / 2)), Image.LANCZOS).save(OUT_DIR / "world_chart2_preview.jpg", quality=88)
    debug_copy(img).save(OUT_DIR / "world_chart2_debug.png")
    print("wrote", OUT, img.size, "split row", split, "scale px/stud", round(sc, 6), "offsets", round(offx, 3), round(offz, 3))


if __name__ == "__main__":
    main()
