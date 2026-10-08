# Oct 8 2026: Porto gates planning - draws the read-only ground survey (italy/map/survey/porto_survey.txt) with the area
# rects, the More Squirrels Coming Soon wall line and the routes, south UP like the in-game chart. Output: survey_view.png
import math
from PIL import Image, ImageDraw, ImageFont
S = '../map/survey/'
L = open(S + 'porto_survey.txt', encoding='utf-8').read().split('\n')
ci = L.index('CLASS'); hi = L.index('HEIGHT')
CL = L[ci + 1:ci + 197]; HT = L[hi + 1:hi + 197]
X0, Z0, ST = -130, -530, 4
def h(r, c): return (ord(HT[r][c]) - 33) * 3 - 150
XA, XB, ZA, ZB = 140, 820, -1310, -530       # crop
K = 6                                         # px per cell (4 studs)
def px(x, z): return ((x - XA) / ST * K, (z - ZA) / ST * K)   # south (low z) at the top
W = int((XB - XA) / ST * K); H = int((ZB - ZA) / ST * K)
im = Image.new('RGB', (W, H), (0, 0, 0)); d = ImageDraw.Draw(im, 'RGBA')
COL = {'~': (90, 150, 190), 's': (225, 210, 160), 'g': (120, 170, 90), 'l': (100, 150, 80), 'd': (140, 120, 90), 'r': (130, 130, 135),
       'k': (200, 195, 180), 'e': (90, 95, 105), 'a': (70, 70, 75), 'n': (210, 180, 130), 'c': (190, 185, 175), 'w': (160, 120, 80),
       'v': (170, 165, 155), 'b': (175, 90, 70), 't': (60, 110, 60), 'o': (240, 240, 240), 'p': (225, 220, 205), 'x': (150, 140, 160),
       'G': (120, 170, 90), 'S': (225, 210, 160), 'R': (130, 130, 135), '?': (0, 0, 0)}
for r in range(196):
    z = Z0 - r * ST
    if z < ZA or z > ZB: continue
    for c in range(len(CL[r])):
        x = X0 + c * ST
        if x < XA or x > XB: continue
        ch = CL[r][c]
        col = COL.get(ch, COL.get(ch.lower(), (255, 0, 255)))
        if ch not in '~?':
            hh = h(r, c); f = max(0.55, min(1.25, 0.85 + hh / 160))
            col = tuple(int(min(255, v * f)) for v in col)
        X, Y = px(x - 2, z + 2)
        d.rectangle([X, Y - K, X + K, Y], fill=col)
# area rects
Z = {'harbour': ((70, 120, 255), [(150, -880, 355, -540), (150, -1300, 300, -880)]),
     'borgo': ((255, 150, 40), [(355.5, -1000, 617, -540), (617, -756, 800.5, -540), (617, -1000, 800.5, -949), (300, -1000, 355, -880)]),
     'groves': ((40, 200, 90), [(300, -1300, 800, -1000), (617, -949, 800.5, -756)])}
for k, (col, rs) in Z.items():
    for (x0, z0, x1, z1) in rs:
        a = px(x0, z0); b = px(x1, z1)
        d.rectangle([a[0], a[1], b[0], b[1]], outline=col + (255,), width=3)
LINE = [(268, -1140), (281, -989), (288, -953), (292, -881), (300, -855), (309, -828), (314, -794), (317, -773), (324, -768), (333, -764), (339, -744), (342, -723), (347, -698), (347, -672), (343, -652), (343, -634), (353, -622), (358, -591), (358, -540)]
d.line([px(*p) for p in LINE], fill=(230, 30, 30, 255), width=4)
font = ImageFont.truetype('arial.ttf', 15)
# routes
for line in open(S + 'porto_landmarks2.txt', encoding='utf-8'):
    if line.startswith('ROUTE|'):
        _, name, n, pts = line.rstrip('\n').split('|', 3)
        P = [[float(t) for t in p.split(',')] for p in pts.split(';') if p]
        for v in P:
            X, Y = px(v[0], v[1]); d.ellipse([X - 2, Y - 2, X + 2, Y + 2], fill=(255, 255, 255, 200))
        cx = sum(v[0] for v in P) / len(P); cz = sum(v[1] for v in P) / len(P)
        X, Y = px(cx, cz); d.text((X + 4, Y), name, fill=(255, 255, 255), font=font, stroke_width=2, stroke_fill=(0, 0, 0))
# grid ticks every 50 studs
for x in range(150, 821, 50):
    X, _ = px(x, 0); d.line([X, 0, X, 8], fill=(255, 255, 255)); d.text((X + 2, 8), str(x), fill=(255, 255, 255), font=font)
for z in range(-1300, -539, 50):
    _, Y = px(0, z); d.line([0, Y, 8, Y], fill=(255, 255, 255)); d.text((10, Y - 8), str(z), fill=(255, 255, 255), font=font)
im.save('survey_view.png'); print(im.size)
