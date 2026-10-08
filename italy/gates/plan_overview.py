# Oct 8 2026: the Porto gates plan drawn on the new world chart (south up, like the game's map).
# Areas tinted, the existing invisible wall (the old "coming soon" line, red), the proposed new wall between Via della Piazza
# and The Groves (purple), and numbered gates. Output: page/img/plan_overview.png (+ plan_overview_b.png = option B lines).
import math, os
from PIL import Image, ImageDraw, ImageFont
OUT = 'page/img'; os.makedirs(OUT, exist_ok=True)
im0 = Image.open('../map/world_chart2.png').convert('RGB')
sc, ox, oz, WX0, WZ0 = 1.023158, 26.0, 25.984, -130, -1310
def P(x, z): return (ox + (x - WX0) * sc, oz + (z - WZ0) * sc)
XA, ZA, XB, ZB = 150, -1250, 810, -560
a = P(XA, ZA); b = P(XB, ZB)
K = 1.75
base = im0.crop((int(a[0]), int(a[1]), int(b[0]), int(b[1])))
base = base.resize((int(base.width * K), int(base.height * K)), Image.LANCZOS)
def Q(x, z): p = P(x, z); return ((p[0] - int(a[0])) * K, (p[1] - int(a[1])) * K)
F = lambda n: ImageFont.truetype('arialbd.ttf', n)

HARB = [(150, -880, 355, -540), (150, -1300, 300, -880)]
BORGO = [(355.5, -1000, 617, -540), (617, -756, 800.5, -540), (300, -1000, 355, -880)]
STRIP = (617, -1000, 800.5, -949)
GROVES = [(300, -1300, 800, -1000), (617, -949, 800.5, -756)]
CSW = [(268, -1140), (281, -989), (288, -953), (292, -881), (300, -855), (309, -828), (314, -794), (317, -773), (324, -768), (333, -764),
       (339, -744), (342, -723), (347, -698), (347, -672), (343, -652), (343, -634), (353, -622), (358, -591), (358, -540)]
# proposed wall, option A (recommended): the strip south of the terraces joins The Groves -> one line
WALL_A = [(338, -985), (372, -994), (383, -1004), (394, -1012), (412, -1030), (432, -1032), (470, -1005), (520, -990), (551, -984),
          (575, -982), (617, -985), (617, -756), (680, -760), (703, -760), (795, -756)]
# option B (zones as they are now): the line runs along z -1000 to the east point, the terraces get their own fence
WALL_B1 = [(338, -985), (372, -994), (383, -1004), (394, -1012), (412, -1030), (432, -1032), (470, -1005), (520, -990), (551, -984),
           (575, -985), (620, -1000), (790, -1000)]
WALL_B2 = [(617, -949), (617, -756), (680, -760), (703, -760), (795, -756)]
WALL_B3 = [(617, -949), (790, -949)]
GATES = [  # n, x, z, kind
    (1, 359, -627, 'h'), (2, 323, -771, 'h'), (3, 340, -604, 'f'),
    (3, 386, -1000, 'g'), (4, 423, -1031, 'g'), (5, 551, -985, 'g'), (6, 680, -759, 'g'), (7, 703, -759, 'g')]


def draw(fn, walls, strip_groves):
    im = base.copy(); d = ImageDraw.Draw(im, 'RGBA')
    def rect(r, col):
        p0 = Q(r[0], r[1]); p1 = Q(r[2], r[3])
        d.rectangle([p0[0], p0[1], p1[0], p1[1]], fill=col)
    for r in HARB: rect(r, (60, 120, 230, 46))
    for r in BORGO: rect(r, (240, 140, 30, 46))
    for r in GROVES: rect(r, (40, 170, 70, 46))
    rect(STRIP, (40, 170, 70, 46) if strip_groves else (240, 140, 30, 46))
    if strip_groves:   # hatch the strip that changes area
        p0 = Q(STRIP[0], STRIP[1]); p1 = Q(STRIP[2], STRIP[3])
        for t in range(int(p0[0]) - 120, int(p1[0]), 14):
            d.line([t, p0[1], t + (p1[1] - p0[1]), p1[1]], fill=(30, 120, 50, 90), width=2)
    def poly(pts, col, w, dash=None):
        q = [Q(*p) for p in pts]
        if not dash: d.line(q, fill=col, width=w, joint='curve'); return
        for (x0, y0), (x1, y1) in zip(q, q[1:]):
            L = math.hypot(x1 - x0, y1 - y0); n = max(1, int(L / dash))
            for i in range(0, n, 2):
                t0, t1 = i / n, min(1, (i + 1) / n)
                d.line([x0 + (x1 - x0) * t0, y0 + (y1 - y0) * t0, x0 + (x1 - x0) * t1, y0 + (y1 - y0) * t1], fill=col, width=w)
    poly(CSW, (215, 40, 40, 235), 5, dash=9)
    for wl in walls: poly(wl, (120, 40, 190, 240), 5, dash=9)
    for n, x, z, kind in GATES:
        X, Y = Q(x, z)
        ring = {'h': (215, 40, 40), 'g': (120, 40, 190), 'f': (40, 90, 160)}[kind]
        r = 15
        d.ellipse([X - r, Y - r, X + r, Y + r], fill=(255, 250, 235, 255), outline=ring + (255,), width=4)
        d.text((X, Y + 1), str(n) if kind != 'f' else 'F', fill=ring, font=F(17), anchor='mm')
    # area names
    for name, x, z in (('THE HARBOUR', 205, -760), ('VIA DELLA PIAZZA', 470, -700), ('THE GROVES', 520, -1150)):
        X, Y = Q(x, z); d.text((X, Y), name, fill=(60, 40, 25), font=F(20), anchor='mm', stroke_width=3, stroke_fill=(255, 250, 235))
    im.save(fn); print(fn, im.size)


draw(os.path.join(OUT, 'plan_overview.png'), [WALL_A], True)
draw(os.path.join(OUT, 'plan_overview_b.png'), [WALL_B1, WALL_B2, WALL_B3], False)
