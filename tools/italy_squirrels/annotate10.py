import math, re
from PIL import Image, ImageDraw, ImageFont
D = r'C:\Users\slard\AppData\Local\Temp\claude\C--Users-slard\396c58ec-3e4f-4bbd-9d54-a851d5aca070\scratchpad'
W, H = 1568, 417
K = 222.5 / (141.8 * math.tan(math.radians(15)))
def px(z): return (836 + (z + 655) * K) * W / 1672
def py(x): return (222.5 - (x - 238) * K) * H / 445
LEFT = int(px(-722)); S = 2
def P(x, z): return ((px(z) - LEFT) * S, py(x) * S)
F = ImageFont.truetype('arialbd.ttf', 21); Fs = ImageFont.truetype('arialbd.ttf', 18)
L = open(r'C:\Users\slard\roblox-props\tools\italy_squirrels\probe_promenade_out.txt', encoding='utf-8-sig').read().splitlines()
wall = []
for l in L:
    if ('Seawall ashlar' in l or 'Rounded coping' in l) and l.startswith('QPR@item'):
        m = re.search(r'min ([-\d.]+),[-\d.]+,([-\d.]+) max ([-\d.]+),[-\d.]+,([-\d.]+)', l)
        wall.append(tuple(map(float, m.groups())))
def edge_x(z):
    xs = [a for a, z0, b, z1 in wall if z0 - 0.6 <= z <= z1 + 0.6]
    return min(xs) if xs else None

def label(d, xy, text, fill=(255, 255, 255), bg=(20, 24, 32), font=F, anchor='mm'):
    b = d.textbbox(xy, text, font=font, anchor=anchor)
    d.rounded_rectangle((b[0] - 7, b[1] - 5, b[2] + 7, b[3] + 5), 7, fill=bg)
    d.text(xy, text, font=font, fill=fill, anchor=anchor)

def lane(d, z, x_sea, x_land, text, col, side=1):
    a, b = P(x_sea, z), P(x_land, z)
    d.line([a, b], fill=col, width=5)
    for p in (a, b):
        d.line([(p[0] - 11, p[1]), (p[0] + 11, p[1])], fill=col, width=5)
    mid = ((a[0] + b[0]) / 2 + side * 14, (a[1] + b[1]) / 2)
    label(d, mid, text, fill=col, anchor='lm' if side > 0 else 'rm')

RED, GREEN, YEL = (255, 110, 100), (120, 240, 140), (255, 214, 90)
# lanes: (z, NOW sea x, NOW land x, PLAN sea x, PLAN land x, name)
LANES = [(-646.5, 242.8, 247.2, 232.8, 242.2, 'front of fish stall'),
         (-644.0, 259.3, 266.0, 254.3, 266.0, 'behind fish stall'),
         (-669.0, 240.8, 247.7, 230.8, 242.7, 'edge to bench'),
         (-669.0, 250.5, 259.0, 245.5, 259.0, 'bench to Bottega')]

for kind in ('now', 'plan10'):
    im = Image.open(f'{D}\\promenade_{kind}.png').convert('RGB')
    d = ImageDraw.Draw(im)
    if kind == 'plan10':   # old quay edge, dashed
        pts = [P(edge_x(z), z) for z in [(-599.4 - i * 0.5) for i in range(199)] if edge_x(z)]
        for i in range(0, len(pts) - 1, 4):
            d.line(pts[i:i + 3], fill=YEL, width=3)
        label(d, P(236, -611), 'old edge', fill=YEL, font=Fs)
        label(d, P(222.0, -612.5), 'new edge +10', fill=(255, 255, 255), font=Fs)
        label(d, P(212.0, -633), 'pier 10 shorter', font=Fs, anchor='rm')
        label(d, P(204.0, -681), 'pier 10 shorter', font=Fs, anchor='rm')
        label(d, P(255.0, -639.0), 'fish stall +5', font=Fs, anchor='lm')
        label(d, P(208.5, -647.5), 'Stella Marina 2 out', font=Fs, anchor='lm')
    else:
        label(d, P(254, -646.5), 'fish stall', font=Fs)
        label(d, P(257.5, -619), 'gelato tables', font=Fs, anchor='rm')
        label(d, P(232, -637), 'Molo dei Pescatori', font=Fs, anchor='lm')
        label(d, P(230, -685), 'Molo delle Reti', font=Fs, anchor='lm')
    for z, a0, b0, a1, b1, name in LANES:
        a, b = (a0, b0) if kind == 'now' else (a1, b1)
        w = b - a
        col = RED if w < 7.5 else GREEN
        lane(d, z, a, b, f'{w:.0f}', col, side=1 if name != 'bench to Bottega' else 1)
    label(d, (16, 20), 'NOW' if kind == 'now' else 'PLAN: +10 studs', anchor='lm',
          fill=(255, 255, 255), bg=(150, 40, 40) if kind == 'now' else (30, 110, 60))
    label(d, (im.width - 16, 20), 'north \u2192', anchor='rm', font=Fs)
    im.save(f'{D}\\promenade_{kind}_ann.png')
    print('ok', kind, im.size)
