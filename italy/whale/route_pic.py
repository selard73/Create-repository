"""Route picture for the whale: Studio straight-down capture (cam y 716, FOV 40, looking at (250,-53,-980), screen up = +Z,
screen right = -X) with the proposed loop, blow stations, whale at scale and place labels from the survey."""
import math
from PIL import Image, ImageDraw, ImageFont
D = r'C:\Users\slard\roblox-props\italy\whale'
im = Image.open(D + r'\sea_topdown.jpg').convert('RGB')
W, H = im.size                                  # 1568 x 635 for a 1272 x 515 viewport
K = (H / (2 * 769 * math.tan(math.radians(20))))  # image px per stud at the water surface
def P(x, z): return (W / 2 - (x - 250) * K, H / 2 - (z + 980) * K)

ROUTE = [(200, -840), (90, -940), (40, -1110), (210, -1215), (340, -1165), (362, -1102), (215, -985)]
BLOW = {0: 'A', 5: 'B'}
def catmull(pts, n=24):
    out = []
    m = len(pts)
    for i in range(m):
        p0, p1, p2, p3 = pts[(i - 1) % m], pts[i], pts[(i + 1) % m], pts[(i + 2) % m]
        for k in range(n):
            t = k / n
            out.append(tuple(0.5 * ((2 * p1[a]) + (-p0[a] + p2[a]) * t + (2 * p0[a] - 5 * p1[a] + 4 * p2[a] - p3[a]) * t * t + (-p0[a] + 3 * p1[a] - 3 * p2[a] + p3[a]) * t ** 3) for a in (0, 1)))
    return out
curve = catmull(ROUTE)
length = sum(math.dist(curve[i], curve[(i + 1) % len(curve)]) for i in range(len(curve)))
print('loop length studs', round(length))

SC = 1.35
big = im.resize((int(W * SC), int(H * SC)), Image.LANCZOS)
ov = Image.new('RGBA', big.size, (0, 0, 0, 0))
d = ImageDraw.Draw(ov)
def Q(x, z): a, b = P(x, z); return (a * SC, b * SC)
def font(sz, bold=True):
    try: return ImageFont.truetype('C:/Windows/Fonts/' + ('segoeuib.ttf' if bold else 'segoeui.ttf'), sz)
    except Exception: return ImageFont.load_default()

# whale lane (trench 60 wide) under the route
lane_px = 60 * K * SC
pts = [Q(*c) for c in curve]
d.line(pts + [pts[0]], fill=(10, 40, 90, 70), width=int(lane_px), joint='curve')
# the route
d.line(pts + [pts[0]], fill=(255, 255, 255, 230), width=5, joint='curve')
# direction arrows every ~90 studs
acc = 0
for i in range(len(curve)):
    a, b = curve[i], curve[(i + 1) % len(curve)]
    acc += math.dist(a, b)
    if acc > 110:
        acc = 0
        pa, pb = Q(*a), Q(*b)
        ang = math.atan2(pb[1] - pa[1], pb[0] - pa[0])
        L = 14
        tip = pb
        l = (tip[0] - L * math.cos(ang - 0.5), tip[1] - L * math.sin(ang - 0.5))
        r = (tip[0] - L * math.cos(ang + 0.5), tip[1] - L * math.sin(ang + 0.5))
        d.polygon([tip, l, r], fill=(255, 255, 255, 240))

# whale at scale (60 x 20 body, flukes) at station A heading along the route
def whale(at, nxt, col=(70, 120, 200, 235)):
    a, b = Q(*at), Q(*nxt)
    ang = math.atan2(b[1] - a[1], b[0] - a[0])
    Lh, Wh = 60 * K * SC / 2, 20 * K * SC / 2
    def rot(px, py): return (a[0] + px * math.cos(ang) - py * math.sin(ang), a[1] + px * math.sin(ang) + py * math.cos(ang))
    body = [rot(Lh * math.cos(t) * (1 if math.cos(t) > 0 else 1.0), Wh * math.sin(t) * (0.55 + 0.45 * (math.cos(t) + 1) / 2)) for t in [i * 2 * math.pi / 48 for i in range(48)]]
    d.polygon(body, fill=col, outline=(255, 255, 255, 255))
    fl = [rot(-Lh * 0.92, 0), rot(-Lh * 1.18, -Wh * 1.1), rot(-Lh * 1.05, 0), rot(-Lh * 1.18, Wh * 1.1)]
    d.polygon(fl, fill=col, outline=(255, 255, 255, 255))
whale(ROUTE[0], ROUTE[1])
whale(ROUTE[5], ROUTE[6], col=(70, 120, 200, 150))

# blow stations
f = font(26); fs = font(18); fl = font(19, False)
for i, tag in BLOW.items():
    cx, cy = Q(*ROUTE[i])
    r = 22
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 196, 40, 240), outline=(40, 30, 0, 255), width=3)
    tw = d.textlength(tag, font=f)
    d.text((cx - tw / 2, cy - 18), tag, font=f, fill=(30, 20, 0, 255))

def label(x, z, text, dx=14, dy=-12, anchor='l'):
    px, py = Q(x, z)
    tw = d.textlength(text, font=fs)
    if anchor == 'r': px -= tw + 2 * dx
    box = [px + dx - 6, py + dy - 4, px + dx + tw + 6, py + dy + 24]
    d.rounded_rectangle(box, radius=6, fill=(255, 255, 255, 215))
    d.text((px + dx, py + dy), text, font=fs, fill=(20, 30, 45, 255))
    d.ellipse([Q(x, z)[0] - 5, Q(x, z)[1] - 5, Q(x, z)[0] + 5, Q(x, z)[1] + 5], fill=(255, 80, 60, 255), outline=(255, 255, 255, 255), width=2)

label(200, -770, 'Bay mouth (harbour entrance)', dx=16, dy=-34)
label(300, -715, 'Tide pools', dx=14, dy=8)
label(310, -782, 'Cala della Sabbia', dx=14, dy=4)
label(437, -950, 'Sailing club', dx=-10, dy=-34, anchor='r')
label(416, -1067, 'Spiaggia dei Ciottoli', dx=14, dy=-30)
label(450, -1112, 'Grotta Azzurra (the cave)', dx=14, dy=4)
label(520, -1178, 'Faro (lighthouse)', dx=-10, dy=-36, anchor='r')
label(585, -1006, 'Torre di Guardia', dx=-10, dy=-12, anchor='r')

# station captions
def cap(x, z, lines, dx, dy):
    px, py = Q(x, z)
    tw = max(d.textlength(t, font=fl) for t in lines)
    box = [px + dx - 8, py + dy - 6, px + dx + tw + 8, py + dy + 26 * len(lines) + 2]
    d.rounded_rectangle(box, radius=8, fill=(255, 244, 200, 235), outline=(200, 150, 20, 255), width=2)
    for k, t in enumerate(lines): d.text((px + dx, py + dy + 26 * k), t, font=fl, fill=(40, 30, 0, 255))
cap(*ROUTE[0], ['A: blows outside the bay,', 'facing the open sea'], 40, -10)
cap(*ROUTE[5], ['B: blows off the pebble beach,', 'the cave 90 studs away'], -330, 30)

# scale bar + legend
x0, y0 = 40, big.size[1] - 48
d.line([(x0, y0), (x0 + 100 * K * SC, y0)], fill=(255, 255, 255, 255), width=5)
d.text((x0, y0 - 28), '100 studs', font=fs, fill=(255, 255, 255, 255))
d.text((x0 + 100 * K * SC + 24, y0 - 28), 'loop %d studs  |  shaded band = whale lane (sea bed dug to -80)' % length, font=fl, fill=(255, 255, 255, 255))
d.text((x0, 16), 'Top of picture = toward the harbour and town.  Bottom = open sea.', font=fl, fill=(255, 255, 255, 255))

out = Image.alpha_composite(big.convert('RGBA'), ov).convert('RGB')
out = out.crop((0, 0, int(1250 * SC), out.size[1]))
out.save(D + r'\route_map.jpg', 'JPEG', quality=88)
print(out.size)
